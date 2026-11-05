--[[
	⚙️ SETTINGS – allgemeine Spielwerte
	Hier stehen Zahlen, die das ganze Spiel betreffen.
	Ändere nur die Zahlen/Texte rechts vom "=" und lass Kommas und Klammern stehen.
]]

local Settings = {}

-- 🔐 Admins: Trage hier eure Roblox-UserIds ein (Zahl aus der Profil-URL).
-- Beispiel: Settings.AdminUserIds = { 12345678, 87654321 }
Settings.AdminUserIds = {}
-- Im Roblox Studio darf jeder Admin-Befehle nutzen (praktisch zum Testen).
Settings.AdminInStudio = true

-- 💾 Speichern
Settings.DataStoreName = "UhrwerkInsel_Spieler_v1"
Settings.SchemaVersion = 2 -- nur erhöhen, wenn eine Migration geschrieben wurde
Settings.AutosaveInterval = 60 -- Sekunden zwischen automatischem Speichern
Settings.SaveRetries = 5 -- wie oft Speichern/Laden wiederholt wird
Settings.RetryDelay = 2 -- Sekunden Wartezeit zwischen Versuchen (wird jedes Mal etwas länger)
Settings.SessionLockTimeout = 1800 -- nach so vielen Sekunden gilt eine Sperre als verwaist
Settings.LockWaitTries = 6 -- so oft warten wir, wenn ein anderer Server die Daten noch hält

-- 🌍 Welt
Settings.RebuildWorldOnStart = false -- true = Welt bei jedem Serverstart neu bauen
Settings.HubCenter = Vector3.new(0, 100, 0)
Settings.ZoneSpacing = 1400 -- Abstand der Zonen-Inseln
Settings.RespawnTime = 3

-- 🧍 Spieler-Grundwerte
Settings.Player = {
	WalkSpeed = 18,
	JumpPower = 52,
	MaxHealth = 100,
}

-- 📈 Level & XP
-- XP für das nächste Level = Basis * Level ^ Exponent
Settings.XP = {
	Basis = 50,
	Exponent = 1.5,
	MaxLevel = 100,
	SkillPunkteProLevel = 1,
}

-- ♻️ Rebirth
Settings.Rebirth = {
	Basiskosten = 250000, -- Energie für den ersten Rebirth
	Kostenfaktor = 3, -- jeder Rebirth kostet so viel mal mehr
	MindestLevel = 15,
	MultiplikatorProRebirth = 0.5, -- +50 % Energie für immer pro Rebirth
	PunkteProRebirth = 1,
}

-- 🎓 Klassenwechsel im Hub
Settings.ClassChangeCost = 1000

-- 🐾 Pets
Settings.Pets = {
	MaxInventar = 60,
	StartSlots = 3,
}

-- ⚡ Energie sammeln
Settings.Energy = {
	ClickCooldown = 0.12, -- kürzeste Zeit zwischen zwei Kristall-Klicks
	ClickDistance = 40, -- so nah muss man am Kristall sein
	FieldTick = 0.5, -- alle so viele Sekunden gibt ein Energie-Feld Energie
	FieldMinSpeed = 4, -- so schnell muss man laufen
	OrbsPerField = 12,
	OrbRespawn = 5,
	BaseCollectRadius = 6,
}

-- 🚀 Doppel-Energie-Boosts (zeitlich begrenzt)
Settings.Boost = {
	Interval = 240, -- alle 4 Minuten startet irgendwo ein Boost
	Duration = 60,
	Multiplier = 2,
}

-- 🏁 Strecken
Settings.Course = {
	FallDistance = 35, -- so tief unter dem Checkpoint gilt man als abgestürzt
	MaxStudsPerSecond = 60, -- schneller kann niemand ehrlich laufen (Anti-Schummel)
	FirstClearBonus = 2, -- erste Runde gibt doppelte Belohnung
}

-- 🥇 Zeit-Medaillen: Jede Bahn hat eine Richtzeit (wird beim Bauen aus Länge + Hindernissen geschätzt).
-- Zeit ≤ Richtzeit × Faktor → Medaille. Belohnung einmalig pro Medaille (Anteil der Strecken-Belohnung).
Settings.Medals = {
	{ Name = "Bronze", Symbol = "🥉", Faktor = 1.9, Belohnung = 0.3 },
	{ Name = "Silber", Symbol = "🥈", Faktor = 1.4, Belohnung = 0.6 },
	{ Name = "Gold", Symbol = "🥇", Faktor = 1.1, Belohnung = 1.2 },
}

-- 🤝 Co-op
Settings.Coop = {
	SoloTestMode = false, -- true = Rätsel klappen auch allein (nur zum Testen!)
	BridgeWindow = 1.5, -- so gleichzeitig müssen beide Knöpfe gedrückt werden (Sekunden)
	BridgeDuration = 15,
	DoorHoldTime = 4, -- Tür bleibt so lange offen, nachdem jemand von der Platte geht
	ConsoleFactor = 0.25, -- so langsam laufen Hindernisse, wenn die Zeit-Konsole besetzt ist
	RewardCooldown = 45,
	AreaRadius = 110,
}

-- 🏆 Bestenliste
Settings.Leaderboard = {
	Enabled = true,
	Top = 10,
	CacheSeconds = 120,
}

-- 💬 Schnellnachrichten (kein freier Chat!)
Settings.QuickChat = {
	"Hallo! 👋",
	"Folge mir!",
	"Hilf mir bitte!",
	"Gut gemacht! 🎉",
	"Warte kurz!",
	"Auf die Druckplatte!",
	"Verlangsame die Zeit! 🐢",
	"Los geht's! 🚀",
	"Danke! 😊",
	"Noch mal!",
	"Ich hab's geschafft! 🏁",
	"Boss-Kampf? ⚔️",
}

-- 🏷️ Erlaubte Pet-Namen (wegen Textfilter keine freie Eingabe)
Settings.PetNames = {
	"Ticki",
	"Tacki",
	"Sprocket",
	"Bolzen",
	"Funki",
	"Kling",
	"Pling",
	"Rädchen",
	"Messing",
	"Kupfer",
	"Sternchen",
	"Blitz",
	"Wuschel",
	"Kuller",
	"Schraubi",
	"Glöckchen",
	"Sekunde",
	"Minute",
	"Turbo",
	"Kompass",
}

return Settings
