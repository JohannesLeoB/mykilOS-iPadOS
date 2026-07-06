@preconcurrency import CoreBluetooth
import Observation

/// Generisches Bluetooth-LE-Gerüst für den Laser-Messgeräte-Anschluss —
/// bewusst OHNE erfundene Herstellerprotokolldetails, solange nicht
/// feststeht, welches Gerät im Studio verwendet wird. Was hier wirklich
/// passiert: scannen, verbinden, die echten GATT-Services/Characteristics
/// des verbundenen Geräts anzeigen. Das ist der Explorer, der später —
/// sobald ein echtes Gerät in der Hand ist — die richtigen IDs für das
/// eigentliche Mess-Wert-Parsing liefert, statt eine Herstellerschnittstelle
/// zu raten.
///
/// Portiert aus mykilOS iOS (`BluetoothLaserScanner.swift`), mit einer
/// bewussten Architektur-Korrektur: `CBCentralManager(delegate:queue: nil)`
/// garantiert laut Apple-Doku Delegate-Aufrufe auf der Main-Queue. Die
/// iOS-Version markierte die Delegate-Methoden trotzdem `nonisolated` und
/// hoppte per `Task { @MainActor in }` zurück — das erzeugte 8 ungelöste
/// Sendable-Warnings beim Erfassen von `CBPeripheral` (nicht `Sendable`)
/// über die Task-Grenze. Hier stattdessen `@preconcurrency import
/// CoreBluetooth`: die Delegate-Konformanz bleibt MainActor-isoliert (wie
/// die Klasse selbst), keine Task-Hops, keine Sendable-Warnings — korrekt,
/// weil die Laufzeit-Garantie (Main-Queue) mit der statischen Isolation
/// übereinstimmt.
///
/// Off-by-default wie jede sensible Fähigkeit. Kein Mess-Wert wird hier
/// interpretiert, außer für das eine dokumentierte Leica-DISTO-Protokoll.
@MainActor
@Observable
final class BluetoothLaserScanner: NSObject, @preconcurrency CBCentralManagerDelegate, @preconcurrency CBPeripheralDelegate {
    /// Eine App-weite Instanz: die BLE-Verbindung muss die Navigation
    /// ueberleben (koppeln in "Verbindungen", messen im Aufmaß-Modus).
    /// Erst der Toggle erzeugt den CBCentralManager — off-by-default bleibt.
    static let shared = BluetoothLaserScanner()

    private(set) var aktiv: Bool
    private(set) var scanntGerade = false
    private(set) var gefundeneGeraete: [BLEGeraet] = []
    private(set) var verbundenesGeraet: BLEGeraet?
    private(set) var entdeckteServices: [BLEService] = []
    private(set) var fehler: String?

    /// Letzter echter Laser-Messwert (Leica-DISTO-Protokoll), in Millimetern.
    /// Bleibt nil, bis ein Geraet wirklich funkt — nie ein Platzhalterwert.
    private(set) var letzterMesswertMM: Int?
    private(set) var letzterMesswertZeit: Date?
    private(set) var messwertQuelle: String?

    private var manager: CBCentralManager?
    private var peripherals: [UUID: CBPeripheral] = [:]

    private static let aktivKey = "bluetoothLaserAktiv"

    override init() {
        self.aktiv = UserDefaults.standard.bool(forKey: Self.aktivKey)
        super.init()
        if aktiv {
            manager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    func aktivieren() {
        aktiv = true
        UserDefaults.standard.set(true, forKey: Self.aktivKey)
        if manager == nil {
            manager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    func deaktivieren() {
        scanStoppen()
        if let verbundenesGeraet, let peripheral = peripherals[verbundenesGeraet.id] {
            manager?.cancelPeripheralConnection(peripheral)
        }
        self.verbundenesGeraet = nil
        entdeckteServices = []
        gefundeneGeraete = []
        aktiv = false
        UserDefaults.standard.set(false, forKey: Self.aktivKey)
    }

    func scanStarten() {
        guard let manager, manager.state == .poweredOn else {
            fehler = "Bluetooth ist nicht eingeschaltet oder noch nicht bereit."
            return
        }
        gefundeneGeraete = []
        fehler = nil
        scanntGerade = true
        manager.scanForPeripherals(withServices: nil)
    }

    func scanStoppen() {
        manager?.stopScan()
        scanntGerade = false
    }

    func verbinden(_ geraet: BLEGeraet) {
        guard let peripheral = peripherals[geraet.id] else { return }
        scanStoppen()
        manager?.connect(peripheral)
    }

    func trennen() {
        guard let verbundenesGeraet, let peripheral = peripherals[verbundenesGeraet.id] else { return }
        manager?.cancelPeripheralConnection(peripheral)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            scanntGerade = false
            if central.state == .unauthorized {
                fehler = "Keine Berechtigung für Bluetooth erteilt."
            }
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name ?? "Unbekanntes Gerät"
        let id = peripheral.identifier
        peripherals[id] = peripheral
        if let index = gefundeneGeraete.firstIndex(where: { $0.id == id }) {
            gefundeneGeraete[index] = BLEGeraet(id: id, name: name, rssi: RSSI.intValue)
        } else {
            gefundeneGeraete.append(BLEGeraet(id: id, name: name, rssi: RSSI.intValue))
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let name = peripheral.name ?? "Unbekanntes Gerät"
        verbundenesGeraet = BLEGeraet(id: peripheral.identifier, name: name, rssi: 0)
        entdeckteServices = []
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        fehler = "Verbindung fehlgeschlagen: \(error?.localizedDescription ?? "unbekannter Fehler")"
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        verbundenesGeraet = nil
        entdeckteServices = []
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let serviceID = service.uuid.uuidString
        let charakteristiken = (service.characteristics ?? []).map { charakteristik in
            BLECharacteristic(id: charakteristik.uuid.uuidString, eigenschaften: lesbareEigenschaften(charakteristik.properties))
        }
        // Leica-DISTO-Service erkannt: Mess-Characteristics abonnieren
        // (dokumentiertes Protokoll, siehe LeicaDistoProtokoll). Fuer alle
        // anderen Hersteller bleibt es beim reinen Explorer — keine
        // geratenen Abos.
        if service.uuid == LeicaDistoProtokoll.service {
            for charakteristik in service.characteristics ?? []
            where LeicaDistoProtokoll.messCharakteristiken.contains(charakteristik.uuid)
                && (charakteristik.properties.contains(.notify) || charakteristik.properties.contains(.indicate)) {
                peripheral.setNotifyValue(true, for: charakteristik)
            }
        }
        if let index = entdeckteServices.firstIndex(where: { $0.id == serviceID }) {
            entdeckteServices[index].characteristics = charakteristiken
        } else {
            entdeckteServices.append(BLEService(id: serviceID, characteristics: charakteristiken))
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil,
              LeicaDistoProtokoll.messCharakteristiken.contains(characteristic.uuid),
              let daten = characteristic.value,
              let millimeter = LeicaDistoProtokoll.distanzInMM(aus: daten) else { return }
        letzterMesswertMM = millimeter
        letzterMesswertZeit = Date()
        messwertQuelle = "Leica DISTO"
    }

    private func lesbareEigenschaften(_ eigenschaften: CBCharacteristicProperties) -> [String] {
        var ergebnis: [String] = []
        if eigenschaften.contains(.read) { ergebnis.append("read") }
        if eigenschaften.contains(.write) { ergebnis.append("write") }
        if eigenschaften.contains(.notify) { ergebnis.append("notify") }
        if eigenschaften.contains(.indicate) { ergebnis.append("indicate") }
        return ergebnis
    }
}
