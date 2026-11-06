import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            List {
                Text("Home")
            }
            .navigationTitle("Home")
        }
    }
}

struct FavoritesView: View {
    var body: some View {
        NavigationView {
            List {
                Text("Favorites")
            }
            .navigationTitle("Favorites")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Text("Settings")
            }
            .navigationTitle("Settings")
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationView {
            List {
                Text("Profile")
            }
            .navigationTitle("Profile")
        }
    }
}

struct SearchView: View {
    var body: some View {
        NavigationView {
            List {
                Text("Search")
            }
            .navigationTitle("Search")
        }
    }
}

struct HistoryView: View {
    var body: some View {
        NavigationView {
            List {
                Text("History")
            }
            .navigationTitle("History")
        }
    }
}

struct DownloadsView: View {
    var body: some View {
        NavigationView {
            List {
                Text("Downloads")
            }
            .navigationTitle("Downloads")
        }
    }
}

struct NotificationsView: View {
    var body: some View {
        NavigationView {
            List {
                Text("Notifications")
            }
            .navigationTitle("Notifications")
        }
    }
}

struct DetailView: View {
    var body: some View {
        VStack {
            Text("Detail")
        }
        .navigationTitle("Detail")
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}