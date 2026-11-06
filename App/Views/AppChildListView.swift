import SwiftUI

struct AppChildListView: View {
    @State private var children: [String] = []

    var body: some View {
        List {
            ForEach(children, id: \.self) { name in
                Text(name)
            }
        }
        .navigationTitle("孩子")
        .contentMargins(.bottom, 96, for: .scrollContent)
        .overlay {
            if children.isEmpty {
                ContentUnavailableView(
                    "暂无孩子记录",
                    systemImage: "person.crop.circle.badge.plus",
                    description: Text("点击右上角添加孩子")
                )
            }
        }
    }
}