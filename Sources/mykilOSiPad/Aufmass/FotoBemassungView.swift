import SwiftUI
import UIKit
import PencilKit

/// Foto-Bemaßung / Aufmaß — Foto ohne Projekt als "neues Aufmaß" anlegen, mit
/// geraden Maßlinien (Laser oder manuell), Notiz-Pins, Anschluss-Symbolen,
/// Winkelmessung UND Apple-Pencil-Freihand annotieren. Alles wird als
/// lebendiges, wieder-editierbares Aufmaß-Dokument (`AufmassStore`)
/// gespeichert.
///
/// Portiert aus mykilOS iOS (`FotoBemassungView.swift`), zwei Änderungen:
/// 1. Echte `ProjectStore`-Kopplung (Projektwahl-Sheet wie im Original),
///    aber (noch) keine `FeldFotoStore`-Kopplung — "Als Feld-Foto ablegen"
///    entfällt, bis dieses Subsystem portiert ist.
/// 2. Neues fünftes Werkzeug **Freihand** (Apple Pencil, PencilKit) — in
///    myMini noch gar nicht vorhanden.
struct FotoBemassungView: View {
    var aufmassStore: AufmassStore
    var projectStore: ProjectStore

    private let laser = BluetoothLaserScanner.shared
    @State private var projektSuche = ""

    private enum Werkzeug { case masslinie, notiz, symbol, winkel, freihand }
    private enum EditZiel: Identifiable {
        case mass(UUID), notiz(UUID), symbol(UUID), winkel(UUID)
        var id: String {
            switch self {
            case .mass(let i): return "m\(i)"
            case .notiz(let i): return "n\(i)"
            case .symbol(let i): return "s\(i)"
            case .winkel(let i): return "w\(i)"
            }
        }
    }

    @State private var dok: Aufmass?
    @State private var originalBild: UIImage?
    @State private var zeigeKamera = false
    @State private var werkzeug: Werkzeug = .masslinie
    @State private var ersterPunkt: NormPunkt?
    @State private var massText = ""
    @State private var notizText = ""
    @State private var anzeigeGroesse: CGSize = .zero
    @State private var editZiel: EditZiel?
    @State private var editText = ""
    @State private var zeigeZuordnung = false
    @State private var infoText: String?

    // Zoom/Pan
    @State private var zoom: CGFloat = 1
    @State private var pan: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var ziehen: CGSize = .zero

    private struct EndpunktRef: Equatable { let id: UUID; let endpunkt: Int } // 0 = p1, 1 = p2
    @State private var farbwahl: MassFarbe = .rot
    @State private var symbolwahl: SymbolTyp = .steckdose
    @State private var winkelPunkte: [NormPunkt] = []

    // Freihand (Apple Pencil)
    @State private var freihandZeichnung = PKDrawing()

    // Zug-Modus: Setzen (Default, mit Lupe) ⇄ Verschieben (Leinwand pannen)
    private enum ZugModus { case setzen, verschieben }
    @State private var zugModus: ZugModus = .setzen

    @State private var zugPunkt: CGPoint?
    @State private var zugEndpunkt: EndpunktRef?
    @State private var panStart: CGSize = .zero
    @State private var zugGestartet = false
    @State private var zugVerworfen = false

    // Export
    @State private var zeigeExport = false
    @State private var exportPDF: URL?
    @State private var exportJPEG: URL?
    @State private var exportJSON: URL?

    var body: some View {
        Group {
            if let dok, let bild = originalBild {
                editor(dok: dok, bild: bild)
            } else {
                startseite
            }
        }
        .navigationTitle(dok == nil ? "Aufmaß" : "Aufmaß bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $zeigeKamera) {
            KameraAufnahmeView(
                onAufnahme: { neuesBild, _ in zeigeKamera = false; neuesAufmass(neuesBild) },
                onAbbruch: { zeigeKamera = false }
            ).ignoresSafeArea()
        }
        .alert("Beschriftung", isPresented: Binding(get: { editZiel != nil }, set: { if !$0 { editZiel = nil } })) {
            TextField("Text", text: $editText)
            Button("Übernehmen") { editUebernehmen() }
            Button("Löschen", role: .destructive) { editLoeschen() }
            Button("Abbrechen", role: .cancel) { editZiel = nil }
        }
        .sheet(isPresented: $zeigeZuordnung) { zuordnungSheet }
        .sheet(isPresented: $zeigeExport) { exportSheet }
    }

    // MARK: Startseite (neu / fortsetzen)

    private var startseite: some View {
        List {
            Section {
                Button {
                    zeigeKamera = true
                } label: {
                    Label("Neues Aufmaß — Foto aufnehmen", systemImage: "camera.fill")
                }
            } footer: {
                Text("Kein Projekt nötig. Zwei Punkte antippen → gerade Maßlinie mit Laser-Maß, plus Notiz-Pins, Symbole, Winkel oder Pencil-Freihand. Projekt kannst du später zuordnen.")
            }
            if !aufmassStore.aufmasse.isEmpty {
                Section("Gespeicherte Aufmaße") {
                    ForEach(aufmassStore.aufmasse.sorted { $0.geaendertAm > $1.geaendertAm }) { a in
                        Button { oeffne(a) } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(a.raumTitel ?? a.projectTitel ?? "Ohne Zuordnung")
                                    .foregroundStyle(MykColor.ink)
                                Text("\(a.erstelltAm.formatted(date: .abbreviated, time: .shortened)) · \(a.annotationen.count) Einträge")
                                    .font(.caption).foregroundStyle(MykColor.muted)
                            }
                        }
                    }
                    .onDelete { idx in
                        let sortiert = aufmassStore.aufmasse.sorted { $0.geaendertAm > $1.geaendertAm }
                        for i in idx { try? aufmassStore.remove(sortiert[i].id) }
                    }
                }
            }
            if let error = aufmassStore.loadError {
                Text(error).font(.footnote).foregroundStyle(MykColor.crit)
            }
        }
    }

    // MARK: Editor

    private func editor(dok: Aufmass, bild: UIImage) -> some View {
        VStack(spacing: 8) {
            Picker("Werkzeug", selection: $werkzeug) {
                Text("Maß").tag(Werkzeug.masslinie)
                Text("Notiz").tag(Werkzeug.notiz)
                Text("Symbol").tag(Werkzeug.symbol)
                Text("Winkel").tag(Werkzeug.winkel)
                Text("Freihand").tag(Werkzeug.freihand)
            }
            .pickerStyle(.segmented).padding(.horizontal, 12)
            .onChange(of: werkzeug) { _, neu in
                ersterPunkt = nil; winkelPunkte = []
                if neu != .freihand { freihandUebernehmen(groesse: anzeigeGroesse) }
            }

            if werkzeug != .freihand {
                HStack(spacing: 8) {
                    Picker("Zug-Modus", selection: $zugModus) {
                        Label("Setzen", systemImage: "hand.point.up.left.and.text").tag(ZugModus.setzen)
                        Label("Verschieben", systemImage: "hand.draw").tag(ZugModus.verschieben)
                    }
                    .pickerStyle(.segmented)
                    if zoom > 1.01 {
                        Text("\(String(format: "%.1f", zoom))×")
                            .font(.caption2.weight(.bold)).foregroundStyle(MykColor.muted)
                    }
                }
                .padding(.horizontal, 12)
            }

            werkzeugEingabe

            GeometryReader { geo in
                let groesse = eingepasst(bild.size, in: geo.size)
                ZStack {
                    Image(uiImage: bild).resizable().scaledToFit()
                    ForEach(dok.annotationen) { annot in
                        annotationView(liveAnnot(annot, groesse: groesse), in: groesse)
                    }
                    if let ep = ersterPunkt {
                        let p = ep.cgPoint(in: groesse)
                        Circle().stroke(.red, lineWidth: 2).frame(width: 16, height: 16).position(p)
                    }
                    ForEach(Array(winkelPunkte.enumerated()), id: \.offset) { _, wp in
                        Circle().fill(MykColor.brand).frame(width: 12, height: 12).position(wp.cgPoint(in: groesse))
                    }
                    if let zp = zugPunkt {
                        Circle().stroke(.red, lineWidth: 2).frame(width: 20, height: 20).position(zp)
                        Circle().fill(.red).frame(width: 5, height: 5).position(zp)
                    }
                    if werkzeug == .freihand {
                        PKCanvasRepresentable(drawing: $freihandZeichnung)
                    }
                }
                .frame(width: groesse.width, height: groesse.height)
                .contentShape(Rectangle())
                .scaleEffect(werkzeug == .freihand ? 1 : zoom * pinch)
                .offset(x: werkzeug == .freihand ? 0 : pan.width + ziehen.width, y: werkzeug == .freihand ? 0 : pan.height + ziehen.height)
                .gesture(werkzeug == .freihand ? nil : MagnifyGesture()
                    .updating($pinch) { v, s, _ in s = v.magnification }
                    .onEnded { v in
                        zoom = min(max(zoom * v.magnification, 1), 6)
                        if zoom <= 1.01 { zoom = 1; pan = .zero }
                    }
                )
                .simultaneousGesture(werkzeug == .freihand ? nil : DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { v in zugGeaendert(v, groesse: groesse) }
                    .onEnded { v in zugBeendet(v, groesse: groesse) }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .overlay(alignment: .top) {
                    if zugModus == .setzen, werkzeug != .freihand, let zp = zugPunkt {
                        LupeOverlay(bild: bild, inhaltsGroesse: groesse, punkt: zp)
                            .padding(.top, 10)
                            .allowsHitTesting(false)
                            .transition(.opacity)
                    }
                }
                .onAppear { anzeigeGroesse = groesse }
                .onChange(of: geo.size) { _, _ in anzeigeGroesse = eingepasst(bild.size, in: geo.size) }
            }

            if let infoText { Text(infoText).font(.footnote).foregroundStyle(MykColor.ok) }

            HStack(spacing: 8) {
                Button(dok.raumTitel ?? dok.projectTitel ?? "Zuordnen") { zeigeZuordnung = true }
                    .buttonStyle(.bordered).font(.footnote.weight(.semibold)).lineLimit(1)
                if werkzeug == .freihand {
                    Button("Freihand übernehmen") { freihandUebernehmen(groesse: anzeigeGroesse) }
                        .buttonStyle(.bordered).font(.footnote.weight(.semibold))
                        .disabled(freihandZeichnung.strokes.isEmpty)
                } else {
                    Button("Zurück") { letzteZurueck() }
                        .buttonStyle(.bordered).font(.footnote.weight(.semibold))
                        .disabled(dok.annotationen.isEmpty && ersterPunkt == nil)
                    if zoom > 1.01 {
                        Button("1:1") { zoom = 1; pan = .zero }.buttonStyle(.bordered).font(.footnote.weight(.semibold))
                    }
                }
                Spacer()
                Button("Teilen") { exportiere() }
                    .buttonStyle(.borderedProminent).tint(MykColor.brand).font(.footnote.weight(.semibold))
                    .disabled(dok.annotationen.isEmpty)
                Button("Schließen") { self.dok = nil; self.originalBild = nil }
                    .buttonStyle(.bordered).font(.footnote.weight(.semibold))
            }
            .padding(.horizontal, 12).padding(.bottom, 10)
        }
        .background(MykColor.paper)
    }

    @ViewBuilder
    private func annotationView(_ annot: Aufmassannotation, in groesse: CGSize) -> some View {
        switch annot {
        case .mass(let m):
            let p1 = m.p1.cgPoint(in: groesse), p2 = m.p2.cgPoint(in: groesse)
            Path { p in p.move(to: p1); p.addLine(to: p2) }
                .stroke(m.farbe.farbe, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            endpunktMarke(p1, gewaehlt: zugEndpunkt == EndpunktRef(id: m.id, endpunkt: 0), farbe: m.farbe.farbe)
            endpunktMarke(p2, gewaehlt: zugEndpunkt == EndpunktRef(id: m.id, endpunkt: 1), farbe: m.farbe.farbe)
            plakette(m.istVeraltet ? "veraltet — neu messen" : (m.hatWert ? m.anzeige : "Maß?"),
                     farbe: m.istVeraltet ? Color(MykColor.crit) : m.farbe.farbe)
                .position(m.mitte.cgPoint(in: groesse))
                .onTapGesture { editText = laser.letzterMesswertMM.map { "\($0) mm" } ?? m.anzeige; editZiel = .mass(m.id) }
        case .notiz(let n):
            ZStack {
                Circle().fill(.red).frame(width: 12, height: 12).overlay(Circle().stroke(.white, lineWidth: 2))
                plakette(n.text.isEmpty ? "Notiz?" : n.text, farbe: .red).offset(y: -22)
            }
            .position(n.position.cgPoint(in: groesse))
            .onTapGesture { editText = n.text; editZiel = .notiz(n.id) }
        case .symbol(let s):
            VStack(spacing: 1) {
                ZStack {
                    Circle().fill(.white).frame(width: 30, height: 30).overlay(Circle().stroke(s.farbe.farbe, lineWidth: 2))
                    Image(systemName: s.typ.sfName).font(.system(size: 15, weight: .semibold)).foregroundStyle(s.farbe.farbe)
                }
                plakette(s.typ == .gasanschluss ? "GAS" : (s.beschriftung.isEmpty ? s.typ.titel : s.beschriftung), farbe: s.farbe.farbe)
            }
            .position(s.position.cgPoint(in: groesse))
            .onTapGesture { editText = s.beschriftung; editZiel = .symbol(s.id) }
        case .winkel(let w):
            let sp = w.scheitel.cgPoint(in: groesse)
            Path { p in
                p.move(to: w.schenkelA.cgPoint(in: groesse)); p.addLine(to: sp); p.addLine(to: w.schenkelB.cgPoint(in: groesse))
            }
            .stroke(MykColor.brand, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            plakette(w.gradzahl.map { "\(Int($0.rounded()))°" } ?? "Winkel", farbe: MykColor.brand)
                .position(CGPoint(x: sp.x, y: sp.y - 16))
                .onTapGesture { editText = ""; editZiel = .winkel(w.id) }
        case .freihand(let f):
            if let zeichnung = f.pkDrawing() {
                let rect = f.boundingBox.cgRect(in: groesse)
                Image(uiImage: zeichnung.image(from: zeichnung.bounds, scale: 1))
                    .resizable()
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .allowsHitTesting(false)
            }
        }
    }

    private func plakette(_ s: String, farbe: Color) -> some View {
        Text(s).font(.system(size: 9, weight: .bold)).foregroundStyle(farbe)
            .padding(.horizontal, 3).padding(.vertical, 1)
            .background(.white.opacity(0.9)).clipShape(RoundedRectangle(cornerRadius: 2))
    }

    private func endpunktMarke(_ p: CGPoint, gewaehlt: Bool, farbe: Color) -> some View {
        Circle().fill(farbe)
            .frame(width: gewaehlt ? 16 : 9, height: gewaehlt ? 16 : 9)
            .overlay(Circle().stroke(MykColor.ink, lineWidth: gewaehlt ? 2 : 0))
            .position(p)
    }

    // MARK: Aktionen

    private func neuesAufmass(_ bild: UIImage) {
        do {
            let a = try aufmassStore.anlegen(originalfoto: bild)
            dok = a; originalBild = bild
            ersterPunkt = nil; massText = ""; notizText = ""; winkelPunkte = []; zoom = 1; pan = .zero
        } catch { infoText = Fehlertext.deutsch(error) }
    }

    private func oeffne(_ a: Aufmass) {
        guard let bild = UIImage(contentsOfFile: aufmassStore.originalBildURL(fuer: a).path) else {
            infoText = "Foto nicht ladbar"; return
        }
        dok = a; originalBild = bild; ersterPunkt = nil; winkelPunkte = []; zoom = 1; pan = .zero
    }

    private var hinweis: String {
        if zugModus == .verschieben { return "Ein-Finger-Zug verschiebt die Leinwand" }
        if ersterPunkt != nil { return "Punkt B ziehen (Lupe) — oder Endpunkt zum Verschieben greifen" }
        return "Punkt A ziehen (mit Lupe) — oder Endpunkt zum Verschieben greifen"
    }

    private var farbwahlLeiste: some View {
        HStack(spacing: 8) {
            Text("Farbe").font(.caption2).foregroundStyle(MykColor.muted)
            ForEach(MassFarbe.allCases) { f in
                Circle().fill(f.farbe).frame(width: 22, height: 22)
                    .overlay(Circle().stroke(MykColor.ink, lineWidth: farbwahl == f ? 2 : 0))
                    .onTapGesture { farbwahl = f }
            }
            Spacer()
        }.padding(.horizontal, 12)
    }

    @ViewBuilder
    private var werkzeugEingabe: some View {
        switch werkzeug {
        case .masslinie:
            HStack(spacing: 8) {
                if let mm = laser.letzterMesswertMM {
                    Label("\(mm) mm", systemImage: "dot.radiowaves.left.and.right")
                        .font(.footnote.weight(.bold)).foregroundStyle(MykColor.brand)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(MykColor.brand.opacity(0.12)).clipShape(Capsule())
                        .accessibilityLabel("Laser-Messwert \(mm) Millimeter, wird automatisch übernommen")
                } else {
                    Text("Kein Laser").font(.caption).foregroundStyle(MykColor.muted)
                }
                TextField(massText.isEmpty ? "…oder manuell eintippen" : "manuell", text: $massText)
                    .textFieldStyle(.roundedBorder)
            }.padding(.horizontal, 12)
            farbwahlLeiste
            Text(hinweis).font(.caption)
                .foregroundStyle(ersterPunkt != nil ? MykColor.brand : MykColor.muted)
        case .notiz:
            TextField("Notiz (z. B. Steckdose fehlt)", text: $notizText)
                .textFieldStyle(.roundedBorder).padding(.horizontal, 12)
            Text("Punkt antippen").font(.caption).foregroundStyle(MykColor.muted)
        case .symbol:
            symbolPalette
            farbwahlLeiste
            Text("Symbol antippen zum Platzieren: \(symbolwahl.titel)")
                .font(.caption).foregroundStyle(MykColor.muted)
        case .winkel:
            Text("Wand A → Ecke → Wand B antippen  (\(winkelPunkte.count)/3)")
                .font(.caption).foregroundStyle(winkelPunkte.isEmpty ? MykColor.muted : MykColor.brand)
        case .freihand:
            Text("Mit Apple Pencil (oder Finger) direkt aufs Foto zeichnen — \"Freihand übernehmen\" speichert die Notiz.")
                .font(.caption).foregroundStyle(MykColor.muted)
                .padding(.horizontal, 12)
        }
    }

    private var symbolPalette: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SymbolTyp.allCases) { t in
                    VStack(spacing: 2) {
                        Image(systemName: t.sfName).font(.system(size: 20))
                            .foregroundStyle(symbolwahl == t ? MykColor.brand : MykColor.ink)
                        Text(t.titel).font(.caption2).foregroundStyle(MykColor.muted)
                    }
                    .frame(width: 64).padding(.vertical, 6)
                    .background(symbolwahl == t ? MykColor.brand.opacity(0.12) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture { symbolwahl = t }
                }
            }.padding(.horizontal, 12)
        }
    }

    // MARK: Zug-Gesten — eine DragGesture, verzweigt am Zug-Modus

    private func zugGeaendert(_ v: DragGesture.Value, groesse: CGSize) {
        if !zugGestartet {
            zugGestartet = true
            if zugModus == .verschieben {
                panStart = pan
            } else {
                let startNorm = NormPunkt(v.startLocation, in: groesse)
                if werkzeug == .masslinie, let d = dok, let treffer = endpunktTreffer(startNorm, in: d) {
                    zugEndpunkt = treffer
                }
            }
        }
        if pinch != 1 { zugVerworfen = true }
        if zugModus == .verschieben {
            pan = CGSize(width: panStart.width + v.translation.width,
                         height: panStart.height + v.translation.height)
        } else if !zugVerworfen {
            zugPunkt = begrenzt(v.location, in: groesse)
        } else {
            zugPunkt = nil
        }
    }

    private func zugBeendet(_ v: DragGesture.Value, groesse: CGSize) {
        defer { zugGestartet = false; zugVerworfen = false; zugPunkt = nil; zugEndpunkt = nil }
        guard zugModus == .setzen, !zugVerworfen else { return }
        let ziel = begrenzt(v.location, in: groesse)
        let np = NormPunkt(ziel, in: groesse)
        if let ref = zugEndpunkt {
            guard var d = dok,
                  let i = d.annotationen.firstIndex(where: { $0.id == ref.id }),
                  case .mass(var m) = d.annotationen[i] else { return }
            if ref.endpunkt == 0 { m.p1 = np } else { m.p2 = np }
            d.annotationen[i] = .mass(m)
            speichere(d)
            return
        }
        tippAufFoto(np, groesse: groesse)
    }

    private func begrenzt(_ p: CGPoint, in groesse: CGSize) -> CGPoint {
        CGPoint(x: min(max(p.x, 0), groesse.width), y: min(max(p.y, 0), groesse.height))
    }

    private func liveAnnot(_ annot: Aufmassannotation, groesse: CGSize) -> Aufmassannotation {
        guard let ref = zugEndpunkt, let zp = zugPunkt,
              case .mass(var m) = annot, m.id == ref.id else { return annot }
        let np = NormPunkt(zp, in: groesse)
        if ref.endpunkt == 0 { m.p1 = np } else { m.p2 = np }
        return .mass(m)
    }

    private func tippAufFoto(_ np: NormPunkt, groesse: CGSize) {
        guard var d = dok else { return }
        switch werkzeug {
        case .masslinie:
            if let start = ersterPunkt {
                let mass = aktuellesMass()
                let sig = GeometrieSignatur(p1: start, p2: np)
                let m = MassAnnotation(
                    p1: start, p2: np,
                    anzeige: mass,
                    quelle: (laser.letzterMesswertMM != nil && massText.trimmingCharacters(in: .whitespaces).isEmpty) ? .laser : .manuell,
                    farbe: farbwahl,
                    gemessenBei: mass.isEmpty ? nil : sig
                )
                d.annotationen.append(.mass(m)); ersterPunkt = nil
                massText = ""
            } else { ersterPunkt = np; return }
        case .notiz:
            d.annotationen.append(.notiz(NotizAnnotation(position: np, text: notizText.trimmingCharacters(in: .whitespaces))))
        case .symbol:
            d.annotationen.append(.symbol(SymbolAnnotation(
                position: np, typ: symbolwahl, farbe: farbwahl,
                beschriftung: symbolwahl == .gasanschluss ? "GAS" : "")))
        case .winkel:
            winkelPunkte.append(np)
            guard winkelPunkte.count == 3 else { return }
            let scheitel = winkelPunkte[1], a = winkelPunkte[0], b = winkelPunkte[2]
            let grad = winkelGrad(scheitel: scheitel, a: a, b: b, bild: CGSize(width: d.bildBreite, height: d.bildHoehe))
            d.annotationen.append(.winkel(WinkelAnnotation(scheitel: scheitel, schenkelA: a, schenkelB: b, gradzahl: grad)))
            winkelPunkte = []
        case .freihand:
            return
        }
        speichere(d)
    }

    /// Übernimmt die aktuelle Pencil-Zeichnung als neue `FreihandAnnotation`
    /// und leert die Live-Canvas — eigenständige Aktion (kein Tap-Ziel wie
    /// bei den anderen Werkzeugen, da PencilKit die Touch-Eingabe exklusiv
    /// bekommt).
    private func freihandUebernehmen(groesse: CGSize) {
        guard var d = dok, !freihandZeichnung.strokes.isEmpty, groesse.width > 0, groesse.height > 0 else { return }
        let bounds = freihandZeichnung.bounds
        let normRect = NormRect(bounds, in: groesse)
        let annotation = FreihandAnnotation(
            boundingBox: normRect,
            drawingData: freihandZeichnung.dataRepresentation(),
            farbe: farbwahl
        )
        d.annotationen.append(.freihand(annotation))
        freihandZeichnung = PKDrawing()
        speichere(d)
    }

    private func winkelGrad(scheitel: NormPunkt, a: NormPunkt, b: NormPunkt, bild: CGSize) -> Double {
        let w = Double(bild.width), h = Double(bild.height)
        let ang1 = atan2((a.y - scheitel.y) * h, (a.x - scheitel.x) * w)
        let ang2 = atan2((b.y - scheitel.y) * h, (b.x - scheitel.x) * w)
        var d = abs(ang1 - ang2) * 180 / .pi
        if d > 180 { d = 360 - d }
        return d
    }

    private func endpunktTreffer(_ np: NormPunkt, in d: Aufmass) -> EndpunktRef? {
        let schwelle = 0.045
        func dist(_ a: NormPunkt, _ b: NormPunkt) -> Double { hypot(a.x - b.x, a.y - b.y) }
        for annot in d.annotationen {
            if case .mass(let m) = annot {
                if dist(np, m.p1) < schwelle { return EndpunktRef(id: m.id, endpunkt: 0) }
                if dist(np, m.p2) < schwelle { return EndpunktRef(id: m.id, endpunkt: 1) }
            }
        }
        return nil
    }

    private func aktuellesMass() -> String {
        let t = massText.trimmingCharacters(in: .whitespaces)
        if !t.isEmpty { return t }
        if let mm = laser.letzterMesswertMM { return "\(mm) mm" }
        return ""
    }

    private func letzteZurueck() {
        if ersterPunkt != nil { ersterPunkt = nil; return }
        guard var d = dok, !d.annotationen.isEmpty else { return }
        d.annotationen.removeLast(); speichere(d)
    }

    private func editUebernehmen() {
        guard var d = dok else { return }
        let neu = editText.trimmingCharacters(in: .whitespaces)
        switch editZiel {
        case .mass(let id):
            if let i = d.annotationen.firstIndex(where: { $0.id == id }), case .mass(var m) = d.annotationen[i] {
                m.anzeige = neu
                m.gemessenBei = GeometrieSignatur(p1: m.p1, p2: m.p2)
                m.quelle = .manuell
                d.annotationen[i] = .mass(m)
            }
        case .notiz(let id):
            if let i = d.annotationen.firstIndex(where: { $0.id == id }), case .notiz(var n) = d.annotationen[i] {
                n.text = neu; d.annotationen[i] = .notiz(n)
            }
        case .symbol(let id):
            if let i = d.annotationen.firstIndex(where: { $0.id == id }), case .symbol(var s) = d.annotationen[i] {
                s.beschriftung = neu; d.annotationen[i] = .symbol(s)
            }
        case .winkel: break
        case .none: break
        }
        editZiel = nil; speichere(d)
    }

    private func editLoeschen() {
        guard var d = dok else { return }
        switch editZiel {
        case .mass(let id): d.annotationen.removeAll { $0.id == id }
        case .notiz(let id): d.annotationen.removeAll { $0.id == id }
        case .symbol(let id): d.annotationen.removeAll { $0.id == id }
        case .winkel(let id): d.annotationen.removeAll { $0.id == id }
        case .none: break
        }
        editZiel = nil; speichere(d)
    }

    private func speichere(_ d: Aufmass) {
        dok = d
        do { try aufmassStore.aktualisieren(d) } catch { infoText = Fehlertext.deutsch(error) }
    }

    private func eingepasst(_ bildGroesse: CGSize, in container: CGSize) -> CGSize {
        guard bildGroesse.width > 0, bildGroesse.height > 0 else { return container }
        let skala = min(container.width / bildGroesse.width, container.height / bildGroesse.height)
        return CGSize(width: bildGroesse.width * skala, height: bildGroesse.height * skala)
    }

    // MARK: Zuordnung (echte Projekt-Auswahl statt Freitext)

    private var zuordnungSheet: some View {
        NavigationStack {
            Form {
                Section("Raum") {
                    TextField("Raum, z. B. \"Küche EG\"", text: Binding(
                        get: { dok?.raumTitel ?? "" },
                        set: { neu in dok?.raumTitel = neu.isEmpty ? nil : neu }
                    ))
                }
                Section {
                    Button("Ohne Projekt") { zuordnen(nil) }
                        .foregroundStyle(MykColor.muted)
                    ForEach(projectStore.matching(projektSuche).sorted { $0.projectNumber > $1.projectNumber }.prefix(20)) { project in
                        Button { zuordnen(project) } label: {
                            HStack {
                                Text(project.title).foregroundStyle(MykColor.ink)
                                Spacer()
                                Text(project.projectNumber)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(MykColor.muted)
                                if dok?.projectNumber == project.projectNumber {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(MykColor.brand)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Projekt — nie geraten, immer bestätigt")
                }
            }
            .searchable(text: $projektSuche, prompt: "Projekt suchen")
            .navigationTitle("Zuordnung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { zeigeZuordnung = false }
                }
            }
        }
    }

    private func zuordnen(_ project: Project?) {
        guard var d = dok else { return }
        d.projectNumber = project?.projectNumber
        d.projectTitel = project?.title
        speichere(d)
    }

    // MARK: Export

    private func exportiere() {
        guard let d = dok, let bild = originalBild else { return }
        let annotiert = BemassungsRenderer.einbrennen(bild: bild, annotationen: d.annotationen)
        try? aufmassStore.setzeAnnotiert(d.id, bild: annotiert)
        if let jpg = annotiert.jpegData(compressionQuality: 0.9) {
            let u = FileManager.default.temporaryDirectory.appendingPathComponent("Aufmass-\(d.id.uuidString).jpg")
            try? jpg.write(to: u, options: .atomic); exportJPEG = u
        }
        exportPDF = try? AufmassPDFRenderer.rendere(aufmass: d, annotiertesBild: annotiert)
        exportJSON = try? aufmassStore.aufmassExportJSON(d.id)
        zeigeExport = true
    }

    private var exportSheet: some View {
        NavigationStack {
            List {
                Section {
                    if let u = exportPDF { ShareLink("PDF-Bericht teilen", item: u) }
                    if let u = exportJPEG { ShareLink("Foto (eingebrannt) teilen", item: u) }
                    if let u = exportJSON { ShareLink("Maß-Datei (JSON) teilen", item: u) }
                } footer: {
                    Text("PDF für den Alltag, JSON zum späteren Wieder-Einlesen.")
                }
            }
            .navigationTitle("Teilen / Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { zeigeExport = false } } }
        }
    }
}

// MARK: - Mini-Lupe

/// Feste, runde Lupe fürs präzise Setzen. 1:1 aus mykilOS iOS übernommen.
private struct LupeOverlay: View {
    let bild: UIImage
    let inhaltsGroesse: CGSize
    let punkt: CGPoint

    private let vergroesserung: CGFloat = 2.6
    private let durchmesser: CGFloat = 132

    var body: some View {
        let m = vergroesserung
        let skaliertB = inhaltsGroesse.width * m
        let skaliertH = inhaltsGroesse.height * m
        let dx = skaliertB / 2 - punkt.x * m
        let dy = skaliertH / 2 - punkt.y * m

        return ZStack {
            Image(uiImage: bild)
                .resizable()
                .frame(width: skaliertB, height: skaliertH)
                .offset(x: dx, y: dy)
            Rectangle().fill(.red).frame(width: durchmesser, height: 1)
            Rectangle().fill(.red).frame(width: 1, height: durchmesser)
            Circle().fill(.clear).frame(width: 7, height: 7).overlay(Circle().stroke(.red, lineWidth: 1.5))
        }
        .frame(width: durchmesser, height: durchmesser)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 3))
        .overlay(Circle().stroke(MykColor.ink.opacity(0.3), lineWidth: 1).padding(1.5))
        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
    }
}

#Preview {
    NavigationStack {
        FotoBemassungView(aufmassStore: AufmassStore(), projectStore: ProjectStore())
    }
}
