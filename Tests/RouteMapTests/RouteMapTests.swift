import CoreLocation
import XCTest
@testable import RouteMap

final class RouteMapTests: XCTestCase {
    private let start = CLLocationCoordinate2D(latitude: 27.7172, longitude: 85.3240)
    private let middle = CLLocationCoordinate2D(latitude: 27.8553, longitude: 84.5580)
    private let end = CLLocationCoordinate2D(latitude: 28.2096, longitude: 83.9856)

    private func makeRoute(path: RoutePath = .straightLine, passesThroughMarkers: Bool = true) -> Route {
        Route(
            origin: .origin(coordinate: start, title: "Start"),
            destination: .destination(coordinate: end, title: "End"),
            markers: [
                RouteMarker(
                    id: "stop",
                    coordinate: middle,
                    title: "Stop",
                    info: [RouteMarkerInfo("Open", "24 hours")],
                    userInfo: ["placeID": 42]
                )
            ],
            path: path,
            passesThroughMarkers: passesThroughMarkers
        )
    }

    func testAllMarkersRunFromOriginToDestination() {
        XCTAssertEqual(makeRoute().allMarkers.map(\.id), ["origin", "stop", "destination"])
    }

    func testMarkerLookupReturnsTheInformationItCarries() {
        let marker = makeRoute().marker(withID: "stop")
        XCTAssertEqual(marker?.info, [RouteMarkerInfo("Open", "24 hours")])
        XCTAssertEqual(marker?.userInfo["placeID"] as? Int, 42)
        XCTAssertNil(makeRoute().marker(withID: "missing"))
    }

    func testWaypointsIncludeMarkersOnlyWhenRoutePassesThroughThem() {
        XCTAssertEqual(makeRoute().waypoints.map(\.latitude), [start.latitude, middle.latitude, end.latitude])
        XCTAssertEqual(
            makeRoute(passesThroughMarkers: false).waypoints.map(\.latitude),
            [start.latitude, end.latitude]
        )
    }

    func testCustomPathIsDrawnAsGiven() {
        let custom = [start, end]
        XCTAssertEqual(makeRoute(path: .custom(custom)).immediateCoordinates.count, 2)
        // A custom path with fewer than two points cannot be drawn, so the waypoints are used instead.
        XCTAssertEqual(makeRoute(path: .custom([start])).immediateCoordinates.count, 3)
    }

    func testGeometryKeyIgnoresChangesThatDoNotMoveTheLine() {
        var renamed = makeRoute()
        renamed.markers[0].title = "Renamed"
        renamed.lineColor = .red
        XCTAssertEqual(renamed.geometryKey, makeRoute().geometryKey)

        var moved = makeRoute()
        moved.markers[0].coordinate.latitude += 0.1
        XCTAssertNotEqual(moved.geometryKey, makeRoute().geometryKey)
        XCTAssertNotEqual(makeRoute(path: .directions(.walking)).geometryKey, makeRoute().geometryKey)
    }

    func testJoinDropsThePointSharedByConsecutiveLegs() {
        let joined = RouteGeometry.join([[start, middle], [middle, end]])
        XCTAssertEqual(joined.map(\.latitude), [start.latitude, middle.latitude, end.latitude])
    }

    func testIconRendersAtTheRequestedSize() {
        let image = RouteMarkerIcon.system("fuelpump.fill").rendered(diameter: 36)
        XCTAssertEqual(image.size, CGSize(width: 36, height: 36))
    }
}
