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
                .tabViewStyle(.page(indexDisplayMode: .never))
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
                .shadow(color: .black.opacity(0.8), radius: 6, y: 2)
            Spacer()
            Button {
                withAnimation { searching = true }
            } label: {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.8), radius: 6, y: 2)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 56)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.55), .clear],
                startPoint: .top, endPoint: .bottom
            )
        )
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

    private let panelHeight: CGFloat = 132
    private let tabBarClearance: CGFloat = 84

    var body: some View {
        GeometryReader { geo in
            let posterHeight = max(geo.size.height - panelHeight - tabBarClearance, 0)

            VStack(spacing: 0) {
                AsyncImage(url: item.artworkLarge) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    AppTheme.surface
                }
                .frame(width: geo.size.width, height: posterHeight)
                .clipped()

                infoPanel
                    .frame(height: panelHeight + tabBarClearance, alignment: .top)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .background(AppTheme.background)
        }
        .ignoresSafeArea()
    }

    private var infoPanel: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.kind.label.uppercased())
                    .font(AppTheme.caption(10)).tracking(2).foregroundStyle(AppTheme.accent)
                Text(item.title)
                    .font(AppTheme.display(22)).foregroundStyle(.white).lineLimit(2)
                Text(item.caption)
                    .font(AppTheme.caption(13)).foregroundStyle(Color.white.opacity(0.72))
            }
            Spacer(minLength: 8)
            VStack(spacing: 14) {
                iconButton("info.circle.fill", color: .white, action: onTap)
                iconButton("plus.circle.fill", color: AppTheme.accent, action: onSave)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, tabBarClearance + 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.surface)
    }

    private func iconButton(_ icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: icon.contains("plus") ? 34 : 28))
                .foregroundStyle(color)
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
