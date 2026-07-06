import RoomPlan
import SwiftUI
import UIKit

/// RoomPlan-Aufmaß: echte Projektwahl (wie im Original `RoomPlanCaptureScreen`
/// aus mykilOS iOS), Raum scannen (Apples eigene Scan-UI), Ergebnis als USDZ
/// sichern. Braucht ein LiDAR-Gerät — auf anderen Geräten ehrlicher
/// Fallback-Zustand statt Absturz.
struct RoomPlanCaptureScreen: View {
    let roomPlanStore: RoomPlanStore
    let projectStore: ProjectStore

    @State private var projektSuche = ""
    @State private var gewaehltesProjekt: Project?
    @State private var raumTitel = ""
    @State private var zeigeScan = false
    @State private var stoppAnfrage = false
    @State private var fertigesErgebnis: RoomPlanErgebnis?
    @State private var fehler: String?
    @State private var gespeichert = false
    @State private var exportDatei: ExportDatei?

    private var projekte: [Project] {
        projectStore.matching(projektSuche).sorted { $0.projectNumber > $1.projectNumber }
    }

    var body: some View {
        Group {
            if RoomCaptureSession.isSupported {
                Form {
                    Section("Projekt — nie geraten, immer bestätigt") {
                        TextField("Projekt suchen…", text: $projektSuche)
                        ForEach(projekte.prefix(5)) { project in
                            Button {
                                gewaehltesProjekt = project
                            } label: {
                                HStack {
                                    Text(project.title)
                                    Spacer()
                                    Text(project.projectNumber)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(MykColor.muted)
                                    if gewaehltesProjekt?.id == project.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(MykColor.brand)
                                    }
                                }
                            }
                            .foregroundStyle(MykColor.ink)
                        }
                        TextField("Raum, z. B. \"Küche EG\"", text: $raumTitel)
                    }

                    Section {
                        Button("Raum scannen") { zeigeScan = true }
                            .buttonStyle(.borderedProminent)
                            .tint(MykColor.brand)
                    } footer: {
                        Text("Apples geführte Scan-Ansicht öffnet sich. Braucht ein LiDAR-Gerät (iPad Pro).")
                    }

                    if let fertigesErgebnis {
                        Section("Scan fertig — 3D") {
                            if gespeichert {
                                Label("Gespeichert", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(MykColor.ok)
                            } else {
                                Button("Speichern") {
                                    speichern(fertigesErgebnis.usdzURL)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(MykColor.brand)
                            }
                        }

                        Section {
                            Button("Als PDF-Grundriss teilen") { pdfExportieren(fertigesErgebnis.geometrie) }
                            Button("Als DXF exportieren (CAD-Unterlage)") { dxfExportieren(fertigesErgebnis.geometrie) }
                        } header: {
                            Text("2D-Zeichnung")
                        } footer: {
                            Text("Referenz-Grundriss aus dem Scan (~cm), kein Ersatz fürs Laser-Aufmaß.")
                        }
                    }

                    if let fehler {
                        Text(fehler).foregroundStyle(MykColor.crit)
                    }
                }
            } else {
                ContentUnavailableView(
                    "RoomPlan nicht unterstützt",
                    systemImage: "arkit",
                    description: Text("Braucht ein Gerät mit LiDAR-Scanner (iPad Pro 2020 oder neuer).")
                )
            }
        }
        .navigationTitle("RoomPlan-Aufmaß")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $zeigeScan) {
            ZStack(alignment: .bottom) {
                RoomPlanCaptureBridge(stoppAnfrage: $stoppAnfrage) { ergebnis in
                    fertigesErgebnis = ergebnis
                    gespeichert = false
                    if ergebnis == nil {
                        fehler = "Scan fehlgeschlagen — bitte erneut versuchen."
                    }
                    zeigeScan = false
                }
                .ignoresSafeArea()

                Button("Fertig") { stoppAnfrage = true }
                    .buttonStyle(.borderedProminent)
                    .tint(MykColor.brand)
                    .padding(.bottom, 40)
            }
        }
        .sheet(item: $exportDatei) { wrapper in
            TeilenAnsicht(activityItems: [wrapper.url])
        }
    }

    private func speichern(_ url: URL) {
        do {
            try roomPlanStore.aufnehmen(
                usdzQuelle: url,
                projectNumber: gewaehltesProjekt?.projectNumber,
                projectTitel: gewaehltesProjekt?.title,
                raumTitel: raumTitel.isEmpty ? nil : raumTitel
            )
            gespeichert = true
            fehler = nil
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }

    private func pdfExportieren(_ geometrie: RaumGeometrie) {
        do {
            let url = try GrundrissPDFRenderer.erstellePDF(geometrie: geometrie, titel: raumTitel.isEmpty ? "Grundriss" : raumTitel)
            exportDatei = ExportDatei(url: url)
            fehler = nil
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }

    private func dxfExportieren(_ geometrie: RaumGeometrie) {
        do {
            let url = try GrundrissDXFExporter.erstelleDXF(geometrie: geometrie)
            exportDatei = ExportDatei(url: url)
            fehler = nil
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }
}

#Preview {
    NavigationStack {
        RoomPlanCaptureScreen(roomPlanStore: RoomPlanStore(), projectStore: ProjectStore())
    }
}
