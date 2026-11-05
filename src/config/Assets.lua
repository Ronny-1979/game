--[[
	🎵 ASSETS – Töne, Musik, Bilder, Meshes
	Musik: lizenzierte Stücke von APM Music (kostenlos im Creator Store).
	Töne: kostenlose Soundeffekte aus dem Creator Store (alle in Studio auf Abspielbarkeit getestet).
	Eigene IDs eintragen:
	  1. Im Studio: Toolbox → Audio/Bilder suchen → Rechtsklick → "Copy Asset ID"
	  2. Hier eintragen als "rbxassetid://1234567890"
	Leerer Text "" = nichts abspielen / nichts anzeigen (das Spiel läuft trotzdem).

	"rbxasset://sounds/..." sind eingebaute Roblox-Töne, die ohne Upload funktionieren.
	Achtung: Nur diese gibt es noch: action_jump.mp3, action_jump_land.mp3, action_falling.ogg,
	impact_water.mp3, impact_explosion_03.mp3, oof.ogg, ouch.ogg, volume_slider.ogg
]]

local Assets = {}

Assets.Sounds = {
	Klick = "rbxassetid://79130903404606", -- Kristall angeklickt („crystal fx“)
	Menue = "rbxassetid://117649901456711", -- Button im Menü („ui_button_click“)
	Kaufen = "rbxassetid://90531793028786", -- Upgrade gekauft (Kasse „Kaching“)
	Fehler = "rbxassetid://91483797839384", -- nicht genug Energie („Error“)
	Ei = "rbxassetid://109359226723492", -- Ei öffnet sich („cartoon bubble pop“)
	LevelUp = "rbxassetid://75192528656257", -- Glöckchen
	Checkpoint = "rbxassetid://79138466370636", -- „ding“
	Ziel = "rbxassetid://93529351909119", -- Power-up-Ton
	Sprungpad = "rbxasset://sounds/action_jump.mp3",
	Puff = "rbxasset://sounds/action_jump_land.mp3", -- zurück zum Checkpoint
	Faehigkeit = "rbxassetid://9116275998", -- Elektro-Funke (Pro Sound Effects)
	Treffer = "rbxasset://sounds/action_jump_land.mp3",
	Zahnraeder = "rbxassetid://9113757109", -- Metall-Klirren, Gegner zerfällt (Pro Sound Effects)
	BossWarnung = "rbxassetid://16903690359", -- Warn-Piepton
	Portal = "rbxassetid://9120713942", -- Whoosh (Pro Sound Effects)
	Sammeln = "rbxassetid://98668934757781", -- Energie-Kugel (Münz-Ton)
}

-- Lautstärke pro Ton (0 bis 1)
Assets.SoundVolume = {
	Klick = 0.35,
	Sammeln = 0.25,
	Puff = 0.6,
	Kaufen = 0.4,
	Fehler = 0.35,
	Zahnraeder = 0.4,
	Portal = 0.45,
}

-- Hintergrundmusik pro Ort (Index 0 = Hub, 1–5 = Zonen). "" = keine Musik.
Assets.Music = {
	[0] = "rbxassetid://1842185080", -- Hub: „Explore OL (a)“ – fröhliches Abenteuer
	[1] = "rbxassetid://1837478855", -- Zahnrad-Wiese: „Outdoor Fun“
	[2] = "rbxassetid://1836289689", -- Rost-Werkstatt: „Silly Chase“
	[3] = "rbxassetid://1844631856", -- Pendel-Schlucht: „Final Frontier“
	[4] = "rbxassetid://1840358349", -- Kristall-Getriebe: „Weightless“ – schwebend, ruhig
	[5] = "rbxassetid://1840513012", -- Uhrwerk: „Classic Action (A)“
	[6] = "rbxassetid://9041843800", -- Sternwarte: „Whirlpool“ – weite, staunende Welten
	[7] = "rbxassetid://1838969059", -- Versunkenes Uhrwerk: „Mysterious Discovery“
	Boss = "rbxassetid://1841286238", -- Bosskampf: „Final Faceoff – Epic Orchestral Tension“
	Turm = "rbxassetid://9046503137", -- Endlos-Turm: „Imminent Closure“ – heldenhaft
	Werkstatt = "rbxassetid://1839864816", -- eigene Werkstatt-Insel: „Daisy Fresh“ – gemütlich
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
