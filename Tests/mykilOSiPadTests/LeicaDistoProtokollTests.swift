import Testing
import Foundation
@testable import mykilOSiPad

struct LeicaDistoProtokollTests {
    private func float32LEData(_ wert: Float) -> Data {
        withUnsafeBytes(of: wert.bitPattern.littleEndian) { Data($0) }
    }

    @Test func distanzInMMDekodiertPlausiblenWert() {
        let daten = float32LEData(2.45) // Meter
        let mm = LeicaDistoProtokoll.distanzInMM(aus: daten)
        #expect(mm == 2450)
    }

    @Test func distanzInMMVerwirftZuKurzeDistanz() {
        let daten = float32LEData(0.01) // 1 cm, unterhalb 2-cm-Plausibilitätsfenster
        #expect(LeicaDistoProtokoll.distanzInMM(aus: daten) == nil)
    }

    @Test func distanzInMMVerwirftZuLangeDistanz() {
        let daten = float32LEData(600) // 600 m, oberhalb 500-m-Fenster
        #expect(LeicaDistoProtokoll.distanzInMM(aus: daten) == nil)
    }

    @Test func distanzInMMVerwirftZuKurzeDaten() {
        let daten = Data([0x01, 0x02])
        #expect(LeicaDistoProtokoll.distanzInMM(aus: daten) == nil)
    }

    @Test func distanzInMMVerwirftNichtEndlicheWerte() {
        let daten = float32LEData(Float.infinity)
        #expect(LeicaDistoProtokoll.distanzInMM(aus: daten) == nil)
    }
}
