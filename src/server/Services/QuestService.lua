--!strict
--[[
	QuestService: führt neue Spieler mit einer Aufgaben-Kette durchs Spiel (Konfig: Quests.lua).
	Fortschritt steht im Profil unter Quest = { Index, Progress }.
	Ereignisse kommen über QuestEvents von den anderen Services.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Quests = require(Config:WaitForChild("Quests")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local LevelService = require(script.Parent:WaitForChild("LevelService"))
local QuestEvents = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("QuestEvents"))

local QuestService = {}

local function current(data: any): any
	return Quests.Liste[data.Quest.Index]
end

-- Passt ein Ereignis zur Aufgabe?
local function matches(q: any, kind: string, info: any): boolean
	if q.Art ~= kind then
		return false
	end
	if kind == "Zone" or kind == "Boss" then
		return info.Zone == q.Wert
	elseif kind == "Faehigkeit" then
		return info.Name == q.Wert
	elseif kind == "Strecke" then
		if q.Zone and info.Zone ~= q.Zone then
			return false
		end
		if q.Strecke and info.Track ~= q.Strecke then
			return false
		end
		if q.Diff == "Normal" and info.Diff == "Leicht" then
			return false -- "Normal" heißt: Normal oder schwerer
		elseif q.Diff == "Profi" and info.Diff ~= "Profi" then
			return false
		end
		return true
	elseif kind == "Gegner" then
		return q.Zone == nil or info.Zone == q.Zone
	end
	return true
end

-- Aufgaben, die man schon "hat" (z.B. Level erreicht), sofort abhaken
local function alreadyDone(q: any, data: any): boolean
	if q.Art == "Klasse" then
		return data.Class ~= ""
	elseif q.Art == "Level" then
		return data.Level >= (q.Wert or 1)
	elseif q.Art == "Boss" then
		local zone = Zones[q.Wert]
		return zone ~= nil and data.BossesDefeated[zone.Id] == true
	elseif q.Art == "Rebirth" then
		return data.Rebirths > 0
	end
	return false
end

local function complete(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local q = current(data)
	if not q then
		return
	end
	DataService.Update(player, function(d)
		d.Quest.Index += 1
		d.Quest.Progress = 0
	end)
	Remotes.Event("Toast"):FireClient(player, ("✅ Aufgabe geschafft: %s"):format(q.Titel), "gut")
	Remotes.Event("Effect"):FireAllClients("LevelUp", { UserId = player.UserId })
	if q.Belohnung then
		LevelService.Grant(player, q.Belohnung, 1)
	end
	local nextQ = current(data)
	if nextQ then
		task.delay(1.5, function()
			if player.Parent then
				Remotes.Event("Toast"):FireClient(player, ("📜 Neue Aufgabe: %s"):format(nextQ.Titel), "info")
			end
		end)
	else
		Remotes.Event("Toast"):FireClient(player, "🏆 Alle Aufgaben geschafft – du bist ein echter Uhrwerk-Meister!", "gut")
	end
end

function QuestService.CheckState(player: Player)
	-- mehrere Aufgaben hintereinander abhaken, falls schon erfüllt (max. 10 auf einmal)
	for _ = 1, 10 do
		local data = DataService.Get(player)
		local q = data and current(data)
		if not q or not alreadyDone(q, data) then
			return
		end
		complete(player)
	end
end

function QuestService.Progress(player: Player, kind: string, info: any, amount: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local q = current(data)
	if not q then
		return
	end
	if q.Art == "Level" or q.Art == "Klasse" or kind == "Level" then
		QuestService.CheckState(player)
		return
	end
	if not matches(q, kind, info) then
		return
	end
	local need = q.Anzahl or 1
	local progress = data.Quest.Progress + amount
	if progress >= need then
		complete(player)
		QuestService.CheckState(player)
	else
		DataService.Update(player, function(d)
			d.Quest.Progress = progress
		end)
	end
end

function QuestService.Init() end

function QuestService.Start()
	QuestEvents.Signal:Connect(function(player: Player, kind: string, info: any, amount: number)
		if player.Parent then
			QuestService.Progress(player, kind, info, amount)
		end
	end)
	-- optionale Aufgaben (z.B. Co-op) dürfen übersprungen werden
	Remotes.OnInvoke("SkipQuest", 0.5, function(player)
		local data = DataService.Get(player)
		local q = data and current(data)
		if not q or not q.Optional then
			return { ok = false, msg = "Diese Aufgabe kann man nicht überspringen." }
		end
		DataService.Update(player, function(d)
			d.Quest.Index += 1
			d.Quest.Progress = 0
		end)
		QuestService.CheckState(player)
		return { ok = true, msg = "⏭ Aufgabe übersprungen" }
	end)

	DataService.OnLoaded(function(player)
		task.wait(2)
		QuestService.CheckState(player)
	end)
end

return QuestService
