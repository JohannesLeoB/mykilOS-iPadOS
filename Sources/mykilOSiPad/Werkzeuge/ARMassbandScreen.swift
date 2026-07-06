import ARKit
import SwiftUI

/// Allgemeines AR-Maßband — zwei Punkte antippen, Distanz sehen.
/// **Nicht live testbar vom Simulator** — ARKit-Genauigkeit/Ebenen-Erkennung
/// hängt stark vom Gerät und der Umgebung ab, das bleibt ein Beta-Check.
struct ARMassbandScreen: View {
    @State private var messer = ARMassbandMesser()

    var body: some View {
        Group {
            if ARWorldTrackingConfiguration.isSupported {
                ZStack(alignment: .bottom) {
                    ARMassbandBridge(messer: messer)
                        .ignoresSafeArea()

                    VStack(spacing: 10) {
                        hinweisKarte
                    }
                    .padding(16)
                }
            } else {
                ContentUnavailableView(
                    "AR nicht unterstützt",
                    systemImage: "arkit",
                    description: Text("Keine AR-Weltverfolgung möglich.")
                )
            }
        }
        .navigationTitle("AR-Maßband")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var hinweisKarte: some View {
        VStack(spacing: 8) {
            if let abstandText = messer.abstandText {
                Label(abstandText, systemImage: "ruler.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(MykColor.brand)
                Button("Neu messen") { messer.zuruecksetzen() }
                    .buttonStyle(.borderedProminent)
                    .tint(MykColor.brand)
            } else if messer.ersterPunkt != nil {
                Text("Jetzt zweiten Punkt antippen.")
                    .font(.subheadline.weight(.semibold))
            } else {
                Text("Ersten Punkt antippen, um zu messen.")
                    .font(.subheadline.weight(.semibold))
            }
            Text("Grobe AR-Schätzung, kein Laser — gegenprüfen.")
                .font(.caption2)
                .foregroundStyle(MykColor.muted)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        ARMassbandScreen()
    }
}
