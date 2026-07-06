import SwiftUI

/// Host-Screen für den Grundriss-Editor: Werkzeugleiste (Neu/Raster/
/// Rückgängig/Messen/Wände/Bauelement/Formen/Text — Layout-Idee aus den
/// Referenz-Apps, siehe `docs/AUFMASS_APP_MARKTVERGLEICH.md`), darunter die
/// Zeichenfläche. Strikt mykilOS-CI: schwarze Werkzeugleiste, Großbuchstaben-
/// Mono-Buttons, quadratische Ecken, keine Wettbewerber-Farben.
struct GrundrissEditorScreen: View {
    let store: GrundrissEditorStore
    @State var dokument: GrundrissDokument

    @State private var modus: GrundrissEditorModus = .waende
    @State private var rasterAn = true
    @State private var rueckgaengigAnfrage = false
    @State private var exportDatei: ExportDatei?
    @State private var fehler: String?

    init(store: GrundrissEditorStore, dokument: GrundrissDokument) {
        self.store = store
        self._dokument = State(initialValue: dokument)
    }

    var body: some View {
        VStack(spacing: 0) {
            werkzeugleiste
            Divider().overlay(MykColor.line)
            modusleiste
            Divider().overlay(MykColor.line)
            GrundrissCanvasView(
                dokument: $dokument,
                modus: $modus,
                rasterAn: $rasterAn,
                rueckgaengigAnfrage: $rueckgaengigAnfrage
            ) { neu in
                try? store.aktualisieren(neu)
            }
        }
        .background(MykColor.paper)
        .navigationTitle(dokument.titel)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $exportDatei) { wrapper in
            TeilenAnsicht(activityItems: [wrapper.url])
        }
        .alert("Fehler", isPresented: Binding(get: { fehler != nil }, set: { if !$0 { fehler = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(fehler ?? "")
        }
    }

    private var werkzeugleiste: some View {
        HStack(spacing: 0) {
            werkzeugButton("NEU", sfName: "doc.badge.plus") {
                dokument = GrundrissDokument(titel: "Neuer Grundriss")
            }
            werkzeugButton("RASTER", sfName: "grid", aktiv: rasterAn) {
                rasterAn.toggle()
            }
            werkzeugButton("RÜCKGÄNGIG", sfName: "arrow.uturn.backward") {
                rueckgaengigAnfrage = true
            }
            werkzeugButton("PDF", sfName: "doc.richtext") {
                pdfExportieren()
            }
            werkzeugButton("DXF", sfName: "square.and.arrow.up.on.square") {
                dxfExportieren()
            }
        }
        .padding(.vertical, 10)
        .background(Color.black)
    }

    private var modusleiste: some View {
        HStack(spacing: 0) {
            ForEach(GrundrissEditorModus.allCases) { m in
                Button {
                    modus = m
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: m.sfName)
                        Text(m.titel.uppercased())
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .foregroundStyle(modus == m ? MykColor.brand : MykColor.muted)
            }
        }
        .background(MykColor.card)
    }

    private func werkzeugButton(_ titel: String, sfName: String, aktiv: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: sfName)
                Text(titel).font(.system(size: 9, weight: .medium, design: .monospaced))
            }
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(aktiv ? MykColor.brand : .white)
    }

    private func pdfExportieren() {
        do {
            let url = try GrundrissPDFRenderer.erstellePDF(geometrie: dokument.raumGeometrie(), titel: dokument.titel)
            exportDatei = ExportDatei(url: url)
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }

    private func dxfExportieren() {
        do {
            let url = try GrundrissDXFExporter.erstelleDXF(geometrie: dokument.raumGeometrie())
            exportDatei = ExportDatei(url: url)
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }
}

#Preview {
    NavigationStack {
        GrundrissEditorScreen(store: GrundrissEditorStore(), dokument: GrundrissDokument())
    }
}
