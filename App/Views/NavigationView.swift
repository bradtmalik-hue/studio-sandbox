import SwiftUI

struct NavigationView: View {
    private let content: AnyView

    init() {
        self.content = AnyView(EmptyView())
    }

    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }

    var body: some View {
        content
    }
}