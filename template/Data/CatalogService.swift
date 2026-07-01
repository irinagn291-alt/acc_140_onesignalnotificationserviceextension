import Foundation

enum CatalogError: LocalizedError, Sendable {
    case emptyQuery, noResults, networkUnavailable

    var errorDescription: String? {
        switch self {
        case .emptyQuery:          return "Enter a title to search."
        case .noResults:           return "No results for that title."
        case .networkUnavailable:  return "Unable to reach the catalogue."
        }
    }
}

protocol CatalogSource: Sendable {
    func search(_ query: String, kind: MediaKind) async throws -> [BingeItem]
}

final class ITunesCatalog: CatalogSource, Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) { self.session = session }

    func search(_ query: String, kind: MediaKind) async throws -> [BingeItem] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { throw CatalogError.emptyQuery }

        guard var comps = URLComponents(string: "https://itunes.apple.com/search") else {
            throw CatalogError.networkUnavailable
        }

        var params: [URLQueryItem] = [
            URLQueryItem(name: "term",  value: q),
            URLQueryItem(name: "limit", value: kind == .film ? "50" : "24"),
        ]
        if kind == .series {
            params += [
                URLQueryItem(name: "media",  value: "tvShow"),
                URLQueryItem(name: "entity", value: "tvSeason"),
            ]
        }
        comps.queryItems = params
        guard let url = comps.url else { throw CatalogError.networkUnavailable }

        let (data, resp) = try await session.data(from: url)
        guard let http = resp as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw CatalogError.networkUnavailable
        }

        let bundle = try JSONDecoder().decode(SearchBundle.self, from: data)
        let items = bundle.results
            .filter { $0.isMatch(for: kind) }
            .compactMap { $0.toItem(kind: kind) }
        guard !items.isEmpty else { throw CatalogError.noResults }
        return items
    }

    // ── private DTOs ────────────────────────────────────────────────────────

    private struct SearchBundle: Decodable { let results: [Row] }

    private struct Row: Decodable {
        let trackId: Int?
        let collectionId: Int?
        let trackName: String?
        let collectionName: String?
        let artistName: String?
        let primaryGenreName: String?
        let releaseDate: String?
        let artworkUrl100: String?
        let longDescription: String?
        let shortDescription: String?
        let contentAdvisoryRating: String?
        let trackTimeMillis: Int?
        let kind: String?
        let wrapperType: String?

        func isMatch(for k: MediaKind) -> Bool {
            switch k {
            case .film:   return kind == "feature-movie"
            case .series: return kind == "tv-episode" || wrapperType == "collection"
            }
        }

        func toItem(kind: MediaKind) -> BingeItem? {
            let ref  = trackId ?? collectionId
            let name = trackName ?? collectionName
            guard let ref, let name else { return nil }
            let year = releaseDate.flatMap { String($0.prefix(4)) }.flatMap { Int($0) }
            return BingeItem(
                itemID:          ref,
                title:           name,
                creator:         artistName ?? "Unknown",
                kind:            kind,
                genre:           primaryGenreName,
                year:            year,
                artworkSmall:    artworkUrl100,
                synopsis:        longDescription ?? shortDescription,
                advisory:        contentAdvisoryRating,
                durationMinutes: trackTimeMillis.map { $0 / 60_000 }
            )
        }
    }
}
