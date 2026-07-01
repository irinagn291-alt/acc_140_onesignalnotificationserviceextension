import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var library: BingeVault
    @StateObject private var vm = DiscoverViewModel()
    @State private var searching = false
    @State private var selected: BingeItem?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                if searching {
                    searchPanel
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    featuredFeed
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.38), value: searching)
            .navigationBarHidden(true)
            .navigationDestination(for: BingeItem.self) { DetailView(item: $0) }
            .sheet(item: $selected) { DetailView(item: $0).presentationDetents([.large]) }
        }
        .onAppear { vm.preload() }
    }

    // ── Full-screen paging feed ───────────────────────────────────────────

    private var featuredFeed: some View {
        ZStack(alignment: .top) {
            if vm.featured.isEmpty {
                shimmerFeed
            } else {
                TabView {
                    ForEach(vm.featured) { item in
                        BingePosterCard(item: item) {
                            selected = item
                        } onSave: {
                            library.add(item, status: .stashed)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .ignoresSafeArea()
            }
            topBar
        }
    }

    private var shimmerFeed: some View {
        ZStack {
            AppTheme.surface
            VStack(spacing: 16) {
                ProgressView().tint(AppTheme.accent).scaleEffect(1.5)
                Text("Loading catalogue…").font(AppTheme.body(15)).foregroundStyle(AppTheme.sublabel)
            }
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Text("Bingewise").font(AppTheme.display(22)).foregroundStyle(.white)
                .shadow(radius: 4)
            Spacer()
            Button {
                withAnimation { searching = true }
            } label: {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 56)
    }

    // ── Search panel ──────────────────────────────────────────────────────

    private var searchPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Button { withAnimation { searching = false; vm.clear() } } label: {
                    Image(systemName: "xmark").font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.label)
                }
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(AppTheme.sublabel)
                    TextField("", text: $vm.query,
                              prompt: Text("Search shows & films…").foregroundStyle(AppTheme.sublabel))
                        .font(AppTheme.body(16)).foregroundStyle(AppTheme.label)
                        .autocorrectionDisabled()
                        .onSubmit { vm.search() }
                        .onChange(of: vm.query) { _, _ in vm.search() }
                    if !vm.query.isEmpty {
                        Button { vm.clear() } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(AppTheme.sublabel)
                        }
                    }
                }
                .padding(11).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.corner))
            }
            .padding(.horizontal, 16).padding(.top, 54).padding(.bottom, 10)

            HStack(spacing: 8) {
                ForEach([MediaKind.film, .series], id: \.self) { k in
                    let on = vm.kind == k
                    Button { vm.switchKind(k) } label: {
                        Text(k.label).font(AppTheme.caption(13))
                            .foregroundStyle(on ? AppTheme.background : AppTheme.sublabel)
                            .padding(.horizontal, 16).padding(.vertical, 7)
                            .background(on ? AppTheme.accent : AppTheme.surface, in: Capsule())
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.bottom, 12)

            switch vm.stage {
            case .prompt:
                SearchSuggestions(terms: ["Breaking Bad", "Stranger Things", "Squid Game", "The Last of Us"]) {
                    vm.query = $0; vm.search()
                }
            case .loading:
                Spacer(); ProgressView().tint(AppTheme.accent); Spacer()
            case .results(let r):
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(r) { item in
                            Button { selected = item } label: {
                                BingeListRow(item: item, status: library.statusOf(id: item.itemID))
                            }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 80)
                }
            case .empty:
                emptyState("No results", "tv.slash")
            case .error(let m):
                emptyState(m, "wifi.slash")
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private func emptyState(_ msg: String, _ icon: String) -> some View {
        VStack { Spacer()
            ContentUnavailableView(msg, systemImage: icon).padding(40)
            Spacer() }
    }
}

struct BingePosterCard: View {
    let item: BingeItem
    let onTap: () -> Void
    let onSave: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: item.artworkLarge) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                AppTheme.surface
            }
            .ignoresSafeArea()

            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.9)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.kind.label.uppercased())
                        .font(AppTheme.caption(10)).tracking(3).foregroundStyle(AppTheme.accent)
                    Text(item.title)
                        .font(AppTheme.display(30)).foregroundStyle(.white).lineLimit(3)
                    Text(item.caption)
                        .font(AppTheme.caption(13)).foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                VStack(spacing: 16) {
                    Button(action: onTap) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 30)).foregroundStyle(.white)
                    }
                    Button(action: onSave) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36)).foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 100)
        }
    }
}

struct BingeListRow: View {
    let item: BingeItem; let status: ItemStatus?
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.artworkLarge) { img in img.resizable().aspectRatio(contentMode: .fill) }
                placeholder: { AppTheme.surface }
                .frame(width: 52, height: 76).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(AppTheme.heading(15)).foregroundStyle(AppTheme.label).lineLimit(2)
                Text(item.caption).font(AppTheme.caption(12)).foregroundStyle(AppTheme.sublabel)
                if let s = status {
                    Capsule().fill(AppTheme.accent.opacity(0.2))
                        .overlay { Text(s.label).font(AppTheme.caption(10)).foregroundStyle(AppTheme.accent) }
                        .frame(width: 60, height: 20)
                }
            }
            Spacer()
        }
        .padding(12).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.corner))
    }
}

struct SearchSuggestions: View {
    let terms: [String]; let onTap: (String) -> Void
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(terms, id: \.self) { term in
                    Button { onTap(term) } label: {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundStyle(AppTheme.sublabel)
                            Text(term).font(AppTheme.body(16)).foregroundStyle(AppTheme.label)
                            Spacer()
                            Image(systemName: "arrow.up.left").foregroundStyle(AppTheme.sublabel).font(.caption)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        Divider().background(AppTheme.edge).padding(.horizontal, 16)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.bottom, 60)
        }
    }
}
