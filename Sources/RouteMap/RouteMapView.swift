import SwiftUI

/// A map showing a route with tappable icons, and the tapped icon's information below it.
///
/// Tapping an icon calls `onMarkerTap` with the marker, including its `info` and `userInfo`,
/// and shows the marker's information under the map.
public struct RouteMapView<InfoContent: View>: View {
    private let route: Route
    private let placeholder: String
    private let onMarkerTap: (RouteMarker) -> Void
    private let infoContent: (RouteMarker) -> InfoContent

    @State private var selectedMarkerID: RouteMarker.ID?

    /// Creates a route map that shows your own view below the map for the tapped marker.
    public init(
        route: Route,
        placeholder: String = "Tap an icon on the route to see its details",
        onMarkerTap: @escaping (RouteMarker) -> Void = { _ in },
        @ViewBuilder infoContent: @escaping (RouteMarker) -> InfoContent
    ) {
        self.route = route
        self.placeholder = placeholder
        self.onMarkerTap = onMarkerTap
        self.infoContent = infoContent
    }

    public var body: some View {
        VStack(spacing: 0) {
            RouteMapRepresentable(
                route: route,
                onSelect: { marker in
                    selectedMarkerID = marker.id
                    onMarkerTap(marker)
                },
                onDeselect: { id in
                    if selectedMarkerID == id {
                        selectedMarkerID = nil
                    }
                }
            )
            Divider()
            infoPanel
        }
    }

    @ViewBuilder
    private var infoPanel: some View {
        // Looked up from the current route, so the panel never shows a marker that has been removed.
        if let marker = selectedMarkerID.flatMap(route.marker(withID:)) {
            infoContent(marker)
        } else {
            Text(placeholder)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding()
        }
    }
}

extension RouteMapView where InfoContent == RouteMarkerInfoView {
    /// Creates a route map that shows the standard information panel below the map.
    public init(
        route: Route,
        placeholder: String = "Tap an icon on the route to see its details",
        onMarkerTap: @escaping (RouteMarker) -> Void = { _ in }
    ) {
        self.init(route: route, placeholder: placeholder, onMarkerTap: onMarkerTap) { marker in
            RouteMarkerInfoView(marker: marker)
        }
    }
}

/// The standard panel shown below the map: the marker's icon, title, subtitle and information rows.
public struct RouteMarkerInfoView: View {
    private let marker: RouteMarker

    public init(marker: RouteMarker) {
        self.marker = marker
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(uiImage: marker.icon.rendered(diameter: 40))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(marker.title)
                        .font(.headline)
                    if let subtitle = marker.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            ForEach(Array(marker.info.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline) {
                    Text(item.label)
                        .foregroundColor(.secondary)
                    Spacer(minLength: 16)
                    Text(item.value)
                        .multilineTextAlignment(.trailing)
                }
                .font(.subheadline)
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}
