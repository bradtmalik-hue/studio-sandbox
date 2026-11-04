import SwiftUI

struct SandboxProbeRootView: View {
    @StateObject private var homeStore = HomeStore()
    @StateObject private var settingsStore = SettingsStore()
    private static func startIndex() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-startTab"), i + 1 < args.count,
           let v = Int(args[i + 1]) { return v }
        return 0
    }
    @State private var destination: Int? = SandboxProbeRootView.startIndex()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("SandboxProbe")
                        .font(.largeTitle.bold())
                        .padding(.bottom, 6)
                Button {
                    destination = 0
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "square.grid.2x2")
                            .font(.title3)
                            .frame(width: 34)
                        Text("Home").font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.35),
                                in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                Button {
                    destination = 1
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "list.bullet")
                            .font(.title3)
                            .frame(width: 34)
                        Text("Stats").font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.35),
                                in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                Button {
                    destination = 2
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "clock")
                            .font(.title3)
                            .frame(width: 34)
                        Text("Settings").font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.35),
                                in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                }
                .padding(20)
            }
            .navigationDestination(item: $destination) { value in
                Group {
                    switch value {
                    case 0: HomeView()
                    case 1: SandboxProbeInsightView()
                    case 2: SettingsView()
                    default: HomeView()
                    }
                }
                .environmentObject(homeStore)
                .environmentObject(homeStore)
                .environmentObject(settingsStore)
            }
        }
    }
}
