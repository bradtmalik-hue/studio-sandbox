import SwiftUI

struct AppPage2NoResultsView: View {
    var body: some View {
        ContentUnavailableView(
            "没有结果",
            systemImage: "magnifyingglass",
            description: Text("没有找到匹配的内容")
        )
    }
}