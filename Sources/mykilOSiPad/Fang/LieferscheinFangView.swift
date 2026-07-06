import SwiftUI

/// Einstieg fürs Lieferschein-Fangen: Kamera öffnen → Foto → OCR-Bestätigung
/// → Wareneingangs-Log. Eigener schlanker Launcher (die iOS-Vorlage startet
/// das aus der Fang-Karte; auf dem iPad hängt es hier im Werkzeugkasten, bis
/// die Fang-Karte den Kamera-Fang selbst anbietet).
struct LieferscheinFangView: View {
    let store: ProjectStore
    let wareneingangStore: WareneingangsLogStore

    @State private var zeigeKamera = false
    @State private var erfasstesBild: FangBild?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "shippingbox")
                .font(.system(size: 44))
                .foregroundStyle(MykColor.muted)
            Text("Paketlabel abfotografieren — Tracking-Nummer und Absender werden on-device erkannt (Vorschlag, kein Fakt).")
                .font(.subheadline)
                .foregroundStyle(MykColor.muted)
                .multilineTextAlignment(.center)
            Button("Lieferschein fotografieren") { zeigeKamera = true }
                .buttonStyle(.borderedProminent)
                .tint(MykColor.brand)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MykColor.paper)
        .navigationTitle("Lieferschein-Fang")
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
            LieferscheinBestaetigungView(
                bild: fang.bild,
                store: store,
                wareneingangStore: wareneingangStore,
                onFertig: { erfasstesBild = nil }
            )
        }
    }
}

/// Kleiner Identifiable-Wrapper, damit ein frisch geknipstes Bild per
/// `sheet(item:)` präsentiert werden kann.
struct FangBild: Identifiable {
    let id = UUID()
    let bild: UIImage
}

#Preview {
    NavigationStack {
        LieferscheinFangView(store: ProjectStore(), wareneingangStore: WareneingangsLogStore())
    }
}
