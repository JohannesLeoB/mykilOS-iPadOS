import Testing
@testable import mykilOSiPad

/// Die feste, kleine Gewerke-Auswahl der AR-Anker — stellt sicher, dass jede
/// Kategorie eine eigene Farbe/ein eigenes Symbol hat (kein leerer Marker).
struct GewerkeTypTests {
    @Test func vierKategorienInFesterReihenfolge() {
        #expect(GewerkeTyp.allCases == [.wasser, .strom, .abfluss, .sonstiges])
    }

    @Test func jedeKategorieHatEinSymbol() {
        for typ in GewerkeTyp.allCases {
            #expect(!typ.symbol.isEmpty)
        }
    }

    @Test func idIstDerRohwert() {
        #expect(GewerkeTyp.wasser.id == "Wasser")
        #expect(GewerkeTyp.abfluss.id == "Abfluss")
    }
}
