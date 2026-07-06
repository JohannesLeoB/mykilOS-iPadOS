import SwiftUI

/// Start-/Dashboard-Modul — schlankere erste Fassung von mykilOS iOS'
/// `StartHomeView`/`GlanceCockpitView` (Kachel-Launcher + "gerade heiß"-
/// Zeile). Zeigt echte Zahlen aus den hochgezogenen Stores, keine
/// Platzhalter-Kacheln.
struct HeuteView: View {
    let stores: AppStores

    private var laser: BluetoothLaserScanner { .shared }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                kopf
                kachelReihe
                laserStatus
            }
            .padding(24)
        }
        .background(MykColor.paper)
        .navigationTitle("Heute")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var kopf: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date(), style: .date)
                .font(.mykMono(12)).foregroundStyle(MykColor.muted)
            Text("Guten Tag")
                .font(.mykGrotesk(30)).foregroundStyle(MykColor.ink)
        }
    }

    private var kachelReihe: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 14)], spacing: 14) {
            kachel(titel: "Projekte", zahl: stores.projectStore.projects.count, sfName: "folder")
            kachel(titel: "Aufmaße", zahl: stores.aufmassStore.aufmasse.count, sfName: "camera.viewfinder")
            kachel(titel: "Grundrisse", zahl: stores.grundrissStore.dokumente.count, sfName: "square.on.square.dashed")
            kachel(titel: "RoomPlan-Scans", zahl: stores.roomPlanStore.aufnahmen.count, sfName: "cube.transparent")
        }
    }

    private func kachel(titel: String, zahl: Int, sfName: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: sfName).font(.system(size: 20)).foregroundStyle(MykColor.brand)
            Text("\(zahl)").font(.mykGrotesk(28)).foregroundStyle(MykColor.ink)
            Text(titel.uppercased()).font(.mykMono(11)).tracking(1.0).foregroundStyle(MykColor.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MykColor.card)
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(MykColor.line, lineWidth: 0.5))
    }

    private var laserStatus: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(laser.letzterMesswertMM != nil ? MykColor.ok : MykColor.muted)
                .frame(width: 8, height: 8)
            Text(laser.letzterMesswertMM.map { "Laser verbunden · letzter Wert \($0) mm" } ?? "Kein Laser verbunden")
                .font(.mykMono(12))
                .foregroundStyle(MykColor.muted)
        }
    }
}

#Preview {
    NavigationStack { HeuteView(stores: AppStores()) }
}
