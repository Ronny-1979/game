--[[
	🤖 ENEMIES – Rost-Bots und ihre Freunde
	Leben     = wie viele Treffer-Punkte
	Schaden   = so viel Leben verliert ein Spieler bei Berührung (klein halten!)
	Tempo     = Laufgeschwindigkeit
	XP/Energie= Belohnung beim Besiegen
	Sichtweite= ab dieser Entfernung verfolgen sie dich
	Angriffsmuster:
	  "Ramme"   – bleibt kurz stehen (blinkt!) und rammt dann geradeaus
	  "Huepfer" – hüpft auf dich zu
	  "Kreisel" – dreht sich und hat einen größeren Trefferbereich
	Groesse   = Größe in Studs
]]

local Enemies = {
	RostBot = {
		Name = "Rost-Bot",
		Leben = 40,
		Schaden = 8,
		Tempo = 9,
		XP = 12,
		Energie = 20,
		Sichtweite = 35,
		Angriffsmuster = "Ramme",
		Groesse = 4,
		Farbe = Color3.fromRGB(200, 120, 80),
		Augenfarbe = Color3.fromRGB(120, 230, 255),
		Respawnzeit = 8,
	},
	SchraubenBot = {
		Name = "Schrauben-Bot",
		Leben = 90,
		Schaden = 10,
		Tempo = 11,
		XP = 30,
		Energie = 160,
		Sichtweite = 40,
		Angriffsmuster = "Kreisel",
		Groesse = 4.5,
		Farbe = Color3.fromRGB(170, 170, 185),
		Augenfarbe = Color3.fromRGB(255, 210, 90),
		Respawnzeit = 8,
	},
	PendelBot = {
		Name = "Pendel-Bot",
		Leben = 180,
		Schaden = 12,
		Tempo = 12,
		XP = 60,
		Energie = 1600,
		Sichtweite = 45,
		Angriffsmuster = "Huepfer",
		Groesse = 5,
		Farbe = Color3.fromRGB(160, 130, 210),
		Augenfarbe = Color3.fromRGB(255, 255, 160),
		Respawnzeit = 9,
	},
	KristallBot = {
		Name = "Kristall-Bot",
		Leben = 320,
		Schaden = 14,
		Tempo = 13,
		XP = 110,
		Energie = 14000,
		Sichtweite = 45,
		Angriffsmuster = "Ramme",
		Groesse = 5,
		Farbe = Color3.fromRGB(130, 210, 235),
		Augenfarbe = Color3.fromRGB(255, 130, 220),
		Respawnzeit = 9,
	},
	UhrwerkWaechter = {
		Name = "Uhrwerk-Wächter",
		Leben = 550,
		Schaden = 16,
		Tempo = 14,
		XP = 200,
		Energie = 120000,
		Sichtweite = 50,
		Angriffsmuster = "Kreisel",
		Groesse = 6,
		Farbe = Color3.fromRGB(225, 180, 90),
		Augenfarbe = Color3.fromRGB(120, 255, 170),
		Respawnzeit = 10,
	},
}

return Enemies
