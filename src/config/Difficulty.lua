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
		Plattformgroesse = 13, -- Breite/Länge einer Plattform (Studs)
		LueckeMin = 3, -- kleinster Abstand zwischen Plattformen
		LueckeMax = 5, -- größter Abstand
		Hoehenstufe = 1, -- so viel darf es hoch/runter gehen
		Tempo = 0.5, -- Hindernis-Tempo
		Takt = 4.5, -- Zeitplattform: Sekunden pro Runde
		AnAnteil = 0.8, -- Anteil der Zeit, in der die Plattform da ist
		Wackelwinkel = 6, -- Grad
		PendelWinkel = 38, -- Grad
		LaserHoehen = { 1.5 }, -- nur ein tiefer Laser (darüber springen geht immer)
		CheckpointAlle = 2, -- alle 2 Abschnitte ein Checkpoint
		Belohnung = 1.0, -- Belohnungs-Multiplikator
		EiChance = 0.05, -- 5 % Chance auf ein Gratis-Ei
	},
	Normal = {
		Name = "Normal",
		Symbol = "🟡",
		Farbe = Color3.fromRGB(255, 210, 90),
		Plattformgroesse = 10.5,
		LueckeMin = 4,
		LueckeMax = 6.5,
		Hoehenstufe = 1.5,
		Tempo = 0.8,
		Takt = 3.6,
		AnAnteil = 0.7,
		Wackelwinkel = 10,
		PendelWinkel = 50,
		LaserHoehen = { 1.5, 4.5 },
		CheckpointAlle = 2,
		Belohnung = 1.6,
		EiChance = 0.1,
	},
	Profi = {
		Name = "Profi",
		Symbol = "🔴",
		Farbe = Color3.fromRGB(255, 110, 110),
		Plattformgroesse = 8,
		LueckeMin = 5,
		LueckeMax = 7.5,
		Hoehenstufe = 2,
		Tempo = 1.15,
		Takt = 2.8,
		AnAnteil = 0.6,
		Wackelwinkel = 15,
		PendelWinkel = 60,
		LaserHoehen = { 1.5, 4.5 },
		CheckpointAlle = 3,
		Belohnung = 2.5,
		EiChance = 0.2,
	},
}

-- Sicherheitsgrenze: mit Grundwerten (Tempo 18, Sprungkraft 52) schafft man ca. 9,5 Studs – wir bleiben darunter.
-- Größer machen nur, wenn ihr auch Settings.Player erhöht!
Difficulty.MaxLuecke = 8.5
-- Kleinste erlaubte Plattform
Difficulty.MinPlattform = 4.5
-- Seitliches Versetzen der Plattformen (Studs)
Difficulty.Seitenversatz = 4

return Difficulty
