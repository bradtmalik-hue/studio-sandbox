import SwiftUI

struct ContentView<Content: View>: View {
    var store: AppMealStore
    var content: Content

    init(store: AppMealStore, content: Content) {
        self.store = store
        self.content = content
    }

    var body: some View {
        content
    }
}