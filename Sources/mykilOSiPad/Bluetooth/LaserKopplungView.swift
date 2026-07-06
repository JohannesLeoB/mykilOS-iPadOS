import SwiftUI

/// Bluetooth-Laser-Kopplung — bewusst noch OHNE Mess-Werte für die meisten
/// Hersteller. Scannt, verbindet, zeigt die echten GATT-Services/
/// Characteristics des verbundenen Geräts. 1:1 aus mykilOS iOS übernommen.
struct LaserKopplungView: View {
    let scanner: BluetoothLaserScanner

    var body: some View {
        List {
            if let verbundenesGeraet = scanner.verbundenesGeraet {
                Section {
                    HStack {
                        Text(verbundenesGeraet.name).font(.subheadline.weight(.semibold))
                        Spacer()
                        Button("Trennen", role: .destructive) { scanner.trennen() }
                            .font(.caption)
                    }
                    if let millimeter = scanner.letzterMesswertMM {
                        HStack {
                            Label("\(millimeter) mm", systemImage: "ruler.fill")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(MykColor.brand)
                            Spacer()
                            if let zeit = scanner.letzterMesswertZeit {
                                Text(zeit.formatted(date: .omitted, time: .standard))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(MykColor.muted)
                            }
                        }
                    }
                } header: {
                    Text("Verbunden")
                } footer: {
                    if verbundenesGeraet.erkannterHersteller == "Leica DISTO" {
                        Text("Leica-DISTO angebunden: Messtaste drücken – der Wert erscheint hier und in der Foto-Bemaßung. Gerät auf METER stellen.")
                    } else if let hersteller = verbundenesGeraet.erkannterHersteller {
                        Text("Als \(hersteller) erkannt (per Name, unbestätigt) — Mess-Protokoll noch nicht verifiziert, nur die Service-Liste unten nutzbar.")
                    } else {
                        Text("Kein Hersteller erkannt — über die Service-Liste unten erkundbar.")
                    }
                }

                Section {
                    if scanner.entdeckteServices.isEmpty {
                        Text("Suche nach Services…").font(.footnote).foregroundStyle(MykColor.muted)
                    } else {
                        ForEach(scanner.entdeckteServices) { service in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(service.id)
                                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                                ForEach(service.characteristics) { charakteristik in
                                    HStack {
                                        Text(charakteristik.id)
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundStyle(MykColor.muted)
                                        Spacer()
                                        Text(charakteristik.eigenschaften.joined(separator: ", "))
                                            .font(.caption2)
                                            .foregroundStyle(MykColor.brand)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text("Gefundene Services")
                } footer: {
                    Text("Diese IDs binden das echte Mess-Protokoll deines Geräts an.")
                }
            } else {
                Section {
                    Button(scanner.scanntGerade ? "Suche läuft…" : "Nach Geräten suchen") {
                        scanner.scanStarten()
                    }
                    .disabled(scanner.scanntGerade)
                }

                if !scanner.gefundeneGeraete.isEmpty {
                    Section("Gefundene Geräte") {
                        ForEach(scanner.gefundeneGeraete) { geraet in
                            Button {
                                scanner.verbinden(geraet)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(geraet.name)
                                        if let hersteller = geraet.erkannterHersteller {
                                            Text(hersteller)
                                                .font(.caption2)
                                                .foregroundStyle(MykColor.brand)
                                        }
                                    }
                                    Spacer()
                                    Text("\(geraet.rssi) dBm")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(MykColor.muted)
                                }
                            }
                            .foregroundStyle(MykColor.ink)
                        }
                    }
                }
            }

            if let fehler = scanner.fehler {
                Text(fehler).font(.footnote).foregroundStyle(MykColor.crit)
            }
        }
        .navigationTitle("Laser koppeln")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { scanner.scanStoppen() }
    }
}

#Preview {
    NavigationStack {
        LaserKopplungView(scanner: BluetoothLaserScanner.shared)
    }
}
