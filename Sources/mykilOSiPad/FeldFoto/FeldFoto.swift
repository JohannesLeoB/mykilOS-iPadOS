import Foundation

/// Die Kanon-Zielschublade — feste, kleine Auswahl, nie geraten, immer vom
/// Menschen bestätigt. 1:1 aus mykilOS iOS übernommen.
enum KanonZiel: String, Codable, CaseIterable, Identifiable {
    case bestand
    case rohbau
    case mangel

    var id: String { rawValue }

    var titel: String {
        switch self {
        case .bestand: return "Bestand"
        case .rohbau: return "Rohbau"
        case .mangel: return "Mangel"
        }
    }

    var ordner: String {
        switch self {
        case .bestand: return "02"
        case .rohbau: return "06 Fotos Baustelle"
        case .mangel: return "09"
        }
    }
}

/// Ein Feld-Foto, lokal auf dem Gerät geparkt — echt, neustart-fest.
/// EXIF-Zeit + Standort sind die Beweiskette für Abnahmen. Bild selbst
/// liegt als Datei in `Documents/FeldFotos/`, hier nur Dateiname + Metadaten.
///
/// Übernommen aus mykilOS iOS. `driveFileID`/`syncedAt` bleiben vorerst
/// immer `nil` — die Google-Drive-Anbindung ist hier noch nicht portiert
/// (siehe `WORK_STATUS.md`), die Felder existieren trotzdem schon, damit
/// spätere Anbindung keine Migration braucht.
struct FeldFoto: Identifiable, Codable {
    let id: UUID
    let dateiname: String
    let projectNumber: String
    let projectTitel: String
    let kanonZiel: KanonZiel
    let aufgenommenAm: Date
    var breitengrad: Double?
    var laengengrad: Double?
    var driveFileID: String?
    var syncedAt: Date?
    var foerderrelevant: Bool = false

    init(
        id: UUID = UUID(),
        dateiname: String,
        projectNumber: String,
        projectTitel: String,
        kanonZiel: KanonZiel,
        aufgenommenAm: Date = Date(),
        breitengrad: Double? = nil,
        laengengrad: Double? = nil,
        driveFileID: String? = nil,
        syncedAt: Date? = nil,
        foerderrelevant: Bool = false
    ) {
        self.id = id
        self.dateiname = dateiname
        self.projectNumber = projectNumber
        self.projectTitel = projectTitel
        self.kanonZiel = kanonZiel
        self.aufgenommenAm = aufgenommenAm
        self.breitengrad = breitengrad
        self.laengengrad = laengengrad
        self.driveFileID = driveFileID
        self.syncedAt = syncedAt
        self.foerderrelevant = foerderrelevant
    }

    private enum CodingKeys: String, CodingKey {
        case id, dateiname, projectNumber, projectTitel, kanonZiel, aufgenommenAm
        case breitengrad, laengengrad, driveFileID, syncedAt, foerderrelevant
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        dateiname = try container.decode(String.self, forKey: .dateiname)
        projectNumber = try container.decode(String.self, forKey: .projectNumber)
        projectTitel = try container.decode(String.self, forKey: .projectTitel)
        kanonZiel = try container.decode(KanonZiel.self, forKey: .kanonZiel)
        aufgenommenAm = try container.decode(Date.self, forKey: .aufgenommenAm)
        breitengrad = try container.decodeIfPresent(Double.self, forKey: .breitengrad)
        laengengrad = try container.decodeIfPresent(Double.self, forKey: .laengengrad)
        driveFileID = try container.decodeIfPresent(String.self, forKey: .driveFileID)
        syncedAt = try container.decodeIfPresent(Date.self, forKey: .syncedAt)
        foerderrelevant = try container.decodeIfPresent(Bool.self, forKey: .foerderrelevant) ?? false
    }
}
