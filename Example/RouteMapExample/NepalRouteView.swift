import CoreLocation
import RouteMap
import SwiftUI

/// Kathmandu to Pokhara with the standard info panel. Apple Maps has no directions in Nepal,
/// so the line falls back to straight segments between the icons.
struct NepalRouteView: View {
    @State private var lastTapped = "Nothing tapped yet"

    private let route = Route(
        origin: .origin(
            coordinate: CLLocationCoordinate2D(latitude: 27.7172, longitude: 85.3240),
            title: "Kathmandu",
            subtitle: "Starting point",
            info: [RouteMarkerInfo("Departure", "7:00 AM")]
        ),
        destination: .destination(
            coordinate: CLLocationCoordinate2D(latitude: 28.2096, longitude: 83.9856),
            title: "Pokhara",
            subtitle: "Destination",
            info: [RouteMarkerInfo("Arrival", "2:30 PM")]
        ),
        markers: [
            RouteMarker(
                id: "fuel-naubise",
                coordinate: CLLocationCoordinate2D(latitude: 27.7270, longitude: 85.1230),
                title: "Naubise Fuel Station",
                subtitle: "Petrol and diesel",
                icon: .system("fuelpump.fill", backgroundColor: .systemOrange),
                info: [
                    RouteMarkerInfo("Open", "24 hours"),
                    RouteMarkerInfo("Distance from start", "26 km")
                ],
                userInfo: ["stationID": 101]
            ),
            RouteMarker(
                id: "lunch-mugling",
                coordinate: CLLocationCoordinate2D(latitude: 27.8553, longitude: 84.5580),
                title: "Mugling Highway Restaurant",
                subtitle: "Lunch stop",
                icon: .system("fork.knife", backgroundColor: .systemPurple),
                info: [
                    RouteMarkerInfo("Stop", "45 minutes"),
                    RouteMarkerInfo("Known for", "Dal bhat and fresh fish")
                ],
                userInfo: ["restaurantID": 202]
            ),
            RouteMarker(
                id: "view-bandipur",
                coordinate: CLLocationCoordinate2D(latitude: 27.9700, longitude: 84.4100),
                title: "Dumre Viewpoint",
                subtitle: "Turn-off for Bandipur",
                icon: .system("camera.fill", backgroundColor: .systemTeal),
                info: [RouteMarkerInfo("Best for", "Himalaya views on a clear day")],
                userInfo: ["poiID": 303]
            )
        ]
    )

    var body: some View {
        VStack(spacing: 0) {
            Text(lastTapped)
                .font(.footnote)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color(.secondarySystemBackground))

            RouteMapView(route: route) { marker in
                // The callback receives the whole marker, including the payload in `userInfo`.
                lastTapped = "Callback: \(marker.title), userInfo \(marker.userInfo)"
            }
        }
    }
}
