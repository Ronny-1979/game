--[[
	🌳 SKILLS – Zeit-Fähigkeiten und Skill-Bäume

	1) Faehigkeiten: Grundwerte jeder Zeit-Fähigkeit
	   Abklingzeit = Sekunden bis zur nächsten Nutzung
	   Kosten      = Zeit-Energie pro Nutzung
	   Taste       = Taste am PC (Handy/Tablet: Knopf am Bildschirm)

	2) Baeume: pro Klasse 3 Äste mit je 4 Knoten.
	   Ein Knoten braucht immer den Knoten davor im selben Ast.
	   Kosten = Skill-Punkte (1 Punkt pro Level).
	   Effekte wie bei den Klassen: { Stat = "...", Plus = 1 } oder { Stat = "...", Mal = 1.2 }
]]

local Skills = {}

Skills.Faehigkeiten = {
	Verlangsamen = {
		Name = "Verlangsamen",
		Symbol = "🐢",
		Taste = "Q",
		Beschreibung = "Hindernisse und Gegner in der Nähe werden langsamer.",
		Abklingzeit = 12,
		Kosten = 10,
		Dauer = 4, -- Sekunden
		Radius = 24, -- Studs
		Faktor = 0.4, -- 0.4 = 40 % Tempo
	},
	Zurueckspulen = {
		Name = "Zurückspulen",
		Symbol = "⏪",
		Taste = "X", -- (E ist schon für ProximityPrompts belegt)
		Beschreibung = "Springe dorthin zurück, wo du vor 3 Sekunden warst.",
		Abklingzeit = 8,
		Kosten = 5,
		Sekunden = 3,
	},
	Beschleunigen = {
		Name = "Beschleunigen",
		Symbol = "⚡",
		Taste = "R",
		Beschreibung = "Kurzer Sprint mit Funkenspur.",
		Abklingzeit = 10,
		Kosten = 8,
		Dauer = 3,
		Tempo = 14, -- zusätzliches Lauftempo
	},
	ZeitWurf = {
		Name = "Zeit-Wurf",
		Symbol = "🌀",
		Taste = "F",
		Beschreibung = "Wirf eine Zeit-Scheibe auf Gegner und Bosse.",
		Abklingzeit = 1.0,
		Kosten = 0,
		Schaden = 20,
		Reichweite = 70,
		Geschwindigkeit = 110,
	},
	Hilfsplattform = {
		Name = "Hilfsplattform",
		Symbol = "🧱",
		Taste = "G",
		Beschreibung = "Baut kurz eine Messing-Plattform vor dir.",
		Abklingzeit = 6,
		Kosten = 6,
		Dauer = 5,
		Groesse = 8,
		NurKlasse = "Mechaniker",
	},
}

-- Reihenfolge in der Skill-Leiste
Skills.Reihenfolge = { "Verlangsamen", "Zurueckspulen", "Beschleunigen", "ZeitWurf", "Hilfsplattform" }

Skills.Baeume = {
	Zeitwaechter = {
		{
			Name = "Zeitblase",
			Knoten = {
				{ Id = "ZW_A1", Name = "Große Blase", Beschreibung = "+5 Radius beim Verlangsamen", Kosten = 1, Effekte = { { Stat = "SlowRadius", Plus = 5 } } },
				{ Id = "ZW_A2", Name = "Lange Blase", Beschreibung = "+1,5 s Verlangsamen", Kosten = 1, Effekte = { { Stat = "SlowDuration", Plus = 1.5 } } },
				{ Id = "ZW_A3", Name = "Zähe Zeit", Beschreibung = "Verlangsamen wirkt 20 % stärker", Kosten = 2, Effekte = { { Stat = "SlowFactor", Mal = 0.8 } } },
				{ Id = "ZW_A4", Name = "Zeitmeister", Beschreibung = "-4 s Abklingzeit Verlangsamen", Kosten = 3, Effekte = { { Stat = "SlowCooldown", Plus = -4 } } },
			},
		},
		{
			Name = "Rückspul-Kunst",
			Knoten = {
				{ Id = "ZW_B1", Name = "Schnelles Spulen", Beschreibung = "-2 s Abklingzeit Zurückspulen", Kosten = 1, Effekte = { { Stat = "RewindCooldown", Plus = -2 } } },
				{ Id = "ZW_B2", Name = "Tiefe Erinnerung", Beschreibung = "+1 s weiter zurück", Kosten = 1, Effekte = { { Stat = "RewindSeconds", Plus = 1 } } },
				{ Id = "ZW_B3", Name = "Gratis-Spulen", Beschreibung = "Zurückspulen kostet nichts", Kosten = 2, Effekte = { { Stat = "RewindCost", Mal = 0 } } },
				{ Id = "ZW_B4", Name = "Zeitschleife", Beschreibung = "-2 s Abklingzeit Zurückspulen", Kosten = 3, Effekte = { { Stat = "RewindCooldown", Plus = -2 } } },
			},
		},
		{
			Name = "Hüter",
			Knoten = {
				{ Id = "ZW_C1", Name = "Zähes Uhrwerk", Beschreibung = "+20 Leben", Kosten = 1, Effekte = { { Stat = "MaxHealth", Plus = 20 } } },
				{ Id = "ZW_C2", Name = "Scharfe Scheibe", Beschreibung = "+25 % Wurf-Schaden", Kosten = 1, Effekte = { { Stat = "ThrowDamage", Mal = 1.25 } } },
				{ Id = "ZW_C3", Name = "Weisheit", Beschreibung = "+15 % XP", Kosten = 2, Effekte = { { Stat = "XPMult", Plus = 0.15 } } },
				{ Id = "ZW_C4", Name = "Ewiger Wächter", Beschreibung = "+40 Leben", Kosten = 3, Effekte = { { Stat = "MaxHealth", Plus = 40 } } },
			},
		},
	},
	Mechaniker = {
		{
			Name = "Pet-Werkstatt",
			Knoten = {
				{ Id = "ME_A1", Name = "Ölwechsel", Beschreibung = "Pets +10 % stärker", Kosten = 1, Effekte = { { Stat = "PetPower", Mal = 1.1 } } },
				{ Id = "ME_A2", Name = "Feintuning", Beschreibung = "Pets +15 % stärker", Kosten = 1, Effekte = { { Stat = "PetPower", Mal = 1.15 } } },
				{ Id = "ME_A3", Name = "Turbo-Pets", Beschreibung = "Pets +20 % stärker", Kosten = 2, Effekte = { { Stat = "PetPower", Mal = 1.2 } } },
				{ Id = "ME_A4", Name = "Meister-Bastler", Beschreibung = "+15 % Energie", Kosten = 3, Effekte = { { Stat = "EnergyMult", Mal = 1.15 } } },
			},
		},
		{
			Name = "Baumeister",
			Knoten = {
				{ Id = "ME_B1", Name = "Breite Bretter", Beschreibung = "Hilfsplattform +3 groß", Kosten = 1, Effekte = { { Stat = "PlatformSize", Plus = 3 } } },
				{ Id = "ME_B2", Name = "Stabil gebaut", Beschreibung = "Hilfsplattform +2 s", Kosten = 1, Effekte = { { Stat = "PlatformDuration", Plus = 2 } } },
				{ Id = "ME_B3", Name = "Schnellbau", Beschreibung = "-2 s Abklingzeit Plattform", Kosten = 2, Effekte = { { Stat = "PlatformCooldown", Plus = -2 } } },
				{ Id = "ME_B4", Name = "Gratis-Bau", Beschreibung = "Plattformen kosten nichts", Kosten = 3, Effekte = { { Stat = "PlatformCost", Mal = 0 } } },
			},
		},
		{
			Name = "Sammler",
			Knoten = {
				{ Id = "ME_C1", Name = "Magnet", Beschreibung = "+3 Sammelradius", Kosten = 1, Effekte = { { Stat = "CollectRadius", Plus = 3 } } },
				{ Id = "ME_C2", Name = "Kräftiger Klick", Beschreibung = "+20 % Klickkraft", Kosten = 1, Effekte = { { Stat = "ClickPower", Mal = 1.2 } } },
				{ Id = "ME_C3", Name = "Wurf-Mechanik", Beschreibung = "+30 % Wurf-Schaden", Kosten = 2, Effekte = { { Stat = "ThrowDamage", Mal = 1.3 } } },
				{ Id = "ME_C4", Name = "Super-Magnet", Beschreibung = "+5 Sammelradius", Kosten = 3, Effekte = { { Stat = "CollectRadius", Plus = 5 } } },
			},
		},
	},
	Laeufer = {
		{
			Name = "Sprinter",
			Knoten = {
				{ Id = "LA_A1", Name = "Flinke Füße", Beschreibung = "+2 Lauftempo", Kosten = 1, Effekte = { { Stat = "WalkSpeed", Plus = 2 } } },
				{ Id = "LA_A2", Name = "Turbo", Beschreibung = "+6 Sprint-Tempo", Kosten = 1, Effekte = { { Stat = "BoostSpeed", Plus = 6 } } },
				{ Id = "LA_A3", Name = "Ausdauer", Beschreibung = "+1,5 s Sprint", Kosten = 2, Effekte = { { Stat = "BoostDuration", Plus = 1.5 } } },
				{ Id = "LA_A4", Name = "Blitz", Beschreibung = "-3 s Abklingzeit Sprint", Kosten = 3, Effekte = { { Stat = "BoostCooldown", Plus = -3 } } },
			},
		},
		{
			Name = "Springer",
			Knoten = {
				{ Id = "LA_B1", Name = "Federbeine", Beschreibung = "+3 Sprungkraft", Kosten = 1, Effekte = { { Stat = "JumpPower", Plus = 3 } } },
				{ Id = "LA_B2", Name = "Stampfer", Beschreibung = "+50 % Sprung-Angriff", Kosten = 1, Effekte = { { Stat = "StompDamage", Mal = 1.5 } } },
				{ Id = "LA_B3", Name = "Kurzes Spulen", Beschreibung = "-2 s Abklingzeit Zurückspulen", Kosten = 2, Effekte = { { Stat = "RewindCooldown", Plus = -2 } } },
				{ Id = "LA_B4", Name = "Superfeder", Beschreibung = "+3 Sprungkraft", Kosten = 3, Effekte = { { Stat = "JumpPower", Plus = 3 } } },
			},
		},
		{
			Name = "Läufer-Glück",
			Knoten = {
				{ Id = "LA_C1", Name = "Feldläufer", Beschreibung = "+30 % Energie in Feldern", Kosten = 1, Effekte = { { Stat = "FieldEnergy", Mal = 1.3 } } },
				{ Id = "LA_C2", Name = "Streckenkenner", Beschreibung = "+15 % XP", Kosten = 1, Effekte = { { Stat = "XPMult", Plus = 0.15 } } },
				{ Id = "LA_C3", Name = "Schnelle Scheibe", Beschreibung = "-0,3 s Wurf-Abklingzeit", Kosten = 2, Effekte = { { Stat = "ThrowCooldown", Plus = -0.3 } } },
				{ Id = "LA_C4", Name = "Glückspilz", Beschreibung = "+15 % Energie", Kosten = 3, Effekte = { { Stat = "EnergyMult", Mal = 1.15 } } },
			},
		},
	},
}

return Skills
