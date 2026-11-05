--!strict
--[[
	TowerService: der Endlos-Turm (Konfig: Tower.lua)
	- Etagen werden erst gebaut, wenn jemand sie braucht (TowerBuilder) → endlos
	- Jeden Montag ein neuer Turm (anderer Zufalls-Startwert) und neue Wochen-Bestenliste
	- Einstieg auf Etage 1 oder jeder 10er-Etage, die man diese Woche schon erreicht hat
	- Spieler-Attribute: Ort = "Turm", TowerFloor = aktuelle Etage
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Tower = require(Config:WaitForChild("Tower")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Settings = require(Config:WaitForChild("Settings")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local Progression = require(Shared:WaitForChild("Progression"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local LevelService = require(script.Parent:WaitForChild("LevelService"))
local PetService = require(script.Parent:WaitForChild("PetService"))
local ZoneService = require(script.Parent:WaitForChild("ZoneService"))
local QuestEvents = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("QuestEvents"))
local Validate = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Validate"))
local TowerBuilder = require(ServerScriptService:WaitForChild("Server"):WaitForChild("World"):WaitForChild("Builders"):WaitForChild("TowerBuilder"))

local TowerService = {}

type Floor = { Folder: Folder, Start: Vector3, Length: number }
local floors: { [number]: Floor } = {}
local building: { [number]: boolean } = {}
local towerFolder: Folder
local builtWeek = 0
local enteredAt: { [Player]: number } = {}
local debounce: { [Player]: number } = {}
local boardCache: { [string]: { t: number, list: { any } } } = {}
local names: { [number]: string } = {}

-- Wochennummer (Wechsel montags 0 Uhr UTC; 1.1.1970 war ein Donnerstag → +3 Tage)
function TowerService.CurrentWeek(): number
	return math.floor((os.time() + 3 * 86400) / (7 * 86400))
end

-- Sekunden bis zum nächsten Turm
function TowerService.SecondsLeft(): number
	local week = TowerService.CurrentWeek()
	return (week + 1) * 7 * 86400 - 3 * 86400 - os.time()
end

local function resetIfNewWeek(player: Player)
	local week = TowerService.CurrentWeek()
	local data = DataService.Get(player)
	if data and data.Tower.Week ~= week then
		DataService.Update(player, function(d)
			d.Tower.Week = week
			d.Tower.WeekBest = 0
		end)
	end
end

-- Etage n sicher gebaut zurückgeben (wartet, falls gerade jemand anderes sie baut)
function TowerService.EnsureFloor(n: number): Floor?
	local week = TowerService.CurrentWeek()
	if week ~= builtWeek then
		-- neue Woche: alten Turm abräumen (Spieler darin kommen beim nächsten Schritt in den neuen)
		for _, f in floors do
			f.Folder:Destroy()
		end
		table.clear(floors)
		builtWeek = week
	end
	if floors[n] then
		return floors[n]
	end
	if building[n] then
		local t0 = os.clock()
		while building[n] and os.clock() - t0 < 10 do
			task.wait(0.1)
		end
		return floors[n]
	end
	building[n] = true
	local ok, folder, start, length = pcall(TowerBuilder.BuildFloor, towerFolder, week, n)
	building[n] = nil
	if not ok then
		warn("[Turm] Etage", n, "konnte nicht gebaut werden:", folder)
		return nil
	end
	local f = { Folder = folder, Start = start, Length = length }
	floors[n] = f
	return f
end

-- Erlaubte Start-Etagen: 1 und jede 10er-Etage + 1, die man diese Woche erreicht hat
function TowerService.StartFloors(data: any): { number }
	local list = { 1 }
	local reached = if data.Tower.Week == TowerService.CurrentWeek() then data.Tower.WeekBest else 0
	local step = Tower.MeilensteinAlle
	local k = step
	while k <= reached do
		table.insert(list, k + 1)
		k += step
	end
	return list
end

local function bestZone(data: any): number
	local best = 1
	for i = 1, #Zones do
		if Progression.IsZoneUnlocked(data, i) then
			best = i
		end
	end
	return best
end

local function sendTo(player: Player, n: number): boolean
	local f = TowerService.EnsureFloor(n)
	if not f then
		Remotes.Event("Toast"):FireClient(player, "Der Turm klemmt gerade – versuch es gleich nochmal.", "fehler")
		return false
	end
	ZoneService.TeleportTo(player, f.Start, 0, f.Start)
	player:SetAttribute("Ort", "Turm")
	player:SetAttribute("TowerFloor", n)
	enteredAt[player] = os.clock()
	-- nächste Etage schon vorbereiten, damit es ohne Wartezeit weitergeht
	task.spawn(TowerService.EnsureFloor, n + 1)
	return true
end

local function submitBoards(player: Player, weekBest: number, best: number)
	if DataService.IsOffline() then
		return
	end
	task.spawn(function()
		local week = TowerService.CurrentWeek()
		for _, entry in { { "Turm_Woche_" .. week, weekBest }, { "Turm_Rekord", best } } do
			local ok, err = pcall(function()
				DataStoreService:GetOrderedDataStore(entry[1]):UpdateAsync(tostring(player.UserId), function(old)
					if type(old) == "number" and old >= entry[2] then
						return nil
					end
					return entry[2]
				end)
			end)
			if not ok then
				warn("[Turm] Bestenliste:", err)
			end
			boardCache[entry[1]] = nil
		end
	end)
end

local function onExit(part: BasePart, player: Player)
	local now = os.clock()
	if (debounce[player] or 0) > now then
		return
	end
	debounce[player] = now + 1.5
	local n = part:GetAttribute("Floor")
	if player:GetAttribute("Ort") ~= "Turm" or player:GetAttribute("TowerFloor") ~= n or type(n) ~= "number" then
		return
	end
	-- Anti-Schummel: so schnell kann niemand ehrlich durch die Etage
	local f = floors[n]
	local minTime = if f then f.Length / Settings.Course.MaxStudsPerSecond else 1
	if now - (enteredAt[player] or 0) < minTime then
		Remotes.Event("Toast"):FireClient(player, "Hm, das ging zu schnell. Versuch es noch mal!", "fehler")
		return
	end
	resetIfNewWeek(player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local newBest = n > data.Tower.Best
	local newWeekBest = n > data.Tower.WeekBest
	DataService.Update(player, function(d)
		d.Tower.WeekBest = math.max(d.Tower.WeekBest, n)
		d.Tower.Best = math.max(d.Tower.Best, n)
		d.Tower.Floors += 1
	end)
	if newWeekBest then
		submitBoards(player, data.Tower.WeekBest, data.Tower.Best)
	end
	-- Belohnung
	local zone = Zones[bestZone(data)]
	local B = Tower.Belohnung
	LevelService.Grant(player, {
		Energie = zone.Energiewert * (B.EnergieBasis + n * B.EnergieProEtage),
		XP = B.XPBasis + n * B.XPProEtage,
	}, 1)
	if n % Tower.MeilensteinAlle == 0 then
		Remotes.Event("Toast"):FireClient(player, ("🗼 Etage %d geschafft! Gratis-Ei + neuer Startpunkt"):format(n), "gut")
		PetService.Hatch(player, zone.Ei, true)
		Remotes.Event("Effect"):FireAllClients("Finish", { Pos = part.Position })
	end
	if newBest then
		Remotes.Event("Toast"):FireClient(player, ("🏆 Neuer Turm-Rekord: Etage %d!"):format(n), "gut")
	end
	QuestEvents.Fire(player, "Turm", { Floor = n })
	sendTo(player, n + 1)
end

local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local p = Players:GetPlayerByUserId(userId)
	local ok, n = pcall(function()
		return if p then p.DisplayName else Players:GetNameFromUserIdAsync(userId)
	end)
	names[userId] = if ok and n then n else "Spieler"
	return names[userId]
end

local function board(storeName: string, field: string): { any }
	if DataService.IsOffline() then
		local list = {}
		for _, p in Players:GetPlayers() do
			local d = DataService.Get(p)
			if d and d.Tower[field] > 0 then
				table.insert(list, { Name = p.DisplayName, Floor = d.Tower[field] })
			end
		end
		table.sort(list, function(a, b)
			return a.Floor > b.Floor
		end)
		return list
	end
	local c = boardCache[storeName]
	if c and os.clock() - c.t < Settings.Leaderboard.CacheSeconds then
		return c.list
	end
	local ok, result = pcall(function()
		local pages = DataStoreService:GetOrderedDataStore(storeName):GetSortedAsync(false, Settings.Leaderboard.Top)
		local list = {}
		for _, entry in pages:GetCurrentPage() do
			local uid = tonumber(entry.key)
			table.insert(list, { Name = if uid then nameOf(uid) else "?", Floor = entry.value })
		end
		return list
	end)
	if not ok then
		warn("[Turm] Bestenliste laden:", result)
		return {}
	end
	boardCache[storeName] = { t = os.clock(), list = result }
	return result
end

function TowerService.Init()
	local old = workspace:FindFirstChild("Endlosturm")
	if old then
		old:Destroy()
	end
	towerFolder = Instance.new("Folder")
	towerFolder.Name = "Endlosturm"
	towerFolder.Parent = workspace
	builtWeek = TowerService.CurrentWeek()
end

function TowerService.Start()
	-- die ersten Etagen gleich bauen
	task.spawn(function()
		for n = 1, 3 do
			TowerService.EnsureFloor(n)
		end
	end)

	local function hook(tag: string, fn: (BasePart, Player) -> ())
		local function connect(part: Instance)
			if part:IsA("BasePart") then
				part.Touched:Connect(function(hit)
					local player = Util.PlayerFromPart(hit)
					if player and DataService.Get(player) then
						fn(part, player)
					end
				end)
			end
		end
		for _, p in CollectionService:GetTagged(tag) do
			connect(p)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(connect)
	end
	hook("TowerExit", onExit)
	hook("TowerLeave", function(_part, player)
		local now = os.clock()
		if (debounce[player] or 0) > now then
			return
		end
		debounce[player] = now + 2
		ZoneService.TeleportToZone(player, 0)
	end)

	DataService.OnLoaded(function(player)
		resetIfNewWeek(player)
	end)
	Players.PlayerRemoving:Connect(function(p)
		enteredAt[p] = nil
		debounce[p] = nil
	end)

	Remotes.OnInvoke("EnterTower", 1, function(player, startFloor)
		if not Validate.Int(startFloor, 1, 100000) then
			return { ok = false }
		end
		if not Validate.Alive(player) then
			return { ok = false, msg = "Warte, bis du wieder da bist." }
		end
		resetIfNewWeek(player)
		local data = DataService.Get(player)
		if not data then
			return { ok = false }
		end
		if not table.find(TowerService.StartFloors(data), startFloor) then
			return { ok = false, msg = "Diese Etage hast du diese Woche noch nicht erreicht." }
		end
		local ok = sendTo(player, startFloor)
		if ok then
			Remotes.Event("Toast"):FireClient(player, ("🗼 Endlos-Turm – Etage %d. Viel Glück!"):format(startFloor), "info")
		end
		return { ok = ok }
	end)

	Remotes.OnInvoke("GetTowerBoard", 2, function(player)
		resetIfNewWeek(player)
		local data = DataService.Get(player)
		if not data then
			return { ok = false }
		end
		return {
			ok = true,
			week = board("Turm_Woche_" .. TowerService.CurrentWeek(), "WeekBest"),
			record = board("Turm_Rekord", "Best"),
			starts = TowerService.StartFloors(data),
			secondsLeft = TowerService.SecondsLeft(),
		}
	end)
end

return TowerService
