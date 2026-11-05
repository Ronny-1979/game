--!strict
--[[
	Obstacles: wiederverwendbare Hindernis-Bausteine für die Strecken.
	Jeder Baustein bekommt den "Cursor" (X = Bahnmitte, Y = Oberkante, Z = Vorderkante der letzten Plattform)
	und gibt den neuen Cursor zurück. Bewegte Teile sind Modelle mit Tag "Obstacle" und Attributen –
	die Bewegung berechnet der Client (ObstacleController) aus der Serverzeit.

	Arten (Attribut "Kind"): Spin (drehen), Swing (pendeln), Slide (gleiten), Wobble (wackeln),
	Blink (Zeitplattform), Laser (Takt-Laser), Conveyor (Förderband)
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Difficulty = require(Config:WaitForChild("Difficulty")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Assets = require(Config:WaitForChild("Assets")) :: any
local Tags = require(Shared:WaitForChild("Tags"))
local Util = require(Shared:WaitForChild("Util"))
local Parts = require(script.Parent:WaitForChild("Parts"))

local Obstacles = {}

local THICK = 1.2
Obstacles.THICK = THICK

local HAZARD = Color3.fromRGB(255, 95, 70)
local LASER = Color3.fromRGB(255, 60, 90)
local TIME_COLOR = Color3.fromRGB(140, 225, 255)

export type Ctx = {
	Folder: Instance,
	P: any,
	F: number,
	Colors: any,
	Rng: Random,
	LaneX: number,
	LastX: number,
	StartY: number,
	Size: number,
	Speed: number,
	Takt: number,
	Hints: boolean,
	HintsShown: { [string]: boolean },
}

-- ===== Hilfen =====

function Obstacles.Gap(ctx: Ctx, factor: number?): number
	local P = ctx.P
	local g = Util.Lerp(P.LueckeMin, P.LueckeMax, ctx.Rng:NextNumber()) * ctx.F ^ 0.08 * (factor or 1)
	return math.clamp(g, 2, Difficulty.MaxLuecke)
end

function Obstacles.NextY(ctx: Ctx, gap: number, y: number): number
	local step = ctx.P.Hoehenstufe
	-- weite Sprünge nie nach oben (sonst nicht schaffbar)
	local choices = if gap > 7 then { -1, 0, 0 } else { -1, 0, 1, 1 }
	local dh = choices[ctx.Rng:NextInteger(1, #choices)] * step
	return math.clamp(y + dh, ctx.StartY - 2, ctx.StartY + 45)
end

function Obstacles.NextX(ctx: Ctx): number
	local side = Difficulty.Seitenversatz
	local x = ctx.LastX + ctx.Rng:NextNumber(-1, 1) * side
	x = math.clamp(x, ctx.LaneX - side, ctx.LaneX + side)
	ctx.LastX = x
	return x
end

local function plat(ctx: Ctx, top: Vector3, sx: number, sz: number, color: Color3?, parent: Instance?): Part
	return Parts.Block(top, Vector3.new(sx, THICK, sz), {
		Name = "Plattform",
		Color = color or ctx.Colors.Plattform,
		Parent = parent or ctx.Folder,
	})
end

function Obstacles.Hint(ctx: Ctx, kind: string, cur: Vector3)
	if not ctx.Hints or ctx.HintsShown[kind] then
		return
	end
	local text = Zones.Hinweise[kind]
	if not text then
		return
	end
	ctx.HintsShown[kind] = true
	Parts.Sign(ctx.Folder, Vector3.new(ctx.LaneX - 13, cur.Y, cur.Z + 2), text, 10, 4.5)
end

local B: { [string]: (Ctx, Vector3) -> Vector3 } = {}

-- ===== Sprung: normale Plattformen =====
B.Sprung = function(ctx, cur)
	for i = 1, 3 do
		local s = ctx.Size * ctx.Rng:NextNumber(0.85, 1.1)
		local gap = Obstacles.Gap(ctx)
		local y = Obstacles.NextY(ctx, gap, cur.Y)
		local x = Obstacles.NextX(ctx)
		local top = Vector3.new(x, y, cur.Z + gap + s / 2)
		if i == 2 then
			Parts.Cylinder(top, s / 2, THICK, { Name = "Rundplattform", Color = ctx.Colors.Akzent, Material = Enum.Material.Metal, Parent = ctx.Folder })
		else
			plat(ctx, top, s, s)
		end
		cur = Vector3.new(x, y, top.Z + s / 2)
	end
	return cur
end

-- ===== Drehzahnrad (+ Kehrbalken ab Normal) =====
B.Zahnrad = function(ctx, cur)
	local R = math.clamp(ctx.Size * 0.8 + 3, 6.5, 11)
	local gap = Obstacles.Gap(ctx, 0.85)
	local y = cur.Y
	local center = Vector3.new(ctx.LaneX, y, cur.Z + gap + R)
	local pivot = CFrame.new(center - Vector3.new(0, THICK / 2, 0))
	local dir = if ctx.Rng:NextNumber() < 0.5 then 1 else -1
	local m = Parts.Obstacle(ctx.Folder, "Drehzahnrad", "Spin", pivot, {
		Axis = Vector3.yAxis,
		Speed = 0.45 * ctx.Speed * dir,
		Phase = ctx.Rng:NextNumber(0, 6),
	})
	Parts.Gear(m, pivot, R, THICK, 12, ctx.Colors.Akzent)
	if ctx.P.Name ~= "Leicht" then
		local armCf = CFrame.new(center + Vector3.new(0, 1.4, 0))
		local sweep = Parts.Obstacle(ctx.Folder, "Kehrbalken", "Spin", armCf, {
			Axis = Vector3.yAxis,
			Speed = -1.1 * ctx.Speed * dir,
			Phase = ctx.Rng:NextNumber(0, 6),
		})
		Parts.Part({
			Name = "Balken",
			Size = Vector3.new(R * 1.8, 0.9, 0.9),
			CFrame = armCf,
			Color = HAZARD,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Tags = { Tags.Hazard },
			Parent = sweep,
		})
		Parts.Part({
			Name = "Nabe",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3, 2, 2),
			CFrame = armCf * CFrame.Angles(0, 0, math.rad(90)),
			Color = ctx.Colors.Deko,
			Material = Enum.Material.Metal,
			CanCollide = false,
			Parent = sweep,
		})
	end
	ctx.LastX = ctx.LaneX
	return Vector3.new(ctx.LaneX, y, center.Z + R)
end

-- ===== Pendel über einem Steg =====
B.Pendel = function(ctx, cur)
	local W = math.clamp(ctx.Size * 0.75, 4.5, 8)
	local L = 36
	local gap = math.min(Obstacles.Gap(ctx), 6)
	local y = cur.Y
	local z0 = cur.Z + gap
	plat(ctx, Vector3.new(ctx.LaneX, y, z0 + L / 2), W, L, ctx.Colors.Plattform)
	local n = if ctx.P.Name ~= "Leicht" then 3 else 2
	local amp = math.rad(ctx.P.PendelWinkel)
	local period = 2.8 / ctx.Speed
	local armLen = 18
	for i = 1, n do
		local z = z0 + L * (i / (n + 1))
		local pivot = CFrame.new(ctx.LaneX, y + armLen + 2.5, z)
		local m = Parts.Obstacle(ctx.Folder, "Pendel", "Swing", pivot, {
			Axis = Vector3.zAxis,
			Amp = amp,
			Period = period * ctx.Rng:NextNumber(0.9, 1.1),
			Phase = i * 1.7,
		})
		Parts.Part({
			Name = "Arm",
			Size = Vector3.new(0.6, armLen, 0.6),
			CFrame = pivot * CFrame.new(0, -armLen / 2, 0),
			Color = ctx.Colors.Akzent,
			Material = Enum.Material.Metal,
			CanCollide = false,
			Parent = m,
		})
		Parts.Part({
			Name = "Gewicht",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(5.5, 5.5, 5.5),
			CFrame = pivot * CFrame.new(0, -armLen - 0.5, 0),
			Color = HAZARD,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Tags = { Tags.Hazard },
			Parent = m,
		})
		-- schwebendes Lager-Zahnrad als Aufhängung (Deko)
		Parts.Gear(ctx.Folder, pivot * CFrame.Angles(math.rad(90), 0, 0), 2.2, 0.8, 8, ctx.Colors.Akzent, false)
	end
	ctx.LastX = ctx.LaneX
	return Vector3.new(ctx.LaneX, y, z0 + L)
end

-- ===== Förderbänder =====
B.Foerderband = function(ctx, cur)
	for i = 1, 3 do
		local gap = math.max(2, Obstacles.Gap(ctx) * 0.6)
		local len = 20
		local w = math.max(ctx.Size, 6)
		local y = cur.Y
		local zc = cur.Z + gap + len / 2
		local center = Vector3.new(ctx.LaneX, y - THICK / 2, zc)
		local sideways = i == 2
		local speed = (if sideways then 6 else 8) * ctx.Speed
		local dirVec = if sideways then Vector3.new(if ctx.Rng:NextNumber() < 0.5 then -1 else 1, 0, 0) else Vector3.new(0, 0, -1)
		local cf = CFrame.lookAt(center, center + dirVec)
		local size = if sideways then Vector3.new(len, THICK, w) else Vector3.new(w, THICK, len)
		local m = Parts.Obstacle(ctx.Folder, "Foerderband", "Conveyor", cf, {})
		local belt = Parts.Part({
			Name = "Band",
			Size = size,
			CFrame = cf,
			Color = Color3.fromRGB(95, 90, 100),
			Material = Enum.Material.DiamondPlate,
			Tags = { Tags.Conveyor },
			Attrs = { ConveyorSpeed = speed },
			Parent = m,
		})
		if Assets.Textures.Foerderband ~= "" then
			local tex = Instance.new("Texture")
			tex.Texture = Assets.Textures.Foerderband
			tex.Face = Enum.NormalId.Top
			tex.StudsPerTileU = 4
			tex.StudsPerTileV = 4
			tex.Parent = belt
		end
		-- Pfeile zeigen die Richtung
		for k = -1, 1 do
			Parts.Part({
				Name = "Pfeil",
				Size = Vector3.new(0.5, 0.1, 3),
				CFrame = cf * CFrame.new(k * (math.min(size.X, size.Z) * 0.3), THICK / 2 + 0.05, 0),
				Color = Color3.fromRGB(255, 220, 90),
				Material = Enum.Material.Neon,
				CanCollide = false,
				CanQuery = false,
				Parent = m,
			})
		end
		cur = Vector3.new(ctx.LaneX, y, zc + len / 2)
	end
	ctx.LastX = ctx.LaneX
	return cur
end

-- ===== Gleitende Plattformen (+ Fähre ab Normal) =====
B.Bewegt = function(ctx, cur)
	local s = ctx.Size
	for _ = 1, 2 do
		local gap = Obstacles.Gap(ctx)
		local y = cur.Y
		local zc = cur.Z + gap + s / 2
		local swing = (6 + 3 * ctx.P.Tempo) * (if ctx.Rng:NextNumber() < 0.5 then -1 else 1)
		local base = CFrame.new(ctx.LaneX - swing / 2, y - THICK / 2, zc)
		local m = Parts.Obstacle(ctx.Folder, "Gleitplattform", "Slide", base, {
			Offset = Vector3.new(swing, 0, 0),
			Period = 4 / ctx.Speed,
			Phase = ctx.Rng:NextNumber(0, 6),
		})
		Parts.Part({ Name = "Plattform", Size = Vector3.new(s, THICK, s), CFrame = base, Color = ctx.Colors.Deko, Parent = m })
		cur = Vector3.new(ctx.LaneX, y, zc + s / 2)
	end
	if ctx.P.Name ~= "Leicht" then
		local D = 14 + 4 * ctx.P.Tempo
		local y = cur.Y
		local z0 = cur.Z + 2.5 + s / 2
		local base = CFrame.new(ctx.LaneX, y - THICK / 2, z0)
		local m = Parts.Obstacle(ctx.Folder, "Faehre", "Slide", base, {
			Offset = Vector3.new(0, 0, D),
			Period = 5 / ctx.Speed,
			Phase = ctx.Rng:NextNumber(0, 6),
		})
		Parts.Part({ Name = "Faehre", Size = Vector3.new(s, THICK, s), CFrame = base, Color = ctx.Colors.Akzent, Material = Enum.Material.Metal, Parent = m })
		local landZ = z0 + D + s / 2 + 2.5 + s / 2
		plat(ctx, Vector3.new(ctx.LaneX, y, landZ), s, s)
		cur = Vector3.new(ctx.LaneX, y, landZ + s / 2)
	end
	ctx.LastX = ctx.LaneX
	return cur
end

-- ===== Zeitplattformen (erscheinen/verschwinden im Takt) =====
B.Zeitplattform = function(ctx, cur)
	local period = ctx.Takt
	local onTime = period * ctx.P.AnAnteil
	for i = 1, 5 do
		local s = ctx.Size * 0.9
		local gap = Obstacles.Gap(ctx, 0.85)
		local y = Obstacles.NextY(ctx, gap, cur.Y)
		local x = Obstacles.NextX(ctx)
		local top = Vector3.new(x, y, cur.Z + gap + s / 2)
		local base = CFrame.new(top - Vector3.new(0, THICK / 2, 0))
		local m = Parts.Obstacle(ctx.Folder, "Zeitplattform", "Blink", base, {
			Period = period,
			OnTime = onTime,
			Phase = -(i - 1) * period * 0.2,
		})
		Parts.Part({ Name = "Plattform", Size = Vector3.new(s, THICK, s), CFrame = base, Color = TIME_COLOR, Parent = m })
		Parts.Part({
			Name = "Ziffer",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.1, s * 0.6, s * 0.6),
			CFrame = base * CFrame.new(0, THICK / 2 + 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(255, 255, 255),
			Material = Enum.Material.Neon,
			CanCollide = false,
			CanQuery = false,
			Parent = m,
		})
		cur = Vector3.new(x, y, top.Z + s / 2)
	end
	return cur
end

-- ===== Wackelplatten =====
B.Wackel = function(ctx, cur)
	for _ = 1, 3 do
		local s = ctx.Size * 1.1
		local gap = Obstacles.Gap(ctx)
		local y = Obstacles.NextY(ctx, gap, cur.Y)
		local x = Obstacles.NextX(ctx)
		local top = Vector3.new(x, y, cur.Z + gap + s / 2)
		local base = CFrame.new(top - Vector3.new(0, THICK / 2, 0))
		local m = Parts.Obstacle(ctx.Folder, "Wackelplatte", "Wobble", base, {
			Amp = math.rad(ctx.P.Wackelwinkel),
			Period = 3.2 / ctx.Speed * ctx.Rng:NextNumber(0.85, 1.15),
			Phase = ctx.Rng:NextNumber(0, 6),
		})
		Parts.Part({ Name = "Platte", Size = Vector3.new(s, THICK, s), CFrame = base, Color = ctx.Colors.Deko, Parent = m })
		cur = Vector3.new(x, y, top.Z + s / 2)
	end
	return cur
end

-- ===== Laser-Takt =====
B.Laser = function(ctx, cur)
	local W = math.max(ctx.Size, 7)
	local L = 42
	local gap = math.min(Obstacles.Gap(ctx), 6)
	local y = cur.Y
	local z0 = cur.Z + gap
	plat(ctx, Vector3.new(ctx.LaneX, y, z0 + L / 2), W, L, Color3.fromRGB(80, 75, 95))
	local period = ctx.Takt * 0.9
	for i = 1, 3 do
		local z = z0 + L * (i / 4)
		local base = CFrame.new(ctx.LaneX, y, z)
		local m = Parts.Obstacle(ctx.Folder, "Lasertor", "Laser", base, {
			Period = period,
			OnTime = period * 0.5,
			Phase = (i - 1) * period / 3,
		})
		for _, h in ctx.P.LaserHoehen do
			Parts.Part({
				Name = "Strahl",
				Size = Vector3.new(W + 1.5, 0.45, 0.45),
				CFrame = base * CFrame.new(0, h, 0),
				Color = LASER,
				Material = Enum.Material.Neon,
				CanCollide = false,
				Tags = { Tags.Hazard },
				Attrs = { Timed = true },
				Parent = m,
			})
		end
		for _, side in { -1, 1 } do
			Parts.Part({
				Name = "Sender",
				Size = Vector3.new(1, 6, 1),
				CFrame = base * CFrame.new(side * (W / 2 + 1.2), 3, 0),
				Color = ctx.Colors.Akzent,
				Material = Enum.Material.Metal,
				Parent = ctx.Folder,
			})
		end
	end
	ctx.LastX = ctx.LaneX
	return Vector3.new(ctx.LaneX, y, z0 + L)
end

-- ===== Sprungpad =====
B.Sprungpad = function(ctx, cur)
	local s = math.max(ctx.Size * 1.1, 7)
	local gap = Obstacles.Gap(ctx)
	local y = cur.Y
	local padTop = Vector3.new(ctx.LaneX, y, cur.Z + gap + s / 2)
	plat(ctx, padTop, s, s)
	Parts.Cylinder(padTop + Vector3.new(0, 0.4, 0), 2.4, 0.4, {
		Name = "Sprungfeder",
		Color = Color3.fromRGB(120, 255, 140),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Tags = { Tags.JumpPad },
		Attrs = { Up = 82, Forward = 22, Dir = Vector3.zAxis },
		Parent = ctx.Folder,
	})
	local s2 = math.max(ctx.Size * 1.2, 8)
	local y2 = y + 10
	local z2 = padTop.Z + 9 + s2 / 2
	plat(ctx, Vector3.new(ctx.LaneX, y2, z2), s2, s2, ctx.Colors.Akzent)
	ctx.LastX = ctx.LaneX
	return Vector3.new(ctx.LaneX, y2, z2 + s2 / 2)
end

-- ===== Funkenboden: nur die hellen Felder sind sicher =====
B.Funken = function(ctx, cur)
	local t = math.clamp(ctx.Size * 0.55, 3.5, 6)
	local rows = if ctx.P.Tempo > 1.2 then 6 else 5
	local gap = math.min(Obstacles.Gap(ctx), 5)
	local y = cur.Y
	local z0 = cur.Z + gap
	local safeCol = ctx.Rng:NextInteger(1, 3)
	local step = t + 0.3
	for r = 1, rows do
		for c = 1, 3 do
			local top = Vector3.new(ctx.LaneX + (c - 2) * step, y, z0 + (r - 1) * step + t / 2)
			local safe = c == safeCol or (ctx.P.Tempo < 1 and ctx.Rng:NextNumber() < 0.35)
			if safe then
				plat(ctx, top, t, t, Color3.fromRGB(255, 250, 230))
			else
				local tile = Parts.Block(top, Vector3.new(t, THICK, t), {
					Name = "Funken",
					Color = Color3.fromRGB(255, 140, 60),
					Material = Enum.Material.Neon,
					Tags = { Tags.Hazard },
					Parent = ctx.Folder,
				})
				local sparks = Instance.new("ParticleEmitter")
				sparks.Rate = 2
				sparks.Lifetime = NumberRange.new(0.4, 0.8)
				sparks.Speed = NumberRange.new(3, 6)
				sparks.Size = NumberSequence.new(0.3, 0)
				sparks.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120))
				sparks.LightEmission = 1
				sparks.EmissionDirection = Enum.NormalId.Top
				sparks.Parent = tile
			end
		end
		safeCol = math.clamp(safeCol + ctx.Rng:NextInteger(-1, 1), 1, 3)
	end
	ctx.LastX = ctx.LaneX
	return Vector3.new(ctx.LaneX, y, z0 + rows * step)
end

-- ===== Drehringe um eine Säule =====
B.Drehring = function(ctx, cur)
	local Ro, Ri, pillarR = 13, 8.5, 4
	local gap = math.min(Obstacles.Gap(ctx), 6)
	local y = cur.Y
	local center = Vector3.new(ctx.LaneX, y, cur.Z + gap + Ro + 1.75)
	Parts.Cylinder(center, pillarR, THICK, { Name = "Saeule", Color = ctx.Colors.Akzent, Material = Enum.Material.Metal, Parent = ctx.Folder })
	local pivot = CFrame.new(center - Vector3.new(0, THICK / 2, 0))
	local rings = {
		{ R = Ro, N = 12, Miss = 3, Speed = 0.45 },
		{ R = Ri, N = 8, Miss = 2, Speed = -0.6 },
	}
	for _, ring in rings do
		local m = Parts.Obstacle(ctx.Folder, "Drehring", "Spin", pivot, {
			Axis = Vector3.yAxis,
			Speed = ring.Speed * ctx.Speed,
			Phase = ctx.Rng:NextNumber(0, 6),
		})
		local tangential = 2 * math.pi * ring.R / ring.N * 0.85
		for k = ring.Miss + 1, ring.N do
			local a = k / ring.N * math.pi * 2
			Parts.Part({
				Name = "Ringblock",
				Size = Vector3.new(tangential, THICK, 3.5),
				CFrame = pivot * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -ring.R),
				Color = ctx.Colors.Deko,
				Material = Enum.Material.Glass,
				Transparency = 0.15,
				Parent = m,
			})
		end
	end
	ctx.LastX = ctx.LaneX
	return Vector3.new(ctx.LaneX, y, center.Z + Ro + 1.75)
end

Obstacles.Builders = B

-- Geschätzte Wartezeit (Sekunden) pro Hindernis – für die Richtzeit der Zeit-Medaillen
function Obstacles.WaitEstimate(kind: string, ctx: Ctx): number
	local takt = ctx.Takt
	local w = {
		Sprung = 0.3,
		Zahnrad = 1.6,
		Pendel = 1.8,
		Foerderband = 1.2,
		Bewegt = 2.2,
		Zeitplattform = takt * 0.55,
		Wackel = 0.8,
		Laser = takt * 0.55,
		Sprungpad = 0.6,
		Funken = 1.2,
		Drehring = 2.4,
	}
	return w[kind] or 1
end

function Obstacles.Build(kind: string, ctx: Ctx, cur: Vector3): Vector3
	local fn = B[kind] or B.Sprung
	Obstacles.Hint(ctx, kind, cur)
	return fn(ctx, cur)
end

return Obstacles
