import SwiftUI

private enum AppRootTab: String {
    case beans
    case brew
    case history

    var title: String {
        switch self {
        case .beans: return "豆子库"
        case .brew: return "冲煮"
        case .history: return "参数历史"
        }
    }

    var icon: String {
        switch self {
        case .beans: return "bag.fill"
        case .brew: return "cup.and.saucer.fill"
        case .history: return "clock.arrow.circlepath"
        }
    }
}

struct AppRootView: View {
    @StateObject private var beanStore = AppBeanStore()
    @StateObject private var brewStore = AppBrewStore()
    @State private var selectedTab: AppRootTab = .beans

    var body: some View {
        VStack(spacing: 0) {
            activeView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            AppRootTabBar(selectedTab: $selectedTab)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private var activeView: some View {
        switch selectedTab {
        case .beans:
            AppBeanLibraryView()
                .environmentObject(beanStore)
                .environmentObject(brewStore)
        case .brew:
            AppBrewLogView()
                .environmentObject(beanStore)
                .environmentObject(brewStore)
        case .history:
            AppBrewHistoryView()
                .environmentObject(beanStore)
                .environmentObject(brewStore)
        }
    }
}

private struct AppRootTabBar: View {
    @Binding var selectedTab: AppRootTab

    var body: some View {
        HStack(spacing: 8) {
            tabButton(for: .beans)
            tabButton(for: .brew)
            tabButton(for: .history)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func tabButton(for tab: AppRootTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(tab.title)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(selectedTab == tab ? Color.primary : Color.secondary)
            .background(selectedTab == tab ? Color(uiColor: .secondarySystemFill) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityValue(selectedTab == tab ? "已选中" : "未选中")
    }
}