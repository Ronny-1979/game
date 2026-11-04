--!strict
--[[
	DataService: verwaltet alle Spieler-Profile.
	- Laden beim Beitreten, Autosave, Speichern beim Verlassen und in BindToClose
	- Update(player, fn) ändert Daten und schickt einen Schnappschuss an den Client
	- GetStats(player) liefert berechnete Werte (mit Cache)
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Signal = require(Shared:WaitForChild("Signal"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local StatCalc = require(Shared:WaitForChild("StatCalc"))

local Data = script.Parent.Parent:WaitForChild("Data")
local ProfileStore = require(Data:WaitForChild("ProfileStore"))
local Template = require(Data:WaitForChild("Template"))
local Migrations = require(Data:WaitForChild("Migrations"))

local DataService = {}
DataService.Loaded = Signal.new() -- (player, data)
DataService.Changed = Signal.new() -- (player, data)

local store: any
local profiles: { [Player]: any } = {}
local statsCache: { [Player]: { [string]: number } } = {}
local dirty: { [Player]: boolean } = {}
local joinTime: { [Player]: number } = {}
local closing = false

function DataService.Init()
	store = ProfileStore.new({
		Name = Settings.DataStoreName,
		Template = Template,
		Version = Settings.SchemaVersion,
		Migrations = Migrations,
		Retries = Settings.SaveRetries,
		RetryDelay = Settings.RetryDelay,
		LockTimeout = Settings.SessionLockTimeout,
		LockWaitTries = Settings.LockWaitTries,
	})
end

-- fn(player, data) für alle schon geladenen UND alle künftigen Profile aufrufen
function DataService.OnLoaded(fn: (Player, any) -> ())
	DataService.Loaded:Connect(fn)
	for player, data in profiles do
		task.spawn(fn, player, data)
	end
end

function DataService.IsOffline(): boolean
	return store ~= nil and store.Offline
end

function DataService.Get(player: Player): any
	return profiles[player]
end

function DataService.WaitFor(player: Player, timeout: number?): any
	local t0 = os.clock()
	while not profiles[player] and player.Parent and os.clock() - t0 < (timeout or 30) do
		task.wait(0.1)
	end
	return profiles[player]
end

function DataService.GetStats(player: Player): { [string]: number }?
	local data = profiles[player]
	if not data then
		return nil
	end
	local cached = statsCache[player]
	if not cached then
		cached = StatCalc.Compute(data)
		statsCache[player] = cached
	end
	return cached
end

-- Daten ändern. fn bekommt die Profil-Tabelle. Gibt zurück, was fn zurückgibt.
function DataService.Update(player: Player, fn: (any) -> any): any
	local data = profiles[player]
	if not data then
		return nil
	end
	local result = fn(data)
	statsCache[player] = nil
	dirty[player] = true
	DataService.Changed:Fire(player, data)
	return result
end

function DataService.AddEnergy(player: Player, amount: number)
	if amount <= 0 or amount ~= amount then
		return
	end
	DataService.Update(player, function(d)
		d.Energy += amount
		d.TotalEnergy += amount
	end)
	local ls = player:FindFirstChild("leaderstats")
	local ev = ls and ls:FindFirstChild("Energie")
	if ev and ev:IsA("NumberValue") then
		ev.Value = math.floor(profiles[player] and profiles[player].Energy or 0)
	end
end

-- Energie abziehen, wenn genug da ist
function DataService.Spend(player: Player, amount: number): boolean
	local data = profiles[player]
	if not data or amount < 0 or data.Energy < amount then
		return false
	end
	DataService.Update(player, function(d)
		d.Energy -= amount
	end)
	return true
end

local function sendSnapshot(player: Player)
	local data = profiles[player]
	if data then
		Remotes.Event("Data"):FireClient(player, data)
	end
end

local function updateLeaderstats(player: Player)
	local data = profiles[player]
	local ls = player:FindFirstChild("leaderstats")
	if not data or not ls then
		return
	end
	local lv = ls:FindFirstChild("Level") :: NumberValue?
	local en = ls:FindFirstChild("Energie") :: NumberValue?
	if lv then
		lv.Value = data.Level
	end
	if en then
		en.Value = math.floor(data.Energy)
	end
end

local function save(player: Player, release: boolean)
	local data = profiles[player]
	if not data then
		return
	end
	local start = joinTime[player]
	if start then
		data.Stats.PlayTime += os.time() - start
		joinTime[player] = os.time()
	end
	store:Save(player.UserId, data, release)
end

local function onPlayerAdded(player: Player)
	local data, err = store:Load(player.UserId)
	if not player.Parent then
		-- Spieler ist schon weg: Sperre wieder freigeben
		if data then
			store:Save(player.UserId, data, true)
		end
		return
	end
	if not data then
		player:Kick(err or "Spielstand konnte nicht geladen werden. Bitte neu beitreten.")
		return
	end
	profiles[player] = data
	joinTime[player] = os.time()

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local lv = Instance.new("NumberValue")
	lv.Name = "Level"
	lv.Parent = ls
	local en = Instance.new("NumberValue")
	en.Name = "Energie"
	en.Parent = ls
	ls.Parent = player
	updateLeaderstats(player)

	sendSnapshot(player)
	DataService.Loaded:Fire(player, data)
	if store.Offline then
		task.delay(3, function()
			if player.Parent then
				Remotes.Event("Toast"):FireClient(player, "⚠️ Test-Modus: Fortschritt wird nicht gespeichert.", "fehler")
			end
		end)
	end
end

local function onPlayerRemoving(player: Player)
	if profiles[player] and not closing then
		save(player, true)
	end
	profiles[player] = nil
	statsCache[player] = nil
	dirty[player] = nil
	joinTime[player] = nil
end

-- Profil komplett zurücksetzen (Admin)
function DataService.ResetProfile(player: Player)
	local Util = require(Shared:WaitForChild("Util"))
	if not profiles[player] then
		return
	end
	profiles[player] = Util.DeepCopy(Template)
	DataService.Update(player, function() end)
end

function DataService.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayerAdded, p)
	end
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Beim Herunterfahren alle gleichzeitig speichern
	game:BindToClose(function()
		closing = true
		if RunService:IsStudio() and store.Offline then
			return
		end
		local pending = 0
		for player, _ in profiles do
			pending += 1
			task.spawn(function()
				save(player, true)
				pending -= 1
			end)
		end
		local t0 = os.clock()
		while pending > 0 and os.clock() - t0 < 25 do
			task.wait(0.2)
		end
	end)

	-- Autosave
	task.spawn(function()
		while true do
			task.wait(Settings.AutosaveInterval)
			for player, _ in profiles do
				if player.Parent then
					task.spawn(save, player, false)
				end
			end
		end
	end)

	-- Änderungen gedrosselt an Clients schicken (max. ~7 mal pro Sekunde)
	task.spawn(function()
		while true do
			task.wait(0.15)
			for player, _ in dirty do
				dirty[player] = nil
				if player.Parent then
					sendSnapshot(player)
					updateLeaderstats(player)
				end
			end
		end
	end)

	Remotes.OnEvent("RequestData", 1, function(player)
		sendSnapshot(player)
	end)

	-- Einstellungen ändern (nur erlaubte Schlüssel und Werte)
	local allowed = {
		Music = function(v)
			return type(v) == "number" and v >= 0 and v <= 1
		end,
		Sfx = function(v)
			return type(v) == "number" and v >= 0 and v <= 1
		end,
		Graphics = function(v)
			return v == "Hoch" or v == "Niedrig"
		end,
		Difficulty = function(v)
			return v == "Leicht" or v == "Normal" or v == "Profi"
		end,
	}
	Remotes.OnEvent("ChangeSetting", 5, function(player, key, value)
		if type(key) ~= "string" then
			return
		end
		local check = allowed[key]
		if not check or not check(value) then
			return
		end
		DataService.Update(player, function(d)
			d.Settings[key] = value
		end)
	end)
end

return DataService
