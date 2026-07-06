import Foundation

/// Ein Projekt aus der mykilOS-Registry. 1:1 aus mykilOS iOS übernommen
/// (bewusst additiv/tolerant dekodierbar — neue Felder dürfen jederzeit
/// dazukommen, ohne bestehende Ansichten zu brechen). Das ist jetzt DIE
/// zentrale Zuordnungsinstanz für Aufmaß/RoomPlan/Grundriss — keine freien
/// Textfelder mehr.
struct Project: Identifiable, Codable, Hashable {
    var id: String { projectNumber }

    let projectNumber: String
    let title: String
    let kind: String
    let customerNumber: String
    let driveFolderID: String

    var driveURL: URL? {
        URL(string: "https://drive.google.com/drive/folders/\(driveFolderID)")
    }
}
