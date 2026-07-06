# Arbeitsstand — ehrlich, nicht schöngeredet

**Stand: 2026-07-07, ~01:50 Uhr (Nacht-Session, autonom).**

## Kontext

Johannes' Kritik am ersten Durchgang (wörtlich): "noch lange nicht auch nur einen
Hauch so gut wie die iOS App... weder CI noch UX noch irgendwas beachtet, einfach
kopierten Müll gebaut". Daraufhin wurde die Architektur neu aufgesetzt: echte
mykilOS-IA (Sidebar/Breadcrumb statt Platzhalter-Liste), echte Projekt-Registry
statt Freitext-Feldern, und ein systematischer Anlauf, **alle** ~113 Swift-Dateien
aus mykilOS iOS (`myMini`) zu portieren, nicht nur den Aufmaß-Ausschnitt.
Siehe Memory `feedback_full-parity-real-ux` — UNBEDINGT vor Weiterarbeit lesen.

In der Nacht-Session vom 07.07. wurden die verbliebenen portierbaren Tasks
#16–#19 komplett abgearbeitet (siehe unten). Alles baut grün, 34 Unit-Tests grün,
App startet im Simulator (Screenshot verifiziert).

## Was echt verifiziert ist (Build grün + Simulator-Launch)

- Xcode-Projekt (xcodegen, iPadOS 17+, Swift 6 strict concurrency)
- Echte mykilOS-CI: ABC-Monument-Grotesk-Schrift, Farbtokens, App-Icon (M-Wortzeichen)
- **AppShell**: NavigationSplitView, schwarze Sidebar, jetzt sechs nummerierte
  Sektionen (01 Heute, 02 Fang, 03 Projekte, 04 Aufmaß, **05 Werkzeuge**,
  06 Verbindungen), Breadcrumb "MYKILOS / MODUL". Simulator-Launch bestätigt.
- **Projekt-Registry**: 31 echte Kundenprojekte aus `projekte.json`
- **Aufmaß-Kette**: Grundriss-Editor, Foto-Bemaßung (+ Pencil), RoomPlan/LiDAR,
  Bluetooth-Laser-Registry (nur Leica DISTO echt verifiziert)
- **Fang-Workflow**: Postbox, FeldFoto, FangCard, EinmaligerOrtsSensor

### NEU in dieser Nacht-Session — Tasks #16–#19 (alle grün)

- **Task #16 — Werkzeuge-Sammlung** (`Sources/.../Werkzeuge/`): Wasserwaage
  (CoreMotion), Beleuchtungs-/Farbtemperatur-Check (CoreImage), Raumakustik-Check
  (AVAudioRecorder), Barcode/QR-Scanner (VisionKit + neustart-fester Log),
  AR-Maßband (ARKit/SceneKit), Wareneingangs-Log.
- **Task #17 — Abnahmeprotokoll + Vertragssignatur** (`Abnahme/`, `Vertrag/`,
  `Sprache/`): on-device Diktat (Speech), Mangel-Protokoll + A4-PDF-Export;
  PencilKit-Unterschrift + SHA-256-versiegeltes PDF + nicht-löschbares Register.
- **Task #18 — Service-Anfrage + Kontakte** (`Service/`, `Kontakte/`): geführte
  Service-Mail (MFMailCompose, Fotos als Anhang), Partner-/Anfrage-Log;
  Kontakte-Verzeichnis (anrufen/mailen/Route). Airtable-Sync bewusst NICHT
  portiert → `KontakteStore` ehrlich cache-only (siehe unten).
- **Task #19 — OCR-Fang + AR-Anker** (`Fang/`, `ARAnker/`): Vision-OCR für
  Lieferschein (→ Wareneingang) und Visitenkarte (→ Contacts), beide mit
  Karte→Bestätigung; AR-Gewerke-Marker (Wasser/Strom/Abfluss) → FeldFoto.
- **Info.plist**: NSMicrophone-, NSSpeechRecognition-, NSContactsUsageDescription
  ergänzt (Mikrofon-Key fehlte auch dem Raumakustik-Check → retroaktiv gefixt).
- **Laser-Recherche**: `docs/LASER_PROTOKOLL_RECHERCHE.md` jetzt vorhanden
  (Leica + Bosch real dokumentiert, Rest ehrlich als undokumentiert markiert).
- **Tests**: 18 → **34** grün (neu: ARMassbandMesser, vier Store-Persistenz-
  Round-Trips, GewerkeTyp).

**Letzte git-Commits** (lokal auf `main`, NOCH NICHT gepusht — siehe unten):
`9ec111f` Tests, `e3d556c` Task #19, `e3cc7d8` #18, `bd07c57` #17, `63028a0` #16 …

## ⚠️ Push nach `origin main` steht noch aus

Der direkte Push auf `main` wurde in der autonomen Session vom Auto-Mode-
Classifier blockiert (Schutz gegen Direkt-Push auf den Default-Branch ohne
PR-Review). Alle Arbeit liegt als saubere lokale Commits vor. **Johannes muss
`git push origin main` selbst auslösen** (oder einen Branch + PR anlegen). Der
Pre-Push-Hook (`scripts/guard-pre-push.sh`) schützt weiterhin das Ziel-Repo.

## Was NUR compiliert, nicht am Gerät getestet (Simulator kann's nicht)

Bluetooth-Kopplung, Kamera, RoomPlan/LiDAR, ARKit (AR-Maßband, AR-Anker —
Ebenen-Erkennung geräteabhängig), Apple Pencil (Druck/Neigung), Mikrofon/
Speech-Diktat, Contacts-Schreiben, GPS/CoreLocation.

## Was jetzt noch fehlt — nur noch credential-gated Module

Die portierbare Basis ist komplett. Was übrig ist, braucht externe Zugänge, die
Johannes erst einrichten muss (bewusst zurückgestellt, siehe Memory):

- **Airtable-Sync**: `AirtableKundenClient` (Kontakte-Verzeichnis wird dann echt
  befüllt — Einhängepunkt ist `KontakteStore.aktualisieren()`, View bleibt gleich),
  `AirtableClockodoPostboxClient`, `AirtablePostboxSettingsView`.
- **Google-Drive-Upload**: `GoogleDriveUploadClient`, `GoogleOAuthPKCEService`,
  `GoogleSignInSettingsView`, `GoogleCredentialsStore`.
- **Claude-Assistent-Chat**: `ClaudeMessagesClient`, `AssistantChatView`,
  `ClaudeSettingsView`.
- **Geofencing/Standort-Wächter**: `GeofenceWaechter`, `StandortAufenthalt`-System
  (bewusst niedrige Priorität — iPad wird seltener am Körper getragen).

## Offene Politur-Ideen (nicht blockiert, optional)

- OCR-Fang (Lieferschein/Visitenkarte) sitzt aktuell im Werkzeugkasten; die
  iOS-Vorlage startet ihn aus der **Fang-Karte** — könnte dorthin verschoben/
  ergänzt werden.
- `MFMailComposeViewControllerDelegate`-Konformanz erzeugt unter strict
  concurrency einen Compiler-`note` (kein Fehler, Build grün) — könnte mit
  `@preconcurrency` sauberer markiert werden.

## Wichtige Lektionen (weiterhin gültig)

- **xcodegen 2.45.4**: Top-Level-`resources:` wird fürs App-Target ignoriert →
  Ressourcen über `sources:` mit `buildPhase: resources` einbinden.
- **SourceKit vs. xcodebuild**: Nach `xcodegen generate` zeigt der Editor kurz
  massenhaft "Cannot find … in scope" / "unavailable in macOS" — reines
  Reindex-/falsches-SDK-Rauschen. Grundwahrheit ist `xcodebuild` (baute grün).
- **Swift Testing statt XCTest**: Tests nutzen `@Test`/`#expect`. `xcodebuild
  test` meldet in der XCTest-Summenzeile "Executed 0 tests" — die echte Zahl
  steht in der Swift-Testing-Zeile ("Test run with N tests … passed").
- **Simulator-Flakiness**: `simctl` hängt gelegentlich → `killall -9 Simulator
  com.apple.CoreSimulator.CoreSimulatorService`, neu booten.
