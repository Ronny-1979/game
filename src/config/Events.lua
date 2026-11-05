--[[
	🎉 EVENTS – automatische Bonus-Zeiten
	Events laufen von selbst nach Wochentag oder Datum (Uhrzeit: Deutschland, ungefähr).
	Laufen mehrere gleichzeitig, werden die Boni multipliziert.

	Boni:
	  Energie = Energie-Multiplikator (2 = doppelt)
	  XP      = XP-Multiplikator
	  Glueck  = seltene Pets (Episch + Legendär) kommen so viel öfter aus Eiern

	Wochen-Events: Tage = Liste der Wochentage (1 = Sonntag, 2 = Montag … 7 = Samstag)
	Saison-Events: Von/Bis = { Monat, Tag } (beide Tage zählen mit; geht auch über Silvester)
	Deko (optional): "Kuerbis" oder "Schnee" → passende Deko im Hub
]]
local Events = {}

Events.Woche = {
	{ Id = "Wochenende", Name = "⚡ Doppel-Energie-Wochenende", Tage = { 7, 1 }, Energie = 2 },
	{ Id = "XPMittwoch", Name = "⭐ Doppel-XP-Mittwoch", Tage = { 4 }, XP = 2 },
	{ Id = "GluecksFreitag", Name = "🍀 Glücks-Freitag", Tage = { 6 }, Glueck = 2 },
}

Events.Saison = {
	{ Id = "Halloween", Name = "🎃 Halloween im Uhrwerk", Von = { 10, 20 }, Bis = { 11, 3 }, Energie = 1.5, Glueck = 1.5, Deko = "Kuerbis" },
	{ Id = "Winter", Name = "❄️ Winter-Zauber", Von = { 12, 15 }, Bis = { 1, 6 }, Energie = 1.5, XP = 1.5, Deko = "Schnee" },
	{ Id = "Sommer", Name = "☀️ Sommerferien-Bonus", Von = { 7, 1 }, Bis = { 8, 31 }, Energie = 1.25, XP = 1.25 },
}

-- Zeitverschiebung zu UTC in Stunden (Deutschland: 1 im Winter, 2 im Sommer – 1 reicht für Tageswechsel)
Events.Zeitzone = 1

-- 👥 Freunde-Bonus: pro Freund auf demselben Server mehr Energie
Events.Freunde = {
	ProFreund = 0.1, -- +10 % pro Freund
	Maximal = 0.5, -- höchstens +50 %
}

return Events
