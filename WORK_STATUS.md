# Arbeitsstand — ehrlich, nicht schöngeredet

**Stand: 2026-07-07, ~01:00 Uhr, Session-Ende (Rate-Limit-Handoff).**

## Kontext dieser Session

Johannes' Kritik am ersten Durchgang (wörtlich): "noch lange nicht auch nur einen
Hauch so gut wie die iOS App... weder CI noch UX noch irgendwas beachtet, einfach
kopierten Müll gebaut". Daraufhin wurde die Architektur neu aufgesetzt: echte
mykilOS-IA (Sidebar/Breadcrumb statt Platzhalter-Liste), echte Projekt-Registry
statt Freitext-Feldern, und ein systematischer Anlauf, **alle** ~113 Swift-Dateien
aus mykilOS iOS (`myMini`) zu portieren, nicht nur den Aufmaß-Ausschnitt.
Siehe Memory `feedback_full-parity-real-ux` — UNBEDINGT vor Weiterarbeit lesen.

## Was echt verifiziert ist (Build grün + Simulator-Screenshot)

- Xcode-Projekt (xcodegen, iPadOS 17+, Swift 6 strict concurrency)
- Echte mykilOS-CI: ABC-Monument-Grotesk-Schrift, Farbtokens, offizielles
  App-Icon (M-Wortzeichen)
- **AppShell**: NavigationSplitView, schwarze Sidebar, nummerierte Sektionen
  (01 Heute, 02 Fang, 03 Projekte, 04 Aufmaß, 05 Verbindungen), Breadcrumb
  "MYKILOS / MODUL"
- **Projekt-Registry**: echte 31 Kundenprojekte aus `projekte.json`,
  ProjectListView/ProjectDetailView, Aufmaß/RoomPlan/Grundriss sind jetzt an
  echte Projektwahl gekoppelt (nicht mehr Freitext)
- **Grundriss-Editor**: manuelles 2D-Wände-Zeichnen (Raster/Magnet-Fang,
  Bauelemente, Formen, Text, Rückgängig, PDF/DXF-Export)
- **Foto-Bemaßung**: Zoom/Pan/Lupe, Maß/Notiz/Symbol/Winkel + neues
  Apple-Pencil-Freihand-Werkzeug (PencilKit)
- **RoomPlan/LiDAR-Aufmaß**: Scan, PDF/DXF-Grundrissexport
- **Bluetooth-Laser-Registry**: 12 Hersteller, nur Leica DISTO echt
  verifiziert (siehe `Sources/mykilOSiPad/Bluetooth/LaserAdapter.swift`)
- **Fang-Workflow (NEU diese Session)**: PostboxStore/-View, FeldFotoStore/
  -ListView/-BestaetigungView, FangCard (Text-Fang + Feld-Foto-Kamera),
  EinmaligerOrtsSensor — ohne Sprachaufnahme/OCR (siehe unten)
- 18 Unit-Tests grün (reine Logik: Geometrie, Aufmaß-Modell, Leica-Protokoll)

**Letzter git-Commit**: `e36f5a4` "Postbox + FeldFoto-Fang-Workflow portiert
(Task #15)", gepusht auf `main` @ github.com/JohannesLeoB/mykilOS-iPadOS.
Build war zu diesem Stand grün (vor dem Commit verifiziert).

## Was NUR compiliert, nicht am Gerät getestet (Simulator kann's nicht)

Bluetooth-Kopplung, Kamera, RoomPlan/LiDAR, Apple Pencil (Druck/Neigung/
Palm-Rejection), Multi-Touch-Gesten am echten Display, GPS/CoreLocation.

## Was noch komplett fehlt — die verbleibenden ~90 der 113 mykilOS-iOS-Dateien

Siehe TaskList (Tool `TaskList` bzw. die Aufgaben #16-19 unten), in
Prioritätsreihenfolge:

1. **Werkzeuge-Sammlung** (Task #16): WasserwaageView/-Sensor (Gyroskop-
   Wasserwaage), Beleuchtungs-/Farbtemperatur-/Raumakustik-Check (schnelle
   Sensor-Checks, alle on-device, keine externen Abhängigkeiten),
   ARMassbandMesser/-Bridge/-Screen (einfaches AR-Maßband via ARKit),
   BarcodeScannerBridge/-Screen/-LogView (VisionKit Live-Barcode),
   WareneingangsLogStore/-ListView. Alle Dateien liegen in
   `/Users/johannesleoberger/Claude/Projects/myMini/mykilos-mobile/myMini/mykilOS-mobile-KOMPLETT/`
   (READ-ONLY, fremdes Repo — siehe KOORDINATEN.md) und sind meist
   selbstständig portierbar (keine Cloud-Credentials nötig).
2. **Abnahmeprotokoll + Vertragssignatur** (Task #17): AbnahmeprotokollView/
   -Store/-PDFRenderer (Diktat-Mängelaufnahme — braucht
   SpracheZuTextService, on-device Speech-Framework, kein Cloud-Call),
   VertragSignierenView/VertragsSignatur (PencilKit-Unterschrift — direkt an
   unser bestehendes `PKCanvasRepresentable`-Muster anschließbar).
3. **Service-Anfrage + Kontakte** (Task #18): ServiceAnfrageView/-Kern,
   KontakteVerzeichnisView/-Store/KundenKontakt, KontaktSchreiber — die
   Kontakte-Anbindung braucht Airtable-Credentials (noch nicht portiert),
   kann aber mit leerer/lokaler Liste starten.
4. **OCR-Fang-Flows + AR-Anker** (Task #19): LieferscheinOCR/
   -BestaetigungView, VisitenkartenOCR/-BestaetigungView (beide Vision-
   Framework, on-device), ARAnkerScreen/-Bridge/GewerkeTyp.

**Bewusst zurückgestellt** (brauchen externe Credentials/OAuth, die
Johannes erst einrichten müsste): Google-Drive-Upload (GoogleDriveUploadClient,
GoogleOAuthPKCEService, GoogleSignInSettingsView, GoogleCredentialsStore),
Airtable-Postbox-Sync (AirtableClockodoPostboxClient, AirtablePostboxSettingsView,
AirtableKundenClient), Claude-Assistent-Chat (ClaudeMessagesClient,
AssistantChatView, ClaudeSettingsView), Geofencing/Standort-Wächter
(GeofenceWaechter, StandortAufenthalt-System — bewusst niedrige Priorität,
iPad wird seltener am Körper getragen als iPhone).

**Laser-Hersteller-Recherche**: Ein Hintergrund-Agent sollte
`docs/LASER_PROTOKOLL_RECHERCHE.md` befüllen (echte BLE-GATT-Protokolle für
Bosch/Einhell/Laserliner/etc. statt nur Namens-Heuristik) — bei Session-Ende
war die Datei noch NICHT entstanden. Zwei Versuche liefen, keiner hat
sichtbar ein Ergebnis geschrieben. In der nächsten Session prüfen und ggf.
neu anstoßen (Prompt-Vorlage siehe unten im Handoff).

## Wichtige Lektionen aus dieser Session

- **xcodegen 2.45.4-Eigenheit**: `resources:` als Top-Level-Key wird für das
  App-Target komplett ignoriert (kein Fehler, einfach leer). Fix: Ressourcen
  über `sources:` mit `buildPhase: resources` einbinden (siehe `project.yml`).
- **GraphicsContext.draw() + Image**: `.font()`/`.foregroundColor()` auf
  `Image` geben KEIN konkretes `Image` zurück (anders als bei `Text`) —
  `context.draw(_:at:)` erwartet aber exakt `Image`. Lösung: entweder ohne
  Modifier zeichnen oder `context.draw(_:in: CGRect)` mit vorbestimmter
  Größe nutzen.
- **CoreBluetooth/RoomPlan-Delegates + Swift 6 strict concurrency**: `class`
  ist `@MainActor`, Delegate-Protokoll ist es nicht → Konformanz mit
  `@preconcurrency` markieren (`@preconcurrency CBCentralManagerDelegate`
  etc.), NICHT die iOS-Vorlage kopieren, die stattdessen `nonisolated` +
  `Task { @MainActor in }`-Hopping nutzt (erzeugt Sendable-Warnings bei
  `CBPeripheral`).
- **Simulator-Flakiness**: `xcrun simctl install/boot` hängt gelegentlich
  minutenlang oder schlägt mit obskuren Fehlern fehl. Fix: `killall -9
  Simulator com.apple.CoreSimulator.CoreSimulatorService`, dann neu booten.
- **Guard-Hook-Selbstschutz**: Das automatische Anlegen von
  PreToolUse-Permission-Hooks (`.claude/guard-ipados.sh`, das eigene
  Tool-Rechte einschränkt) wurde vom Auto-Mode-Classifier blockiert — zu
  Recht, das ist Selbst-Modifikation der eigenen Befugnisse. Nur mit
  explizitem Nutzer-Go anlegen.
