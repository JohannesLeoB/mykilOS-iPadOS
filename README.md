# mykilOS iPadOS

Native iPadOS-App für MYKILOS GmbH (Hamburg) — Schwester-App zu `mykilOS-macOS` und
`myMini` (mykilOS iOS). Fokus: ein maximal ausgebauter **Aufmaß-Modus** mit
Apple-Pencil-Bedienung, Bluetooth-Laser-Entfernungsmessern und optionalem
LiDAR-Raumscan (iPad Pro).

Siehe `KOORDINATEN.md` für die Repo-/Ordner-Zuordnung im mykilOS-Ökosystem und
`WORK_STATUS.md` für den ehrlichen aktuellen Baustand (was läuft echt vs. was nur
compiliert).

## Bauen

```bash
xcodegen generate
open mykilOSiPad.xcodeproj
```

oder per CLI:

```bash
xcodegen generate
xcodebuild -project mykilOSiPad.xcodeproj -scheme mykilOSiPad \
  -destination "platform=iOS Simulator,name=iPad Pro 13-inch (M5)" build
xcodebuild test -project mykilOSiPad.xcodeproj -scheme mykilOSiPad \
  -destination "platform=iOS Simulator,name=iPad Pro 13-inch (M5)"
```

`project.yml` ist die Quelle der Wahrheit — `mykilOSiPad.xcodeproj` wird generiert
und ist mit eingecheckt (Komfort), aber nach jeder `project.yml`-Änderung neu zu
generieren.

**Xcodegen-Eigenheit (Stand xcodegen 2.45.4):** Der Top-Level-Key `resources:`
wird für dieses Target ignoriert (keine Fehlermeldung, aber leer). Ressourcen
(hier: Fonts) müssen stattdessen über `sources:` mit `buildPhase: resources`
eingebunden werden — siehe `project.yml`.

## Module (Stand siehe `WORK_STATUS.md`)

- **Grundriss-Editor** — manuelles 2D-Wände-Zeichnen, geräteunabhängig
- **Foto-Bemaßung** — Maß/Notiz/Symbol/Winkel/Pencil-Freihand auf einem Foto
- **RoomPlan-Aufmaß** — LiDAR-Raumscan (nur iPad Pro), PDF-/DXF-Grundrissexport
- **Bluetooth-Laser** — Registry für ~12 Hersteller, echtes Protokoll bisher nur
  für Leica DISTO verifiziert (siehe `docs/LASER_PROTOKOLL_RECHERCHE.md`, sobald
  fertig)
