import CoreLocation
import RouteMap
import SwiftUI

/// San Francisco to San Jose with real driving directions and a custom panel below the map.
struct CaliforniaRouteView: View {
    @State private var tapCount = 0

    private let route = Route(
        origin: .origin(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            title: "San Francisco",
            userInfo: ["kind": "City"]
        ),
        destination: .destination(
            coordinate: CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863),
            title: "San Jose",
            userInfo: ["kind": "City"]
        ),
        markers: [
            RouteMarker(
                id: "coffee-san-mateo",
                coordinate: CLLocationCoordinate2D(latitude: 37.5630, longitude: -122.3255),
                title: "San Mateo Coffee Stop",
                icon: .system("cup.and.saucer.fill", backgroundColor: .brown),
                info: [RouteMarkerInfo("Stop", "15 minutes")],
                userInfo: ["kind": "Cafe", "rating": 4.6]
            ),
            RouteMarker(
                id: "charger-palo-alto",
                coordinate: CLLocationCoordinate2D(latitude: 37.4419, longitude: -122.1430),
                title: "Palo Alto Charger",
                icon: .system("bolt.car.fill", backgroundColor: .systemIndigo),
                info: [
                    RouteMarkerInfo("Chargers", "8 free"),
                    RouteMarkerInfo("Power", "150 kW")
                ],
                userInfo: ["kind": "Charger", "rating": 4.2]
            )
        ],
        path: .directions(.automobile),
        lineColor: .systemIndigo
    )

    var body: some View {
        RouteMapView(
            route: route,
            placeholder: "Tap an icon. Taps so far: \(tapCount)",
            onMarkerTap: { _ in tapCount += 1 }
        ) { marker in
            // Your own view for the tapped marker, built from anything the marker carries.
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(marker.title)
                        .font(.title3.bold())
                    Spacer()
                    if let kind = marker.userInfo["kind"] as? String {
                        Text(kind)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(marker.icon.backgroundColor).opacity(0.2)))
                    }
                }
                if let rating = marker.userInfo["rating"] as? Double {
                    Label(String(format: "%.1f", rating), systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                ForEach(marker.info, id: \.self) { item in
                    Text("\(item.label): \(item.value)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}
