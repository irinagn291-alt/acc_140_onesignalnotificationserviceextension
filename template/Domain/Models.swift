import Foundation

enum MediaKind: String, Codable, Sendable {
    case film, series
    var label: String { self == .film ? "Film" : "Series" }
}

enum ItemStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case stashed
    case binged

    var id: String { rawValue }
    var label: String {
        switch self {
        case .stashed: return "Stash"
        case .binged: return "Binged"
        }
    }
    var icon: String {
        switch self {
        case .stashed: return "bookmark.fill"
        case .binged: return "checkmark.circle.fill"
        }
    }
}

struct BingeItem: Identifiable, Codable, Hashable, Sendable {
    let itemID: Int
    let title: String
    let creator: String
    let kind: MediaKind
    let genre: String?
    let year: Int?
    let artworkSmall: String?
    let synopsis: String?
    let advisory: String?
    let durationMinutes: Int?

    var id: Int { itemID }

    var artworkLarge: URL? {
        artworkSmall.flatMap {
            URL(string: $0.replacingOccurrences(of: "100x100bb", with: "600x600bb"))
        }
    }

    var durationLabel: String? {
        guard let m = durationMinutes, m > 0 else { return nil }
        return "\(m / 60)h \(m % 60)m"
    }

    var caption: String {
        [kind.label, genre, year.map(String.init)].compactMap { $0 }.joined(separator: " · ")
    }
}

struct StashEntry: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let item: BingeItem
    var status: ItemStatus
    var starred: Bool
    var rating: Int        // 0…5
    var note: String
    let addedAt: Date

    init(item: BingeItem, status: ItemStatus = .stashed) {
        self.id        = UUID()
        self.item      = item
        self.status    = status
        self.starred   = false
        self.rating    = 0
        self.note      = ""
        self.addedAt   = Date()
    }
}
