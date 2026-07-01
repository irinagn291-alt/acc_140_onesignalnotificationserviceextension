import Foundation
import Combine

@MainActor
final class BingeVault: ObservableObject {
    @Published private(set) var entries: [StashEntry] = []

    private let defaultsKey = "bingewise.library.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        entries = load()
    }

    func statusOf(id: Int) -> ItemStatus? {
        entries.first { $0.item.itemID == id }?.status
    }

    func entries(status: ItemStatus) -> [StashEntry] {
        entries.filter { $0.status == status }.sorted { $0.addedAt > $1.addedAt }
    }

    @discardableResult
    func add(_ item: BingeItem, status: ItemStatus = .stashed) -> StashEntry {
        if let i = entries.firstIndex(where: { $0.item.itemID == item.itemID }) {
            entries[i].status = status
            persist()
            return entries[i]
        }
        let entry = StashEntry(item: item, status: status)
        entries.insert(entry, at: 0)
        persist()
        return entry
    }

    func remove(id: Int) {
        entries.removeAll { $0.item.itemID == id }
        persist()
    }

    func update(id: Int, _ mutation: (inout StashEntry) -> Void) {
        guard let i = entries.firstIndex(where: { $0.item.itemID == id }) else { return }
        mutation(&entries[i])
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: defaultsKey)
        }
    }

    private func load() -> [StashEntry] {
        guard let data = defaults.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([StashEntry].self, from: data)
        else { return [] }
        return decoded
    }
}
