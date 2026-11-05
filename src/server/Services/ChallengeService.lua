--!strict
-- ChallengeService: Zonen-Herausforderungen (Konfig: Challenges.lua) – einmalige Belohnungen für Profis
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Challenges = require(Config:WaitForChild("Challenges")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))
local Goals = require(Shared:WaitForChild("Goals"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local LevelService = require(script.Parent:WaitForChild("LevelService"))
local QuestEvents = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("QuestEvents"))

local ChallengeService = {}

local COUNTED = { Gegner = true, Kristall = true, Boss = true }

function ChallengeService.Check(player: Player, zoneIndex: number)
	local data = DataService.Get(player)
	local list = Challenges[zoneIndex]
	if not data or not list then
		return
	end
	for _, ch in list do
		if not data.Challenges[ch.Id] then
			local have, need = Goals.Challenge(ch, data, zoneIndex)
			if have >= need then
				DataService.Update(player, function(d)
					d.Challenges[ch.Id] = true
				end)
				Remotes.Event("Toast"):FireClient(player, ("🎯 Herausforderung geschafft: %s!"):format(ch.Titel), "gut")
				Remotes.Event("Effect"):FireAllClients("LevelUp", { UserId = player.UserId })
				if ch.Belohnung then
					LevelService.Grant(player, ch.Belohnung, 1)
				end
			end
		end
	end
end

function ChallengeService.Init() end

function ChallengeService.Start()
	QuestEvents.Signal:Connect(function(player: Player, kind: string, info: any, amount: number)
		if not player.Parent then
			return
		end
		local zoneIndex = info.Zone
		if kind == "Coop" and type(info.Id) == "string" then
			zoneIndex = tonumber(string.match(info.Id, "^Z(%d+)_"))
		end
		if type(zoneIndex) ~= "number" or not Zones[zoneIndex] then
			return
		end
		if COUNTED[kind] then
			local zoneId = Zones[zoneIndex].Id
			DataService.Update(player, function(d)
				local s = d.ZoneStats[zoneId]
				if not s then
					s = { Gegner = 0, Kristall = 0, Boss = 0 }
					d.ZoneStats[zoneId] = s
				end
				s[kind] = (s[kind] or 0) + amount
			end)
		end
		if COUNTED[kind] or kind == "Strecke" or kind == "Coop" then
			ChallengeService.Check(player, zoneIndex)
		end
	end)
	DataService.OnLoaded(function(player)
		task.wait(3)
		for i = 1, #Zones do
			ChallengeService.Check(player, i)
		end
	end)
end

return ChallengeService
