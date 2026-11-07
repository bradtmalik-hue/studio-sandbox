import SwiftUI
import Foundation

struct AppPage3EmptyView: View {
    private var isChinese: Bool {
        Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
    }

    var body: some View {
        ContentUnavailableView {
            Label(isChinese ? "暂无内容" : "No Content", systemImage: "tray")
        } description: {
            Text(isChinese ? "这里还没有数据显示，请稍后再来看看。" : "Nothing to show here yet. Check back later.")
        }
    }
}