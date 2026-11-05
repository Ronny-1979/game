--[[
	📜 QUESTS – die Aufgaben, die neue Spieler Schritt für Schritt durchs Spiel führen
	Oben im Bild steht immer die aktuelle Aufgabe, ein leuchtender Wegweiser zeigt zum Ziel.

	Jede Aufgabe:
	  Titel     = kurze Überschrift
	  Text      = was genau zu tun ist (kurz und klar!)
	  Tipp      = (optional) zusätzlicher Hinweis
	  Art       = was gezählt wird (siehe Liste unten)
	  Anzahl    = wie oft (Standard 1)
	  Wert      = (bei manchen Arten) z.B. Zonennummer, Level oder Fähigkeit
	  Belohnung = { Energie = ..., XP = ..., Ei = "WiesenEi" }
	  Optional  = true → Aufgabe kann im Aufgaben-Fenster übersprungen werden (ohne Belohnung)
	  Ziel      = wohin der Wegweiser zeigt (optional)
	              Zone = 0 (Hub) oder 1–7, Tag = Art des Ziels, Attr = genaues Ziel

	Arten:
	  "Klasse"     – eine Klasse wählen
	  "Zone"       – Zone betreten (Wert = Zonennummer)
	  "Kristall"   – Energie-Kristalle anklicken
	  "Upgrade"    – Upgrades kaufen
	  "Ei"         – Eier öffnen
	  "Strecke"    – Strecke schaffen (optional Zone = 1, Strecke = 1, Diff = "Normal" → Normal ODER Profi)
	  "Faehigkeit" – Fähigkeit benutzen (Wert = "Verlangsamen", "Zurueckspulen", "Beschleunigen", "ZeitWurf")
	  "Gegner"     – Gegner besiegen (optional Zone = 1)
	  "Boss"       – Boss besiegen (Wert = Zonennummer)
	  "Level"      – Level erreichen (Wert = Level)
	  "Coop"       – Co-op-Rätsel lösen
	  "Rebirth"    – Rebirth machen

	Ziel-Tags: "ZoneTeleporter", "Portal", "EnergyCrystal", "TrackStart", "EnemySpawn", "BossArena",
	           "CoopArea", "EggStation", "MenuPrompt" (Shop/Skills/Rebirth/Bestenliste)
]]

local Quests = {}

Quests.Liste = {
	{
		Titel = "Wähle deine Klasse",
		Text = "Entscheide dich für Zeitwächter, Mechaniker oder Läufer.",
		Art = "Klasse",
		Belohnung = { Energie = 20, XP = 10 },
	},
	{
		Titel = "Ab in die Zahnrad-Wiese!",
		Text = "Folge dem goldenen Wegweiser zum Teleporter 1 und stell dich drauf.",
		Tipp = "Du kannst auch links auf 🗺️ Karte tippen.",
		Art = "Zone",
		Wert = 1,
		Belohnung = { Energie = 20, XP = 15 },
		Ziel = { Zone = 0, Tag = "ZoneTeleporter", Attr = { ZoneIndex = 1 } },
	},
	{
		Titel = "Zeit-Energie sammeln",
		Text = "Lauf über die Brücke zur Energie-Insel und klicke 20-mal auf die leuchtenden Kristalle.",
		Tipp = "Durch das blaue Feld laufen und Kugeln einsammeln gibt auch Energie ⚡",
		Art = "Kristall",
		Anzahl = 20,
		Belohnung = { Energie = 40, XP = 20 },
		Ziel = { Zone = 1, Tag = "EnergyCrystal" },
	},
	{
		Titel = "Deine erste Strecke",
		Text = "Schaffe die Strecke „Erste Schritte“ auf der grünen Bahn (Leicht).",
		Tipp = "Fällst du runter, geht es am letzten Checkpoint 🚩 weiter.",
		Art = "Strecke",
		Zone = 1,
		Strecke = 1,
		Belohnung = { Energie = 60, XP = 40 },
		Ziel = { Zone = 1, Tag = "TrackStart", Attr = { TrackKey = "Z1_T1", Diff = "Leicht" } },
	},
	{
		Titel = "Upgrade kaufen",
		Text = "Reise zurück in den Hub (Portal oder 🗺️ Karte) und kaufe im Shop 🛒 ein Upgrade.",
		Tipp = "„Klickkraft“ ist am Anfang am besten.",
		Art = "Upgrade",
		Belohnung = { Energie = 80, XP = 25 },
		Ziel = { Zone = 0, Tag = "MenuPrompt", Attr = { Menu = "Shop" } },
	},
	{
		Titel = "Dein erstes Pet",
		Text = "Öffne an der Eier-Station ein Wiesen-Ei (150 ⚡). Pets folgen dir und geben mehr Energie!",
		Tipp = "Zu wenig Energie? Sammle noch ein bisschen an den Kristallen.",
		Art = "Ei",
		Belohnung = { Energie = 50, XP = 30 },
		Ziel = { Zone = 0, Tag = "EggStation", Attr = { EggId = "WiesenEi" } },
	},
	{
		Titel = "Zeit verlangsamen",
		Text = "Benutze Verlangsamen 🐢 (Taste Q oder Knopf unten). Hindernisse und Gegner werden langsam!",
		Tipp = "Kostet 10 ⚡ – perfekt bei schnellen Pendeln.",
		Art = "Faehigkeit",
		Wert = "Verlangsamen",
		Belohnung = { Energie = 30, XP = 20 },
	},
	{
		Titel = "Zurückspulen",
		Text = "Benutze Zurückspulen ⏪ (Taste X). Du springst dahin zurück, wo du vor 3 Sekunden warst.",
		Tipp = "Rettet dich nach einem Fehlsprung!",
		Art = "Faehigkeit",
		Wert = "Zurueckspulen",
		Belohnung = { Energie = 30, XP = 20 },
	},
	{
		Titel = "Rost-Bots stoppen",
		Text = "Besiege 3 Rost-Bots auf der Gegner-Insel: Spring auf sie drauf oder wirf Zeit-Scheiben (F).",
		Tipp = "Wenn ein Bot zittert, rammt er gleich – geh zur Seite!",
		Art = "Gegner",
		Anzahl = 3,
		Belohnung = { Energie = 80, XP = 50 },
		Ziel = { Zone = 1, Tag = "EnemySpawn", Attr = { ZoneIndex = 1 } },
	},
	{
		Titel = "Etwas schwieriger",
		Text = "Schaffe irgendeine Strecke in der Zahnrad-Wiese auf 🟡 Normal (oder 🔴 Profi).",
		Tipp = "Normal und Profi geben viel mehr Belohnung.",
		Art = "Strecke",
		Zone = 1,
		Diff = "Normal",
		Belohnung = { Energie = 150, XP = 80 },
		Ziel = { Zone = 1, Tag = "TrackStart", Attr = { TrackKey = "Z1_T2", Diff = "Normal" } },
	},
	{
		Titel = "Stärker werden",
		Text = "Erreiche Level 5. XP gibt es für Strecken, Gegner und Aufgaben.",
		Tipp = "Level-Ups geben Skill-Punkte 🌳 – schau in den Skill-Baum!",
		Art = "Level",
		Wert = 5,
		Belohnung = { Energie = 150, XP = 0 },
	},
	{
		Titel = "Boss: Zahnrad-König",
		Text = "Besiege den Zahnrad-König in der Boss-Arena. Weich den orangen Flächen aus!",
		Tipp = "Bei der Schockwelle springen. Wenn er 💤 müde ist, nimmt er doppelten Schaden. Zu zweit geht's leichter!",
		Art = "Boss",
		Wert = 1,
		Belohnung = { Energie = 300, XP = 100 },
		Ziel = { Zone = 1, Tag = "BossArena", Attr = { ZoneIndex = 1 } },
	},
	{
		Titel = "Neue Zone: Rost-Werkstatt",
		Text = "Die Rost-Werkstatt ist jetzt offen! Reise mit dem Portal oder Teleporter 2 dorthin.",
		Art = "Zone",
		Wert = 2,
		Belohnung = { Energie = 500, XP = 60 },
		Ziel = { Zone = 0, Tag = "ZoneTeleporter", Attr = { ZoneIndex = 2 } },
	},
	{
		Titel = "Werkstatt-Strecke",
		Text = "Schaffe eine Strecke in der Rost-Werkstatt. Achtung, Förderbänder schieben dich!",
		Art = "Strecke",
		Zone = 2,
		Belohnung = { Energie = 1500, XP = 120 },
		Ziel = { Zone = 2, Tag = "TrackStart", Attr = { TrackKey = "Z2_T1", Diff = "Leicht" } },
	},
	{
		Titel = "Teamwork! 🤝",
		Text = "Löse mit einem Freund ein Co-op-Rätsel (seitlich an der Startterrasse).",
		Tipp = "Lade jemanden mit 👥 ein. Allein geht das nicht – dann kannst du die Aufgabe überspringen.",
		Art = "Coop",
		Optional = true, -- darf übersprungen werden
		Belohnung = { Energie = 2500, XP = 150 },
		Ziel = { Zone = 2, Tag = "CoopArea", Attr = { ZoneIndex = 2 } },
	},
	{
		Titel = "Boss: Rost-Rudi",
		Text = "Besiege Rost-Rudi. Er rennt gerne geradeaus – geh aus dem Streifen!",
		Art = "Boss",
		Wert = 2,
		Belohnung = { Energie = 5000, XP = 250 },
		Ziel = { Zone = 2, Tag = "BossArena", Attr = { ZoneIndex = 2 } },
	},
	{
		Titel = "Neue Zone: Pendel-Schlucht",
		Text = "Reise in die Pendel-Schlucht.",
		Art = "Zone",
		Wert = 3,
		Belohnung = { Energie = 8000, XP = 100 },
		Ziel = { Zone = 0, Tag = "ZoneTeleporter", Attr = { ZoneIndex = 3 } },
	},
	{
		Titel = "Boss: Pendel-Paula",
		Text = "Besiege Pendel-Paula in der Boss-Arena der Pendel-Schlucht.",
		Tipp = "Upgrades, Pets und Skills machen dich stärker.",
		Art = "Boss",
		Wert = 3,
		Belohnung = { Energie = 50000, XP = 500 },
		Ziel = { Zone = 3, Tag = "BossArena", Attr = { ZoneIndex = 3 } },
	},
	{
		Titel = "Neue Zone: Kristall-Getriebe",
		Text = "Reise ins Kristall-Getriebe.",
		Art = "Zone",
		Wert = 4,
		Belohnung = { Energie = 80000, XP = 200 },
		Ziel = { Zone = 0, Tag = "ZoneTeleporter", Attr = { ZoneIndex = 4 } },
	},
	{
		Titel = "Boss: Kristall-Koloss",
		Text = "Besiege den Kristall-Koloss.",
		Art = "Boss",
		Wert = 4,
		Belohnung = { Energie = 500000, XP = 900 },
		Ziel = { Zone = 4, Tag = "BossArena", Attr = { ZoneIndex = 4 } },
	},
	{
		Titel = "Das Große Uhrwerk",
		Text = "Reise ins Herz der Insel: Das Große Uhrwerk.",
		Art = "Zone",
		Wert = 5,
		Belohnung = { Energie = 800000, XP = 400 },
		Ziel = { Zone = 0, Tag = "ZoneTeleporter", Attr = { ZoneIndex = 5 } },
	},
	{
		Titel = "Finale: Meister Unruh",
		Text = "Besiege Meister Unruh und repariere das Uhrwerk!",
		Art = "Boss",
		Wert = 5,
		Belohnung = { Energie = 5000000, XP = 2000 },
		Ziel = { Zone = 5, Tag = "BossArena", Attr = { ZoneIndex = 5 } },
	},
	{
		Titel = "Neu geboren ♻️",
		Text = "Mache deinen ersten Rebirth am Rebirth-Altar im Hub (ab Level 15).",
		Tipp = "Rebirth-Punkte bekommst du für das besondere Rebirth-Ei.",
		Art = "Rebirth",
		Belohnung = { XP = 1000 },
		Ziel = { Zone = 0, Tag = "MenuPrompt", Attr = { Menu = "Rebirth" } },
	},
	{
		Titel = "Deine eigene Werkstatt 🏡",
		Text = "Geh im Hub zu „Meine Werkstatt“ und stelle 3 Deko-Stücke auf deine Insel.",
		Tipp = "Jedes Deko-Stück gibt dir dauerhaft etwas mehr Energie!",
		Art = "Deko",
		Anzahl = 3,
		Belohnung = { Energie = 30000, XP = 600 },
		Ziel = { Zone = 0, Tag = "MenuPrompt", Attr = { Menu = "Insel" } },
	},
	{
		Titel = "Pet-Fusion ✨",
		Text = "Verschmelze 3 gleiche Pets zu einem Gold-Pet (Pets-Menü → Fusion).",
		Tipp = "Gold-Pets sind 3,5-mal so stark. Regenbogen-Pets sogar 12-mal!",
		Art = "Fusion",
		Belohnung = { Energie = 40000, XP = 700 },
		Optional = true,
	},
	{
		Titel = "Der Endlos-Turm 🗼",
		Text = "Klettere im Endlos-Turm bis Etage 10.",
		Tipp = "Alle 10 Etagen gibt es ein Gratis-Ei. Jeden Montag steht ein neuer Turm!",
		Art = "Turm",
		Wert = 10,
		Belohnung = { Energie = 60000, XP = 900 },
		Ziel = { Zone = 0, Tag = "MenuPrompt", Attr = { Menu = "Turm" } },
	},
	{
		Titel = "Geheimnis-Jäger 🔍",
		Text = "Finde 5 versteckte goldene Zahnräder (im Hub und in den Zonen).",
		Tipp = "Im Erfolge-Menü 🏅 → Geheimnisse stehen Rätsel-Tipps.",
		Art = "Geheimnis",
		Anzahl = 5,
		Belohnung = { Energie = 50000, XP = 800 },
	},
	{
		Titel = "Gold-Medaille 🥇",
		Text = "Schaffe irgendeine Bahn so schnell, dass du eine Gold-Medaille bekommst.",
		Tipp = "Die Medaillen-Zeiten stehen in der Bestenliste 🏆. Leichte Bahnen sind kürzer!",
		Art = "Medaille",
		Wert = 3,
		Belohnung = { Energie = 50000, XP = 800 },
		Optional = true,
	},
	{
		Titel = "Neue Zone: Sternen-Sternwarte",
		Text = "Reise in die Sternwarte hoch über den Wolken (ab Level 40 oder nach Meister Unruh).",
		Art = "Zone",
		Wert = 6,
		Belohnung = { Energie = 8000000, XP = 800 },
		Ziel = { Zone = 0, Tag = "ZoneTeleporter", Attr = { ZoneIndex = 6 } },
	},
	{
		Titel = "Boss: Komet-Kasimir",
		Text = "Besiege Komet-Kasimir in der Boss-Arena der Sternwarte.",
		Tipp = "Zu zweit oder zu dritt geht es viel leichter!",
		Art = "Boss",
		Wert = 6,
		Belohnung = { Energie = 60000000, XP = 3000 },
		Ziel = { Zone = 6, Tag = "BossArena", Attr = { ZoneIndex = 6 } },
	},
	{
		Titel = "Neue Zone: Versunkenes Uhrwerk",
		Text = "Tauche ab ins Versunkene Uhrwerk am Meeresgrund.",
		Art = "Zone",
		Wert = 7,
		Belohnung = { Energie = 80000000, XP = 1200 },
		Ziel = { Zone = 0, Tag = "ZoneTeleporter", Attr = { ZoneIndex = 7 } },
	},
	{
		Titel = "Finale: Kapitän Ankerzahn",
		Text = "Besiege Kapitän Ankerzahn und rette das Herz der Tiefe!",
		Art = "Boss",
		Wert = 7,
		Belohnung = { Energie = 600000000, XP = 5000 },
		Ziel = { Zone = 7, Tag = "BossArena", Attr = { ZoneIndex = 7 } },
	},
}

-- 👋 Einführung beim ersten Start (Seiten zum Durchblättern)
Quests.Einfuehrung = {
	{ Symbol = "⚙️", Titel = "Willkommen auf der Uhrwerk-Insel!", Text = "Die Insel ist ein riesiges, kaputtes Uhrwerk. Du reparierst es, indem du Strecken schaffst, Zeit-Energie sammelst und Bosse besiegst." },
	{ Symbol = "📜", Titel = "Folge den Aufgaben", Text = "Oben links steht immer deine nächste Aufgabe. Der goldene Wegweiser zeigt dir den Weg. Tippe auf die Aufgabe für mehr Infos." },
	{ Symbol = "🏁", Titel = "Strecken", Text = "Jede Strecke hat drei Bahnen: 🟢 Leicht, 🟡 Normal, 🔴 Profi. Je schwerer, desto mehr Belohnung. Checkpoints 🚩 speichern deinen Fortschritt." },
	{ Symbol = "⏳", Titel = "Zeit-Fähigkeiten", Text = "Q = Verlangsamen 🐢   X = Zurückspulen ⏪   R = Sprint ⚡   F = Zeit-Wurf 🌀\nAuf Handy und Tablet sind es die runden Knöpfe unten rechts." },
	{ Symbol = "🐾", Titel = "Pets & Upgrades", Text = "Im Hub gibt es den Shop 🛒 und die Eier-Station 🥚. Pets folgen dir und geben mehr Energie. Die Menü-Knöpfe sind links." },
	{ Symbol = "🗼", Titel = "Turm & Werkstatt", Text = "Im Hub wartet der Endlos-Turm 🗼 – jede Woche ein neuer! Und in „Meine Werkstatt“ 🏡 baust du dir deine eigene Insel. Jedes Deko-Stück gibt dir mehr Energie." },
	{ Symbol = "🤝", Titel = "Zusammen spielen", Text = "Ab Zone 2 gibt es Rätsel, die nur zu zweit gehen. Lade Freunde mit 👥 ein und schickt euch Schnellnachrichten mit 💬. Viel Spaß!" },
}

-- 💡 Tipps, die ab und zu unten erscheinen
Quests.Tipps = {
	"Fällst du oft? Probier erst die 🟢 Leicht-Bahn!",
	"⏪ Zurückspulen (X) rettet dich nach einem Fehlsprung.",
	"Bosse sind müde 💤 nach ein paar Angriffen – dann doppelt Schaden!",
	"Bei der Schockwelle des Bosses: rechtzeitig springen!",
	"Pets mit ⭐ „Beste ausrüsten“ automatisch anlegen.",
	"Die 🗺️ Karte bringt dich direkt an jeden Streckenstart.",
	"Ab und zu gibt es 🚀 Doppel-Energie in einem Energie-Feld.",
	"Skill-Punkte 🌳 bekommst du bei jedem Level-Up.",
	"Auf Profi 🔴 gibt es 2,5-mal so viel Belohnung.",
	"Zu zweit sind Bosse viel leichter. 👥",
	"3 gleiche Pets? Verschmelze sie im Pet-Menü zu einem ✨ Gold-Pet!",
	"Spielst du mit Freunden auf einem Server, gibt es +10 % Energie pro Freund. 👥",
	"Irgendwo glitzern goldene Zahnräder … 🔍 Tipps stehen bei 🏅 Erfolge.",
	"Schaffst du die 🥇 Gold-Zeit? Die Zeiten stehen in der Bestenliste.",
	"Jeden Montag steht ein neuer 🗼 Endlos-Turm – wie hoch kommst du?",
	"Am Wochenende gibt es oft ⚡ Doppel-Energie!",
}
Quests.TippIntervall = 150 -- Sekunden zwischen zwei Tipps

return Quests
