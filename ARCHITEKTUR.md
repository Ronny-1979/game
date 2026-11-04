# Architektur – Uhrwerk-Insel

Dieses Dokument ist der Bauplan. Es beschreibt Module, Datenfluss und Remotes.

## Grundprinzipien

1. **Ein Einstieg pro Seite**: `src/server/init.server.lua` (Script) und `src/client/init.client.lua` (LocalScript).
   Alles andere sind ModuleScripts mit `Init()` (Zustand anlegen) und `Start()` (Verbindungen herstellen).
2. **Konfig statt Code**: Alle Inhalte (Zonen, Pets, Gegner, Bosse, Upgrades, Klassen, Skills, Schwierigkeit,
   Assets, Spielwerte) liegen in `src/config`. Code liest nur daraus.
3. **Server entscheidet**: Energie, XP, Käufe, Schaden, Belohnungen, Freischaltungen werden nur auf dem Server
   berechnet. Der Client zeigt an und schickt Wünsche, die geprüft werden.
4. **Welt aus Tags**: Der WorldBuilder baut die Welt und markiert Teile mit CollectionService-Tags und Attributen.
   Services finden ihre Teile über Tags – deshalb funktioniert die Welt egal ob sie im Edit-Modus
   (Command Bar) oder beim Serverstart gebaut wurde.
5. **Synchroner Takt**: Bewegte Hindernisse werden auf jedem Client lokal animiert. Die Position wird aus
   `workspace:GetServerTimeNow()` berechnet → alle sehen dasselbe, nichts ruckelt.
   Verlangsamen ändert serverseitig eine „virtuelle Zeit“ pro Hindernis (Attribute `VTBase`, `VTAt`, `VTScale`).

## Ordner

```
src/config   -> ReplicatedStorage.Shared.Config   (Inhalte zum Anpassen)
src/shared   -> ReplicatedStorage.Shared          (gemeinsamer Code)
src/server   -> ServerScriptService.Server        (Services, Daten, Welt)
src/client   -> StarterPlayerScripts.Client       (Controller, UI)
```

### Shared
| Modul | Aufgabe |
|---|---|
| `Remotes` | Legt alle RemoteEvents/-Functions an (Server) bzw. findet sie (Client). Server-Wrapper mit Rate-Limit + pcall. |
| `Signal` | Kleines Event-Objekt. |
| `Janitor` | Räumt Verbindungen/Instanzen auf. |
| `Util` | Zahlen formatieren, Zeit formatieren, Tiefenkopie, gewichteter Zufall. |
| `StatCalc` | Berechnet alle Werte eines Spielers (Upgrades + Klasse + Skills + Pets + Rebirth). Server = Wahrheit, Client = Anzeige. |
| `Progression` | XP-Kurve, Upgrade-Kosten, Rebirth-Kosten, Zonen-Freischaltung. |
| `ObstacleMath` | Virtuelle Zeit und Pose eines Hindernisses (Drehen, Pendeln, Gleiten, Wackeln, Takt). |
| `Tags` | Namen aller CollectionService-Tags. |
| `Types` | Luau-Typen (Profil). |

### Server-Services
| Service | Aufgabe |
|---|---|
| `DataService` | Profile laden/speichern (über `Data/ProfileStore`), Änderungen an Client senden, Werte-Cache. |
| `PlayerService` | Charakter-Spawn, Werte anwenden (Tempo, Sprung, Leben), Namensschild mit Titel, Positions-Verlauf. |
| `LevelService` | XP, Level-Ups, Skill-Punkte, Zonen freischalten, Belohnungen verteilen. |
| `ZoneService` | Teleporter, Portale, aktuelle Zone, Respawn-Punkt. |
| `CourseService` | Start/Checkpoint/Ziel, Streckenzeit, Bestzeit, Anti-Schummel-Prüfung, Belohnung. |
| `LeaderboardService` | OrderedDataStore-Bestenlisten pro Strecke + Schwierigkeit (mit Cache). |
| `ObstacleService` | Förderbänder, Hindernis-Takt-Basis. |
| `TimeScaleService` | Zeit-Blasen (Verlangsamen). Liefert Zeitfaktor für Gegner/Bosse und setzt virtuelle Zeit der Hindernisse. |
| `EnergyService` | Kristalle (ClickDetector), Energie-Felder, Energie-Kugeln, Doppel-Energie-Boosts. |
| `UpgradeService` | Upgrades kaufen, Rebirth. |
| `PetService` | Eier öffnen, Pets ausrüsten/ablegen/umbenennen/freilassen. |
| `ClassService` | Klassenwahl, Klassenwechsel, Skill-Baum. |
| `AbilityService` | Zeit-Fähigkeiten (Verlangsamen, Zurückspulen, Beschleunigen, Zeit-Wurf, Hilfsplattform). |
| `EnemyService` | Rost-Bots: Patrouille, Verfolgen, Zurücksetzen, Kontaktschaden, Sprung-Angriff. |
| `BossService` | Bosse mit 3 Phasen, Warnmarkierungen, Belohnungen. |
| `CoopService` | Doppel-Türen, Gleichzeitig-Brücken, Zeit-Konsolen, Team-Belohnung. |
| `ChatService` | Vorgefertigte Schnellnachrichten. |
| `AdminService` | Test-Befehle für Admin-UserIds. |

### Welt (Server)
`World/WorldBuilder` (Einstieg, auch per Command Bar) → `Builders/Parts`, `Builders/Obstacles`,
`Builders/TrackBuilder`, `Builders/HubBuilder`, `Builders/ZoneBuilder`, `Builders/CoopBuilder`, `World/Lighting`.

### Client-Controller
| Controller | Aufgabe |
|---|---|
| `DataController` | Spiegel des Profils + `Changed`-Signal. |
| `ObstacleController` | Animiert alle Hindernisse lokal, trägt den Spieler auf bewegten Plattformen mit. |
| `CourseController` | Gefahren erkennen → zurück zum Checkpoint, Sprungpads, Absturz, Streckenzeit. |
| `PetController` | Pets aller Spieler folgen lassen (nur lokal gebaut). |
| `AbilityController` | Tasten, Touch-Buttons, Gamepad, Abklingzeiten. |
| `EffectController` | Partikel, Zahlen, Zahnrad-Explosionen, Zeit-Blasen. |
| `SoundController` | Töne und Musik mit Lautstärke aus den Einstellungen. |
| `PromptController` | ProximityPrompts öffnen Menüs (Shop, Eier, Skill-Lehrer …). |
| `ChatController` | Schnellnachrichten als Sprechblasen, Roblox-Chat aus. |
| `UI/*` | HUD, Toasts, Boss-Leiste und alle Menüs – komplett per Code. |

## Datenfluss

```
Spieler klickt Kristall ─▶ ClickDetector (Server) ─▶ EnergyService prüft Abstand+Abklingzeit
                                                  ─▶ DataService.Update(+Energie)
                                                  ─▶ Remote "Data" (Profil-Schnappschuss, gedrosselt)
                                                  ─▶ DataController.Changed ─▶ HUD/Menüs
```

```
Spieler drückt Q ─▶ AbilityController ─▶ Remote "UseAbility"("Verlangsamen", Richtung)
   Server: Rate-Limit ▸ Typprüfung ▸ Klasse ▸ Abklingzeit ▸ Energie
         ─▶ TimeScaleService.AddRegion ─▶ Hindernisse: VTBase/VTAt/VTScale neu setzen
                                       ─▶ Gegner/Bosse lesen GetScale(pos)
         ─▶ Remote "Effect"("Slow") an alle ─▶ blaue Zeitblase
```

## Remotes (alle in `ReplicatedStorage.Remotes`)

**Server → Client (RemoteEvent)**
| Name | Daten |
|---|---|
| `Data` | kompletter Profil-Schnappschuss |
| `Toast` | Text, Art ("info", "gut", "fehler", "boss") |
| `Effect` | Art, Daten-Tabelle |
| `CourseEvent` | Art ("Start", "Checkpoint", "Ziel", "Abbruch"), Daten |
| `Bounce` | Sprungkraft (nach Sprung-Angriff) |
| `QuickChatShow` | UserId, Nachrichten-Nummer |
| `BossUi` | Boss-Daten oder nil |
| `AbilityUsed` | Fähigkeit, Abklingzeit (Bestätigung für Kreis-Anzeige) |

**Client → Server (RemoteEvent)**
| Name | Prüfung |
|---|---|
| `UseAbility` | Name ∈ Konfig, Vector3 endlich, Abklingzeit, Energie, Klasse, lebendig |
| `QuickChat` | Ganzzahl im Bereich, max. 1 pro 2 s |
| `ChangeSetting` | Schlüssel ∈ erlaubte Liste, Wert-Typ + Bereich |

**Client → Server (RemoteFunction, Antwort `{ok, msg, ...}`)**
`BuyUpgrade`, `Rebirth`, `HatchEgg`, `EquipPet`, `UnequipPet`, `EquipBest`, `RenamePet`, `ReleasePet`,
`ChooseClass`, `UnlockSkill`, `ResetSkills`, `TeleportZone`, `StartTrack`, `GetLeaderboard`, `Admin`.

Jeder Aufruf läuft durch `Remotes.OnEvent/OnInvoke` → Rate-Limit pro Spieler und Remote, `pcall` um den Handler.

## Profil (Schema-Version 2)

```
Version, Level, XP, Class, Energy, TotalEnergy, Upgrades{}, Rebirths, RebirthPoints,
Pets[{Id,Type,Name}], Equipped[Id], PetCounter, UnlockedZones{}, BossesDefeated{},
BestTimes{[TrackKey]={Leicht,Normal,Profi}}, Completed{}, SkillPoints, Skills{}, Titles[], ActiveTitle,
CoopSolved{}, Settings{Music,Sfx,Graphics,Difficulty}, Stats{PlayTime,Jumps,Defeated}
```
Migration v1 → v2: `Pets` von Liste aus Namen zu Liste aus Tabellen, `Settings` ergänzt.

## Welt-Koordinaten

* Hub-Insel: Mittelpunkt (0, 100, 0)
* Zone *i*: Mittelpunkt (i · 1400, 100, 0)
  * Platz (Spawn, Portale) im Zentrum, Startterrasse bei z = +90
  * 3 Strecken bei x = −110 / 0 / +110, je 3 Bahnen (Leicht/Normal/Profi) nebeneinander in +z
  * Energie-Insel (−200, 0, −60), Gegner-Insel (+200, 0, −60), Boss-Arena (0, 0, −240)
  * Co-op-Rätsel seitlich bei x = ±250

## Sicherheit
* Kein freier Text: Pet-Namen und Chat nur aus vorgefertigten Listen → kein Filter nötig.
* Keine Käufe mit Echtgeld, kein Handel, keine Links.
* Admin-Befehle nur für `Settings.AdminUserIds` (+ optional im Studio).
