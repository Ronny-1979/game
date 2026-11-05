--!strict
--[[
	CourseService: Obby-Strecken
	Start-Feld → Checkpoints (in Reihenfolge) → Ziel.
	Der Server misst die Zeit selbst und prüft, ob alle Checkpoints erreicht wurden und
	die Zeit überhaupt möglich ist (Anti-Schummel).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Difficulty = require(Config:WaitForChild("Difficulty")) :: any
local Tags = require(Shared:WaitForChild("Tags"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Progression = require(Shared:WaitForChild("Progression"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local LevelService = require(script.Parent:WaitForChild("LevelService"))
local PetService = require(script.Parent:WaitForChild("PetService"))
local ZoneService = require(script.Parent:WaitForChild("ZoneService"))
local LeaderboardService = require(script.Parent:WaitForChild("LeaderboardService"))
local QuestEvents = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("QuestEvents"))

local CourseService = {}

type Course = {
	Key: string,
	Diff: string,
	Zone: number,
	Track: number,
	Start: number,
	Checkpoint: number,
	Count: number,
	Length: number,
	Par: number,
	Name: string,
}
local courses: { [Player]: Course } = {}
local touchDebounce: { [Player]: { [Instance]: number } } = {}

local function debounced(player: Player, part: Instance, seconds: number): boolean
	local map = touchDebounce[player]
	if not map then
		map = {}
		touchDebounce[player] = map
	end
	local now = os.clock()
	if (map[part] or 0) > now then
		return true
	end
	map[part] = now + seconds
	return false
end

local function clearCourse(player: Player, notify: boolean)
	if courses[player] then
		courses[player] = nil
		player:SetAttribute("CourseKey", nil)
		player:SetAttribute("CourseDiff", nil)
		player:SetAttribute("CourseStart", nil)
		if notify then
			Remotes.Event("CourseEvent"):FireClient(player, "Abbruch", {})
		end
	end
end

function CourseService.GetCourse(player: Player): Course?
	return courses[player]
end

local function onStart(part: BasePart, player: Player)
	if debounced(player, part, 0.5) then
		return
	end
	local key = part:GetAttribute("TrackKey") :: string
	local diff = part:GetAttribute("Diff") :: string
	local current = courses[player]
	-- Auf dem Startfeld stehen = Zeit läuft immer wieder neu an
	local c: Course = {
		Key = key,
		Diff = diff,
		Zone = (part:GetAttribute("ZoneIndex") :: number?) or 1,
		Track = (part:GetAttribute("TrackIndex") :: number?) or 1,
		Start = workspace:GetServerTimeNow(),
		Checkpoint = 0,
		Count = (part:GetAttribute("CheckpointCount") :: number?) or 0,
		Length = (part:GetAttribute("Length") :: number?) or 100,
		Par = 0,
		Name = (part:GetAttribute("TrackName") :: string?) or key,
	}
	-- Richtzeit für Medaillen (ältere Welten ohne Attribut: grob aus der Länge schätzen)
	c.Par = (part:GetAttribute("Par") :: number?) or (c.Length / 9 + c.Count + 3)
	courses[player] = c
	player:SetAttribute("CourseKey", key)
	player:SetAttribute("CourseDiff", diff)
	player:SetAttribute("CourseStart", c.Start)
	player:SetAttribute("RespawnPos", part.Position + Vector3.new(0, 2, 0))
	if not current or current.Key ~= key or current.Diff ~= diff or current.Checkpoint > 0 then
		Remotes.Event("CourseEvent"):FireClient(player, "Start", { Key = key, Diff = diff, Name = c.Name })
	end
end

local function onCheckpoint(part: BasePart, player: Player)
	if debounced(player, part, 1) then
		return
	end
	local c = courses[player]
	local key = part:GetAttribute("TrackKey")
	local diff = part:GetAttribute("Diff")
	local index = (part:GetAttribute("Index") :: number?) or 0
	if c and c.Key == key and c.Diff == diff then
		if index > c.Checkpoint then
			-- Checkpoints müssen in Reihenfolge erreicht werden (keine Abkürzungen)
			if index ~= c.Checkpoint + 1 then
				return
			end
			c.Checkpoint = index
			player:SetAttribute("RespawnPos", part.Position + Vector3.new(0, 2, 0))
			Remotes.Event("CourseEvent"):FireClient(player, "Checkpoint", { Index = index, Count = c.Count })
		end
	end
end

local function onFinish(part: BasePart, player: Player)
	if debounced(player, part, 2) then
		return
	end
	local c = courses[player]
	if not c or c.Key ~= part:GetAttribute("TrackKey") or c.Diff ~= part:GetAttribute("Diff") then
		return
	end
	if c.Checkpoint < c.Count then
		Remotes.Event("Toast"):FireClient(player, "Du hast einen Checkpoint verpasst!", "fehler")
		return
	end
	local elapsed = workspace:GetServerTimeNow() - c.Start
	local minTime = c.Length / Settings.Course.MaxStudsPerSecond
	clearCourse(player, false)
	player:SetAttribute("RespawnPos", part.Position + Vector3.new(0, 2, 0))
	if elapsed < minTime then
		Remotes.Event("Toast"):FireClient(player, "Hm, das ging zu schnell. Versuch es noch mal!", "fehler")
		return
	end

	local zone = Zones[c.Zone]
	local track = zone and zone.Strecken[c.Track]
	local diffCfg = Difficulty.Stufen[c.Diff]
	local data = DataService.Get(player)
	if not zone or not track or not diffCfg or not data then
		return
	end
	local completedKey = c.Key .. "_" .. c.Diff
	local first = not data.Completed[completedKey]
	local factor = diffCfg.Belohnung * (if first then Settings.Course.FirstClearBonus else 1)

	-- Bestzeit
	local times = data.BestTimes[c.Key]
	local old = times and times[c.Diff]
	local newBest = old == nil or elapsed < old
	DataService.Update(player, function(d)
		d.Completed[completedKey] = true
		d.Stats.Courses += 1
		d.BestTimes[c.Key] = d.BestTimes[c.Key] or {}
		if newBest then
			d.BestTimes[c.Key][c.Diff] = math.floor(elapsed * 100) / 100
		end
	end)
	if newBest then
		LeaderboardService.Submit(player, c.Key, c.Diff, elapsed)
	end

	LevelService.Grant(player, track.Belohnung, factor)
	QuestEvents.Fire(player, "Strecke", { Zone = c.Zone, Track = c.Track, Diff = c.Diff })

	-- Zeit-Medaillen: jede neue Stufe gibt einmalig eine Extra-Belohnung
	local medal = Progression.MedalFor(elapsed, c.Par)
	local oldMedal = (data.Medals and data.Medals[completedKey]) or 0
	if medal > oldMedal then
		local bonus = 0
		for m = oldMedal + 1, medal do
			bonus += Settings.Medals[m].Belohnung
		end
		DataService.Update(player, function(d)
			d.Medals[completedKey] = medal
		end)
		local info = Settings.Medals[medal]
		task.delay(1.2, function()
			if player.Parent then
				Remotes.Event("Toast"):FireClient(player, ("%s %s-Medaille auf %s!"):format(info.Symbol, info.Name, c.Name), "gut")
				LevelService.Grant(player, track.Belohnung, bonus * diffCfg.Belohnung)
			end
		end)
		QuestEvents.Fire(player, "Medaille", { Medal = medal, Zone = c.Zone })
	end
	local medalTimes = {}
	for m = 1, #Settings.Medals do
		medalTimes[m] = Progression.MedalTime(c.Par, m)
	end
	if math.random() < diffCfg.EiChance and zone.Ei then
		PetService.Hatch(player, zone.Ei, true)
	end

	Remotes.Event("CourseEvent"):FireClient(player, "Ziel", {
		Time = elapsed,
		Best = if newBest then elapsed else old,
		NewBest = newBest,
		First = first,
		Name = c.Name,
		Diff = c.Diff,
		Medal = medal,
		NewMedal = medal > oldMedal,
		BestMedal = math.max(medal, oldMedal),
		MedalTimes = medalTimes,
	})
	Remotes.Event("Effect"):FireAllClients("Finish", { Pos = part.Position })
	if newBest and old then
		Remotes.Event("Toast"):FireClient(player, ("🏆 Neue Bestzeit: %s"):format(Util.FormatTime(elapsed)), "gut")
	end
end

local function hook(tag: string, handler: (BasePart, Player) -> ())
	local function connect(part: Instance)
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				local player = Util.PlayerFromPart(hit)
				if player and DataService.Get(player) then
					handler(part, player)
				end
			end)
		end
	end
	for _, p in CollectionService:GetTagged(tag) do
		connect(p)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(connect)
end

function CourseService.Init() end

function CourseService.Start()
	hook(Tags.TrackStart, onStart)
	hook(Tags.Checkpoint, onCheckpoint)
	hook(Tags.TrackFinish, onFinish)
	hook(Tags.ReturnPad, function(part, player)
		if debounced(player, part, 2) then
			return
		end
		clearCourse(player, false)
		ZoneService.TeleportToZone(player, (part:GetAttribute("ZoneIndex") :: number?) or 0)
	end)

	ZoneService.Teleported:Connect(function(player)
		clearCourse(player, true)
	end)

	Players.PlayerRemoving:Connect(function(p)
		courses[p] = nil
		touchDebounce[p] = nil
	end)

	-- Sicherheitsnetz: wer sehr tief fällt, kommt zum Respawn-Punkt zurück
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, player in Players:GetPlayers() do
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				local pos = player:GetAttribute("RespawnPos")
				if root and typeof(pos) == "Vector3" and root.Position.Y < pos.Y - Settings.Course.FallDistance - 40 then
					char:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)))
					root.AssemblyLinearVelocity = Vector3.zero
				end
			end
		end
	end)
end

return CourseService
