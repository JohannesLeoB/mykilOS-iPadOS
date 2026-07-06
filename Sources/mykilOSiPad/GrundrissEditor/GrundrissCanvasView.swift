import SwiftUI

/// Die eigentliche Zeichenfläche des Grundriss-Editors. Weltkoordinaten sind
/// Meter (Ursprung oben links, keine negativen Koordinaten in dieser ersten
/// Version — reicht für den Einsatzfall "ein Grundriss von Grund auf
/// zeichnen"). `pixelProMeter` skaliert Meter auf Bildschirmpunkte; die
/// Fläche liegt in einem `ScrollView`, Pinch-Geste zoomt.
///
/// Strikt mykilOS-CI: Wände in `MykColor.ink`, Bauelemente/Hervorhebungen in
/// `MykColor.brand`, Hilfslinien in `MykColor.line` — bewusst KEINE
/// Wettbewerber-Farbcodierung (Blau=Fenster/Rot=Wand etc. wie in den
/// Referenz-Apps), Farbe bleibt in mykilOS für Status/Kategorien reserviert.
struct GrundrissCanvasView: View {
    @Binding var dokument: GrundrissDokument
    @Binding var modus: GrundrissEditorModus
    @Binding var rasterAn: Bool
    @Binding var rueckgaengigAnfrage: Bool
    var onAenderung: (GrundrissDokument) -> Void = { _ in }

    private let canvasGroesseMeter: CGFloat = 24
    private let rasterWeiteMeter = 0.1
    private let magnetRadiusMeter = 0.2

    @State private var pixelProMeter: CGFloat = 60
    @State private var ziehStart: CGPoint?
    @State private var ziehAktuell: CGPoint?
    @State private var undoStack: [GrundrissDokument] = []

    @State private var wandBemassung: WandBemassungsAuswahl?
    @State private var neueLaengeText = ""
    @State private var bauelementAuswahl: BauelementAuswahl?
    @State private var textEingabePunkt: CGPoint?
    @State private var textEingabeInhalt = ""
    @State private var laser = BluetoothLaserScanner.shared

    private struct WandBemassungsAuswahl: Identifiable {
        let id: UUID
        let wand: GrundrissWand
    }

    private struct BauelementAuswahl: Identifiable {
        let id = UUID()
        let wand: GrundrissWand
        let anteil: Double
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            canvas
                .frame(width: canvasGroesseMeter * pixelProMeter, height: canvasGroesseMeter * pixelProMeter)
                .gesture(zeichenGeste)
                .simultaneousGesture(zoomGeste)
        }
        .background(MykColor.paper)
        .onChange(of: rueckgaengigAnfrage) { _, neu in
            if neu {
                rueckgaengig()
                rueckgaengigAnfrage = false
            }
        }
        .sheet(item: $wandBemassung) { auswahl in
            wandLaengeSheet(auswahl.wand)
        }
        .confirmationDialog("Bauelement platzieren", isPresented: Binding(
            get: { bauelementAuswahl != nil },
            set: { if !$0 { bauelementAuswahl = nil } }
        )) {
            ForEach(WandElementTyp.allCases) { typ in
                Button(typ.titel) {
                    if let auswahl = bauelementAuswahl {
                        bauelementEinfuegen(wand: auswahl.wand, anteil: auswahl.anteil, typ: typ)
                    }
                    bauelementAuswahl = nil
                }
            }
            Button("Abbrechen", role: .cancel) { bauelementAuswahl = nil }
        }
        .alert("Textlabel", isPresented: Binding(
            get: { textEingabePunkt != nil },
            set: { if !$0 { textEingabePunkt = nil } }
        )) {
            TextField("z. B. \"Küche\"", text: $textEingabeInhalt)
            Button("Hinzufügen") {
                if let punkt = textEingabePunkt, !textEingabeInhalt.trimmingCharacters(in: .whitespaces).isEmpty {
                    pushUndo()
                    dokument.texte.append(GrundrissTextLabel(position: punkt, text: textEingabeInhalt))
                    onAenderung(dokument)
                }
                textEingabeInhalt = ""
                textEingabePunkt = nil
            }
            Button("Abbrechen", role: .cancel) {
                textEingabeInhalt = ""
                textEingabePunkt = nil
            }
        }
    }

    // MARK: - Zeichnen

    private var canvas: some View {
        Canvas { context, groesse in
            if rasterAn {
                zeichneRaster(&context, groesse: groesse)
            }
            for wand in dokument.waende {
                zeichneWand(wand, in: &context)
            }
            for element in dokument.elemente {
                if let wand = dokument.waende.first(where: { $0.id == element.wandID }) {
                    zeichneElement(element, an: wand, in: &context)
                }
            }
            for label in dokument.texte {
                zeichneText(label, in: &context)
            }
            if let start = ziehStart, let aktuell = ziehAktuell {
                zeichneVorschau(von: start, bis: aktuell, in: &context)
            }
        }
    }

    private func zeichneRaster(_ context: inout GraphicsContext, groesse: CGSize) {
        var pfad = Path()
        var meter: CGFloat = 0
        while meter <= canvasGroesseMeter {
            let position = meter * pixelProMeter
            pfad.move(to: CGPoint(x: position, y: 0))
            pfad.addLine(to: CGPoint(x: position, y: groesse.height))
            pfad.move(to: CGPoint(x: 0, y: position))
            pfad.addLine(to: CGPoint(x: groesse.width, y: position))
            meter += 1
        }
        context.stroke(pfad, with: .color(MykColor.line), lineWidth: 0.5)
    }

    private func zeichneWand(_ wand: GrundrissWand, in context: inout GraphicsContext) {
        var pfad = Path()
        pfad.move(to: viewPunkt(wand.start))
        pfad.addLine(to: viewPunkt(wand.ende))
        context.stroke(pfad, with: .color(MykColor.ink), style: StrokeStyle(lineWidth: 3, lineCap: .square))

        let mitte = viewPunkt(wand.punkt(bei: 0.5))
        let beschriftung = "\(wand.label) · \(String(format: "%.2f m", wand.laengeMeter))"
        context.draw(
            Text(beschriftung).font(.system(size: 11, design: .monospaced)).foregroundColor(MykColor.muted),
            at: CGPoint(x: mitte.x, y: mitte.y - 10)
        )
    }

    private func zeichneElement(_ element: GrundrissElement, an wand: GrundrissWand, in context: inout GraphicsContext) {
        let mitte = viewPunkt(wand.punkt(bei: element.anteil))
        let radius: CGFloat = 9
        let rect = CGRect(x: mitte.x - radius, y: mitte.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(MykColor.paper))
        context.stroke(Path(ellipseIn: rect), with: .color(MykColor.brand), lineWidth: 1.5)
        let iconRect = CGRect(x: mitte.x - 6, y: mitte.y - 6, width: 12, height: 12)
        context.draw(Image(systemName: element.typ.sfName), in: iconRect)
        context.draw(
            Text(element.label).font(.system(size: 9, design: .monospaced)).foregroundColor(MykColor.brand),
            at: CGPoint(x: mitte.x, y: mitte.y - radius - 8)
        )
    }

    private func zeichneText(_ label: GrundrissTextLabel, in context: inout GraphicsContext) {
        context.draw(
            Text(label.text).font(.system(size: 13, weight: .medium)).foregroundColor(MykColor.ink),
            at: viewPunkt(label.position)
        )
    }

    private func zeichneVorschau(von start: CGPoint, bis aktuell: CGPoint, in context: inout GraphicsContext) {
        switch modus {
        case .waende:
            var pfad = Path()
            pfad.move(to: viewPunkt(start))
            pfad.addLine(to: viewPunkt(aktuell))
            context.stroke(pfad, with: .color(MykColor.brand), style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
        case .formen:
            let rect = CGRect(
                x: min(viewPunkt(start).x, viewPunkt(aktuell).x),
                y: min(viewPunkt(start).y, viewPunkt(aktuell).y),
                width: abs(viewPunkt(aktuell).x - viewPunkt(start).x),
                height: abs(viewPunkt(aktuell).y - viewPunkt(start).y)
            )
            context.stroke(Path(rect), with: .color(MykColor.brand), style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
        default:
            break
        }
    }

    // MARK: - Koordinaten

    private func viewPunkt(_ welt: CGPoint) -> CGPoint {
        CGPoint(x: welt.x * pixelProMeter, y: welt.y * pixelProMeter)
    }

    private func weltPunkt(_ view: CGPoint) -> CGPoint {
        CGPoint(x: max(view.x, 0) / pixelProMeter, y: max(view.y, 0) / pixelProMeter)
    }

    private func fange(_ welt: CGPoint) -> CGPoint {
        GrundrissGeometrieHilfen.fang(
            welt, waende: dokument.waende,
            rasterWeiteMeter: rasterAn ? rasterWeiteMeter : 0.01,
            magnetRadiusMeter: magnetRadiusMeter
        )
    }

    // MARK: - Gesten

    private var zeichenGeste: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { wert in
                let welt = fange(weltPunkt(wert.startLocation))
                if ziehStart == nil { ziehStart = welt }
                ziehAktuell = fange(weltPunkt(wert.location))
            }
            .onEnded { wert in
                defer { ziehStart = nil; ziehAktuell = nil }
                let startWelt = fange(weltPunkt(wert.startLocation))
                let endeWelt = fange(weltPunkt(wert.location))
                let distanz = hypot(endeWelt.x - startWelt.x, endeWelt.y - startWelt.y)
                let warTap = distanz < 0.03

                switch modus {
                case .waende:
                    guard !warTap, distanz > 0.05 else { return }
                    pushUndo()
                    dokument.waende.append(GrundrissWand(start: startWelt, ende: endeWelt, label: dokument.naechstesWandLabel()))
                    onAenderung(dokument)
                case .formen:
                    guard !warTap, distanz > 0.1 else { return }
                    pushUndo()
                    rechteckEinfuegen(von: startWelt, bis: endeWelt)
                    onAenderung(dokument)
                case .bauelement:
                    guard warTap else { return }
                    if let wand = GrundrissGeometrieHilfen.naechsteWand(zu: endeWelt, in: dokument.waende, toleranzMeter: 0.3) {
                        let (_, anteil) = GrundrissGeometrieHilfen.naechsterPunktUndAnteil(endeWelt, start: wand.start, ende: wand.ende)
                        bauelementAuswahl = BauelementAuswahl(wand: wand, anteil: anteil)
                    }
                case .text:
                    guard warTap else { return }
                    textEingabePunkt = endeWelt
                case .messen:
                    guard warTap else { return }
                    if let wand = GrundrissGeometrieHilfen.naechsteWand(zu: endeWelt, in: dokument.waende, toleranzMeter: 0.3) {
                        neueLaengeText = String(format: "%.0f", wand.laengeMeter * 1000)
                        wandBemassung = WandBemassungsAuswahl(id: wand.id, wand: wand)
                    }
                }
            }
    }

    private var zoomGeste: some Gesture {
        MagnificationGesture()
            .onChanged { wert in
                let neu = pixelProMeter * wert
                pixelProMeter = min(max(neu, 20), 220)
            }
    }

    // MARK: - Mutationen

    private func pushUndo() {
        undoStack.append(dokument)
        if undoStack.count > 50 { undoStack.removeFirst() }
    }

    func rueckgaengig() {
        guard let letzter = undoStack.popLast() else { return }
        dokument = letzter
        onAenderung(dokument)
    }

    var kannRueckgaengig: Bool { !undoStack.isEmpty }

    private func rechteckEinfuegen(von start: CGPoint, bis ende: CGPoint) {
        let a = start
        let c = ende
        let b = CGPoint(x: c.x, y: a.y)
        let d = CGPoint(x: a.x, y: c.y)
        let ecken = [a, b, c, d, a]
        for i in 0..<4 {
            dokument.waende.append(GrundrissWand(start: ecken[i], ende: ecken[i + 1], label: dokument.naechstesWandLabel()))
        }
    }

    private func bauelementEinfuegen(wand: GrundrissWand, anteil: Double, typ: WandElementTyp) {
        pushUndo()
        dokument.elemente.append(GrundrissElement(wandID: wand.id, anteil: anteil, typ: typ, label: dokument.naechstesElementLabel()))
        onAenderung(dokument)
    }

    @ViewBuilder
    private func wandLaengeSheet(_ wand: GrundrissWand) -> some View {
        NavigationStack {
            Form {
                Section("Wand \(wand.label)") {
                    HStack {
                        TextField("Länge in mm", text: $neueLaengeText)
                            .keyboardType(.numberPad)
                        Text("mm").foregroundStyle(MykColor.muted)
                    }
                }
                if laser.aktiv, let messwert = laser.letzterMesswertMM {
                    Section {
                        Button("Aus Laser übernehmen: \(messwert) mm") {
                            neueLaengeText = String(messwert)
                        }
                    }
                }
            }
            .navigationTitle("Wandlänge anpassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { wandBemassung = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Übernehmen") {
                        if let neueLaengeMM = Double(neueLaengeText), neueLaengeMM > 0 {
                            pushUndo()
                            wandNeuLaengen(wand, aufMM: neueLaengeMM)
                            onAenderung(dokument)
                        }
                        wandBemassung = nil
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func wandNeuLaengen(_ wand: GrundrissWand, aufMM neueLaengeMM: Double) {
        guard let index = dokument.waende.firstIndex(where: { $0.id == wand.id }) else { return }
        let aktuelleLaenge = wand.laengeMeter
        guard aktuelleLaenge > 0 else { return }
        let richtung = CGPoint(
            x: (wand.ende.x - wand.start.x) / CGFloat(aktuelleLaenge),
            y: (wand.ende.y - wand.start.y) / CGFloat(aktuelleLaenge)
        )
        let neueLaengeMeter = CGFloat(neueLaengeMM / 1000)
        dokument.waende[index].ende = CGPoint(
            x: wand.start.x + richtung.x * neueLaengeMeter,
            y: wand.start.y + richtung.y * neueLaengeMeter
        )
    }
}
