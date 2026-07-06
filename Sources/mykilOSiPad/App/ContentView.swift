import SwiftUI

struct ContentView: View {
    @State private var laser = BluetoothLaserScanner.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("mykilOS")
                    .font(.system(size: 34, weight: .medium, design: .default))
                    .foregroundStyle(MykColor.ink)
                Text("iPad — Aufmaß-Modus im Aufbau")
                    .foregroundStyle(MykColor.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MykColor.paper)
            .navigationTitle("MYKILOS")
        }
    }
}

#Preview {
    ContentView()
}
