# ✅ Test-Checkliste

Abhaken beim Durchspielen. Für Co-op: Test → *Clients and Servers* → **2 Spieler**.
Tipp: Mit dem 🔧-Admin-Menü (im Studio immer da) kommt man schnell an Energie, Level und Zonen.

## 0. Vorbereitung
- [ ] `rokit install` (oder `aftman install`), dann `selene src` → keine Fehler/Warnungen (sonst melden/beheben)
- [ ] `stylua --check src` → ggf. `stylua src` ausführen
- [ ] `rojo serve`, Studio verbunden, keine roten Fehler im Output
- [ ] WorldBuilder per Command Bar ausgeführt → Output: „Welt gebaut: … Teile“
- [ ] Workspace → *StreamingEnabled* an (Standard bei neuen Orten)

## 1. Start & Daten
- [ ] Spawn im Hub, Klassenwahl erscheint und lässt sich nicht wegklicken
- [ ] Klasse wählen → Fenster schließt, Toast erscheint, Skill-Leiste passt (Mechaniker hat 🧱)
- [ ] Mit API-Zugriff: Energie sammeln, Spiel beenden, neu starten → Energie ist noch da
- [ ] Ohne API-Zugriff: Hinweis „Test-Modus“ oben rechts
- [ ] Roblox-Chat ist ausgeblendet, 💬 Schnellnachrichten zeigen Sprechblasen über dem Kopf

## 2. Hub
- [ ] Shop (Prompt an der Theke): Upgrade kaufen, Preis steigt, „MAX“ bei Maximalstufe
- [ ] Eier: Wiesen-Ei öffnen (150 ⚡), Pet erscheint und folgt; anderes Ei ohne Zone → Fehlermeldung
- [ ] Rebirth-Altar zeigt Kosten; Rebirth nur ab Level 15 und genug Energie, Doppel-Tipp-Bestätigung
- [ ] Skill-Lehrer: Skill-Baum mit Wechseln/Zurücksetzen; im Feld geöffnet ohne diese Knöpfe
- [ ] Teleporter: Zone 1 geht, Zone 2 zeigt „🔒 ab Level 6 …“

## 3. Zone 1 – Zahnrad-Wiese (Tutorial)
- [ ] Hinweis-Schilder an der 🟢-Bahn
- [ ] Startfeld → Timer oben, Checkpoint → Toast „🚩 1/x“, Runterfallen → zurück zum Checkpoint
- [ ] Ziel → Ergebnis-Fenster mit Zeit, „Neue Bestzeit“, Belohnung als Toast
- [ ] Gleiche Strecke auf 🟡 und 🔴 → eigene Bestzeiten in 🏆 Bestenliste
- [ ] Zeitplattformen blinken vor dem Verschwinden; Zahnrad nimmt mich mit; Kehrbalken schickt mich zurück
- [ ] Sprungfeder schleudert hoch; Funkenboden schickt zurück
- [ ] Energie-Insel: Kristall-Klick (+Zahl), Laufen im Feld gibt Energie, Kugeln einsammeln
- [ ] Gegner-Insel: Bot verfolgt, rammt (zittert vorher), Sprung drauf = Schaden + Hochfedern, F-Wurf trifft
- [ ] Bot besiegt → Zahnrad-Explosion, XP/Energie, kommt nach ein paar Sekunden wieder
- [ ] Boss-Arena: Boss startet beim Betreten, Warnflächen vor jedem Angriff, Schockwelle überspringbar
- [ ] 💤 Müde-Phase: doppelter Schaden; Phase 2/3-Toast; Sieg → Titel über dem Kopf, Gratis-Ei, Zone 2 frei

## 4. Fähigkeiten
- [ ] Q: blaue Blase, Hindernisse/Gegner in der Nähe langsamer (bei beiden Spielern gleich!)
- [ ] X: Zurückspulen an eine Stelle von vor ~3 s (gut nach einem Fehlsprung)
- [ ] R: Sprint mit Funkenspur
- [ ] Abklingkreise laufen ab, Energiekosten werden abgezogen, ohne Energie → Fehlermeldung
- [ ] Handy-Emulation (Studio: Test → Device): Knöpfe groß, über dem Sprung-Knopf, alles erreichbar

## 5. Co-op (2 Spieler, ab Zone 2)
- [ ] Doppeltür: nur mit beiden Spielern auf den Platten offen, Team-Belohnung für beide
- [ ] Zeit-Brücke: beide Knöpfe innerhalb 1,5 s → Brücke + Barriere weg für 15 s
- [ ] Zeit-Konsole (Zone 3): einer steht drauf → Strecke langsam, der andere schafft sie
- [ ] Allein: Hinweis „nur zusammen“ (oder `SoloTestMode = true` zum Testen)
- [ ] 👥 Einladen öffnet das Roblox-Einladefenster (nur im veröffentlichten Spiel)

## 6. Zonen 2–5
- [ ] Admin: „Alle Zonen frei“ → jede Zone per Karte erreichbar, alle 3 Strecken je Bahn schaffbar
- [ ] Förderbänder (Z2), Pendel (Z3), Drehringe + Laser (Z4), Mischung (Z5)
- [ ] Jeder Boss besiegbar (zu zweit testen), Portal führt zur nächsten Zone

## 7. Sicherheit (optional mit Exploit-Testwerkzeug)
- [ ] Admin-Befehl als Nicht-Admin (UserId entfernen, `AdminInStudio = false`) → „Keine Admin-Rechte“
- [ ] Remote-Spam (schnelles Klicken) → „Nicht so schnell!“, kein Fehler
- [ ] Ziel ohne Checkpoints erreichen → „Checkpoint verpasst“

## 8. Leistung
- [ ] Grafik „Niedrig“ in ⚙️ → weniger Effekte, flüssig auf älteren Geräten
- [ ] Mikroprofiler (Strg+F6): keine dauerhaften Spitzen
