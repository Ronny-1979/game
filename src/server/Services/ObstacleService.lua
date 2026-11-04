--!strict
--[[
	ObstacleService: Server-Seite der Hindernisse.
	Die Bewegung macht der Client (ObstacleController). Hier werden nur Förderbänder eingestellt
	(Geschwindigkeit der Oberfläche) und bei Zeitänderung angepasst.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tags = require(Shared:WaitForChild("Tags"))
local ObstacleMath = require(Shared:WaitForChild("ObstacleMath"))

local ObstacleService = {}

local function setupConveyor(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local function apply()
		local speed = (part:GetAttribute("ConveyorSpeed") :: number?) or 10
		local holder = part:FindFirstAncestorWhichIsA("Model")
		local scale = if holder then ObstacleMath.Scale(holder) else 1
		part.AssemblyLinearVelocity = part.CFrame.LookVector * speed * scale
	end
	apply()
	local holder = part:FindFirstAncestorWhichIsA("Model")
	if holder then
		holder:GetAttributeChangedSignal("VTScale"):Connect(apply)
	end
end

function ObstacleService.Init() end

function ObstacleService.Start()
	for _, p in CollectionService:GetTagged(Tags.Conveyor) do
		setupConveyor(p)
	end
	CollectionService:GetInstanceAddedSignal(Tags.Conveyor):Connect(setupConveyor)
end

return ObstacleService
