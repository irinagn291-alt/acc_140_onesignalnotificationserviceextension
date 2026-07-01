import SwiftUI

struct GenericSearchRow: View {
    let item: BingeItem
    let status: ItemStatus?

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.artworkLarge) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: { AppTheme.surface }
            .frame(width: 52, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerSmall))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(AppTheme.heading(15)).foregroundStyle(AppTheme.label).lineLimit(2)
                Text(item.caption)
                    .font(AppTheme.caption(12)).foregroundStyle(AppTheme.sublabel)
                if let s = status {
                    Label(s.label, systemImage: s.icon)
                        .font(AppTheme.caption(11)).foregroundStyle(AppTheme.accent)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.corner))
    }
}
