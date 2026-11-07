import SwiftUI

struct AppPage2EmptyView: View {
    var body: some View {
        ContentUnavailableView {
            Label("暂无数据", systemImage: "tray")
        } description: {
            Text("这里还没有内容")
        }
    }
}