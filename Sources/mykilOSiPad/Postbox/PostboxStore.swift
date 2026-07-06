import Foundation
import Observation

enum PostboxError: Error, LocalizedError {
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .writeFailed(let detail): return "Postbox nicht beschreibbar: \(detail)"
        }
    }
}

/// Echte lokale Ablage — jeder bestätigte Fang landet hier, überlebt einen
/// App-Neustart und wartet auf einen späteren Sync (noch nicht angebunden).
/// 1:1 aus mykilOS iOS übernommen.
@Observable
final class PostboxStore {
    private(set) var items: [PostboxItem] = []
    private(set) var loadError: String?

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.fileURL = documents.appendingPathComponent("postbox.json")
        }
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            items = []
            loadError = nil
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            items = try JSONDecoder().decode([PostboxItem].self, from: data)
            loadError = nil
        } catch {
            loadError = "Postbox nicht lesbar: \(error.localizedDescription)"
        }
    }

    @discardableResult
    func append(_ item: PostboxItem) throws -> PostboxItem {
        var next = items
        next.append(item)
        try write(next)
        items = next
        return item
    }

    func markSynced(_ id: UUID) throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        var next = items
        next[index].syncedAt = Date()
        try write(next)
        items = next
    }

    /// Entfernt einen verunglückten Fang wieder — nur solange er noch NICHT
    /// synchronisiert ist.
    func remove(_ id: UUID) throws {
        guard let index = items.firstIndex(where: { $0.id == id }), items[index].syncedAt == nil else { return }
        var next = items
        next.remove(at: index)
        try write(next)
        items = next
    }

    private func write(_ items: [PostboxItem]) throws {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw PostboxError.writeFailed(error.localizedDescription)
        }
    }
}
