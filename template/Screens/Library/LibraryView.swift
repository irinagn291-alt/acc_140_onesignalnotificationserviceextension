import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var library: BingeVault
    let status: ItemStatus

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                let items = library.entries(status: status)
                if items.isEmpty {
                    ContentUnavailableView(status.label, systemImage: status.icon,
                        description: Text("Nothing here yet."))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("\(items.count) titles").font(AppTheme.caption(13)).foregroundStyle(AppTheme.sublabel)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(items) { entry in
                                        NavigationLink { DetailView(item: entry.item) } label: {
                                            BingeCard(entry: entry)
                                        }.buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 18)
                            }
                            ForEach(items) { entry in
                                NavigationLink { DetailView(item: entry.item) } label: {
                                    GenericSearchRow(item: entry.item, status: entry.status)
                                }.buttonStyle(.plain).padding(.horizontal, 18)
                            }
                        }
                        .padding(.top, 16).padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle(status.label)
        }
    }
}

struct BingeCard: View {
    let entry: StashEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: entry.item.artworkLarge) { img in img.resizable().aspectRatio(2/3, contentMode: .fill) }
                placeholder: { AppTheme.surface.aspectRatio(2/3, contentMode: .fit) }
                .frame(width: 110, height: 165).clipped().clipShape(RoundedRectangle(cornerRadius: 10))
            Text(entry.item.title).font(AppTheme.caption(12)).foregroundStyle(AppTheme.label).lineLimit(2).frame(width: 110, alignment: .leading)
        }
    }
}
