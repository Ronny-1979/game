--[[
	🐾 PETS – kleine Uhr-Roboter
	Jedes Pet hat:
	  Name, Seltenheit ("Gewoehnlich", "Selten", "Episch", "Legendaer"),
	  Multiplikator (1.5 = +50 % Energie), Farbe, Form ("Kugel", "Wuerfel", "Zylinder", "Zahnrad"),
	  Beschreibung (wie es aussieht).

	Eier: Preis + Waehrung ("Energie" oder "Rebirth" = Rebirth-Punkte),
	  Chancen = Gewichte (größere Zahl = häufiger). Prozent werden automatisch berechnet.

	Beispiel für ein neues Pet:
	Pets.Liste.Kuckuck = {
		Name = "Kuckuck", Seltenheit = "Selten", Multiplikator = 1.6,
		Farbe = Color3.fromRGB(255, 200, 100), Form = "Kugel",
		Beschreibung = "Ein kleiner Vogel aus Holz mit Federflügeln",
	}
	…und dann bei einem Ei in "Chancen" eintragen: Kuckuck = 20,
]]

local Pets = {}

Pets.Seltenheiten = {
	Gewoehnlich = { Name = "Gewöhnlich", Farbe = Color3.fromRGB(190, 190, 190), Rang = 1 },
	Selten = { Name = "Selten", Farbe = Color3.fromRGB(90, 170, 255), Rang = 2 },
	Episch = { Name = "Episch", Farbe = Color3.fromRGB(190, 110, 255), Rang = 3 },
	Legendaer = { Name = "Legendär", Farbe = Color3.fromRGB(255, 200, 50), Rang = 4 },
}

Pets.Liste = {
	-- 🌼 Wiesen-Ei
	Tick = { Name = "Tick", Seltenheit = "Gewoehnlich", Multiplikator = 1.15, Farbe = Color3.fromRGB(255, 220, 150), Form = "Kugel", Beschreibung = "Runder Messing-Wecker mit Knopfaugen" },
	Tack = { Name = "Tack", Seltenheit = "Gewoehnlich", Multiplikator = 1.2, Farbe = Color3.fromRGB(170, 230, 160), Form = "Wuerfel", Beschreibung = "Grüner Würfel mit kleinem Zahnrad oben" },
	Federling = { Name = "Federling", Seltenheit = "Selten", Multiplikator = 1.5, Farbe = Color3.fromRGB(140, 200, 255), Form = "Zylinder", Beschreibung = "Hüpft auf einer Sprungfeder" },
	Kuckucki = { Name = "Kuckucki", Seltenheit = "Episch", Multiplikator = 2.2, Farbe = Color3.fromRGB(255, 170, 200), Form = "Kugel", Beschreibung = "Rosa Kuckucksuhr-Vogel" },
	Goldwecker = { Name = "Goldwecker", Seltenheit = "Legendaer", Multiplikator = 4, Farbe = Color3.fromRGB(255, 205, 60), Form = "Zahnrad", Beschreibung = "Glänzendes Gold-Zahnrad mit Krone" },

	-- 🔧 Werkstatt-Ei
	Schraubi = { Name = "Schraubi", Seltenheit = "Gewoehnlich", Multiplikator = 1.4, Farbe = Color3.fromRGB(200, 200, 210), Form = "Zylinder", Beschreibung = "Kleine Schraube mit großen Augen" },
	Mutterli = { Name = "Mutterli", Seltenheit = "Gewoehnlich", Multiplikator = 1.5, Farbe = Color3.fromRGB(220, 160, 110), Form = "Zahnrad", Beschreibung = "Kupferne Schraubenmutter" },
	Oelkaennchen = { Name = "Ölkännchen", Seltenheit = "Selten", Multiplikator = 2.0, Farbe = Color3.fromRGB(120, 180, 210), Form = "Zylinder", Beschreibung = "Blaues Ölkännchen mit Tülle" },
	Funkenfuchs = { Name = "Funkenfuchs", Seltenheit = "Episch", Multiplikator = 3.0, Farbe = Color3.fromRGB(255, 140, 70), Form = "Wuerfel", Beschreibung = "Oranger Blech-Fuchs, der Funken sprüht" },
	TurboTom = { Name = "Turbo-Tom", Seltenheit = "Legendaer", Multiplikator = 6, Farbe = Color3.fromRGB(255, 90, 90), Form = "Kugel", Beschreibung = "Roter Rennroboter mit Raketen" },

	-- 🌉 Schlucht-Ei
	Pendlino = { Name = "Pendlino", Seltenheit = "Gewoehnlich", Multiplikator = 2.2, Farbe = Color3.fromRGB(210, 190, 250), Form = "Kugel", Beschreibung = "Schwingt immer hin und her" },
	Echo = { Name = "Echo", Seltenheit = "Gewoehnlich", Multiplikator = 2.4, Farbe = Color3.fromRGB(170, 220, 240), Form = "Wuerfel", Beschreibung = "Wiederholt jedes Ticken" },
	Sanduhrchen = { Name = "Sanduhrchen", Seltenheit = "Selten", Multiplikator = 3.2, Farbe = Color3.fromRGB(250, 220, 140), Form = "Zylinder", Beschreibung = "Kleine Sanduhr mit Füßchen" },
	Glockenbaer = { Name = "Glockenbär", Seltenheit = "Episch", Multiplikator = 4.5, Farbe = Color3.fromRGB(200, 150, 110), Form = "Kugel", Beschreibung = "Teddy mit Glocken-Bauch" },
	ChronoDrache = { Name = "Chrono-Drache", Seltenheit = "Legendaer", Multiplikator = 9, Farbe = Color3.fromRGB(150, 110, 240), Form = "Zahnrad", Beschreibung = "Lila Drache aus Zahnrädern" },

	-- 💎 Kristall-Ei
	Prisma = { Name = "Prisma", Seltenheit = "Gewoehnlich", Multiplikator = 3.5, Farbe = Color3.fromRGB(200, 240, 255), Form = "Wuerfel", Beschreibung = "Durchsichtiger Kristallwürfel" },
	Funkel = { Name = "Funkel", Seltenheit = "Gewoehnlich", Multiplikator = 3.8, Farbe = Color3.fromRGB(255, 200, 240), Form = "Kugel", Beschreibung = "Glitzert in allen Farben" },
	Quarzi = { Name = "Quarzi", Seltenheit = "Selten", Multiplikator = 5, Farbe = Color3.fromRGB(180, 160, 255), Form = "Zylinder", Beschreibung = "Quarz-Roboter mit Lichtern" },
	RegenbogenRobo = { Name = "Regenbogen-Robo", Seltenheit = "Episch", Multiplikator = 7, Farbe = Color3.fromRGB(120, 230, 200), Form = "Wuerfel", Beschreibung = "Wechselt seine Farbe" },
	KristallPhoenix = { Name = "Kristall-Phönix", Seltenheit = "Legendaer", Multiplikator = 14, Farbe = Color3.fromRGB(110, 220, 255), Form = "Zahnrad", Beschreibung = "Leuchtender Vogel aus Kristall" },

	-- 🕰️ Uhrwerk-Ei
	Zahnkrone = { Name = "Zahnkrone", Seltenheit = "Gewoehnlich", Multiplikator = 5.5, Farbe = Color3.fromRGB(240, 200, 110), Form = "Zahnrad", Beschreibung = "Trägt eine Krone aus Zähnen" },
	Unruhchen = { Name = "Unruhchen", Seltenheit = "Gewoehnlich", Multiplikator = 6, Farbe = Color3.fromRGB(215, 130, 90), Form = "Kugel", Beschreibung = "Kann nie stillsitzen" },
	Minutenmaus = { Name = "Minutenmaus", Seltenheit = "Selten", Multiplikator = 8, Farbe = Color3.fromRGB(190, 190, 200), Form = "Wuerfel", Beschreibung = "Maus mit Zeiger-Schwanz" },
	Stundenhase = { Name = "Stundenhase", Seltenheit = "Episch", Multiplikator = 11, Farbe = Color3.fromRGB(255, 240, 230), Form = "Zylinder", Beschreibung = "Hase mit Taschenuhr" },
	Ewigkeitsuhr = { Name = "Ewigkeitsuhr", Seltenheit = "Legendaer", Multiplikator = 22, Farbe = Color3.fromRGB(255, 225, 120), Form = "Zahnrad", Beschreibung = "Die schönste Uhr der Insel" },

	-- ♻️ Rebirth-Ei
	Zeitstern = { Name = "Zeitstern", Seltenheit = "Episch", Multiplikator = 8, Farbe = Color3.fromRGB(255, 250, 160), Form = "Kugel", Beschreibung = "Ein kleiner Stern, der tickt" },
	Phoenixuhr = { Name = "Phönix-Uhr", Seltenheit = "Legendaer", Multiplikator = 18, Farbe = Color3.fromRGB(255, 120, 80), Form = "Zahnrad", Beschreibung = "Wird bei jedem Rebirth neu geboren" },
	Galaxis = { Name = "Galaxis-Ticker", Seltenheit = "Legendaer", Multiplikator = 30, Farbe = Color3.fromRGB(120, 100, 230), Form = "Zylinder", Beschreibung = "Hat eine Galaxie im Bauch" },
}

Pets.Eier = {
	WiesenEi = {
		Name = "Wiesen-Ei",
		Zone = 1,
		Preis = 150,
		Waehrung = "Energie",
		Farbe = Color3.fromRGB(180, 235, 160),
		Chancen = { Tick = 45, Tack = 35, Federling = 15, Kuckucki = 4.5, Goldwecker = 0.5 },
	},
	WerkstattEi = {
		Name = "Werkstatt-Ei",
		Zone = 2,
		Preis = 3000,
		Waehrung = "Energie",
		Farbe = Color3.fromRGB(230, 170, 120),
		Chancen = { Schraubi = 45, Mutterli = 35, Oelkaennchen = 15, Funkenfuchs = 4.5, TurboTom = 0.5 },
	},
	SchluchtEi = {
		Name = "Schlucht-Ei",
		Zone = 3,
		Preis = 40000,
		Waehrung = "Energie",
		Farbe = Color3.fromRGB(205, 185, 245),
		Chancen = { Pendlino = 45, Echo = 35, Sanduhrchen = 15, Glockenbaer = 4.5, ChronoDrache = 0.5 },
	},
	KristallEi = {
		Name = "Kristall-Ei",
		Zone = 4,
		Preis = 500000,
		Waehrung = "Energie",
		Farbe = Color3.fromRGB(170, 235, 250),
		Chancen = { Prisma = 45, Funkel = 35, Quarzi = 15, RegenbogenRobo = 4.5, KristallPhoenix = 0.5 },
	},
	UhrwerkEi = {
		Name = "Uhrwerk-Ei",
		Zone = 5,
		Preis = 6000000,
		Waehrung = "Energie",
		Farbe = Color3.fromRGB(245, 210, 120),
		Chancen = { Zahnkrone = 45, Unruhchen = 35, Minutenmaus = 15, Stundenhase = 4.5, Ewigkeitsuhr = 0.5 },
	},
	RebirthEi = {
		Name = "Rebirth-Ei",
		Zone = 1,
		Preis = 1,
		Waehrung = "Rebirth",
		Farbe = Color3.fromRGB(255, 150, 120),
		Chancen = { Zeitstern = 70, Phoenixuhr = 25, Galaxis = 5 },
	},
}

-- Reihenfolge der Eier an der Eier-Station im Hub
Pets.EierReihenfolge = { "WiesenEi", "WerkstattEi", "SchluchtEi", "KristallEi", "UhrwerkEi", "RebirthEi" }

return Pets
