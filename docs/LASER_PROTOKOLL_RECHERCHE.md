# Laser-Entfernungsmesser — BLE-Protokoll-Recherche

Ziel: Echte BLE-GATT-Adapter statt Namens-Heuristiken. Diese Datei dokumentiert pro Hersteller,
welche BLE Service-/Characteristic-UUIDs und welches Datenformat für Distanzmessungen bekannt sind,
und ob das Protokoll öffentlich dokumentiert, reverse-engineered oder unbekannt ist.

Recherchestand: 2026-07-07. Quellen am Ende. Wo kein öffentliches Protokoll existiert, steht
ausdrücklich "unbekannt / nicht öffentlich dokumentiert" — es werden **keine** UUIDs erfunden.

> Wichtiger Praxis-Hinweis: Fast alle dieser Geräte werden von den Cross-Vendor-Apps
> **imagemeter** und **magicplan** unterstützt. Deren interne Adapter sind die verlässlichste
> Evidenz dafür, dass ein Gerät ein maschinenlesbares BLE-Distanzprotokoll besitzt — auch wenn
> die konkreten UUIDs nicht öffentlich publiziert sind. Für die meisten Hersteller unten musste
> das Protokoll durch Sniffing der Hersteller-App reverse-engineered werden; es gibt keine
> offizielle GATT-Spezifikation.

## Zusammenfassung (Übersicht)

| Hersteller | BLE dokumentiert? | Service-UUID | Notiz |
|---|---|---|---|
| **Leica (DISTO)** | Reverse-engineered, gut belegt (Referenz) | `3ab10100-f831-4395-b29d-570977d5bf94` | Float in Messungs-Characteristic. De-facto-Standard für viele DISTO-Modelle. |
| **Bosch (GLM / Measuring Master)** | Reverse-engineered, gut belegt | `02a6c0d0-0451-4000-b000-fb3210111989` | IEEE-754 Float LE in Metern; Start-Kommando per Write; Antwort per Indication. |
| **Einhell** | Unbekannt / nicht öffentlich dokumentiert | — | TE-LD 60 in imagemeter gelistet; keine öffentliche Protokolldoku. Wahrscheinlich rebadged. |
| **Laserliner** | Unbekannt / nicht öffentlich (proprietär, in Apps implementiert) | — | MeasureNote-App; imagemeter unterstützt Gi7 Pro / T4 Pro. Kein öffentliches GATT. |
| **Stabila** | Unbekannt / nicht öffentlich dokumentiert | — | LD 250 BT / LD 520 / LD 530 BT; "Measures"-App; kein publiziertes Protokoll. |
| **Hilti** | Unbekannt / nicht öffentlich dokumentiert | — | PD-I / PD-38; nutzt Partner-Apps (magicplan, imagemeter). Kein öffentliches GATT. |
| **Makita** | Unbekannt / kein BLE bekannt | — | LD080P u.a. haben i.d.R. **kein** Bluetooth. Kein Adapter sinnvoll. |
| **Stanley / DeWalt** | Unbekannt / nicht öffentlich dokumentiert | — | TLM99s/165si bzw. DW099S/DW0330SN; eigene "Smart Connect"/"Tool Connect"-Apps. |
| **Metabo** | Unbekannt / vermutlich kein BLE | — | LD-Serie; keine belastbaren Hinweise auf App-fähiges BLE. |
| **Würth** | Unbekannt / nicht öffentlich dokumentiert | — | WDM 3-19 … 9-24 in imagemeter gelistet; kein publiziertes Protokoll. |
| **CEM** | Unbekannt / nicht öffentlich (proprietär) | — | iLDM-Serie; Meterbox/iDM-App; proprietäres BLE-Protokoll, nicht publiziert. |
| **Mileseey** | Unbekannt / nicht öffentlich dokumentiert | — | P7/P9/T7/DT20 etc.; OEM/rebadge-Familie; kein publiziertes GATT. |

**Fazit für die Implementierung:** Zuverlässig mit echten, publiziert reverse-engineerten
UUIDs implementierbar sind nur **Leica DISTO** und **Bosch GLM**. Für alle anderen Hersteller
existiert öffentlich kein GATT-Layout; ein echter Adapter erfordert entweder eigenes BLE-Sniffing
der jeweiligen Hersteller-App oder eine Lizenz/Partnerschaft (wie sie imagemeter/magicplan haben).

---

## Leica (DISTO) — Referenzimplementierung

**Status:** Reverse-engineered, mehrfach unabhängig bestätigt. Keine offizielle Leica-Spezifikation,
aber das Layout ist über mehrere Community-Projekte konsistent belegt und gilt als De-facto-Standard
über viele DISTO-BLE-Modelle (D1, D2, D110, D510, X3, X4 …).

**Service-UUID**
```
3ab10100-f831-4395-b29d-570977d5bf94
```

**Characteristics** (128-bit, gleiche Basis, Byte 3-4 variiert)

| Zweck | UUID | Eigenschaften |
|---|---|---|
| Distanz-Messung | `3ab10101-f831-4395-b29d-570977d5bf94` | Read, Indicate |
| Einheiten | `3ab10102-f831-4395-b29d-570977d5bf94` | Read, Indicate |
| Kommando | `3ab10109-f831-4395-b29d-570977d5bf94` | Write Without Response |
| Distanz-Notify (alt. Variante) | `3ab1010d-f831-4395-b29d-570977d5bf94` | Notify/Indicate |
| Device-ID | `3ab1010c-f831-4395-b29d-570977d5bf94` | Read |

> Hinweis: Verschiedene Modelle/Firmwares exponieren die Messung teils auf `...0101` (z. B. d2relay,
> Leica D2) und teils auf `...010d` (z. B. DISTO X3 laut B4X-Forum). Ein robuster Adapter sollte beide
> auf Notify/Indicate abonnieren.

**Datenformat der Distanz**
- Ein **IEEE-754 32-bit Float**, **Little Endian** (die ersten 4 Bytes des Nutzdaten-Arrays in
  umgekehrter Reihenfolge → Float).
- Wert in **Metern** (bzw. in der am Gerät eingestellten Einheit; Einheiten-Characteristic separat).
- Der Client abonniert die Messungs-Characteristic; eine neue Messung (Tastendruck am Gerät oder
  ausgelöst) erzeugt eine Indication/Notification mit dem Float.

**Quellen:** seichter/d2relay (`doc/notes.md`); B4X-Forum "BLE2 = Leica Disto and Bosch laser rangefinder".

---

## Bosch (GLM-Serie / Bosch Measuring Master)

**Status:** Reverse-engineered aus BLE-Dumps der "Measuring Master"-App; öffentlich gut belegt
(z. B. GLM 50 C/G, GLM 100 C, GLM 50-27 CG). Keine offizielle Bosch-Spezifikation.

**Service-UUID**
```
02a6c0d0-0451-4000-b000-fb3210111989
```

**Characteristic-UUID (Messung / Kommando)**
```
02a6c0d1-0451-4000-b000-fb3210111989   (im selben Service, Write + Indicate)
```

**Mess-Ablauf**
- Zum Starten der Messung wird die Byte-Sequenz `c0 56 01 00 1e` auf die Characteristic
  `02a6c0d1...` geschrieben.
- Das Gerät antwortet mit zwei **Indications** auf derselben Characteristic.

**Datenformat der Distanz**
- **IEEE-754 32-bit Float**, **Little Endian**, in **Metern**.
- Beispiel: Byte-Sequenz `2C 43 9C 3E` → `0.305 m`.

> Achtung: Nicht alle GLM-Modelle verhalten sich identisch; manche älteren Bosch-Geräte nutzen
> statt BLE das serielle "MT"-Protokoll (Bosch MT-Protocol) über SPP/Serial. Der GATT-Layout oben
> gilt für die BLE-fähigen GLM-…C-Modelle.

**Quellen:** alexwhittemore.com "Reverse Engineering Cheap BLE Devices"; ketan/Bosch-GLM50C-Rangefinder;
pklaus/bsch; Nordic DevZone "Sniffing a Bosch laser tape"; B4X-Forum (Bosch GLM100C MT-Protocol).

---

## Einhell

**Status:** Unbekannt / nicht öffentlich dokumentiert.

Einhell führt Laser-Entfernungsmesser (u. a. TE-LD-Serie). Das Modell **TE-LD 60** ist in der
imagemeter-Geräteliste als unterstützt geführt — d. h. es besitzt ein maschinenlesbares
BLE-Protokoll —, aber weder Service- noch Characteristic-UUIDs sind öffentlich publiziert. Einhell
gilt als Rebadge-/OEM-Kunde; das Protokoll könnte einer der generischen OEM-Familien (siehe
Mileseey/CEM) entsprechen, ist aber nicht bestätigt. Für einen echten Adapter ist eigenes
App-Sniffing nötig.

**Quellen:** imagemeter Supported Devices; Einhell Produktseite Messtechnik.

---

## Laserliner

**Status:** Unbekannt / nicht öffentlich (proprietär, nur in Apps implementiert).

Laserliner betreibt die eigene **MeasureNote**-App, die "laufend neue Kommunikationsprotokolle"
für verschiedene Modelle ergänzt (getestet u. a. **LaserRange-Master Gi7 Pro** und **T4 Pro**).
imagemeter unterstützt ebenfalls DistanceMaster Compact Pro/Plus sowie Gi7 Pro / T4 Pro. Das
belegt ein reales BLE-Protokoll, aber es ist nicht öffentlich dokumentiert; UUIDs unbekannt.

**Quellen:** Laserliner MeasureNote (laserliner.com, Play Store); imagemeter Supported Devices.

---

## Stabila

**Status:** Unbekannt / nicht öffentlich dokumentiert.

Modelle **LD 250 BT**, **LD 520**, **LD 530 BT** senden Messwerte per "Bluetooth Smart" (BLE 4.0,
LD 530 BT: BLE 5.0) an die kostenlose **STABILA Measures**-App. imagemeter listet LD250 BT / LD520
als unterstützt. Es existiert also ein reales BLE-Distanzprotokoll, aber keine öffentliche
GATT-Dokumentation; UUIDs unbekannt.

**Quellen:** stabila.com (LD 250 BT, LD 530 BT); imagemeter Supported Devices.

---

## Hilti

**Status:** Unbekannt / nicht öffentlich dokumentiert.

**PD-I** (und PD-38) haben eine integrierte Bluetooth-Schnittstelle und übertragen Messwerte per
Tastendruck an Partner-Apps (magicplan, imagemeter, Floor Plan Creator, WinWorker). Damit ist ein
maschinenlesbares BLE-Protokoll belegt, jedoch nicht öffentlich spezifiziert; UUIDs unbekannt.

**Quellen:** hilti.com PD-I; imagemeter Supported Devices.

---

## Makita

**Status:** Unbekannt / vermutlich kein BLE-Distanzprotokoll — Adapter nicht sinnvoll.

Makita-Laser-Distanzmesser (z. B. **LD080P / LD050P**) sind reine Handgeräte **ohne** Bluetooth-
Konnektivität; sie tauchen in keiner der Cross-Vendor-App-Listen auf. Es ist kein App-fähiges
BLE-Distanzprotokoll bekannt. (Makitas Bluetooth-Fokus liegt auf AWS-Staubsauger-Kopplung, nicht auf
Distanzmessern.)

**Quellen:** makitatools.com / makitauk.com LD080P; Abwesenheit in imagemeter/magicplan-Listen.

---

## Stanley / DeWalt

**Status:** Unbekannt / nicht öffentlich dokumentiert.

Stanley (**TLM99s / TLM99si / TLM165si**, FatMax-Serie) nutzt die **STANLEY Smart Connect**-App;
DeWalt (**DW099S / DW0330SN**, teils identisch als **DW03050**) nutzt die **Tool Connect**-App.
Beide sind BLE-fähig (imagemeter listet TLM99s/99si/165si sowie DW03050), das Protokoll ist aber
nicht öffentlich dokumentiert. Stanley Black & Decker besitzt Stanley und DeWalt — die beiden
Protokolle könnten verwandt sein, ist aber nicht bestätigt. UUIDs unbekannt.

**Quellen:** stanleytools.global / dewalt.com Produktseiten; imagemeter Supported Devices.

---

## Metabo

**Status:** Unbekannt / vermutlich kein App-fähiges BLE.

Metabo führt Laser-Distanzmesser, es gibt aber keine belastbaren Hinweise auf ein Bluetooth-/App-
Ökosystem oder eine Aufnahme in Cross-Vendor-App-Listen. Kein öffentliches Protokoll; ein Adapter
ist derzeit nicht begründbar.

**Quellen:** metabo.com Laser-Distanzmesser (keine App-/BLE-Doku).

---

## Würth

**Status:** Unbekannt / nicht öffentlich dokumentiert.

Würth-Modelle **WDM 3-19, WDM 6-22, WDM 8-14, WDM 9-24** sind in der imagemeter-Geräteliste als
unterstützt geführt, besitzen also ein reales BLE-Distanzprotokoll. UUIDs/Datenformat sind nicht
öffentlich publiziert. Würth-Geräte sind häufig OEM-Rebadges; das Protokoll könnte einer generischen
OEM-Familie entsprechen, ist aber nicht bestätigt.

**Quellen:** imagemeter Supported Devices.

---

## CEM

**Status:** Unbekannt / nicht öffentlich (proprietär).

CEM (Shenzhen Everbest) **iLDM-Serie** (iLDM-150, iLDM-25, iLDM-80C, iLDM-30) sendet Messwerte per
BLE an die **Meterbox Pro / iDM**-App. imagemeter unterstützt die iLDM-Modelle und erlaubt teils,
das Protokoll manuell auf "CEM iLDM-150" zu setzen — was auf ein proprietäres, aber über mehrere
OEM-Rebadges wiederverwendetes CEM-Protokoll hindeutet. Konkrete UUIDs sind nicht publiziert.

**Quellen:** cem-instruments.de iLDM-150; Meterbox/iDM Apps; imagemeter Supported Devices.

---

## Mileseey

**Status:** Unbekannt / nicht öffentlich dokumentiert.

Mileseey ist ein großer OEM/ODM-Hersteller; viele "No-Name"- und rebadgete Distanzmesser stammen von
Mileseey. imagemeter unterstützt zahlreiche Modelle (**P7, P9, T7, DT20, R2B, M120, M130**). Es gibt
also ein reales BLE-Protokoll (bzw. mehrere Protokollgenerationen), aber keine öffentliche
GATT-Spezifikation; UUIDs unbekannt. Wegen der OEM-Verbreitung ist ein reverse-engineerter
Mileseey-Adapter potenziell der mit der breitesten Abdeckung über Fremdmarken hinweg.

**Quellen:** imagemeter Supported Devices; mileseey.net / Produktseiten.

---

## Implementierungs-Empfehlung

1. **Sofort umsetzbar mit echten UUIDs:** Leica DISTO (`3ab10100-…`) und Bosch GLM (`02a6c0d0-…`).
   Beide mit IEEE-754-Float-Decoding (Little Endian, Meter). Leica: Indicate abonnieren; Bosch:
   Start-Kommando `c0 56 01 00 1e` schreiben, dann Indication lesen.
2. **Adapter mit "unbekanntem Protokoll":** Für Stabila, Hilti, Laserliner, Würth, CEM, Mileseey,
   Stanley/DeWalt, Einhell keine erfundenen UUIDs hinterlegen. Stattdessen entweder (a) das Gerät
   erkennen und dem Nutzer sagen "Protokoll nicht implementiert", oder (b) je Hersteller ein eigenes
   BLE-Sniffing durchführen und das Ergebnis hier ergänzen.
3. **Kein Adapter nötig:** Makita, Metabo (kein App-fähiges BLE bekannt).
4. Namens-Heuristik (Advertised Name enthält "DISTO"/"GLM") bleibt sinnvoll **nur** zur Auswahl des
   passenden echten Adapters — nicht als Ersatz für das GATT-Layout.

---

## Sources

- seichter/d2relay (Leica D2 BLE readout, `doc/notes.md`): https://github.com/seichter/d2relay
- B4X-Forum — "BLE2 = Leica Disto and Bosch laser rangefinder": https://www.b4x.com/android/forum/threads/ble2-leica-disto-and-bosch-laser-rangefinder.160390/
- alexwhittemore.com — "Reverse Engineering Cheap BLE Devices" (Bosch GLM): https://www.alexwhittemore.com/reverse-engineering-cheap-ble-devices/
- ketan/Bosch-GLM50C-Rangefinder: https://github.com/ketan/Bosch-GLM50C-Rangefinder
- pklaus/bsch (Bosch Professional tools): https://github.com/pklaus/bsch
- Nordic DevZone — "Sniffing a Bosch laser tape 2": https://devzone.nordicsemi.com/f/nordic-q-a/80589/sniffing-a-bosch-laser-tape-2
- B4X-Forum — "Bosch GLM100C MT-Protocol": https://www.b4x.com/android/forum/threads/bosch-glm100c-mt-protocol-to-read-devicemeasurent-from-bosch-rangefinder-using-bluetooth.160495/
- imagemeter — Supported Bluetooth Devices: https://imagemeter.com/manual/bluetooth/devices/
- magicplan — Laser distance meters help: https://help.magicplan.app/laser-distance-meters
- Leica DISTO Bluetooth Compatibility: https://shop.leica-geosystems.com/measurement-tools/disto/blog/bluetoothr-disto-os-compatibility
- Bosch Professional — Messtechnik/Konnektivität: https://www.bosch-professional.com/static/specials/mt/za/en/konnektivitaet.html
- Laserliner MeasureNote: https://www.laserliner.com/en/measurenote
- Stabila LD 250 BT: https://www.stabila.com/en/products/details/ld-250-bt-laser-distance-measurer-with-bluetooth-smart-4-0.html
- Stabila LD 530 BT (press release): https://www.stabila.com/en/service/press-releases/09-2025-ld-530-bt-laser-distance-measurer-from-stabila-high-performance-distance-measurement-indoors-and-outdoors.html
- Hilti PD-I Laser meter: https://www.hilti.com/c/CLS_MEA_TOOL_INSERT_7127/CLS_LASER_METERS_7127/r9121031
- Makita LD080P: https://makitatools.com/products/details/LD080P
- Stanley FatMax Bluetooth (TLM): https://cee.stanleytools.global/product/stht1-77140/stanley-fatmax-100m-laser-distance-measurer-bluetooth-connectivity
- DeWalt DW0330SN Bluetooth Laser Measure: https://www.dewalt.com/en-us/product/dw0330sn/330-ft-100m-bluetooth-laser-measure-tooldistance-meter
- Metabo Laser distance meters: https://www.metabo.com/com/en/products/tools/others/measuring-technology/laser-distance-meters
- CEM iLDM-150: https://cem-instruments.de/product/ldm150-ldm/
- Einhell Measuring tools: https://www.einhell.de/en/tools/power-tools/measuring-tools/
- Mileseey (Golf/Optics): https://www.mileseey.net/
