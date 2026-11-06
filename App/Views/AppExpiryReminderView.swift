import SwiftUI

struct AppExpiryReminderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "暂无过期提醒",
                systemImage: "checkmark.circle",
                description: Text("所有物品都在保质期内")
            )
            .navigationTitle("过期提醒")
        }
    }
}