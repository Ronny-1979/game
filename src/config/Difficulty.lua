--[[
	🎚️ DIFFICULTY – Leicht / Normal / Profi
	Jede Strecke hat drei Bahnen nebeneinander:
	  🟢 Leicht   🟡 Normal   🔴 Profi
	Größere Zahlen bei "Luecke" = weitere Sprünge. Kleinere "Plattformgroesse" = schmalere Plattformen.
	"Tempo" = wie schnell sich Hindernisse bewegen (1 = normal).
	"Takt" = Sekunden, bis eine Zeitplattform wieder auftaucht.
]]

local Difficulty = {}

Difficulty.Reihenfolge = { "Leicht", "Normal", "Profi" }

Difficulty.Stufen = {
	Leicht = {
		Name = "Leicht",
		Symbol = "🟢",
		Farbe = Color3.fromRGB(120, 220, 140),
		Plattformgroesse = 12, -- Breite/Länge einer Plattform (Studs)
		LueckeMin = 3.5, -- kleinster Abstand zwischen Plattformen
		LueckeMax = 6, -- größter Abstand
		Hoehenstufe = 1, -- so viel darf es hoch/runter gehen
		Tempo = 0.6, -- Hindernis-Tempo
		Takt = 4.0, -- Zeitplattform: Sekunden pro Runde
		AnAnteil = 0.7, -- Anteil der Zeit, in der die Plattform da ist
		Wackelwinkel = 8, -- Grad
		PendelWinkel = 45, -- Grad
		LaserHoehen = { 1.5 }, -- nur ein tiefer Laser (darüber springen geht immer)
		CheckpointAlle = 2, -- alle 2 Abschnitte ein Checkpoint
		Belohnung = 1.0, -- Belohnungs-Multiplikator
		EiChance = 0.05, -- 5 % Chance auf ein Gratis-Ei
	},
	Normal = {
		Name = "Normal",
		Symbol = "🟡",
		Farbe = Color3.fromRGB(255, 210, 90),
		Plattformgroesse = 9,
		LueckeMin = 5,
		LueckeMax = 7.5,
		Hoehenstufe = 2,
		Tempo = 1.0,
		Takt = 3.0,
		AnAnteil = 0.6,
		Wackelwinkel = 14,
		PendelWinkel = 58,
		LaserHoehen = { 1.5, 4.5 },
		CheckpointAlle = 3,
		Belohnung = 1.6,
		EiChance = 0.1,
	},
	Profi = {
		Name = "Profi",
		Symbol = "🔴",
		Farbe = Color3.fromRGB(255, 110, 110),
		Plattformgroesse = 6.5,
		LueckeMin = 6.5,
		LueckeMax = 9,
		Hoehenstufe = 3,
		Tempo = 1.45,
		Takt = 2.2,
		AnAnteil = 0.5,
		Wackelwinkel = 20,
		PendelWinkel = 68,
		LaserHoehen = { 1.5, 4.5 },
		CheckpointAlle = 4,
		Belohnung = 2.5,
		EiChance = 0.2,
	},
}

-- Sicherheitsgrenze: mit Grundwerten (Tempo 18, Sprungkraft 52) schafft man ca. 9,5 Studs.
-- Größer machen nur, wenn ihr auch Settings.Player erhöht!
Difficulty.MaxLuecke = 9.5
-- Kleinste erlaubte Plattform
Difficulty.MinPlattform = 4.5
-- Seitliches Versetzen der Plattformen (Studs)
Difficulty.Seitenversatz = 4

return Difficulty
