import Foundation

/// Ein gespeicherter RoomPlan-Scan — die USDZ-Datei liegt in
/// `Documents/RoomPlan/`, hier nur Metadaten. Gleiches Muster wie `Aufmass`.
/// Gegenüber mykilOS iOS: Projekt-Felder optional (projektfreies Scannen
/// erlaubt), plus `raumTitel`.
struct RoomPlanAufnahme: Identifiable, Codable, Hashable {
    let id: UUID
    let dateiname: String
    var projectNumber: String?
    var projectTitel: String?
    var raumTitel: String?
    let aufgenommenAm: Date

    init(
        id: UUID = UUID(),
        dateiname: String,
        projectNumber: String? = nil,
        projectTitel: String? = nil,
        raumTitel: String? = nil,
        aufgenommenAm: Date = Date()
    ) {
        self.id = id
        self.dateiname = dateiname
        self.projectNumber = projectNumber
        self.projectTitel = projectTitel
        self.raumTitel = raumTitel
        self.aufgenommenAm = aufgenommenAm
    }
}
