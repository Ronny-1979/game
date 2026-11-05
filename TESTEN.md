# ✅ Test-Checkliste

Abhaken beim Durchspielen. Für Co-op: Test → *Clients and Servers* → **2 Spieler**.
Tipp: Mit dem 🔧-Admin-Menü (im Studio immer da) kommt man schnell an Energie, Level und Zonen.

## 0. Vorbereitung
- [ ] `rokit install` (oder `aftman install`), dann `selene src` → keine Fehler/Warnungen (sonst melden/beheben)
- [ ] `stylua --check src` → ggf. `stylua src` ausführen
- [ ] `.\rojo serve` (PowerShell) oder `aktualisieren.bat`, Studio verbunden, keine roten Fehler im Output
- [ ] WorldBuilder per Command Bar ausgeführt → Output: „Welt gebaut: … Teile“
- [ ] Workspace → *StreamingEnabled* an (Standard bei neuen Orten)

## 1. Start & Daten
- [ ] Spawn im Hub, Klassenwahl erscheint und lässt sich nicht wegklicken
- [ ] Klasse wählen → Fenster schließt, Toast erscheint, Skill-Leiste passt (Mechaniker hat 🧱)
- [ ] Mit API-Zugriff: Energie sammeln, Spiel beenden, neu starten → Energie ist noch da
- [ ] Ohne API-Zugriff: Hinweis „Test-Modus“ oben rechts
- [ ] Roblox-Chat ist ausgeblendet, 💬 Schnellnachrichten zeigen Sprechblasen über dem Kopf

## 1b. Anleitung & Aufgaben
- [ ] Nach der Klassenwahl erscheint die Einführung (6 Seiten), danach nicht mehr bei jedem Start
- [ ] Oben links steht die Aufgabe mit Entfernung, goldener Strahl + hüpfender Pfeil zeigen zum Ziel
- [ ] Ziel in anderer Zone → Wegweiser zeigt erst zum Teleporter/Portal (mit Hinweis)
- [ ] Tippen auf die Aufgabe → Fenster mit Text, Tipp, Fortschritt, Belohnung, Wegweiser an/aus
- [ ] Aufgabe erledigt → Toast + Belohnung + nächste Aufgabe; Tipps 💡 erscheinen ab und zu
- [ ] Alter Spielstand: bereits erfüllte Aufgaben (Klasse, Level, Boss) werden sofort abgehakt

## 1c. Bonus, Erfolge, Grafik
- [ ] Nach der Einführung öffnet sich 🎁 Tagesbonus, Abholen gibt Belohnung, danach „Heute abgeholt“ + Countdown
- [ ] Roter Punkt am 🎁-Knopf, solange der Bonus bereit ist (Admin: „Bonus zurücksetzen“ zum erneuten Testen)
- [ ] 🏅 Erfolge: Herausforderungen pro Zone mit Fortschrittsbalken; Abzeichen werden automatisch vergeben (Toast)
- [ ] Neue Gegner: Zahnrad-Käfer (Zone 1), Drohnen mit Sturzflug (Warnfläche!), Schützen mit Zahnrad-Wurf (Warnfläche!)
- [ ] Welt neu gebaut: Blumen, Felsen, Wolken unter den Inseln, schwebende Mini-Inseln – nichts blockiert Wege
- [ ] Zonenwechsel: Licht/Nebel/Tageszeit gleiten um, Glühwürmchen-Funken (bei Grafik „Niedrig“ aus)

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

## 6. Zonen 2–7
- [ ] Admin: „Alle Zonen frei“ → jede Zone per Karte erreichbar, alle 3 Strecken je Bahn schaffbar
- [ ] Förderbänder (Z2), Pendel (Z3), Drehringe + Laser (Z4), Mischung (Z5), Sternwarte (Z6), Tiefsee (Z7)
- [ ] Jeder Boss besiegbar (zu zweit testen), Portal führt zur nächsten Zone

## 6b. Neue Funktionen (1.3)
- [ ] Pets: Admin „3× gleiches Pet“ → im Pet-Menü „Fusion zu Gold (3/3)“ → ein ✨ Gold-Pet, glänzt golden
- [ ] Strecke schaffen → Ergebnis zeigt Medaille + nächstes Ziel, Karte zeigt 🥇/🥈/🥉
- [ ] Bestenliste zeigt die Medaillen-Zeiten der Bahn
- [ ] Admin: Event-Knopf → Banner links im HUD, Energie doppelt; „Test-Event aus“ → Banner weg
- [ ] Halloween-Event → Kürbisse im Hub; Winter-Event → Schneefall
- [ ] Geheimnis im Hub (hinter dem Uhrturm) berühren → Belohnung, Zahnrad verschwindet; 🏅 Erfolge → Geheimnisse
- [ ] Hub → 🗼 Endlos-Turm → „Etage 1“ → Ausgang erreicht → Etage 2; Absturz → zurück auf die Etagen-Startplatte
- [ ] Turm: „↩ Hub“-Feld bringt zurück; Admin „Turm: Etage +10“ → Start auf Etage 11 möglich
- [ ] Hub → 🏡 Meine Werkstatt → „Zur Werkstatt“ → Katalog → Deko wählen → Vorschau grün/rot, T dreht, Klick baut
- [ ] Abbauen-Modus: Deko anklicken → verschwindet, Energie zurück; Werkstatt-Bonus im Menü steigt/sinkt
- [ ] Zweiter Spieler: „Werkstätten besuchen“ → landet auf der fremden Insel, darf dort nichts bauen
- [ ] Boss besiegen → Konfetti-Regen + Feuerwerk; danach Pokal im Werkstatt-Katalog frei

## 7. Sicherheit (optional mit Exploit-Testwerkzeug)
- [ ] Admin-Befehl als Nicht-Admin (UserId entfernen, `AdminInStudio = false`) → „Keine Admin-Rechte“
- [ ] Remote-Spam (schnelles Klicken) → „Nicht so schnell!“, kein Fehler
- [ ] Ziel ohne Checkpoints erreichen → „Checkpoint verpasst“

## 8. Leistung
- [ ] Grafik „Niedrig“ in ⚙️ → weniger Effekte, flüssig auf älteren Geräten
- [ ] Mikroprofiler (Strg+F6): keine dauerhaften Spitzen
