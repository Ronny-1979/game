--!strict
--[[
	WorldBuilder – baut die ganze Uhrwerk-Insel aus den Konfig-Dateien.

	📋 COMMAND-BAR-ANLEITUNG (Roblox Studio, Edit-Modus, Rojo verbunden):
	  1. Ansicht (View) → Command Bar einschalten
	  2. Diese Zeile einfügen und Enter drücken:
	       require(game.ServerScriptService.Server.World.WorldBuilder).Build()
	  3. Die Welt erscheint im Workspace unter "UhrwerkWelt". Jetzt speichern (Strg+S).
	  Nach Änderungen an den Konfig-Dateien einfach Schritt 2 wiederholen (die alte Welt wird ersetzt).

	Ohne diesen Schritt baut der Server die Welt beim Start automatisch (wenn keine da ist).
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Zones = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Zones")) :: any
local Builders = script.Parent:WaitForChild("Builders")
local HubBuilder = require(Builders:WaitForChild("HubBuilder"))
local ZoneBuilder = require(Builders:WaitForChild("ZoneBuilder"))
local Parts = require(Builders:WaitForChild("Parts"))
local LightingSetup = require(script.Parent:WaitForChild("Lighting"))

local WorldBuilder = {}

WorldBuilder.Version = 2

function WorldBuilder.ApplyLighting()
	LightingSetup.Apply()
end

-- Gestein unter den Inseln je Ort (Terrain-Materialien) + pastellige Farben dafür
local ROCKS = {
	Hub = { Fels = Enum.Material.Rock, Fels2 = Enum.Material.Ground },
	Wiese = { Fels = Enum.Material.Rock, Fels2 = Enum.Material.Ground },
	Werkstatt = { Fels = Enum.Material.Sandstone, Fels2 = Enum.Material.Rock },
	Schlucht = { Fels = Enum.Material.Slate, Fels2 = Enum.Material.Basalt },
	Kristall = { Fels = Enum.Material.Glacier, Fels2 = Enum.Material.Slate },
	Uhrwerk = { Fels = Enum.Material.Sandstone, Fels2 = Enum.Material.Brick },
	Sternwarte = { Fels = Enum.Material.Basalt, Fels2 = Enum.Material.Slate },
	Tiefsee = { Fels = Enum.Material.Limestone, Fels2 = Enum.Material.Salt },
}
local ROCK_COLORS = {
	[Enum.Material.Rock] = Color3.fromRGB(180, 160, 145),
	[Enum.Material.Ground] = Color3.fromRGB(155, 125, 100),
	[Enum.Material.Sandstone] = Color3.fromRGB(225, 175, 130),
	[Enum.Material.Slate] = Color3.fromRGB(150, 140, 175),
	[Enum.Material.Basalt] = Color3.fromRGB(95, 90, 130),
	[Enum.Material.Glacier] = Color3.fromRGB(175, 225, 245),
	[Enum.Material.Brick] = Color3.fromRGB(205, 135, 100),
	[Enum.Material.Limestone] = Color3.fromRGB(225, 215, 190),
	[Enum.Material.Salt] = Color3.fromRGB(240, 236, 230),
}

-- Eier-Station aus der aktuellen Konfig neu bauen (läuft bei jedem Serverstart)
function WorldBuilder.RefreshEggs()
	local world = workspace:FindFirstChild("UhrwerkWelt")
	if world then
		HubBuilder.RefreshEggStation(world)
	end
end

function WorldBuilder.Build(): Folder
	local t0 = os.clock()
	local old = workspace:FindFirstChild("UhrwerkWelt")
	if old then
		old:Destroy()
	end
	local world = Instance.new("Folder")
	world.Name = "UhrwerkWelt"
	world:SetAttribute("BuilderVersion", WorldBuilder.Version)

	-- Terrain gehört komplett zur Welt: alte Felsen weg, Farben setzen
	local terrain = workspace.Terrain
	terrain:Clear()
	for mat, color in ROCK_COLORS do
		terrain:SetMaterialColor(mat, color)
	end

	Parts.TerrainStyle = ROCKS.Hub
	HubBuilder.Build(world)
	for i, zone in ipairs(Zones) do
		Parts.TerrainStyle = ROCKS[zone.Id] or ROCKS.Hub
		ZoneBuilder.Build(world, i, zone)
		task.wait() -- Studio zwischendurch atmen lassen
	end
	-- zur Laufzeit gebaute Inseln (Werkstätten) nutzen wieder Part-Felsen
	Parts.TerrainStyle = nil

	-- andere SpawnLocations (z.B. aus der Vorlage) ausschalten, damit alle im Hub starten
	for _, inst in workspace:GetDescendants() do
		if inst:IsA("SpawnLocation") then
			inst.Enabled = false
		end
	end
	-- die graue Grundplatte der Studio-Vorlage würde man unter den Inseln sehen → unsichtbar machen
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Transparency = 1
		baseplate.CanCollide = false
		baseplate.CanQuery = false
		baseplate.CanTouch = false
		for _, child in baseplate:GetChildren() do
			if child:IsA("Texture") or child:IsA("Decal") then
				child.Transparency = 1
			end
		end
	end
	world.Parent = workspace
	LightingSetup.Apply()

	local count = 0
	for _, d in world:GetDescendants() do
		if d:IsA("BasePart") then
			count += 1
		end
	end
	print(("[WorldBuilder] Welt gebaut: %d Teile, %d Hindernisse, %.2f s"):format(count, #CollectionService:GetTagged("Obstacle"), os.clock() - t0))
	return world
end

return WorldBuilder
