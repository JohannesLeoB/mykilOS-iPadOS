import Foundation

/// Architektur für "ganz viele" Laser-Hersteller statt einen fest
/// verdrahteten (Vorbild: `LaserAdapter.swift` aus mykilOS iOS, 1:1 mit
/// Ergänzung Laserliner übernommen — Johannes wünscht ~15 Top-Hersteller
/// europäischer Bluetooth-Laser-Entfernungsmesser der letzten 5-7 Jahre).
///
/// **Ehrlichkeitsregel, nicht verhandelbar:** Kein Adapter hier erfindet
/// GATT-Service-/Characteristic-IDs aus der Erinnerung. `istProtokollVerifiziert`
/// ist bei jedem Adapter `false`, bis er an echter Hardware getestet wurde —
/// die Namens-Erkennung hilft schon beim Einordnen ("das ist ein Bosch"),
/// aber liefert bewusst KEINEN Messwert vor der echten Verifikation. Lieber
/// ehrlich "noch nicht" als eine stillschweigend falsche Zahl.
protocol LaserAdapter: Sendable {
    var herstellerName: String { get }
    var istProtokollVerifiziert: Bool { get }
    /// Vertrauensstufe der Namens-Heuristik selbst — auch die Erkennung
    /// ist bei manchen Herstellern nur eine Vermutung, kein bestätigtes
    /// Muster aus echten Geräten.
    var erkennungsVertrauen: LaserErkennungsVertrauen { get }
    func erkennt(geraeteName: String) -> Bool
}

enum LaserErkennungsVertrauen: String, Sendable {
    case etabliert = "Etablierte BLE-Schnittstelle, viele Dritt-Apps nutzen sie bereits"
    case wahrscheinlich = "Bluetooth-Modelle bekannt, Namens-Muster ungeprüft"
    case unsicher = "Nicht verlässlich bestätigt, ob/wie dieser Hersteller offene BLE-Distanzwerte anbietet"
}

/// **Leica DISTO** — die etablierteste BLE-Schnittstelle in diesem Bereich,
/// viele Dritt-Apps binden sich hierüber an.
struct LeicaDistoAdapter: LaserAdapter {
    let herstellerName = "Leica DISTO"
    let istProtokollVerifiziert = false
    let erkennungsVertrauen = LaserErkennungsVertrauen.etabliert
    func erkennt(geraeteName: String) -> Bool {
        geraeteName.uppercased().contains("DISTO")
    }
}

/// **Bosch GLM** — eigenes Ökosystem ("Measuring Master"), Bluetooth-Modelle
/// bekannt, Dritt-Zugriff eher über Partnerprogramm.
struct BoschGLMAdapter: LaserAdapter {
    let herstellerName = "Bosch GLM"
    let istProtokollVerifiziert = false
    let erkennungsVertrauen = LaserErkennungsVertrauen.wahrscheinlich
    func erkennt(geraeteName: String) -> Bool {
        let name = geraeteName.uppercased()
        return name.contains("GLM") || name.contains("BOSCH")
    }
}

/// **Stanley** (TLM-Serie) — hat Bluetooth-Modelle, Namens-Muster ungeprüft.
struct StanleyAdapter: LaserAdapter {
    let herstellerName = "Stanley"
    let istProtokollVerifiziert = false
    let erkennungsVertrauen = LaserErkennungsVertrauen.wahrscheinlich
    func erkennt(geraeteName: String) -> Bool {
        let name = geraeteName.uppercased()
        return name.contains("STANLEY") || name.contains("TLM")
    }
}

/// **DeWalt** — hat Laser-Entfernungsmesser im Programm, ob/wie offen die
/// Bluetooth-Schnittstelle ist, ist unsicher.
struct DeWaltAdapter: LaserAdapter {
    let herstellerName = "DeWalt"
    let istProtokollVerifiziert = false
    let erkennungsVertrauen = LaserErkennungsVertrauen.unsicher
    func erkennt(geraeteName: String) -> Bool {
        geraeteName.uppercased().contains("DEWALT")
    }
}

/// **Milwaukee** — bekannt für das ONE-KEY-Ökosystem (eher Werkzeug-Tracking
/// als Distanzmessung), ob ein offenes Distanz-Protokoll existiert, ist
/// unsicher.
struct MilwaukeeAdapter: LaserAdapter {
    let herstellerName = "Milwaukee"
    let istProtokollVerifiziert = false
    let erkennungsVertrauen = LaserErkennungsVertrauen.unsicher
    func erkennt(geraeteName: String) -> Bool {
        geraeteName.uppercased().contains("MILWAUKEE")
    }
}

/// **Hilti** (PD-Serie) — Profi-Linie, einzelne Modelle mit Bluetooth,
/// Namens-Muster ungeprüft.
struct HiltiAdapter: LaserAdapter {
    let herstellerName = "Hilti"
    let istProtokollVerifiziert = false
    let erkennungsVertrauen = LaserErkennungsVertrauen.wahrscheinlich
    func erkennt(geraeteName: String) -> Bool {
        let name = geraeteName.uppercased()
        return name.contains("HILTI") || name.contains("PD-")
    }
}

/// **Makita** — hat Laser-Messwerkzeuge im Programm, offene BLE-Schnittstelle
/// unsicher.
struct MakitaAdapter: LaserAdapter {
    let herstellerName = "Makita"
    let istProtokollVerifiziert = false
    let erkennungsVertrauen = LaserErkennungsVertrauen.unsicher
    func erkennt(geraeteName: String) -> Bool {
        geraeteName.uppercased().contains("MAKITA")
    }
}

/// **Einhell** — DIY-/Consumer-Werkzeugmarke, hat Laser-Messwerkzeuge im
/// Programm, offene BLE-Schnittstelle unsicher.
struct EinhellAdapter: LaserAdapter {
    let herstellerName = "Einhell"
    let istProtokollVerifiziert = false
    let erkennungsVertrauen = LaserErkennungsVertrauen.unsicher
    func erkennt(geraeteName: String) -> Bool {
        geraeteName.uppercased().contains("EINHELL")
    }
}

/// **Worx** — Werkzeugmarke (Positec), App-verbundene Werkzeuge existieren,
/// ob ein offenes Laser-Distanz-Protokoll existiert, ist unsicher.
struct WorxAdapter: LaserAdapter {
    let herstellerName = "Worx"
    let istProtokollVerifiziert = false
    let erkennungsVertrauen = LaserErkennungsVertrauen.unsicher
    func erkennt(geraeteName: String) -> Bool {
        geraeteName.uppercased().contains("WORX")
    }
}

/// **Stier** — kleinere Werkzeugmarke, am wenigsten verifizierbar, ob es
/// überhaupt Bluetooth-Modelle gibt.
struct StierAdapter: LaserAdapter {
    let herstellerName = "Stier"
    let istProtokollVerifiziert = false
    let erkennungsVertrauen = LaserErkennungsVertrauen.unsicher
    func erkennt(geraeteName: String) -> Bool {
        geraeteName.uppercased().contains("STIER")
    }
}

/// **Ryobi** — großer Werkzeughersteller (TTI), Bluetooth-Laser-Distanz-
/// Modell nicht sicher bekannt, Namens-Erkennung ein Platzhalter.
struct RyobiAdapter: LaserAdapter {
    let herstellerName = "Ryobi"
    let istProtokollVerifiziert = false
    let erkennungsVertrauen = LaserErkennungsVertrauen.unsicher
    func erkennt(geraeteName: String) -> Bool {
        geraeteName.uppercased().contains("RYOBI")
    }
}

/// **Laserliner** (Umarex-Gruppe) — deutsche Consumer-/Profi-Messtechnik-Marke,
/// hat Bluetooth-fähige Distanzmesser (z.B. DistanceMaster-Reihe) im Programm.
/// Offene BLE-Distanzwert-Schnittstelle für Drittanbieter nicht verlässlich
/// bestätigt — bewusst neu ergänzt für die iPad-App, noch ohne echte Prüfung.
struct LaserlinerAdapter: LaserAdapter {
    let herstellerName = "Laserliner"
    let istProtokollVerifiziert = false
    let erkennungsVertrauen = LaserErkennungsVertrauen.unsicher
    func erkennt(geraeteName: String) -> Bool {
        geraeteName.uppercased().contains("LASERLINER")
    }
}

/// Zentrale Liste — neue Hersteller kommen als neuer Adapter dazu, nie als
/// Umbau der bestehenden. Reihenfolge = grobe Vertrauens-Reihenfolge.
enum LaserAdapterRegistry {
    static let alle: [LaserAdapter] = [
        LeicaDistoAdapter(),
        BoschGLMAdapter(),
        StanleyAdapter(),
        HiltiAdapter(),
        DeWaltAdapter(),
        MilwaukeeAdapter(),
        MakitaAdapter(),
        EinhellAdapter(),
        WorxAdapter(),
        RyobiAdapter(),
        StierAdapter(),
        LaserlinerAdapter()
    ]

    static func erkenne(geraeteName: String) -> LaserAdapter? {
        alle.first { $0.erkennt(geraeteName: geraeteName) }
    }
}
