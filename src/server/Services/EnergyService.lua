--!strict
--[[
	EnergyService: Zeit-Energie sammeln
	- Kristalle anklicken (ClickDetector, Server prüft Abstand + Abklingzeit)
	- Durch Energie-Felder laufen
	- Energie-Kugeln im Feld einsammeln (Sammelradius)
	- Doppel-Energie-Boost: ab und zu leuchtet ein Feld golden → doppelte Energie in dieser Zone
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
local BonusService = require(script.Parent:WaitForChild("BonusService"))
local QuestEvents = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("QuestEvents"))
local Validate = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Validate"))

local EnergyService = {}

local lastClick: { [Player]: number } = {}
local pendingGain: { [Player]: number } = {}
local boostZone = 0
local boostEnds = 0

type Orb = { Part: BasePart, Field: BasePart, Zone: number, Active: boolean }
local orbs: { Orb } = {}

function EnergyService.BoostFactor(zoneIndex: number): number
	if zoneIndex == boostZone and os.clock() < boostEnds then
		return Settings.Boost.Multiplier
	end
	return 1
end

function EnergyService.GetBoost(): (number, number)
	return boostZone, boostEnds
end

local function zoneValue(zoneIndex: number): number
	local z = Zones[zoneIndex]
	return if z then z.Energiewert else 1
end

-- Energie gutschreiben (mit allen Multiplikatoren) und für die Anzeige merken
local function give(player: Player, base: number, zoneIndex: number): number
	local stats = DataService.GetStats(player)
	if not stats then
		return 0
	end
	local amount = base * stats.TotalEnergyMult * EnergyService.BoostFactor(zoneIndex) * BonusService.EnergyFactor(player)
	amount = math.max(1, math.floor(amount))
	DataService.AddEnergy(player, amount)
	return amount
end

local function setupCrystal(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local detector = part:FindFirstChildOfClass("ClickDetector")
	if not detector then
		detector = Instance.new("ClickDetector")
		detector.MaxActivationDistance = Settings.Energy.ClickDistance
		detector.Parent = part
	end
	detector.MouseClick:Connect(function(player: Player)
		local now = os.clock()
		if now - (lastClick[player] or 0) < Settings.Energy.ClickCooldown then
			return
		end
		if not Validate.Near(player, part.Position, Settings.Energy.ClickDistance + 6) then
			return
		end
		lastClick[player] = now
		local stats = DataService.GetStats(player)
		if not stats then
			return
		end
		local zoneIndex = (part:GetAttribute("ZoneIndex") :: number?) or 1
		local amount = give(player, stats.ClickPower * zoneValue(zoneIndex), zoneIndex)
		Remotes.Event("Effect"):FireClient(player, "Click", { Pos = part.Position, Amount = amount })
		QuestEvents.Fire(player, "Kristall", { Zone = zoneIndex })
	end)
end

local function insideField(field: BasePart, pos: Vector3): boolean
	local rel = field.CFrame:PointToObjectSpace(pos)
	local half = field.Size / 2
	return math.abs(rel.X) <= half.X and math.abs(rel.Z) <= half.Z and rel.Y > -2 and rel.Y < 10
end

local function spawnOrbs(field: BasePart)
	local folder = field.Parent
	local zoneIndex = (field:GetAttribute("ZoneIndex") :: number?) or 1
	local rng = Random.new()
	for _ = 1, Settings.Energy.OrbsPerField do
		local orb = Instance.new("Part")
		orb.Name = "EnergieKugel"
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(1.6, 1.6, 1.6)
		orb.Material = Enum.Material.Neon
		orb.Color = Color3.fromRGB(120, 230, 255)
		orb.Anchored = true
		orb.CanCollide = false
		orb.CanQuery = false
		orb.CanTouch = false
		local half = field.Size / 2
		local local_ = Vector3.new(rng:NextNumber(-half.X + 3, half.X - 3), 2.2, rng:NextNumber(-half.Z + 3, half.Z - 3))
		orb.CFrame = field.CFrame * CFrame.new(local_)
		orb.Parent = folder
		table.insert(orbs, { Part = orb, Field = field, Zone = zoneIndex, Active = true })
	end
end

local function startBoost()
	local fields = CollectionService:GetTagged(Tags.EnergyField)
	if #fields == 0 then
		return
	end
	local field = fields[math.random(1, #fields)]
	local zoneIndex = (field:GetAttribute("ZoneIndex") :: number?) or 1
	boostZone = zoneIndex
	boostEnds = os.clock() + Settings.Boost.Duration
	for _, f in fields do
		f:SetAttribute("Boost", f:GetAttribute("ZoneIndex") == zoneIndex)
	end
	local zone = Zones[zoneIndex]
	Remotes.Event("Toast"):FireAllClients(
		("🚀 Doppel-Energie in %s für %d Sekunden!"):format(zone and zone.Name or "?", Settings.Boost.Duration),
		"gut"
	)
	task.delay(Settings.Boost.Duration, function()
		for _, f in fields do
			f:SetAttribute("Boost", false)
		end
		boostZone = 0
	end)
end

function EnergyService.Init() end

function EnergyService.Start()
	for _, c in CollectionService:GetTagged(Tags.EnergyCrystal) do
		setupCrystal(c)
	end
	CollectionService:GetInstanceAddedSignal(Tags.EnergyCrystal):Connect(setupCrystal)
	for _, f in CollectionService:GetTagged(Tags.EnergyField) do
		if f:IsA("BasePart") then
			spawnOrbs(f)
		end
	end

	Players.PlayerRemoving:Connect(function(p)
		lastClick[p] = nil
		pendingGain[p] = nil
	end)

	-- Felder: Energie fürs Laufen
	task.spawn(function()
		while true do
			task.wait(Settings.Energy.FieldTick)
			local fields = CollectionService:GetTagged(Tags.EnergyField)
			for _, player in Players:GetPlayers() do
				local root = Validate.Alive(player)
				local stats = DataService.GetStats(player)
				if root and stats and root.AssemblyLinearVelocity.Magnitude >= Settings.Energy.FieldMinSpeed then
					for _, field in fields do
						if field:IsA("BasePart") and insideField(field, root.Position) then
							local zoneIndex = (field:GetAttribute("ZoneIndex") :: number?) or 1
							local got = give(player, stats.FieldEnergy * zoneValue(zoneIndex), zoneIndex)
							pendingGain[player] = (pendingGain[player] or 0) + got
							break
						end
					end
				end
			end
		end
	end)

	-- Kugeln einsammeln
	task.spawn(function()
		while true do
			task.wait(0.2)
			for _, player in Players:GetPlayers() do
				local root = Validate.Alive(player)
				local stats = DataService.GetStats(player)
				if root and stats then
					local radius = stats.CollectRadius
					for _, orb in orbs do
						if orb.Active and (orb.Part.Position - root.Position).Magnitude <= radius then
							orb.Active = false
							orb.Part.Transparency = 1
							local got = give(player, 3 * stats.FieldEnergy * zoneValue(orb.Zone), orb.Zone)
							pendingGain[player] = (pendingGain[player] or 0) + got
							Remotes.Event("Effect"):FireClient(player, "Orb", { Pos = orb.Part.Position })
							task.delay(Settings.Energy.OrbRespawn, function()
								orb.Active = true
								orb.Part.Transparency = 0
							end)
						end
					end
				end
			end
		end
	end)

	-- Gesammelte Energie gebündelt anzeigen (alle 1,5 s)
	task.spawn(function()
		while true do
			task.wait(1.5)
			for player, amount in pendingGain do
				if amount > 0 and player.Parent then
					Remotes.Event("Effect"):FireClient(player, "Gain", { Amount = amount, Text = "+" .. Util.FormatNumber(amount) .. " ⚡" })
				end
			end
			table.clear(pendingGain)
		end
	end)

	-- Doppel-Energie-Boosts
	task.spawn(function()
		while true do
			task.wait(Settings.Boost.Interval)
			startBoost()
		end
	end)
end

return EnergyService
