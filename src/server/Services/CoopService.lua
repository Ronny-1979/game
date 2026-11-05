--!strict
--[[
	CoopService: Zwei-Spieler-Rätsel
	  "Tuer"    – zwei Druckplatten gleichzeitig besetzen → Tür öffnet sich
	  "Bruecke" – zwei Knöpfe fast gleichzeitig drücken → Brücke erscheint
	  "Konsole" – einer steht auf der Zeit-Konsole (Hindernisse werden langsam), der andere springt
	Am Ende wartet ein Belohnungsfeld: ALLE Spieler im Rätsel bekommen die Team-Belohnung.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Tags = require(Shared:WaitForChild("Tags"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local LevelService = require(script.Parent:WaitForChild("LevelService"))
local TimeScaleService = require(script.Parent:WaitForChild("TimeScaleService"))
local QuestEvents = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("QuestEvents"))

local CoopService = {}

type Puzzle = {
	Id: string,
	Kind: string,
	ZoneIndex: number,
	Center: Vector3,
	Radius: number,
	Plates: { BasePart },
	Buttons: { BasePart },
	Doors: { BasePart },
	Bridges: { BasePart },
	Consoles: { BasePart },
	Rewards: { BasePart },
	OpenUntil: number,
	Presses: { [BasePart]: { t: number, p: Player } },
	RegionId: number?,
	ConsoleUntil: number,
	LastReward: number,
}

local puzzles: { [string]: Puzzle } = {}

local function occupied(part: BasePart): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local rel = part.CFrame:PointToObjectSpace(root.Position)
			if math.abs(rel.X) <= part.Size.X / 2 + 0.5 and math.abs(rel.Z) <= part.Size.Z / 2 + 0.5 and rel.Y > 0 and rel.Y < 7 then
				table.insert(list, p)
			end
		end
	end
	return list
end

local function needed(): number
	return if Settings.Coop.SoloTestMode then 1 else 2
end

local function setSolid(parts: { BasePart }, solid: boolean)
	for _, part in parts do
		part.CanCollide = solid
		local solidT = (part:GetAttribute("SolidTransparency") :: number?) or 0
		part.Transparency = if solid then solidT else 0.9
	end
end

local function setVisible(parts: { BasePart }, visible: boolean)
	for _, part in parts do
		part.CanCollide = visible
		part.Transparency = if visible then 0.1 else 1
	end
end

local function playersInArea(pz: Puzzle): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and (root.Position - pz.Center).Magnitude <= pz.Radius then
			table.insert(list, p)
		end
	end
	return list
end

local function solvable(pz: Puzzle, now: number): boolean
	if pz.Kind == "Tuer" then
		return now < pz.OpenUntil
	elseif pz.Kind == "Bruecke" then
		return now < pz.OpenUntil
	elseif pz.Kind == "Konsole" then
		return pz.RegionId ~= nil or now < pz.ConsoleUntil + 3
	end
	return false
end

local function reward(pz: Puzzle, toucher: Player)
	local now = os.clock()
	if not solvable(pz, now) then
		Remotes.Event("Toast"):FireClient(toucher, "🤝 Dieses Rätsel schafft ihr nur zusammen!", "info")
		return
	end
	if now - pz.LastReward < Settings.Coop.RewardCooldown then
		return
	end
	pz.LastReward = now
	local zone = Zones[pz.ZoneIndex]
	local base = zone and zone.Strecken[2] and zone.Strecken[2].Belohnung or { Energie = 100, XP = 50 }
	local team = playersInArea(pz)
	for _, p in team do
		local data = DataService.Get(p)
		if data then
			local first = not data.CoopSolved[pz.Id]
			DataService.Update(p, function(d)
				d.CoopSolved[pz.Id] = true
			end)
			LevelService.Grant(p, base, if first then 3 else 1.5)
			QuestEvents.Fire(p, "Coop", { Id = pz.Id })
			Remotes.Event("Toast"):FireClient(p, ("🤝 Team-Belohnung! (%d Spieler)"):format(#team), "gut")
			Remotes.Event("Effect"):FireClient(p, "Finish", { Pos = pz.Center })
		end
	end
end

local function collect(tag: string, id: string): { BasePart }
	local list = {}
	for _, part in CollectionService:GetTagged(tag) do
		if part:IsA("BasePart") and part:GetAttribute("PuzzleId") == id then
			table.insert(list, part)
		end
	end
	return list
end

local function setupPuzzle(area: Instance)
	if not area:IsA("BasePart") then
		return
	end
	local id = area:GetAttribute("PuzzleId") :: string?
	if not id or puzzles[id] then
		return
	end
	local pz: Puzzle = {
		Id = id,
		Kind = (area:GetAttribute("Kind") :: string?) or "Tuer",
		ZoneIndex = (area:GetAttribute("ZoneIndex") :: number?) or 1,
		Center = area.Position,
		Radius = (area:GetAttribute("Radius") :: number?) or Settings.Coop.AreaRadius,
		Plates = collect(Tags.CoopPlate, id),
		Buttons = collect(Tags.CoopButton, id),
		Doors = collect(Tags.CoopDoor, id),
		Bridges = collect(Tags.CoopBridge, id),
		Consoles = collect(Tags.CoopConsole, id),
		Rewards = collect(Tags.CoopReward, id),
		OpenUntil = 0,
		Presses = {},
		RegionId = nil,
		ConsoleUntil = 0,
		LastReward = -math.huge,
	}
	puzzles[id] = pz
	setSolid(pz.Doors, true)
	setVisible(pz.Bridges, false)

	for _, btn in pz.Buttons do
		local prompt = btn:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				pz.Presses[btn] = { t = os.clock(), p = player }
				btn.Color = Color3.fromRGB(120, 230, 120)
				task.delay(Settings.Coop.BridgeWindow, function()
					btn.Color = Color3.fromRGB(255, 120, 120)
				end)
				-- alle Knöpfe innerhalb des Zeitfensters von verschiedenen Spielern?
				local now = os.clock()
				local who = {}
				local count = 0
				for _, b in pz.Buttons do
					local press = pz.Presses[b]
					if press and now - press.t <= Settings.Coop.BridgeWindow then
						count += 1
						who[press.p] = true
					end
				end
				local distinct = Util.Count(who)
				if count >= math.min(#pz.Buttons, needed()) and distinct >= needed() then
					pz.OpenUntil = now + Settings.Coop.BridgeDuration
					setVisible(pz.Bridges, true)
					setSolid(pz.Doors, false)
					for _, p in playersInArea(pz) do
						Remotes.Event("Toast"):FireClient(p, ("🌉 Die Brücke ist da – %d Sekunden!"):format(Settings.Coop.BridgeDuration), "gut")
					end
				elseif not Settings.Coop.SoloTestMode then
					Remotes.Event("Toast"):FireClient(player, "Dein Partner muss den anderen Knopf gleichzeitig drücken!", "info")
				end
			end)
		end
	end

	for _, r in pz.Rewards do
		r.Touched:Connect(function(hit)
			local player = Util.PlayerFromPart(hit)
			if player then
				reward(pz, player)
			end
		end)
	end
end

function CoopService.Init() end

function CoopService.Start()
	for _, a in CollectionService:GetTagged(Tags.CoopArea) do
		setupPuzzle(a)
	end
	CollectionService:GetInstanceAddedSignal(Tags.CoopArea):Connect(function(a)
		task.wait(1) -- warten, bis alle Teile des Rätsels da sind
		setupPuzzle(a)
	end)

	task.spawn(function()
		while true do
			task.wait(0.2)
			local now = os.clock()
			for _, pz in puzzles do
				-- Druckplatten
				if pz.Kind == "Tuer" then
					local busy = 0
					for _, plate in pz.Plates do
						local on = #occupied(plate) > 0
						plate.Color = if on then Color3.fromRGB(120, 230, 120) else Color3.fromRGB(255, 200, 90)
						if on then
							busy += 1
						end
					end
					if busy >= math.min(#pz.Plates, needed()) and #pz.Plates > 0 then
						pz.OpenUntil = now + Settings.Coop.DoorHoldTime
					end
					setSolid(pz.Doors, now >= pz.OpenUntil)
				elseif pz.Kind == "Bruecke" then
					if pz.OpenUntil > 0 and now >= pz.OpenUntil then
						pz.OpenUntil = 0
						setVisible(pz.Bridges, false)
						setSolid(pz.Doors, true)
					end
				elseif pz.Kind == "Konsole" then
					local on = false
					for _, c in pz.Consoles do
						if #occupied(c) > 0 then
							on = true
						end
						c.Color = if on then Color3.fromRGB(120, 200, 255) else Color3.fromRGB(190, 160, 255)
					end
					if on then
						pz.ConsoleUntil = now + (if Settings.Coop.SoloTestMode then 20 else 0)
					end
					local active = on or now < pz.ConsoleUntil
					if active and not pz.RegionId then
						pz.RegionId = TimeScaleService.AddRegion(pz.Center, pz.Radius, Settings.Coop.ConsoleFactor, nil)
					elseif not active and pz.RegionId then
						TimeScaleService.RemoveRegion(pz.RegionId)
						pz.RegionId = nil
					end
				end
			end
		end
	end)
end

return CoopService
