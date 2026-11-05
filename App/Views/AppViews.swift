import SwiftUI
import Combine

struct AppFilmListView: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var showingAddFilm = false
    @State private var sortNewestFirst = true
    @State private var selectedGenre: String? = nil

    private var genres: [String] {
        Array(Set(store.entries.map(\.genre))).sorted()
    }

    private var filteredEntries: [AppFilmEntry] {
        var result = store.entries
        if let genre = selectedGenre {
            result = result.filter { $0.genre == genre }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.director.lowercased().contains(query)
            }
        }
        result.sort { sortNewestFirst ? $0.watchDate > $1.watchDate : $0.watchDate < $1.watchDate }
        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.entries.isEmpty {
                    AppEmptyFilmView()
                } else {
                    filmList
                }
            }
            .navigationTitle("片库")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddFilm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFilm) {
                AppAddFilmView()
            }
            .searchable(text: $searchText, prompt: "搜索片名或导演")
        }
    }

    private var filmList: some View {
        List {
            Section {
                if !genres.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            genreChip(title: "全部", genre: nil)
                            ForEach(genres, id: \.self) { genre in
                                genreChip(title: genre, genre: genre)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets())
                }
                Picker("排序", selection: $sortNewestFirst) {
                    Text("最新优先").tag(true)
                    Text("最早优先").tag(false)
                }
                .pickerStyle(.segmented)
            }
            Section {
                ForEach(filteredEntries) { film in
                    NavigationLink {
                        AppFilmDetailView(film: film)
                    } label: {
                        AppFilmRow(film: film)
                    }
                }
                .onDelete(perform: deleteFilms)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func genreChip(title: String, genre: String?) -> some View {
        Button {
            selectedGenre = genre
        } label: {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedGenre == genre ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(selectedGenre == genre ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func deleteFilms(at offsets: IndexSet) {
        let filmsToDelete = offsets.map { filteredEntries[$0] }
        filmsToDelete.forEach { store.delete($0) }
    }
}

struct AppFilmRow: View {
    let film: AppFilmEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(film.title)
                    .font(.headline)
                Text(film.director)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(film.genre)
                    Text("·")
                    Text("\(film.year)")
                    Text("·")
                    Text(film.watchDate, format: .dateTime.year().month().day())
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.caption)
                Text(String(format: "%.1f", film.rating))
                    .font(.subheadline)
            }
            .foregroundStyle(.yellow)
        }
        .padding(.vertical, 4)
    }
}

struct AppFilmDetailView: View {
    @EnvironmentObject var store: AppStore
    let film: AppFilmEntry
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(film.title)
                            .font(.largeTitle.bold())
                        Text(film.director)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(format: "%.1f", film.rating))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.yellow)
                        .frame(minWidth: 60)
                }
                HStack(spacing: 12) {
                    Label(film.genre, systemImage: "tag")
                    Label("\(film.year)", systemImage: "calendar")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Label("观看日期", systemImage: "clock")
                        .font(.headline)
                    Text(film.watchDate, style: .date)
                        .foregroundStyle(.secondary)
                }

                if !film.review.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("短评", systemImage: "text.quote")
                            .font(.headline)
                        Text(film.review)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Spacer()
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("编辑") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AppEditFilmView(film: film)
        }
        .navigationTitle(film.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppAddFilmView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var director = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var rating = 3.0
    @State private var review = ""
    @State private var watchDate = Date()
    @State private var genre = "剧情"

    private let genreOptions = ["剧情", "喜剧", "动作", "科幻", "爱情", "动画", "纪录片", "恐怖", "悬疑", "其他"]

    var body: some View {
        NavigationStack {
            Form {
                Section("影片信息") {
                    TextField("片名", text: $title)
                    TextField("导演", text: $director)
                    Stepper("年份: \(year)", value: $year, in: 1900...Calendar.current.component(.year, from: Date()))
                    Picker("类型", selection: $genre) {
                        ForEach(genreOptions, id: \.self) { Text($0) }
                    }
                }

                Section("观影记录") {
                    DatePicker("观看日期", selection: $watchDate, displayedComponents: .date)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("评分: \(String(format: "%.1f", rating))")
                        Slider(value: $rating, in: 0...5, step: 0.5)
                    }
                    TextField("短评", text: $review, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("添加影片")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    func save() {
        let newEntry = AppFilmEntry(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            director: director.trimmingCharacters(in: .whitespacesAndNewlines),
            year: year,
            rating: rating,
            review: review,
            watchDate: watchDate,
            genre: genre
        )
        store.add(newEntry)
        dismiss()
    }
}

struct AppEditFilmView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    let film: AppFilmEntry

    @State private var title: String
    @State private var director: String
    @State private var year: Int
    @State private var rating: Double
    @State private var review: String
    @State private var watchDate: Date
    @State private var genre: String

    private let genreOptions = ["剧情", "喜剧", "动作", "科幻", "爱情", "动画", "纪录片", "恐怖", "悬疑", "其他"]

    init(film: AppFilmEntry) {
        self.film = film
        _title = State(initialValue: film.title)
        _director = State(initialValue: film.director)
        _year = State(initialValue: film.year)
        _rating = State(initialValue: film.rating)
        _review = State(initialValue: film.review)
        _watchDate = State(initialValue: film.watchDate)
        _genre = State(initialValue: film.genre)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("影片信息") {
                    TextField("片名", text: $title)
                    TextField("导演", text: $director)
                    Stepper("年份: \(year)", value: $year, in: 1900...Calendar.current.component(.year, from: Date()))
                    Picker("类型", selection: $genre) {
                        ForEach(genreOptions, id: \.self) { Text($0) }
                    }
                }

                Section("观影记录") {
                    DatePicker("观看日期", selection: $watchDate, displayedComponents: .date)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("评分: \(String(format: "%.1f", rating))")
                        Slider(value: $rating, in: 0...5, step: 0.5)
                    }
                    TextField("短评", text: $review, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("编辑影片")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    func save() {
        var updated = film
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.director = director.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.year = year
        updated.rating = rating
        updated.review = review
        updated.watchDate = watchDate
        updated.genre = genre
        store.update(updated)
        dismiss()
    }
}

struct AppEmptyFilmView: View {
    @Binding var showingAddFilm: Bool

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "film.stack")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("还没有电影记录")
                .font(.title2.bold())
            Text("点击右上角 + 或下方按钮，记下你看过的第一部电影。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                showingAddFilm = true
            } label: {
                Label("添加第一部电影", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.05))
    }
}

struct AppStatsView: View {
    @EnvironmentObject var store: AppStore

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    private var entriesThisYear: [AppFilmEntry] {
        store.entries.filter { Calendar.current.component(.year, from: $0.watchDate) == currentYear }
    }

    private var totalEntries: Int { store.entries.count }

    private var averageRatingThisYear: Double {
        guard !entriesThisYear.isEmpty else { return 0 }
        return entriesThisYear.map(\.rating).reduce(0, +) / Double(entriesThisYear.count)
    }

    private var topGenreThisYear: String {
        let grouped = Dictionary(grouping: entriesThisYear, by: \.genre)
        return grouped.max { $0.value.count < $1.value.count }?.key ?? "暂无"
    }

    private var monthlyCounts: [(month: Int, count: Int)] {
        (1...12).map { month in
            let count = entriesThisYear.filter { Calendar.current.component(.month, from: $0.watchDate) == month }.count
            return (month, count)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.entries.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("还没有可以统计的数据")
                            .font(.headline)
                        Text("去片库添加几部电影后，这里会显示你的观影统计。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    VStack(alignment: .leading, spacing: 24) {
                        summaryCard
                        monthlyChart
                        genreCard
                    }
                    .padding()
                }
            }
            .navigationTitle("年度回顾")
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(currentYear) 年概览")
                .font(.headline)
            HStack {
                statItem(value: "\(totalEntries)", label: "总共看过")
                statItem(value: "\(entriesThisYear.count)", label: "今年看过")
                statItem(value: String(format: "%.1f", averageRatingThisYear), label: "今年平均评分")
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今年每月观影")
                .font(.headline)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(monthlyCounts, id: \.month) { item in
                    VStack(spacing: 4) {
                        Text("\(item.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(item.count > 0 ? Color.accentColor : Color.secondary.opacity(0.25))
                            .frame(height: barHeight(for: item.count))
                        Text("\(item.month)月")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func barHeight(for count: Int) -> CGFloat {
        let maxCount = max(monthlyCounts.map(\.count).max() ?? 1, 1)
        return CGFloat(count) / CGFloat(maxCount) * 80 + 4
    }

    private var genreCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今年最常看的类型")
                .font(.headline)
            HStack {
                Text(topGenreThisYear)
                    .font(.title3.bold())
                Spacer()
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct AppAboutView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "film")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("Film Diary")
                    .font(.largeTitle.bold())
                Text("私人电影日记")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("所有数据仅保存在本机，不会上传。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.secondary.opacity(0.05))
            .navigationTitle("关于")
        }
    }
}