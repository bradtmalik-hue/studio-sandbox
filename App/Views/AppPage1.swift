import SwiftUI

private let appPage1TimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日 HH:mm"
    return formatter
}()

private let appPage1DayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "yyyy年M月d日 HH:mm"
    return formatter
}()

private func appPage1KindDisplayName(_ kind: AppDrinkKind) -> String {
    switch kind.rawValue {
    case "water": return "水"
    case "tea": return "茶"
    case "coffee": return "咖啡"
    case "juice": return "果汁"
    case "milk": return "牛奶"
    case "soda": return "汽水"
    default: return kind.rawValue
    }
}

private func appPage1KindDisplayNameFromRaw(_ rawValue: String) -> String {
    switch rawValue {
    case "water": return "水"
    case "tea": return "茶"
    case "coffee": return "咖啡"
    case "juice": return "果汁"
    case "milk": return "牛奶"
    case "soda": return "汽水"
    default: return rawValue
    }
}

struct AppPage1Row: View {
    let record: AppWaterRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Image("sample1")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(appPage1KindDisplayName(record.kind))
                    .font(.headline)
                Text(appPage1TimeFormatter.string(from: record.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("每次 \(record.amount) 毫升")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(record.amount)")
                    .font(.title3.bold())
                    .foregroundColor(.accentColor)
                Text("毫升")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AppPage1SummaryCard: View {
    let total: Int
    let goal: Int
    let recordCount: Int
    let lastDateText: String
    let onAdd: () -> Void
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(total) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 18)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                VStack(spacing: 6) {
                    Text("\(total)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("毫升")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 180, height: 180)
            
            HStack {
                Label("目标 \(goal) 毫升", systemImage: "target")
                Spacer()
                Label("\(recordCount) 条", systemImage: "list.bullet")
                Spacer()
                Label(lastDateText, systemImage: "clock")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            
            Button(action: onAdd) {
                Label("加 250 毫升", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color.accentColor)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal)
    }
}

struct AppPage1EmptyView: View {
    let onAdd: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label("今天还没有喝水记录", systemImage: "drop")
        } description: {
            Text("点击下方按钮添加第一杯水")
        } actions: {
            Button("添加 250 毫升", action: onAdd)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}

struct AppPage1RecordDetailView: View {
    let record: AppWaterRecord
    
    var body: some View {
        List {
            Section {
                LabeledContent("饮水量") { Text("\(record.amount) 毫升") }
                LabeledContent("类型") { Text(appPage1KindDisplayName(record.kind)) }
                LabeledContent("日期") { Text(appPage1DayFormatter.string(from: record.date)) }
                LabeledContent("记录 ID") { Text(record.id.uuidString) }
            }
        }
        .navigationTitle("记录详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppPage1View: View {
    @EnvironmentObject var store: AppStore
    @State private var filterKindRaw: String? = nil
    
    var todayRecords: [AppWaterRecord] {
        store.todayRecords
    }
    
    private var uniqueKinds: [String] {
        Array(Set(todayRecords.map { $0.kind.rawValue })).sorted()
    }
    
    var filteredRecords: [AppWaterRecord] {
        guard let kindRaw = filterKindRaw else { return todayRecords }
        return todayRecords.filter { $0.kind.rawValue == kindRaw }
    }
    
    var todayTotal: Int {
        todayRecords.reduce(0) { $0 + $1.amount }
    }
    
    private var lastDateText: String {
        guard let lastDate = todayRecords.map(\.date).max() else {
            return "暂无记录"
        }
        return appPage1TimeFormatter.string(from: lastDate)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if todayRecords.isEmpty {
                    AppPage1EmptyView(onAdd: addWater)
                        .background(Color(.systemGroupedBackground))
                } else {
                    List {
                        Section {
                            AppPage1SummaryCard(
                                total: todayTotal,
                                goal: store.dailyGoal,
                                recordCount: todayRecords.count,
                                lastDateText: lastDateText,
                                onAdd: addWater
                            )
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        
                        Section {
                            Picker("筛选", selection: $filterKindRaw) {
                                Text("全部").tag(String?.none)
                                ForEach(uniqueKinds, id: \.self) { kindRaw in
                                    Text(appPage1KindDisplayNameFromRaw(kindRaw)).tag(String?.some(kindRaw))
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        Section {
                            ForEach(filteredRecords) { record in
                                NavigationLink {
                                    AppPage1RecordDetailView(record: record)
                                } label: {
                                    AppPage1Row(record: record)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        delete(record)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("今天")
        }
    }
    
    func delete(_ record: AppWaterRecord) {
        guard let index = store.records.firstIndex(where: { $0.id == record.id }) else { return }
        store.records.remove(at: index)
        store.save()
    }
    
    private func addWater() {
        let kind = AppDrinkKind(rawValue: "water")!
        let record = AppWaterRecord(id: UUID(), amount: 250, date: Date(), kind: kind)
        store.records.append(record)
        store.save()
    }
}