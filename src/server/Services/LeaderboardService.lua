--!strict
--[[
	LeaderboardService: Bestenlisten pro Strecke und Schwierigkeit (OrderedDataStore).
	Kleinere Zeit = besser. Werte werden in Hundertstelsekunden gespeichert.
	Ohne DataStore-Zugriff gibt es eine Liste nur mit den Spielern auf diesem Server.
]]
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Difficulty = require(Config:WaitForChild("Difficulty")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local Validate = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Validate"))

local LeaderboardService = {}

local cache: { [string]: { t: number, list: { any } } } = {}
local names: { [number]: string } = {}

local function storeName(trackKey: string, diff: string): string
	return ("Bestzeit_%s_%s"):format(trackKey, diff)
end

local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local p = Players:GetPlayerByUserId(userId)
	if p then
		names[userId] = p.DisplayName
		return p.DisplayName
	end
	local ok, n = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	names[userId] = if ok and n then n else "Spieler"
	return names[userId]
end

function LeaderboardService.Submit(player: Player, trackKey: string, diff: string, seconds: number)
	if not Settings.Leaderboard.Enabled or DataService.IsOffline() then
		return
	end
	task.spawn(function()
		local ok, err = pcall(function()
			local store = DataStoreService:GetOrderedDataStore(storeName(trackKey, diff))
			store:UpdateAsync(tostring(player.UserId), function(old)
				local value = math.floor(seconds * 100)
				if type(old) == "number" and old <= value then
					return nil
				end
				return value
			end)
		end)
		if not ok then
			warn("[Leaderboard] Speichern fehlgeschlagen:", err)
		end
		cache[storeName(trackKey, diff)] = nil
	end)
end

local function localList(trackKey: string, diff: string): { any }
	local list = {}
	for _, p in Players:GetPlayers() do
		local d = DataService.Get(p)
		local t = d and d.BestTimes[trackKey] and d.BestTimes[trackKey][diff]
		if t then
			table.insert(list, { Name = p.DisplayName, Time = t })
		end
	end
	table.sort(list, function(a, b)
		return a.Time < b.Time
	end)
	return list
end

function LeaderboardService.Get(trackKey: string, diff: string): { any }
	if not Settings.Leaderboard.Enabled or DataService.IsOffline() then
		return localList(trackKey, diff)
	end
	local key = storeName(trackKey, diff)
	local c = cache[key]
	if c and os.clock() - c.t < Settings.Leaderboard.CacheSeconds then
		return c.list
	end
	local ok, result = pcall(function()
		local store = DataStoreService:GetOrderedDataStore(key)
		local pages = store:GetSortedAsync(true, Settings.Leaderboard.Top)
		local list = {}
		for _, entry in pages:GetCurrentPage() do
			local uid = tonumber(entry.key)
			table.insert(list, { Name = if uid then nameOf(uid) else "?", Time = entry.value / 100 })
		end
		return list
	end)
	if not ok then
		warn("[Leaderboard] Laden fehlgeschlagen:", result)
		return localList(trackKey, diff)
	end
	cache[key] = { t = os.clock(), list = result }
	return result
end

function LeaderboardService.Init() end

function LeaderboardService.Start()
	Remotes.OnInvoke("GetLeaderboard", 2, function(player, trackKey, diff)
		if not Validate.String(trackKey, 12) or not string.match(trackKey, "^Z%d_T%d$") then
			return { ok = false }
		end
		if not Validate.Key(diff, Difficulty.Stufen) then
			return { ok = false }
		end
		local data = DataService.Get(player)
		local mine = data and data.BestTimes[trackKey] and data.BestTimes[trackKey][diff]
		return { ok = true, list = LeaderboardService.Get(trackKey, diff), mine = mine }
	end)
end

return LeaderboardService
