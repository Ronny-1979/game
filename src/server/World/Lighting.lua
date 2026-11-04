--!strict
-- Lighting: warmes Licht, leichter Nebel, sanftes Leuchten (wird vom WorldBuilder gesetzt)
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Assets")) :: any

local LightingSetup = {}

local function replace(className: string, name: string, parent: Instance): Instance
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = parent
	return inst
end

function LightingSetup.Apply()
	Lighting.ClockTime = 15.2
	Lighting.GeographicLatitude = 35
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(120, 105, 95)
	Lighting.OutdoorAmbient = Color3.fromRGB(165, 150, 140)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 225, 190)
	Lighting.ColorShift_Bottom = Color3.fromRGB(120, 100, 140)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.4
	pcall(function()
		Lighting.Technology = Enum.Technology.Future
	end)

	local atmo = replace("Atmosphere", "UhrwerkAtmosphaere", Lighting) :: Atmosphere
	atmo.Density = 0.28
	atmo.Offset = 0.2
	atmo.Color = Color3.fromRGB(255, 232, 205)
	atmo.Decay = Color3.fromRGB(255, 180, 200)
	atmo.Glare = 0.25
	atmo.Haze = 1.4

	local sky = replace("Sky", "UhrwerkHimmel", Lighting) :: Sky
	sky.SunAngularSize = 14
	sky.MoonAngularSize = 9
	sky.StarCount = 1500
	if Assets.Sky.Bk ~= "" then
		sky.SkyboxBk = Assets.Sky.Bk
		sky.SkyboxDn = Assets.Sky.Dn
		sky.SkyboxFt = Assets.Sky.Ft
		sky.SkyboxLf = Assets.Sky.Lf
		sky.SkyboxRt = Assets.Sky.Rt
		sky.SkyboxUp = Assets.Sky.Up
	end

	local bloom = replace("BloomEffect", "UhrwerkLeuchten", Lighting) :: BloomEffect
	bloom.Intensity = 0.55
	bloom.Size = 26
	bloom.Threshold = 1.4

	local cc = replace("ColorCorrectionEffect", "UhrwerkFarben", Lighting) :: ColorCorrectionEffect
	cc.Saturation = 0.15
	cc.Contrast = 0.06
	cc.Brightness = 0.02
	cc.TintColor = Color3.fromRGB(255, 248, 238)

	local rays = replace("SunRaysEffect", "UhrwerkSonnenstrahlen", Lighting) :: SunRaysEffect
	rays.Intensity = 0.06
	rays.Spread = 0.6

	-- Wolken unter den Inseln
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
		clouds.Cover = 0.55
		clouds.Density = 0.45
		clouds.Color = Color3.fromRGB(255, 240, 245)
		clouds.Parent = terrain
	end
end

return LightingSetup
