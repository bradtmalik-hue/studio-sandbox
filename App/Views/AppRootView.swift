import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            AppPage1()
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }
            AppPage2()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            AppPage3()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
        }
    }
}

#Preview {
    AppRootView()
}
