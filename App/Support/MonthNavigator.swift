import Foundation
import SwiftUI

struct AppMonthNavigator: View {
    let month: Date
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("上个月"))

            Spacer()

            Text(month, format: .dateTime.month(.wide).year())
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("下个月"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}