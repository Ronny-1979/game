--[[
	🛒 UPGRADES – was man im Shop kaufen kann
	Kosten für Stufe n = Basiskosten * Kostenfaktor ^ n
	Effekt.Plus = so viel kommt pro Stufe dazu.
	BehaltenBeiRebirth = true → bleibt beim Rebirth erhalten.

	Beispiel für ein neues Upgrade:
	{
		Id = "Glueck",               -- eindeutiger Name ohne Leerzeichen
		Name = "Glück",
		Symbol = "🍀",
		Beschreibung = "Mehr Glück",
		Basiskosten = 100,
		Kostenfaktor = 1.5,
		MaxStufe = 10,
		Effekt = { Stat = "XPMult", Plus = 0.05 },
	},
	Erlaubte Stats: siehe KONFIG-ANLEITUNG.md
]]

local Upgrades = {
	{
		Id = "Klickkraft",
		Name = "Klickkraft",
		Symbol = "👆",
		Beschreibung = "+1 Energie pro Kristall-Klick",
		Basiskosten = 20,
		Kostenfaktor = 1.28,
		MaxStufe = 100,
		Effekt = { Stat = "ClickPower", Plus = 1 },
	},
	{
		Id = "Sammelradius",
		Name = "Sammelradius",
		Symbol = "🧲",
		Beschreibung = "Energie-Kugeln aus größerer Entfernung einsammeln",
		Basiskosten = 60,
		Kostenfaktor = 1.6,
		MaxStufe = 15,
		Effekt = { Stat = "CollectRadius", Plus = 1.5 },
	},
	{
		Id = "LaufBonus",
		Name = "Lauf-Bonus",
		Symbol = "👟",
		Beschreibung = "Mehr Energie beim Laufen durch Energie-Felder",
		Basiskosten = 40,
		Kostenfaktor = 1.35,
		MaxStufe = 60,
		Effekt = { Stat = "FieldEnergy", Plus = 1 },
	},
	{
		Id = "Sprungkraft",
		Name = "Sprungkraft",
		Symbol = "🦘",
		Beschreibung = "Höher springen",
		Basiskosten = 150,
		Kostenfaktor = 2.2,
		MaxStufe = 8,
		Effekt = { Stat = "JumpPower", Plus = 2.5 },
	},
	{
		Id = "PetSlots",
		Name = "Pet-Plätze",
		Symbol = "🐾",
		Beschreibung = "+1 Pet gleichzeitig ausrüsten",
		Basiskosten = 2000,
		Kostenfaktor = 12,
		MaxStufe = 3,
		Effekt = { Stat = "PetSlots", Plus = 1 },
		BehaltenBeiRebirth = true,
	},
	{
		Id = "EnergieMulti",
		Name = "Energie-Multiplikator",
		Symbol = "✨",
		Beschreibung = "+10 % auf alle Energie",
		Basiskosten = 500,
		Kostenfaktor = 1.55,
		MaxStufe = 30,
		Effekt = { Stat = "EnergyMult", Plus = 0.1 },
	},
}

return Upgrades
