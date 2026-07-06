import Foundation

/// Gemeinsame, hochgezogene Stores — gleiches Prinzip wie `HauptTabView` in
/// mykilOS iOS: einmal erzeugt, an alle Module durchgereicht, damit
/// Projekt-Auswahl und Aufmaß-Zuordnung überall denselben Stand sehen.
@MainActor
final class AppStores {
    let projectStore = ProjectStore()
    let aufmassStore = AufmassStore()
    let roomPlanStore = RoomPlanStore()
    let grundrissStore = GrundrissEditorStore()
    let postboxStore = PostboxStore()
    let feldFotoStore = FeldFotoStore()
}
