import SwiftUI

struct AppPage2HistoryEmptyView: View {
    private var isChinese: Bool {
        Locale.current.language.languageCode?.identifier.hasPrefix("zh") == true
    }

    var body: some View {
        ContentUnavailableView(
            isChinese ? "暂无历史记录" : "No History Yet",
            systemImage: "clock.arrow.circlepath",
            description: Text(isChinese ? "完成第一条记录后，这里会显示你的历史。" : "Your history will appear here after you complete your first entry.")
        )
    }
}