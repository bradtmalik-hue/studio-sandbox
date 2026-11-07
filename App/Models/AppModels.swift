import Foundation
import SwiftUI

struct AppPage1Model: Identifiable, Codable {
    let id: UUID
    let title: String
    let subtitle: String
    let value: Double
    let unit: String
    let icon: String
    let date: Date
}

struct AppPage2Model: Identifiable, Codable {
    let id: UUID
    let name: String
    let detail: String
    let amount: Double
    let category: String
    let timestamp: Date
}

struct AppPage3Model: Identifiable, Codable {
    let id: UUID
    let header: String
    let body: String
    let badge: String
    let isActive: Bool
    let createdAt: Date
}

struct AppChartPoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
}

struct AppStyle {
    let name: String
    let strokeColor: Color
    let lineWidth: CGFloat
    let dash: [CGFloat]
}

extension AppStyle {
    static let allStyles: [AppStyle] = [
        AppStyle(name: "默认", strokeColor: .blue, lineWidth: 2, dash: []),
        AppStyle(name: "虚线", strokeColor: .green, lineWidth: 2, dash: [6, 3])
    ]

    static var defaultStyle: AppStyle? {
        guard let first = allStyles.first else { return nil }
        return first
    }
}

enum AppCategory: String, CaseIterable {
    case health
    case work
    case travel
    case food
}

struct AppSummary: Codable {
    let items: [AppPage2Model]

    func firstItem() -> AppPage2Model? {
        guard !items.isEmpty else { return nil }
        return items[0]
    }
}