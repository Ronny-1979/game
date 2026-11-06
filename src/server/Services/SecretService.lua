--!strict
--[[
	SecretService: versteckte goldene Zahnräder (Tag "Secret", Konfig: Secrets.lua).
	Einmal pro Spieler und Zahnrad gibt es eine Belohnung, dazu Meilensteine (z.B. Titel bei allen).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Secrets = require(Config:WaitForChild("Secrets")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local Goals = require(Shared:WaitForChild("Goals"))
local Progression = require(Shared:WaitForChild("Progression"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PadSensor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("PadSensor"))
local LevelService = require(script.Parent:WaitForChild("LevelService"))
local QuestEvents = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("QuestEvents"))

local SecretService = {}

local debounce: { [Player]: number } = {}

-- Ei der besten freigeschalteten Zone
local function bestEgg(data: any): string
	local best = 1
	for i = 1, #Zones do
		if Progression.IsZoneUnlocked(data, i) then
			best = i
		end
	end
	return Zones[best].Ei
end

local function milestone(player: Player, count: number)
	for _, m in Secrets.Meilensteine do
		if m.Anzahl == count then
			local data = DataService.Get(player)
			if not data then
				return
			end
			local reward = table.clone(m.Belohnung)
			if reward.Ei == "BestesEi" then
				reward.Ei = bestEgg(data)
			end
			if reward.RebirthPunkte then
				local n = reward.RebirthPunkte
				DataService.Update(player, function(d)
					d.RebirthPoints += n
				end)
			end
			Remotes.Event("Toast"):FireClient(player, "🏆 " .. m.Text, "gut")
			LevelService.Grant(player, reward, 1)
		end
	end
end

local function onTouch(part: BasePart, player: Player)
	local now = os.clock()
	if (debounce[player] or 0) > now then
		return
	end
	debounce[player] = now + 0.5
	local id = part:GetAttribute("SecretId")
	local data = DataService.Get(player)
	if type(id) ~= "string" or not data or data.Secrets[id] then
		return
	end
	DataService.Update(player, function(d)
		d.Secrets[id] = true
	end)
	local found = Util.Count(data.Secrets)
	local total = Goals.SecretTotal()
	local zoneIndex = (part:GetAttribute("ZoneIndex") :: number?) or 0
	local zone = Zones[math.max(zoneIndex, 1)]
	Remotes.Event("Toast"):FireClient(player, ("🔍 Geheimnis gefunden! (%d/%d)"):format(found, total), "gut")
	Remotes.Event("Effect"):FireClient(player, "SecretFound", { Pos = part.Position, Id = id })
	LevelService.Grant(player, { Energie = zone.Energiewert * Secrets.Belohnung.EnergieFaktor, XP = Secrets.Belohnung.XP * math.max(zoneIndex, 1) }, 1)
	QuestEvents.Fire(player, "Geheimnis", { Zone = zoneIndex })
	milestone(player, found)
end

function SecretService.Init() end

function SecretService.Start()
	local function connect(part: Instance)
		if part:IsA("BasePart") then
			PadSensor.OnStep(part, function(player)
				onTouch(part, player)
			end)
		end
	end
	for _, p in CollectionService:GetTagged("Secret") do
		connect(p)
	end
	CollectionService:GetInstanceAddedSignal("Secret"):Connect(connect)
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		debounce[p] = nil
	end)
end

return SecretService
