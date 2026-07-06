import CoreGraphics
import Foundation

/// Der branchenweit universelle Kernmodus (siehe `docs/AUFMASS_APP_MARKTVERGLEICH.md`):
/// von Grund auf Wände zeichnen, Tür-/Fenster-/Säulen-Elemente platzieren,
/// Textlabel für Räume — funktioniert auf JEDEM iPad, kein LiDAR nötig.
/// Layout-Idee (Werkzeugleiste Wände/Bauelement/Formen/Text, nummerierte
/// Wand-/Element-Labels) aus Referenz-Apps (hand:werk, Bosch MeasureOn,
/// STABILA Measures II) — Darstellung strikt in mykilOS-CI, keine
/// Wettbewerber-Farben.
///
/// Koordinaten sind Meter in einem freien 2D-Weltkoordinatensystem (nicht
/// normiert wie bei `Aufmass`/`NormPunkt` — hier gibt es kein Referenzfoto,
/// die Zeichenfläche ist unbegrenzt und wird über `pixelProMeter` skaliert
/// dargestellt).

/// Art eines an einer Wand platzierten Bauelements.
enum WandElementTyp: String, Codable, CaseIterable, Identifiable {
    case tuer, fenster, saeule

    var id: String { rawValue }

    var titel: String {
        switch self {
        case .tuer: return "Tür"
        case .fenster: return "Fenster"
        case .saeule: return "Säule"
        }
    }

    var sfName: String {
        switch self {
        case .tuer: return "door.left.hand.open"
        case .fenster: return "window.casement2"
        case .saeule: return "cylinder"
        }
    }
}

/// Eine gezeichnete Wand — analog zu `WandSegment` (RoomPlan), aber von Hand
/// erzeugt statt aus einem 3D-Scan extrahiert, deshalb mit eigenem, editierbarem
/// Label (w1, w2, …) statt einer reinen UUID.
struct GrundrissWand: Identifiable, Codable, Hashable {
    let id: UUID
    var start: CGPoint
    var ende: CGPoint
    var label: String

    init(id: UUID = UUID(), start: CGPoint, ende: CGPoint, label: String) {
        self.id = id
        self.start = start
        self.ende = ende
        self.label = label
    }

    var laengeMeter: Double {
        Double(hypot(ende.x - start.x, ende.y - start.y))
    }

    func punkt(bei anteil: Double) -> CGPoint {
        CGPoint(
            x: start.x + (ende.x - start.x) * CGFloat(anteil),
            y: start.y + (ende.y - start.y) * CGFloat(anteil)
        )
    }
}

/// Ein Tür-/Fenster-/Säulen-Element, an einer Wand befestigt (Position als
/// Anteil 0…1 entlang der Wand) — bewegt sich mit, wenn die Wand später
/// verschoben wird.
struct GrundrissElement: Identifiable, Codable, Hashable {
    let id: UUID
    var wandID: UUID
    var anteil: Double          // 0…1 entlang der Wand
    var breiteMeter: Double
    var typ: WandElementTyp
    var label: String

    init(
        id: UUID = UUID(),
        wandID: UUID,
        anteil: Double,
        breiteMeter: Double = 0.9,
        typ: WandElementTyp,
        label: String
    ) {
        self.id = id
        self.wandID = wandID
        self.anteil = anteil
        self.breiteMeter = breiteMeter
        self.typ = typ
        self.label = label
    }
}

/// Ein frei platziertes Textlabel (Raumname o. Ä.), analog zu den grünen
/// Raumbezeichnungen ("Terrasse", "Küche" …) in den Referenz-Apps.
struct GrundrissTextLabel: Identifiable, Codable, Hashable {
    let id: UUID
    var position: CGPoint
    var text: String

    init(id: UUID = UUID(), position: CGPoint, text: String) {
        self.id = id
        self.position = position
        self.text = text
    }
}

/// Das Grundriss-Dokument — Projekt-/Raum-Zuordnung lose wie bei `Aufmass`
/// und `RoomPlanAufnahme`, kein hartes Foreign-Key-Modell.
struct GrundrissDokument: Identifiable, Codable, Hashable {
    let id: UUID
    let erstelltAm: Date
    var geaendertAm: Date
    var titel: String
    var projectNumber: String?
    var projectTitel: String?
    var raumTitel: String?
    var waende: [GrundrissWand]
    var elemente: [GrundrissElement]
    var texte: [GrundrissTextLabel]

    init(
        id: UUID = UUID(),
        erstelltAm: Date = Date(),
        geaendertAm: Date = Date(),
        titel: String = "Neuer Grundriss",
        projectNumber: String? = nil,
        projectTitel: String? = nil,
        raumTitel: String? = nil,
        waende: [GrundrissWand] = [],
        elemente: [GrundrissElement] = [],
        texte: [GrundrissTextLabel] = []
    ) {
        self.id = id
        self.erstelltAm = erstelltAm
        self.geaendertAm = geaendertAm
        self.titel = titel
        self.projectNumber = projectNumber
        self.projectTitel = projectTitel
        self.raumTitel = raumTitel
        self.waende = waende
        self.elemente = elemente
        self.texte = texte
    }

    /// Nächstes freies Wand-Label ("w1", "w2", …) nach dem Muster der
    /// Referenz-Apps.
    func naechstesWandLabel() -> String {
        "w\(waende.count + 1)"
    }

    /// Nächstes freies Element-Label ("b1", "b2", …).
    func naechstesElementLabel() -> String {
        "b\(elemente.count + 1)"
    }

    /// Wandelt das Dokument in die geräteunabhängige `RaumGeometrie` um, damit
    /// PDF- und DXF-Export (`GrundrissPDFRenderer`, `GrundrissDXFExporter`)
    /// unverändert wiederverwendet werden können — ein Renderer für beide
    /// Aufnahmewege (RoomPlan-Scan UND manueller Editor).
    func raumGeometrie() -> RaumGeometrie {
        var geometrie = RaumGeometrie()
        geometrie.waende = waende.map { WandSegment(id: $0.id, start: $0.start, ende: $0.ende) }
        geometrie.oeffnungen = elemente.compactMap { element -> OeffnungSegment? in
            guard let wand = waende.first(where: { $0.id == element.wandID }) else { return nil }
            let halbeBreite = CGFloat(element.breiteMeter / 2)
            let richtung = wand.laengeMeter > 0
                ? CGPoint(x: (wand.ende.x - wand.start.x) / CGFloat(wand.laengeMeter), y: (wand.ende.y - wand.start.y) / CGFloat(wand.laengeMeter))
                : CGPoint(x: 1, y: 0)
            let mitte = wand.punkt(bei: element.anteil)
            let start = CGPoint(x: mitte.x - richtung.x * halbeBreite, y: mitte.y - richtung.y * halbeBreite)
            let ende = CGPoint(x: mitte.x + richtung.x * halbeBreite, y: mitte.y + richtung.y * halbeBreite)
            let typ: OeffnungSegment.Typ = element.typ == .tuer ? .tuer : (element.typ == .fenster ? .fenster : .sonstige)
            return OeffnungSegment(id: element.id, start: start, ende: ende, typ: typ)
        }
        return geometrie
    }
}
