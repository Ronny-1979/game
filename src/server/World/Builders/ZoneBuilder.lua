--!strict
--[[
	ZoneBuilder: baut eine komplette Zone aus der Konfig.
	Platz mit Spawn + Portalen, Startterrasse, 3 Strecken × 3 Bahnen, Energie-Insel,
	Gegner-Insel, Boss-Arena und Co-op-Rätsel.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Difficulty = require(Config:WaitForChild("Difficulty")) :: any
local Bosses = require(Config:WaitForChild("Bosses")) :: any
local Enemies = require(Config:WaitForChild("Enemies")) :: any
local Tags = require(Shared:WaitForChild("Tags"))
local Parts = require(script.Parent:WaitForChild("Parts"))
local TrackBuilder = require(script.Parent:WaitForChild("TrackBuilder"))
local CoopBuilder = require(script.Parent:WaitForChild("CoopBuilder"))
local Decor = require(script.Parent:WaitForChild("Decor"))
local SecretBuilder = require(script.Parent:WaitForChild("SecretBuilder"))
local Backdrop = require(script.Parent:WaitForChild("Backdrop"))

local ZoneBuilder = {}

local WOOD = Color3.fromRGB(200, 150, 100)
local TRACK_X = { -120, 0, 120 }
local LANE_SPACING = 34

function ZoneBuilder.Origin(index: number): Vector3
	return Vector3.new(index * Settings.ZoneSpacing, Settings.HubCenter.Y, 0)
end

local function lamp(parent: Instance, pos: Vector3, color: Color3)
	Parts.Part({ Name = "Laternenmast", Size = Vector3.new(0.6, 8, 0.6), CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)), Color = Color3.fromRGB(120, 90, 60), Material = Enum.Material.Metal, Parent = parent })
	local bulb = Parts.Part({
		Name = "Laterne",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.8, 1.8, 1.8),
		CFrame = CFrame.new(pos + Vector3.new(0, 8.5, 0)),
		Color = color,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = parent,
	})
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 170)
	light.Range = 18
	light.Brightness = 1.2
	light.Shadows = false
	light.Parent = bulb
end

function ZoneBuilder.SpinningGear(parent: Instance, cf: CFrame, radius: number, color: Color3, speed: number)
	local m = Parts.Obstacle(parent, "DekoZahnrad", "Spin", cf, { Axis = Vector3.yAxis, Speed = speed, Phase = 0 })
	local list = Parts.Gear(m, cf, radius, 0.8, math.max(8, math.floor(radius * 2)), color, false)
	-- kleine Funken an der Nabe (wirkt, als würde das Uhrwerk arbeiten)
	local hub = list[1]
	if hub and radius >= 4 then
		local sparks = Instance.new("ParticleEmitter")
		sparks.Rate = 2
		sparks.Lifetime = NumberRange.new(0.4, 0.8)
		sparks.Speed = NumberRange.new(4, 8)
		sparks.SpreadAngle = Vector2.new(180, 180)
		sparks.Acceleration = Vector3.new(0, -20, 0)
		sparks.Size = NumberSequence.new(0.18, 0)
		sparks.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 150, 60))
		sparks.LightEmission = 1
		sparks.Parent = hub
	end
end

function ZoneBuilder.Portal(parent: Instance, pos: Vector3, faceTo: Vector3, target: number, text: string, color: Color3): BasePart
	local cf = CFrame.lookAt(pos + Vector3.new(0, 7, 0), Vector3.new(faceTo.X, pos.Y + 7, faceTo.Z))
	for _, side in { -1, 1 } do
		Parts.Part({ Name = "Saeule", Size = Vector3.new(1.6, 15, 1.6), CFrame = cf * CFrame.new(side * 6, 0.5, 0), Color = color, Material = Enum.Material.Metal, Parent = parent })
	end
	Parts.Part({ Name = "Sturz", Size = Vector3.new(13.6, 1.6, 1.6), CFrame = cf * CFrame.new(0, 8, 0), Color = color, Material = Enum.Material.Metal, Parent = parent })
	Parts.Gear(parent, cf * CFrame.new(0, 9.5, 0) * CFrame.Angles(math.rad(90), 0, 0), 2.5, 0.8, 10, Color3.fromRGB(255, 215, 90), false)
	local face = Parts.Part({
		Name = "Portal",
		Size = Vector3.new(10.4, 14, 0.6),
		CFrame = cf,
		Color = Color3.fromRGB(150, 220, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanCollide = false,
		Tags = { Tags.Portal },
		Attrs = { Target = target },
		Parent = parent,
	})
	Parts.Billboard(face, text, 10, Vector2.new(260, 60))
	return face
end

local function buildPlaza(folder: Instance, index: number, zone: any, O: Vector3)
	local C = zone.Farben
	Parts.Island(folder, O, 72, C.Boden, C.Akzent)
	Parts.Cylinder(O + Vector3.new(0, 0.3, 0), 6, 0.3, {
		Name = "ZonenSpawn",
		Color = Color3.fromRGB(255, 245, 210),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Tags = { Tags.ZoneSpawn },
		Attrs = { ZoneIndex = index },
		Parent = folder,
	})
	Parts.Sign(folder, O + Vector3.new(0, 0, 28), ("%s\n%s"):format(zone.Name, zone.Beschreibung), 18, 6, Vector3.new(0, 0, -1))
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		lamp(folder, O + Vector3.new(math.cos(a) * 64, 0, math.sin(a) * 64), C.Deko)
	end
	for i = 1, 4 do
		local a = i / 4 * math.pi * 2 + 0.4
		ZoneBuilder.SpinningGear(folder, CFrame.new(O + Vector3.new(math.cos(a) * 85, 18, math.sin(a) * 85)) * CFrame.Angles(math.rad(70), 0, 0), 8, C.Akzent, 0.3 * (if i % 2 == 0 then 1 else -1))
	end
	-- Portale
	ZoneBuilder.Portal(folder, O + Vector3.new(-40, 0, -40), O, 0, "🏝️ Zurück zum Hub", C.Akzent)
	local nextZone = Zones[index + 1]
	if nextZone then
		ZoneBuilder.Portal(
			folder,
			O + Vector3.new(40, 0, -40),
			O,
			index + 1,
			("➡️ %s\n(ab Lv. %d oder Boss besiegen)"):format(nextZone.Name, nextZone.FreischaltLevel),
			C.Akzent
		)
	end
	if zone.Tutorial then
		Parts.Sign(folder, O + Vector3.new(-18, 0, 12), Zones.Hinweise.Faehigkeiten, 12, 4.5, Vector3.new(0, 0, -1))
	end
end

local function buildTracks(folder: Instance, index: number, zone: any, O: Vector3)
	local C = zone.Farben
	-- Startterrasse
	Parts.Block(O + Vector3.new(0, 0.04, 84), Vector3.new(350, 2, 32), {
		Name = "Startterrasse",
		Color = C.Plattform,
		Material = Enum.Material.WoodPlanks,
		Parent = folder,
	})
	for t, track in zone.Strecken do
		local trackX = O.X + TRACK_X[t]
		local tf = Parts.Model(("Strecke%d_%s"):format(t, track.Name), folder)
		-- Tor mit Namen
		for _, side in { -1, 1 } do
			Parts.Part({ Name = "Torpfosten", Size = Vector3.new(1.5, 18, 1.5), CFrame = CFrame.new(trackX + side * 52, O.Y + 9, O.Z + 96), Color = C.Akzent, Material = Enum.Material.Metal, Parent = tf })
		end
		local board = Parts.Part({
			Name = "Tor",
			Size = Vector3.new(60, 5, 0.8),
			CFrame = CFrame.new(trackX, O.Y + 20, O.Z + 96),
			Color = Color3.fromRGB(255, 244, 220),
			Parent = tf,
		})
		local label = ("Strecke %d: %s"):format(t, track.Name)
		Parts.SurfaceText(board, label, Enum.NormalId.Front)
		Parts.SurfaceText(board, label, Enum.NormalId.Back)
		Parts.Part({ Name = "Torbalken", Size = Vector3.new(106, 1.2, 1.2), CFrame = CFrame.new(trackX, O.Y + 17.4, O.Z + 96), Color = C.Akzent, Material = Enum.Material.Metal, Parent = tf })
		for k, diff in Difficulty.Reihenfolge do
			TrackBuilder.BuildLane(tf, {
				ZoneIndex = index,
				TrackIndex = t,
				Track = track,
				Diff = diff,
				LaneX = trackX + (k - 2) * LANE_SPACING,
				StartZ = O.Z + 100,
				Y = O.Y,
				Colors = C,
				F = zone.Schwierigkeit,
				Hints = zone.Tutorial == true,
				Seed = index * 1000 + t * 10 + k,
			})
		end
		if zone.Tutorial and t == 1 then
			Parts.Sign(tf, Vector3.new(trackX - 52, O.Y, O.Z + 80), Zones.Hinweise.Start, 12, 4.5, Vector3.new(0, 0, -1))
		end
	end
end

local function buildEnergy(folder: Instance, index: number, zone: any, O: Vector3)
	local C = zone.Farben
	local E = O + Vector3.new(-215, 0, -60)
	local dir = (Vector3.new(E.X, O.Y, E.Z) - O).Unit
	Parts.Island(folder, E, 50, C.Boden:Lerp(Color3.fromRGB(160, 235, 255), 0.35), C.Akzent)
	Parts.Bridge(folder, O + dir * 66, E - dir * 46, 14, WOOD)
	local ef = Parts.Folder("EnergieFeld", folder)
	Parts.Part({
		Name = "EnergieFeld",
		Size = Vector3.new(56, 0.3, 56),
		CFrame = CFrame.new(E + Vector3.new(0, 0.16, 0)),
		Color = Color3.fromRGB(140, 230, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.6,
		CanCollide = false,
		CanQuery = false,
		Tags = { Tags.EnergyField },
		Attrs = { ZoneIndex = index },
		Parent = ef,
	})
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		local p = E + Vector3.new(math.cos(a) * 22, 0, math.sin(a) * 22)
		Parts.Cylinder(p + Vector3.new(0, 1, 0), 2.6, 1, { Name = "Sockel", Color = Color3.fromRGB(170, 150, 130), Material = Enum.Material.Slate, Parent = ef })
		local crystal = Parts.Part({
			Name = "EnergieKristall",
			Size = Vector3.new(3, 7, 3),
			CFrame = CFrame.new(p + Vector3.new(0, 4.6, 0)) * CFrame.Angles(0, a, math.rad(12)),
			Color = C.Deko:Lerp(Color3.fromRGB(140, 230, 255), 0.5),
			Material = Enum.Material.Neon,
			Transparency = 0.15,
			Tags = { Tags.EnergyCrystal },
			Attrs = { ZoneIndex = index },
			Parent = ef,
		})
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = Settings.Energy.ClickDistance
		cd.Parent = crystal
	end
	Parts.Sign(folder, E + Vector3.new(0, 0, 40), "⚡ Energie-Feld\nKlicke die Kristalle & lauf durchs Feld!", 14, 5, Vector3.new(0, 0, -1))
	if zone.Tutorial then
		Parts.Sign(folder, O + dir * 60 + Vector3.new(0, 0, 10), Zones.Hinweise.Energie, 11, 4.5, -dir)
	end
end

local function buildEnemies(folder: Instance, index: number, zone: any, O: Vector3)
	local C = zone.Farben
	local G = O + Vector3.new(215, 0, -60)
	local dir = (Vector3.new(G.X, O.Y, G.Z) - O).Unit
	Parts.Island(folder, G, 52, C.Boden:Lerp(Color3.fromRGB(190, 150, 120), 0.4), C.Akzent)
	Parts.Bridge(folder, O + dir * 66, G - dir * 48, 14, WOOD)
	-- mehrere Gegner-Arten erlaubt: { {Typ, Anzahl}, ... } (alte Form {Typ, Anzahl} geht auch)
	local list = if zone.Gegner.Typ then { zone.Gegner } else zone.Gegner
	local names = {}
	for k, entry in list do
		local cfg = Enemies[entry.Typ]
		if cfg then
			table.insert(names, cfg.Name)
		end
		local a = (k - 1) / #list * math.pi * 2
		local offset = if k == 1 then Vector3.zero else Vector3.new(math.cos(a) * 12, 0, math.sin(a) * 12)
		Parts.Part({
			Name = "GegnerSpawn_" .. entry.Typ,
			Size = Vector3.new(2, 1, 2),
			CFrame = CFrame.new(G + offset + Vector3.new(0, 0.5, 0)),
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Tags = { Tags.EnemySpawn },
			Attrs = { EnemyType = entry.Typ, Count = entry.Anzahl, Radius = if k == 1 then 38 else 30, ZoneIndex = index },
			Parent = folder,
		})
	end
	for i = 1, 16 do
		local a = i / 16 * math.pi * 2
		Parts.Part({
			Name = "Zaun",
			Size = Vector3.new(1, 3, 1),
			CFrame = CFrame.new(G + Vector3.new(math.cos(a) * 48, 1.5, math.sin(a) * 48)),
			Color = C.Akzent,
			Material = Enum.Material.Metal,
			Parent = folder,
		})
	end
	Parts.Sign(folder, O + dir * 62 + Vector3.new(0, 0, 10), "🤖 Gegner-Arena\n" .. table.concat(names, ", "), 12, 4.5, -dir)
	if zone.Tutorial then
		Parts.Sign(folder, O + dir * 62 + Vector3.new(0, 0, -10), Zones.Hinweise.Gegner, 11, 4.5, -dir)
	end
end

local function buildBoss(folder: Instance, index: number, zone: any, O: Vector3)
	local C = zone.Farben
	local Bp = O + Vector3.new(0, 0, -255)
	local top = Parts.Island(folder, Bp, 64, C.Boden:Lerp(Color3.fromRGB(255, 200, 200), 0.25), C.Akzent)
	CollectionService:AddTag(top, Tags.BossArena)
	top:SetAttribute("ZoneIndex", index)
	top:SetAttribute("BossId", zone.Boss)
	top:SetAttribute("Radius", 60)
	top:SetAttribute("FloorY", Bp.Y)
	top.Material = Enum.Material.Cobblestone
	Parts.Bridge(folder, O + Vector3.new(0, 0, -66), Bp + Vector3.new(0, 0, 62), 16, WOOD)
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		local p = Bp + Vector3.new(math.cos(a) * 62, 0, math.sin(a) * 62)
		if math.abs(math.cos(a)) > 0.2 or math.sin(a) < 0 then -- Lücke für die Brücke
			Parts.Part({ Name = "Saeule", Size = Vector3.new(3, 14, 3), CFrame = CFrame.new(p + Vector3.new(0, 7, 0)), Color = C.Akzent, Material = Enum.Material.Marble, Parent = folder })
			lamp(folder, p + Vector3.new(0, 14, 0), C.Deko)
		end
	end
	local boss = Bosses[zone.Boss]
	Parts.Sign(folder, O + Vector3.new(12, 0, -72), ("👑 Boss: %s"):format(boss and boss.Name or "?"), 12, 4, Vector3.new(0, 0, 1))
	if zone.Tutorial then
		Parts.Sign(folder, O + Vector3.new(-12, 0, -72), Zones.Hinweise.Boss, 11, 4.5, Vector3.new(0, 0, 1))
	end
end

local function buildCoop(folder: Instance, index: number, zone: any, O: Vector3)
	if not zone.Coop or #zone.Coop == 0 then
		return
	end
	local C = zone.Farben
	local cf = Parts.Folder("CoopRaetsel", folder)
	local leftEnd: number? = nil
	for k, kind in zone.Coop do
		local id = ("Z%d_%s_%d"):format(index, kind, k)
		if k == 1 or k == 2 then
			local side = if k == 1 then -1 else 1
			local entry = O + Vector3.new(side * 265, 0, 125)
			Parts.Bridge(cf, O + Vector3.new(side * 170, 0, 84), entry + Vector3.new(0, 0, -1), 12, WOOD)
			local endZ = CoopBuilder.Build(cf, entry, kind, id, index, C, zone.Schwierigkeit)
			if k == 1 then
				leftEnd = endZ
			end
		else
			local startZ = (leftEnd or (O.Z + 230)) + 30
			local entry = Vector3.new(O.X - 265, O.Y, startZ)
			Parts.Bridge(cf, Vector3.new(O.X - 265, O.Y, startZ - 31), entry, 12, WOOD)
			CoopBuilder.Build(cf, entry, kind, id, index, C, zone.Schwierigkeit)
		end
	end
end

-- Blumen, Felsen, Wolken und Mini-Inseln (nicht auf Wegen und Brücken)
local function buildDecor(folder: Instance, index: number, zone: any, O: Vector3)
	local C = zone.Farben
	local flat = Vector3.new(O.X, O.Y, O.Z)
	local E = O + Vector3.new(-215, 0, -60)
	local G = O + Vector3.new(215, 0, -60)
	local Bp = O + Vector3.new(0, 0, -255)
	local dirE = (E - flat).Unit
	local dirG = (G - flat).Unit
	local portals = { Vector3.new(-40, 0, -40), Vector3.new(40, 0, -40) }
	Decor.Scatter(folder, O, 44, 68, 28, C, index * 100 + 1, function(rel)
		if rel.Z > 50 or (math.abs(rel.X) < 12 and rel.Z < -40) then
			return true
		end
		local u = rel.Unit
		if u:Dot(dirE) > 0.96 or u:Dot(dirG) > 0.96 then
			return true
		end
		for _, p in portals do
			if (rel - p).Magnitude < 10 then
				return true
			end
		end
		return false
	end)
	Decor.Scatter(folder, E, 41, 48, 10, C, index * 100 + 2, function(rel)
		return rel.Unit:Dot(-dirE) > 0.9
	end)
	Decor.Scatter(folder, G, 40, 46, 10, C, index * 100 + 3, function(rel)
		return rel.Unit:Dot(-dirG) > 0.9
	end)
	Decor.Scatter(folder, Bp, 56, 61, 12, C, index * 100 + 4, function(rel)
		return rel.Z > 40 and math.abs(rel.X) < 14
	end)
	for k, island in { { O, 72 }, { E, 50 }, { G, 52 }, { Bp, 64 } } do
		Decor.Clouds(folder, island[1], island[2], index * 100 + 10 + k)
	end
	-- nicht über den Strecken (die gehen nach +Z)
	Decor.FloatingIslands(folder, O, 380, 9, C, index * 100 + 20, function(rel)
		return rel.Z > 40 and math.abs(rel.X) < 320
	end)
end

function ZoneBuilder.Build(world: Instance, index: number, zone: any)
	local O = ZoneBuilder.Origin(index)
	local folder = Parts.Folder(("Zone%d_%s"):format(index, zone.Id), world)
	buildPlaza(folder, index, zone, O)
	buildTracks(folder, index, zone, O)
	buildEnergy(folder, index, zone, O)
	buildEnemies(folder, index, zone, O)
	buildBoss(folder, index, zone, O)
	buildCoop(folder, index, zone, O)
	buildDecor(folder, index, zone, O)
	SecretBuilder.BuildZone(folder, index, O)
	Backdrop.Zone(folder, index, zone, O)
end

return ZoneBuilder
