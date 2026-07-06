import CoreGraphics
import Foundation

/// Geometrie-Hilfsfunktionen für den Grundriss-Editor: Rasterfang und
/// Magnet-Fang an vorhandenen Wandenden — die "Präzisions-Hilfen", die laut
/// Marktvergleich bei praktisch jeder Wettbewerber-App vorhanden sind
/// (STABILA: Lupe/Magnet/Raster).
enum GrundrissGeometrieHilfen {
    /// Rundet einen Weltpunkt (Meter) auf das nächste Rastermaß.
    static func rasterFang(_ punkt: CGPoint, rasterWeiteMeter: Double) -> CGPoint {
        guard rasterWeiteMeter > 0 else { return punkt }
        func runde(_ wert: CGFloat) -> CGFloat {
            (wert / CGFloat(rasterWeiteMeter)).rounded() * CGFloat(rasterWeiteMeter)
        }
        return CGPoint(x: runde(punkt.x), y: runde(punkt.y))
    }

    /// Sucht unter allen vorhandenen Wandenden das nächste innerhalb des
    /// Fang-Radius — Magnet-Effekt, damit Wände wirklich lückenlos anschließen.
    static func magnetFang(_ punkt: CGPoint, waende: [GrundrissWand], radiusMeter: Double) -> CGPoint {
        var bestenPunkt = punkt
        var besteDistanz = CGFloat(radiusMeter)
        for wand in waende {
            for ende in [wand.start, wand.ende] {
                let distanz = hypot(ende.x - punkt.x, ende.y - punkt.y)
                if distanz < besteDistanz {
                    besteDistanz = distanz
                    bestenPunkt = ende
                }
            }
        }
        return bestenPunkt
    }

    /// Kombiniert Magnet- vor Rasterfang (Magnet hat Vorrang, damit Wände
    /// exakt aneinander anschließen statt nur beide aufs Raster zu runden).
    static func fang(_ punkt: CGPoint, waende: [GrundrissWand], rasterWeiteMeter: Double, magnetRadiusMeter: Double) -> CGPoint {
        let magnet = magnetFang(punkt, waende: waende, radiusMeter: magnetRadiusMeter)
        if magnet != punkt { return magnet }
        return rasterFang(punkt, rasterWeiteMeter: rasterWeiteMeter)
    }

    /// Kürzester Abstand eines Punkts zu einem Liniensegment — Grundlage für
    /// Hit-Testing (Wand antippen zum Bemaßen/Bauelement-Platzieren).
    static func abstandZuSegment(_ punkt: CGPoint, start: CGPoint, ende: CGPoint) -> CGFloat {
        let (projiziert, _) = naechsterPunktUndAnteil(punkt, start: start, ende: ende)
        return hypot(projiziert.x - punkt.x, projiziert.y - punkt.y)
    }

    /// Projiziert `punkt` senkrecht auf das Segment start–ende und liefert
    /// zusätzlich den Anteil (0…1) entlang des Segments — Grundlage, um beim
    /// Antippen einer Wand die Position eines neuen Bauelements zu bestimmen.
    static func naechsterPunktUndAnteil(_ punkt: CGPoint, start: CGPoint, ende: CGPoint) -> (CGPoint, Double) {
        let dx = ende.x - start.x
        let dy = ende.y - start.y
        let laengeQuadrat = dx * dx + dy * dy
        guard laengeQuadrat > 0 else { return (start, 0) }
        var t = ((punkt.x - start.x) * dx + (punkt.y - start.y) * dy) / laengeQuadrat
        t = min(max(t, 0), 1)
        return (CGPoint(x: start.x + t * dx, y: start.y + t * dy), Double(t))
    }

    /// Findet die nächste Wand zu einem Punkt, sofern sie innerhalb von
    /// `toleranzMeter` liegt.
    static func naechsteWand(zu punkt: CGPoint, in waende: [GrundrissWand], toleranzMeter: Double) -> GrundrissWand? {
        var beste: GrundrissWand?
        var besteDistanz = CGFloat(toleranzMeter)
        for wand in waende {
            let distanz = abstandZuSegment(punkt, start: wand.start, ende: wand.ende)
            if distanz < besteDistanz {
                besteDistanz = distanz
                beste = wand
            }
        }
        return beste
    }
}
