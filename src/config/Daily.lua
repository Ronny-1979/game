--[[
	🎁 DAILY – tägliche Belohnung
	Jeden Tag einmal abholen. Wer jeden Tag kommt, steigt einen Tag weiter (Serie).
	Nach Tag 7 geht es wieder bei Tag 1 los. Einen Tag verpasst? Dann beginnt die Serie neu.

	Energie wird mit dem Energiewert der besten freigeschalteten Zone und deinem
	Energie-Multiplikator verrechnet – so lohnt es sich auch später noch.
	Ei = "BestesEi" → ein Ei der besten freigeschalteten Zone.
]]
local Daily = {}

Daily.Belohnungen = {
	{ Symbol = "⚡", Energie = 100, XP = 30 },
	{ Symbol = "⚡", Energie = 200, XP = 50 },
	{ Symbol = "⭐", Energie = 300, XP = 120 },
	{ Symbol = "⚡", Energie = 500, XP = 80 },
	{ Symbol = "🥚", Energie = 400, XP = 100, Ei = "BestesEi" },
	{ Symbol = "⚡", Energie = 900, XP = 150 },
	{ Symbol = "🎉", Energie = 2000, XP = 300, Ei = "BestesEi" },
}

return Daily
