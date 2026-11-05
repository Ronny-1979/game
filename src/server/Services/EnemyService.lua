--!strict
--[[
	EnemyService: Rost-Bots mit einfacher KI
	Zustände: Patrouille → Verfolgen → (Ausholen → Rammen) → Zurücksetzen
	Besiegen: Zeit-Wurf (AbilityService) oder Sprung-Angriff (von oben draufspringen).
	Besiegte Bots zerfallen in Zahnräder und kommen nach einer Weile wieder.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Enemies = require(Config:WaitForChild("Enemies")) :: any
local Tags = require(Shared:WaitForChild("Tags"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local LevelService = require(script.Parent:WaitForChild("LevelService"))
local TimeScaleService = require(script.Parent:WaitForChild("TimeScaleService"))
local QuestEvents = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("QuestEvents"))

local EnemyService = {}

type Enemy = {
	Id: string,
	Cfg: any,
	Model: Model,
	Root: BasePart,
	Home: Vector3,
	Radius: number,
	Hp: number,
	MaxHp: number,
	State: string,
	Target: Player?,
	Goal: Vector3,
	StateTime: number,
	DashDir: Vector3,
	Dead: boolean,
	Folder: Instance,
	HitCooldown: { [Player]: number },
	Bar: Frame?,
	Phase: number,
	Zone: number,
}

local enemies: { Enemy } = {}
local rng = Random.new()

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

local function makePart(props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

-- Baut einen kleinen Roboter aus Grundformen
local function buildModel(cfg: any, pos: Vector3): (Model, BasePart, Frame)
	local g = cfg.Groesse
	local model = Instance.new("Model")
	model.Name = cfg.Name
	local body = makePart({
		Name = "Koerper",
		Size = Vector3.new(g, g * 0.85, g),
		Color = cfg.Farbe,
		Material = Enum.Material.Metal,
		Anchored = true,
		CFrame = CFrame.new(pos + Vector3.new(0, g * 0.5 + 0.6, 0)),
	})
	body.Parent = model
	model.PrimaryPart = body
	local function add(p: BasePart)
		p.Anchored = false
		p.Massless = true
		p.Parent = model
		weld(body, p)
	end
	for _, side in { -1, 1 } do
		local eye = makePart({
			Name = "Auge",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(g * 0.28, g * 0.28, g * 0.28),
			Color = cfg.Augenfarbe,
			Material = Enum.Material.Neon,
			CFrame = body.CFrame * CFrame.new(side * g * 0.22, g * 0.12, -g * 0.5),
		})
		add(eye)
		local wheel = makePart({
			Name = "Rad",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(g * 0.25, g * 0.55, g * 0.55),
			Color = Color3.fromRGB(70, 60, 55),
			CFrame = body.CFrame * CFrame.new(side * g * 0.55, -g * 0.4, 0),
		})
		add(wheel)
	end
	local antenna = makePart({
		Name = "Antenne",
		Size = Vector3.new(0.3, g * 0.5, 0.3),
		Color = Color3.fromRGB(90, 80, 70),
		CFrame = body.CFrame * CFrame.new(0, g * 0.65, 0),
	})
	add(antenna)
	local tip = makePart({
		Name = "Spitze",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.8, 0.8, 0.8),
		Color = cfg.Augenfarbe,
		Material = Enum.Material.Neon,
		CFrame = body.CFrame * CFrame.new(0, g * 0.9, 0),
	})
	add(tip)
	local gear = makePart({
		Name = "Zahnrad",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, g * 0.6, g * 0.6),
		Color = Color3.fromRGB(215, 170, 80),
		Material = Enum.Material.Metal,
		CFrame = body.CFrame * CFrame.new(g * 0.52, g * 0.1, 0),
	})
	add(gear)

	-- Lebensleiste
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(90, 26)
	gui.StudsOffset = Vector3.new(0, g + 1, 0)
	gui.MaxDistance = 90
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(1, 0.55)
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.4
	name.Text = cfg.Name
	name.Parent = gui
	local back = Instance.new("Frame")
	back.Position = UDim2.fromScale(0, 0.6)
	back.Size = UDim2.fromScale(1, 0.4)
	back.BackgroundColor3 = Color3.fromRGB(60, 50, 45)
	back.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = back
	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromScale(1, 1)
	bar.BackgroundColor3 = Color3.fromRGB(120, 230, 120)
	bar.Parent = back
	corner:Clone().Parent = bar
	gui.Parent = body

	model:SetAttribute("EnemyType", cfg.Name)
	CollectionService:AddTag(model, Tags.Enemy)
	return model, body, bar
end

local function nearestPlayer(pos: Vector3, maxDist: number): (Player?, BasePart?, number)
	local best, bestRoot, bestDist = nil, nil, maxDist
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			local d = (root.Position - pos).Magnitude
			if d < bestDist then
				best, bestRoot, bestDist = p, root, d
			end
		end
	end
	return best, bestRoot, bestDist
end

local function updateBar(e: Enemy)
	if e.Bar then
		e.Bar.Size = UDim2.fromScale(math.clamp(e.Hp / e.MaxHp, 0, 1), 1)
	end
end

local function kill(e: Enemy, killer: Player?)
	if e.Dead then
		return
	end
	e.Dead = true
	Remotes.Event("Effect"):FireAllClients("GearBurst", { Pos = e.Root.Position, Size = e.Cfg.Groesse / 4 })
	e.Model.Parent = nil
	if killer and DataService.Get(killer) then
		LevelService.Grant(killer, { XP = e.Cfg.XP, Energie = e.Cfg.Energie }, 1)
		DataService.Update(killer, function(d)
			d.Stats.Defeated += 1
		end)
		QuestEvents.Fire(killer, "Gegner", { Zone = e.Zone })
	end
	task.delay(e.Cfg.Respawnzeit, function()
		e.Hp = e.MaxHp
		e.Dead = false
		e.State = "Patrouille"
		e.Target = nil
		e.Root.CFrame = CFrame.new(e.Home + Vector3.new(0, e.Cfg.Groesse * 0.5 + 0.6, 0))
		updateBar(e)
		e.Model.Parent = e.Folder
	end)
end

function EnemyService.Damage(e: Enemy, amount: number, player: Player?)
	if e.Dead then
		return
	end
	e.Hp -= amount
	updateBar(e)
	Remotes.Event("Effect"):FireAllClients("Hit", { Pos = e.Root.Position, Amount = math.floor(amount) })
	if player and e.State == "Patrouille" then
		e.State = "Verfolgen"
		e.Target = player
	end
	if e.Hp <= 0 then
		kill(e, player)
	end
end

-- Für den Zeit-Wurf: erstes getroffenes Ziel entlang eines Strahls
function EnemyService.FindTarget(origin: Vector3, dir: Vector3, range: number): (any, number?)
	local best, bestAlong = nil, math.huge
	for _, e in enemies do
		if not e.Dead then
			local v = e.Root.Position - origin
			local along = v:Dot(dir)
			local r = e.Cfg.Groesse * 0.6
			if along > 0 and along < range + r then
				local perp = (v - dir * along).Magnitude
				if perp <= r + 2.5 and along < bestAlong then
					best, bestAlong = e, along
				end
			end
		end
	end
	if best then
		return best, bestAlong
	end
	return nil, nil
end

local function spawnFromMarker(marker: Instance)
	if not marker:IsA("BasePart") then
		return
	end
	local typ = marker:GetAttribute("EnemyType") :: string?
	local cfg = typ and Enemies[typ]
	if not cfg then
		warn("[EnemyService] Unbekannter Gegner:", typ)
		return
	end
	local count = (marker:GetAttribute("Count") :: number?) or 4
	local radius = (marker:GetAttribute("Radius") :: number?) or 30
	local folder = Instance.new("Folder")
	folder.Name = "Gegner_" .. typ
	folder.Parent = marker.Parent
	for i = 1, count do
		local angle = (i / count) * math.pi * 2
		local home = marker.Position + Vector3.new(math.cos(angle) * radius * 0.5, 0, math.sin(angle) * radius * 0.5)
		local model, body, bar = buildModel(cfg, home)
		model.Parent = folder
		local e: Enemy = {
			Id = typ .. i,
			Cfg = cfg,
			Model = model,
			Root = body,
			Home = home,
			Radius = radius,
			Hp = cfg.Leben,
			MaxHp = cfg.Leben,
			State = "Patrouille",
			Target = nil,
			Goal = home,
			StateTime = 0,
			DashDir = Vector3.zAxis,
			Dead = false,
			Folder = folder,
			HitCooldown = {},
			Bar = bar,
			Phase = rng:NextNumber(0, 10),
			Zone = (marker:GetAttribute("ZoneIndex") :: number?) or 1,
		}
		table.insert(enemies, e)
	end
end

local function moveTowards(e: Enemy, goal: Vector3, speed: number, dt: number, center: Vector3?)
	local pos = e.Root.Position
	local flatGoal = Vector3.new(goal.X, pos.Y, goal.Z)
	local delta = flatGoal - pos
	local dist = delta.Magnitude
	if dist < 0.1 then
		return
	end
	local step = math.min(dist, speed * dt)
	local dir = delta.Unit
	local newPos = pos + dir * step
	-- in der Arena bleiben
	local c = center or e.Home
	local fromHome = Vector3.new(newPos.X - c.X, 0, newPos.Z - c.Z)
	if fromHome.Magnitude > e.Radius then
		newPos = Vector3.new(c.X, newPos.Y, c.Z) + fromHome.Unit * e.Radius
	end
	e.Root.CFrame = CFrame.lookAt(newPos, newPos + dir)
end

local function step(e: Enemy, dt: number, now: number)
	local scale = TimeScaleService.GetScale(e.Root.Position)
	local sdt = dt * scale
	local cfg = e.Cfg
	local pos = e.Root.Position
	local baseY = e.Home.Y + cfg.Groesse * 0.5 + 0.6
	e.StateTime += sdt

	local target = nearestPlayer(pos, cfg.Sichtweite)
	if e.State == "Patrouille" then
		if (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(e.Goal.X, 0, e.Goal.Z)).Magnitude < 2 or e.StateTime > 6 then
			local a = rng:NextNumber(0, math.pi * 2)
			local r = rng:NextNumber(0, e.Radius * 0.8)
			e.Goal = e.Home + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			e.StateTime = 0
		end
		moveTowards(e, e.Goal, cfg.Tempo * 0.45, sdt)
		if target then
			e.State = "Verfolgen"
			e.Target = target
			e.StateTime = 0
		end
	elseif e.State == "Verfolgen" then
		local tchar = e.Target and e.Target.Character
		local tr = tchar and tchar:FindFirstChild("HumanoidRootPart") :: BasePart?
		local thum = tchar and tchar:FindFirstChildOfClass("Humanoid")
		if not tr or not thum or thum.Health <= 0 or (tr.Position - e.Home).Magnitude > e.Radius * 1.6 then
			e.State = "Zuruecksetzen"
			e.StateTime = 0
		else
			moveTowards(e, tr.Position, cfg.Tempo, sdt)
			if cfg.Angriffsmuster == "Ramme" and (tr.Position - pos).Magnitude < 12 then
				e.State = "Ausholen"
				e.StateTime = 0
				local d = Vector3.new(tr.Position.X - pos.X, 0, tr.Position.Z - pos.Z)
				e.DashDir = if d.Magnitude > 0.1 then d.Unit else e.Root.CFrame.LookVector
			end
		end
	elseif e.State == "Ausholen" then
		-- gut sichtbare Warnung: der Bot zittert kurz
		local wobble = math.sin(now * 40) * 0.25
		e.Root.CFrame = CFrame.lookAt(pos, pos + e.DashDir) * CFrame.Angles(0, wobble, 0)
		if e.StateTime > 0.8 then
			e.State = "Rammen"
			e.StateTime = 0
		end
	elseif e.State == "Rammen" then
		moveTowards(e, pos + e.DashDir * 10, cfg.Tempo * 2.6, sdt)
		if e.StateTime > 0.6 then
			e.State = "Verfolgen"
			e.StateTime = 0
		end
	elseif e.State == "Zuruecksetzen" then
		moveTowards(e, e.Home, cfg.Tempo * 1.2, sdt)
		e.Hp = math.min(e.MaxHp, e.Hp + e.MaxHp * 0.5 * sdt)
		updateBar(e)
		if (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(e.Home.X, 0, e.Home.Z)).Magnitude < 2 then
			e.State = "Patrouille"
			e.Target = nil
			e.StateTime = 0
		end
	end

	-- Höhe (Hüpfer hüpfen)
	local cf = e.Root.CFrame
	local y = baseY
	if cfg.Angriffsmuster == "Huepfer" and e.State == "Verfolgen" then
		y += math.abs(math.sin((now + e.Phase) * 5 * scale)) * 3
	end
	local spin = if cfg.Angriffsmuster == "Kreisel" and e.State == "Verfolgen" then CFrame.Angles(0, (now * 8) % (math.pi * 2), 0) else CFrame.identity
	e.Root.CFrame = CFrame.new(cf.Position.X, y, cf.Position.Z) * cf.Rotation * spin

	-- Berührung mit Spielern: Sprung-Angriff oder Schaden
	local top = e.Root.Position.Y + cfg.Groesse * 0.45
	local hitRadius = cfg.Groesse * (if cfg.Angriffsmuster == "Kreisel" then 0.85 else 0.65)
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			local rp = root.Position
			local flat = Vector3.new(rp.X - e.Root.Position.X, 0, rp.Z - e.Root.Position.Z).Magnitude
			local above = rp.Y - top
			if flat < hitRadius + 1.2 and above > 0.5 and above < 4.5 and root.AssemblyLinearVelocity.Y < -1 then
				-- Sprung-Angriff!
				local stats = DataService.GetStats(p)
				EnemyService.Damage(e, stats and stats.StompDamage or 25, p)
				Remotes.Event("Bounce"):FireClient(p, 55, Vector3.zero)
				if e.Dead then
					break
				end
			elseif flat < hitRadius + 1 and math.abs(rp.Y - e.Root.Position.Y) < cfg.Groesse then
				if (e.HitCooldown[p] or 0) < now then
					e.HitCooldown[p] = now + 1.2
					hum:TakeDamage(cfg.Schaden)
					local away = Vector3.new(rp.X - e.Root.Position.X, 0, rp.Z - e.Root.Position.Z)
					Remotes.Event("Bounce"):FireClient(p, 30, if away.Magnitude > 0.1 then away.Unit * 45 else Vector3.zero)
				end
			end
		end
	end
end

function EnemyService.Init() end

function EnemyService.Start()
	for _, m in CollectionService:GetTagged(Tags.EnemySpawn) do
		spawnFromMarker(m)
	end
	CollectionService:GetInstanceAddedSignal(Tags.EnemySpawn):Connect(spawnFromMarker)

	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for _, e in enemies do
			if not e.Dead then
				-- nur rechnen, wenn ein Spieler in der Nähe ist (spart Leistung)
				local p = nearestPlayer(e.Root.Position, 160)
				if p then
					step(e, dt, now)
				end
			end
		end
	end)
end

return EnemyService
