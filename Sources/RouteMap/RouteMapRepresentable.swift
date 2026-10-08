import MapKit
import SwiftUI

/// The map itself: draws the line and the marker icons, and reports marker selection.
struct RouteMapRepresentable: UIViewRepresentable {
    let route: Route
    let onSelect: (RouteMarker) -> Void
    let onDeselect: (RouteMarker.ID) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> LayoutReportingMapView {
        let mapView = LayoutReportingMapView()
        mapView.delegate = context.coordinator
        mapView.register(
            RouteMarkerAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: RouteMarkerAnnotationView.reuseIdentifier
        )
        let coordinator = context.coordinator
        mapView.onLayout = { [weak coordinator] mapView in
            coordinator?.fitIfNeeded(mapView)
        }
        return mapView
    }

    func updateUIView(_ mapView: LayoutReportingMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.apply(route, to: mapView)
    }

    static func dismantleUIView(_ mapView: LayoutReportingMapView, coordinator: Coordinator) {
        coordinator.cancelLoading()
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RouteMapRepresentable

        private var annotations: [RouteMarkerAnnotation] = []
        private var polyline: MKPolyline?
        private var geometryKey: RouteGeometryKey?
        private var needsFit = false
        private var hasFit = false
        private let loader = RouteDirectionsLoader()

        init(parent: RouteMapRepresentable) {
            self.parent = parent
        }

        func cancelLoading() {
            loader.cancel()
        }

        func apply(_ route: Route, to mapView: MKMapView) {
            updateAnnotations(route.allMarkers, on: mapView)

            let key = route.geometryKey
            if key != geometryKey {
                geometryKey = key
                reloadPath(for: route, on: mapView)
            } else if let polyline, let renderer = mapView.renderer(for: polyline) as? MKPolylineRenderer,
                      renderer.strokeColor != route.lineColor || renderer.lineWidth != route.lineWidth {
                renderer.strokeColor = route.lineColor
                renderer.lineWidth = route.lineWidth
                renderer.setNeedsDisplay()
            }
        }

        // MARK: Markers

        private func updateAnnotations(_ markers: [RouteMarker], on mapView: MKMapView) {
            assert(Set(markers.map(\.id)).count == markers.count, "RouteMap: marker IDs must be unique within a route")

            var existing = Dictionary(annotations.map { ($0.marker.id, $0) }, uniquingKeysWith: { first, _ in first })
            var updated: [RouteMarkerAnnotation] = []
            var added: [RouteMarkerAnnotation] = []

            for marker in markers {
                // Reusing the annotation keeps a selected marker selected when the route is rebuilt.
                if let annotation = existing.removeValue(forKey: marker.id) {
                    annotation.update(with: marker)
                    (mapView.view(for: annotation) as? RouteMarkerAnnotationView)?.refresh()
                    updated.append(annotation)
                } else {
                    let annotation = RouteMarkerAnnotation(marker: marker)
                    updated.append(annotation)
                    added.append(annotation)
                }
            }

            if !existing.isEmpty {
                mapView.removeAnnotations(Array(existing.values))
                needsFit = true
            }
            if !added.isEmpty {
                mapView.addAnnotations(added)
                needsFit = true
            }
            annotations = updated
            fitIfNeeded(mapView)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is RouteMarkerAnnotation else { return nil }
            return mapView.dequeueReusableAnnotationView(
                withIdentifier: RouteMarkerAnnotationView.reuseIdentifier,
                for: annotation
            )
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? RouteMarkerAnnotation else { return }
            parent.onSelect(annotation.marker)
        }

        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            guard let annotation = view.annotation as? RouteMarkerAnnotation else { return }
            parent.onDeselect(annotation.marker.id)
        }

        // MARK: Path

        private func reloadPath(for route: Route, on mapView: MKMapView) {
            loader.cancel()
            // Draw a line straight away; directions replace it when they arrive.
            setPath(route.immediateCoordinates, on: mapView)

            guard case .directions(let transportType) = route.path else { return }
            loader.load(waypoints: route.waypoints, transportType: transportType) { [weak self, weak mapView] coordinates in
                guard let self, let mapView else { return }
                self.setPath(coordinates, on: mapView)
            }
        }

        private func setPath(_ coordinates: [CLLocationCoordinate2D], on mapView: MKMapView) {
            if let polyline {
                mapView.removeOverlay(polyline)
            }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            self.polyline = polyline
            mapView.addOverlay(polyline, level: .aboveRoads)
            needsFit = true
            fitIfNeeded(mapView)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = parent.route.lineColor
            renderer.lineWidth = parent.route.lineWidth
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }

        // MARK: Camera

        /// Zooms to show the whole route. Waits until the map has a size, because fitting a zero-sized map does nothing.
        func fitIfNeeded(_ mapView: MKMapView) {
            guard needsFit, let polyline, !mapView.bounds.isEmpty else { return }
            needsFit = false

            var rect = polyline.boundingMapRect
            for annotation in annotations {
                rect = rect.union(MKMapRect(origin: MKMapPoint(annotation.coordinate), size: MKMapSize()))
            }

            if rect.size.width == 0 && rect.size.height == 0 {
                let region = MKCoordinateRegion(
                    center: MKMapPoint(x: rect.midX, y: rect.midY).coordinate,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )
                mapView.setRegion(region, animated: hasFit)
            } else {
                let padding = UIEdgeInsets(top: 56, left: 44, bottom: 44, right: 44)
                mapView.setVisibleMapRect(rect, edgePadding: padding, animated: hasFit)
            }
            hasFit = true
        }
    }
}

/// A map view that reports layout passes, so the route can be fitted once the map has a real size.
final class LayoutReportingMapView: MKMapView {
    var onLayout: ((MKMapView) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?(self)
    }
}

final class RouteMarkerAnnotation: NSObject, MKAnnotation {
    private(set) var marker: RouteMarker
    // `dynamic` so the map moves the icon when the coordinate changes.
    @objc dynamic var coordinate: CLLocationCoordinate2D

    var title: String? { marker.title }

    init(marker: RouteMarker) {
        self.marker = marker
        self.coordinate = marker.coordinate
    }

    func update(with marker: RouteMarker) {
        self.marker = marker
        if coordinate.latitude != marker.coordinate.latitude || coordinate.longitude != marker.coordinate.longitude {
            coordinate = marker.coordinate
        }
    }
}

final class RouteMarkerAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "RouteMarkerAnnotationView"
    private static let diameter: CGFloat = 36

    override var annotation: MKAnnotation? {
        didSet { refresh() }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        // Every icon must stay visible and tappable, even where markers crowd together.
        displayPriority = .required
        collisionMode = .circle
        canShowCallout = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 3
        layer.shadowOffset = CGSize(width: 0, height: 1)
        isAccessibilityElement = true
        accessibilityTraits = .button
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func refresh() {
        guard let marker = (annotation as? RouteMarkerAnnotation)?.marker else { return }
        image = marker.icon.rendered(diameter: Self.diameter)
        accessibilityLabel = marker.title
        accessibilityValue = marker.subtitle
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        let transform = selected ? CGAffineTransform(scaleX: 1.3, y: 1.3) : .identity
        UIView.animate(withDuration: animated ? 0.2 : 0) {
            self.transform = transform
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        transform = .identity
    }
}
