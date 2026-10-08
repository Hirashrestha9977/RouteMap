# RouteMap

An iOS framework (Swift Package, iOS 14+) that shows a route from one place to another with any number of
tappable icons along it. Tapping an icon calls you back with the information the icon carries and shows that
information below the map.

## Install

In Xcode: **File > Add Package Dependencies… > Add Local…** and pick this folder (or use the repository URL once
it is hosted), then add the `RouteMap` library to your app target.

## Usage

```swift
import CoreLocation
import RouteMap
import SwiftUI

let route = Route(
    origin: .origin(
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        title: "San Francisco"
    ),
    destination: .destination(
        coordinate: CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863),
        title: "San Jose"
    ),
    markers: [
        RouteMarker(
            id: "charger-palo-alto",
            coordinate: CLLocationCoordinate2D(latitude: 37.4419, longitude: -122.1430),
            title: "Palo Alto Supercharger",
            subtitle: "Fast charging",
            icon: .system("bolt.car.fill", backgroundColor: .systemIndigo),
            info: [RouteMarkerInfo("Chargers", "8 free")],   // shown below the map
            userInfo: ["chargerID": 42]                      // returned in the callback only
        )
    ]
)

RouteMapView(route: route) { marker in
    print(marker.title, marker.info, marker.userInfo)
}
```

- **Icons**: `.system("sf.symbol.name", tintColor:backgroundColor:)` or `RouteMarkerIcon(image: yourUIImage)`.
- **Marker IDs** must be unique within a route and stay the same between updates.
- **Custom panel**: pass a trailing view builder to replace the standard panel:
  `RouteMapView(route: route, onMarkerTap: { … }) { marker in MyPanel(marker) }`.
- **UIKit**: `RouteMapViewController(route: route) { marker in … }`.

## The route line

`Route.path` controls how the line is drawn:

| Path | Line |
| --- | --- |
| `.directions(.automobile)` (default) | Apple Maps directions, routed through each marker in order |
| `.straightLine` | Straight segments between the points |
| `.custom([CLLocationCoordinate2D])` | A line you supply, such as one from your own routing service |

Apple Maps has no directions in some regions (Nepal, for example). There, and when offline, `.directions` draws
straight segments instead; use `.custom` if you need a road-following line in those regions.

Set `passesThroughMarkers: false` when markers are only near the route and the line should go directly from the
origin to the destination.

## Example app

Open `Example/RouteMapExample.xcodeproj` and run the `RouteMapExample` scheme on a simulator. It uses this
folder as a local package, so changes to the framework are picked up straight away. The first tab shows the
standard info panel; the second shows real driving directions with a custom panel.
