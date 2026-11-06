import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
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