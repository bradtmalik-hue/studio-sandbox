import SwiftUI

struct NavigationView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    init() where Content == EmptyView {
        self.content = EmptyView()
    }

    var body: some View {
        NavigationStack {
            content
        }
    }
}