--[[
	🎓 CLASSES – drei Klassen
	Boni verändern Werte (Stats):
	  { Stat = "WalkSpeed", Plus = 4 }   → +4 Lauftempo
	  { Stat = "SlowFactor", Mal = 0.75 } → Verlangsamen wirkt stärker (kleiner = langsamer)
	Erlaubte Stats: siehe KONFIG-ANLEITUNG.md
]]

local Classes = {
	Zeitwaechter = {
		Name = "Zeitwächter",
		Symbol = "⏳",
		Farbe = Color3.fromRGB(120, 170, 255),
		Beschreibung = "Meister der Zeit-Blase. Verlangsamen hält länger, ist größer und stärker.",
		Startfaehigkeit = "Verlangsamen",
		Boni = {
			{ Stat = "SlowDuration", Plus = 1.5 },
			{ Stat = "SlowRadius", Plus = 6 },
			{ Stat = "SlowFactor", Mal = 0.75 },
			{ Stat = "MaxHealth", Plus = 20 },
		},
	},
	Mechaniker = {
		Name = "Mechaniker",
		Symbol = "🔧",
		Farbe = Color3.fromRGB(255, 170, 90),
		Beschreibung = "Pets sind stärker und du kannst Hilfsplattformen bauen (Taste G).",
		Startfaehigkeit = "Hilfsplattform",
		Boni = {
			{ Stat = "PetPower", Mal = 1.3 },
			{ Stat = "PlatformDuration", Plus = 2 },
			{ Stat = "ThrowDamage", Plus = 5 },
		},
	},
	Laeufer = {
		Name = "Läufer",
		Symbol = "👟",
		Farbe = Color3.fromRGB(120, 230, 150),
		Beschreibung = "Schneller unterwegs. Beschleunigen ist stärker und lädt schneller.",
		Startfaehigkeit = "Beschleunigen",
		Boni = {
			{ Stat = "WalkSpeed", Plus = 4 },
			{ Stat = "BoostSpeed", Plus = 8 },
			{ Stat = "BoostDuration", Plus = 1 },
			{ Stat = "BoostCooldown", Plus = -3 },
		},
	},
}

Classes.Reihenfolge = { "Zeitwaechter", "Mechaniker", "Laeufer" }

return Classes
