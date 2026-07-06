import RoomPlan
import SwiftUI
import UIKit

/// RoomPlan-Aufmaß: Projekt-/Raumtitel frei eintragen, Raum scannen (Apples
/// eigene Scan-UI), Ergebnis als USDZ sichern. Braucht ein LiDAR-Gerät — auf
/// anderen Geräten ehrlicher Fallback-Zustand statt Absturz.
///
/// Gegenüber mykilOS iOS angepasst: dort wurde ein Projekt aus einer
/// bestehenden `ProjectStore`-Liste gewählt — die iPad-App hat (noch) keine
/// eigene Projektverwaltung, deshalb freie Texteingabe für Projekt/Raum,
/// konsistent mit dem lose gekoppelten `Aufmass`-Modell.
struct RoomPlanCaptureScreen: View {
    let roomPlanStore: RoomPlanStore

    @State private var projectNumber = ""
    @State private var projectTitel = ""
    @State private var raumTitel = ""
    @State private var zeigeScan = false
    @State private var stoppAnfrage = false
    @State private var fertigesErgebnis: RoomPlanErgebnis?
    @State private var fehler: String?
    @State private var gespeichert = false
    @State private var exportDatei: ExportDatei?

    var body: some View {
        Group {
            if RoomCaptureSession.isSupported {
                Form {
                    Section("Zuordnung (optional)") {
                        TextField("Projekt", text: $projectTitel)
                        TextField("Projektnummer", text: $projectNumber)
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
                projectNumber: projectNumber.isEmpty ? nil : projectNumber,
                projectTitel: projectTitel.isEmpty ? nil : projectTitel,
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
        RoomPlanCaptureScreen(roomPlanStore: RoomPlanStore())
    }
}
