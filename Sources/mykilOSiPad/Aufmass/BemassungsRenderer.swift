import PencilKit
import SwiftUI
import UIKit

// MARK: - Farb-Mapping (View/Renderer-Schicht, nicht im Datenmodell)

extension MassFarbe {
    private var hex: UInt32 {
        switch self {
        case .orange: return 0xEA5B25
        case .blau:   return 0x3B4A5E
        case .gruen:  return 0x2E7D4F
        case .ocker:  return 0xC99A3E
        case .plum:   return 0x8A5B73
        case .rot:    return 0xC0392B
        }
    }
    var uiFarbe: UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
    var farbe: Color { Color(uiFarbe) }
}

// MARK: - Einbrenn-Renderer (norm → Original-Pixel)

/// Brennt alle Annotationen eines Aufmaßes in voller Fotoauflösung ins Bild
/// ein. Norm-Koordinaten (0…1) werden auf die Original-Pixelmaße
/// hochgerechnet. 1:1 aus mykilOS iOS übernommen, um den neuen `.freihand`-
/// Fall (PKDrawing) ergänzt.
enum BemassungsRenderer {
    static func einbrennen(bild: UIImage, annotationen: [Aufmassannotation]) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let groesse = bild.size
        let faktor = groesse.width / 1000 // Referenz für Linien-/Schriftstärke
        let renderer = UIGraphicsImageRenderer(size: groesse, format: format)
        return renderer.image { ctx in
            bild.draw(in: CGRect(origin: .zero, size: groesse))
            let cg = ctx.cgContext
            let schrift = UIFont.boldSystemFont(ofSize: 15 * faktor)

            func plakette(_ s: String, mitte: CGPoint, farbe: UIColor) {
                let text = s as NSString
                let attr: [NSAttributedString.Key: Any] = [.font: schrift, .foregroundColor: farbe]
                let gr = text.size(withAttributes: attr)
                let rahmen = CGRect(x: mitte.x - gr.width/2 - 6*faktor, y: mitte.y - gr.height/2 - 3*faktor,
                                    width: gr.width + 12*faktor, height: gr.height + 6*faktor)
                UIColor.white.withAlphaComponent(0.9).setFill()
                UIBezierPath(roundedRect: rahmen, cornerRadius: 5*faktor).fill()
                text.draw(at: CGPoint(x: mitte.x - gr.width/2, y: mitte.y - gr.height/2), withAttributes: attr)
            }

            cg.setLineWidth(5 * faktor)
            cg.setLineCap(.round)
            for annot in annotationen {
                switch annot {
                case .mass(let m):
                    let uc = m.farbe.uiFarbe
                    let p1 = m.p1.cgPoint(in: groesse), p2 = m.p2.cgPoint(in: groesse)
                    cg.setStrokeColor(uc.cgColor)
                    cg.move(to: p1); cg.addLine(to: p2); cg.strokePath()
                    let r: CGFloat = 8 * faktor
                    cg.setFillColor(uc.cgColor)
                    for p in [p1, p2] { cg.fillEllipse(in: CGRect(x: p.x-r, y: p.y-r, width: 2*r, height: 2*r)) }
                    if m.hatWert {
                        let label = m.istVeraltet ? "\(m.anzeige.isEmpty ? "Maß" : m.anzeige) · veraltet" : m.anzeige
                        plakette(label, mitte: m.mitte.cgPoint(in: groesse), farbe: uc)
                    }
                case .notiz(let n):
                    let p = n.position.cgPoint(in: groesse)
                    let r: CGFloat = 10 * faktor
                    cg.setFillColor(UIColor.systemRed.cgColor)
                    cg.fillEllipse(in: CGRect(x: p.x-r, y: p.y-r, width: 2*r, height: 2*r))
                    cg.setStrokeColor(UIColor.white.cgColor); cg.setLineWidth(3*faktor)
                    cg.strokeEllipse(in: CGRect(x: p.x-r, y: p.y-r, width: 2*r, height: 2*r))
                    cg.setLineWidth(5*faktor)
                    if !n.text.isEmpty { plakette(n.text, mitte: CGPoint(x: p.x, y: p.y - 34*faktor), farbe: .systemRed) }
                case .symbol(let s):
                    let p = s.position.cgPoint(in: groesse)
                    let uc = s.farbe.uiFarbe
                    let dm: CGFloat = 46 * faktor
                    cg.setFillColor(UIColor.white.cgColor)
                    cg.fillEllipse(in: CGRect(x: p.x - dm/2, y: p.y - dm/2, width: dm, height: dm))
                    cg.setStrokeColor(uc.cgColor); cg.setLineWidth(4 * faktor)
                    cg.strokeEllipse(in: CGRect(x: p.x - dm/2, y: p.y - dm/2, width: dm, height: dm))
                    cg.setLineWidth(5 * faktor)
                    let conf = UIImage.SymbolConfiguration(pointSize: 24 * faktor, weight: .semibold)
                    if let img = UIImage(systemName: s.typ.sfName, withConfiguration: conf)?.withTintColor(uc, renderingMode: .alwaysOriginal) {
                        img.draw(in: CGRect(x: p.x - img.size.width/2, y: p.y - img.size.height/2, width: img.size.width, height: img.size.height))
                    }
                    let label = s.typ == .gasanschluss ? "GAS" : (s.beschriftung.isEmpty ? s.typ.titel : s.beschriftung)
                    plakette(label, mitte: CGPoint(x: p.x, y: p.y + dm/2 + 16 * faktor), farbe: uc)
                case .winkel(let w):
                    let uc = MassFarbe.orange.uiFarbe
                    let sp = w.scheitel.cgPoint(in: groesse)
                    cg.setStrokeColor(uc.cgColor); cg.setLineWidth(4 * faktor); cg.setLineJoin(.round)
                    cg.move(to: w.schenkelA.cgPoint(in: groesse)); cg.addLine(to: sp); cg.addLine(to: w.schenkelB.cgPoint(in: groesse)); cg.strokePath()
                    cg.setLineWidth(5 * faktor)
                    if let g = w.gradzahl {
                        plakette("\(Int(g.rounded()))°", mitte: CGPoint(x: sp.x, y: sp.y - 30 * faktor), farbe: uc)
                    }
                case .freihand(let f):
                    guard let zeichnung = f.pkDrawing() else { continue }
                    let rect = f.boundingBox.cgRect(in: groesse)
                    let bild = zeichnung.image(from: zeichnung.bounds, scale: UIScreen.main.scale)
                    bild.draw(in: rect)
                }
            }
        }
    }
}
