--!strict
--[[
	PadSensor: zuverlässiges "Spieler steht auf dem Feld"
	Roblox-Figuren schweben ein kleines Stück über dem Boden, deshalb feuert Touched bei
	flachen Feldern (Checkpoints, Start, Teleporter …) oft erst spät oder gar nicht.
	Hier prüft der Server 10x pro Sekunde mit einer Box um die Figur (bis knapp unter die
	Füße), ob sie ein angemeldetes Feld berührt – das klappt schon am Rand des Feldes.
	Touched bleibt zusätzlich aktiv; die Handler haben ihre eigene Sperrzeit.
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))

local PadSensor = {}

type Handler = (Player) -> ()

local handlers: { [BasePart]: { Handler } } = {}
local inside: { [Player]: { [BasePart]: boolean } } = {}
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include
local dirty = true
local started = false

local INTERVAL = 0.1

local function refreshFilter()
	local list = {}
	for part in handlers do
		table.insert(list, part)
	end
	overlap.FilterDescendantsInstances = list
	dirty = false
end

local function fire(part: BasePart, player: Player)
	local list = handlers[part]
	if not list then
		return
	end
	for _, fn in list do
		task.spawn(fn, player)
	end
end

local function check(player: Player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then
		inside[player] = nil
		return
	end
	-- Box: Körperbreite, vom Kopf bis etwas unter die Füße
	local below = hum.HipHeight + root.Size.Y / 2 + 1
	local above = 2.5
	local size = Vector3.new(2.4, below + above, 2.4)
	local center = root.Position + Vector3.new(0, (above - below) / 2, 0)
	local hits = workspace:GetPartBoundsInBox(CFrame.new(center), size, overlap)
	local now: { [BasePart]: boolean } = {}
	local before = inside[player] or {}
	for _, part in hits do
		if handlers[part] then
			now[part] = true
			if not before[part] then
				fire(part, player)
			end
		end
	end
	inside[player] = now
end

local function start()
	if started then
		return
	end
	started = true
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < INTERVAL then
			return
		end
		acc = 0
		if dirty then
			refreshFilter()
		end
		for _, player in Players:GetPlayers() do
			check(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		inside[p] = nil
	end)
end

-- Ruft fn(player) auf, sobald ein Spieler das Feld betritt (Sensor) oder berührt (Touched)
function PadSensor.OnStep(part: BasePart, fn: Handler)
	start()
	local list = handlers[part]
	if not list then
		list = {}
		handlers[part] = list
		dirty = true
		part.Destroying:Connect(function()
			handlers[part] = nil
			dirty = true
		end)
	end
	table.insert(list, fn)
	part.Touched:Connect(function(hit)
		local player = Util.PlayerFromPart(hit)
		if player then
			fn(player)
		end
	end)
end

return PadSensor
