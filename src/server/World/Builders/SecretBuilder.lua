--!strict
--[[
	SecretBuilder: versteckte goldene Zahnräder (Konfig: Secrets.lua).
	Jedes Zahnrad hat den Tag "Secret" und das Attribut SecretId ("Hub_1", "Z3_2" …).
	Der SecretService gibt die Belohnung, der Client blendet gefundene Zahnräder aus.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Secrets = require(Config:WaitForChild("Secrets")) :: any
local Parts = require(script.Parent:WaitForChild("Parts"))

local SecretBuilder = {}

local GOLD = Color3.fromRGB(255, 205, 70)

local function build(parent: Instance, pos: Vector3, id: string, zoneIndex: number)
	-- Zahnrad steht hochkant und dreht sich langsam (Client-Animation über Tag "Obstacle" / Kind "Spin")
	local cf = CFrame.new(pos + Vector3.new(0, 1.4, 0)) * CFrame.Angles(math.rad(90), 0, 0)
	local m = Parts.Obstacle(parent, "Geheimnis_" .. id, "Spin", cf, { Axis = Vector3.yAxis, Speed = 0.6, Phase = 0 })
	local list = Parts.Gear(m, cf, 1.1, 0.35, 8, GOLD, false)
	for _, p in list do
		p.CanQuery = false
		p.CastShadow = false
	end
	-- unsichtbare Berührungs-Kugel (größer als das Zahnrad, damit man es leicht trifft)
	local touch = Parts.Part({
		Name = "Geheimnis",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(4, 4, 4),
		CFrame = CFrame.new(pos + Vector3.new(0, 1.4, 0)),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Tags = { "Secret" },
		Attrs = { SecretId = id, ZoneIndex = zoneIndex },
		Parent = m,
	})
	local light = Instance.new("PointLight")
	light.Color = GOLD
	light.Range = 6
	light.Brightness = 0.8
	light.Shadows = false
	light.Parent = touch
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Rate = 1.5
	sparkle.Lifetime = NumberRange.new(0.8, 1.4)
	sparkle.Speed = NumberRange.new(0.3, 0.8)
	sparkle.Size = NumberSequence.new(0.18, 0)
	sparkle.Color = ColorSequence.new(GOLD)
	sparkle.LightEmission = 1
	sparkle.Parent = touch
end

function SecretBuilder.Count(zoneCount: number): number
	return #Secrets.Hub + #Secrets.Zone * zoneCount
end

function SecretBuilder.BuildHub(parent: Instance, center: Vector3)
	local folder = Parts.Folder("Geheimnisse", parent)
	for i, s in Secrets.Hub do
		build(folder, center + s.Pos, "Hub_" .. i, 0)
	end
end

function SecretBuilder.BuildZone(parent: Instance, index: number, origin: Vector3)
	local folder = Parts.Folder("Geheimnisse", parent)
	for i, s in Secrets.Zone do
		local pos = s.Pos
		-- jede zweite Zone gespiegelt, damit das Versteck nicht überall gleich ist
		if s.Spiegeln and index % 2 == 0 then
			pos = Vector3.new(-pos.X, pos.Y, pos.Z)
		end
		build(folder, origin + pos, ("Z%d_%d"):format(index, i), index)
	end
end

return SecretBuilder
