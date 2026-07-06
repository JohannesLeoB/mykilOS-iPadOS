# Arbeitsstand — ehrlich, nicht schöngeredet

**Stand: 2026-07-07, Nachtsession.** Diese Datei sagt, was WIRKLICH läuft (im
Simulator gebaut/gestartet/getestet) vs. was nur compiliert vs. was noch fehlt.
"Fertig" heißt hier nie mehr als "Build grün + Simulator-Screenshot" — echte
Geräte-Verifikation (Bluetooth, Kamera, RoomPlan/LiDAR, Apple Pencil) steht noch
komplett aus, weil der Simulator das nicht kann.

## Was echt verifiziert ist

- **Build**: `xcodebuild build` gegen iPad Pro 13" (M5) Simulator, Swift 6 strict
  concurrency, 0 Warnings/Errors.
- **Tests**: 18 Unit-Tests (Geometrie-Fang, Aufmaß-Modell-Logik,
  Leica-Protokoll-Parsing), alle grün — reine Logik, kein UI/Hardware.
- **App startet im Simulator**: Navigation (Sidebar mit allen vier Modulen),
  mykilOS-CI-Farben und die echte ABC-Monument-Grotesk-Schrift wurden per
  Screenshot bestätigt (Font-Datei im App-Bundle nachgewiesen, nicht nur
  angenommen).

## Was NUR compiliert, aber nicht am Gerät getestet ist

- **Bluetooth-Laser** (`BluetoothLaserScanner`, `LaserAdapter`-Registry,
  `LeicaDistoProtokoll`): Simulator hat kein CoreBluetooth-Radio — ungetestet
  mit echter Hardware. Nur Leica DISTO hat ein echtes, doppelt bestätigtes
  Protokoll; 11 weitere Hersteller sind nur Namens-Heuristik (siehe
  `Sources/mykilOSiPad/Bluetooth/LaserAdapter.swift`, Kommentare).
- **Kamera** (`KameraAufnahmeView`): Simulator hat keine echte Kamera —
  ungetestet.
- **RoomPlan/LiDAR**: Simulator kann keinen LiDAR-Scan — komplett ungetestet.
  Die Geometrie-Extraktion (`RaumGeometrieExtractor`) ist laut eigenem
  Kommentar "mathematisch plausibel, nicht live verifiziert" (Erbe aus
  mykilOS iOS, dort ebenfalls nie an echtem Scan geprüft).
- **Apple Pencil / PencilKit** (`PKCanvasRepresentable`, Freihand-Werkzeug in
  `FotoBemassungView`): Simulator kann Pencil nicht emulieren (nur
  Finger-/Maus-Zeichnen) — Druckempfindlichkeit, Palm-Rejection, Neigung
  ungetestet.
- **Grundriss-Editor**: Gesten (Ziehen/Zoom/Rückgängig) nur im Simulator per
  Maus/Touch-Emulation geprüft, nicht am echten Multi-Touch-Display.

## Bekannte Lücken / bewusst nicht gebaut

- **Keine Projekt-/Kundenverwaltung.** Alle Module (Aufmaß, RoomPlan, Grundriss)
  haben nur lose, freie Text-Zuordnung (Projekt/Raum), keine Anbindung an eine
  Projektdatenbank — die gibt es für die iPad-App noch nicht (bewusste
  Entscheidung, um nicht vorzeitig eine ganze Projektverwaltung nachzubauen,
  bevor geklärt ist, ob/wie die iPad-App an weclapp/mykilOS-Ökosystem andockt).
- **Kein App-Icon.**
- **Kein Cloud-Sync / Mehrgeräte-Abgleich** — alles lokal in `Documents/`
  (JSON-Manifeste + Bilddateien), gleiches Muster wie mykilOS iOS.
- **Laser-Hersteller-Recherche** (Bosch, Einhell, Laserliner, Stanley, Worx
  etc. — echte BLE-GATT-Protokolle statt nur Namens-Erkennung): lief als
  Hintergrund-Recherche, Ergebnis in `docs/LASER_PROTOKOLL_RECHERCHE.md`
  sobald fertig.
- **Grundriss-Editor "Formen"-Werkzeug**: bisher nur Schnell-Rechteck
  (4 Wände aus einer Diagonalen), keine Freihand-Formen — bewusst minimal
  gehalten, um kein halbfertiges Formen-System zu bauen.

## Nächste sinnvolle Schritte

1. Laser-Protokoll-Recherche abwarten und Ergebnis einarbeiten (Registry ggf.
   um echte UUIDs für weitere Hersteller ergänzen, mit derselben
   "kein Raten"-Doktrin wie beim Leica-Protokoll).
2. Echte Geräte-Session: Bluetooth-Kopplung mit einem echten Lasermessgerät,
   RoomPlan-Scan auf einem LiDAR-iPad, Apple-Pencil-Test.
3. App-Icon + Launch-Screen-Feinschliff.
4. Entscheiden, ob/wie Projekt-Zuordnung an eine echte Datenquelle (weclapp?
   lokale Projektliste wie in mykilOS iOS?) angebunden wird.
