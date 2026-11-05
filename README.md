# ⚙️ Uhrwerk-Insel

Ein buntes, kinderfreundliches Roblox-Spiel: Obby + Simulator + kleines RPG.
Die Welt ist ein kaputtes Uhrwerk – repariert es mit Obby-Strecken, Zeit-Energie, Pets und Zeit-Fähigkeiten.

## Schnellstart

1. **Werkzeuge installieren** (einmalig): [Rokit](https://github.com/rojo-rbx/rokit) oder Aftman installieren, dann im Projektordner:
   ```
   rokit install        # oder: aftman install
   ```
2. **Rojo-Plugin** in Roblox Studio installieren (Toolbox → Plugins → „Rojo“ oder über `.\rojo plugin install`).
3. **Server starten**:
   ```
   .\rojo serve
   ```
   ⚠️ **PowerShell:** Liegt `rojo.exe` im Projektordner, muss `.\` davor stehen (`.\rojo serve`),
   sonst kommt „nicht erkannt“. Oder einfach **`aktualisieren.bat`** doppelklicken – das startet Rojo auch.
4. In Studio eine **neue leere Baseplate** öffnen → Rojo-Plugin → **Connect**.
5. **Welt bauen** (empfohlen, damit ihr sie im Editor seht):
   Ansicht → *Command Bar* öffnen und eingeben:
   ```lua
   require(game.ServerScriptService.Server.World.WorldBuilder).Build()
   ```
   Danach speichern (Strg+S). Ohne diesen Schritt baut der Server die Welt beim Start automatisch.
6. **Spielen**: ▶ Play. Für Co-op-Tests: Test → *Clients and Servers* → 2 Spieler → *Start*.

### Updates holen (neue Versionen von GitHub)
**Einmal einrichten** (statt ZIP-Download), in PowerShell:
```
cd C:\Roblox
git clone https://github.com/Ronny-1979/game.git
```
Danach liegt das Projekt in `C:\Roblox\game` (rojo.exe wieder hineinlegen).
**Jedes Mal:** Doppelklick auf **`aktualisieren.bat`** → holt die neueste Version und startet Rojo.
In Studio dann *Plugins → Rojo → Connect*. Sind Zonen, Strecken oder Deko neu: Welt neu bauen (Schritt 5).

### Speichern im Studio aktivieren
Game Settings → Security → **Enable Studio Access to API Services** einschalten (Spiel muss veröffentlicht sein).
Ohne das läuft das Spiel im **Test-Modus** (Hinweis oben rechts) und speichert nichts.

## Ordner

| Ordner | Wird zu | Inhalt |
|---|---|---|
| `src/config` | `ReplicatedStorage.Shared.Config` | **Alles zum Anpassen** (Zonen, Pets, Bosse …) – siehe [KONFIG-ANLEITUNG.md](KONFIG-ANLEITUNG.md) |
| `src/shared` | `ReplicatedStorage.Shared` | Gemeinsamer Code (Remotes, Formeln, Hindernis-Mathe) |
| `src/server` | `ServerScriptService.Server` | Ein Script + Services, Daten-Modul, WorldBuilder |
| `src/client` | `StarterPlayerScripts.Client` | Ein LocalScript + Controller und komplette UI |

Die Architektur (Module, Datenfluss, Remotes) steht in [ARCHITEKTUR.md](ARCHITEKTUR.md).

## Steuerung

| Aktion | PC | Handy/Tablet | Gamepad |
|---|---|---|---|
| Verlangsamen 🐢 | Q | Knopf | Steuerkreuz ← |
| Zurückspulen ⏪ | X | Knopf | Steuerkreuz ↑ |
| Sprint ⚡ | R | Knopf | Steuerkreuz → |
| Zeit-Wurf 🌀 | F | Knopf | R1 |
| Hilfsplattform 🧱 (Mechaniker) | G | Knopf | L1 |
| Menüs | Knöpfe links | Knöpfe links | – |

## Spielablauf (kurz)
* **Aufgaben** oben links + goldener Wegweiser zeigen immer, was als Nächstes zu tun ist.
* **Hub-Insel**: Upgrade-Shop, Pet-Eier, Rebirth-Altar, Skill-Lehrer, Bestenliste, 5 Zonen-Teleporter.
* **Zonen 1–5**: je 3 Strecken mit 🟢 Leicht / 🟡 Normal / 🔴 Profi (nebeneinander), Energie-Insel, Gegner-Insel,
  Boss-Arena, Portal zur nächsten Zone (ab Level X **oder** nach Boss-Sieg), ab Zone 2 Co-op-Rätsel.

## Qualität / Werkzeuge
```
selene src      # Linter
stylua src      # Formatierer
```
Hinweis: In der Entwicklungsumgebung dieses Projekts konnten Selene und StyLua nicht installiert werden.
Bitte einmal lokal ausführen (siehe TESTEN.md, Punkt 0).

## Admin-/Test-Befehle
Eure UserIds in `src/config/Settings.lua` bei `Settings.AdminUserIds` eintragen. Im Studio darf jeder (Einstellung
`AdminInStudio`). Im Spiel erscheint dann links der 🔧-Knopf.
