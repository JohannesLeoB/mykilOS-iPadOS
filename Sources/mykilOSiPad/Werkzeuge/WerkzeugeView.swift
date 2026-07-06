import SwiftUI

/// Sammelstelle für eigenständige Vor-Ort-Werkzeuge, die keine Postbox,
/// keinen Sync und kein Projekt brauchen — nur Kamera/Sensor + sofortige
/// Antwort. Portiert aus mykilOS iOS (`WerkzeugeView`) und wächst hier
/// Baustein für Baustein mit; gelistet wird nur, was schon portiert ist.
struct WerkzeugeView: View {
    var body: some View {
        List {
            werkzeug(
                ziel: { WasserwaageView() },
                titel: "Wasserwaage",
                unter: "Gyroskop-Neigungsmesser",
                symbol: "level"
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
        WerkzeugeView()
    }
}
