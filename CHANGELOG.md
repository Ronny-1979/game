# Changelog

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
