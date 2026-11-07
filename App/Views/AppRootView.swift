import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            AppPage1View()
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }
            AppPage2View()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            AppPage3View()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
        }
    }
}

#Preview {
    AppRootView()
}