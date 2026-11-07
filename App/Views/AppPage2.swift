import SwiftUI

struct AppPage2View: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("暂无数据", systemImage: "tray")
                .navigationTitle("页面二")
        }
    }
}

#Preview {
    AppPage2View()
}
