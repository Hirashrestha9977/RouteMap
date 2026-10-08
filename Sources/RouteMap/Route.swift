import CoreLocation
import MapKit
import UIKit

/// How the line between the origin and the destination is produced.
public enum RoutePath {
    /// Real directions from Apple Maps. Falls back to straight lines for any leg that cannot be loaded.
    case directions(MKDirectionsTransportType)
    /// Straight lines between the points.
    case straightLine
    /// A line you supply yourself, for example one decoded from your own routing backend.
    case custom([CLLocationCoordinate2D])
}

/// A route from one place to another, with any number of tappable markers along it.
public struct Route {
    public var origin: RouteMarker
    public var destination: RouteMarker
    /// Markers between the origin and the destination, in travel order.
    public var markers: [RouteMarker]
    public var path: RoutePath
    /// When `true` the line is routed through every marker in order, so each icon sits on the path.
    /// Set it to `false` for markers that are only near the route. Ignored for `.custom` paths.
    public var passesThroughMarkers: Bool
    public var lineColor: UIColor
    public var lineWidth: CGFloat

    public init(
        origin: RouteMarker,
        destination: RouteMarker,
        markers: [RouteMarker] = [],
        path: RoutePath = .directions(.automobile),
        passesThroughMarkers: Bool = true,
        lineColor: UIColor = .systemBlue,
        lineWidth: CGFloat = 5
    ) {
        self.origin = origin
        self.destination = destination
        self.markers = markers
        self.path = path
        self.passesThroughMarkers = passesThroughMarkers
        self.lineColor = lineColor
        self.lineWidth = lineWidth
    }

    /// Every marker on the map: the origin, the markers in between, then the destination.
    public var allMarkers: [RouteMarker] {
        [origin] + markers + [destination]
    }

    public func marker(withID id: RouteMarker.ID) -> RouteMarker? {
        allMarkers.first { $0.id == id }
    }
}

extension Route {
    /// The points the line has to connect, in order.
    var waypoints: [CLLocationCoordinate2D] {
        let stops = passesThroughMarkers ? markers.map(\.coordinate) : []
        return [origin.coordinate] + stops + [destination.coordinate]
    }

    /// The line that can be drawn immediately, before any directions have loaded.
    var immediateCoordinates: [CLLocationCoordinate2D] {
        if case .custom(let coordinates) = path, coordinates.count >= 2 {
            return coordinates
        }
        return waypoints
    }

    /// Identifies the shape of the line, so it is only recomputed when something that affects it changes.
    var geometryKey: RouteGeometryKey {
        let mode: String
        var points = waypoints
        switch path {
        case .directions(let transportType):
            mode = "directions-\(transportType.rawValue)"
        case .straightLine:
            mode = "straight"
        case .custom(let coordinates):
            mode = "custom"
            points = coordinates
        }
        return RouteGeometryKey(mode: mode, points: points.map { [$0.latitude, $0.longitude] })
    }
}

struct RouteGeometryKey: Equatable {
    let mode: String
    let points: [[Double]]
}

enum RouteGeometry {
    /// Joins consecutive legs into one line, dropping the point repeated where two legs meet.
    static func join(_ legs: [[CLLocationCoordinate2D]]) -> [CLLocationCoordinate2D] {
        var joined: [CLLocationCoordinate2D] = []
        for leg in legs {
            for coordinate in leg {
                if let last = joined.last,
                   last.latitude == coordinate.latitude,
                   last.longitude == coordinate.longitude {
                    continue
                }
                joined.append(coordinate)
            }
        }
        return joined
    }
}
