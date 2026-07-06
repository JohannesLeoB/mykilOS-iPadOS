import UIKit

/// Übernommen 1:1 nach dem Muster aus mykilOS iOS (`AufmassStore` in
/// `Aufmass.swift`): Manifest `Documents/aufmasse.json` + Bilddateien in
/// `Documents/Aufmasse/`. throws-basiert, atomare Writes, Rollback der
/// Bilddatei wenn das Manifest-Schreiben scheitert, `loadError` statt Absturz.
enum AufmassError: Error, LocalizedError {
    case writeFailed(String)
    case bildKonnteNichtGespeichertWerden
    case nichtGefunden
    case bilddateiFehltNachImport

    var errorDescription: String? {
        switch self {
        case .writeFailed(let detail): return "Aufmaß nicht speicherbar: \(detail)"
        case .bildKonnteNichtGespeichertWerden: return "Foto konnte nicht als Datei gespeichert werden."
        case .nichtGefunden: return "Aufmaß nicht gefunden."
        case .bilddateiFehltNachImport: return "Import abgebrochen: zugehöriges Originalfoto fehlt im Aufmaße-Ordner."
        }
    }
}

@Observable
final class AufmassStore {
    private(set) var aufmasse: [Aufmass] = []
    private(set) var loadError: String?

    private let manifestURL: URL
    private let ordnerURL: URL

    init(documentsURL: URL? = nil) {
        let documents = documentsURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.manifestURL = documents.appendingPathComponent("aufmasse.json")
        self.ordnerURL = documents.appendingPathComponent("Aufmasse", isDirectory: true)
        try? FileManager.default.createDirectory(at: ordnerURL, withIntermediateDirectories: true)
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            aufmasse = []
            loadError = nil
            return
        }
        do {
            let data = try Data(contentsOf: manifestURL)
            aufmasse = try JSONDecoder().decode([Aufmass].self, from: data)
            loadError = nil
        } catch {
            loadError = "Aufmaße nicht lesbar: \(error.localizedDescription)"
        }
    }

    func originalBildURL(fuer aufmass: Aufmass) -> URL {
        ordnerURL.appendingPathComponent(aufmass.originalDateiname)
    }

    func annotiertBildURL(fuer aufmass: Aufmass) -> URL? {
        aufmass.annotiertDateiname.map { ordnerURL.appendingPathComponent($0) }
    }

    /// Legt ein NEUES Aufmaß aus einem frisch aufgenommenen Foto an — Projekt
    /// und Raum optional. Schreibt das Originalfoto als JPEG + Manifest-Eintrag.
    @discardableResult
    func anlegen(
        originalfoto: UIImage,
        projectNumber: String? = nil,
        projectTitel: String? = nil,
        raumTitel: String? = nil
    ) throws -> Aufmass {
        guard let jpeg = originalfoto.jpegData(compressionQuality: 0.85) else {
            throw AufmassError.bildKonnteNichtGespeichertWerden
        }
        let id = UUID()
        let dateiname = "\(id.uuidString)-original.jpg"
        let zielURL = ordnerURL.appendingPathComponent(dateiname)
        do {
            try jpeg.write(to: zielURL, options: .atomic)
        } catch {
            throw AufmassError.writeFailed(error.localizedDescription)
        }

        let eintrag = Aufmass(
            id: id,
            originalDateiname: dateiname,
            bildBreite: Double(originalfoto.size.width),
            bildHoehe: Double(originalfoto.size.height),
            projectNumber: projectNumber,
            projectTitel: projectTitel,
            raumTitel: raumTitel
        )
        var next = aufmasse
        next.append(eintrag)
        do {
            try schreibeManifest(next)
        } catch {
            try? FileManager.default.removeItem(at: zielURL)
            throw error
        }
        aufmasse = next
        return eintrag
    }

    /// Ersetzt ein komplettes Aufmaß-Dokument (nach Annotations-Änderungen),
    /// setzt `geaendertAm` neu.
    func aktualisieren(_ aufmass: Aufmass) throws {
        guard let index = aufmasse.firstIndex(where: { $0.id == aufmass.id }) else {
            throw AufmassError.nichtGefunden
        }
        var kopie = aufmass
        kopie.geaendertAm = Date()
        var next = aufmasse
        next[index] = kopie
        try schreibeManifest(next)
        aufmasse = next
    }

    /// Legt das eingebrannte Bild als zweite Datei ab und merkt sich den Namen.
    func setzeAnnotiert(_ id: UUID, bild: UIImage) throws {
        guard let index = aufmasse.firstIndex(where: { $0.id == id }) else {
            throw AufmassError.nichtGefunden
        }
        guard let jpeg = bild.jpegData(compressionQuality: 0.9) else {
            throw AufmassError.bildKonnteNichtGespeichertWerden
        }
        let dateiname = "\(id.uuidString)-annotiert.jpg"
        let zielURL = ordnerURL.appendingPathComponent(dateiname)
        do {
            try jpeg.write(to: zielURL, options: .atomic)
        } catch {
            throw AufmassError.writeFailed(error.localizedDescription)
        }
        var next = aufmasse
        next[index].annotiertDateiname = dateiname
        next[index].geaendertAm = Date()
        do {
            try schreibeManifest(next)
        } catch {
            try? FileManager.default.removeItem(at: zielURL)
            throw error
        }
        aufmasse = next
    }

    /// Nachträgliche (änderbare) Projekt-/Raum-Zuordnung.
    func zuordnen(_ id: UUID, projectNumber: String?, projectTitel: String?, raumTitel: String? = nil) throws {
        guard let index = aufmasse.firstIndex(where: { $0.id == id }) else {
            throw AufmassError.nichtGefunden
        }
        var next = aufmasse
        next[index].projectNumber = projectNumber
        next[index].projectTitel = projectTitel
        next[index].raumTitel = raumTitel
        next[index].geaendertAm = Date()
        try schreibeManifest(next)
        aufmasse = next
    }

    func verknuepfeFeldFoto(_ id: UUID, feldFotoID: UUID) throws {
        guard let index = aufmasse.firstIndex(where: { $0.id == id }) else {
            throw AufmassError.nichtGefunden
        }
        var next = aufmasse
        next[index].feldFotoID = feldFotoID
        next[index].geaendertAm = Date()
        try schreibeManifest(next)
        aufmasse = next
    }

    /// Löscht Manifest-Eintrag + beide Bilddateien.
    func remove(_ id: UUID) throws {
        guard let index = aufmasse.firstIndex(where: { $0.id == id }) else { return }
        let original = aufmasse[index].originalDateiname
        let annotiert = aufmasse[index].annotiertDateiname
        var next = aufmasse
        next.remove(at: index)
        try schreibeManifest(next)
        aufmasse = next
        try? FileManager.default.removeItem(at: ordnerURL.appendingPathComponent(original))
        if let annotiert {
            try? FileManager.default.removeItem(at: ordnerURL.appendingPathComponent(annotiert))
        }
    }

    /// Exportiert EIN Aufmaß als schön formatierte JSON-Datei (Maß-Datei) in ein
    /// temporäres Verzeichnis zum Teilen. Derivat, keine zweite Wahrheit.
    func aufmassExportJSON(_ id: UUID) throws -> URL {
        guard let aufmass = aufmasse.first(where: { $0.id == id }) else {
            throw AufmassError.nichtGefunden
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(aufmass)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Aufmass-\(id.uuidString).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Importiert eine einzelne exportierte „Maß-Datei" zurück in den Store —
    /// z. B. Wiederherstellung von einem anderen Gerät oder nach Teilen per
    /// AirDrop. Voraussetzung: das referenzierte Originalfoto liegt bereits in
    /// `Aufmasse/` — sonst Fehler statt eines stillen Datensatzes ohne Foto.
    /// Existiert die `id` schon, wird der bestehende Eintrag ersetzt (Re-Import
    /// als Update), sonst neu angelegt.
    @discardableResult
    func importAufmass(von url: URL) throws -> Aufmass {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: url)
        let importiert = try decoder.decode(Aufmass.self, from: data)
        guard FileManager.default.fileExists(atPath: originalBildURL(fuer: importiert).path) else {
            throw AufmassError.bilddateiFehltNachImport
        }
        var next = aufmasse
        if let index = next.firstIndex(where: { $0.id == importiert.id }) {
            next[index] = importiert
        } else {
            next.append(importiert)
        }
        try schreibeManifest(next)
        aufmasse = next
        return importiert
    }

    private func schreibeManifest(_ liste: [Aufmass]) throws {
        do {
            let data = try JSONEncoder().encode(liste)
            try data.write(to: manifestURL, options: .atomic)
        } catch {
            throw AufmassError.writeFailed(error.localizedDescription)
        }
    }
}
