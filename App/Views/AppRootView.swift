import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppFilmLibraryStore()
    @State private var selectedTab: AppRootTab = .record

    var body: some View {
        ZStack(alignment: .bottom) {
            currentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            AppFilmTabBar(selection: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .background(
            Color(red: 0.09, green: 0.08, blue: 0.07)
                .ignoresSafeArea()
        )
        .environmentObject(store)
    }

    @ViewBuilder
    private var currentView: some View {
        switch selectedTab {
        case .record:
            RecordFilmView()
        case .list:
            FilmListView()
        case .stats:
            YearStatsView()
        }
    }
}

private enum AppRootTab: String, CaseIterable, Identifiable {
    case record
    case list
    case stats

    var id: String { rawValue }

    var title: String {
        switch self {
        case .record:
            return "记一部"
        case .list:
            return "观影列表"
        case .stats:
            return "年度统计"
        }
    }

    var icon: String {
        switch self {
        case .record:
            return "plus.circle.fill"
        case .list:
            return "list.bullet"
        case .stats:
            return "chart.bar.fill"
        }
    }
}

private struct AppFilmTabBar: View {
    @Binding var selection: AppRootTab

    private let perforations = Array(0..<7)

    var body: some View {
        VStack(spacing: 6) {
            perforationRow

            HStack(spacing: 0) {
                ForEach(AppRootTab.allCases) { tab in
                    Button {
                        selection = tab
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18, weight: .semibold))

                            Text(tab.title)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(selection == tab ? Color.white : Color.white.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selection == tab ? Color.white.opacity(0.14) : Color.clear)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red: 0.13, green: 0.12, blue: 0.11))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )

            perforationRow
        }
    }

    private var perforationRow: some View {
        HStack(spacing: 8) {
            ForEach(perforations, id: \.self) { _ in
                Capsule()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 12, height: 3)
            }
        }
    }
}