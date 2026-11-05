--[[
	🗺️ ZONES – die sieben Zonen der Uhrwerk-Insel
	Jede Zone bekommt:
	  Name, Farben, Schwierigkeit (1.0 = leicht … 2.0 = sehr schwer),
	  FreischaltLevel (ab diesem Level offen – oder wenn der Boss der Zone davor besiegt ist),
	  Strecken (3 Stück), Gegner, Boss, Ei, Co-op-Rätsel.

	Hindernis-Namen für "Hindernisse" (beliebig mischen):
	  "Sprung"       – normale Plattformen mit Lücken
	  "Zahnrad"      – drehendes Zahnrad zum Draufspringen
	  "Pendel"       – Pendel schwingen über einen Steg
	  "Foerderband"  – Förderbänder schieben dich
	  "Bewegt"       – Plattformen gleiten hin und her
	  "Zeitplattform"– Plattformen erscheinen/verschwinden im Takt
	  "Wackel"       – Wackelplatten kippen
	  "Laser"        – Laser gehen im Takt an und aus
	  "Sprungpad"    – Sprungfeder schleudert dich hoch
	  "Funken"       – Funkenboden: nur auf die sicheren Felder treten
	  "Drehring"     – rotierende Ringe um eine Säule

	Co-op-Rätsel (für "Coop"):
	  "Tuer"     – Doppeltür: zwei Druckplatten gleichzeitig besetzen
	  "Bruecke"  – zwei Knöpfe gleichzeitig drücken → Brücke erscheint
	  "Konsole"  – einer hält die Zeit an der Konsole an, der andere springt
]]

local Zones = {
	{
		Id = "Wiese",
		Name = "Zahnrad-Wiese",
		Beschreibung = "Hier fängt alles an! Lerne springen, sammeln und kämpfen.",
		Farben = {
			Boden = Color3.fromRGB(150, 215, 130),
			Akzent = Color3.fromRGB(215, 170, 80),
			Plattform = Color3.fromRGB(255, 228, 160),
			Deko = Color3.fromRGB(255, 170, 190),
		},
		Schwierigkeit = 1.0,
		FreischaltLevel = 1,
		Energiewert = 1, -- Energie pro Kristall-Klick (vor Multiplikatoren)
		Tutorial = true, -- zeigt Hinweis-Schilder
		Strecken = {
			{ Name = "Erste Schritte", Abschnitte = 6, Hindernisse = { "Sprung", "Sprungpad", "Sprung", "Zeitplattform" }, Belohnung = { Energie = 80, XP = 40 } },
			{ Name = "Zahnrad-Hüpfer", Abschnitte = 10, Hindernisse = { "Sprung", "Zahnrad", "Wackel" }, Belohnung = { Energie = 120, XP = 60 } },
			{ Name = "Funkelpfad", Abschnitte = 12, Hindernisse = { "Sprung", "Zahnrad", "Zeitplattform", "Funken" }, Belohnung = { Energie = 180, XP = 90 } },
		},
		Gegner = { { Typ = "RostBot", Anzahl = 5 }, { Typ = "Zahnradkaefer", Anzahl = 3 } },
		-- Stimmung: Tageszeit (0–24), Nebelfarbe, Nebeldichte (0–1), Farbtönung, Glühwürmchen-Farbe
		Stimmung = { Uhrzeit = 14.5, Nebel = Color3.fromRGB(235, 245, 245), Dichte = 0.24, Toenung = Color3.fromRGB(252, 255, 250), Funken = Color3.fromRGB(255, 240, 150) },
		Boss = "ZahnradKoenig",
		Ei = "WiesenEi",
		Coop = {},
	},
	{
		Id = "Werkstatt",
		Name = "Rost-Werkstatt",
		Beschreibung = "Förderbänder rattern, Plattformen gleiten – und Rost-Bots wuseln herum.",
		Farben = {
			Boden = Color3.fromRGB(205, 145, 105),
			Akzent = Color3.fromRGB(120, 170, 205),
			Plattform = Color3.fromRGB(235, 200, 160),
			Deko = Color3.fromRGB(245, 150, 95),
		},
		Schwierigkeit = 1.25,
		FreischaltLevel = 6,
		Energiewert = 5,
		Strecken = {
			{ Name = "Fließband-Flitzer", Abschnitte = 10, Hindernisse = { "Foerderband", "Bewegt", "Sprung" }, Belohnung = { Energie = 900, XP = 110 } },
			{ Name = "Funkenhalle", Abschnitte = 12, Hindernisse = { "Foerderband", "Zahnrad", "Funken" }, Belohnung = { Energie = 1300, XP = 150 } },
			{ Name = "Rostige Rampe", Abschnitte = 13, Hindernisse = { "Bewegt", "Wackel", "Foerderband", "Sprungpad" }, Belohnung = { Energie = 1800, XP = 200 } },
		},
		Gegner = { { Typ = "SchraubenBot", Anzahl = 5 }, { Typ = "Schweissdrohne", Anzahl = 3 } },
		Stimmung = { Uhrzeit = 16.5, Nebel = Color3.fromRGB(245, 228, 210), Dichte = 0.3, Toenung = Color3.fromRGB(255, 250, 242), Funken = Color3.fromRGB(255, 170, 90) },
		Boss = "RostRudi",
		Ei = "WerkstattEi",
		Coop = { "Tuer", "Bruecke" },
	},
	{
		Id = "Schlucht",
		Name = "Pendel-Schlucht",
		Beschreibung = "Riesige Pendel schwingen über tiefe Schluchten. Timing ist alles!",
		Farben = {
			Boden = Color3.fromRGB(175, 155, 215),
			Akzent = Color3.fromRGB(225, 185, 95),
			Plattform = Color3.fromRGB(250, 222, 240),
			Deko = Color3.fromRGB(130, 200, 225),
		},
		Schwierigkeit = 1.5,
		FreischaltLevel = 12,
		Energiewert = 20,
		Strecken = {
			{ Name = "Pendel-Pass", Abschnitte = 12, Hindernisse = { "Pendel", "Zeitplattform", "Sprung" }, Belohnung = { Energie = 9000, XP = 220 } },
			{ Name = "Schwingende Brücken", Abschnitte = 13, Hindernisse = { "Pendel", "Bewegt", "Wackel" }, Belohnung = { Energie = 13000, XP = 280 } },
			{ Name = "Echo-Abgrund", Abschnitte = 15, Hindernisse = { "Pendel", "Zeitplattform", "Funken", "Sprungpad" }, Belohnung = { Energie = 18000, XP = 350 } },
		},
		Gegner = { { Typ = "PendelBot", Anzahl = 5 }, { Typ = "Glockenschuetze", Anzahl = 3 } },
		Stimmung = { Uhrzeit = 17.6, Nebel = Color3.fromRGB(225, 200, 255), Dichte = 0.36, Toenung = Color3.fromRGB(245, 235, 255), Funken = Color3.fromRGB(200, 170, 255) },
		Boss = "PendelPaula",
		Ei = "SchluchtEi",
		Coop = { "Konsole", "Tuer" },
	},
	{
		Id = "Kristall",
		Name = "Kristall-Getriebe",
		Beschreibung = "Funkelnde Ringe drehen sich, Laser blitzen im Takt.",
		Farben = {
			Boden = Color3.fromRGB(145, 220, 232),
			Akzent = Color3.fromRGB(190, 145, 240),
			Plattform = Color3.fromRGB(228, 246, 255),
			Deko = Color3.fromRGB(255, 165, 222),
		},
		Schwierigkeit = 1.75,
		FreischaltLevel = 20,
		Energiewert = 80,
		Strecken = {
			{ Name = "Ring-Tanz", Abschnitte = 13, Hindernisse = { "Drehring", "Laser", "Zeitplattform" }, Belohnung = { Energie = 90000, XP = 420 } },
			{ Name = "Laser-Labyrinth", Abschnitte = 14, Hindernisse = { "Laser", "Zahnrad", "Bewegt" }, Belohnung = { Energie = 130000, XP = 500 } },
			{ Name = "Prismen-Gipfel", Abschnitte = 16, Hindernisse = { "Drehring", "Laser", "Pendel", "Wackel" }, Belohnung = { Energie = 180000, XP = 620 } },
		},
		Gegner = { { Typ = "KristallBot", Anzahl = 5 }, { Typ = "Prismadrohne", Anzahl = 4 } },
		Stimmung = { Uhrzeit = 20.5, Nebel = Color3.fromRGB(170, 225, 255), Dichte = 0.3, Toenung = Color3.fromRGB(230, 245, 255), Funken = Color3.fromRGB(140, 240, 255) },
		Boss = "KristallKoloss",
		Ei = "KristallEi",
		Coop = { "Bruecke", "Konsole", "Tuer" },
	},
	{
		Id = "Uhrwerk",
		Name = "Das Große Uhrwerk",
		Beschreibung = "Das Herz der Insel. Alles auf einmal – und Meister Unruh wartet!",
		Farben = {
			Boden = Color3.fromRGB(228, 188, 98),
			Akzent = Color3.fromRGB(205, 115, 72),
			Plattform = Color3.fromRGB(255, 242, 205),
			Deko = Color3.fromRGB(120, 205, 175),
		},
		Schwierigkeit = 2.0,
		FreischaltLevel = 30,
		Energiewert = 300,
		Strecken = {
			{ Name = "Zeiger-Sprint", Abschnitte = 15, Hindernisse = { "Zahnrad", "Pendel", "Foerderband", "Zeitplattform", "Sprung" }, Belohnung = { Energie = 900000, XP = 800 } },
			{ Name = "Unruh-Wirbel", Abschnitte = 16, Hindernisse = { "Drehring", "Bewegt", "Laser", "Wackel", "Funken" }, Belohnung = { Energie = 1300000, XP = 950 } },
			{ Name = "Mitternacht", Abschnitte = 18, Hindernisse = { "Zahnrad", "Pendel", "Laser", "Drehring", "Zeitplattform", "Sprungpad", "Foerderband" }, Belohnung = { Energie = 2000000, XP = 1200 } },
		},
		Gegner = { { Typ = "UhrwerkWaechter", Anzahl = 5 }, { Typ = "Zeigerschuetze", Anzahl = 3 }, { Typ = "Schweissdrohne", Anzahl = 2 } },
		Stimmung = { Uhrzeit = 18.4, Nebel = Color3.fromRGB(245, 225, 200), Dichte = 0.32, Toenung = Color3.fromRGB(255, 248, 238), Funken = Color3.fromRGB(255, 215, 120) },
		Boss = "MeisterUnruh",
		Ei = "UhrwerkEi",
		Coop = { "Tuer", "Bruecke", "Konsole" },
	},
	{
		Id = "Sternwarte",
		Name = "Sternen-Sternwarte",
		Beschreibung = "Hoch über den Wolken drehen sich Planeten-Zahnräder unter dem Sternenhimmel.",
		Farben = {
			Boden = Color3.fromRGB(125, 115, 195),
			Akzent = Color3.fromRGB(240, 210, 120),
			Plattform = Color3.fromRGB(228, 228, 255),
			Deko = Color3.fromRGB(150, 205, 255),
		},
		Schwierigkeit = 2.2,
		FreischaltLevel = 40,
		Energiewert = 1200,
		Strecken = {
			{ Name = "Sternen-Sprung", Abschnitte = 16, Hindernisse = { "Sprung", "Drehring", "Zeitplattform", "Sprungpad" }, Belohnung = { Energie = 9000000, XP = 1500 } },
			{ Name = "Kometen-Kurs", Abschnitte = 17, Hindernisse = { "Bewegt", "Laser", "Pendel", "Wackel" }, Belohnung = { Energie = 13000000, XP = 1800 } },
			{ Name = "Milchstraße", Abschnitte = 19, Hindernisse = { "Drehring", "Zahnrad", "Laser", "Funken", "Zeitplattform" }, Belohnung = { Energie = 20000000, XP = 2200 } },
		},
		Gegner = { { Typ = "SternBot", Anzahl = 5 }, { Typ = "Kometdrohne", Anzahl = 3 }, { Typ = "Teleskopschuetze", Anzahl = 2 } },
		Stimmung = { Uhrzeit = 22.5, Nebel = Color3.fromRGB(150, 140, 230), Dichte = 0.3, Toenung = Color3.fromRGB(235, 232, 255), Funken = Color3.fromRGB(230, 240, 255) },
		Boss = "KometKasimir",
		Ei = "SternwarteEi",
		Coop = { "Konsole", "Bruecke", "Tuer" },
	},
	{
		Id = "Tiefsee",
		Name = "Versunkenes Uhrwerk",
		Beschreibung = "Ein uraltes Uhrwerk am Meeresgrund. Blubberblasen, Korallen – und Kapitän Ankerzahn.",
		Farben = {
			Boden = Color3.fromRGB(95, 190, 185),
			Akzent = Color3.fromRGB(220, 150, 90),
			Plattform = Color3.fromRGB(220, 250, 245),
			Deko = Color3.fromRGB(255, 145, 170),
		},
		Schwierigkeit = 2.4,
		FreischaltLevel = 50,
		Energiewert = 5000,
		Strecken = {
			{ Name = "Blubber-Bahn", Abschnitte = 17, Hindernisse = { "Foerderband", "Bewegt", "Wackel", "Sprungpad" }, Belohnung = { Energie = 90000000, XP = 2000 } },
			{ Name = "Korallen-Kreisel", Abschnitte = 18, Hindernisse = { "Zahnrad", "Drehring", "Pendel", "Funken" }, Belohnung = { Energie = 130000000, XP = 2400 } },
			{ Name = "Tiefsee-Taktgeber", Abschnitte = 20, Hindernisse = { "Zahnrad", "Pendel", "Laser", "Drehring", "Zeitplattform", "Foerderband", "Wackel" }, Belohnung = { Energie = 200000000, XP = 3000 } },
		},
		Gegner = { { Typ = "TaucherBot", Anzahl = 5 }, { Typ = "Quallendrohne", Anzahl = 3 }, { Typ = "Ankerschuetze", Anzahl = 2 } },
		Stimmung = { Uhrzeit = 15, Nebel = Color3.fromRGB(110, 200, 215), Dichte = 0.42, Toenung = Color3.fromRGB(215, 245, 250), Funken = Color3.fromRGB(190, 255, 255) },
		Boss = "KapitaenAnkerzahn",
		Ei = "TiefseeEi",
		Coop = { "Bruecke", "Tuer", "Konsole" },
	},
}

-- 🏝️ Stimmung im Hub
Zones.HubStimmung = { Uhrzeit = 13.5, Nebel = Color3.fromRGB(238, 242, 250), Dichte = 0.22, Toenung = Color3.fromRGB(255, 255, 255), Funken = Color3.fromRGB(255, 230, 160) }
-- 🗼 Stimmung im Endlos-Turm (Abendrot) und 🏡 auf der eigenen Werkstatt-Insel (gemütlicher Vormittag)
Zones.TurmStimmung = { Uhrzeit = 18.9, Nebel = Color3.fromRGB(230, 190, 255), Dichte = 0.3, Toenung = Color3.fromRGB(250, 238, 255), Funken = Color3.fromRGB(220, 190, 255) }
Zones.InselStimmung = { Uhrzeit = 10.5, Nebel = Color3.fromRGB(230, 245, 255), Dichte = 0.2, Toenung = Color3.fromRGB(255, 250, 240), Funken = Color3.fromRGB(255, 240, 170) }

-- 📋 Hinweis-Schilder (erscheinen in Zonen mit Tutorial = true vor dem ersten Hindernis jeder Art)
Zones.Hinweise = {
	Start = "🟢 Leicht   🟡 Normal   🔴 Profi\nWähle deine Bahn!",
	Sprung = "Springe mit LEERTASTE\n(Handy: Sprung-Knopf)",
	Zahnrad = "Spring aufs Zahnrad –\nes nimmt dich mit!",
	Pendel = "Warte, bis das Pendel\nvorbei ist!",
	Foerderband = "Förderbänder schieben dich.\nLauf dagegen!",
	Bewegt = "Spring, wenn die Plattform\nnah ist!",
	Zeitplattform = "Diese Plattformen verschwinden\nim Takt. Wenn sie blinken: schnell!",
	Wackel = "Wackelplatten kippen.\nBleib in der Mitte!",
	Laser = "Laser gehen an und aus.\nWarte auf AUS!",
	Sprungpad = "Lauf auf die Feder\nund flieg hoch!",
	Funken = "Funken! Nur auf die\nhellen Felder treten!",
	Drehring = "Die Ringe drehen sich.\nSpring auf die Blöcke!",
	Checkpoint = "Checkpoint! Hier geht's\nweiter, wenn du fällst.",
	Faehigkeiten = "Q = Zeit verlangsamen\nX = Zurückspulen  R = Sprint",
	Energie = "Klicke Kristalle und lauf\ndurch das Feld für Energie ⚡",
	Gegner = "Rost-Bots! Spring drauf\noder wirf Zeit (F) 🌀",
	Boss = "Boss! Achte auf die\nroten Warnflächen!",
}

return Zones
