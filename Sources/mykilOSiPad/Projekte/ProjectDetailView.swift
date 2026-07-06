import SwiftUI

/// Dedizierte Einzel-Projekt-Ansicht — angelehnt an mykilOS iOS
/// `ProjectDetailView`, hier um die Aufmaß-Werkzeuge erweitert: von hier aus
/// direkt ein Aufmaß/Grundriss/RoomPlan-Scan FÜR DIESES PROJEKT anlegen,
/// statt Aufmaß-Werkzeuge lose zu öffnen und Projekt/Raum als Freitext
/// einzutippen.
struct ProjectDetailView: View {
    let project: Project
    let stores: AppStores

    private var kindLabel: String { project.kind == "studioInternal" ? "Studio-intern" : "Küche" }
    private var kindColor: Color { project.kind == "studioInternal" ? MykColor.plum : MykColor.ocker }

    private var eigeneAufmasse: [Aufmass] {
        stores.aufmassStore.aufmasse
            .filter { $0.projectNumber == project.projectNumber }
            .sorted { $0.geaendertAm > $1.geaendertAm }
    }

    private var eigeneGrundrisse: [GrundrissDokument] {
        stores.grundrissStore.dokumente
            .filter { $0.projectNumber == project.projectNumber }
            .sorted { $0.geaendertAm > $1.geaendertAm }
    }

    private var eigeneRoomPlanScans: [RoomPlanAufnahme] {
        stores.roomPlanStore.aufnahmen
            .filter { $0.projectNumber == project.projectNumber }
            .sorted { $0.aufgenommenAm > $1.aufgenommenAm }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                kopf
                metadaten
                aufmassWerkzeuge
                if !eigeneAufmasse.isEmpty { aufmassListe }
                if !eigeneGrundrisse.isEmpty { grundrissListe }
                if !eigeneRoomPlanScans.isEmpty { roomPlanListe }
            }
            .padding(20)
        }
        .background(MykColor.paper)
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var kopf: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle().fill(kindColor).frame(width: 10, height: 10)
                Text(kindLabel.uppercased())
                    .font(.mykMono(11)).tracking(1.2).foregroundStyle(MykColor.muted)
            }
            Text(project.title).font(.mykGrotesk(30)).foregroundStyle(MykColor.ink)
            Text(project.projectNumber).font(.system(.footnote, design: .monospaced)).foregroundStyle(MykColor.muted)
        }
    }

    private var metadaten: some View {
        VStack(alignment: .leading, spacing: 10) {
            metaZeile(label: "Kundennummer", wert: project.customerNumber)
            metaZeile(label: "Aufmaße", wert: "\(eigeneAufmasse.count)")
            metaZeile(label: "Grundrisse", wert: "\(eigeneGrundrisse.count)")
            metaZeile(label: "RoomPlan-Scans", wert: "\(eigeneRoomPlanScans.count)")
            if let url = project.driveURL {
                Link(destination: url) {
                    Label("Drive-Ordner öffnen", systemImage: "folder.fill")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(MykColor.drive)
                .padding(.top, 4)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MykColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func metaZeile(label: String, wert: String) -> some View {
        HStack {
            Text(label.uppercased()).font(.mykMono(11)).tracking(0.6).foregroundStyle(MykColor.muted)
            Spacer()
            Text(wert).font(.system(.footnote, design: .monospaced).weight(.semibold)).foregroundStyle(MykColor.ink)
        }
    }

    private var aufmassWerkzeuge: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AUFMASS FÜR DIESES PROJEKT").font(.mykMono(11)).tracking(1.5).foregroundStyle(MykColor.brand)
            HStack(spacing: 10) {
                NavigationLink {
                    GrundrissEditorScreen(store: stores.grundrissStore, dokument: neuerGrundriss())
                } label: {
                    Label("Grundriss", systemImage: "square.on.square.dashed")
                }
                .buttonStyle(.bordered)
                NavigationLink {
                    FotoBemassungView(aufmassStore: stores.aufmassStore, projectStore: stores.projectStore)
                } label: {
                    Label("Foto-Bemaßung", systemImage: "camera.viewfinder")
                }
                .buttonStyle(.bordered)
                NavigationLink {
                    RoomPlanCaptureScreen(roomPlanStore: stores.roomPlanStore, projectStore: stores.projectStore)
                } label: {
                    Label("RoomPlan", systemImage: "cube.transparent")
                }
                .buttonStyle(.bordered)
            }
            .tint(MykColor.ink)
        }
    }

    private func neuerGrundriss() -> GrundrissDokument {
        GrundrissDokument(titel: project.title, projectNumber: project.projectNumber, projectTitel: project.title)
    }

    private var aufmassListe: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AUFMASSE").font(.mykMono(11)).tracking(1.5).foregroundStyle(MykColor.muted)
            ForEach(eigeneAufmasse) { aufmass in
                HStack {
                    Text(aufmass.raumTitel ?? "Ohne Raumtitel").foregroundStyle(MykColor.ink)
                    Spacer()
                    Text(aufmass.geaendertAm, style: .relative).font(.caption).foregroundStyle(MykColor.muted)
                }
                .padding(10)
                .background(MykColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var grundrissListe: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GRUNDRISSE").font(.mykMono(11)).tracking(1.5).foregroundStyle(MykColor.muted)
            ForEach(eigeneGrundrisse) { dokument in
                NavigationLink {
                    GrundrissEditorScreen(store: stores.grundrissStore, dokument: dokument)
                } label: {
                    HStack {
                        Text(dokument.titel).foregroundStyle(MykColor.ink)
                        Spacer()
                        Text("\(dokument.waende.count) Wände").font(.caption).foregroundStyle(MykColor.muted)
                    }
                    .padding(10)
                    .background(MykColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var roomPlanListe: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ROOMPLAN-SCANS").font(.mykMono(11)).tracking(1.5).foregroundStyle(MykColor.muted)
            ForEach(eigeneRoomPlanScans) { aufnahme in
                HStack {
                    Text(aufnahme.raumTitel ?? "Ohne Raumtitel").foregroundStyle(MykColor.ink)
                    Spacer()
                    Text(aufnahme.aufgenommenAm, style: .relative).font(.caption).foregroundStyle(MykColor.muted)
                }
                .padding(10)
                .background(MykColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(
            project: Project(projectNumber: "2026-038", title: "Beispiel", kind: "kitchen", customerNumber: "K-0001", driveFolderID: ""),
            stores: AppStores()
        )
    }
}
