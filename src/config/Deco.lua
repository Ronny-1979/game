--[[
	🏡 DECO – die eigene Werkstatt-Insel
	Jeder Spieler bekommt auf dem Server eine eigene kleine Insel und kann sie mit Deko gestalten.
	Freunde können sie besuchen. Jedes Deko-Stück gibt dauerhaft etwas mehr Energie (Werkstatt-Bonus).

	Preis = Basispreis × Energiewert der besten freigeschalteten Zone (so bleibt es immer passend teuer).
	Groesse = 1 (ein Feld) oder 2 (2×2 Felder)
	Frei (optional): Zone = n → erst ab Zone n,  Boss = "ZonenId" → erst nach diesem Boss-Sieg
	Abbauen gibt den vollen Preis zurück.

	Modell = welche Bauform benutzt wird (siehe src/shared/DecoModels.lua)
]]
local Deco = {}

Deco.Katalog = {
	{ Id = "Blumenbeet", Name = "Blumenbeet", Symbol = "🌷", Preis = 30, Groesse = 1, Modell = "Blumenbeet" },
	{ Id = "Hecke", Name = "Hecke", Symbol = "🌿", Preis = 25, Groesse = 1, Modell = "Hecke" },
	{ Id = "Zaun", Name = "Zaun", Symbol = "🚧", Preis = 15, Groesse = 1, Modell = "Zaun" },
	{ Id = "Baum", Name = "Baum", Symbol = "🌳", Preis = 60, Groesse = 1, Modell = "Baum" },
	{ Id = "Pilze", Name = "Pilzgruppe", Symbol = "🍄", Preis = 40, Groesse = 1, Modell = "Pilze" },
	{ Id = "Laterne", Name = "Laterne", Symbol = "🏮", Preis = 50, Groesse = 1, Modell = "Laterne" },
	{ Id = "Bank", Name = "Bank", Symbol = "🪑", Preis = 70, Groesse = 1, Modell = "Bank" },
	{ Id = "Kristall", Name = "Energie-Kristall", Symbol = "💎", Preis = 120, Groesse = 1, Modell = "Kristall" },
	{ Id = "Pethaus", Name = "Pet-Häuschen", Symbol = "🏠", Preis = 300, Groesse = 2, Modell = "Haus" },
	{ Id = "Zahnradskulptur", Name = "Zahnrad-Skulptur", Symbol = "⚙️", Preis = 200, Groesse = 2, Modell = "Zahnradskulptur" },
	{ Id = "Brunnen", Name = "Springbrunnen", Symbol = "⛲", Preis = 400, Groesse = 2, Modell = "Brunnen" },
	{ Id = "Uhrturm", Name = "Mini-Uhrturm", Symbol = "🕰️", Preis = 800, Groesse = 2, Modell = "Uhrturm" },
	{ Id = "Amboss", Name = "Amboss", Symbol = "🔨", Preis = 150, Groesse = 1, Modell = "Amboss", Zone = 2 },
	{ Id = "Pendeluhr", Name = "Pendeluhr", Symbol = "⏳", Preis = 350, Groesse = 1, Modell = "Pendeluhr", Zone = 3 },
	{ Id = "Prisma", Name = "Prismen-Säule", Symbol = "🔷", Preis = 500, Groesse = 1, Modell = "Prisma", Zone = 4 },
	{ Id = "Teleskop", Name = "Teleskop", Symbol = "🔭", Preis = 600, Groesse = 1, Modell = "Teleskop", Zone = 6 },
	{ Id = "Koralle", Name = "Korallen-Riff", Symbol = "🪸", Preis = 700, Groesse = 1, Modell = "Koralle", Zone = 7 },
	-- 🏆 Pokale für besiegte Bosse (gratis!)
	{ Id = "Pokal1", Name = "Zahnrad-König-Pokal", Symbol = "🏆", Preis = 0, Groesse = 1, Modell = "Pokal", Boss = "Wiese" },
	{ Id = "Pokal2", Name = "Rost-Rudi-Pokal", Symbol = "🏆", Preis = 0, Groesse = 1, Modell = "Pokal", Boss = "Werkstatt" },
	{ Id = "Pokal3", Name = "Pendel-Paula-Pokal", Symbol = "🏆", Preis = 0, Groesse = 1, Modell = "Pokal", Boss = "Schlucht" },
	{ Id = "Pokal4", Name = "Kristall-Koloss-Pokal", Symbol = "🏆", Preis = 0, Groesse = 1, Modell = "Pokal", Boss = "Kristall" },
	{ Id = "Pokal5", Name = "Meister-Unruh-Pokal", Symbol = "🏆", Preis = 0, Groesse = 1, Modell = "Pokal", Boss = "Uhrwerk" },
	{ Id = "Pokal6", Name = "Komet-Kasimir-Pokal", Symbol = "🏆", Preis = 0, Groesse = 1, Modell = "Pokal", Boss = "Sternwarte" },
	{ Id = "Pokal7", Name = "Ankerzahn-Pokal", Symbol = "🏆", Preis = 0, Groesse = 1, Modell = "Pokal", Boss = "Tiefsee" },
}

-- Insel-Raster
Deco.Zellen = 10 -- 10 × 10 Felder
Deco.Zelle = 8 -- Studs pro Feld
Deco.MaxDeko = 80 -- so viele Teile pro Insel
Deco.MaxProPokal = 1 -- jeden Pokal nur einmal

-- Werkstatt-Bonus: jedes Deko-Stück +0,5 % Energie, höchstens +25 %
Deco.BonusProDeko = 0.005
Deco.BonusMax = 0.25

-- Wo die Inseln liegen (weit weg von allem anderen), Abstand zwischen zwei Inseln, Inseln pro Reihe
Deco.Ursprung = Vector3.new(0, 100, 3400)
Deco.Abstand = 260
Deco.ProReihe = 4

function Deco.Find(id: string): any
	for _, item in Deco.Katalog do
		if item.Id == id then
			return item
		end
	end
	return nil
end

-- Mitte (Oberkante) der Insel Nummer i
function Deco.PlotCenter(i: number): Vector3
	local col = (i - 1) % Deco.ProReihe
	local row = math.floor((i - 1) / Deco.ProReihe)
	return Deco.Ursprung + Vector3.new(col * Deco.Abstand, 0, row * Deco.Abstand)
end

-- Weltposition (Boden-Mitte) eines Deko-Stücks auf Feld x, z (1 … Zellen)
function Deco.CellPos(center: Vector3, x: number, z: number, size: number): Vector3
	local half = Deco.Zellen * Deco.Zelle / 2
	local cx = -half + (x - 1) * Deco.Zelle + size * Deco.Zelle / 2
	local cz = -half + (z - 1) * Deco.Zelle + size * Deco.Zelle / 2
	return center + Vector3.new(cx, 0, cz)
end

return Deco
