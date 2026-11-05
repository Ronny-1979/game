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

function AmbienceController.Start()
	player:GetAttributeChangedSignal("Zone"):Connect(apply)
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
