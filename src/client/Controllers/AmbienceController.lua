--!strict
--[[
	AmbienceController: Stimmung je nach Ort (Konfig: Zones[*].Stimmung und Zones.HubStimmung)
	- Tageszeit, Nebelfarbe und Farbtönung gleiten sanft über
	- schwebende Glühwürmchen-Funken um die Kamera (bei Grafik "Niedrig" aus)
	Alles nur lokal – jeder Spieler sieht die Stimmung seiner eigenen Zone.
]]
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Zones = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Zones")) :: any
local DataController = require(script.Parent:WaitForChild("DataController"))

local AmbienceController = {}

local player = Players.LocalPlayer
local holder: Part
local emitter: ParticleEmitter

local TWEEN = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local function moodFor(zoneIndex: number): any
	local ort = player:GetAttribute("Ort")
	if ort == "Turm" and Zones.TurmStimmung then
		return Zones.TurmStimmung
	elseif ort == "Insel" and Zones.InselStimmung then
		return Zones.InselStimmung
	end
	local zone = Zones[zoneIndex]
	return (zone and zone.Stimmung) or Zones.HubStimmung
end

local function apply()
	local mood = moodFor((player:GetAttribute("Zone") :: number?) or 0)
	if not mood then
		return
	end
	TweenService:Create(Lighting, TWEEN, { ClockTime = mood.Uhrzeit or 14 }):Play()
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		TweenService:Create(atmo, TWEEN, { Color = mood.Nebel, Density = mood.Dichte or 0.28 }):Play()
	end
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if cc and mood.Toenung then
		TweenService:Create(cc, TWEEN, { TintColor = mood.Toenung }):Play()
	end
	if mood.Funken then
		emitter.Color = ColorSequence.new(mood.Funken)
	end
end

function AmbienceController.Init()
	holder = Instance.new("Part")
	holder.Name = "Gluehwuermchen"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(90, 30, 90)
	holder.Parent = workspace
	emitter = Instance.new("ParticleEmitter")
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Rate = 10
	emitter.Lifetime = NumberRange.new(4, 7)
	emitter.Speed = NumberRange.new(0.3, 1.2)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.28), NumberSequenceKeypoint.new(0.8, 0.28), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.1), NumberSequenceKeypoint.new(1, 1) })
	emitter.LightEmission = 1
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 235, 150))
	emitter.Parent = holder
end

-- ===== Saison-Deko (Events.lua: Deko = "Kuerbis" / "Schnee") =====
local snow: ParticleEmitter
local dekoFolder: Folder? = nil

local function pumpkin(parent: Instance, pos: Vector3, rng: Random)
	local s = rng:NextNumber(1.6, 2.6)
	local function p(props: { [string]: any }): Part
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		for k, v in props do
			(part :: any)[k] = v
		end
		part.Parent = parent
		return part
	end
	local body = p({ Shape = Enum.PartType.Ball, Size = Vector3.new(s * 1.3, s, s * 1.3), CFrame = CFrame.new(pos + Vector3.new(0, s / 2, 0)), Color = Color3.fromRGB(255, 140, 40) })
	p({ Size = Vector3.new(0.25, 0.6, 0.25) * s, CFrame = body.CFrame * CFrame.new(0, s * 0.55, 0), Color = Color3.fromRGB(90, 130, 60) })
	for _, side in { -1, 1 } do
		p({ Size = Vector3.new(0.3, 0.3, 0.1) * s, CFrame = body.CFrame * CFrame.new(side * s * 0.25, s * 0.12, -s * 0.62), Color = Color3.fromRGB(255, 230, 120), Material = Enum.Material.Neon })
	end
	p({ Size = Vector3.new(0.6, 0.15, 0.1) * s, CFrame = body.CFrame * CFrame.new(0, -s * 0.15, -s * 0.63), Color = Color3.fromRGB(255, 230, 120), Material = Enum.Material.Neon })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 170, 70)
	light.Range = 10
	light.Brightness = 1.2
	light.Parent = body
end

local function applyEventDeko()
	local deko = ReplicatedStorage:GetAttribute("EventDeko")
	local low = DataController.Data and DataController.Data.Settings.Graphics == "Niedrig"
	snow.Enabled = deko == "Schnee" and not low
	if dekoFolder then
		dekoFolder:Destroy()
		dekoFolder = nil
	end
	if deko == "Kuerbis" then
		local f = Instance.new("Folder")
		f.Name = "SaisonDeko"
		local rng = Random.new(31)
		local hub = Vector3.new(0, 100, 0)
		for i = 1, 16 do
			local a = i / 16 * math.pi * 2 + 0.2
			pumpkin(f, hub + Vector3.new(math.cos(a) * 44, 0, math.sin(a) * 44), rng)
		end
		f.Parent = workspace
		dekoFolder = f
	end
end

function AmbienceController.Start()
	snow = Instance.new("ParticleEmitter")
	snow.Shape = Enum.ParticleEmitterShape.Box
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.Rate = 60
	snow.Lifetime = NumberRange.new(5, 8)
	snow.Speed = NumberRange.new(4, 7)
	snow.SpreadAngle = Vector2.new(20, 20)
	snow.Size = NumberSequence.new(0.22)
	snow.Color = ColorSequence.new(Color3.new(1, 1, 1))
	snow.LightEmission = 0.4
	snow.Enabled = false
	snow.Parent = holder
	ReplicatedStorage:GetAttributeChangedSignal("EventDeko"):Connect(applyEventDeko)
	task.delay(2, applyEventDeko)

	player:GetAttributeChangedSignal("Zone"):Connect(apply)
	player:GetAttributeChangedSignal("Ort"):Connect(apply)
	task.delay(1, apply)
	DataController.Changed:Connect(function(data)
		emitter.Enabled = data.Settings.Graphics ~= "Niedrig"
	end)
	RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		if cam then
			holder.CFrame = CFrame.new(cam.CFrame.Position)
		end
	end)
end

return AmbienceController
