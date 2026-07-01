import SwiftUI
import Charts
import Alamofire

struct ProfileView: View {
    @EnvironmentObject private var library: BingeVault
    @State private var ringVisible = false
    @State private var tab: BingeStatsTab = .overview
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        topCards
                        tabRow
                        switch tab {
                        case .overview: overviewContent
                        case .notes:    notesContent
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(AppTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(contactUsURL: "https://new-bingewise.pro/contact-us")
            }
            .onAppear { withAnimation(.spring(response: 0.8).delay(0.2)) { ringVisible = true } }
        }
    }

    private var topCards: some View {
        HStack(spacing: 10) {
            bingeCard("\(library.entries(status: .binged).count)", "Binged", "tv.fill", AppTheme.accent)
            bingeCard("\(library.entries(status: .stashed).count)", "Stashed", "tray.fill", AppTheme.sublabel)
            bingeCard("\(library.entries.filter { !$0.note.isEmpty }.count)", "Notes", "bubble.left.fill", AppTheme.positive)
        }
    }

    private func bingeCard(_ v: String, _ l: String, _ icon: String, _ c: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 15)).foregroundStyle(c)
            Text(v).font(AppTheme.display(22)).foregroundStyle(AppTheme.label)
            Text(l).font(AppTheme.caption(10)).foregroundStyle(AppTheme.sublabel)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.corner))
    }

    private var tabRow: some View {
        HStack(spacing: 0) {
            ForEach(BingeStatsTab.allCases, id: \.self) { t in
                Button { withAnimation(.spring(response: 0.3)) { tab = t } } label: {
                    Text(t.label).font(AppTheme.caption(13))
                        .foregroundStyle(tab == t ? AppTheme.background : AppTheme.sublabel)
                        .frame(maxWidth: .infinity).padding(.vertical, 9)
                        .background(tab == t ? AppTheme.accent : .clear)
                }
            }
        }
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.corner))
    }

    @ViewBuilder
    private var overviewContent: some View {
        genreDonut
        ratingBars
        recentBinges
    }

    private var genreDonut: some View {
        let genres = topGenres.prefix(5)
        let palette: [Color] = [AppTheme.accent, AppTheme.positive,
                                Color(red:1,green:0.54,blue:0.35), Color(red:0.3,green:0.8,blue:1),
                                Color(red:1,green:0.3,blue:0.6)]
        return VStack(alignment: .leading, spacing: 14) {
            Label("Genre Breakdown", systemImage: "chart.pie.fill").font(AppTheme.heading(15)).foregroundStyle(AppTheme.label)
            HStack(spacing: 16) {
                Chart(Array(genres.enumerated()), id: \.offset) { i, pair in
                    SectorMark(
                        angle: .value("Count", ringVisible ? pair.1 : 0),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(palette[i % palette.count])
                    .cornerRadius(4)
                }
                .animation(.spring(response: 0.9), value: ringVisible)
                .frame(width: 120, height: 120)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(genres.enumerated()), id: \.offset) { i, pair in
                        HStack(spacing: 8) {
                            Circle().fill(palette[i % palette.count]).frame(width: 8, height: 8)
                            Text(pair.0).font(AppTheme.body(13)).foregroundStyle(AppTheme.label).lineLimit(1)
                            Spacer()
                            Text("\(pair.1)").font(AppTheme.caption(12)).foregroundStyle(AppTheme.sublabel)
                        }
                    }
                }
            }
        }
        .padding(16).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.corner))
    }

    private var ratingBars: some View {
        let data = (1...5).map { r in (r, library.entries.filter { $0.rating == r }.count) }
        let mx = data.map(\.1).max() ?? 1
        return VStack(alignment: .leading, spacing: 14) {
            Label("Your Ratings", systemImage: "star.fill").font(AppTheme.heading(15)).foregroundStyle(AppTheme.label)
            Chart(data, id: \.0) { star, count in
                BarMark(x: .value("Stars", "\(star)★"), y: .value("Count", ringVisible ? count : 0))
                    .foregroundStyle(AppTheme.accent.gradient).cornerRadius(5)
            }
            .chartYAxis(.hidden)
            .chartXAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(AppTheme.sublabel) } }
            .frame(height: 120)
            .animation(.spring(response: 0.7), value: ringVisible)
        }
        .padding(16).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.corner))
    }

    private var recentBinges: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Binges", systemImage: "clock").font(AppTheme.heading(15)).foregroundStyle(AppTheme.label)
            ForEach(library.entries(status: .binged).prefix(4)) { e in
                HStack(spacing: 10) {
                    AsyncImage(url: e.item.artworkLarge) { img in img.resizable().aspectRatio(contentMode: .fill) }
                        placeholder: { AppTheme.surface }
                        .frame(width: 38, height: 54).clipShape(RoundedRectangle(cornerRadius: 6))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(e.item.title).font(AppTheme.body(14)).foregroundStyle(AppTheme.label).lineLimit(1)
                        Text(e.item.caption).font(AppTheme.caption(12)).foregroundStyle(AppTheme.sublabel)
                        if e.rating > 0 {
                            HStack(spacing: 2) {
                                ForEach(1...e.rating, id: \.self) { _ in
                                    Image(systemName: "star.fill").font(.system(size: 8)).foregroundStyle(AppTheme.accent)
                                }
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(16).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.corner))
    }

    @ViewBuilder
    private var notesContent: some View {
        let noted = library.entries.filter { !$0.note.isEmpty }.sorted { $0.addedAt > $1.addedAt }
        if noted.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "bubble.left").font(.system(size: 48)).foregroundStyle(AppTheme.accent.opacity(0.3))
                Text("No binge notes yet").font(AppTheme.heading(18)).foregroundStyle(AppTheme.label)
                Text("Write your thoughts on any title after watching.").font(AppTheme.body(14)).foregroundStyle(AppTheme.sublabel).multilineTextAlignment(.center)
            }.padding(32)
        } else {
            VStack(spacing: 12) {
                ForEach(noted) { e in
                    BingeNoteCard(entry: e)
                }
            }
        }
    }

    private var topGenres: [(String, Int)] {
        Dictionary(grouping: library.entries(status: .binged).compactMap(\.item.genre), by: { $0 })
            .sorted { $0.value.count > $1.value.count }.map { ($0.key, $0.value.count) }
    }
}

enum BingeStatsTab: CaseIterable {
    case overview, notes
    var label: String { self == .overview ? "Overview" : "Notes" }
}

struct BingeNoteCard: View {
    let entry: StashEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                AsyncImage(url: entry.item.artworkLarge) { img in img.resizable().aspectRatio(contentMode: .fill) }
                    placeholder: { AppTheme.surface }
                    .frame(width: 36, height: 52).clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.item.title).font(AppTheme.heading(14)).foregroundStyle(AppTheme.label).lineLimit(1)
                    if entry.rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= entry.rating ? "star.fill" : "star").font(.system(size: 9))
                                    .foregroundStyle(i <= entry.rating ? AppTheme.accent : AppTheme.sublabel)
                            }
                        }
                    }
                }
                Spacer()
                Text(entry.addedAt, format: .dateTime.day().month(.abbreviated))
                    .font(AppTheme.caption(10)).foregroundStyle(AppTheme.sublabel)
            }
            HStack(alignment: .top, spacing: 8) {
                RoundedRectangle(cornerRadius: 2).fill(AppTheme.accent).frame(width: 3)
                Text(entry.note).font(AppTheme.body(14)).foregroundStyle(AppTheme.label.opacity(0.85)).lineSpacing(4).lineLimit(5)
            }
        }
        .padding(14).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.corner))
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let contactUsURL: String
    @State private var showContactUs = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                List {
                    Section {
                        Button {
                            showContactUs = true
                        } label: {
                            HStack {
                                Label("Contact Us", systemImage: "envelope.fill")
                                    .foregroundColor(AppTheme.label)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.sublabel)
                            }
                        }
                    } header: {
                        Text("Support")
                            .foregroundColor(AppTheme.sublabel)
                    }
                    .listRowBackground(AppTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accent)
                }
            }
            .sheet(isPresented: $showContactUs) {
                NavigationStack {
                    Alamofire.WebContentView(url: contactUsURL)
                        .navigationTitle("Contact Us")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") {
                                    showContactUs = false
                                }
                                .foregroundColor(AppTheme.accent)
                            }
                        }
                }
            }
        }
    }
}
