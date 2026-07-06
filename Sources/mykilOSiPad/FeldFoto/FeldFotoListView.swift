import SwiftUI
import UIKit

/// Die sichtbare Feld-Foto-Liste. Gegenüber mykilOS iOS ohne Google-Drive-
/// Sync-Anbindung (noch nicht portiert, siehe `WORK_STATUS.md`) — Fotos
/// bleiben lokal, Förderrelevanz-Markierung funktioniert bereits.
struct FeldFotoListView: View {
    let feldFotoStore: FeldFotoStore

    var body: some View {
        List {
            if feldFotoStore.fotos.isEmpty {
                ContentUnavailableView(
                    "Noch keine Feld-Fotos",
                    systemImage: "camera",
                    description: Text("Kamera-Knopf in der Fang-Karte antippen.")
                )
            } else {
                ForEach(feldFotoStore.fotos.reversed()) { foto in
                    row(for: foto)
                        .swipeActions(edge: .trailing) {
                            Button("Löschen", role: .destructive) {
                                try? feldFotoStore.remove(foto.id)
                            }
                        }
                        .contextMenu {
                            Button {
                                try? feldFotoStore.setzeFoerderrelevant(foto.id, foerderrelevant: !foto.foerderrelevant)
                            } label: {
                                Label(
                                    foto.foerderrelevant ? "Förderrelevant entfernen" : "Förderrelevant markieren",
                                    systemImage: foto.foerderrelevant ? "checkmark.seal.fill" : "checkmark.seal"
                                )
                            }
                        }
                }
            }
        }
        .navigationTitle("Feld-Fotos")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func row(for foto: FeldFoto) -> some View {
        HStack(alignment: .top, spacing: 11) {
            if let bild = UIImage(contentsOfFile: feldFotoStore.bildURL(fuer: foto).path) {
                Image(uiImage: bild)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(foto.projectTitel).font(.subheadline.weight(.semibold))
                    if foto.foerderrelevant {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(MykColor.sage)
                            .accessibilityLabel("Förderrelevant")
                    }
                }
                Text("\(foto.kanonZiel.titel) · \(foto.kanonZiel.ordner)")
                    .font(.caption)
                    .foregroundStyle(MykColor.muted)
                Text(foto.aufgenommenAm, style: .relative)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(MykColor.muted)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        FeldFotoListView(feldFotoStore: FeldFotoStore())
    }
}
