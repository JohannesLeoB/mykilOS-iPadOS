import Testing
import CoreGraphics
import Foundation
@testable import mykilOSiPad

struct AufmassModelTests {
    @Test func normPunktRoundtripUeberlebtGroessenwechsel() {
        let original = CGPoint(x: 150, y: 300)
        let groesse = CGSize(width: 1000, height: 2000)
        let norm = NormPunkt(original, in: groesse)
        let zurueck = norm.cgPoint(in: groesse)
        #expect(abs(zurueck.x - original.x) < 0.01)
        #expect(abs(zurueck.y - original.y) < 0.01)
    }

    @Test func massAnnotationIstVeraltetWennGeometrieAbweicht() {
        let p1 = NormPunkt(x: 0.1, y: 0.1)
        let p2 = NormPunkt(x: 0.5, y: 0.1)
        var mass = MassAnnotation(p1: p1, p2: p2, anzeige: "1000 mm", gemessenBei: GeometrieSignatur(p1: p1, p2: p2))
        #expect(mass.istVeraltet == false)

        mass.p2 = NormPunkt(x: 0.7, y: 0.1) // deutlich verschoben
        #expect(mass.istVeraltet == true)
    }

    @Test func massAnnotationOhneWertIstNieVeraltet() {
        let p1 = NormPunkt(x: 0, y: 0)
        let p2 = NormPunkt(x: 1, y: 1)
        let mass = MassAnnotation(p1: p1, p2: p2)
        #expect(mass.hatWert == false)
        #expect(mass.istVeraltet == false)
    }

    @Test func aufmassannotationCodableRoundtripUeberAlleFaelle() throws {
        let annotationen: [Aufmassannotation] = [
            .mass(MassAnnotation(p1: NormPunkt(x: 0, y: 0), p2: NormPunkt(x: 1, y: 1))),
            .notiz(NotizAnnotation(position: NormPunkt(x: 0.2, y: 0.2), text: "Test")),
            .symbol(SymbolAnnotation(position: NormPunkt(x: 0.3, y: 0.3), typ: .steckdose)),
            .winkel(WinkelAnnotation(scheitel: NormPunkt(x: 0.5, y: 0.5), schenkelA: NormPunkt(x: 0.4, y: 0.4), schenkelB: NormPunkt(x: 0.6, y: 0.6))),
            .freihand(FreihandAnnotation(boundingBox: NormRect(x: 0, y: 0, breite: 0.1, hoehe: 0.1), drawingData: Data()))
        ]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(annotationen)
        let decoded = try decoder.decode([Aufmassannotation].self, from: data)
        #expect(decoded.count == annotationen.count)
        #expect(decoded.map(\.id) == annotationen.map(\.id))
    }

    @Test func grundrissDokumentLabelZaehlenHoch() {
        var dokument = GrundrissDokument()
        #expect(dokument.naechstesWandLabel() == "w1")
        dokument.waende.append(GrundrissWand(start: .zero, ende: CGPoint(x: 1, y: 0), label: "w1"))
        #expect(dokument.naechstesWandLabel() == "w2")
        #expect(dokument.naechstesElementLabel() == "b1")
    }

    @Test func grundrissDokumentRaumGeometrieUebersetztWaendeUndOeffnungen() {
        var dokument = GrundrissDokument()
        let wand = GrundrissWand(start: CGPoint(x: 0, y: 0), ende: CGPoint(x: 4, y: 0), label: "w1")
        dokument.waende.append(wand)
        dokument.elemente.append(GrundrissElement(wandID: wand.id, anteil: 0.5, breiteMeter: 1, typ: .tuer, label: "b1"))

        let geometrie = dokument.raumGeometrie()
        #expect(geometrie.waende.count == 1)
        #expect(geometrie.oeffnungen.count == 1)
        #expect(abs(geometrie.waende[0].laengeMeter - 4) < 0.0001)
    }
}
