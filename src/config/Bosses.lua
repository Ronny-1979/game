--[[
	👑 BOSSES – ein Boss pro Zone, jeweils 3 Phasen
	Leben steigt automatisch mit der Spielerzahl (+50 % pro weiterem Spieler).
	Vor JEDEM Angriff erscheint eine Warnfläche am Boden. Schnell raus da!

	Angriffe (für "Angriffe" in den Phasen):
	  "Stampfen"     – Kreis um den Boss
	  "Zahnradregen" – Kreise unter allen Spielern, dann fallen Zahnräder
	  "Schockwelle"  – ein Ring läuft nach außen: drüberspringen!
	  "Laserlinie"   – ein Streifen in Richtung eines Spielers
	  "Ansturm"      – der Boss rennt einen Streifen entlang

	Warnzeit = Sekunden, die die Warnfläche zu sehen ist (größer = leichter)
	Pause    = Sekunden zwischen Angriffen
	Nach "AngriffeBisMuede" Angriffen ist der Boss kurz müde (leuchtet) → doppelter Schaden!
]]

local Bosses = {
	ZahnradKoenig = {
		Name = "Zahnrad-König",
		Leben = 500,
		Schaden = 12,
		Groesse = 12,
		Farbe = Color3.fromRGB(230, 185, 80),
		Augenfarbe = Color3.fromRGB(90, 200, 255),
		AngriffeBisMuede = 3,
		MuedeZeit = 4,
		Phasen = {
			{ Angriffe = { "Stampfen", "Zahnradregen" }, Warnzeit = 1.8, Pause = 2.2 },
			{ Angriffe = { "Stampfen", "Zahnradregen", "Schockwelle" }, Warnzeit = 1.6, Pause = 1.9 },
			{ Angriffe = { "Schockwelle", "Zahnradregen", "Stampfen" }, Warnzeit = 1.4, Pause = 1.6 },
		},
		Belohnung = { XP = 300, Energie = 1500, Ei = "WiesenEi", Titel = "Zahnrad-Bezwinger" },
	},
	RostRudi = {
		Name = "Rost-Rudi",
		Leben = 1400,
		Schaden = 14,
		Groesse = 13,
		Farbe = Color3.fromRGB(200, 120, 75),
		Augenfarbe = Color3.fromRGB(255, 220, 90),
		AngriffeBisMuede = 3,
		MuedeZeit = 4,
		Phasen = {
			{ Angriffe = { "Ansturm", "Stampfen" }, Warnzeit = 1.7, Pause = 2.1 },
			{ Angriffe = { "Ansturm", "Zahnradregen", "Stampfen" }, Warnzeit = 1.5, Pause = 1.8 },
			{ Angriffe = { "Ansturm", "Schockwelle", "Zahnradregen" }, Warnzeit = 1.35, Pause = 1.5 },
		},
		Belohnung = { XP = 800, Energie = 20000, Ei = "WerkstattEi", Titel = "Rostbuster" },
	},
	PendelPaula = {
		Name = "Pendel-Paula",
		Leben = 3000,
		Schaden = 16,
		Groesse = 14,
		Farbe = Color3.fromRGB(175, 140, 225),
		Augenfarbe = Color3.fromRGB(255, 255, 170),
		AngriffeBisMuede = 3,
		MuedeZeit = 3.5,
		Phasen = {
			{ Angriffe = { "Laserlinie", "Zahnradregen" }, Warnzeit = 1.6, Pause = 2.0 },
			{ Angriffe = { "Laserlinie", "Schockwelle", "Zahnradregen" }, Warnzeit = 1.45, Pause = 1.7 },
			{ Angriffe = { "Laserlinie", "Schockwelle", "Ansturm", "Zahnradregen" }, Warnzeit = 1.3, Pause = 1.4 },
		},
		Belohnung = { XP = 1800, Energie = 200000, Ei = "SchluchtEi", Titel = "Pendel-Profi" },
	},
	KristallKoloss = {
		Name = "Kristall-Koloss",
		Leben = 5500,
		Schaden = 18,
		Groesse = 15,
		Farbe = Color3.fromRGB(140, 220, 240),
		Augenfarbe = Color3.fromRGB(255, 120, 220),
		AngriffeBisMuede = 4,
		MuedeZeit = 3.5,
		Phasen = {
			{ Angriffe = { "Laserlinie", "Stampfen", "Zahnradregen" }, Warnzeit = 1.5, Pause = 1.8 },
			{ Angriffe = { "Schockwelle", "Laserlinie", "Ansturm" }, Warnzeit = 1.35, Pause = 1.6 },
			{ Angriffe = { "Schockwelle", "Zahnradregen", "Laserlinie", "Ansturm" }, Warnzeit = 1.2, Pause = 1.3 },
		},
		Belohnung = { XP = 3500, Energie = 2000000, Ei = "KristallEi", Titel = "Kristall-Held" },
	},
	MeisterUnruh = {
		Name = "Meister Unruh",
		Leben = 9000,
		Schaden = 20,
		Groesse = 18,
		Farbe = Color3.fromRGB(235, 195, 100),
		Augenfarbe = Color3.fromRGB(120, 255, 180),
		AngriffeBisMuede = 4,
		MuedeZeit = 3,
		Phasen = {
			{ Angriffe = { "Stampfen", "Zahnradregen", "Laserlinie" }, Warnzeit = 1.45, Pause = 1.7 },
			{ Angriffe = { "Schockwelle", "Ansturm", "Zahnradregen", "Laserlinie" }, Warnzeit = 1.3, Pause = 1.45 },
			{ Angriffe = { "Schockwelle", "Laserlinie", "Ansturm", "Zahnradregen", "Stampfen" }, Warnzeit = 1.15, Pause = 1.2 },
		},
		Belohnung = { XP = 7000, Energie = 20000000, Ei = "UhrwerkEi", Titel = "Meister der Zeit" },
	},
}

return Bosses
