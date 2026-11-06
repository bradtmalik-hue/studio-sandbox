import SwiftUI

struct ContentView: View {
    var body: some View {
        SwiftUI.NavigationView {
            List {
                Text("Hello, world!")
            }
            .navigationTitle("App")
        }
    }
}

struct PlaceholderView: View {
    var body: some View {
        Text("Placeholder")
    }
}

extension DemoSeed {
    static func apply() {
    }
}