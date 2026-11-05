import SwiftUI

struct AppStarRatingView: View {
    @Binding var rating: Int
    var maxRating: Int = 5
    var starSize: CGFloat = 30
    var activeColor: Color = Color(white: 0.12)
    var inactiveColor: Color = Color(white: 0.72)

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...maxRating, id: \.self) { star in
                Button {
                    rating = star
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: starSize))
                        .foregroundStyle(star <= rating ? activeColor : inactiveColor)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(star) 星\(star <= rating ? "，已选中" : "")")
                .accessibilityValue(star <= rating ? "已选中" : "未选中")
            }
        }
        .animation(.easeInOut(duration: 0.15), value: rating)
    }
}