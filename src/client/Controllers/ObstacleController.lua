--!strict
--[[
	ObstacleController: animiert alle Hindernisse lokal.
	Die Pose kommt aus ObstacleMath + Serverzeit → alle Spieler sehen dasselbe, ohne Ruckeln.
	Steht der Spieler auf einem bewegten Teil, wird er mitbewegt (Position + Drehung um Y).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tags = require(Shared:WaitForChild("Tags"))
local ObstacleMath = require(Shared:WaitForChild("ObstacleMath"))
local DataController = require(script.Parent:WaitForChild("DataController"))

local ObstacleController = {}

type Entry = {
	Model: Model,
	Kind: string,
	Base: CFrame,
	Pos: Vector3,
	Attrs: { [string]: any },
	Parts: { BasePart },
	Orig: { [BasePart]: number },
	Collide: { [BasePart]: boolean },
	Last: CFrame,
	On: boolean?,
	Warn: boolean?,
	Scale: number?,
}

local entries: { [Model]: Entry } = {}
local list: { Entry } = {}
local player = Players.LocalPlayer

local ATTRS = { "Axis", "Speed", "Phase", "Period", "Amp", "Offset", "OnTime" }

local function rebuildList()
	table.clear(list)
	for _, e in entries do
		table.insert(list, e)
	end
end

local function setConveyor(e: Entry)
	local scale = ObstacleMath.Scale(e.Model)
	e.Scale = scale
	for _, p in e.Parts do
		local speed = p:GetAttribute("ConveyorSpeed")
		if type(speed) == "number" then
			p.AssemblyLinearVelocity = p.CFrame.LookVector * speed * scale
		end
	end
end

local function register(inst: Instance)
	if not inst:IsA("Model") or entries[inst] then
		return
	end
	local base = inst:GetAttribute("BasePivot")
	local baseCf: CFrame = if typeof(base) == "CFrame" then base else inst:GetPivot()
	local attrs = {}
	for _, name in ATTRS do
		attrs[name] = inst:GetAttribute(name)
	end
	local parts = {}
	local orig = {}
	local collide = {}
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			orig[d] = d.Transparency
			collide[d] = d.CanCollide
		end
	end
	local e: Entry = {
		Model = inst,
		Kind = (inst:GetAttribute("Kind") :: string?) or "Spin",
		Base = baseCf,
		Pos = baseCf.Position,
		Attrs = attrs,
		Parts = parts,
		Orig = orig,
		Collide = collide,
		Last = baseCf,
	}
	entries[inst] = e
	if e.Kind == "Conveyor" then
		setConveyor(e)
	end
	rebuildList()
end

local function unregister(inst: Instance)
	if inst:IsA("Model") and entries[inst] then
		entries[inst] = nil
		rebuildList()
	end
end

-- Ist ein Gefahren-Teil gerade gefährlich? (Laser im AUS-Takt sind harmlos)
function ObstacleController.IsHazardActive(part: BasePart): boolean
	if not part:GetAttribute("Timed") then
		return true
	end
	local model = part:FindFirstAncestorWhichIsA("Model")
	local e = model and entries[model]
	if not e then
		return true
	end
	return e.On ~= false
end

local function findEntry(part: Instance): Entry?
	local node: Instance? = part.Parent
	while node and node ~= workspace do
		if node:IsA("Model") and entries[node] then
			return entries[node]
		end
		node = node.Parent
	end
	return nil
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function update()
	local now = workspace:GetServerTimeNow()
	local cam = workspace.CurrentCamera
	local camPos = if cam then cam.CFrame.Position else Vector3.zero
	local low = DataController.Data and DataController.Data.Settings.Graphics == "Niedrig"
	local maxDist = if low then 260 else 450

	-- Worauf steht der Spieler?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local carry: Entry? = nil
	if root and char then
		rayParams.FilterDescendantsInstances = { char }
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -4.5, 0), rayParams)
		if hit then
			carry = findEntry(hit.Instance)
		end
	end
	local carryOld = if carry then carry.Last else nil

	for _, e in list do
		if e ~= carry and (e.Pos - camPos).Magnitude > maxDist then
			continue
		end
		local kind = e.Kind
		if kind == "Blink" or kind == "Laser" then
			local vt = ObstacleMath.VirtualTime(e.Model, now)
			local on, warnSoon = ObstacleMath.Blink(e.Attrs, vt)
			-- Warnblinken: schnell flackern kurz vor dem Ausgehen
			local flicker = warnSoon and (math.floor(now * 10) % 2 == 0)
			if on ~= e.On or flicker ~= e.Warn then
				e.On = on
				e.Warn = flicker
				for _, p in e.Parts do
					if kind == "Blink" then
						p.CanCollide = on and e.Collide[p] == true
						p.Transparency = if on then (if flicker then 0.55 else e.Orig[p]) else 0.88
					else
						p.Transparency = if on then 0.05 else 0.85
					end
				end
			end
		elseif kind == "Conveyor" then
			if ObstacleMath.Scale(e.Model) ~= e.Scale then
				setConveyor(e)
			end
		else
			local vt = ObstacleMath.VirtualTime(e.Model, now)
			local cf = ObstacleMath.Pose(kind, e.Base, e.Attrs, vt)
			e.Model:PivotTo(cf)
			e.Last = cf
		end
	end

	-- Mitfahren auf bewegten Teilen
	if carry and carryOld and root then
		local delta = carry.Last * carryOld:Inverse()
		if delta.Position.Magnitude < 5 then
			local newPos = delta * root.Position
			local _, dy, _ = delta:ToEulerAnglesYXZ()
			root.CFrame = CFrame.new(newPos) * CFrame.Angles(0, dy, 0) * root.CFrame.Rotation
		end
	end
end

function ObstacleController.Init() end

function ObstacleController.Start()
	for _, m in CollectionService:GetTagged(Tags.Obstacle) do
		register(m)
	end
	CollectionService:GetInstanceAddedSignal(Tags.Obstacle):Connect(register)
	CollectionService:GetInstanceRemovedSignal(Tags.Obstacle):Connect(unregister)
	RunService.PreSimulation:Connect(update)
end

return ObstacleController
