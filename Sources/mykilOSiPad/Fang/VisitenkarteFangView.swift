import SwiftUI

/// Einstieg fürs Visitenkarten-Fangen: Kamera öffnen → Foto → OCR-Bestätigung
/// → Kontakt anlegen. Eigener schlanker Launcher, gleicher Aufbau wie
/// `LieferscheinFangView`.
struct VisitenkarteFangView: View {
    @State private var zeigeKamera = false
    @State private var erfasstesBild: FangBild?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.crop.rectangle")
                .font(.system(size: 44))
                .foregroundStyle(MykColor.muted)
            Text("Visitenkarte abfotografieren — Name, Firma, Telefon und E-Mail werden on-device erkannt. Kontakt wird erst auf deinen Tipp angelegt.")
                .font(.subheadline)
                .foregroundStyle(MykColor.muted)
                .multilineTextAlignment(.center)
            Button("Visitenkarte fotografieren") { zeigeKamera = true }
                .buttonStyle(.borderedProminent)
                .tint(MykColor.brand)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MykColor.paper)
        .navigationTitle("Visitenkarten-Fang")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $zeigeKamera) {
            KameraAufnahmeView(
                onAufnahme: { foto, _ in
                    erfasstesBild = FangBild(bild: foto)
                    zeigeKamera = false
                },
                onAbbruch: { zeigeKamera = false }
            )
            .ignoresSafeArea()
        }
        .sheet(item: $erfasstesBild) { fang in
            VisitenkarteBestaetigungView(
                bild: fang.bild,
                onFertig: { erfasstesBild = nil }
            )
        }
    }
}

#Preview {
    NavigationStack {
        VisitenkarteFangView()
    }
}
