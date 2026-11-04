# 🛠️ Konfig-Anleitung – so gestaltest du das Spiel mit!

Alle Dateien liegen in **`src/config`**. Du musst keinen Code verstehen.
Wichtig:
* Ändere nur Zahlen und Texte **rechts vom `=`**.
* Lass Kommas `,`, Klammern `{ }` und Anführungszeichen `" "` stehen.
* Nach dem Speichern überträgt Rojo die Datei automatisch ins Studio.
* Wenn du **Zonen, Strecken, Hindernisse oder Farben** änderst: Welt neu bauen (Command Bar):
  ```lua
  require(game.ServerScriptService.Server.World.WorldBuilder).Build()
  ```
* Fehler gemacht? Im Studio-Fenster *Output* steht dann eine rote Meldung mit Datei und Zeile.

---

## 🐾 Ein neues Pet erfinden (`Pets.lua`)

1. Unter `Pets.Liste = {` eine neue Zeile einfügen, z. B.:
   ```lua
   Blitzi = { Name = "Blitzi", Seltenheit = "Episch", Multiplikator = 3, Farbe = Color3.fromRGB(255, 240, 80), Form = "Kugel", Beschreibung = "Ein gelber Blitz mit Uhr-Bauch" },
   ```
   * `Seltenheit`: `"Gewoehnlich"`, `"Selten"`, `"Episch"` oder `"Legendaer"` (Episch/Legendär leuchten!)
   * `Multiplikator`: 1.5 = +50 % Energie
   * `Farbe`: Rot, Grün, Blau – jeweils 0 bis 255
   * `Form`: `"Kugel"`, `"Wuerfel"`, `"Zylinder"` oder `"Zahnrad"`
2. Das Pet in ein Ei eintragen, z. B. beim `WiesenEi` unter `Chancen`:
   ```lua
   Chancen = { Tick = 45, Tack = 35, Federling = 15, Kuckucki = 4.5, Goldwecker = 0.5, Blitzi = 2 },
   ```
   Größere Zahl = häufiger. Die Prozente rechnet das Spiel selbst aus.

**Neues Ei?** Unter `Pets.Eier` eine Kopie eines Eis machen, umbenennen und in `Pets.EierReihenfolge` eintragen.
Danach Welt neu bauen (dann steht das Ei im Hub).

## 👑 Einen Boss ändern (`Bosses.lua`)

```lua
ZahnradKoenig = {
	Name = "Zahnrad-König",   -- Anzeigename
	Leben = 500,              -- mehr = länger kämpfen
	Schaden = 12,             -- pro Treffer (Spieler haben 100 Leben)
	Groesse = 12,
	Farbe = Color3.fromRGB(230, 185, 80),
	AngriffeBisMuede = 3,     -- nach 3 Angriffen ist er müde (doppelter Schaden!)
	MuedeZeit = 4,
	Phasen = {
		{ Angriffe = { "Stampfen", "Zahnradregen" }, Warnzeit = 1.8, Pause = 2.2 },
		...
	},
	Belohnung = { XP = 300, Energie = 1500, Ei = "WiesenEi", Titel = "Zahnrad-Bezwinger" },
},
```
Angriffe: `"Stampfen"`, `"Zahnradregen"`, `"Schockwelle"` (drüberspringen!), `"Laserlinie"`, `"Ansturm"`.
**Tipp:** Größere `Warnzeit` = leichter. Neuer Boss? Kopieren, umbenennen und in `Zones.lua` bei `Boss = "..."` eintragen.

## 🗺️ Zonen und Strecken (`Zones.lua`)

* `FreischaltLevel`: ab diesem Level ist die Zone offen (oder wenn der Boss davor besiegt ist).
* `Schwierigkeit`: 1.0 (leicht) bis 2.0 (sehr schwer) – macht Hindernisse schneller, Plattformen kleiner.
* `Energiewert`: so viel Energie gibt ein Kristall-Klick.
* `Farben`: Boden, Akzent (Messing-Teile), Plattform, Deko.
* `Strecken`: genau 3 Stück. Beispiel:
  ```lua
  { Name = "Meine Strecke", Abschnitte = 12, Hindernisse = { "Zahnrad", "Pendel", "Laser" }, Belohnung = { Energie = 500, XP = 80 } },
  ```
  Hindernisse: `"Sprung"`, `"Zahnrad"`, `"Pendel"`, `"Foerderband"`, `"Bewegt"`, `"Zeitplattform"`, `"Wackel"`,
  `"Laser"`, `"Sprungpad"`, `"Funken"`, `"Drehring"`.
* `Gegner = { Typ = "RostBot", Anzahl = 5 }` – Typen aus `Enemies.lua`.
* `Coop = { "Tuer", "Bruecke", "Konsole" }` – bis zu 3 Zwei-Spieler-Rätsel.
* `Zones.Hinweise` (unten): Texte der Hinweis-Schilder in Zone 1.

## 🎚️ Schwierigkeit (`Difficulty.lua`)
Pro Stufe (Leicht/Normal/Profi): `Plattformgroesse`, `LueckeMin/LueckeMax` (Sprungweite), `Tempo` der Hindernisse,
`Takt` der Zeitplattformen, `CheckpointAlle`, `Belohnung`, `EiChance`.
⚠️ `MaxLuecke` nicht über **9.5** stellen – weiter kann man mit Grundwerten nicht springen!

## 🤖 Gegner (`Enemies.lua`)
`Leben`, `Schaden`, `Tempo`, `XP`, `Energie`, `Sichtweite`, `Angriffsmuster` (`"Ramme"`, `"Huepfer"`, `"Kreisel"`),
`Groesse`, `Farbe`, `Respawnzeit`.

## 🛒 Upgrades (`Upgrades.lua`)
Kosten der nächsten Stufe = `Basiskosten × Kostenfaktor ^ Stufe`. `Effekt = { Stat = "...", Plus = ... }`.

## 🎓 Klassen (`Classes.lua`) und 🌳 Skills (`Skills.lua`)
Boni und Skill-Knoten benutzen **Stats**: `{ Stat = "WalkSpeed", Plus = 2 }` oder `{ Stat = "PetPower", Mal = 1.2 }`.

| Stat | Bedeutung |
|---|---|
| WalkSpeed / JumpPower / MaxHealth | Lauftempo / Sprungkraft / Leben |
| ClickPower / CollectRadius / FieldEnergy | Klick-Energie / Sammelradius / Feld-Energie |
| EnergyMult / XPMult / PetPower / PetSlots | Energie-, XP-, Pet-Multiplikator / Pet-Plätze |
| StompDamage / ThrowDamage / ThrowRange / ThrowCooldown | Sprung-Angriff / Zeit-Wurf |
| SlowDuration / SlowRadius / SlowFactor / SlowCooldown / SlowCost | Verlangsamen (SlowFactor kleiner = stärker) |
| RewindSeconds / RewindCooldown / RewindCost | Zurückspulen |
| BoostSpeed / BoostDuration / BoostCooldown / BoostCost | Sprint |
| PlatformDuration / PlatformSize / PlatformCooldown / PlatformCost | Hilfsplattform |

In `Skills.Faehigkeiten` stehen die Grundwerte (Abklingzeit, Kosten, Dauer, Taste).

## ⚙️ Spielwerte (`Settings.lua`)
Admin-UserIds, Autosave-Intervall, XP-Kurve, Rebirth-Kosten, Boost-Zeiten, Schnellnachrichten, erlaubte Pet-Namen.
`Settings.Coop.SoloTestMode = true` lässt Co-op-Rätsel zum Testen auch allein funktionieren.

## 🎵 Töne & Bilder (`Assets.lua`)
Platzhalter durch eigene IDs ersetzen: Studio → Toolbox → Rechtsklick auf ein Audio → *Copy Asset ID* →
`"rbxassetid://1234567"`. Leerer Text `""` = aus.
