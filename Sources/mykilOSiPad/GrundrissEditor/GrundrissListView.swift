import SwiftUI

/// Übersicht gespeicherter Grundrisse — bisher fehlte diese Liste, obwohl
/// `GrundrissEditorStore` schon mehrere Dokumente verwalten kann;
/// `ContentView` legte bisher bei jedem Aufruf ein neues, ungespeichertes
/// Dokument an. Gleiches Muster wie `RoomPlanListView`/die Aufmaß-Startseite.
struct GrundrissListView: View {
    let store: GrundrissEditorStore

    @State private var neuesDokument: GrundrissDokument?

    var body: some View {
        List {
            Section {
                Button {
                    neuesDokument = (try? store.anlegen()) ?? GrundrissDokument()
                } label: {
                    Label("Neuer Grundriss", systemImage: "plus.square.dashed")
                }
            }
            if !store.dokumente.isEmpty {
                Section("Gespeicherte Grundrisse") {
                    ForEach(store.dokumente.sorted { $0.geaendertAm > $1.geaendertAm }) { dokument in
                        NavigationLink {
                            GrundrissEditorScreen(store: store, dokument: dokument)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dokument.titel).foregroundStyle(MykColor.ink)
                                Text("\(dokument.waende.count) Wände · \(dokument.geaendertAm.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption).foregroundStyle(MykColor.muted)
                            }
                        }
                    }
                    .onDelete { idx in
                        let sortiert = store.dokumente.sorted { $0.geaendertAm > $1.geaendertAm }
                        for i in idx { try? store.remove(sortiert[i].id) }
                    }
                }
            }
            if let error = store.loadError {
                Text(error).font(.footnote).foregroundStyle(MykColor.crit)
            }
        }
        .navigationTitle("Grundrisse")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $neuesDokument) { dokument in
            GrundrissEditorScreen(store: store, dokument: dokument)
        }
    }
}

#Preview {
    NavigationStack {
        GrundrissListView(store: GrundrissEditorStore())
    }
}
