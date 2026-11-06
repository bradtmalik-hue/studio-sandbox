import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationView {
                Text("Home")
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            NavigationView {
                Text("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}
