--!strict
--[[
	Goals: Fortschritt von Zonen-Herausforderungen und Abzeichen berechnen.
	Server (Vergabe) und Client (Anzeige) benutzen dieselben Formeln.
]]
local Config = script.Parent:WaitForChild("Config")
local Zones = require(Config:WaitForChild("Zones")) :: any
local Pets = require(Config:WaitForChild("Pets")) :: any
local Progression = require(script.Parent:WaitForChild("Progression"))

local Goals = {}

local DIFF_RANK = { Leicht = 1, Normal = 2, Profi = 3 }

-- Wurde Strecke t in Zone z auf diff ODER schwerer geschafft?
local function trackDone(data: any, z: number, t: number, diff: string): boolean
	local key = Progression.TrackKey(z, t)
	for d, rank in DIFF_RANK do
		if rank >= (DIFF_RANK[diff] or 1) and data.Completed[key .. "_" .. d] then
			return true
		end
	end
	return false
end

function Goals.ZoneStat(data: any, zoneIndex: number, key: string): number
	local zone = Zones[zoneIndex]
	local stats = zone and data.ZoneStats and data.ZoneStats[zone.Id]
	return (stats and stats[key]) or 0
end

-- Fortschritt einer Herausforderung: (hat, braucht)
function Goals.Challenge(ch: any, data: any, zoneIndex: number): (number, number)
	if ch.Art == "AlleStrecken" then
		local n = 0
		for t = 1, 3 do
			if trackDone(data, zoneIndex, t, ch.Diff or "Leicht") then
				n += 1
			end
		end
		return n, 3
	elseif ch.Art == "Strecke" then
		return (if trackDone(data, zoneIndex, ch.Strecke or 1, ch.Diff or "Leicht") then 1 else 0), 1
	elseif ch.Art == "Gegner" or ch.Art == "Kristall" or ch.Art == "Boss" then
		return Goals.ZoneStat(data, zoneIndex, ch.Art), ch.Anzahl or 1
	elseif ch.Art == "Coop" then
		local zone = Zones[zoneIndex]
		local need = zone and zone.Coop and #zone.Coop or 0
		local prefix = ("Z%d_"):format(zoneIndex)
		local n = 0
		for id in data.CoopSolved do
			if string.sub(id, 1, #prefix) == prefix then
				n += 1
			end
		end
		return math.min(n, need), math.max(need, 1)
	end
	return 0, 1
end

local function count(t: { [any]: any }?): number
	local n = 0
	for _ in t or {} do
		n += 1
	end
	return n
end

-- Wert für eine Abzeichen-Bedingung
function Goals.BadgeValue(art: string, data: any): number
	if art == "Level" then
		return data.Level
	elseif art == "Rebirths" then
		return data.Rebirths
	elseif art == "Pets" then
		return #data.Pets
	elseif art == "Legendaer" then
		local n = 0
		for _, p in data.Pets do
			local def = Pets.Liste[p.Type]
			if def and def.Seltenheit == "Legendaer" then
				n += 1
			end
		end
		return n
	elseif art == "Bosse" then
		return count(data.BossesDefeated)
	elseif art == "Herausforderungen" then
		return count(data.Challenges)
	elseif art == "Serie" then
		return data.Daily and data.Daily.BestStreak or 0
	elseif art == "Energie" then
		return data.TotalEnergy
	elseif art == "Strecken" then
		return data.Stats.Courses
	elseif art == "Profi" then
		local n = 0
		for key in data.Completed do
			if string.sub(key, -6) == "_Profi" then
				n += 1
			end
		end
		return n
	elseif art == "Gegner" then
		return data.Stats.Defeated
	elseif art == "Coop" then
		return count(data.CoopSolved)
	elseif art == "Aufgaben" then
		return (data.Quest and data.Quest.Index or 1) - 1
	elseif art == "Eier" then
		return data.Stats.Hatched
	elseif art == "Zonen" then
		return count(data.UnlockedZones)
	end
	return 0
end

-- Tagesnummer (UTC) für tägliche Belohnungen
function Goals.Day(unixTime: number): number
	return math.floor(unixTime / 86400)
end

-- Kann heute abgeholt werden? Gibt (verfügbar, Tag 1–7 der nächsten Belohnung) zurück
function Goals.DailyState(data: any, today: number, maxDays: number): (boolean, number)
	local d = data.Daily or { LastDay = 0, Streak = 0 }
	if d.LastDay >= today then
		return false, d.Streak
	end
	local nextStreak = if d.LastDay == today - 1 then d.Streak + 1 else 1
	if nextStreak > maxDays then
		nextStreak = 1
	end
	return true, nextStreak
end

return Goals
