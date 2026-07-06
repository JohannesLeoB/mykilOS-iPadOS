import Foundation

enum GrundrissEditorStoreError: Error, LocalizedError {
    case writeFailed(String)
    case nichtGefunden

    var errorDescription: String? {
        switch self {
        case .writeFailed(let detail): return "Grundriss nicht speicherbar: \(detail)"
        case .nichtGefunden: return "Grundriss nicht gefunden."
        }
    }
}

/// Gleiches Manifest-Muster wie `AufmassStore`/`RoomPlanStore`: eine
/// JSON-Datei `Documents/grundrisse.json`, keine Binärdateien nötig (die
/// Geometrie ist reiner Text/Zahlen).
@Observable
final class GrundrissEditorStore {
    private(set) var dokumente: [GrundrissDokument] = []
    private(set) var loadError: String?

    private let manifestURL: URL

    init(documentsURL: URL? = nil) {
        let documents = documentsURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.manifestURL = documents.appendingPathComponent("grundrisse.json")
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            dokumente = []
            loadError = nil
            return
        }
        do {
            let data = try Data(contentsOf: manifestURL)
            dokumente = try JSONDecoder().decode([GrundrissDokument].self, from: data)
            loadError = nil
        } catch {
            loadError = "Grundrisse nicht lesbar: \(error.localizedDescription)"
        }
    }

    @discardableResult
    func anlegen(titel: String = "Neuer Grundriss") throws -> GrundrissDokument {
        let dokument = GrundrissDokument(titel: titel)
        var next = dokumente
        next.append(dokument)
        try schreibeManifest(next)
        dokumente = next
        return dokument
    }

    func aktualisieren(_ dokument: GrundrissDokument) throws {
        guard let index = dokumente.firstIndex(where: { $0.id == dokument.id }) else {
            throw GrundrissEditorStoreError.nichtGefunden
        }
        var kopie = dokument
        kopie.geaendertAm = Date()
        var next = dokumente
        next[index] = kopie
        try schreibeManifest(next)
        dokumente = next
    }

    func remove(_ id: UUID) throws {
        guard let index = dokumente.firstIndex(where: { $0.id == id }) else { return }
        var next = dokumente
        next.remove(at: index)
        try schreibeManifest(next)
        dokumente = next
    }

    private func schreibeManifest(_ liste: [GrundrissDokument]) throws {
        do {
            let data = try JSONEncoder().encode(liste)
            try data.write(to: manifestURL, options: .atomic)
        } catch {
            throw GrundrissEditorStoreError.writeFailed(error.localizedDescription)
        }
    }
}
