# Marktvergleich Aufmaß-Apps (Stand 2026-07-06)

Quelle für die Ausgangsliste: [cendas.net – Aufmaß App: Die 10 besten Apps fürs Handwerk](https://www.cendas.net/blog/aufmass-app/).
Vertieft recherchiert: magicplan, Bosch MeasureOn, Leica DISTO Plan, STABILA Measures II,
CATSmobil 3D, hand:werk (tophandwerk).

## Verglichene Apps

| App | Hersteller/Anbieter | Kernidee |
|---|---|---|
| [magicplan](https://apps.apple.com/de/app/magicplan/id427424432) | Sensopia | Grundriss per Kamera/AR, 360°, Kostenvoranschläge |
| [Bosch MeasureOn](https://www.bosch-professional.com/de/de/measureon/) | Bosch | Grundrissskizze + BLE-Übernahme von Bosch-GLM-C-Geräten |
| [Leica DISTO Plan](https://shop.leica-geosystems.com/measurement-tools/disto/leica-disto-plan-app) | Leica Geosystems | Sketch Plan, Smart Room, P2P, Skizze-auf-Foto, DXF/DWG-Export |
| [STABILA Measures II](https://www.stabila.com/de/produkte/details/aufmass-app-stabila-measures-ii.html) | STABILA | Smart Sketch, Freihand+Lupe+Magnet+Raster, Fernauslösung |
| [CATSmobil 3D](https://www.malersoftware.net/catsmobil-3d-das-mobile-erfassungssystem/) | C.A.T.S.-Soft | „Autopilot fürs Aufmaß", 3D-Raumplan, Zielgruppe Maler/Stuckateure |
| [hand:werk](https://meister.software/app-handwerk-jetzt-mit-aufmass/) | tophandwerk/meister.software | Raumbuch, Skizze je Raum mit Tür/Fenster/Säule/Abzugsflächen, Anbindung ans Büro-System |

Nicht vertieft (nur in der Ausgangsliste): Würth WDM, ViSoft Smart, Mobilaufmaß Free, SimpleMeasure, Solaflex.

## Gemeinsamer Funktionskern (über alle Apps hinweg)

Sortiert nach Häufigkeit/Zentralität:

1. **Manuelle 2D-Grundriss-/Raumskizze** (Wände zeichnen, Türen/Fenster/Säulen als Elemente
   platzieren, Aussparungen) — bei ALLEN untersuchten Apps die zentrale, geräteunabhängige
   Kernfunktion (funktioniert auf jedem Gerät, kein LiDAR nötig).
2. **Bluetooth-Laser-Kopplung** zur direkten Maßübernahme in die Skizze (Bosch GLM C, STABILA
   LD 530 BT, Leica DISTO) — deckt sich mit unserer bereits gebauten `BluetoothLaserScanner`/
   `LaserAdapter`-Registry.
3. **Automatische Flächen-/Umfangsberechnung** (Boden, Wand, Decke) aus der Skizze.
4. **Foto-Dokumentation mit Notizen** — deckt sich mit unserem bereits portierten
   `Aufmass`-Modell (Foto + Annotationen).
5. **Projekt-/Raumverwaltung** (mehrere Räume je Projekt, Suche/Sortierung).
6. **Export**: PDF (alle), DXF/DWG (Leica, für CAD-Weiterverarbeitung — deckt sich mit unserem
   `GrundrissDXFExporter`), teils XLS/JPEG (Bosch).
7. **Freihand-Zeichnen mit Präzisions-Hilfen**: Lupe beim Punktsetzen, Magnet-Fang an
   Linien/Ecken, Rasteranzeige (STABILA) — deckt sich mit der Lupen-Funktion aus
   `FotoBemassungView`, sollte aber auch im neuen Grundriss-Editor gelten.
8. **3D-/LiDAR-Raumscan** (magicplan, CATSmobil-Autopilot, unser RoomPlan-Port) — fortgeschrittene
   Zusatzstufe, nur auf LiDAR-Geräten (iPad Pro) — kein Ersatz für die manuelle Skizze, sondern
   Ergänzung.
9. **Anbindung ans Büro-/Projektsystem** (hand:werk→tophandwerk, Bosch-Cloud, CATSmobil→Büro-
   Software) — für mykilOS die Anbindung an die eigene Projekte-Ebene (perspektivisch weclapp,
   siehe `mykilos-core`-Architektur).
10. **Digitale Unterschrift/Abnahme** (aus dem vom Nutzer beigefügten Referenzbild) — bei den
    tief recherchierten Apps nicht zentral, aber ein verbreitetes Feature in umfassenderen
    Aufmaß-/Abnahme-Suiten.

## Lücke in unserer bisherigen Planung

Unsere bisherige Architektur deckt **Foto-Bemaßung** (FotoBemassungView-Port) und **LiDAR-
Raumscan** (RoomPlan-Port) ab — beides sind bei den Wettbewerbern eher Zusatz-/Nischenmodi.
Der **eine Modus, den praktisch jede Wettbewerber-App als Kern anbietet und wir noch nicht
geplant hatten, ist ein manueller 2D-Grundriss-Editor**: von Grund auf Wände zeichnen (nicht an
ein Foto gebunden), Tür-/Fenster-/Säulen-Elemente platzieren, direkt mit Bluetooth-Laserwert
oder Apple Pencil bemaßen — funktioniert auf JEDEM iPad, nicht nur LiDAR-Modellen.

→ Neue Aufgabe: **Grundriss-Editor** (Wände/Bauelemente/Formen/Text, Raster+Magnet+Lupe,
Bluetooth-Laser- und Pencil-Eingabe) als eigenständiger dritter Aufmaß-Teilmodus neben
Foto-Bemaßung und RoomPlan-Scan. Layout-Inspiration aus den Referenzbildern (Werkzeugleiste
Neu/Raster/Rückgängig/Messen, Wände/Bauelement/Formen/Text), visuell aber strikt in mykilOS-CI
(monochrom, Paper/Ink/Brand-Orange, Quadrat-Ecken, 0.5px-Hairlines, nummerierte Sektionen —
keine bunten Wettbewerber-Farben wie Blau/Rot/Grün für Wände/Türen/Fenster).

Sources:
- [Aufmaß App: Die 10 besten Apps fürs Handwerk im Vergleich (cendas)](https://www.cendas.net/blog/aufmass-app/)
- [magicplan – App Store](https://apps.apple.com/de/app/magicplan/id427424432)
- [Bosch MeasureOn](https://www.bosch-professional.com/de/de/measureon/)
- [Leica DISTO Plan App](https://shop.leica-geosystems.com/measurement-tools/disto/leica-disto-plan-app)
- [Aufmaß-App STABILA Measures II](https://www.stabila.com/de/produkte/details/aufmass-app-stabila-measures-ii.html)
- [CATSmobil 3D](https://www.malersoftware.net/catsmobil-3d-das-mobile-erfassungssystem/)
- [hand:werk App mit neuer Aufmaß-Funktion](https://meister.software/app-handwerk-jetzt-mit-aufmass/)
