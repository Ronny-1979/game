--!strict
--[[
	AbilityService: Zeit-Fähigkeiten – alles wird hier auf dem Server geprüft und ausgeführt.
	Prüfungen: Name bekannt, Klasse erlaubt, lebendig, Abklingzeit vorbei, genug Energie, Richtung gültig.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Skills = require(Config:WaitForChild("Skills")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlayerService = require(script.Parent:WaitForChild("PlayerService"))
local TimeScaleService = require(script.Parent:WaitForChild("TimeScaleService"))
local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local BossService = require(script.Parent:WaitForChild("BossService"))
local Validate = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Validate"))

local AbilityService = {}

-- Welcher Stat gehört zu welcher Fähigkeit
local STAT_PREFIX = {
	Verlangsamen = "Slow",
	Zurueckspulen = "Rewind",
	Beschleunigen = "Boost",
	ZeitWurf = "Throw",
	Hilfsplattform = "Platform",
}

local cooldowns: { [Player]: { [string]: number } } = {}
local boostToken: { [Player]: number } = {}
local platforms: { [Player]: { BasePart } } = {}

local function toast(player: Player, text: string)
	Remotes.Event("Toast"):FireClient(player, text, "fehler")
end

local Run = {}

Run.Verlangsamen = function(player: Player, root: BasePart, stats: any): boolean
	TimeScaleService.AddRegion(root.Position, stats.SlowRadius, stats.SlowFactor, stats.SlowDuration)
	Remotes.Event("Effect"):FireAllClients("Slow", { Pos = root.Position, Radius = stats.SlowRadius, Duration = stats.SlowDuration })
	return true
end

Run.Zurueckspulen = function(player: Player, root: BasePart, stats: any): boolean
	local cf = PlayerService.GetPositionAgo(player, stats.RewindSeconds)
	if not cf then
		toast(player, "Noch keine Zeit zum Zurückspulen gesammelt.")
		return false
	end
	local from = root.Position
	local char = player.Character
	if char then
		char:PivotTo(cf + Vector3.new(0, 0.5, 0))
	end
	Remotes.Event("Effect"):FireAllClients("Rewind", { From = from, To = cf.Position })
	return true
end

Run.Beschleunigen = function(player: Player, root: BasePart, stats: any): boolean
	boostToken[player] = (boostToken[player] or 0) + 1
	local token = boostToken[player]
	player:SetAttribute("Boosting", true)
	PlayerService.ApplyStats(player)
	-- Funkenspur (für alle sichtbar)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.8, 0)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.8, 0)
	a1.Parent = root
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.4
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 140, 80))
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.LightEmission = 0.8
	trail.Parent = root
	local sparks = Instance.new("ParticleEmitter")
	sparks.Rate = 40
	sparks.Lifetime = NumberRange.new(0.3, 0.6)
	sparks.Speed = NumberRange.new(2, 5)
	sparks.Size = NumberSequence.new(0.35, 0)
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 220, 110))
	sparks.LightEmission = 1
	sparks.Parent = a1
	Remotes.Event("Effect"):FireAllClients("Boost", { UserId = player.UserId })
	task.delay(stats.BoostDuration, function()
		a0:Destroy()
		a1:Destroy()
		trail:Destroy()
		if boostToken[player] == token and player.Parent then
			player:SetAttribute("Boosting", false)
			PlayerService.ApplyStats(player)
		end
	end)
	return true
end

Run.ZeitWurf = function(player: Player, root: BasePart, stats: any, dir: Vector3): boolean
	local flat = Vector3.new(dir.X, 0, dir.Z)
	if flat.Magnitude < 0.1 then
		flat = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	end
	flat = flat.Unit
	local origin = root.Position
	local range = stats.ThrowRange
	local enemy, eAlong = EnemyService.FindTarget(origin, flat, range)
	local boss, bAlong = BossService.FindTarget(origin, flat, range)
	local target, along, isBoss = enemy, eAlong, false
	if boss and (not eAlong or (bAlong :: number) < eAlong) then
		target, along, isBoss = boss, bAlong, true
	end
	local dist = along or range
	local speed = Skills.Faehigkeiten.ZeitWurf.Geschwindigkeit
	local travel = dist / speed
	Remotes.Event("Effect"):FireAllClients("Throw", { From = origin, To = origin + flat * dist, Time = travel })
	if target then
		local damage = stats.ThrowDamage
		task.delay(travel, function()
			if isBoss then
				BossService.Damage(target, damage, player)
			else
				EnemyService.Damage(target, damage, player)
			end
		end)
	end
	return true
end

Run.Hilfsplattform = function(player: Player, root: BasePart, stats: any): boolean
	local list = platforms[player] or {}
	platforms[player] = list
	-- höchstens 2 gleichzeitig
	while #list >= 2 do
		local old = table.remove(list, 1)
		if old then
			old:Destroy()
		end
	end
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	look = if look.Magnitude > 0.1 then look.Unit else Vector3.zAxis
	local size = stats.PlatformSize
	local pos = root.Position + look * (size * 0.45) - Vector3.new(0, 3.6, 0)
	local p = Instance.new("Part")
	p.Name = "Hilfsplattform"
	p.Size = Vector3.new(size, 1, size)
	p.CFrame = CFrame.lookAt(pos, pos + look)
	p.Anchored = true
	p.Color = Color3.fromRGB(225, 180, 85)
	p.Material = Enum.Material.Metal
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = workspace
	table.insert(list, p)
	Remotes.Event("Effect"):FireAllClients("Platform", { Pos = pos })
	task.delay(stats.PlatformDuration, function()
		if p.Parent then
			local t = TweenService:Create(p, TweenInfo.new(0.5), { Transparency = 1 })
			t:Play()
			t.Completed:Wait()
			p:Destroy()
		end
		local i = table.find(list, p)
		if i then
			table.remove(list, i)
		end
	end)
	return true
end

function AbilityService.Use(player: Player, name: string, dir: Vector3?)
	local def = Skills.Faehigkeiten[name]
	local data = DataService.Get(player)
	local stats = DataService.GetStats(player)
	if not def or not data or not stats then
		return
	end
	if def.NurKlasse and data.Class ~= def.NurKlasse then
		toast(player, ("%s können nur %s."):format(def.Name, def.NurKlasse))
		return
	end
	local root = Validate.Alive(player)
	if not root then
		return
	end
	local prefix = STAT_PREFIX[name]
	local cd = stats[prefix .. "Cooldown"] or def.Abklingzeit
	local cost = math.floor(stats[prefix .. "Cost"] or def.Kosten or 0)
	local now = os.clock()
	local byPlayer = cooldowns[player] or {}
	cooldowns[player] = byPlayer
	if (byPlayer[name] or 0) > now + 0.05 then
		return -- noch in Abklingzeit
	end
	if cost > 0 and data.Energy < cost then
		toast(player, ("%s braucht %s ⚡"):format(def.Name, Util.FormatNumber(cost)))
		return
	end
	local ok = Run[name](player, root, stats, dir or Vector3.zero)
	if ok then
		if cost > 0 then
			DataService.Spend(player, cost)
		end
		byPlayer[name] = now + cd
		Remotes.Event("AbilityUsed"):FireClient(player, name, cd)
	end
end

function AbilityService.Init() end

function AbilityService.Start()
	Remotes.OnEvent("UseAbility", 10, function(player, name, dir)
		if not Validate.Key(name, Skills.Faehigkeiten) then
			return
		end
		if dir ~= nil and not Validate.Vector(dir, 2) then
			return
		end
		AbilityService.Use(player, name, dir)
	end)

	Players.PlayerRemoving:Connect(function(p)
		cooldowns[p] = nil
		boostToken[p] = nil
		for _, part in platforms[p] or {} do
			part:Destroy()
		end
		platforms[p] = nil
	end)
end

return AbilityService
