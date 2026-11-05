--!strict
--[[
	ZoneService: Teleporter im Hub, Portale in den Zonen, Karten-Teleport, Schnellstart von Strecken.
	Merkt sich die aktuelle Zone im Spieler-Attribut "Zone" (0 = Hub).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Zones = require(Config:WaitForChild("Zones")) :: any
local Difficulty = require(Config:WaitForChild("Difficulty")) :: any
local Tags = require(Shared:WaitForChild("Tags"))
local Signal = require(Shared:WaitForChild("Signal"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local Progression = require(Shared:WaitForChild("Progression"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlayerService = require(script.Parent:WaitForChild("PlayerService"))
local QuestEvents = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("QuestEvents"))
local Validate = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Validate"))

local ZoneService = {}
ZoneService.Teleported = Signal.new() -- (player, zoneIndex)

local debounce: { [Player]: number } = {}

function ZoneService.GetZoneSpawn(index: number): Vector3?
	if index == 0 then
		return PlayerService.GetHubSpawn()
	end
	for _, part in CollectionService:GetTagged(Tags.ZoneSpawn) do
		if part:IsA("BasePart") and part:GetAttribute("ZoneIndex") == index then
			return part.Position + Vector3.new(0, 3, 0)
		end
	end
	return nil
end

local function toast(player: Player, text: string, kind: string?)
	Remotes.Event("Toast"):FireClient(player, text, kind or "info")
end

function ZoneService.TeleportTo(player: Player, pos: Vector3, zoneIndex: number, respawnPos: Vector3?)
	local char = player.Character
	if not char then
		return
	end
	player:SetAttribute("Zone", zoneIndex)
	player:SetAttribute("RespawnPos", respawnPos or pos)
	pcall(function()
		player:RequestStreamAroundAsync(pos, 5)
	end)
	char:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)))
	PlayerService.ClearHistory(player)
	ZoneService.Teleported:Fire(player, zoneIndex)
	QuestEvents.Fire(player, "Zone", { Zone = zoneIndex })
	Remotes.Event("Effect"):FireClient(player, "Portal", {})
end

function ZoneService.CanEnter(player: Player, index: number): (boolean, string?)
	if index == 0 then
		return true, nil
	end
	local data = DataService.Get(player)
	local zone = Zones[index]
	if not data or not zone then
		return false, "Diese Zone gibt es nicht."
	end
	if not Progression.IsZoneUnlocked(data, index) then
		local prev = Zones[index - 1]
		return false, ("🔒 %s: ab Level %d oder nach Sieg über den Boss von %s"):format(zone.Name, zone.FreischaltLevel, prev and prev.Name or "?")
	end
	return true, nil
end

function ZoneService.TeleportToZone(player: Player, index: number): (boolean, string?)
	local ok, why = ZoneService.CanEnter(player, index)
	if not ok then
		return false, why
	end
	local pos = ZoneService.GetZoneSpawn(index)
	if not pos then
		return false, "Zone wurde noch nicht gebaut."
	end
	ZoneService.TeleportTo(player, pos, index)
	if index > 0 then
		toast(player, ("📍 %s – %s"):format(Zones[index].Name, Zones[index].Beschreibung), "info")
	else
		toast(player, "📍 Hub-Insel", "info")
	end
	return true, nil
end

local function connectPad(part: Instance, getTarget: () -> number)
	if not part:IsA("BasePart") then
		return
	end
	part.Touched:Connect(function(hit)
		local player = Util.PlayerFromPart(hit)
		if not player then
			return
		end
		local now = os.clock()
		if (debounce[player] or 0) > now then
			return
		end
		debounce[player] = now + 2
		local ok, why = ZoneService.TeleportToZone(player, getTarget())
		if not ok and why then
			toast(player, why, "fehler")
		end
	end)
end

function ZoneService.Init() end

function ZoneService.Start()
	local function hookTeleporter(part: Instance)
		connectPad(part, function()
			return (part:GetAttribute("ZoneIndex") :: number?) or 1
		end)
	end
	local function hookPortal(part: Instance)
		connectPad(part, function()
			return (part:GetAttribute("Target") :: number?) or 0
		end)
	end
	for _, p in CollectionService:GetTagged(Tags.ZoneTeleporter) do
		hookTeleporter(p)
	end
	CollectionService:GetInstanceAddedSignal(Tags.ZoneTeleporter):Connect(hookTeleporter)
	for _, p in CollectionService:GetTagged(Tags.Portal) do
		hookPortal(p)
	end
	CollectionService:GetInstanceAddedSignal(Tags.Portal):Connect(hookPortal)

	Players.PlayerRemoving:Connect(function(p)
		debounce[p] = nil
	end)

	-- Karten-Teleport
	Remotes.OnInvoke("TeleportZone", 1, function(player, index)
		if not Validate.Int(index, 0, #Zones) then
			return { ok = false }
		end
		if not Validate.Alive(player) then
			return { ok = false, msg = "Warte, bis du wieder da bist." }
		end
		local ok, why = ZoneService.TeleportToZone(player, index)
		return { ok = ok, msg = why }
	end)

	-- Schnellstart: direkt an den Start einer Bahn
	Remotes.OnInvoke("StartTrack", 1, function(player, zoneIndex, trackIndex, diff)
		if not Validate.Int(zoneIndex, 1, #Zones) or not Validate.Int(trackIndex, 1, 3) then
			return { ok = false }
		end
		if not Validate.Key(diff, Difficulty.Stufen) then
			return { ok = false }
		end
		if not Validate.Alive(player) then
			return { ok = false, msg = "Warte, bis du wieder da bist." }
		end
		local ok, why = ZoneService.CanEnter(player, zoneIndex)
		if not ok then
			return { ok = false, msg = why }
		end
		local key = Progression.TrackKey(zoneIndex, trackIndex)
		for _, start in CollectionService:GetTagged(Tags.TrackStart) do
			if start:IsA("BasePart") and start:GetAttribute("TrackKey") == key and start:GetAttribute("Diff") == diff then
				-- etwas vor das Startfeld stellen
				local pos = start.Position - start.CFrame.LookVector * 7
				ZoneService.TeleportTo(player, pos, zoneIndex, pos)
				return { ok = true }
			end
		end
		return { ok = false, msg = "Strecke nicht gefunden." }
	end)
end

return ZoneService
