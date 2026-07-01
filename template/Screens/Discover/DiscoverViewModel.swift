import Foundation
import Combine

enum SearchStage {
    case prompt
    case loading
    case results([BingeItem])
    case empty
    case error(String)
}

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var kind: MediaKind = .film
    @Published private(set) var stage: SearchStage = .prompt
    @Published private(set) var featured: [BingeItem] = []

    private let catalog: any CatalogSource
    private var debounceTask: Task<Void, Never>?
    private let preloadTerms = ["Breaking Bad", "Stranger Things", "The Last of Us"]

    init(catalog: any CatalogSource = ITunesCatalog()) {
        self.catalog = catalog
    }

    func preload() {
        guard featured.isEmpty else { return }
        Task {
            for term in preloadTerms {
                if let items = try? await catalog.search(term, kind: .film) {
                    let picked = items.prefix(6)
                    featured += picked
                    if featured.count >= 12 { break }
                }
            }
        }
    }

    func search() {
        debounceTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            stage = .prompt
            return
        }
        stage = .loading
        debounceTask = Task {
            do {
                let results = try await catalog.search(query, kind: kind)
                if !Task.isCancelled { stage = .results(results) }
            } catch let error as CatalogError {
                if !Task.isCancelled {
                    stage = error == .noResults ? .empty : .error(error.localizedDescription)
                }
            } catch {
                if !Task.isCancelled { stage = .error(error.localizedDescription) }
            }
        }
    }

    func switchKind(_ newKind: MediaKind) {
        kind = newKind
        if case .prompt = stage { } else { search() }
    }

    func clear() {
        query = ""
        stage = .prompt
        debounceTask?.cancel()
    }
}
