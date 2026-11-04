--!strict
--[[
	CourseController: Obby-Gefühl auf dem Client
	- Gefahr berührt / abgestürzt → "Puff" und zurück zum Checkpoint (Attribut RespawnPos)
	- Sprungfedern schleudern hoch
	- Rückstoß nach Sprung-Angriff / Treffer
	- Strecken-Ereignisse an die UI weitergeben
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Tags = require(Shared:WaitForChild("Tags"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local ObstacleController = require(script.Parent:WaitForChild("ObstacleController"))
local SoundController = require(script.Parent:WaitForChild("SoundController"))
local UI = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("UIController"))

local CourseController = {}

local player = Players.LocalPlayer
local probe: Part
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Exclude
local lastReset = 0
local lastPad = 0

local function getRoot(): (BasePart?, Humanoid?)
	local char = player.Character
	if not char then
		return nil, nil
	end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then
		return nil, nil
	end
	return root, hum
end

function CourseController.ResetToCheckpoint()
	local root = getRoot()
	local pos = player:GetAttribute("RespawnPos")
	if not root or typeof(pos) ~= "Vector3" then
		return
	end
	local now = os.clock()
	if now - lastReset < 0.6 then
		return
	end
	lastReset = now
	UI.Effect("Puff", root.Position)
	SoundController.Play("Puff")
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) * root.CFrame.Rotation
end

local function step()
	local root, hum = getRoot()
	if not root or not hum then
		return
	end
	-- Absturz
	local pos = player:GetAttribute("RespawnPos")
	if typeof(pos) == "Vector3" and root.Position.Y < pos.Y - Settings.Course.FallDistance then
		CourseController.ResetToCheckpoint()
		return
	end
	-- Gefahren und Sprungfedern
	probe.CFrame = root.CFrame * CFrame.new(0, -0.6, 0)
	local hits = workspace:GetPartsInPart(probe, overlap)
	for _, part in hits do
		if CollectionService:HasTag(part, Tags.Hazard) then
			if ObstacleController.IsHazardActive(part) then
				CourseController.ResetToCheckpoint()
				return
			end
		elseif CollectionService:HasTag(part, Tags.JumpPad) then
			local now = os.clock()
			if now - lastPad > 0.4 then
				lastPad = now
				local dir = part:GetAttribute("Dir")
				local d: Vector3 = if typeof(dir) == "Vector3" then dir else Vector3.zAxis
				local up = (part:GetAttribute("Up") :: number?) or 80
				local fwd = (part:GetAttribute("Forward") :: number?) or 20
				root.AssemblyLinearVelocity = d * fwd + Vector3.new(0, up, 0)
				SoundController.Play("Sprungpad")
			end
		end
	end
end

function CourseController.Init()
	probe = Instance.new("Part")
	probe.Name = "GefahrenSonde"
	probe.Size = Vector3.new(2.4, 5.4, 1.6)
	probe.Anchored = true
	probe.CanCollide = false
	probe.CanQuery = false
	probe.CanTouch = false
	probe.Transparency = 1
	probe.Parent = workspace
end

function CourseController.Start()
	local function onChar(char: Model)
		overlap.FilterDescendantsInstances = { char, probe }
	end
	player.CharacterAdded:Connect(onChar)
	if player.Character then
		onChar(player.Character)
	end
	RunService.Heartbeat:Connect(step)

	Remotes.Event("Bounce").OnClientEvent:Connect(function(power: number, horizontal: Vector3?)
		local root = getRoot()
		if root and type(power) == "number" then
			local h = if typeof(horizontal) == "Vector3" then horizontal else Vector3.zero
			root.AssemblyLinearVelocity = Vector3.new(h.X, power, h.Z)
			SoundController.Play("Treffer")
		end
	end)

	Remotes.Event("CourseEvent").OnClientEvent:Connect(function(kind: string, data: any)
		if kind == "Start" then
			UI.Toast(("🏁 %s – los geht's!"):format(data.Name or ""), "info")
		elseif kind == "Checkpoint" then
			SoundController.Play("Checkpoint", 1.2)
			UI.Toast(("🚩 Checkpoint %d/%d"):format(data.Index, data.Count), "gut")
		elseif kind == "Ziel" then
			SoundController.Play("Ziel")
			UI.ShowCourseResult(data)
		end
	end)
end

return CourseController
