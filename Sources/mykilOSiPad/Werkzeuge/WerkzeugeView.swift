import SwiftUI

/// Sammelstelle für eigenständige Vor-Ort-Werkzeuge, die keine Postbox,
/// keinen Sync und kein Projekt brauchen — nur Kamera/Sensor + sofortige
/// Antwort. Portiert aus mykilOS iOS (`WerkzeugeView`) und wächst hier
/// Baustein für Baustein mit; gelistet wird nur, was schon portiert ist.
struct WerkzeugeView: View {
    let store: ProjectStore
    let feldFotoStore: FeldFotoStore

    @State private var barcodeLog = BarcodeLogStore()
    @State private var wareneingangLog = WareneingangsLogStore()

    var body: some View {
        List {
            werkzeug(
                ziel: { WasserwaageView() },
                titel: "Wasserwaage",
                unter: "Gyroskop-Neigungsmesser",
                symbol: "level"
            )
            werkzeug(
                ziel: { BarcodeLogListView(logStore: barcodeLog) },
                titel: "Barcode/QR-Scanner",
                unter: "Rohdaten-Log, kein WorkBasket-Abgleich",
                symbol: "barcode.viewfinder"
            )
            werkzeug(
                ziel: { BeleuchtungsCheckView() },
                titel: "Beleuchtungs-Check",
                unter: "Foto → Helligkeit einschätzen",
                symbol: "sun.max.fill"
            )
            werkzeug(
                ziel: { FarbtemperaturCheckView() },
                titel: "Farbtemperatur-Check",
                unter: "Warm/Neutral/Kühl — grobe Schätzung, kein Kelvin",
                symbol: "paintpalette.fill"
            )
            werkzeug(
                ziel: { RaumakustikCheckView() },
                titel: "Raumakustik-Check",
                unter: "Grobe Lautstärke, keine Nachhallzeit",
                symbol: "waveform"
            )
            werkzeug(
                ziel: { ARMassbandScreen() },
                titel: "AR-Maßband",
                unter: "Zwei Punkte antippen, Distanz sehen",
                symbol: "arkit"
            )
            werkzeug(
                ziel: { WareneingangsLogListView(wareneingangStore: wareneingangLog) },
                titel: "Wareneingang",
                unter: "Rohdaten-Log, kein Bestell-Abgleich",
                symbol: "shippingbox"
            )
            werkzeug(
                ziel: { AbnahmeprotokollView(store: store) },
                titel: "Abnahmeprotokoll",
                unter: "Diktat + Foto, nummeriert je Projekt",
                symbol: "list.number"
            )
            werkzeug(
                ziel: { VertragSignierenView(store: store) },
                titel: "Vertrag signieren",
                unter: "Geführt: PDF + Unterschrift + SHA-256-Siegel",
                symbol: "signature"
            )
            werkzeug(
                ziel: { ServiceAnfrageView(store: store, feldFotoStore: feldFotoStore) },
                titel: "Service-Anfrage",
                unter: "Vorbefüllte Mail an den Servicepartner",
                symbol: "wrench.adjustable.fill"
            )
            werkzeug(
                ziel: { KontakteVerzeichnisView() },
                titel: "Kontakte",
                unter: "Kunden-Verzeichnis (Airtable-Sync folgt)",
                symbol: "person.crop.circle"
            )
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(MykColor.paper)
        .navigationTitle("Werkzeuge")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Einheitliche Werkzeug-Zeile: Icon in Markenfarbe, Titel + kurze
    /// Erklärzeile in Grau. Hält die Liste konsistent, wenn sie wächst.
    @ViewBuilder
    private func werkzeug<Ziel: View>(
        @ViewBuilder ziel: @escaping () -> Ziel,
        titel: String,
        unter: String,
        symbol: String
    ) -> some View {
        NavigationLink {
            ziel()
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(titel)
                    Text(unter)
                        .font(.caption)
                        .foregroundStyle(MykColor.muted)
                }
            } icon: {
                Image(systemName: symbol).foregroundStyle(MykColor.brand)
            }
        }
    }
}

#Preview {
    NavigationStack {
        WerkzeugeView(store: ProjectStore(), feldFotoStore: FeldFotoStore())
    }
}
