--!strict
--[[
	PlayerService: alles rund um den Charakter
	- Spawn am Respawn-Punkt (Attribut "RespawnPos")
	- Werte anwenden (Lauftempo, Sprungkraft, Leben)
	- Namensschild mit Titel
	- Positions-Verlauf für "Zurückspulen"
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Tags = require(Shared:WaitForChild("Tags"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Janitor = require(Shared:WaitForChild("Janitor"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local PlayerService = {}

type Sample = { t: number, cf: CFrame }
local history: { [Player]: { Sample } } = {}
local janitors: { [Player]: any } = {} -- räumt Verbindungen pro Spieler auf
local charJanitors: { [Player]: any } = {} -- räumt Verbindungen pro Charakter auf
local HISTORY_SECONDS = 6

function PlayerService.IsAdmin(player: Player): boolean
	if RunService:IsStudio() and Settings.AdminInStudio then
		return true
	end
	return table.find(Settings.AdminUserIds, player.UserId) ~= nil
end

function PlayerService.GetHubSpawn(): Vector3
	local spawn = CollectionService:GetTagged(Tags.HubSpawn)[1]
	if spawn and spawn:IsA("BasePart") then
		return spawn.Position + Vector3.new(0, 3, 0)
	end
	return Settings.HubCenter + Vector3.new(0, 6, 0)
end

-- Werte (Tempo, Sprung, Leben) auf den Humanoid übertragen
function PlayerService.ApplyStats(player: Player)
	local stats = DataService.GetStats(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not stats or not hum then
		return
	end
	local boost = if player:GetAttribute("Boosting") then stats.BoostSpeed else 0
	hum.WalkSpeed = stats.WalkSpeed + boost
	hum.UseJumpPower = true
	hum.JumpPower = stats.JumpPower
	if math.abs(hum.MaxHealth - stats.MaxHealth) > 0.5 then
		local ratio = if hum.MaxHealth > 0 then hum.Health / hum.MaxHealth else 1
		hum.MaxHealth = stats.MaxHealth
		hum.Health = math.max(1, stats.MaxHealth * ratio)
	end
end

-- Position von vor "seconds" Sekunden
function PlayerService.GetPositionAgo(player: Player, seconds: number): CFrame?
	local list = history[player]
	if not list or #list == 0 then
		return nil
	end
	local target = os.clock() - seconds
	for i = #list, 1, -1 do
		if list[i].t <= target then
			return list[i].cf
		end
	end
	return list[1].cf
end

function PlayerService.ClearHistory(player: Player)
	history[player] = {}
end

local function makeNameplate(player: Player, char: Model)
	local head = char:WaitForChild("Head", 10)
	if not head or not head:IsA("BasePart") then
		return
	end
	local old = head:FindFirstChild("Namensschild")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Namensschild"
	gui.Size = UDim2.fromOffset(200, 50)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 80
	local title = Instance.new("TextLabel")
	title.Name = "Titel"
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.5)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 215, 90)
	title.TextStrokeTransparency = 0.4
	title.Text = ""
	title.Parent = gui
	local lvl = Instance.new("TextLabel")
	lvl.Name = "Level"
	lvl.BackgroundTransparency = 1
	lvl.Position = UDim2.fromScale(0, 0.5)
	lvl.Size = UDim2.fromScale(1, 0.5)
	lvl.Font = Enum.Font.FredokaOne
	lvl.TextScaled = true
	lvl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lvl.TextStrokeTransparency = 0.4
	lvl.Parent = gui
	gui.Parent = head
	PlayerService.UpdateNameplate(player)
end

function PlayerService.UpdateNameplate(player: Player)
	local data = DataService.Get(player)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	local gui = head and head:FindFirstChild("Namensschild")
	if not data or not gui then
		return
	end
	local title = gui:FindFirstChild("Titel") :: TextLabel?
	local lvl = gui:FindFirstChild("Level") :: TextLabel?
	if title then
		title.Text = if data.ActiveTitle ~= "" then ("🏅 " .. data.ActiveTitle) else ""
	end
	if lvl then
		lvl.Text = ("%s · Lv. %d"):format(player.DisplayName, data.Level)
	end
end

local function onCharacter(player: Player, char: Model)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	local root = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not hum or not root then
		return
	end
	hum.BreakJointsOnDeath = false
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None -- eigenes Namensschild
	PlayerService.ApplyStats(player)
	hum.Health = hum.MaxHealth
	PlayerService.ClearHistory(player)

	-- Am Respawn-Punkt erscheinen
	task.defer(function()
		local pos = player:GetAttribute("RespawnPos")
		if typeof(pos) == "Vector3" and char.Parent then
			pcall(function()
				player:RequestStreamAroundAsync(pos, 5)
			end)
			char:PivotTo(CFrame.new(pos + Vector3.new(0, 4, 0)))
		end
	end)

	makeNameplate(player, char)

	local old = charJanitors[player]
	if old then
		old:Cleanup()
	end
	local cj = Janitor.new()
	charJanitors[player] = cj
	cj:Add(hum.Died:Connect(function()
		-- Kinderfreundlich: der Charakter zerfällt in Zahnräder
		Remotes.Event("Effect"):FireAllClients("GearBurst", { Pos = root.Position, Size = 1.2 })
	end))
end

function PlayerService.Init() end

function PlayerService.Start()
	DataService.OnLoaded(function(player)
		player:SetAttribute("Zone", 0)
		player:SetAttribute("RespawnPos", PlayerService.GetHubSpawn())
		player:SetAttribute("IsAdmin", PlayerService.IsAdmin(player))
		history[player] = {}
		local j = Janitor.new()
		janitors[player] = j
		j:Add(player.CharacterAdded:Connect(function(char)
			onCharacter(player, char)
		end))
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end)

	Players.PlayerRemoving:Connect(function(p)
		history[p] = nil
		for _, map in { janitors, charJanitors } do
			local j = map[p]
			map[p] = nil
			if j then
				j:Cleanup()
			end
		end
	end)

	DataService.Changed:Connect(function(player)
		PlayerService.ApplyStats(player)
		PlayerService.UpdateNameplate(player)
	end)

	-- Positions-Verlauf alle 0,1 s
	task.spawn(function()
		while true do
			task.wait(0.1)
			local now = os.clock()
			for player, list in history do
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				-- nur sichere Positionen merken (auf dem Boden)
				if root and hum and hum.Health > 0 and hum.FloorMaterial ~= Enum.Material.Air then
					table.insert(list, { t = now, cf = root.CFrame })
				end
				while #list > 0 and now - list[1].t > HISTORY_SECONDS do
					table.remove(list, 1)
				end
			end
		end
	end)
end

return PlayerService
