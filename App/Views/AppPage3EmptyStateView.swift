import SwiftUI

struct AppPage3EmptyStateView: View {
    private var isChinese: Bool {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return code == "zh"
    }

    var body: some View {
        ContentUnavailableView {
            Label(
                isChinese ? "暂无数据" : "No Data",
                systemImage: "chart.bar.doc.horizontal"
            )
        } description: {
            Text(isChinese ? "这里还没有统计内容，去添加一些记录吧。" : "No statistics yet. Add some records to get started.")
        }
    }
}

#Preview {
    AppPage3EmptyStateView()
}