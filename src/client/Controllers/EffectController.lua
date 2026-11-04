--!strict
-- EffectController: alle Effekte vom Server (Partikel, Zahlen, Zahnrad-Explosionen, Zeit-Blasen …)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local DataController = require(script.Parent:WaitForChild("DataController"))
local SoundController = require(script.Parent:WaitForChild("SoundController"))
local UI = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("UIController"))

local EffectController = {}

local player = Players.LocalPlayer
local folder: Folder
local rng = Random.new()

local GEAR_COLORS = { Color3.fromRGB(215, 170, 80), Color3.fromRGB(200, 120, 75), Color3.fromRGB(190, 190, 200) }
local CONFETTI = {
	Color3.fromRGB(255, 120, 150),
	Color3.fromRGB(255, 210, 90),
	Color3.fromRGB(120, 220, 255),
	Color3.fromRGB(150, 240, 150),
	Color3.fromRGB(200, 150, 255),
}

local function lowGraphics(): boolean
	local d = DataController.Data
	return d ~= nil and d.Settings.Graphics == "Niedrig"
end

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = folder
	return p
end

local function fadeAndDestroy(p: BasePart, t: number, goal: { [string]: any }?)
	local props = goal or {}
	props.Transparency = 1
	TweenService:Create(p, TweenInfo.new(t), props):Play()
	Debris:AddItem(p, t + 0.1)
end

-- schwebender Text (z.B. "+12 ⚡")
local function floatText(pos: Vector3, text: string, color: Color3, big: boolean?)
	local anchor = part({ Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1, CFrame = CFrame.new(pos + Vector3.new(rng:NextNumber(-1, 1), 2, rng:NextNumber(-1, 1))) })
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(if big then 160 else 110, if big then 60 else 40)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui
	gui.Parent = anchor
	TweenService:Create(anchor, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = anchor.CFrame + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1.1)
end

local function burst(pos: Vector3, count: number, colors: { Color3 }, size: number, speed: number, gear: boolean)
	if lowGraphics() then
		count = math.ceil(count / 2)
	end
	for _ = 1, count do
		local s = size * rng:NextNumber(0.6, 1.2)
		local p = Instance.new("Part")
		p.Shape = if gear then Enum.PartType.Cylinder else Enum.PartType.Block
		p.Size = if gear then Vector3.new(s * 0.3, s, s) else Vector3.new(s * 0.6, s * 0.1, s * 0.6)
		p.Color = colors[rng:NextInteger(1, #colors)]
		p.Material = if gear then Enum.Material.Metal else Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.CFrame = CFrame.new(pos) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0)
		p.Parent = folder
		p.AssemblyLinearVelocity = Vector3.new(rng:NextNumber(-1, 1) * speed, rng:NextNumber(0.6, 1.4) * speed, rng:NextNumber(-1, 1) * speed)
		p.AssemblyAngularVelocity = Vector3.new(rng:NextNumber(-10, 10), rng:NextNumber(-10, 10), rng:NextNumber(-10, 10))
		task.delay(1.4, function()
			if p.Parent then
				p.Anchored = true
				fadeAndDestroy(p, 0.5)
			end
		end)
	end
end

local function ringEffect(center: Vector3, radius: number, color: Color3, duration: number)
	local ring = part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 2, 2),
		CFrame = CFrame.new(center + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.3,
	})
	TweenService:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Quad), { Size = Vector3.new(0.3, radius * 2, radius * 2), Transparency = 1 }):Play()
	Debris:AddItem(ring, duration + 0.1)
end

local function characterOf(userId: number): Model?
	local p = Players:GetPlayerByUserId(userId)
	return p and p.Character
end

local Handlers: { [string]: (any) -> () } = {}

Handlers.Click = function(d)
	floatText(d.Pos, "+" .. Util.FormatNumber(d.Amount) .. " ⚡", Color3.fromRGB(140, 230, 255))
	SoundController.Play("Klick", rng:NextNumber(0.9, 1.25))
	burst(d.Pos, 4, { Color3.fromRGB(140, 230, 255), Color3.fromRGB(255, 255, 255) }, 0.7, 12, false)
end

Handlers.Orb = function(_d)
	SoundController.Play("Sammeln", rng:NextNumber(1.1, 1.4))
end

Handlers.Gain = function(d)
	UI.FloatHud(d.Text)
end

Handlers.GearBurst = function(d)
	burst(d.Pos, math.floor(10 + (d.Size or 1) * 4), GEAR_COLORS, math.clamp(d.Size or 1, 0.8, 4), 28, true)
	SoundController.Play("Zahnraeder")
end

Handlers.LevelUp = function(d)
	local char = characterOf(d.UserId)
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		burst(root.Position, 20, CONFETTI, 0.8, 22, false)
		ringEffect(root.Position - Vector3.new(0, 3, 0), 12, Color3.fromRGB(255, 220, 100), 0.8)
	end
	if d.UserId == player.UserId then
		SoundController.Play("LevelUp", 1.1)
	end
end

Handlers.Slow = function(d)
	local sphere = part({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2, 2, 2),
		CFrame = CFrame.new(d.Pos),
		Color = Color3.fromRGB(140, 200, 255),
		Material = Enum.Material.ForceField,
		Transparency = 0.2,
	})
	TweenService:Create(sphere, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Size = Vector3.new(d.Radius * 2, d.Radius * 2, d.Radius * 2) }):Play()
	task.delay(math.max(0.5, d.Duration - 0.5), function()
		fadeAndDestroy(sphere, 0.5)
	end)
	SoundController.Play("Faehigkeit", 0.7)
end

Handlers.Rewind = function(d)
	local mid = (d.From + d.To) / 2
	local len = (d.To - d.From).Magnitude
	if len > 0.5 then
		local beam = part({
			Size = Vector3.new(0.5, 0.5, len),
			CFrame = CFrame.lookAt(mid, d.To),
			Color = Color3.fromRGB(190, 150, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.2,
		})
		fadeAndDestroy(beam, 0.7)
	end
	burst(d.To, 10, { Color3.fromRGB(190, 150, 255), Color3.fromRGB(255, 255, 255) }, 0.6, 10, false)
	SoundController.Play("Faehigkeit", 1.4)
end

Handlers.Boost = function(d)
	if d.UserId == player.UserId then
		SoundController.Play("Faehigkeit", 1.6)
	end
end

Handlers.Throw = function(d)
	local disc = part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 2.4, 2.4),
		CFrame = CFrame.new(d.From),
		Color = Color3.fromRGB(120, 230, 255),
		Material = Enum.Material.Neon,
	})
	local t0 = os.clock()
	local dur = math.max(0.05, d.Time)
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = math.clamp((os.clock() - t0) / dur, 0, 1)
		local pos = d.From:Lerp(d.To, a)
		disc.CFrame = CFrame.new(pos) * CFrame.Angles(0, os.clock() * 25, math.rad(90))
		if a >= 1 then
			conn:Disconnect()
			burst(pos, 6, { Color3.fromRGB(120, 230, 255) }, 0.6, 12, false)
			disc:Destroy()
		end
	end)
	SoundController.Play("Faehigkeit", 1.9)
end

Handlers.Platform = function(d)
	burst(d.Pos, 8, GEAR_COLORS, 0.7, 10, true)
end

Handlers.Hit = function(d)
	floatText(d.Pos, "-" .. tostring(d.Amount), if d.Big then Color3.fromRGB(255, 220, 90) else Color3.fromRGB(255, 160, 90), d.Big)
	SoundController.Play("Treffer", rng:NextNumber(1, 1.3))
end

Handlers.Shock = function(d)
	ringEffect(d.Pos, d.Radius, Color3.fromRGB(255, 150, 80), 0.45)
end

Handlers.GearRain = function(d)
	for _, spot in d.Spots do
		local gear = part({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.2, 6, 6),
			CFrame = CFrame.new(spot.X, d.FloorY + 45, spot.Z) * CFrame.Angles(0, 0, math.rad(90)),
			Color = GEAR_COLORS[rng:NextInteger(1, #GEAR_COLORS)],
			Material = Enum.Material.Metal,
		})
		local tween = TweenService:Create(gear, TweenInfo.new(d.Time, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			CFrame = CFrame.new(spot.X, d.FloorY + 1, spot.Z) * CFrame.Angles(0, 0, math.rad(90)),
		})
		tween:Play()
		tween.Completed:Connect(function()
			burst(gear.Position, 6, GEAR_COLORS, 1, 16, true)
			gear:Destroy()
		end)
	end
	SoundController.Play("BossWarnung")
end

Handlers.Wave = function(d)
	local count = if lowGraphics() then 16 else 32
	local pieces = {}
	for i = 1, count do
		pieces[i] = part({
			Size = Vector3.new(2.5, 2.2, 1),
			Color = Color3.fromRGB(255, 130, 80),
			Material = Enum.Material.Neon,
			Transparency = 0.15,
		})
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local r = 6 + (os.clock() - t0) * d.Speed
		for i, p in pieces do
			local a = i / count * math.pi * 2
			local pos = d.Pos + Vector3.new(math.cos(a) * r, 1.1, math.sin(a) * r)
			p.CFrame = CFrame.lookAt(pos, d.Pos + Vector3.new(0, 1.1, 0))
		end
		if r >= d.Max then
			conn:Disconnect()
			for _, p in pieces do
				p:Destroy()
			end
		end
	end)
end

Handlers.Beam = function(d)
	local len = (d.To - d.From).Magnitude
	local beam = part({
		Size = Vector3.new(d.Width * 0.6, 1.5, len),
		CFrame = CFrame.lookAt((d.From + d.To) / 2, d.To),
		Color = Color3.fromRGB(255, 90, 140),
		Material = Enum.Material.Neon,
		Transparency = 0.1,
	})
	fadeAndDestroy(beam, 0.5)
end

Handlers.Finish = function(d)
	burst(d.Pos + Vector3.new(0, 2, 0), 30, CONFETTI, 0.9, 30, false)
end

Handlers.Portal = function(_d)
	SoundController.Play("Portal")
	UI.Flash()
end

function EffectController.Init()
	folder = Instance.new("Folder")
	folder.Name = "LokaleEffekte"
	folder.Parent = workspace
	-- auch für lokale Effekte (z.B. Puff beim Checkpoint)
	UI.SetEffectHandler(function(kind: string, pos: Vector3)
		if kind == "Puff" then
			burst(pos, 12, { Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 230, 255) }, 1, 10, false)
		end
	end)
end

function EffectController.Start()
	Remotes.Event("Effect").OnClientEvent:Connect(function(kind: string, data: any)
		local h = Handlers[kind]
		if h then
			local ok, err = pcall(h, data)
			if not ok then
				warn("[Effekt]", kind, err)
			end
		end
	end)
end

return EffectController
