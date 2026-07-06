import Foundation

/// Die vier Zeichen-Werkzeuge, angelehnt an die Werkzeugleiste der
/// Referenz-Apps (Wände/Bauelement/Formen/Text), plus ein reiner Messen-
/// Modus zum Nachjustieren einer bereits gezeichneten Wandlänge.
enum GrundrissEditorModus: String, CaseIterable, Identifiable {
    case waende, bauelement, formen, text, messen

    var id: String { rawValue }

    var titel: String {
        switch self {
        case .waende: return "Wände"
        case .bauelement: return "Bauelement"
        case .formen: return "Formen"
        case .text: return "Text"
        case .messen: return "Messen"
        }
    }

    var sfName: String {
        switch self {
        case .waende: return "pencil.line"
        case .bauelement: return "door.left.hand.open"
        case .formen: return "square.dashed"
        case .text: return "textformat"
        case .messen: return "ruler"
        }
    }
}
