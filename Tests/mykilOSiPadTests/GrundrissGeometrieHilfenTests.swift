import Testing
import CoreGraphics
@testable import mykilOSiPad

struct GrundrissGeometrieHilfenTests {
    @Test func rasterFangRundetAufNaechstesRastermass() {
        let punkt = CGPoint(x: 1.23, y: 4.57)
        let gefangen = GrundrissGeometrieHilfen.rasterFang(punkt, rasterWeiteMeter: 0.1)
        #expect(abs(gefangen.x - 1.2) < 0.0001)
        #expect(abs(gefangen.y - 4.6) < 0.0001)
    }

    @Test func magnetFangSchnapptAufNahesWandende() {
        let wand = GrundrissWand(start: CGPoint(x: 0, y: 0), ende: CGPoint(x: 3, y: 0), label: "w1")
        let nahDran = CGPoint(x: 3.05, y: 0.05)
        let gefangen = GrundrissGeometrieHilfen.magnetFang(nahDran, waende: [wand], radiusMeter: 0.2)
        #expect(gefangen == wand.ende)
    }

    @Test func magnetFangLaesstFernenPunktUnveraendert() {
        let wand = GrundrissWand(start: CGPoint(x: 0, y: 0), ende: CGPoint(x: 3, y: 0), label: "w1")
        let weitWeg = CGPoint(x: 10, y: 10)
        let gefangen = GrundrissGeometrieHilfen.magnetFang(weitWeg, waende: [wand], radiusMeter: 0.2)
        #expect(gefangen == weitWeg)
    }

    @Test func abstandZuSegmentBerechnetSenkrechtenAbstand() {
        let abstand = GrundrissGeometrieHilfen.abstandZuSegment(
            CGPoint(x: 1, y: 1), start: CGPoint(x: 0, y: 0), ende: CGPoint(x: 2, y: 0)
        )
        #expect(abs(abstand - 1) < 0.0001)
    }

    @Test func naechsterPunktUndAnteilKlemmtAufSegmentEnden() {
        let (punkt, anteil) = GrundrissGeometrieHilfen.naechsterPunktUndAnteil(
            CGPoint(x: -5, y: 0), start: CGPoint(x: 0, y: 0), ende: CGPoint(x: 2, y: 0)
        )
        #expect(anteil == 0)
        #expect(punkt == CGPoint(x: 0, y: 0))
    }

    @Test func naechsteWandFindetInToleranz() {
        let wand1 = GrundrissWand(start: CGPoint(x: 0, y: 0), ende: CGPoint(x: 2, y: 0), label: "w1")
        let wand2 = GrundrissWand(start: CGPoint(x: 0, y: 5), ende: CGPoint(x: 2, y: 5), label: "w2")
        let treffer = GrundrissGeometrieHilfen.naechsteWand(zu: CGPoint(x: 1, y: 0.1), in: [wand1, wand2], toleranzMeter: 0.3)
        #expect(treffer?.label == "w1")
    }

    @Test func naechsteWandLiefertNilAusserhalbToleranz() {
        let wand1 = GrundrissWand(start: CGPoint(x: 0, y: 0), ende: CGPoint(x: 2, y: 0), label: "w1")
        let treffer = GrundrissGeometrieHilfen.naechsteWand(zu: CGPoint(x: 1, y: 5), in: [wand1], toleranzMeter: 0.3)
        #expect(treffer == nil)
    }
}
