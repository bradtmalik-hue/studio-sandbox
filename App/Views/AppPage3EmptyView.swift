import SwiftUI

struct AppPage3EmptyView: View {
    var body: some View {
        ContentUnavailableView(
            "暂无内容",
            systemImage: "tray",
            description: Text("这里还没有内容")
        )
    }
}