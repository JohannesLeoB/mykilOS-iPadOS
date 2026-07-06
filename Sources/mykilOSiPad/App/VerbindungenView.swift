import SwiftUI

/// §14-Datenschutz-Transparenz-Doktrin aus mykilOS iOS: ein Fähigkeiten-
/// Panel, das zeigt, was gerade verbunden ist. Gegenüber der iOS-Vorlage
/// bewusst schlanker — Airtable-/Claude-/Google-Drive-Anbindung existieren
/// in der iPad-App noch nicht (siehe `WORK_STATUS.md`), deshalb erscheinen
/// sie hier nicht als leere Behauptung, sondern gar nicht.
struct VerbindungenView: View {
    @State private var laserScanner = BluetoothLaserScanner.shared

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            Section {
                Toggle(isOn: Binding(
                    get: { laserScanner.aktiv },
                    set: { neu in neu ? laserScanner.aktivieren() : laserScanner.deaktivieren() }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bluetooth-Laser").font(.subheadline.weight(.semibold))
                        Text("Leica DISTO: Live-Messwerte · andere: Suchen & Verbinden")
                            .font(.caption).foregroundStyle(MykColor.muted)
                    }
                }
                if laserScanner.aktiv {
                    NavigationLink("Gerät koppeln") {
                        LaserKopplungView(scanner: laserScanner)
                    }
                }
            } header: {
                Text("Laser")
            } footer: {
                Text("Standardmäßig AUS. Nur Leica DISTO liefert echte Live-Messwerte (verifiziertes Protokoll). Andere Hersteller: Name-Erkennung + rohe Service-Liste, kein geratenes Protokoll.")
            }

            Section {
                HStack {
                    Text("Kamera").foregroundStyle(MykColor.ink)
                    Spacer()
                    Text("nur beim Fotografieren").font(.caption).foregroundStyle(MykColor.muted)
                }
                HStack {
                    Text("Bewegungssensoren").foregroundStyle(MykColor.ink)
                    Spacer()
                    Text("Kamera-Wasserwaage").font(.caption).foregroundStyle(MykColor.muted)
                }
            } header: {
                Text("Weitere Sensoren")
            } footer: {
                Text("Kein Standort-Tracking, kein Netzwerk-Zugriff außer lokalem BLE-Scan.")
            }

            Section {
                HStack {
                    Text("mykilOS iPad")
                    Spacer()
                    Text(appVersion).foregroundStyle(MykColor.muted).font(.system(.footnote, design: .monospaced))
                }
            } header: {
                Text("Über")
            } footer: {
                Text("Schwester-App zu mykilOS macOS und mykilOS iOS. Cloud-Anbindungen (Google Drive, Airtable, Claude-Assistent) sind hier noch nicht portiert.")
            }
        }
        .navigationTitle("Verbindungen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { VerbindungenView() }
}
