import Foundation
import SwiftUI

struct AppRootView: View {
    @StateObject private var store: AppDataStore

    init() {
        let store = AppDataStore()
        if !UserDefaults.standard.bool(forKey: "AppDidLoadSampleData") {
            store.vehicleProfile = AppSampleData.vehicleProfile
            store.fuelRecords = AppSampleData.fuelRecords
            store.maintenanceRecords = AppSampleData.maintenanceRecords
            store.save()
            UserDefaults.standard.set(true, forKey: "AppDidLoadSampleData")
        }
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        TabView {
            AppRecordEntryView()
                .tabItem {
                    Label("记一笔", systemImage: "plus.circle.fill")
                }
                .environmentObject(store)

            AppHistoryView()
                .tabItem {
                    Label("历史", systemImage: "clock.arrow.circlepath")
                }
                .environmentObject(store)

            AppStatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.xaxis")
                }
                .environmentObject(store)
        }
    }
}