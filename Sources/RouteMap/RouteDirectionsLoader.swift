import CoreLocation
import MapKit

/// Loads directions leg by leg through a list of waypoints and joins them into a single line.
final class RouteDirectionsLoader {
    private var requests: [MKDirections] = []
    private var generation = 0

    func cancel() {
        generation += 1
        requests.forEach { $0.cancel() }
        requests = []
    }

    /// Cancels any earlier load. `completion` runs on the main queue, and never for a cancelled load.
    func load(
        waypoints: [CLLocationCoordinate2D],
        transportType: MKDirectionsTransportType,
        completion: @escaping ([CLLocationCoordinate2D]) -> Void
    ) {
        cancel()
        let generation = self.generation
        let legs = Array(zip(waypoints, waypoints.dropFirst()))
        // Every leg starts as a straight line and is replaced if its directions load.
        var results = legs.map { [$0.0, $0.1] }
        let group = DispatchGroup()

        for (index, leg) in legs.enumerated() {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: leg.0))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: leg.1))
            request.transportType = transportType

            let directions = MKDirections(request: request)
            requests.append(directions)
            group.enter()
            // MKDirections calls back on the main thread, so `results` is never touched concurrently.
            directions.calculate { response, _ in
                if let polyline = response?.routes.first?.polyline, polyline.pointCount >= 2 {
                    results[index] = polyline.coordinates
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self, self.generation == generation else { return }
            self.requests = []
            completion(RouteGeometry.join(results))
        }
    }
}

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        return coordinates
    }
}
