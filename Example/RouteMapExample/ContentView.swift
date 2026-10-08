import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NepalRouteView()
                .tabItem { Label("Standard panel", systemImage: "map") }
            CaliforniaRouteView()
                .tabItem { Label("Custom panel", systemImage: "rectangle.and.pencil.and.ellipsis") }
        }
    }
}
