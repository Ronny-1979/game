--!strict
--[[
	BonusService: zeitlich begrenzte Events (Konfig: Events.lua) und Freunde-Bonus.
	- Aktive Events stehen als Attribute an ReplicatedStorage (EventNames, EventEnergy, EventXP, EventLuck, EventDeko),
	  damit jeder Client ein Banner zeigen kann.
	- Freunde auf demselben Server: Spieler-Attribut "FriendCount" → mehr Energie.
	Andere Services fragen EnergyFactor / XPFactor / LuckFactor ab.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Events")) :: any

local BonusService = {}

local active: { any } = {}
local forced: string? = nil -- Admin-Test: Event erzwingen
local friendCache: { [string]: boolean } = {}

-- Ist ein Datum (Monat, Tag) zwischen Von und Bis? (auch über den Jahreswechsel)
local function inRange(month: number, day: number, from: { number }, to: { number }): boolean
	local v = month * 100 + day
	local a = from[1] * 100 + from[2]
	local b = to[1] * 100 + to[2]
	if a <= b then
		return v >= a and v <= b
	end
	return v >= a or v <= b
end

local function findEvent(id: string): any
	for _, e in Events.Woche do
		if e.Id == id then
			return e
		end
	end
	for _, e in Events.Saison do
		if e.Id == id then
			return e
		end
	end
	return nil
end

-- Liste der Events, die jetzt gerade laufen
function BonusService.ComputeActive(now: number?): { any }
	local list = {}
	local t = os.date("!*t", (now or os.time()) + (Events.Zeitzone or 0) * 3600) :: any
	for _, e in Events.Woche do
		if table.find(e.Tage, t.wday) then
			table.insert(list, e)
		end
	end
	for _, e in Events.Saison do
		if inRange(t.month, t.day, e.Von, e.Bis) then
			table.insert(list, e)
		end
	end
	if forced then
		local e = findEvent(forced)
		if e and not table.find(list, e) then
			table.insert(list, e)
		end
	end
	return list
end

local function multiply(key: string): number
	local f = 1
	for _, e in active do
		f *= (e[key] or 1)
	end
	return f
end

local function publish()
	active = BonusService.ComputeActive()
	local names = {}
	local deko = ""
	for _, e in active do
		table.insert(names, e.Name)
		if e.Deko then
			deko = e.Deko
		end
	end
	ReplicatedStorage:SetAttribute("EventNames", table.concat(names, "  ·  "))
	ReplicatedStorage:SetAttribute("EventEnergy", multiply("Energie"))
	ReplicatedStorage:SetAttribute("EventXP", multiply("XP"))
	ReplicatedStorage:SetAttribute("EventLuck", multiply("Glueck"))
	ReplicatedStorage:SetAttribute("EventDeko", deko)
end

function BonusService.FriendBonus(player: Player): number
	local n = (player:GetAttribute("FriendCount") :: number?) or 0
	return math.min(n * Events.Freunde.ProFreund, Events.Freunde.Maximal)
end

function BonusService.EnergyFactor(player: Player): number
	return multiply("Energie") * (1 + BonusService.FriendBonus(player))
end

function BonusService.XPFactor(_player: Player): number
	return multiply("XP")
end

function BonusService.LuckFactor(): number
	return multiply("Glueck")
end

-- Admin: Event zum Testen erzwingen (nil = normal)
function BonusService.Force(id: string?): boolean
	if id and not findEvent(id) then
		return false
	end
	forced = id
	publish()
	return true
end

local function areFriends(a: Player, b: Player): boolean
	local key = if a.UserId < b.UserId then a.UserId .. "_" .. b.UserId else b.UserId .. "_" .. a.UserId
	local cached = friendCache[key]
	if cached ~= nil then
		return cached
	end
	local ok, result = pcall(function()
		return a:IsFriendsWith(b.UserId)
	end)
	local value = ok and result == true
	friendCache[key] = value
	return value
end

local function recountFriends()
	local list = Players:GetPlayers()
	for _, p in list do
		local n = 0
		for _, other in list do
			if other ~= p and areFriends(p, other) then
				n += 1
			end
		end
		p:SetAttribute("FriendCount", n)
	end
end

function BonusService.Init()
	publish()
end

function BonusService.Start()
	Players.PlayerAdded:Connect(function()
		task.wait(2)
		recountFriends()
	end)
	Players.PlayerRemoving:Connect(function()
		task.defer(recountFriends)
	end)
	task.spawn(recountFriends)
	-- Events jede Minute neu prüfen (Tageswechsel)
	task.spawn(function()
		while true do
			task.wait(60)
			publish()
		end
	end)
end

return BonusService
