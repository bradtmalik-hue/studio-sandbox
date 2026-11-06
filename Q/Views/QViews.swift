import SwiftUI

struct QMainView: View {
    var body: some View {
        NavigationView {
            QListView()
                .navigationTitle("Main")
        }
    }
}

struct QListView: View {
    var body: some View {
        List {
            NavigationLink(destination: QDetailView()) {
                Text("Item")
            }
        }
    }
}

struct QDetailView: View {
    var body: some View {
        Text("Detail")
    }
}

struct QContentView: View {
    var body: some View {
        QMainView()
    }
}
