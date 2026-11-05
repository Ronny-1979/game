--!strict
--[[
	EnemyService: Gegner mit einfacher KI
	Zustände: Patrouille → Verfolgen → Angriff (je nach Muster) → Zurücksetzen
	Muster: Ramme, Huepfer, Kreisel, Flieger (Sturzflug), Schuetze (Zahnrad-Wurf)
	Fern-Angriffe zeigen IMMER vorher eine Warnfläche am Boden.
	Besiegen: Zeit-Wurf (AbilityService) oder Sprung-Angriff (von oben draufspringen).
	Besiegte Gegner zerfallen in Zahnräder und kommen nach einer Weile wieder.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

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
	Cooldown: number, -- Zeit bis zum nächsten Fern-Angriff
	DivePos: Vector3?,
	DiveFrom: Vector3?,
}

local enemies: { Enemy } = {}
local rng = Random.new()
local WARN = Color3.fromRGB(255, 120, 60)

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

-- Warnfläche am Boden (orange, pulsierend)
local function warnCircle(pos: Vector3, radius: number, floorY: number): BasePart
	local p = makePart({
		Name = "Warnung",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, radius * 2, radius * 2),
		CFrame = CFrame.new(pos.X, floorY + 0.15, pos.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = WARN,
		Material = Enum.Material.Neon,
		Transparency = 0.5,
		Anchored = true,
	})
	p.Parent = workspace
	TweenService:Create(p, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.15 }):Play()
	return p
end

-- Baut einen kleinen Roboter aus Grundformen (Form aus der Konfig)
local function buildModel(cfg: any, pos: Vector3): (Model, BasePart, Frame)
	local g = cfg.Groesse
	local form = cfg.Form or "Kasten"
	local model = Instance.new("Model")
	model.Name = cfg.Name
	local bodySize = if form == "Kugel"
		then Vector3.new(g, g, g)
		elseif form == "Turm" then Vector3.new(g * 0.8, g * 1.3, g * 0.8)
		else Vector3.new(g, g * 0.85, g)
	local body = makePart({
		Name = "Koerper",
		Shape = if form == "Kugel" then Enum.PartType.Ball else Enum.PartType.Block,
		Size = bodySize,
		Color = cfg.Farbe,
		Material = Enum.Material.Metal,
		Anchored = true,
		CFrame = CFrame.new(pos + Vector3.new(0, bodySize.Y * 0.5 + 0.6, 0)),
	})
	body.Parent = model
	model.PrimaryPart = body
	local function add(p: BasePart)
		p.Anchored = false
		p.Massless = true
		p.Parent = model
		weld(body, p)
	end
	local h = bodySize.Y
	for _, side in { -1, 1 } do
		add(makePart({
			Name = "Auge",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(g * 0.26, g * 0.26, g * 0.26),
			Color = cfg.Augenfarbe,
			Material = Enum.Material.Neon,
			CFrame = body.CFrame * CFrame.new(side * g * 0.2, h * 0.15, -bodySize.Z * 0.48),
		}))
		if form == "Kugel" then
			-- Flügel
			add(makePart({
				Name = "Fluegel",
				Size = Vector3.new(g * 0.7, 0.25, g * 0.45),
				CFrame = body.CFrame * CFrame.new(side * g * 0.75, 0, 0) * CFrame.Angles(0, 0, side * math.rad(15)),
				Color = Color3.fromRGB(230, 230, 240),
				Material = Enum.Material.Metal,
			}))
		elseif form == "Turm" then
			add(makePart({
				Name = "Fuss",
				Size = Vector3.new(g * 0.35, g * 0.3, g * 0.6),
				CFrame = body.CFrame * CFrame.new(side * g * 0.25, -h * 0.55, 0),
				Color = Color3.fromRGB(80, 70, 65),
			}))
		else
			add(makePart({
				Name = "Rad",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(g * 0.25, g * 0.55, g * 0.55),
				Color = Color3.fromRGB(70, 60, 55),
				CFrame = body.CFrame * CFrame.new(side * g * 0.55, -h * 0.47, 0),
			}))
		end
	end
	if form == "Kugel" then
		-- Propeller oben
		add(makePart({
			Name = "Propeller",
			Size = Vector3.new(g * 1.4, 0.2, 0.5),
			CFrame = body.CFrame * CFrame.new(0, g * 0.62, 0),
			Color = Color3.fromRGB(215, 170, 80),
			Material = Enum.Material.Metal,
		}))
		add(makePart({
			Name = "Propeller2",
			Size = Vector3.new(0.5, 0.2, g * 1.4),
			CFrame = body.CFrame * CFrame.new(0, g * 0.62, 0),
			Color = Color3.fromRGB(215, 170, 80),
			Material = Enum.Material.Metal,
		}))
	elseif form == "Turm" then
		-- Kanone + Glocke oben
		add(makePart({
			Name = "Kanone",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(g * 0.7, g * 0.35, g * 0.35),
			CFrame = body.CFrame * CFrame.new(0, h * 0.25, -g * 0.55) * CFrame.Angles(0, math.rad(90), 0),
			Color = Color3.fromRGB(90, 80, 75),
			Material = Enum.Material.Metal,
		}))
		add(makePart({
			Name = "Glocke",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(g * 0.6, g * 0.5, g * 0.6),
			CFrame = body.CFrame * CFrame.new(0, h * 0.62, 0),
			Color = Color3.fromRGB(240, 205, 100),
			Material = Enum.Material.Metal,
		}))
	else
		add(makePart({
			Name = "Antenne",
			Size = Vector3.new(0.3, g * 0.5, 0.3),
			Color = Color3.fromRGB(90, 80, 70),
			CFrame = body.CFrame * CFrame.new(0, h * 0.75, 0),
		}))
		add(makePart({
			Name = "Spitze",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.8, 0.8, 0.8),
			Color = cfg.Augenfarbe,
			Material = Enum.Material.Neon,
			CFrame = body.CFrame * CFrame.new(0, h * 1.05, 0),
		}))
		add(makePart({
			Name = "Zahnrad",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4, g * 0.6, g * 0.6),
			Color = Color3.fromRGB(215, 170, 80),
			Material = Enum.Material.Metal,
			CFrame = body.CFrame * CFrame.new(g * 0.52, h * 0.1, 0),
		}))
	end

	-- Lebensleiste
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(90, 26)
	gui.StudsOffset = Vector3.new(0, h + 1.2, 0)
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

local function rootOf(p: Player): (BasePart?, Humanoid?)
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if root and hum and hum.Health > 0 then
		return root, hum
	end
	return nil, nil
end

local function nearestPlayer(pos: Vector3, maxDist: number): (Player?, BasePart?, number)
	local best, bestRoot, bestDist = nil, nil, maxDist
	for _, p in Players:GetPlayers() do
		local root = rootOf(p)
		if root then
			local d = (root.Position - pos).Magnitude
			if d < bestDist then
				best, bestRoot, bestDist = p, root, d
			end
		end
	end
	return best, bestRoot, bestDist
end

-- Schaden für alle Spieler im Kreis (Fern-Angriffe)
local function areaDamage(center: Vector3, radius: number, damage: number, floorY: number)
	for _, p in Players:GetPlayers() do
		local root, hum = rootOf(p)
		if root and hum then
			local flat = Vector3.new(root.Position.X - center.X, 0, root.Position.Z - center.Z).Magnitude
			if flat <= radius and root.Position.Y - floorY < 7 then
				hum:TakeDamage(damage)
				Remotes.Event("Bounce"):FireClient(p, 30, Vector3.zero)
			end
		end
	end
end

local function updateBar(e: Enemy)
	if e.Bar then
		e.Bar.Size = UDim2.fromScale(math.clamp(e.Hp / e.MaxHp, 0, 1), 1)
	end
end

local function baseY(e: Enemy): number
	local form = e.Cfg.Form or "Kasten"
	local g = e.Cfg.Groesse
	local h = if form == "Kugel" then g elseif form == "Turm" then g * 1.3 else g * 0.85
	return e.Home.Y + h * 0.5 + 0.6
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
		e.DivePos = nil
		e.Root.CFrame = CFrame.new(e.Home.X, baseY(e), e.Home.Z)
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
			-- Flieger: Höhe für den Wurf ignorieren, damit Kinder sie treffen
			if e.Cfg.Angriffsmuster == "Flieger" then
				v = Vector3.new(v.X, 0, v.Z)
			end
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
	folder.Name = "Gegner_" .. (typ :: string)
	folder.Parent = marker.Parent
	for i = 1, count do
		local angle = (i / count) * math.pi * 2 + rng:NextNumber(0, 0.5)
		local home = marker.Position + Vector3.new(math.cos(angle) * radius * 0.5, 0, math.sin(angle) * radius * 0.5)
		local model, body, bar = buildModel(cfg, home)
		model.Parent = folder
		local e: Enemy = {
			Id = (typ :: string) .. i,
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
			Cooldown = rng:NextNumber(1, cfg.Abklingzeit or 3),
			DivePos = nil,
			DiveFrom = nil,
		}
		table.insert(enemies, e)
	end
end

local function moveTowards(e: Enemy, goal: Vector3, speed: number, dt: number)
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
	local fromHome = Vector3.new(newPos.X - e.Home.X, 0, newPos.Z - e.Home.Z)
	if fromHome.Magnitude > e.Radius then
		newPos = Vector3.new(e.Home.X, newPos.Y, e.Home.Z) + fromHome.Unit * e.Radius
	end
	e.Root.CFrame = CFrame.lookAt(newPos, newPos + dir)
end

local function face(e: Enemy, pos: Vector3)
	local p = e.Root.Position
	local d = Vector3.new(pos.X - p.X, 0, pos.Z - p.Z)
	if d.Magnitude > 0.1 then
		e.Root.CFrame = CFrame.lookAt(p, p + d.Unit)
	end
end

-- Schütze: Warnfläche unter dem Ziel, dann fällt ein Zahnrad
local function shoot(e: Enemy, targetPos: Vector3)
	local floorY = e.Home.Y
	local radius = 5
	local warnTime = 1.3
	local w = warnCircle(targetPos, radius, floorY)
	Remotes.Event("Effect"):FireAllClients("GearRain", { Spots = { targetPos }, FloorY = floorY, Time = warnTime })
	task.spawn(function()
		local left = warnTime
		while left > 0 do
			local dt = task.wait(0.05)
			left -= dt * TimeScaleService.GetScale(targetPos)
		end
		w:Destroy()
		if not e.Dead then
			areaDamage(targetPos, radius, e.Cfg.Schaden, floorY)
		end
	end)
end

local function step(e: Enemy, dt: number, now: number)
	local scale = TimeScaleService.GetScale(e.Root.Position)
	local sdt = dt * scale
	local cfg = e.Cfg
	local pattern = cfg.Angriffsmuster
	local pos = e.Root.Position
	e.StateTime += sdt
	e.Cooldown -= sdt

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
		local tr = e.Target and rootOf(e.Target)
		if not tr or (tr.Position - e.Home).Magnitude > e.Radius * 1.6 then
			e.State = "Zuruecksetzen"
			e.StateTime = 0
		else
			local dist = (Vector3.new(tr.Position.X, 0, tr.Position.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
			if pattern == "Schuetze" then
				-- Abstand halten: zu nah → zurück, zu weit → näher
				if dist < 12 then
					moveTowards(e, pos + (pos - tr.Position) * 2, cfg.Tempo, sdt)
				elseif dist > 28 then
					moveTowards(e, tr.Position, cfg.Tempo, sdt)
				end
				face(e, tr.Position)
				if e.Cooldown <= 0 then
					e.Cooldown = cfg.Abklingzeit or 3
					shoot(e, Vector3.new(tr.Position.X, e.Home.Y, tr.Position.Z))
				end
			elseif pattern == "Flieger" then
				moveTowards(e, tr.Position, cfg.Tempo, sdt)
				if e.Cooldown <= 0 and dist < 22 then
					e.State = "Zielen"
					e.StateTime = 0
					e.DivePos = Vector3.new(tr.Position.X, e.Home.Y, tr.Position.Z)
					e.DiveFrom = e.Root.Position
					local w = warnCircle(e.DivePos :: Vector3, 4.5, e.Home.Y)
					task.delay(1.6, function()
						w:Destroy()
					end)
				end
			else
				moveTowards(e, tr.Position, cfg.Tempo, sdt)
				if pattern == "Ramme" and dist < 12 then
					e.State = "Ausholen"
					e.StateTime = 0
					local d = Vector3.new(tr.Position.X - pos.X, 0, tr.Position.Z - pos.Z)
					e.DashDir = if d.Magnitude > 0.1 then d.Unit else e.Root.CFrame.LookVector
				end
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
	elseif e.State == "Zielen" then
		-- Flieger zittert in der Luft über der Warnfläche
		if e.StateTime > 1.0 then
			e.State = "Sturz"
			e.StateTime = 0
		end
	elseif e.State == "Sturz" then
		local from = e.DiveFrom or pos
		local to = (e.DivePos or pos) + Vector3.new(0, cfg.Groesse * 0.5 + 0.4, 0)
		local a = math.clamp(e.StateTime / 0.4, 0, 1)
		e.Root.CFrame = CFrame.new(from:Lerp(to, a)) * e.Root.CFrame.Rotation
		if a >= 1 then
			areaDamage(e.DivePos or pos, 4.5, cfg.Schaden, e.Home.Y)
			Remotes.Event("Effect"):FireAllClients("Shock", { Pos = e.DivePos or pos, Radius = 5 })
			e.State = "Aufsteigen"
			e.StateTime = 0
			e.Cooldown = cfg.Abklingzeit or 4
		end
	elseif e.State == "Aufsteigen" then
		-- kurz am Boden: jetzt kann man draufspringen!
		if e.StateTime > 1.2 then
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

	-- Höhe: Hüpfer hüpfen, Flieger schweben (außer beim Sturzflug)
	if e.State ~= "Sturz" then
		local cf = e.Root.CFrame
		local y = baseY(e)
		if pattern == "Huepfer" and e.State == "Verfolgen" then
			y += math.abs(math.sin((now + e.Phase) * 5 * scale)) * 3
		elseif pattern == "Flieger" then
			local hover = 7 + math.sin((now + e.Phase) * 2) * 0.8
			if e.State == "Aufsteigen" then
				hover = math.clamp(e.StateTime - 0.6, 0, 0.6) / 0.6 * 7
			elseif e.State == "Zielen" then
				hover = 7 + math.sin(now * 30) * 0.3
			end
			y += hover
		end
		local spin = if pattern == "Kreisel" and e.State == "Verfolgen" then CFrame.Angles(0, (now * 8) % (math.pi * 2), 0) else CFrame.identity
		e.Root.CFrame = CFrame.new(cf.Position.X, y, cf.Position.Z) * cf.Rotation * spin
	end

	-- Berührung mit Spielern: Sprung-Angriff oder Schaden
	local g = cfg.Groesse
	local top = e.Root.Position.Y + g * 0.45
	local hitRadius = g * (if pattern == "Kreisel" then 0.85 else 0.65)
	for _, p in Players:GetPlayers() do
		local root, hum = rootOf(p)
		if root and hum then
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
			elseif flat < hitRadius + 1 and math.abs(rp.Y - e.Root.Position.Y) < g then
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
					local ok, err = pcall(step, e, dt, now)
					if not ok then
						warn("[EnemyService]", e.Id, err)
					end
				end
			end
		end
	end)
end

return EnemyService
