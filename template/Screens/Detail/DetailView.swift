import SwiftUI

struct DetailView: View {
    @EnvironmentObject private var library: BingeVault
    let item: BingeItem
    @State private var showNote = false
    @Environment(\.dismiss) private var dismiss
    private var entry: StashEntry? { library.entries.first { $0.item.itemID == item.itemID } }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AppTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    posterSection
                    content.padding(.horizontal, 20).padding(.top, 20)
                }
                .padding(.bottom, 60)
            }
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill").font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(20).padding(.top, 44)
            }
        }
        .sheet(isPresented: $showNote) { NoteSheet(item: item) }
    }

    private var posterSection: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: item.artworkLarge) { img in
                img.resizable().aspectRatio(contentMode: .fill).frame(height: 340).clipped()
            } placeholder: { AppTheme.surface.frame(height: 340) }
            LinearGradient(colors: [.clear, AppTheme.background], startPoint: .top, endPoint: .bottom).frame(height: 180)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(item.title).font(AppTheme.display(24)).foregroundStyle(AppTheme.label)
            Text(item.caption).font(AppTheme.caption(13)).foregroundStyle(AppTheme.sublabel)

            HStack(spacing: 10) {
                addButton(label: "Stash", status: .stashed, color: AppTheme.accent)
                addButton(label: "Binged", status: .binged, color: AppTheme.positive)
            }

            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { i in
                    Button {
                        if entry == nil { library.add(item, status: .stashed) }
                        library.update(id: item.itemID) { $0.rating = i }
                    } label: {
                        Image(systemName: (entry?.rating ?? 0) >= i ? "star.fill" : "star")
                            .font(.system(size: 28)).foregroundStyle(AppTheme.accent)
                    }
                }
            }

            if let syn = item.synopsis {
                Text(syn).font(AppTheme.body(15)).foregroundStyle(AppTheme.label.opacity(0.8)).lineSpacing(4)
            }

            Button { if entry == nil { library.add(item, status: .stashed) }; showNote = true } label: {
                Label(entry?.note.isEmpty == false ? entry!.note : "Add a note…", systemImage: "note.text")
                    .font(AppTheme.body(14)).foregroundStyle(AppTheme.sublabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.corner))
            }.buttonStyle(.plain)
        }
    }

    private func addButton(label: String, status: ItemStatus, color: Color) -> some View {
        Button { library.add(item, status: status) } label: {
            Text(entry?.status == status ? "✓ \(label)" : label)
                .font(AppTheme.caption(14))
                .foregroundStyle(entry?.status == status ? .white : AppTheme.label)
                .frame(maxWidth: .infinity).padding(.vertical, 13)
                .background(entry?.status == status ? color : AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.corner))
        }
    }
}

private struct NoteSheet: View {
    @EnvironmentObject private var library: BingeVault
    let item: BingeItem
    @State private var text = ""
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            TextEditor(text: $text).scrollContentBackground(.hidden).background(AppTheme.background).padding()
                .navigationTitle("Note").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { library.update(id: item.itemID) { $0.note = text }; dismiss() }
                    }
                }
        }
        .onAppear { text = library.entries.first { $0.item.itemID == item.itemID }?.note ?? "" }
    }
}
