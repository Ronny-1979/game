--!strict
--[[
	SecretController: blendet bereits gefundene Geheimnis-Zahnräder lokal aus
	(jeder Spieler sieht nur die, die er noch nicht gefunden hat).
]]
local CollectionService = game:GetService("CollectionService")

local DataController = require(script.Parent:WaitForChild("DataController"))

local SecretController = {}

local function setVisible(touch: Instance, visible: boolean)
	local model = touch.Parent
	if not model then
		return
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Geheimnis" then
			d.LocalTransparencyModifier = if visible then 0 else 1
		elseif d:IsA("PointLight") or d:IsA("ParticleEmitter") then
			d.Enabled = visible
		end
	end
end

local function refresh()
	local data = DataController.Data
	if not data then
		return
	end
	for _, touch in CollectionService:GetTagged("Secret") do
		local id = touch:GetAttribute("SecretId")
		setVisible(touch, not (data.Secrets and data.Secrets[id]))
	end
end

function SecretController.Init() end

function SecretController.Start()
	DataController.Changed:Connect(refresh)
	CollectionService:GetInstanceAddedSignal("Secret"):Connect(function()
		task.defer(refresh)
	end)
	refresh()
end

return SecretController
