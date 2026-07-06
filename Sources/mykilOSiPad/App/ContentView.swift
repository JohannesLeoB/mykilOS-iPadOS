import SwiftUI

/// Vorläufiges Navigationsgerüst, um die bisher gebauten Module (Grundriss-
/// Editor, RoomPlan-Aufmaß, Bluetooth-Laser-Kopplung) sichtbar und testbar
/// zu machen. Kein endgültiges IA-Design — nur der Nagel, an dem die
/// bisherigen Bausteine hängen, bis das eigentliche mykilOS-Modul-Layout
/// (Sidebar, Breadcrumb-Topbar wie bei mykilOS Core) übernommen wird.
struct ContentView: View {
    private let aufmassStore = AufmassStore()
    private let roomPlanStore = RoomPlanStore()
    private let grundrissStore = GrundrissEditorStore()

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink("Grundriss-Editor") {
                    GrundrissEditorScreen(store: grundrissStore, dokument: GrundrissDokument())
                }
                NavigationLink("Foto-Bemaßung") {
                    FotoBemassungView(aufmassStore: aufmassStore)
                }
                NavigationLink("RoomPlan-Aufmaß (LiDAR)") {
                    RoomPlanCaptureScreen(roomPlanStore: roomPlanStore)
                }
                NavigationLink("Raumscans") {
                    RoomPlanListView(roomPlanStore: roomPlanStore)
                }
            }
            .navigationTitle("MYKILOS")
        } detail: {
            VStack(spacing: 24) {
                Text("mykilOS")
                    .font(.system(size: 34, weight: .medium, design: .default))
                    .foregroundStyle(MykColor.ink)
                Text("iPad — Aufmaß-Modus im Aufbau")
                    .foregroundStyle(MykColor.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MykColor.paper)
        }
    }
}

#Preview {
    ContentView()
}
