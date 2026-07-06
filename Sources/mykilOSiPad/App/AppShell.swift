import SwiftUI

/// Echte mykilOS-IA statt Platzhalter-Liste: schwarze Sidebar mit
/// nummerierten Sektionen, Breadcrumb-Topbar "MYKILOS / MODUL" — nach
/// mykilOS-CI (siehe `mykilos-core`-Skill: schwarze Sidebar, aktiv = 3px
/// weißer Balken links, helle Inhaltsfläche, Großbuchstaben-Mono-Labels).
enum AppModul: String, CaseIterable, Identifiable {
    case heute, fang, feldFotos, projekte, grundriss, fotoBemassung, roomPlan, raumscans, verbindungen

    var id: String { rawValue }

    var sektion: String {
        switch self {
        case .heute: return "01"
        case .fang, .feldFotos: return "02"
        case .projekte: return "03"
        case .grundriss, .fotoBemassung, .roomPlan, .raumscans: return "04"
        case .verbindungen: return "05"
        }
    }

    var sektionsTitel: String {
        switch self {
        case .heute: return "HEUTE"
        case .fang, .feldFotos: return "FANG"
        case .projekte: return "PROJEKTE"
        case .grundriss, .fotoBemassung, .roomPlan, .raumscans: return "AUFMASS"
        case .verbindungen: return "VERBINDUNGEN"
        }
    }

    var titel: String {
        switch self {
        case .heute: return "Heute"
        case .fang: return "Fang"
        case .feldFotos: return "Feld-Fotos"
        case .projekte: return "Projekte"
        case .grundriss: return "Grundriss-Editor"
        case .fotoBemassung: return "Foto-Bemaßung"
        case .roomPlan: return "RoomPlan-Scan"
        case .raumscans: return "Raumscan-Archiv"
        case .verbindungen: return "Verbindungen"
        }
    }

    var sfName: String {
        switch self {
        case .heute: return "sun.max"
        case .fang: return "waveform"
        case .feldFotos: return "photo.stack"
        case .projekte: return "folder"
        case .grundriss: return "square.on.square.dashed"
        case .fotoBemassung: return "camera.viewfinder"
        case .roomPlan: return "cube.transparent"
        case .raumscans: return "archivebox"
        case .verbindungen: return "hand.raised"
        }
    }
}

/// Die vier fest umrissenen Module ohne feste Aufmaß-Zuordnung stehen
/// direkt in der Sidebar; Aufmaß-Werkzeuge werden im Kontext eines Projekts
/// aufgerufen (siehe `ProjectDetailView`) — deshalb erscheinen sie hier nur
/// als eigenständiger Direktzugriff für "ohne Projekt" ODER als über die
/// Sidebar globale Kurzwahl.
struct AppShell: View {
    let stores: AppStores

    @State private var auswahl: AppModul? = .heute
    @State private var spalteSichtbarkeit: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $spalteSichtbarkeit) {
            sidebar
        } detail: {
            NavigationStack {
                inhalt(fuer: auswahl ?? .heute)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            breadcrumb
                        }
                    }
            }
            .tint(MykColor.brand)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $auswahl) {
            ForEach(gruppierteSektionen, id: \.sektion) { gruppe in
                Section {
                    ForEach(gruppe.module) { modul in
                        Label {
                            Text(modul.titel)
                                .font(.mykGrotesk(15))
                        } icon: {
                            Image(systemName: modul.sfName)
                        }
                        .tag(modul)
                        .listRowBackground(sidebarZeilenHintergrund(aktiv: auswahl == modul))
                    }
                } header: {
                    Text("\(gruppe.sektion) · \(gruppe.titel)")
                        .font(.mykMono(11))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("MYKILOS")
                    .font(.mykGrotesk(17))
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    @ViewBuilder
    private func sidebarZeilenHintergrund(aktiv: Bool) -> some View {
        if aktiv {
            HStack(spacing: 0) {
                Rectangle().fill(Color.white).frame(width: 3)
                Color.white.opacity(0.08)
            }
        } else {
            Color.clear
        }
    }

    private struct ModulGruppe { let sektion: String; let titel: String; var module: [AppModul] }

    private var gruppierteSektionen: [ModulGruppe] {
        let reihenfolge: [AppModul] = [.heute, .fang, .feldFotos, .projekte, .grundriss, .fotoBemassung, .roomPlan, .raumscans, .verbindungen]
        var ergebnis: [ModulGruppe] = []
        for modul in reihenfolge {
            if let letzte = ergebnis.last, letzte.sektion == modul.sektion {
                ergebnis[ergebnis.count - 1].module.append(modul)
            } else {
                ergebnis.append(ModulGruppe(sektion: modul.sektion, titel: modul.sektionsTitel, module: [modul]))
            }
        }
        return ergebnis
    }

    // MARK: - Breadcrumb

    private var breadcrumb: some View {
        HStack(spacing: 6) {
            Text("MYKILOS").font(.mykMono(12)).foregroundStyle(MykColor.muted)
            Text("/").font(.mykMono(12)).foregroundStyle(MykColor.muted)
            Text((auswahl ?? .heute).titel.uppercased()).font(.mykMono(12)).foregroundStyle(MykColor.ink)
        }
    }

    // MARK: - Inhalt

    @ViewBuilder
    private func inhalt(fuer modul: AppModul) -> some View {
        switch modul {
        case .heute:
            HeuteView(stores: stores)
        case .fang:
            ScrollView {
                FangCard(postbox: stores.postboxStore, store: stores.projectStore, feldFotoStore: stores.feldFotoStore)
                    .padding(20)
            }
            .background(MykColor.paper)
            .navigationTitle("Fang")
            .navigationBarTitleDisplayMode(.inline)
        case .feldFotos:
            FeldFotoListView(feldFotoStore: stores.feldFotoStore)
        case .projekte:
            ProjectListView(stores: stores)
        case .grundriss:
            GrundrissListView(store: stores.grundrissStore)
        case .fotoBemassung:
            FotoBemassungView(aufmassStore: stores.aufmassStore, projectStore: stores.projectStore)
        case .roomPlan:
            RoomPlanCaptureScreen(roomPlanStore: stores.roomPlanStore, projectStore: stores.projectStore)
        case .raumscans:
            RoomPlanListView(roomPlanStore: stores.roomPlanStore)
        case .verbindungen:
            VerbindungenView()
        }
    }
}
