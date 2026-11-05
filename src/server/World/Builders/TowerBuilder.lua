--!strict
--[[
	TowerBuilder: baut eine Etage des Endlos-Turms (Konfig: Tower.lua).
	Wird zur Laufzeit vom TowerService aufgerufen – gleiche Woche + gleiche Etage = gleiche Etage.
	Jede Etage: Startplatte → Hindernisse (wie auf den Strecken) → Ausgang zur nächsten Etage.
	Neben den Etagen wächst eine Turmsäule mit, damit es von außen wie ein Turm aussieht.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Tower = require(Config:WaitForChild("Tower")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Difficulty = require(Config:WaitForChild("Difficulty")) :: any
local Parts = require(script.Parent:WaitForChild("Parts"))
local Obstacles = require(script.Parent:WaitForChild("Obstacles"))

local TowerBuilder = {}

local THICK = Obstacles.THICK
local STONE = Color3.fromRGB(235, 220, 195)
local BRASS = Color3.fromRGB(215, 170, 80)

-- Mitte der Startplatte (Oberkante) von Etage n
function TowerBuilder.FloorOrigin(n: number): Vector3
	local column = math.floor((n - 1) / Tower.EtagenProSaeule)
	local level = (n - 1) % Tower.EtagenProSaeule
	return Tower.Ursprung + Vector3.new(column * Tower.SaeulenAbstand, level * Tower.EtagenHoehe, 0)
end

function TowerBuilder.DiffFor(n: number): string
	if n <= Tower.LeichtBis then
		return "Leicht"
	elseif n <= Tower.NormalBis then
		return "Normal"
	end
	return "Profi"
end

-- Hindernis-Reihenfolge: zufällige Auswahl ohne direkte Wiederholung
local function pickKinds(rng: Random, count: number): { string }
	local list = {}
	local last = ""
	for _ = 1, count do
		local kind = Tower.Hindernisse[rng:NextInteger(1, #Tower.Hindernisse)]
		if kind == last then
			kind = Tower.Hindernisse[(table.find(Tower.Hindernisse, kind) :: number) % #Tower.Hindernisse + 1]
		end
		table.insert(list, kind)
		last = kind
	end
	return list
end

-- Baut Etage n (für Woche "week") in einen neuen Ordner. Gibt (Ordner, Startposition, Länge) zurück.
function TowerBuilder.BuildFloor(parent: Instance, week: number, n: number): (Folder, Vector3, number)
	local rng = Random.new(week * 100003 + n * 97)
	local diff = TowerBuilder.DiffFor(n)
	local P = Difficulty.Stufen[diff]
	local zone = Zones[(n - 1) % #Zones + 1] -- Farben wechseln durch alle Zonen
	local C = zone.Farben
	local F = math.min(1 + n * Tower.FaktorProEtage, Tower.FaktorMax)
	local O = TowerBuilder.FloorOrigin(n)

	local folder = Instance.new("Folder")
	folder.Name = ("Etage_%03d"):format(n)

	local ctx: Obstacles.Ctx = {
		Folder = folder,
		P = P,
		F = F,
		Colors = C,
		Rng = rng,
		LaneX = O.X,
		LastX = O.X,
		StartY = O.Y,
		Size = math.clamp(P.Plattformgroesse * F ^ -0.15, Difficulty.MinPlattform, 20),
		Speed = P.Tempo * F ^ 0.5,
		Takt = P.Takt / F ^ 0.3,
		Hints = false,
		HintsShown = {},
	}

	-- Startplatte mit Etagen-Nummer
	local start = Parts.Block(O, Vector3.new(16, THICK, 16), {
		Name = "Start",
		Color = C.Plattform,
		Material = Enum.Material.Marble,
		Parent = folder,
	})
	start:SetAttribute("TowerFloor", n)
	Parts.Billboard(start, ("🗼 Etage %d  %s"):format(n, P.Symbol), 7, Vector2.new(240, 56), Color3.fromRGB(255, 240, 200))
	-- Rückweg zum Hub
	local back = Parts.Cylinder(O + Vector3.new(-5.5, 0.4, -5.5), 2.2, 0.4, {
		Name = "ZurueckZumHub",
		Color = Color3.fromRGB(150, 200, 255),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Tags = { "TowerLeave" },
		Parent = folder,
	})
	Parts.Billboard(back, "↩ Hub", 2.5, Vector2.new(90, 32))

	-- Hindernisse
	local count = math.min(Tower.AbschnitteStart + math.floor(n / Tower.AbschnitteAlle), Tower.AbschnitteMax)
	local cur = Vector3.new(O.X, O.Y, O.Z + 8)
	for _, kind in pickKinds(rng, count) do
		cur = Obstacles.Build(kind, ctx, cur)
	end

	-- Ausgang → nächste Etage
	local gap = math.min(Obstacles.Gap(ctx), 6)
	local exitTop = Vector3.new(O.X, cur.Y, cur.Z + gap + 8)
	local exit = Parts.Block(exitTop, Vector3.new(16, THICK, 16), {
		Name = "Ausgang",
		Color = Color3.fromRGB(255, 215, 90),
		Material = Enum.Material.Metal,
		Parent = folder,
	})
	local portal = Parts.Cylinder(exitTop + Vector3.new(0, 0.5, 0), 5, 0.5, {
		Name = "Aufzug",
		Color = Color3.fromRGB(255, 235, 150),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Tags = { "TowerExit" },
		Attrs = { Floor = n },
		Parent = folder,
	})
	Parts.Billboard(portal, ("⬆ Etage %d"):format(n + 1), 5, Vector2.new(160, 44))
	for _, side in { -1, 1 } do
		Parts.Part({ Name = "Bogen", Size = Vector3.new(1, 12, 1), CFrame = CFrame.new(exitTop + Vector3.new(side * 7.5, 6, 6)), Color = C.Akzent, Material = Enum.Material.Metal, Parent = folder })
	end
	Parts.Part({ Name = "Bogendach", Size = Vector3.new(16, 1.2, 1.2), CFrame = CFrame.new(exitTop + Vector3.new(0, 12, 6)), Color = C.Akzent, Material = Enum.Material.Metal, Parent = folder })

	-- Turmsäule neben der Etage (wächst mit jeder Etage)
	local length = exitTop.Z - O.Z
	local pillarPos = Vector3.new(O.X - 42, O.Y - Tower.EtagenHoehe / 2, O.Z + 45)
	Parts.Part({
		Name = "Turmsaeule",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(Tower.EtagenHoehe, 26, 26),
		CFrame = CFrame.new(pillarPos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = STONE,
		Material = Enum.Material.Brick,
		CastShadow = false,
		Parent = folder,
	})
	Parts.Part({
		Name = "Turmring",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, 29, 29),
		CFrame = CFrame.new(Vector3.new(pillarPos.X, O.Y + 0.5, pillarPos.Z)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = BRASS,
		Material = Enum.Material.Metal,
		CastShadow = false,
		Parent = folder,
	})
	-- Etagen-Nummer groß an der Säule
	local plate = Parts.Part({
		Name = "Etagenschild",
		Size = Vector3.new(0.6, 10, 14),
		CFrame = CFrame.new(Vector3.new(pillarPos.X + 13.4, O.Y + 8, pillarPos.Z)),
		Color = Color3.fromRGB(255, 246, 225),
		CastShadow = false,
		Parent = folder,
	})
	Parts.SurfaceText(plate, tostring(n), Enum.NormalId.Right, Color3.fromRGB(150, 100, 40))
	-- Laterne an der Startplatte
	local lampPart = Parts.Part({
		Name = "Laterne",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.6, 1.6, 1.6),
		CFrame = CFrame.new(O + Vector3.new(7, 6, -7)),
		Color = C.Deko,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = folder,
	})
	Parts.Part({ Name = "Laternenmast", Size = Vector3.new(0.5, 6, 0.5), CFrame = CFrame.new(O + Vector3.new(7, 3, -7)), Color = BRASS, Material = Enum.Material.Metal, Parent = folder })
	local light = Instance.new("PointLight")
	light.Range = 16
	light.Brightness = 1.2
	light.Color = Color3.fromRGB(255, 225, 180)
	light.Parent = lampPart

	folder.Parent = parent
	return folder, O + Vector3.new(0, 2, 0), length
end

return TowerBuilder
