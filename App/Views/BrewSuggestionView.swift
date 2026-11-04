import SwiftUI

struct BrewSuggestionView: View {
    let beans: [AppCoffeeBean]
    
    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(Color(white: 0.95).ignoresSafeArea())
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("冲煮建议")
                .font(.largeTitle.bold())
            Text("根据养豆状态和剩余量，智能推荐下一杯的冲煮参数")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
    }
    
    @ViewBuilder
    private var content: some View {
        if beans.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(beans) { bean in
                        suggestionCard(for: bean)
                    }
                }
                .padding()
            }
        }
    }
    
    private func suggestionCard(for bean: AppCoffeeBean) -> some View {
        let suggestion = AppBrewCalculator.suggestion(for: bean)
        let remainingCups = AppBrewCalculator.remainingCups(for: bean)
        let daysSinceRoast = Calendar.current.dateComponents([.day], from: bean.roastDate, to: Date()).day ?? 0
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bean.name)
                        .font(.headline)
                    Text("烘焙 \(daysSinceRoast) 天 · 剩余 \(bean.remainingGrams, specifier: "%.1f") g")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(remainingCups)")
                        .font(.title2.bold())
                    Text("剩余杯数")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            if remainingCups <= 0 {
                Label("库存不足，请补充豆子", systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.orange)
            } else {
                Divider()
                HStack {
                    parameterItem(title: "粉水比", value: String(format: "1:%.1f", suggestion.ratio))
                    Spacer()
                    parameterItem(title: "水温", value: String(format: "%.0f°C", suggestion.temperature))
                    Spacer()
                    parameterItem(title: "时间", value: formatTime(suggestion.time))
                }
                if daysSinceRoast >= 3 && daysSinceRoast <= 14 {
                    Label("正值最佳赏味期，建议尽快冲煮", systemImage: "checkmark.seal")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else if daysSinceRoast < 3 {
                    Label("养豆期不足 3 天，建议再等 \(3 - daysSinceRoast) 天", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Label("已过最佳赏味期，建议尽快消耗", systemImage: "hourglass")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    private func parameterItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cup.and.saucer")
                .font(.system(size: 60))
                .foregroundStyle(.quaternary)
            Text("还没有豆子")
                .font(.title3.bold())
            Text("在“豆子库存”里添加你的第一支咖啡豆，这里会自动为你生成专属冲煮建议。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.95))
    }
}