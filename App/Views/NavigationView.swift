import SwiftUI

struct NavigationView<Content: View>: View {
    let content: Content

    @_disfavoredOverload
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