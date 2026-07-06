import SwiftUI

/// Die sichtbare Postbox. Gegenüber mykilOS iOS ohne Airtable-Sync-Anbindung
/// (noch nicht portiert) — Einträge bleiben lokal, "idee"-Einträge lassen
/// sich per System-Share-Sheet weitergeben.
struct PostboxView: View {
    let postbox: PostboxStore

    var body: some View {
        List {
            if postbox.items.isEmpty {
                ContentUnavailableView(
                    "Postbox leer",
                    systemImage: "tray",
                    description: Text("Noch nichts gefangen.")
                )
            } else {
                ForEach(postbox.items.reversed()) { item in
                    row(for: item)
                        .swipeActions(edge: .trailing) {
                            Button("Löschen", role: .destructive) {
                                try? postbox.remove(item.id)
                            }
                        }
                }
            }
        }
        .navigationTitle("Postbox")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func row(for item: PostboxItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Image(systemName: item.kind == "zeit" ? "clock" : "lightbulb")
                    .foregroundStyle(item.kind == "zeit" ? MykColor.brand : MykColor.plum)
                Text(item.text).font(.subheadline.weight(.semibold))
                Spacer()
                ShareLink(item: item.text) {
                    Image(systemName: "square.and.arrow.up").font(.caption)
                }
                .accessibilityLabel("Eintrag teilen")
            }
            if !item.kontext.isEmpty {
                Text(item.kontext).font(.caption).foregroundStyle(MykColor.muted)
            }
            Text(item.capturedAt, style: .relative)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(MykColor.muted)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        PostboxView(postbox: PostboxStore())
    }
}
