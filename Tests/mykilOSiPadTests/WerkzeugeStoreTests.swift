import Testing
import Foundation
@testable import mykilOSiPad

/// Persistenz-Logik der neustart-festen Werkzeug-Stores. Jeder Test bekommt
/// eine eigene Temp-Datei/-Ordner, damit nichts leckt und die Reload-Runde
/// (neuer Store, gleiche Datei) den echten Neustart nachstellt.
struct WerkzeugeStoreTests {

    private func tempDatei() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
    }

    private func tempOrdner() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - BarcodeLogStore

    @Test func barcodeLogSpeichertUndLaedtNeustartFest() throws {
        let url = tempDatei()
        let store = BarcodeLogStore(fileURL: url)
        try store.append(BarcodeTreffer(wert: "4006381333931", symbologie: "EAN13"))
        #expect(store.treffer.count == 1)

        let neuerStore = BarcodeLogStore(fileURL: url)
        #expect(neuerStore.treffer.count == 1)
        #expect(neuerStore.treffer.first?.wert == "4006381333931")
    }

    @Test func barcodeLogLoeschtEintrag() throws {
        let url = tempDatei()
        let store = BarcodeLogStore(fileURL: url)
        let treffer = try store.append(BarcodeTreffer(wert: "ABC", symbologie: "QR"))
        try store.remove(treffer.id)
        #expect(store.treffer.isEmpty)
        #expect(BarcodeLogStore(fileURL: url).treffer.isEmpty)
    }

    // MARK: - WareneingangsLogStore

    @Test func wareneingangSpeichertUndLaedtNeustartFest() throws {
        let url = tempDatei()
        let store = WareneingangsLogStore(fileURL: url)
        try store.append(WareneingangsEreignis(
            projectNumber: "2025-042", projectTitel: "Villa Blank",
            trackingNummer: "00340434", absender: "Miele"
        ))
        #expect(store.ereignisse.count == 1)

        let neuerStore = WareneingangsLogStore(fileURL: url)
        #expect(neuerStore.ereignisse.first?.trackingNummer == "00340434")
    }

    @Test func wareneingangLoeschenBleibtImmerErlaubt() throws {
        let url = tempDatei()
        let store = WareneingangsLogStore(fileURL: url)
        let e = WareneingangsEreignis(projectNumber: "1", projectTitel: "T", trackingNummer: "X", absender: "Y")
        try store.append(e)
        try store.remove(e.id)
        #expect(store.ereignisse.isEmpty)
    }

    // MARK: - AbnahmeprotokollStore

    @Test func abnahmeprotokollSpeichertTextEintragOhneFoto() throws {
        let dir = tempOrdner()
        let store = AbnahmeprotokollStore(documentsURL: dir)
        let eintrag = try store.hinzufuegen(
            projectNumber: "2025-042", projectTitel: "Villa Blank",
            text: "Fuge Bad unsauber", foto: nil
        )
        #expect(eintrag.fotoDateiname == nil)
        #expect(store.eintraege.count == 1)

        let neuerStore = AbnahmeprotokollStore(documentsURL: dir)
        #expect(neuerStore.eintraege.first?.text == "Fuge Bad unsauber")
    }

    @Test func abnahmeprotokollLoeschtEintrag() throws {
        let dir = tempOrdner()
        let store = AbnahmeprotokollStore(documentsURL: dir)
        let eintrag = try store.hinzufuegen(projectNumber: "1", projectTitel: "T", text: "Mangel", foto: nil)
        try store.remove(eintrag.id)
        #expect(store.eintraege.isEmpty)
    }

    // MARK: - ServicePartnerStore

    @Test func servicePartnerAnlegenUndPerIDAktualisieren() throws {
        let dir = tempOrdner()
        let store = ServicePartnerStore(documentsURL: dir)
        let partner = ServicePartner(name: "Miele Kundendienst", email: "service@miele.de", marken: "Miele")
        try store.speicherePartner(partner)
        #expect(store.partner.count == 1)

        var geaendert = partner
        geaendert.email = "neu@miele.de"
        try store.speicherePartner(geaendert)
        #expect(store.partner.count == 1) // gleiche id → ersetzt, nicht angehängt
        #expect(store.partner.first?.email == "neu@miele.de")
    }

    @Test func servicePartnerLoggtAnfrageNeustartFest() throws {
        let dir = tempOrdner()
        let store = ServicePartnerStore(documentsURL: dir)
        try store.loggeAnfrage(ServiceAnfrage(
            partnerName: "Miele", projectTitel: "Villa Blank", geraet: "G 7310 SCi"
        ))
        #expect(store.anfragen.count == 1)
        #expect(ServicePartnerStore(documentsURL: dir).anfragen.first?.geraet == "G 7310 SCi")
    }
}
