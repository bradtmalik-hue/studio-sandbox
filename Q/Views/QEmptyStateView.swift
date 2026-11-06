import SwiftUI

struct QEmptyStateView: View {
    var body: some View {
        ContentUnavailableView(
            "暂无内容",
            systemImage: "tray",
            description: Text("点击按钮开始添加记录")
        )
    }
}