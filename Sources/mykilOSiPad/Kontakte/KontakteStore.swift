import Foundation
import Observation

enum KontakteFehler: Error, LocalizedError {
    case syncNichtEingerichtet

    var errorDescription: String? {
        switch self {
        case .syncNichtEingerichtet:
            return "Kontakt-Sync (Airtable) ist noch nicht eingerichtet. Das Verzeichnis zeigt nur den lokalen Cache."
        }
    }
}

/// Neustart-fester Cache des Kunden-Verzeichnisses — einmal geladen, auch
/// offline da. Gleiches JSON-in-Documents-Muster wie alle Stores; der
/// Cache ist nur Spiegel, System-of-Record bleibt Airtable.
///
/// iPad-Stand: der Airtable-Client (`AirtableKundenClient`) ist bewusst NOCH
/// NICHT portiert — er braucht Credentials, die Johannes erst einrichtet
/// (siehe WORK_STATUS "bewusst zurückgestellt"). Bis dahin ist der Store
/// ehrlich cache-only: `aktualisieren()` meldet offen, dass die Quelle fehlt,
/// statt einen Sync vorzutäuschen. Sobald der Client kommt, wird hier nur
/// `client.ladeAlle()` eingehängt — die View bleibt unverändert.
@Observable
final class KontakteStore {
    private(set) var kontakte: [KundenKontakt] = []
    private(set) var fehler: String?
    private(set) var laedtGerade = false

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.fileURL = documents.appendingPathComponent("kontakte_cache.json")
        }
        ladeCache()
    }

    private func ladeCache() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let geladen = try? JSONDecoder().decode([KundenKontakt].self, from: data) else { return }
        kontakte = geladen
    }

    @MainActor
    func aktualisieren() async {
        laedtGerade = true
        defer { laedtGerade = false }
        // Kein Airtable-Client portiert → ehrliche Meldung statt Fake-Sync.
        fehler = KontakteFehler.syncNichtEingerichtet.errorDescription
    }
}
