import CoreLocation
import UIKit

/// One labelled row of information shown below the map when a marker is tapped.
public struct RouteMarkerInfo: Hashable {
    public var label: String
    public var value: String

    public init(_ label: String, _ value: String) {
        self.label = label
        self.value = value
    }
}

/// The icon drawn on the map for a marker: a glyph centred on a coloured circle.
public struct RouteMarkerIcon {
    /// The glyph. SF Symbols and template images are tinted with `tintColor`; other images keep their own colours.
    public var image: UIImage?
    public var tintColor: UIColor
    public var backgroundColor: UIColor

    public init(image: UIImage?, tintColor: UIColor = .white, backgroundColor: UIColor = .systemBlue) {
        self.image = image
        self.tintColor = tintColor
        self.backgroundColor = backgroundColor
    }

    /// An icon that uses an SF Symbol as its glyph.
    public static func system(
        _ name: String,
        tintColor: UIColor = .white,
        backgroundColor: UIColor = .systemBlue
    ) -> RouteMarkerIcon {
        RouteMarkerIcon(image: UIImage(systemName: name), tintColor: tintColor, backgroundColor: backgroundColor)
    }
}

/// A tappable icon on the route, together with the information it carries.
public struct RouteMarker: Identifiable {
    /// Must be unique within a route and stable across updates, so a selected marker stays selected.
    public let id: String
    public var coordinate: CLLocationCoordinate2D
    public var title: String
    public var subtitle: String?
    public var icon: RouteMarkerIcon
    /// Rows displayed below the map when this marker is tapped.
    public var info: [RouteMarkerInfo]
    /// Any extra payload to get back in the tap callback. It is never displayed.
    public var userInfo: [String: Any]

    public init(
        id: String,
        coordinate: CLLocationCoordinate2D,
        title: String,
        subtitle: String? = nil,
        icon: RouteMarkerIcon = .system("mappin"),
        info: [RouteMarkerInfo] = [],
        userInfo: [String: Any] = [:]
    ) {
        self.id = id
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.info = info
        self.userInfo = userInfo
    }

    /// A marker with the default start icon.
    public static func origin(
        id: String = "origin",
        coordinate: CLLocationCoordinate2D,
        title: String,
        subtitle: String? = nil,
        info: [RouteMarkerInfo] = [],
        userInfo: [String: Any] = [:]
    ) -> RouteMarker {
        RouteMarker(
            id: id,
            coordinate: coordinate,
            title: title,
            subtitle: subtitle,
            icon: .system("location.fill", backgroundColor: .systemGreen),
            info: info,
            userInfo: userInfo
        )
    }

    /// A marker with the default finish icon.
    public static func destination(
        id: String = "destination",
        coordinate: CLLocationCoordinate2D,
        title: String,
        subtitle: String? = nil,
        info: [RouteMarkerInfo] = [],
        userInfo: [String: Any] = [:]
    ) -> RouteMarker {
        RouteMarker(
            id: id,
            coordinate: coordinate,
            title: title,
            subtitle: subtitle,
            icon: .system("flag.fill", backgroundColor: .systemRed),
            info: info,
            userInfo: userInfo
        )
    }
}

extension RouteMarkerIcon {
    /// Draws the icon as a circular badge. The map and the info panel both use this, so they always match.
    func rendered(diameter: CGFloat) -> UIImage {
        let size = CGSize(width: diameter, height: diameter)
        return UIGraphicsImageRenderer(size: size).image { _ in
            let borderWidth: CGFloat = 2
            let circle = UIBezierPath(
                ovalIn: CGRect(origin: .zero, size: size).insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
            )
            backgroundColor.setFill()
            circle.fill()
            UIColor.white.setStroke()
            circle.lineWidth = borderWidth
            circle.stroke()

            guard var glyph = image else { return }
            if glyph.isSymbolImage {
                let configuration = UIImage.SymbolConfiguration(pointSize: diameter * 0.45, weight: .semibold)
                glyph = glyph.applyingSymbolConfiguration(configuration) ?? glyph
            }
            let isTintable = glyph.isSymbolImage || glyph.renderingMode == .alwaysTemplate
            if isTintable && glyph.renderingMode != .alwaysOriginal {
                glyph = glyph.withTintColor(tintColor, renderingMode: .alwaysOriginal)
            }

            let longestSide = max(glyph.size.width, glyph.size.height)
            guard longestSide > 0 else { return }
            let fitScale = diameter * 0.62 / longestSide
            // Symbols are already sized for the badge; only shrink them if they overflow.
            let scale = glyph.isSymbolImage ? min(1, fitScale) : fitScale
            let glyphSize = CGSize(width: glyph.size.width * scale, height: glyph.size.height * scale)
            glyph.draw(in: CGRect(
                x: (diameter - glyphSize.width) / 2,
                y: (diameter - glyphSize.height) / 2,
                width: glyphSize.width,
                height: glyphSize.height
            ))
        }
    }
}
