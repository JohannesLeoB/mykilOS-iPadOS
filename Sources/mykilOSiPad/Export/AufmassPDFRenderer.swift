import UIKit

/// Erzeugt aus einem Aufmaß einen teilbaren PDF-Bericht: das eingebrannte Foto
/// groß + Kopf (Datum/Projekt/Raum/Kommentar) + eine saubere Liste aller Maße
/// (mit Farbe & Gültig/Veraltet-Status), Notizen, Symbole, Winkel und
/// Pencil-Freihandnotizen.
///
/// Übernommen aus mykilOS iOS (`AufmassPDFRenderer.swift`), um die neue
/// `.freihand`-Annotation (Apple Pencil) ergänzt und um `raumTitel`.
enum AufmassPDFRenderer {
    static func rendere(aufmass: Aufmass, annotiertesBild: UIImage) throws -> URL {
        let seite = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 @ 72 dpi
        let rand: CGFloat = 40
        let inhalt = seite.width - 2 * rand
        let brand = UIColor(red: 0xEA/255, green: 0x5B/255, blue: 0x25/255, alpha: 1)

        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "EEEE, d. MMMM yyyy · HH:mm"

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Aufmass-\(aufmass.id.uuidString).pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: seite)

        try renderer.writePDF(to: url) { ctx in
            ctx.beginPage()
            var y: CGFloat = rand

            func zeile(_ s: String, font: UIFont, farbe: UIColor = .black, abstand: CGFloat = 5) {
                let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: farbe]
                let bb = (s as NSString).boundingRect(
                    with: CGSize(width: inhalt, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attr, context: nil)
                if y + bb.height > seite.height - rand { ctx.beginPage(); y = rand }
                (s as NSString).draw(with: CGRect(x: rand, y: y, width: inhalt, height: bb.height),
                                     options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attr, context: nil)
                y += bb.height + abstand
            }

            zeile("Aufmaß", font: .boldSystemFont(ofSize: 24), farbe: brand)
            zeile(df.string(from: aufmass.erstelltAm), font: .systemFont(ofSize: 11), farbe: .darkGray)
            if let pt = aufmass.projectTitel {
                let nr = aufmass.projectNumber.map { " · \($0)" } ?? ""
                zeile("Projekt: \(pt)\(nr)", font: .systemFont(ofSize: 12))
            }
            if let raum = aufmass.raumTitel {
                zeile("Raum: \(raum)", font: .systemFont(ofSize: 12))
            }
            if !aufmass.kommentar.isEmpty { zeile(aufmass.kommentar, font: .italicSystemFont(ofSize: 12), farbe: .darkGray) }
            y += 8

            // Eingebranntes Foto
            let maxH: CGFloat = 400
            let s = min(inhalt / annotiertesBild.size.width, maxH / annotiertesBild.size.height)
            let bw = annotiertesBild.size.width * s, bh = annotiertesBild.size.height * s
            if y + bh > seite.height - rand { ctx.beginPage(); y = rand }
            annotiertesBild.draw(in: CGRect(x: rand, y: y, width: bw, height: bh))
            y += bh + 18

            zeile("Maße & Einträge", font: .boldSystemFont(ofSize: 15), farbe: brand, abstand: 8)

            var massNr = 0
            for annot in aufmass.annotationen {
                switch annot {
                case .mass(let m):
                    massNr += 1
                    let wert = m.anzeige.isEmpty ? "—" : m.anzeige
                    let status = m.istVeraltet ? "  ⚠︎ veraltet, neu messen" : ""
                    zeile("Maß \(massNr): \(wert)   [\(m.farbe.titel)]\(status)", font: .systemFont(ofSize: 12),
                          farbe: m.istVeraltet ? UIColor(red: 0xB4/255, green: 0x50/255, blue: 0x3C/255, alpha: 1) : .black)
                case .notiz(let n):
                    zeile("Notiz: \(n.text)", font: .systemFont(ofSize: 12))
                case .symbol(let sy):
                    let z = sy.beschriftung.isEmpty ? "" : " — \(sy.beschriftung)"
                    zeile("Symbol: \(sy.typ.titel)\(z)", font: .systemFont(ofSize: 12))
                case .winkel(let w):
                    zeile("Winkel: \(w.gradzahl.map { "\(Int($0.rounded()))°" } ?? "—")", font: .systemFont(ofSize: 12))
                case .freihand:
                    zeile("Freihand-Notiz (Apple Pencil) — im Foto eingebrannt", font: .systemFont(ofSize: 12), farbe: .darkGray)
                }
            }
            if massNr == 0 && aufmass.annotationen.isEmpty {
                zeile("(noch keine Einträge)", font: .italicSystemFont(ofSize: 12), farbe: .gray)
            }
        }
        return url
    }
}
