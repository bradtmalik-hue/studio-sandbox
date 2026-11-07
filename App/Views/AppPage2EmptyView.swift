import SwiftUI

struct AppPage2EmptyView: View {
    var body: some View {
        ContentUnavailableView {
            Label("暂无内容", systemImage: "tray")
        } description: {
            Text("这里还没有任何记录")
        }
    }
}