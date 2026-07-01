import SwiftUI

struct RootShell: View {
    @State private var tab = 0
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $tab) {
                DiscoverView().tag(0)
                LibraryView(status: .stashed).tag(1)
                LibraryView(status: .binged).tag(2)
                ProfileView().tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            BingeTabBar(tab: $tab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct BingeTabBar: View {
    @Binding var tab: Int
    private let items: [(String, String)] = [
        ("sparkles","Explore"), ("tray.fill","Stash"),
        ("tv.fill","Binged"), ("chart.pie.fill","Stats")
    ]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                Button { withAnimation(.spring(response: 0.35)) { tab = i } } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.0)
                            .font(.system(size: 20, weight: tab == i ? .bold : .regular))
                            .foregroundStyle(tab == i ? AppTheme.accent : AppTheme.sublabel)
                        Text(item.1).font(AppTheme.caption(10))
                            .foregroundStyle(tab == i ? AppTheme.accent : AppTheme.sublabel)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                }
            }
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Divider().background(AppTheme.edge) }
        .padding(.bottom, 0)
    }
}
