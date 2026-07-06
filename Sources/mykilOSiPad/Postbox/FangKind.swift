import Foundation

/// Was der Versteh-Schritt aus einem Fang macht. 1:1 aus mykilOS iOS
/// übernommen.
enum FangKind: Equatable {
    case zeit(dauer: String, kontext: String)
    case idee(text: String)
    case fotoHinweis

    var titel: String {
        switch self {
        case .zeit: return "Zeit fangen · Karte → Bestätigung"
        case .idee: return "Idee fangen · Karte → Bestätigung"
        case .fotoHinweis: return "Feld-Foto"
        }
    }

    var koerper: String {
        switch self {
        case .zeit(let dauer, let kontext): return "\(dauer) · \(kontext)"
        case .idee(let text): return text
        case .fotoHinweis: return "Dafür gibt's einen echten Knopf, kein Tippen nötig."
        }
    }

    var meta: String {
        switch self {
        case .zeit:
            return "Landet in der Postbox als Zeit-Eintrag · Sync ist ein eigener, späterer Schritt"
        case .idee:
            return "Ziel: Ideen-Topf · getaggt, bevor der Gedanke verglüht"
        case .fotoHinweis:
            return "Tipp das Kamera-Symbol neben dem Eingabefeld an — Text allein macht kein Foto."
        }
    }

    var gesperrt: Bool {
        if case .fotoHinweis = self { return true }
        return false
    }

    /// Versteh-Kaskade — erkennt echte Dauer-Angaben im Freitext (statt sie
    /// zu erfinden). Was nicht als Zahl+Einheit im Text steht, wird nicht
    /// geraten.
    static func versteh(_ freitext: String) -> FangKind {
        let t = freitext.lowercased()
        if t.contains("foto") || t.contains("bild") || t.contains("scan") {
            return .fotoHinweis
        }
        if let dauer = erkannteDauer(in: freitext) {
            let rest = freitext.replacingOccurrences(of: dauer, with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: " ·-–—"))
            return .zeit(dauer: dauer, kontext: rest.isEmpty ? "ohne Kontext" : rest)
        }
        if t.contains("uhr") || t.contains("gebucht") || t.contains("cad") || t.contains("montage") {
            return .zeit(dauer: "?", kontext: freitext)
        }
        return .idee(text: freitext)
    }

    private static func erkannteDauer(in freitext: String) -> String? {
        guard let range = freitext.range(
            of: #"\d+([.,]\d+)?\s*(stunden?|minuten?|std|min|h)\b"#,
            options: [.regularExpression, .caseInsensitive]
        ) else { return nil }
        return String(freitext[range])
    }
}
