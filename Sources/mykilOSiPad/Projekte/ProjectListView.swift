import SwiftUI

/// Die Projektliste — ersetzt die bisherigen freien Textfelder in Aufmaß/
/// RoomPlan/Grundriss als echte Zuordnungsquelle. 1:1 nach dem Muster aus
/// mykilOS iOS (`ProjectRow`/`GlanceCockpitView`), ohne die dortige
/// Geofencing-/Standort-Merken-Funktion (auf dem iPad, das seltener am
/// Körper getragen wird, niedrigere Priorität — kann später ergänzt werden).
struct ProjectListView: View {
    let stores: AppStores

    @State private var suche = ""

    private var projekte: [Project] {
        stores.projectStore.matching(suche).sorted { $0.projectNumber > $1.projectNumber }
    }

    var body: some View {
        List {
            if let error = stores.projectStore.loadError {
                Text(error).foregroundStyle(MykColor.crit)
            }
            ForEach(projekte) { project in
                NavigationLink {
                    ProjectDetailView(project: project, stores: stores)
                } label: {
                    HStack(spacing: 11) {
                        Circle()
                            .fill(project.kind == "studioInternal" ? MykColor.plum : MykColor.ocker)
                            .frame(width: 9, height: 9)
                        Text(project.title)
                            .font(.system(.callout, design: .default).weight(.semibold))
                            .foregroundStyle(MykColor.ink)
                        Spacer()
                        Text(project.projectNumber)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(MykColor.muted)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .searchable(text: $suche, prompt: "Projekt suchen")
        .navigationTitle("Projekte")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProjectListView(stores: AppStores())
    }
}
