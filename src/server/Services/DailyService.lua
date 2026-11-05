--!strict
-- DailyService: tägliche Belohnung mit 7-Tage-Serie (Konfig: Daily.lua)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Daily = require(Config:WaitForChild("Daily")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))
local Goals = require(Shared:WaitForChild("Goals"))
local Progression = require(Shared:WaitForChild("Progression"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local LevelService = require(script.Parent:WaitForChild("LevelService"))

local DailyService = {}

local function bestZone(data: any): number
	local best = 1
	for i = 1, #Zones do
		if Progression.IsZoneUnlocked(data, i) then
			best = i
		end
	end
	return best
end

function DailyService.Init() end

function DailyService.Start()
	Remotes.OnInvoke("ClaimDaily", 1, function(player)
		local data = DataService.Get(player)
		if not data then
			return { ok = false }
		end
		local today = Goals.Day(os.time())
		local available, streak = Goals.DailyState(data, today, #Daily.Belohnungen)
		if not available then
			return { ok = false, msg = "Heute schon abgeholt – komm morgen wieder! 🌙" }
		end
		local reward = Daily.Belohnungen[streak]
		local zone = Zones[bestZone(data)]
		DataService.Update(player, function(d)
			d.Daily.LastDay = today
			d.Daily.Streak = streak
			d.Daily.BestStreak = math.max(d.Daily.BestStreak or 0, streak)
			if reward.RebirthPunkte then
				d.RebirthPoints += reward.RebirthPunkte
			end
		end)
		LevelService.Grant(player, {
			Energie = (reward.Energie or 0) * zone.Energiewert,
			XP = reward.XP,
			Ei = if reward.Ei == "BestesEi" then zone.Ei else reward.Ei,
		}, 1)
		if reward.RebirthPunkte then
			Remotes.Event("Toast"):FireClient(player, ("+%d ♻️ Rebirth-Punkt"):format(reward.RebirthPunkte), "gut")
		end
		Remotes.Event("Effect"):FireAllClients("LevelUp", { UserId = player.UserId })
		return { ok = true, day = streak }
	end)
end

return DailyService
