import UIKit
import PencilKit

// MARK: - Normierte Koordinate (0…1, relativ zum Originalfoto)

/// DIE zentrale Modell-Entscheidung (übernommen aus mykilOS iOS `Aufmass.swift`):
/// Punkte werden auflösungs-, view- und zoom-UNABHÄNGIG als Anteil (0…1) der
/// Originalfoto-Kante gespeichert. Erst zur Laufzeit rechnen View und Renderer
/// auf die aktuelle Bildgröße hoch — so überleben Maße Zoom, Wiederöffnen und
/// Editieren, auch bei Split-View-Größenänderungen auf dem iPad.
struct NormPunkt: Codable, Hashable {
    var x: Double
    var y: Double

    init(x: Double, y: Double) { self.x = x; self.y = y }

    /// Aus einem Anzeige-Punkt in einem aspektgerecht eingepassten Bild.
    init(_ punkt: CGPoint, in groesse: CGSize) {
        x = groesse.width > 0 ? Double(punkt.x / groesse.width) : 0
        y = groesse.height > 0 ? Double(punkt.y / groesse.height) : 0
    }

    /// Zurück in Anzeige-/Pixel-Koordinaten einer gegebenen Bildgröße.
    func cgPoint(in groesse: CGSize) -> CGPoint {
        CGPoint(x: CGFloat(x) * groesse.width, y: CGFloat(y) * groesse.height)
    }
}

/// Ein normiertes Rechteck (0…1) — für die Bounding-Box einer Pencil-Freihand-
/// Annotation, nach demselben Prinzip wie `NormPunkt`.
struct NormRect: Codable, Hashable {
    var x: Double
    var y: Double
    var breite: Double
    var hoehe: Double

    init(x: Double, y: Double, breite: Double, hoehe: Double) {
        self.x = x; self.y = y; self.breite = breite; self.hoehe = hoehe
    }

    init(_ rect: CGRect, in groesse: CGSize) {
        x = groesse.width > 0 ? Double(rect.origin.x / groesse.width) : 0
        y = groesse.height > 0 ? Double(rect.origin.y / groesse.height) : 0
        breite = groesse.width > 0 ? Double(rect.width / groesse.width) : 0
        hoehe = groesse.height > 0 ? Double(rect.height / groesse.height) : 0
    }

    func cgRect(in groesse: CGSize) -> CGRect {
        CGRect(
            x: CGFloat(x) * groesse.width,
            y: CGFloat(y) * groesse.height,
            width: CGFloat(breite) * groesse.width,
            height: CGFloat(hoehe) * groesse.height
        )
    }
}

// MARK: - Kleine geschlossene Enums

/// Woher der Maßwert kam — relevant fürs Neu-Einlesen bei veralteten Maßen.
/// Gegenüber der iOS-Vorlage um `.pencil` erweitert: ein Maß, das direkt aus
/// einer Pencil-Handschrifterkennung übernommen wurde (siehe `PencilErkennung`).
enum MassQuelle: String, Codable { case laser, manuell, pencil }

/// Feste Farbpalette für Maßlinien, auf die MykColor-Palette gemappt
/// (Mapping in der View/Renderer-Schicht, nicht im Modell). Codable-stabil.
enum MassFarbe: String, Codable, CaseIterable, Identifiable {
    case orange, blau, gruen, ocker, plum, rot
    var id: String { rawValue }

    var titel: String {
        switch self {
        case .orange: return "Orange"
        case .blau: return "Blau"
        case .gruen: return "Grün"
        case .ocker: return "Ocker"
        case .plum: return "Pflaume"
        case .rot: return "Rot"
        }
    }
}

/// Platzierbare Anschluss-/Ausstattungs-Symbole.
enum SymbolTyp: String, Codable, CaseIterable, Identifiable {
    case steckdose, lichtschalter, herdanschluss, abluft, zuluft
    case stromanschluss, wasseranschluss, gasanschluss, leuchte

    var id: String { rawValue }

    var titel: String {
        switch self {
        case .steckdose: return "Steckdose"
        case .lichtschalter: return "Lichtschalter"
        case .herdanschluss: return "Herd"
        case .abluft: return "Abluft"
        case .zuluft: return "Zuluft"
        case .stromanschluss: return "Strom"
        case .wasseranschluss: return "Wasser"
        case .gasanschluss: return "Gas"
        case .leuchte: return "Leuchte"
        }
    }

    /// SF-Symbol-Name.
    var sfName: String {
        switch self {
        case .steckdose: return "poweroutlet.type.f.fill"
        case .lichtschalter: return "switch.2"
        case .herdanschluss: return "cooktop.fill"
        case .abluft: return "fan.fill"
        case .zuluft: return "wind"
        case .stromanschluss: return "bolt.fill"
        case .wasseranschluss: return "drop.fill"
        case .gasanschluss: return "flame.fill"
        case .leuchte: return "lightbulb.fill"
        }
    }
}

// MARK: - Annotationen

/// Geometrie-Signatur einer Maßlinie zum Mess-Zeitpunkt — Grundlage der
/// "Maß veraltet"-Erkennung. Wird verglichen, nicht angezeigt.
struct GeometrieSignatur: Codable, Hashable {
    var p1: NormPunkt
    var p2: NormPunkt
}

/// Eine gerade Maßlinie zwischen zwei Punkten mit Maßwert.
struct MassAnnotation: Identifiable, Codable, Hashable {
    let id: UUID
    var p1: NormPunkt
    var p2: NormPunkt
    var wertMM: Int?
    var anzeige: String        // frei anzeigbarer Maßtext, z. B. "2450 mm"
    var quelle: MassQuelle
    var farbe: MassFarbe
    var gemessenBei: GeometrieSignatur?

    init(
        id: UUID = UUID(),
        p1: NormPunkt,
        p2: NormPunkt,
        wertMM: Int? = nil,
        anzeige: String = "",
        quelle: MassQuelle = .manuell,
        farbe: MassFarbe = .rot,
        gemessenBei: GeometrieSignatur? = nil
    ) {
        self.id = id
        self.p1 = p1
        self.p2 = p2
        self.wertMM = wertMM
        self.anzeige = anzeige
        self.quelle = quelle
        self.farbe = farbe
        self.gemessenBei = gemessenBei
    }

    /// Berechnet (nicht persistiert): ein Maß ist veraltet, wenn es einen Wert
    /// hat, aber die aktuellen Endpunkte von der gemessenen Geometrie abweichen.
    /// Single Source of Truth sind die Punkte.
    var istVeraltet: Bool {
        guard hatWert, let g = gemessenBei else { return false }
        let eps = 0.004
        func weit(_ a: NormPunkt, _ b: NormPunkt) -> Bool {
            abs(a.x - b.x) > eps || abs(a.y - b.y) > eps
        }
        return weit(p1, g.p1) || weit(p2, g.p2)
    }

    var hatWert: Bool { wertMM != nil || !anzeige.trimmingCharacters(in: .whitespaces).isEmpty }

    var mitte: NormPunkt { NormPunkt(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2) }
}

/// Ein Pin mit schriftlicher Notiz.
struct NotizAnnotation: Identifiable, Codable, Hashable {
    let id: UUID
    var position: NormPunkt
    var text: String

    init(id: UUID = UUID(), position: NormPunkt, text: String) {
        self.id = id
        self.position = position
        self.text = text
    }
}

/// Ein platziertes Anschluss-/Ausstattungs-Symbol.
struct SymbolAnnotation: Identifiable, Codable, Hashable {
    let id: UUID
    var position: NormPunkt
    var typ: SymbolTyp
    var farbe: MassFarbe
    var beschriftung: String

    init(id: UUID = UUID(), position: NormPunkt, typ: SymbolTyp, farbe: MassFarbe = .rot, beschriftung: String = "") {
        self.id = id
        self.position = position
        self.typ = typ
        self.farbe = farbe
        self.beschriftung = beschriftung
    }
}

/// Ein gemessener Winkel: Scheitel (Ecke) + zwei Schenkel-Endpunkte.
/// Die Gradzahl wird IN PIXELN aus den drei Punkten berechnet (nicht in
/// Norm-Koordinaten — die verzerren bei nicht-quadratischem Foto).
struct WinkelAnnotation: Identifiable, Codable, Hashable {
    let id: UUID
    var scheitel: NormPunkt
    var schenkelA: NormPunkt
    var schenkelB: NormPunkt
    var gradzahl: Double?

    init(id: UUID = UUID(), scheitel: NormPunkt, schenkelA: NormPunkt, schenkelB: NormPunkt, gradzahl: Double? = nil) {
        self.id = id
        self.scheitel = scheitel
        self.schenkelA = schenkelA
        self.schenkelB = schenkelB
        self.gradzahl = gradzahl
    }
}

/// **Neu gegenüber mykilOS iOS**: eine Apple-Pencil-Freihand-Annotation.
/// Die `PKDrawing` wird als ihr eigenes `dataRepresentation()` (PencilKit-
/// natives Binärformat, verlustfrei inkl. Druck/Neigung/Geschwindigkeit)
/// gespeichert, die Bounding-Box zusätzlich normiert für schnelles Hit-Testing
/// ohne die Drawing-Daten decodieren zu müssen.
struct FreihandAnnotation: Identifiable, Codable, Hashable {
    let id: UUID
    var boundingBox: NormRect
    var drawingData: Data
    var farbe: MassFarbe

    init(id: UUID = UUID(), boundingBox: NormRect, drawingData: Data, farbe: MassFarbe = .rot) {
        self.id = id
        self.boundingBox = boundingBox
        self.drawingData = drawingData
        self.farbe = farbe
    }

    func pkDrawing() -> PKDrawing? {
        try? PKDrawing(data: drawingData)
    }
}

/// Diskriminierte Enum, die ALLE Annotationstypen in EINER Liste trägt —
/// Reihenfolge/Undo trivial, Export ist ein simples `map`. Codable über einen
/// String-Diskriminator `typ` + `daten`.
enum Aufmassannotation: Hashable, Identifiable {
    case mass(MassAnnotation)
    case notiz(NotizAnnotation)
    case symbol(SymbolAnnotation)
    case winkel(WinkelAnnotation)
    case freihand(FreihandAnnotation)

    var id: UUID {
        switch self {
        case .mass(let a): return a.id
        case .notiz(let a): return a.id
        case .symbol(let a): return a.id
        case .winkel(let a): return a.id
        case .freihand(let a): return a.id
        }
    }
}

extension Aufmassannotation: Codable {
    private enum CodingKeys: String, CodingKey { case typ, daten }
    private enum Typ: String, Codable { case mass, notiz, symbol, winkel, freihand }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(Typ.self, forKey: .typ) {
        case .mass: self = .mass(try c.decode(MassAnnotation.self, forKey: .daten))
        case .notiz: self = .notiz(try c.decode(NotizAnnotation.self, forKey: .daten))
        case .symbol: self = .symbol(try c.decode(SymbolAnnotation.self, forKey: .daten))
        case .winkel: self = .winkel(try c.decode(WinkelAnnotation.self, forKey: .daten))
        case .freihand: self = .freihand(try c.decode(FreihandAnnotation.self, forKey: .daten))
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .mass(let a): try c.encode(Typ.mass, forKey: .typ); try c.encode(a, forKey: .daten)
        case .notiz(let a): try c.encode(Typ.notiz, forKey: .typ); try c.encode(a, forKey: .daten)
        case .symbol(let a): try c.encode(Typ.symbol, forKey: .typ); try c.encode(a, forKey: .daten)
        case .winkel(let a): try c.encode(Typ.winkel, forKey: .typ); try c.encode(a, forKey: .daten)
        case .freihand(let a): try c.encode(Typ.freihand, forKey: .typ); try c.encode(a, forKey: .daten)
        }
    }
}

// MARK: - Das Aufmaß-Dokument

/// Ein lebendiges, editierbares Aufmaß-Dokument: Originalfoto + Datum + optional
/// Projekt + Gesamt-Kommentar + Liste von Annotationen. Bewusst NICHT als
/// FeldFoto modelliert — ein FeldFoto ist ein unveränderlicher Sync-Beweis, ein
/// Aufmaß dagegen wird bearbeitet (Maße verschieben/veralten). Verbindung nur
/// als lose `feldFotoID`, wenn das eingebrannte Ergebnis zusätzlich als Feld-Foto
/// abgelegt wird.
///
/// Übernommen aus mykilOS iOS (`Aufmass.swift`), Projekt-Zuordnung bewusst als
/// lose optionale Strings belassen (kein hartes Foreign-Key-Modell) — passend
/// zum flexiblen, projektfreien Anlegen im Studio-Alltag.
struct Aufmass: Identifiable, Codable, Hashable {
    let id: UUID
    let erstelltAm: Date
    var geaendertAm: Date
    let originalDateiname: String       // <id>-original.jpg (unannotiert)
    var annotiertDateiname: String?     // <id>-annotiert.jpg (Momentaufnahme beim Einbrennen)
    let bildBreite: Double              // Referenzmaße des Originalfotos
    let bildHoehe: Double
    var kommentar: String
    var projectNumber: String?          // OPTIONAL — projektfreies Anlegen ist Default
    var projectTitel: String?
    var raumTitel: String?              // Optionaler Raumname, z. B. "Küche EG"
    var feldFotoID: UUID?
    var annotationen: [Aufmassannotation]

    init(
        id: UUID = UUID(),
        erstelltAm: Date = Date(),
        geaendertAm: Date = Date(),
        originalDateiname: String,
        annotiertDateiname: String? = nil,
        bildBreite: Double,
        bildHoehe: Double,
        kommentar: String = "",
        projectNumber: String? = nil,
        projectTitel: String? = nil,
        raumTitel: String? = nil,
        feldFotoID: UUID? = nil,
        annotationen: [Aufmassannotation] = []
    ) {
        self.id = id
        self.erstelltAm = erstelltAm
        self.geaendertAm = geaendertAm
        self.originalDateiname = originalDateiname
        self.annotiertDateiname = annotiertDateiname
        self.bildBreite = bildBreite
        self.bildHoehe = bildHoehe
        self.kommentar = kommentar
        self.projectNumber = projectNumber
        self.projectTitel = projectTitel
        self.raumTitel = raumTitel
        self.feldFotoID = feldFotoID
        self.annotationen = annotationen
    }

    private enum CodingKeys: String, CodingKey {
        case id, erstelltAm, geaendertAm, originalDateiname, annotiertDateiname
        case bildBreite, bildHoehe, kommentar, projectNumber, projectTitel, raumTitel, feldFotoID, annotationen
    }

    /// Handgeschrieben: spätere Phasen fügen Felder additiv hinzu;
    /// `decodeIfPresent` hält bereits gespeicherte `aufmasse.json` lesbar.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        erstelltAm = try c.decode(Date.self, forKey: .erstelltAm)
        geaendertAm = try c.decodeIfPresent(Date.self, forKey: .geaendertAm) ?? erstelltAm
        originalDateiname = try c.decode(String.self, forKey: .originalDateiname)
        annotiertDateiname = try c.decodeIfPresent(String.self, forKey: .annotiertDateiname)
        bildBreite = try c.decodeIfPresent(Double.self, forKey: .bildBreite) ?? 0
        bildHoehe = try c.decodeIfPresent(Double.self, forKey: .bildHoehe) ?? 0
        kommentar = try c.decodeIfPresent(String.self, forKey: .kommentar) ?? ""
        projectNumber = try c.decodeIfPresent(String.self, forKey: .projectNumber)
        projectTitel = try c.decodeIfPresent(String.self, forKey: .projectTitel)
        raumTitel = try c.decodeIfPresent(String.self, forKey: .raumTitel)
        feldFotoID = try c.decodeIfPresent(UUID.self, forKey: .feldFotoID)
        annotationen = try c.decodeIfPresent([Aufmassannotation].self, forKey: .annotationen) ?? []
    }
}
