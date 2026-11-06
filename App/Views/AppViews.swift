import SwiftUI

struct AppViews: View {
    var body: some View {
        HomeView()
    }
}

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Home")
                    .font(.largeTitle)
                NavigationLink("Open Detail") {
                    DetailView()
                }
            }
            .navigationTitle("Home")
        }
    }
}

struct DetailView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Detail")
                .font(.title)
            Text("This is a detail view.")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Detail")
    }
}

struct ListView: View {
    var body: some View {
        List {
            Text("Item 1")
            Text("Item 2")
            Text("Item 3")
        }
        .navigationTitle("List")
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profile")
            .font(.title)
            .navigationTitle("Profile")
    }
}
