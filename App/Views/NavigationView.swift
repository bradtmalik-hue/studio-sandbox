import SwiftUI

struct NavigationView<Content: View>: View {
    private let content: Content

    init() where Content == EmptyView {
        self.content = EmptyView()
    }

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            content
        }
    }
}