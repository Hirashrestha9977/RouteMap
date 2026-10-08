import SwiftUI
import UIKit

/// UIKit wrapper around `RouteMapView`, for apps that do not use SwiftUI.
public final class RouteMapViewController: UIHostingController<RouteMapView<RouteMarkerInfoView>> {
    public var route: Route {
        didSet { rootView = makeRootView() }
    }

    /// Called with the tapped marker, including its `info` and `userInfo`.
    public var onMarkerTap: ((RouteMarker) -> Void)?

    public init(route: Route, onMarkerTap: ((RouteMarker) -> Void)? = nil) {
        self.route = route
        self.onMarkerTap = onMarkerTap
        super.init(rootView: RouteMapView(route: route))
        // The callback needs `self`, which is only available after `super.init`.
        rootView = makeRootView()
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func makeRootView() -> RouteMapView<RouteMarkerInfoView> {
        RouteMapView(route: route) { [weak self] marker in
            self?.onMarkerTap?(marker)
        }
    }
}
