# Changelog

## [1.3.1] – 2026-11-05
### Neu
- **Alle Geräte**: Oberfläche passt sich an Handy (iOS/Android), Tablet, PC und Konsole (Xbox/PlayStation) an
  und wechselt live, wenn die Steuerung wechselt (`UI/Device.lua`)
  - alles bleibt im sicheren Bereich (Notch, Roblox-Leiste), Fenster und HUD skalieren mit der Bildschirmgröße,
    auf dem Fernseher größer
  - Menü-Leiste nimmt nur so viele Knöpfe, wie Platz ist, der Rest steckt im neuen **☰-Menü** (große Kacheln)
  - Controller: Y/△ = Menü, B/○ = zurück, Steuerkreuz/Stick = auswählen, Auswahlrahmen,
    Tasten-Symbole passend zu Xbox oder PlayStation an den Fähigkeiten
  - PC: Taste M = Menü
  - Werkstatt-Insel mit Controller bebaubar (Zielkreuz, X/□ = bauen, LT/L2 = drehen)
### Behoben
- Rotstich im ganzen Spiel (Bau-Vorschau ohne Ziel färbte alles ein), doppelte Licht-Effekte aus der Studio-Vorlage
- Bauen in der Werkstatt startete mit einem Fehler
- HUD-Teile oben links überlappten sich bei großen Bildschirmen
- Handy: Aufgaben-Kachel wurde nicht verkleinert und lag über den Menü-Knöpfen; Anzeige oben links rutscht
  unter die Roblox-Knöpfe, falls die im Bild liegen; Skill-Leiste auch auf dem Handy unten in der Mitte
- Handy: Zonen-Name sitzt in der freien Fläche der Roblox-Leiste oben (verdeckt nichts mehr vom Spiel)
### Geändert
- Die Hub-Insel heißt jetzt „Uhrturm-Platz“ (alle Texte, Schilder, Karte)

## [1.3.0] – 2026-11-05
### Neu
- **Zone 6 „Sternen-Sternwarte“ und Zone 7 „Versunkenes Uhrwerk“** – je 3 Strecken, 3 Gegner-Arten, Boss
  (Komet-Kasimir, Kapitän Ankerzahn), Ei mit 5 Pets, 6 Herausforderungen, Co-op-Rätsel, eigene Musik
- **Pet-Fusion** (`Pets.lua` → `Fusion`): 3 gleiche Pets → ✨ Gold (×3,5 Bonus) → 🌈 Regenbogen (×12 Bonus)
- **Schönere Pets**: Füßchen, Bäckchen, Aufziehschlüssel, Ohren, Antenne, Zahnrad-Zähne; Flügel (episch),
  Krone (legendär), Gold-Glanz und Regenbogen-Farben nach der Fusion
- **Zeit-Medaillen** 🥉🥈🥇 für jede Bahn (Richtzeit aus Länge + Hindernissen), Extra-Belohnung pro Medaille,
  Anzeige im Ergebnis, auf der Karte und in der Bestenliste
- **Wochen-Events** (`Events.lua`): Doppel-Energie-Wochenende, Doppel-XP-Mittwoch, Glücks-Freitag,
  Halloween 🎃 (Kürbisse im Hub), Winter ❄️ (Schneefall), Sommerferien – Banner im HUD
- **Freunde-Bonus**: +10 % Energie pro Freund auf dem Server (max. +50 %)
- **24 Geheimnisse** (`Secrets.lua`): versteckte goldene Zahnräder im Hub und in jeder Zone, Belohnung + Meilensteine,
  Rätsel-Tipps im Erfolge-Menü
- **Endlos-Turm** 🗼 (`Tower.lua`): Etagen werden bei Bedarf gebaut, jeden Montag ein neuer Turm,
  Start auf jeder erreichten 10er-Etage, Wochen- und Rekord-Bestenliste
- **Eigene Werkstatt-Insel** 🏡 (`Deco.lua`): 24 Deko-Stücke (inkl. Boss-Pokale), Bauen im Raster, Abbauen,
  andere Werkstätten besuchen, Werkstatt-Bonus (+0,5 % Energie pro Deko, max. +25 %)
- 5 neue Aufgaben (Werkstatt, Fusion, Turm, Geheimnisse, Gold-Medaille) + 4 für die neuen Zonen, 10 neue Abzeichen
- **Grafik**: Terrain-Felsen unter allen Inseln, riesige Uhren und Zahnräder im Hintergrund jeder Zone,
  Zonen-Kulissen (Riesen-Blumen, Schornsteine mit Dampf, Felsnadeln mit Riesen-Pendel, Kristalltürme,
  Planeten, Seetang mit Blasen), Funken an Zahnrädern, Konfetti-Regen + Feuerwerk beim Boss-Sieg
- Hub: 7 Teleporter im Halbkreis, Stationen „Endlos-Turm“ und „Meine Werkstatt“, Karte mit Schnellzugang
### Geändert
- Abzeichen „Alle …“ zählen jetzt 7 Zonen (21 Profi-Bahnen, 16 Co-op-Rätsel, 42 Herausforderungen)
- Profil um `Medals`, `Secrets`, `Tower`, `Island`, `Stats.Fused` erweitert (alte Spielstände werden automatisch ergänzt)
- ⚠️ Welt neu bauen nötig (Command Bar), dabei wird das Terrain neu erzeugt

## [1.2.1] – 2026-11-05
### Neu
- Hintergrundmusik für Hub, alle 5 Zonen und den Bosskampf (APM Music, Creator Store)
### Behoben
- Die meisten Soundeffekte waren stumm: `electronicpingshort.wav` und `clickfast.wav` gibt es in Roblox nicht mehr.
  Alle Töne haben jetzt eigene, getestete Creator-Store-IDs.

## [1.2.0] – 2026-11-05
### Neu
- Tagesbonus mit 7-Tage-Serie (`Daily.lua`), automatisch beim Beitreten, roter Punkt im HUD
- 30 Zonen-Herausforderungen (`Challenges.lua`), z. B. „alle 3 Strecken auf Profi“
- 27 Sammel-Abzeichen (`Badges.lua`), optional als echte Roblox-Badges
- 5 neue Gegner-Arten, neue Muster „Flieger“ (Sturzflug) und „Schütze“ (Zahnrad-Wurf) – beide mit Warnfläche
- Mehrere Gegner-Arten pro Zone, neue Gegner-Formen (Drohne, Turm)
- Grafik: Stimmung pro Zone (Tageszeit, Nebel, Farbtönung), Glühwürmchen, Blumen/Felsen/Büsche/Pilze,
  Wolken unter den Inseln, schwebende Mini-Inseln
- Menü 🏅 Erfolge (Herausforderungen + Abzeichen), Admin-Befehl „Bonus zurücksetzen“

## [1.1.0] – 2026-11-05
### Neu
- Aufgaben-Kette (23 Aufgaben in `Quests.lua`) führt vom ersten Schritt bis zum Endboss und Rebirth
- Aufgaben-Anzeige im HUD mit Fortschritt und Entfernung, Aufgaben-Fenster mit Tipp und Belohnung
- Goldener Wegweiser (Leuchtstrahl + hüpfender Pfeil), führt auch über Teleporter/Portale in andere Zonen
- Willkommens-Einführung nach der Klassenwahl (jederzeit erneut über 📜)
- Regelmäßige Tipps, Zonen-Beschreibung beim Betreten
### Geändert
- Profil um `Quest` und `Settings.IntroSeen` erweitert (alte Spielstände werden automatisch ergänzt)

## [1.0.0] – 2026-11-04
### Neu
- Rojo-Projekt mit Services/Controller-Muster (ein Server-Script, ein Client-Script)
- Konfig-Dateien mit deutschen Kommentaren: Zonen, Pets, Gegner, Bosse, Upgrades, Klassen, Skills, Schwierigkeit, Assets, Settings
- WorldBuilder: baut Hub-Insel und alle 5 Zonen deterministisch aus der Konfig (auch per Command Bar)
- 11 Hindernis-Bausteine (Sprung, Drehzahnrad + Kehrbalken, Pendel, Förderband, Gleit-/Fährplattform, Zeitplattform,
  Wackelplatte, Laser-Takt, Sprungpad, Funkenboden/Killzone, Drehringe), synchron über `GetServerTimeNow()`
- 15 Strecken × 3 Bahnen (Leicht/Normal/Profi) mit Checkpoints, Streckenzeit, Bestzeit pro Schwierigkeit, Belohnungen
- Simulator: Kristalle, Energie-Felder, Energie-Kugeln, Doppel-Energie-Boosts, 6 Upgrades, Rebirth mit Rebirth-Ei
- 28 Pets in 6 Eiern, 4 Seltenheiten, Ausrüsten/Ablegen/Umbenennen (vorgefertigte Namen)/Freilassen
- RPG: Level/XP, 3 Klassen, Skill-Baum (3 Äste × 4 Knoten pro Klasse), Rost-Bots mit KI, 5 Bosse mit 3 Phasen
- Zeit-Fähigkeiten: Verlangsamen (serverseitige Zeitblase), Zurückspulen (Server-Positionsverlauf), Sprint, Zeit-Wurf, Hilfsplattform
- Co-op: Doppeltür, Gleichzeitig-Brücke, Zeit-Konsole mit Team-Belohnung; Einladen über SocialService
- DataStore-Modul: Session-Lock, Wiederholversuche, Autosave, BindToClose, Schema-Version 2 mit Migration
- Bestenlisten (OrderedDataStore), Admin-Befehle, Schnellnachrichten statt freiem Chat
- Komplette UI per Code: HUD, Skill-Leiste mit Abklingkreisen, 11 Menüs, Toasts, Handy-/Tablet-Layout
