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
local LightingSetup = require(script.Parent:WaitForChild("Lighting"))

local WorldBuilder = {}

WorldBuilder.Version = 1

function WorldBuilder.ApplyLighting()
	LightingSetup.Apply()
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

	HubBuilder.Build(world)
	for i, zone in ipairs(Zones) do
		ZoneBuilder.Build(world, i, zone)
	end

	-- andere SpawnLocations (z.B. aus der Vorlage) ausschalten, damit alle im Hub starten
	for _, inst in workspace:GetDescendants() do
		if inst:IsA("SpawnLocation") then
			inst.Enabled = false
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
