import Testing
import simd
@testable import mykilOSiPad

/// Reine Distanz-/Formatierungslogik des AR-Maßbands — die ARKit-Session
/// selbst ist nicht testbar, die Zustandsmaschine (erster Punkt → zweiter
/// Punkt → Abstand) aber sehr wohl.
@MainActor
struct ARMassbandMesserTests {
    @Test func ersterPunktSetztNochKeinenAbstand() {
        let messer = ARMassbandMesser()
        messer.punktGesetzt(SIMD3<Float>(0, 0, 0))
        #expect(messer.ersterPunkt != nil)
        #expect(messer.abstandMeter == nil)
        #expect(messer.abstandText == nil)
    }

    @Test func zweiterPunktBerechnetEuklidischenAbstand() {
        let messer = ARMassbandMesser()
        messer.punktGesetzt(SIMD3<Float>(0, 0, 0))
        messer.punktGesetzt(SIMD3<Float>(3, 4, 0)) // 3-4-5-Dreieck → 5 m
        #expect(messer.abstandMeter != nil)
        #expect(abs((messer.abstandMeter ?? 0) - 5) < 0.0001)
        #expect(messer.ersterPunkt == nil) // Kette zurückgesetzt für nächste Messung
    }

    @Test func abstandTextUnterEinemMeterInZentimeter() {
        let messer = ARMassbandMesser()
        messer.punktGesetzt(SIMD3<Float>(0, 0, 0))
        messer.punktGesetzt(SIMD3<Float>(0.5, 0, 0)) // 50 cm
        #expect(messer.abstandText == "50 cm")
    }

    @Test func abstandTextAbEinemMeterInMeter() {
        let messer = ARMassbandMesser()
        messer.punktGesetzt(SIMD3<Float>(0, 0, 0))
        messer.punktGesetzt(SIMD3<Float>(2.5, 0, 0))
        #expect(messer.abstandText == "2.50 m")
    }

    @Test func zuruecksetzenLoeschtAllesZurueck() {
        let messer = ARMassbandMesser()
        messer.punktGesetzt(SIMD3<Float>(0, 0, 0))
        messer.punktGesetzt(SIMD3<Float>(1, 0, 0))
        messer.zuruecksetzen()
        #expect(messer.ersterPunkt == nil)
        #expect(messer.abstandMeter == nil)
    }
}
