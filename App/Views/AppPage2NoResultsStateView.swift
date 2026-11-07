import SwiftUI

struct AppPage2NoResultsStateView: View {
    var body: some View {
        ContentUnavailableView(
            "没有结果",
            systemImage: "magnifyingglass",
            description: Text("请尝试调整筛选条件或稍后再试。")
        )
    }
}