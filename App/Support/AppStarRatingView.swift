import SwiftUI
import Foundation

struct AppStarRatingView: View {
    @Binding private var rating: Double
    let maxRating: Int
    let allowsHalfStars: Bool
    let starSize: CGFloat
    let spacing: CGFloat

    init(rating: Binding<Double>, maxRating: Int = 5, allowsHalfStars: Bool = true, starSize: CGFloat = 32, spacing: CGFloat = 6) {
        self._rating = rating
        self.maxRating = max(1, maxRating)
        self.allowsHalfStars = allowsHalfStars
        self.starSize = starSize
        self.spacing = spacing
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<maxRating, id: \.self) { index in
                starView(for: index)
            }
        }
        .frame(width: totalWidth, height: starSize)
        .overlay(
            GeometryReader { geometry in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateRating(at: value.location, in: geometry.size)
                            }
                            .onEnded { value in
                                updateRating(at: value.location, in: geometry.size)
                            }
                    )
            }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("星级评分")
        .accessibilityValue(String(format: "%.1f / %d", rating, maxRating))
        .sensoryFeedback(.selection, trigger: rating) { oldValue, newValue in
            newValue != oldValue
        }
    }

    private var totalWidth: CGFloat {
        CGFloat(maxRating) * starSize + CGFloat(maxRating - 1) * spacing
    }

    @ViewBuilder
    private func starView(for index: Int) -> some View {
        if rating >= Double(index) + 1.0 {
            starSymbol(filled: true)
        } else if allowsHalfStars && rating >= Double(index) + 0.5 {
            ZStack {
                starSymbol(filled: false)
                starSymbol(filled: true)
                    .mask(
                        GeometryReader { geometry in
                            Rectangle()
                                .frame(width: geometry.size.width / 2, height: geometry.size.height)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        }
                    )
            }
        } else {
            starSymbol(filled: false)
        }
    }

    private func starSymbol(filled: Bool) -> some View {
        Image(systemName: filled ? "star.fill" : "star")
            .resizable()
            .scaledToFit()
            .foregroundStyle(filled ? Color.yellow : Color.gray)
    }

    private func updateRating(at location: CGPoint, in size: CGSize) {
        guard size.width > 0 else { return }

        let x = min(max(location.x, 0), size.width)
        let segment = starSize + spacing
        let index = min(Int(x / segment), maxRating - 1)
        let offsetInSegment = x - CGFloat(index) * segment

        let value: Double
        if offsetInSegment <= starSize {
            if allowsHalfStars {
                value = Double(index) + (offsetInSegment > starSize / 2 ? 1.0 : 0.5)
            } else {
                value = Double(index) + 1.0
            }
        } else {
            value = Double(index) + 1.0
        }

        rating = min(Double(maxRating), max(0, value))
    }
}