import Foundation
import Observation

/// Lädt den Projekt-Graphen aus dem gebündelten JSON-Snapshot der Registry —
/// 1:1 aus mykilOS iOS übernommen. Reine Lesequelle: die iPad-App schreibt
/// hier nichts.
@Observable
final class ProjectStore {
    private(set) var projects: [Project] = []
    private(set) var loadError: String?

    init() {
        load()
    }

    func load() {
        guard let url = Bundle.main.url(forResource: "projekte", withExtension: "json") else {
            loadError = "projekte.json fehlt im Bundle."
            return
        }
        do {
            let data = try Data(contentsOf: url)
            projects = try JSONDecoder().decode([Project].self, from: data)
            loadError = nil
        } catch {
            loadError = "Registry nicht lesbar: \(error.localizedDescription)"
        }
    }

    func matching(_ query: String) -> [Project] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return projects }
        return projects.filter {
            $0.title.lowercased().contains(q) || $0.projectNumber.contains(q)
        }
    }
}
