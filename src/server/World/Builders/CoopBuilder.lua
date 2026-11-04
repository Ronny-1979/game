--!strict
--[[
	CoopBuilder: baut die Zwei-Spieler-Rätsel.
	origin = Mitte der Eingangskante (Oberkante Boden), das Rätsel geht in +Z.
	Gibt die Z-Position der hinteren Kante zurück.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Difficulty = require(Config:WaitForChild("Difficulty")) :: any
local Tags = require(Shared:WaitForChild("Tags"))
local Parts = require(script.Parent:WaitForChild("Parts"))
local Obstacles = require(script.Parent:WaitForChild("Obstacles"))

local CoopBuilder = {}

local WALL_H = 22
local PLATE = Color3.fromRGB(255, 200, 90)

local function floor(parent: Instance, o: Vector3, x: number, z0: number, z1: number, w: number, color: Color3): Part
	return Parts.Block(Vector3.new(o.X + x, o.Y, o.Z + (z0 + z1) / 2), Vector3.new(w, 2, z1 - z0), {
		Name = "Boden",
		Color = color,
		Material = Enum.Material.Cobblestone,
		Parent = parent,
	})
end

local function wall(parent: Instance, center: Vector3, size: Vector3, color: Color3, tags: { string }?, attrs: { [string]: any }?): Part
	return Parts.Part({
		Name = "Wand",
		Size = size,
		CFrame = CFrame.new(center),
		Color = color,
		Material = Enum.Material.Brick,
		Tags = tags,
		Attrs = attrs,
		Parent = parent,
	})
end

local function area(parent: Instance, center: Vector3, id: string, kind: string, zoneIndex: number, radius: number)
	Parts.Part({
		Name = "RaetselBereich",
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(center),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Tags = { Tags.CoopArea },
		Attrs = { PuzzleId = id, Kind = kind, ZoneIndex = zoneIndex, Radius = radius },
		Parent = parent,
	})
end

local function rewardPad(parent: Instance, pos: Vector3, id: string)
	local pad = Parts.Cylinder(pos + Vector3.new(0, 0.5, 0), 4, 0.5, {
		Name = "TeamBelohnung",
		Color = Color3.fromRGB(120, 255, 160),
		Material = Enum.Material.Neon,
		Tags = { Tags.CoopReward },
		Attrs = { PuzzleId = id },
		Parent = parent,
	})
	Parts.Billboard(pad, "🎁 Team-Belohnung", 4, Vector2.new(180, 45))
	-- kleine Schatztruhe (Deko)
	Parts.Block(pos + Vector3.new(0, 3.5, 6), Vector3.new(5, 3, 3.5), {
		Name = "Truhe",
		Color = Color3.fromRGB(190, 130, 70),
		Material = Enum.Material.Wood,
		Parent = parent,
	})
end

-- 🚪 Doppeltür
local function buildDoor(parent: Instance, o: Vector3, id: string, zoneIndex: number, colors: any): number
	local wc = colors.Akzent:Lerp(Color3.fromRGB(120, 100, 90), 0.4)
	floor(parent, o, 0, 0, 100, 60, colors.Plattform)
	local y = o.Y + WALL_H / 2
	-- Außenwände (vorne mit Eingang)
	wall(parent, Vector3.new(o.X - 30, y, o.Z + 50), Vector3.new(2, WALL_H, 100), wc)
	wall(parent, Vector3.new(o.X + 30, y, o.Z + 50), Vector3.new(2, WALL_H, 100), wc)
	wall(parent, Vector3.new(o.X, y, o.Z + 100), Vector3.new(62, WALL_H, 2), wc)
	wall(parent, Vector3.new(o.X - 19, y, o.Z), Vector3.new(22, WALL_H, 2), wc)
	wall(parent, Vector3.new(o.X + 19, y, o.Z), Vector3.new(22, WALL_H, 2), wc)
	-- Trennwand mit Tür
	wall(parent, Vector3.new(o.X - 18, y, o.Z + 60), Vector3.new(24, WALL_H, 2), wc)
	wall(parent, Vector3.new(o.X + 18, y, o.Z + 60), Vector3.new(24, WALL_H, 2), wc)
	local door = wall(parent, Vector3.new(o.X, y, o.Z + 60), Vector3.new(12, WALL_H, 1.5), Color3.fromRGB(205, 160, 80), { Tags.CoopDoor }, { PuzzleId = id })
	door.Material = Enum.Material.Metal
	Parts.Gear(parent, CFrame.new(o.X, o.Y + 14, o.Z + 59) * CFrame.Angles(math.rad(90), 0, 0), 4, 0.6, 10, colors.Akzent, false)
	for _, side in { -1, 1 } do
		Parts.Block(Vector3.new(o.X + side * 21, o.Y + 0.4, o.Z + 25), Vector3.new(7, 0.4, 7), {
			Name = "Druckplatte",
			Color = PLATE,
			Material = Enum.Material.Neon,
			Tags = { Tags.CoopPlate },
			Attrs = { PuzzleId = id },
			Parent = parent,
		})
	end
	rewardPad(parent, Vector3.new(o.X, o.Y, o.Z + 82), id)
	Parts.Sign(parent, Vector3.new(o.X, o.Y, o.Z - 6), "🤝 Doppeltür\nStellt euch BEIDE auf die gelben Platten!", 14, 5)
	area(parent, Vector3.new(o.X, o.Y + 5, o.Z + 50), id, "Tuer", zoneIndex, 70)
	return o.Z + 100
end

-- 🌉 Gleichzeitig-Brücke
local function buildBridge(parent: Instance, o: Vector3, id: string, zoneIndex: number, colors: any): number
	floor(parent, o, 0, 0, 30, 60, colors.Plattform)
	floor(parent, o, 0, 80, 110, 60, colors.Plattform)
	-- Brücke (erscheint nur, wenn beide Knöpfe gleichzeitig gedrückt werden)
	Parts.Block(Vector3.new(o.X, o.Y, o.Z + 55), Vector3.new(10, 1.5, 50), {
		Name = "Zeitbruecke",
		Color = Color3.fromRGB(140, 225, 255),
		Material = Enum.Material.Neon,
		Transparency = 1,
		CanCollide = false,
		Tags = { Tags.CoopBridge },
		Attrs = { PuzzleId = id },
		Parent = parent,
	})
	-- Energie-Barriere: verhindert, dass man mit Super-Sprung rüberkommt
	Parts.Part({
		Name = "Barriere",
		Size = Vector3.new(60, 40, 1),
		CFrame = CFrame.new(o.X, o.Y + 20, o.Z + 30.5),
		Color = Color3.fromRGB(160, 200, 255),
		Material = Enum.Material.ForceField,
		Transparency = 0.5,
		Tags = { Tags.CoopDoor },
		Attrs = { PuzzleId = id, SolidTransparency = 0.5 },
		Parent = parent,
	})
	for _, side in { -1, 1 } do
		local base = Parts.Block(Vector3.new(o.X + side * 22, o.Y + 3, o.Z + 12), Vector3.new(3, 3, 3), {
			Name = "Sockel",
			Color = colors.Akzent,
			Material = Enum.Material.Metal,
			Parent = parent,
		})
		local btn = Parts.Cylinder(base.Position + Vector3.new(0, 2.1, 0), 1.2, 0.6, {
			Name = "Knopf",
			Color = Color3.fromRGB(255, 120, 120),
			Material = Enum.Material.Neon,
			Tags = { Tags.CoopButton },
			Attrs = { PuzzleId = id },
			Parent = parent,
		})
		Parts.Prompt(btn, "Drücken", "Brücken-Knopf")
	end
	rewardPad(parent, Vector3.new(o.X, o.Y, o.Z + 95), id)
	Parts.Sign(parent, Vector3.new(o.X, o.Y, o.Z - 6), "🌉 Zeit-Brücke\nDrückt die zwei Knöpfe GLEICHZEITIG!", 14, 5)
	area(parent, Vector3.new(o.X, o.Y + 5, o.Z + 55), id, "Bruecke", zoneIndex, 75)
	return o.Z + 110
end

-- 🕹️ Zeit-Konsole: einer verlangsamt, der andere springt
local function buildConsole(parent: Instance, o: Vector3, id: string, zoneIndex: number, colors: any, F: number): number
	floor(parent, o, 0, 0, 18, 60, colors.Plattform)
	local plate = Parts.Block(Vector3.new(o.X - 20, o.Y + 0.4, o.Z + 9), Vector3.new(8, 0.4, 8), {
		Name = "ZeitKonsole",
		Color = Color3.fromRGB(190, 160, 255),
		Material = Enum.Material.Neon,
		Tags = { Tags.CoopConsole },
		Attrs = { PuzzleId = id },
		Parent = parent,
	})
	Parts.Block(plate.Position + Vector3.new(0, 3.5, 5), Vector3.new(6, 3, 1.5), {
		Name = "Pult",
		Color = colors.Akzent,
		Material = Enum.Material.Metal,
		Parent = parent,
	})
	Parts.Billboard(plate, "🕹️ Hier stehen = Zeit langsam", 5, Vector2.new(220, 45))
	-- Turbo-Strecke (ohne Konsole kaum zu schaffen)
	local P = Difficulty.Stufen.Normal
	local ctx: Obstacles.Ctx = {
		Folder = parent,
		P = P,
		F = F,
		Colors = colors,
		Rng = Random.new(zoneIndex * 7919 + #id),
		LaneX = o.X + 8,
		LastX = o.X + 8,
		StartY = o.Y,
		Size = 8,
		Speed = 3.5,
		Takt = P.Takt / 3.5,
		Hints = false,
		HintsShown = {},
	}
	local cur = Vector3.new(o.X + 8, o.Y, o.Z + 18)
	cur = Obstacles.Builders.Zeitplattform(ctx, cur)
	cur = Obstacles.Builders.Laser(ctx, cur)
	cur = Obstacles.Builders.Zeitplattform(ctx, cur)
	local endZ = cur.Z + 4
	local relEnd = endZ - o.Z
	Parts.Block(Vector3.new(o.X, cur.Y, endZ + 15), Vector3.new(40, 2, 30), {
		Name = "Ziel",
		Color = colors.Plattform,
		Material = Enum.Material.Cobblestone,
		Parent = parent,
	})
	rewardPad(parent, Vector3.new(o.X, cur.Y, endZ + 18), id)
	Parts.Sign(parent, Vector3.new(o.X, o.Y, o.Z - 6), "🕹️ Zeit-Konsole\nEiner steht auf der Konsole, der andere springt!", 14, 5)
	area(parent, Vector3.new(o.X, o.Y + 5, o.Z + (relEnd + 30) / 2), id, "Konsole", zoneIndex, math.max(80, relEnd / 2 + 30))
	return endZ + 30
end

function CoopBuilder.Build(parent: Instance, origin: Vector3, kind: string, id: string, zoneIndex: number, colors: any, F: number): number
	local folder = Parts.Model("Raetsel_" .. id, parent)
	if kind == "Tuer" then
		return buildDoor(folder, origin, id, zoneIndex, colors)
	elseif kind == "Bruecke" then
		return buildBridge(folder, origin, id, zoneIndex, colors)
	elseif kind == "Konsole" then
		return buildConsole(folder, origin, id, zoneIndex, colors, F)
	end
	return origin.Z
end

return CoopBuilder
