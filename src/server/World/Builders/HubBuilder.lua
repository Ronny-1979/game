--!strict
--[[
	HubBuilder: die zentrale Hub-Insel
	Uhrturm, Spawn, Upgrade-Shop, Pet-Eier-Station, Rebirth-Altar, Skill-Lehrer, Bestenliste, Zonen-Teleporter.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Pets = require(Config:WaitForChild("Pets")) :: any
local Tags = require(Shared:WaitForChild("Tags"))
local Util = require(Shared:WaitForChild("Util"))
local Parts = require(script.Parent:WaitForChild("Parts"))
local ZoneBuilder = require(script.Parent:WaitForChild("ZoneBuilder"))
local Decor = require(script.Parent:WaitForChild("Decor"))

local HubBuilder = {}

local BRASS = Color3.fromRGB(215, 170, 80)
local COPPER = Color3.fromRGB(200, 120, 75)
local CREAM = Color3.fromRGB(255, 240, 210)
local GRASS = Color3.fromRGB(160, 220, 140)

-- Menü-Station: Teil mit ProximityPrompt, Attribut "Menu" sagt dem Client, welches Menü aufgeht
local function station(parent: Instance, pos: Vector3, menu: string, action: string, title: string, color: Color3, extra: { [string]: any }?): Part
	local base = Parts.Block(pos + Vector3.new(0, 3, 0), Vector3.new(8, 3, 5), {
		Name = "Theke_" .. menu,
		Color = color,
		Material = Enum.Material.Wood,
		Tags = { Tags.MenuPrompt },
		Attrs = { Menu = menu },
		Parent = parent,
	})
	if extra then
		for k, v in extra do
			base:SetAttribute(k, v)
		end
	end
	Parts.Prompt(base, action, title)
	-- Dach
	for _, side in { -1, 1 } do
		Parts.Part({ Name = "Pfosten", Size = Vector3.new(0.6, 9, 0.6), CFrame = CFrame.new(pos + Vector3.new(side * 4.5, 4.5, 2.5)), Color = BRASS, Material = Enum.Material.Metal, Parent = parent })
	end
	local roof = Parts.Part({
		Name = "Dach",
		Size = Vector3.new(11, 1, 7),
		CFrame = CFrame.new(pos + Vector3.new(0, 9.5, 1)),
		Color = color:Lerp(Color3.new(1, 1, 1), 0.3),
		Parent = parent,
	})
	Parts.SurfaceText(roof, title, Enum.NormalId.Front)
	Parts.SurfaceText(roof, title, Enum.NormalId.Back)
	Parts.Billboard(base, title, 8, Vector2.new(220, 50))
	return base
end

local function tree(parent: Instance, pos: Vector3, color: Color3)
	Parts.Part({ Name = "Stamm", Size = Vector3.new(1.4, 7, 1.4), CFrame = CFrame.new(pos + Vector3.new(0, 3.5, 0)), Color = Color3.fromRGB(150, 105, 70), Material = Enum.Material.Wood, Parent = parent })
	Parts.Part({
		Name = "Krone",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(7, 7, 7),
		CFrame = CFrame.new(pos + Vector3.new(0, 9, 0)),
		Color = color,
		Material = Enum.Material.Grass,
		Parent = parent,
	})
end

local function clockTower(parent: Instance, H: Vector3)
	Parts.Cylinder(H + Vector3.new(0, 2, 0), 16, 2, { Name = "Turmsockel", Color = COPPER, Material = Enum.Material.Brick, Parent = parent })
	Parts.Block(H + Vector3.new(0, 42, 0), Vector3.new(16, 40, 16), { Name = "Turm", Color = CREAM, Material = Enum.Material.Brick, Parent = parent })
	Parts.Block(H + Vector3.new(0, 46, 0), Vector3.new(19, 4, 19), { Name = "Turmkranz", Color = BRASS, Material = Enum.Material.Metal, Parent = parent })
	-- Uhren auf allen vier Seiten mit drehenden Zeigern
	for i = 0, 3 do
		local face = CFrame.new(H + Vector3.new(0, 34, 0)) * CFrame.Angles(0, i * math.pi / 2, 0) * CFrame.new(0, 0, -8.3)
		Parts.Part({
			Name = "Zifferblatt",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, 11, 11),
			CFrame = face * CFrame.Angles(0, math.rad(90), 0),
			Color = Color3.fromRGB(255, 252, 240),
			Parent = parent,
		})
		local pivot = face * CFrame.new(0, 0, -0.5)
		local hour = Parts.Obstacle(parent, "Stundenzeiger", "Spin", pivot, { Axis = Vector3.zAxis, Speed = -0.05, Phase = i })
		Parts.Part({ Name = "Zeiger", Size = Vector3.new(0.6, 3.2, 0.3), CFrame = pivot * CFrame.new(0, 1.4, 0), Color = Color3.fromRGB(60, 45, 35), CanCollide = false, Parent = hour })
		local minute = Parts.Obstacle(parent, "Minutenzeiger", "Spin", pivot, { Axis = Vector3.zAxis, Speed = -0.6, Phase = i * 2 })
		Parts.Part({ Name = "Zeiger", Size = Vector3.new(0.4, 4.6, 0.3), CFrame = pivot * CFrame.new(0, 2.1, -0.1), Color = COPPER, CanCollide = false, Parent = minute })
	end
	-- großes Zahnrad oben
	ZoneBuilder.SpinningGear(parent, CFrame.new(H + Vector3.new(0, 52, 0)), 9, BRASS, 0.25)
	ZoneBuilder.SpinningGear(parent, CFrame.new(H + Vector3.new(0, 56, 0)), 5, COPPER, -0.5)
end

local function eggStation(parent: Instance, H: Vector3)
	for k, eggId in Pets.EierReihenfolge do
		local egg = Pets.Eier[eggId]
		local pos = H + Vector3.new(62, 0, 55 - (k - 1) * 17)
		Parts.Cylinder(pos + Vector3.new(0, 2, 0), 4, 2, { Name = "EiSockel", Color = BRASS, Material = Enum.Material.Metal, Parent = parent })
		local eggPart = Parts.Part({
			Name = egg.Name,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(5, 5, 5),
			CFrame = CFrame.new(pos + Vector3.new(0, 5.2, 0)),
			Color = egg.Farbe,
			Material = Enum.Material.SmoothPlastic,
			Tags = { Tags.EggStation, Tags.MenuPrompt },
			Attrs = { EggId = eggId, Menu = "Ei" },
			Parent = parent,
		})
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.new(1, 1.3, 1)
		mesh.Parent = eggPart
		local price = if egg.Waehrung == "Rebirth" then ("%d ♻️"):format(egg.Preis) else (Util.FormatNumber(egg.Preis) .. " ⚡")
		Parts.Prompt(eggPart, "Öffnen", ("%s – %s"):format(egg.Name, price))
		Parts.Billboard(eggPart, ("🥚 %s\n%s"):format(egg.Name, price), 5, Vector2.new(180, 55))
	end
	Parts.Sign(parent, H + Vector3.new(48, 0, 72), "🥚 Pet-Eier-Station\nJede Zone hat ihr eigenes Ei!", 13, 4.5, Vector3.new(-1, 0, 0))
end

local function teacher(parent: Instance, H: Vector3)
	local pos = H + Vector3.new(-58, 0, -30)
	station(parent, pos, "Skills", "Lernen", "🎓 Skill-Lehrer", Color3.fromRGB(150, 180, 255))
	-- kleiner Lehrer-Roboter
	local body = Parts.Block(pos + Vector3.new(0, 6, -4.5), Vector3.new(3, 4, 2.5), { Name = "Lehrer", Color = Color3.fromRGB(150, 180, 255), Material = Enum.Material.Metal, Parent = parent })
	Parts.Part({ Name = "Kopf", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), CFrame = body.CFrame * CFrame.new(0, 3.3, 0), Color = Color3.fromRGB(230, 235, 255), Parent = parent })
	Parts.Part({ Name = "Hut", Size = Vector3.new(3.4, 0.4, 3.4), CFrame = body.CFrame * CFrame.new(0, 5, 0), Color = Color3.fromRGB(60, 60, 90), Parent = parent })
	for _, side in { -1, 1 } do
		Parts.Part({ Name = "Auge", Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.7, 0.7), CFrame = body.CFrame * CFrame.new(side * 0.6, 3.5, 1.4), Color = Color3.fromRGB(90, 200, 255), Material = Enum.Material.Neon, Parent = parent })
	end
end

local function rebirthAltar(parent: Instance, H: Vector3)
	local pos = H + Vector3.new(-100, 0, 10)
	Parts.Cylinder(pos + Vector3.new(0, 1.5, 0), 9, 1.5, { Name = "AltarStufe", Color = Color3.fromRGB(240, 220, 255), Material = Enum.Material.Marble, Parent = parent })
	local altar = Parts.Block(pos + Vector3.new(0, 5, 0), Vector3.new(5, 3.5, 5), {
		Name = "RebirthAltar",
		Color = Color3.fromRGB(255, 160, 130),
		Material = Enum.Material.Marble,
		Tags = { Tags.MenuPrompt },
		Attrs = { Menu = "Rebirth" },
		Parent = parent,
	})
	Parts.Prompt(altar, "Rebirth", "♻️ Rebirth-Altar")
	Parts.Billboard(altar, "♻️ Rebirth-Altar", 6, Vector2.new(200, 50))
	local ring = Parts.Obstacle(parent, "AltarRing", "Spin", CFrame.new(pos + Vector3.new(0, 10, 0)), { Axis = Vector3.yAxis, Speed = 0.8 })
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		Parts.Part({
			Name = "Funke",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.2, 1.2, 1.2),
			CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 5, 10, math.sin(a) * 5)),
			Color = Color3.fromRGB(255, 200, 140),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = ring,
		})
	end
end

local function teleporters(parent: Instance, H: Vector3)
	for i, zone in ipairs(Zones) do
		local pos = H + Vector3.new(-100 + (i - 1) * 50, 0, -108)
		Parts.Cylinder(pos + Vector3.new(0, 0.6, 0), 6, 0.6, {
			Name = "Teleporter_" .. zone.Id,
			Color = zone.Farben.Boden,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Tags = { Tags.ZoneTeleporter },
			Attrs = { ZoneIndex = i },
			Parent = parent,
		})
		Parts.Cylinder(pos + Vector3.new(0, 0.3, 0), 7, 0.3, { Name = "Ring", Color = zone.Farben.Akzent, Material = Enum.Material.Metal, Parent = parent })
		for _, side in { -1, 1 } do
			Parts.Part({ Name = "Bogen", Size = Vector3.new(1.2, 14, 1.2), CFrame = CFrame.new(pos + Vector3.new(side * 7, 7, 0)), Color = zone.Farben.Akzent, Material = Enum.Material.Metal, Parent = parent })
		end
		local top = Parts.Part({ Name = "Bogendach", Size = Vector3.new(15.2, 1.4, 1.4), CFrame = CFrame.new(pos + Vector3.new(0, 14, 0)), Color = zone.Farben.Akzent, Material = Enum.Material.Metal, Parent = parent })
		Parts.Billboard(top, ("%d · %s\nab Level %d"):format(i, zone.Name, zone.FreischaltLevel), 4, Vector2.new(240, 60))
	end
	Parts.Sign(parent, H + Vector3.new(0, 0, -86), "🌀 Zonen-Teleporter\nStell dich auf ein Feld!", 14, 4.5, Vector3.new(0, 0, 1))
end

function HubBuilder.Build(world: Instance)
	local H = Settings.HubCenter
	local folder = Parts.Folder("Hub", world)
	Parts.Island(folder, H, 150, GRASS, BRASS)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(H + Vector3.new(0, 0.5, 70))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(255, 230, 160)
	spawn.Material = Enum.Material.Neon
	spawn.TopSurface = Enum.SurfaceType.Smooth
	game:GetService("CollectionService"):AddTag(spawn, Tags.HubSpawn)
	spawn.Parent = folder

	clockTower(folder, H)
	station(folder, H + Vector3.new(-58, 0, 30), "Shop", "Öffnen", "🛒 Upgrade-Shop", Color3.fromRGB(255, 200, 120))
	station(folder, H + Vector3.new(100, 0, -40), "Bestenliste", "Ansehen", "🏆 Bestenliste", Color3.fromRGB(255, 230, 120))
	teacher(folder, H)
	rebirthAltar(folder, H)
	eggStation(folder, H)
	teleporters(folder, H)

	Parts.Sign(folder, H + Vector3.new(0, 0, 52), "Willkommen auf der Uhrwerk-Insel! ⚙️\nRepariere das Uhrwerk mit deinem Team!", 18, 6, Vector3.new(0, 0, 1))
	Parts.Sign(folder, H + Vector3.new(-24, 0, 70), "Menü-Knöpfe links ◀\nKarte 🗺️ = schnell reisen", 12, 4.5, Vector3.new(0, 0, 1))

	for i = 1, 14 do
		local a = i / 14 * math.pi * 2
		local r = 128
		tree(folder, H + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r), Color3.fromRGB(150 + (i % 3) * 30, 210, 140 + (i % 2) * 60))
	end
	-- Deko: Blumen & Co. am Rand, Wolken darunter, Mini-Inseln drumherum
	local hubColors = { Boden = GRASS, Akzent = BRASS, Deko = Color3.fromRGB(255, 180, 200) }
	Decor.Scatter(folder, H, 112, 146, 50, hubColors, 7, function(rel)
		return rel.Z < -90 or (math.abs(rel.X) < 16 and rel.Z > 40)
	end)
	Decor.Clouds(folder, H, 150, 8)
	Decor.FloatingIslands(folder, H, 250, 9, hubColors, 9)

	for i = 1, 6 do
		local a = i / 6 * math.pi * 2 + 0.3
		ZoneBuilder.SpinningGear(folder, CFrame.new(H + Vector3.new(math.cos(a) * 175, 25, math.sin(a) * 175)) * CFrame.Angles(math.rad(80), a, 0), 12, if i % 2 == 0 then BRASS else COPPER, 0.2 * (if i % 2 == 0 then 1 else -1))
	end
end

return HubBuilder
