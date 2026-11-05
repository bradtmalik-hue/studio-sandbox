import SwiftUI

enum AppPalette {
    // MARK: - Colors
    static let background = Color.white
    static let primary = Color(red: 0.05, green: 0.20, blue: 0.16)
    static let primaryDark = Color(red: 0.03, green: 0.14, blue: 0.11)
    static let primaryLight = Color(red: 0.85, green: 0.93, blue: 0.89)
    static let ink = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let secondaryText = Color(red: 0.40, green: 0.42, blue: 0.45)
    static let divider = Color(red: 0.92, green: 0.93, blue: 0.94)

    // MARK: - Typography
    static let heroTitle = Font.system(size: 34, weight: .heavy, design: .default)
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let title = Font.system(size: 22, weight: .semibold, design: .default)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let callout = Font.system(size: 14, weight: .regular, design: .default)
    static let footnote = Font.system(size: 12, weight: .regular, design: .default)
    static let caption = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - Layout
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 10
    static let cardPadding: CGFloat = 16
    static let screenPadding: CGFloat = 20
}

extension View {
    func appBackground() -> some View {
        self.background(AppPalette.background)
    }

    func appCardStyle() -> some View {
        self
            .padding(AppPalette.cardPadding)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppPalette.cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    func appPrimaryButtonStyle() -> some View {
        self
            .font(AppPalette.headline)
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(AppPalette.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppPalette.smallCornerRadius, style: .continuous))
    }

    func appHeroTitleStyle() -> some View {
        self
            .font(AppPalette.heroTitle)
            .foregroundColor(AppPalette.ink)
    }
}