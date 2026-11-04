--[[
	🎵 ASSETS – Töne, Musik, Bilder, Meshes
	Alles hier sind PLATZHALTER. Ersetze sie durch eigene IDs aus dem Creator Store:
	  1. Im Studio: Toolbox → Audio/Bilder suchen → Rechtsklick → "Copy Asset ID"
	  2. Hier eintragen als "rbxassetid://1234567890"
	Leerer Text "" = nichts abspielen / nichts anzeigen (das Spiel läuft trotzdem).

	"rbxasset://sounds/..." sind eingebaute Roblox-Töne, die ohne Upload funktionieren.
]]

local Assets = {}

Assets.Sounds = {
	Klick = "rbxasset://sounds/electronicpingshort.wav", -- Kristall angeklickt
	Menue = "rbxasset://sounds/clickfast.wav", -- Button im Menü
	Kaufen = "rbxasset://sounds/electronicpingshort.wav", -- Upgrade gekauft
	Fehler = "rbxasset://sounds/clickfast.wav", -- nicht genug Energie
	Ei = "rbxasset://sounds/electronicpingshort.wav", -- Ei öffnet sich
	LevelUp = "rbxasset://sounds/electronicpingshort.wav",
	Checkpoint = "rbxasset://sounds/electronicpingshort.wav",
	Ziel = "rbxasset://sounds/electronicpingshort.wav",
	Sprungpad = "rbxasset://sounds/action_jump.mp3",
	Puff = "rbxasset://sounds/action_jump_land.mp3", -- zurück zum Checkpoint
	Faehigkeit = "rbxasset://sounds/electronicpingshort.wav",
	Treffer = "rbxasset://sounds/action_jump_land.mp3",
	Zahnraeder = "rbxasset://sounds/action_jump_land.mp3", -- Gegner zerfällt
	BossWarnung = "rbxasset://sounds/electronicpingshort.wav",
	Portal = "rbxasset://sounds/electronicpingshort.wav",
	Sammeln = "rbxasset://sounds/electronicpingshort.wav", -- Energie-Kugel
}

-- Lautstärke pro Ton (0 bis 1)
Assets.SoundVolume = {
	Klick = 0.35,
	Sammeln = 0.25,
	Puff = 0.6,
}

-- Hintergrundmusik pro Ort (Index 0 = Hub, 1–5 = Zonen). "" = keine Musik.
Assets.Music = {
	[0] = "",
	[1] = "",
	[2] = "",
	[3] = "",
	[4] = "",
	[5] = "",
	Boss = "",
}

-- Bilder (Texturen). "" = keine Textur.
Assets.Textures = {
	Foerderband = "", -- Pfeil-Textur fürs Förderband
	Holz = "",
}

-- Meshes (optional schönere Formen). "" = Grundformen aus Parts verwenden.
Assets.Meshes = {
	Zahnrad = "",
	Ei = "",
}

-- Himmel (Skybox). "" = Roblox-Standardhimmel.
Assets.Sky = {
	Bk = "",
	Dn = "",
	Ft = "",
	Lf = "",
	Rt = "",
	Up = "",
}

return Assets
