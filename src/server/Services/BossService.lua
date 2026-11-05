--!strict
--[[
	BossService: ein Boss pro Zone mit 3 Phasen.
	Jeder Angriff zeigt VORHER eine Warnfläche am Boden (orange/rot).
	Nach einigen Angriffen ist der Boss müde (leuchtet, 💤) und nimmt doppelten Schaden.
	Besiegte Bosse zerfallen in Zahnräder. Belohnung: XP, Energie, Gratis-Ei, Titel.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Bosses = require(Config:WaitForChild("Bosses")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Tags = require(Shared:WaitForChild("Tags"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local LevelService = require(script.Parent:WaitForChild("LevelService"))
local TimeScaleService = require(script.Parent:WaitForChild("TimeScaleService"))
local QuestEvents = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("QuestEvents"))

local BossService = {}

type Boss = {
	Cfg: any,
	Id: string,
	ZoneIndex: number,
	Center: Vector3,
	FloorY: number,
	Radius: number,
	Model: Model,
	Root: BasePart,
	Body: BasePart,
	TiredLabel: TextLabel,
	Folder: Instance,
	Hp: number,
	MaxHp: number,
	State: string,
	Phase: number,
	Tired: boolean,
	Participants: { [Player]: boolean },
	EmptyTime: number,
	FirstDefeat: { [Player]: boolean },
	FightId: number,
}

local bosses: { Boss } = {}
local rng = Random.new()

local WARN_COLOR = Color3.fromRGB(255, 120, 60)

local function makePart(props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Anchored = true
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

local function weldTo(root: BasePart, p: BasePart, model: Model)
	p.Anchored = false
	p.Massless = true
	p.Parent = model
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = p
	w.Parent = p
end

-- Boss-Modell: großes Zahnrad mit Gesicht und Krone
local function buildBoss(cfg: any, pos: Vector3): (Model, BasePart, BasePart, TextLabel)
	local g = cfg.Groesse
	local model = Instance.new("Model")
	model.Name = cfg.Name
	local root = makePart({ Name = "Kern", Size = Vector3.new(2, 2, 2), Transparency = 1, CFrame = CFrame.new(pos) })
	root.Parent = model
	model.PrimaryPart = root
	local body = makePart({
		Name = "Koerper",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(g * 0.45, g, g),
		Color = cfg.Farbe,
		Material = Enum.Material.Metal,
		CFrame = root.CFrame * CFrame.Angles(0, math.rad(90), 0),
	})
	weldTo(root, body, model)
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		local tooth = makePart({
			Name = "Zahn",
			Size = Vector3.new(g * 0.16, g * 0.16, g * 0.42),
			Color = cfg.Farbe:Lerp(Color3.new(0, 0, 0), 0.15),
			Material = Enum.Material.Metal,
			CFrame = root.CFrame * CFrame.Angles(0, 0, a) * CFrame.new(0, g * 0.53, 0),
		})
		weldTo(root, tooth, model)
	end
	for _, side in { -1, 1 } do
		local eye = makePart({
			Name = "Auge",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(g * 0.16, g * 0.16, g * 0.16),
			Color = cfg.Augenfarbe,
			Material = Enum.Material.Neon,
			CFrame = root.CFrame * CFrame.new(side * g * 0.17, g * 0.1, -g * 0.22),
		})
		weldTo(root, eye, model)
	end
	local mouth = makePart({
		Name = "Mund",
		Size = Vector3.new(g * 0.3, g * 0.05, 0.4),
		Color = Color3.fromRGB(70, 50, 40),
		CFrame = root.CFrame * CFrame.new(0, -g * 0.12, -g * 0.23),
	})
	weldTo(root, mouth, model)
	for i = -2, 2 do
		local spike = makePart({
			Name = "Krone",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(g * 0.12, g * 0.12, g * 0.12),
			Color = Color3.fromRGB(255, 215, 80),
			Material = Enum.Material.Neon,
			CFrame = root.CFrame * CFrame.new(i * g * 0.1, g * 0.62 + math.abs(i) * -0.3, 0),
		})
		weldTo(root, spike, model)
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 50)
	gui.StudsOffset = Vector3.new(0, g * 0.8, 0)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.3
	label.Text = ""
	label.Parent = gui
	gui.Parent = root
	model:SetAttribute("BossName", cfg.Name)
	CollectionService:AddTag(model, Tags.Boss)
	return model, root, body, label
end

local function playersInArena(b: Boss): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			local flat = Vector3.new(root.Position.X - b.Center.X, 0, root.Position.Z - b.Center.Z).Magnitude
			if flat <= b.Radius + 4 and math.abs(root.Position.Y - b.FloorY) < 40 then
				table.insert(list, p)
			end
		end
	end
	return list
end

local function sendUi(b: Boss)
	local payload = if b.State == "Kampf"
		then { Name = b.Cfg.Name, Hp = math.max(0, b.Hp), Max = b.MaxHp, Phase = b.Phase, Tired = b.Tired }
		else nil
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("Zone") == b.ZoneIndex then
			Remotes.Event("BossUi"):FireClient(p, payload)
		end
	end
end

local function toastArena(b: Boss, text: string, kind: string)
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("Zone") == b.ZoneIndex then
			Remotes.Event("Toast"):FireClient(p, text, kind)
		end
	end
end

-- Warten, das durch Verlangsamen länger wird
local function waitScaled(b: Boss, seconds: number)
	local left = seconds
	while left > 0 and b.State == "Kampf" do
		local dt = task.wait(0.05)
		left -= dt * TimeScaleService.GetScale(b.Center)
	end
end

local function warnPart(cf: CFrame, size: Vector3, shape: Enum.PartType?): BasePart
	local p = makePart({
		Name = "Warnung",
		Shape = shape or Enum.PartType.Block,
		Size = size,
		CFrame = cf,
		Color = WARN_COLOR,
		Material = Enum.Material.Neon,
		Transparency = 0.55,
	})
	p.Parent = workspace
	local tween = TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.2 })
	tween:Play()
	return p
end

local function warnCircle(b: Boss, pos: Vector3, radius: number): BasePart
	local cf = CFrame.new(pos.X, b.FloorY + 0.15, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
	return warnPart(cf, Vector3.new(0.3, radius * 2, radius * 2), Enum.PartType.Cylinder)
end

local function warnRect(b: Boss, from: Vector3, dir: Vector3, length: number, width: number): (BasePart, CFrame)
	local mid = from + dir * (length / 2)
	local cf = CFrame.lookAt(Vector3.new(mid.X, b.FloorY + 0.15, mid.Z), Vector3.new(mid.X, b.FloorY + 0.15, mid.Z) + dir)
	return warnPart(cf, Vector3.new(width, 0.3, length)), cf
end

local function hurt(b: Boss, player: Player, amount: number, hitSet: { [Player]: boolean })
	if hitSet[player] then
		return
	end
	hitSet[player] = true
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:TakeDamage(amount)
		Remotes.Event("Bounce"):FireClient(player, 35, Vector3.zero)
	end
end

local function rootOf(p: Player): BasePart?
	local char = p.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function flatDirTo(from: Vector3, to: Vector3): Vector3
	local d = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	if d.Magnitude < 0.1 then
		return Vector3.new(0, 0, 1)
	end
	return d.Unit
end

local function inRect(cf: CFrame, size: Vector3, pos: Vector3): boolean
	local rel = cf:PointToObjectSpace(pos)
	return math.abs(rel.X) <= size.X / 2 + 1 and math.abs(rel.Z) <= size.Z / 2 + 1 and rel.Y < 8
end

local function faceTarget(b: Boss, pos: Vector3)
	local p = b.Root.Position
	b.Root.CFrame = CFrame.lookAt(p, Vector3.new(pos.X, p.Y, pos.Z))
end

local Attacks = {}

Attacks.Stampfen = function(b: Boss, phase: any)
	local radius = math.min(b.Radius * 0.55, b.Cfg.Groesse * 1.6)
	local w = warnCircle(b, b.Center, radius)
	waitScaled(b, phase.Warnzeit)
	w:Destroy()
	if b.State ~= "Kampf" then
		return
	end
	local up = TweenService:Create(b.Root, TweenInfo.new(0.15), { CFrame = b.Root.CFrame - Vector3.new(0, 2, 0) })
	up:Play()
	Remotes.Event("Effect"):FireAllClients("Shock", { Pos = Vector3.new(b.Center.X, b.FloorY, b.Center.Z), Radius = radius })
	local hit = {}
	for _, p in playersInArena(b) do
		local r = rootOf(p)
		if r then
			local flat = Vector3.new(r.Position.X - b.Center.X, 0, r.Position.Z - b.Center.Z).Magnitude
			if flat <= radius and r.Position.Y - b.FloorY < 7 then
				hurt(b, p, b.Cfg.Schaden, hit)
			end
		end
	end
	task.wait(0.2)
	local down = TweenService:Create(b.Root, TweenInfo.new(0.3), { CFrame = b.Root.CFrame + Vector3.new(0, 2, 0) })
	down:Play()
end

Attacks.Zahnradregen = function(b: Boss, phase: any)
	local spots = {}
	for _, p in playersInArena(b) do
		local r = rootOf(p)
		if r then
			table.insert(spots, r.Position)
		end
	end
	local extra = b.Phase + 1
	for _ = 1, extra do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(8, b.Radius * 0.8)
		table.insert(spots, b.Center + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d))
	end
	local radius = 7
	local warns = {}
	for _, s in spots do
		table.insert(warns, warnCircle(b, s, radius))
	end
	Remotes.Event("Effect"):FireAllClients("GearRain", { Spots = spots, FloorY = b.FloorY, Time = phase.Warnzeit })
	waitScaled(b, phase.Warnzeit)
	for _, w in warns do
		w:Destroy()
	end
	if b.State ~= "Kampf" then
		return
	end
	local hit = {}
	for _, p in playersInArena(b) do
		local r = rootOf(p)
		if r then
			for _, s in spots do
				if Vector3.new(r.Position.X - s.X, 0, r.Position.Z - s.Z).Magnitude <= radius then
					hurt(b, p, b.Cfg.Schaden, hit)
				end
			end
		end
	end
end

Attacks.Schockwelle = function(b: Boss, phase: any)
	-- Warnung: Ring aus Markierungen + Hinweis "SPRING!"
	local warns = {}
	for i = 1, 20 do
		local a = i / 20 * math.pi * 2
		local pos = b.Center + Vector3.new(math.cos(a) * 9, 0, math.sin(a) * 9)
		table.insert(warns, warnCircle(b, pos, 1.6))
	end
	b.TiredLabel.Text = "⬆️ SPRING! ⬆️"
	waitScaled(b, phase.Warnzeit)
	for _, w in warns do
		w:Destroy()
	end
	if b.State ~= "Kampf" then
		return
	end
	local speed = 26
	local maxR = b.Radius + 2
	Remotes.Event("Effect"):FireAllClients("Wave", { Pos = Vector3.new(b.Center.X, b.FloorY, b.Center.Z), Speed = speed, Max = maxR })
	local hit = {}
	local r = 6
	while r < maxR and b.State == "Kampf" do
		local dt = task.wait(0.05)
		r += speed * dt
		for _, p in playersInArena(b) do
			local root = rootOf(p)
			if root then
				local flat = Vector3.new(root.Position.X - b.Center.X, 0, root.Position.Z - b.Center.Z).Magnitude
				-- wer springt (hoch genug), wird nicht getroffen
				if math.abs(flat - r) < 2.2 and root.Position.Y - b.FloorY < 4.2 then
					hurt(b, p, b.Cfg.Schaden, hit)
				end
			end
		end
	end
	if not b.Tired then
		b.TiredLabel.Text = ""
	end
end

Attacks.Laserlinie = function(b: Boss, phase: any)
	local targets = playersInArena(b)
	if #targets == 0 then
		return
	end
	local target = rootOf(targets[rng:NextInteger(1, #targets)])
	if not target then
		return
	end
	local dir = flatDirTo(b.Center, target.Position)
	faceTarget(b, target.Position)
	local length = b.Radius * 2
	local width = 8
	local from = b.Center - dir * (b.Radius * 0.1)
	local w, cf = warnRect(b, from, dir, length, width)
	waitScaled(b, phase.Warnzeit)
	w:Destroy()
	if b.State ~= "Kampf" then
		return
	end
	Remotes.Event("Effect"):FireAllClients("Beam", { From = b.Root.Position, To = Vector3.new(from.X, b.FloorY + 2, from.Z) + dir * length, Width = width })
	local hit = {}
	for _, p in playersInArena(b) do
		local r = rootOf(p)
		if r and inRect(cf, Vector3.new(width, 0, length), r.Position) then
			hurt(b, p, b.Cfg.Schaden, hit)
		end
	end
end

Attacks.Ansturm = function(b: Boss, phase: any)
	local targets = playersInArena(b)
	if #targets == 0 then
		return
	end
	local target = rootOf(targets[rng:NextInteger(1, #targets)])
	if not target then
		return
	end
	local dir = flatDirTo(b.Center, target.Position)
	faceTarget(b, target.Position)
	local length = b.Radius * 0.9
	local width = b.Cfg.Groesse * 0.8
	local w = warnRect(b, b.Center, dir, length, width)
	waitScaled(b, phase.Warnzeit)
	w:Destroy()
	if b.State ~= "Kampf" then
		return
	end
	local startCf = b.Root.CFrame
	local endCf = startCf + dir * length
	local tween = TweenService:Create(b.Root, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = endCf })
	tween:Play()
	local hit = {}
	local t0 = os.clock()
	while os.clock() - t0 < 0.75 do
		task.wait(0.05)
		for _, p in playersInArena(b) do
			local r = rootOf(p)
			if r and (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(b.Root.Position.X, 0, b.Root.Position.Z)).Magnitude < width * 0.75 then
				hurt(b, p, b.Cfg.Schaden, hit)
			end
		end
	end
	task.wait(0.4)
	local back = TweenService:Create(b.Root, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { CFrame = startCf })
	back:Play()
	back.Completed:Wait()
end

local function setTired(b: Boss, on: boolean)
	b.Tired = on
	b.Body.Material = if on then Enum.Material.Neon else Enum.Material.Metal
	b.TiredLabel.Text = if on then "💤 MÜDE – jetzt angreifen!" else ""
	sendUi(b)
end

local function phaseFor(b: Boss): number
	local ratio = b.Hp / b.MaxHp
	if ratio > 2 / 3 then
		return 1
	elseif ratio > 1 / 3 then
		return 2
	end
	return 3
end

local function fightLoop(b: Boss, id: number)
	local count = 0
	local idx = 0
	while b.State == "Kampf" and b.FightId == id do
		local phase = b.Cfg.Phasen[b.Phase] or b.Cfg.Phasen[1]
		idx += 1
		local name = phase.Angriffe[((idx - 1) % #phase.Angriffe) + 1]
		local attack = Attacks[name]
		if attack then
			local ok, err = pcall(attack, b, phase)
			if not ok then
				warn("[BossService] Angriff fehlgeschlagen:", name, err)
			end
		end
		count += 1
		if b.State ~= "Kampf" then
			break
		end
		if count % b.Cfg.AngriffeBisMuede == 0 then
			setTired(b, true)
			waitScaled(b, b.Cfg.MuedeZeit)
			setTired(b, false)
		else
			waitScaled(b, phase.Pause)
		end
	end
end

local function resetBoss(b: Boss)
	b.State = "Bereit"
	b.Hp = b.MaxHp
	b.Phase = 1
	b.Tired = false
	b.Participants = {}
	b.Root.CFrame = CFrame.new(b.Center + Vector3.new(0, b.Cfg.Groesse * 0.55 + 1, 0))
	b.TiredLabel.Text = ""
	b.Body.Color = b.Cfg.Farbe
	b.Body.Material = Enum.Material.Metal
	b.Model.Parent = b.Folder
	sendUi(b)
end

local function defeat(b: Boss)
	b.State = "Besiegt"
	b.Tired = false
	sendUi(b)
	Remotes.Event("Effect"):FireAllClients("GearBurst", { Pos = b.Root.Position, Size = b.Cfg.Groesse / 2.5 })
	Remotes.Event("Effect"):FireAllClients("BossWin", { Pos = b.Center, Radius = 55 })
	b.Model.Parent = nil
	local zone = Zones[b.ZoneIndex]
	toastArena(b, ("🎉 %s ist in Zahnräder zerfallen! Super gemacht!"):format(b.Cfg.Name), "boss")
	for _, p in playersInArena(b) do
		b.Participants[p] = true
	end
	for p, _ in b.Participants do
		local data = DataService.Get(p)
		if p.Parent and data then
			local first = not data.BossesDefeated[zone.Id]
			DataService.Update(p, function(d)
				d.BossesDefeated[zone.Id] = true
			end)
			LevelService.Grant(p, b.Cfg.Belohnung, if first then 2 else 1)
			LevelService.CheckUnlocks(p)
			QuestEvents.Fire(p, "Boss", { Zone = b.ZoneIndex })
			Remotes.Event("Effect"):FireClient(p, "Finish", { Pos = b.Center })
		end
	end
	task.delay(45, function()
		resetBoss(b)
	end)
end

function BossService.Damage(b: Boss, amount: number, player: Player?)
	if b.State ~= "Kampf" then
		return
	end
	local dmg = if b.Tired then amount * 2 else amount
	b.Hp -= dmg
	if player then
		b.Participants[player] = true
	end
	Remotes.Event("Effect"):FireAllClients("Hit", { Pos = b.Root.Position + Vector3.new(0, b.Cfg.Groesse * 0.3, 0), Amount = math.floor(dmg), Big = true })
	local newPhase = phaseFor(b)
	if newPhase > b.Phase then
		b.Phase = newPhase
		b.Body.Color = b.Cfg.Farbe:Lerp(Color3.fromRGB(255, 120, 120), (newPhase - 1) * 0.25)
		toastArena(b, ("⚠️ %s – Phase %d!"):format(b.Cfg.Name, newPhase), "boss")
	end
	if b.Hp <= 0 then
		defeat(b)
	else
		sendUi(b)
	end
end

function BossService.FindTarget(origin: Vector3, dir: Vector3, range: number): (any, number?)
	for _, b in bosses do
		if b.State == "Kampf" then
			local v = b.Root.Position - origin
			local along = v:Dot(dir)
			local r = b.Cfg.Groesse * 0.6
			if along > 0 and along < range + r and (v - dir * along).Magnitude <= r + 3 then
				return b, along
			end
		end
	end
	return nil, nil
end

local function setupArena(arena: Instance)
	if not arena:IsA("BasePart") then
		return
	end
	local bossId = arena:GetAttribute("BossId") :: string?
	local cfg = bossId and Bosses[bossId]
	if not cfg then
		warn("[BossService] Unbekannter Boss:", bossId)
		return
	end
	local floorY = (arena:GetAttribute("FloorY") :: number?) or arena.Position.Y
	local center = Vector3.new(arena.Position.X, floorY, arena.Position.Z)
	local model, root, body, label = buildBoss(cfg, center + Vector3.new(0, cfg.Groesse * 0.55 + 1, 0))
	local folder = arena.Parent or workspace
	model.Parent = folder
	local b: Boss = {
		Cfg = cfg,
		Id = bossId :: string,
		ZoneIndex = (arena:GetAttribute("ZoneIndex") :: number?) or 1,
		Center = center,
		FloorY = floorY,
		Radius = (arena:GetAttribute("Radius") :: number?) or 50,
		Model = model,
		Root = root,
		Body = body,
		TiredLabel = label,
		Folder = folder,
		Hp = cfg.Leben,
		MaxHp = cfg.Leben,
		State = "Bereit",
		Phase = 1,
		Tired = false,
		Participants = {},
		EmptyTime = 0,
		FirstDefeat = {},
		FightId = 0,
	}
	table.insert(bosses, b)
end

function BossService.Init() end

function BossService.Start()
	for _, a in CollectionService:GetTagged(Tags.BossArena) do
		setupArena(a)
	end
	CollectionService:GetInstanceAddedSignal(Tags.BossArena):Connect(setupArena)

	-- Kampfbeginn / Zurücksetzen / Sprung-Angriff
	task.spawn(function()
		while true do
			local dt = task.wait(0.1)
			for _, b in bosses do
				local inside = playersInArena(b)
				if b.State == "Bereit" and #inside > 0 then
					b.State = "Kampf"
					b.MaxHp = math.floor(b.Cfg.Leben * (1 + 0.5 * (#inside - 1)))
					b.Hp = b.MaxHp
					b.Phase = 1
					b.EmptyTime = 0
					toastArena(b, ("👑 Boss-Kampf: %s! Achte auf die Warnflächen!"):format(b.Cfg.Name), "boss")
					sendUi(b)
					b.FightId += 1
					task.spawn(fightLoop, b, b.FightId)
				elseif b.State == "Kampf" then
					if #inside == 0 then
						b.EmptyTime += dt
						if b.EmptyTime > 8 then
							resetBoss(b)
						end
					else
						b.EmptyTime = 0
						-- Sprung-Angriff von oben
						local top = b.Root.Position.Y + b.Cfg.Groesse * 0.5
						for _, p in inside do
							local r = rootOf(p)
							if r then
								local flat = Vector3.new(r.Position.X - b.Root.Position.X, 0, r.Position.Z - b.Root.Position.Z).Magnitude
								local above = r.Position.Y - top
								if flat < b.Cfg.Groesse * 0.45 and above > -1 and above < 5 and r.AssemblyLinearVelocity.Y < -1 then
									local stats = DataService.GetStats(p)
									BossService.Damage(b, (stats and stats.StompDamage or 25) * 1.5, p)
									Remotes.Event("Bounce"):FireClient(p, 70, Vector3.zero)
								end
							end
						end
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(p)
		for _, b in bosses do
			b.Participants[p] = nil
		end
	end)
end

return BossService
