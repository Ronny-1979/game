--!strict
--[[
	QuestController: zeigt den Weg zur aktuellen Aufgabe.
	- goldener Leuchtstrahl vom Spieler zum Ziel
	- hüpfender Pfeil ⬇ über dem Ziel mit Entfernung
	Ist das Ziel in einer anderen Zone, zeigt er zuerst zum passenden Teleporter oder Portal.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Quests = require(Config:WaitForChild("Quests")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local DataController = require(script.Parent:WaitForChild("DataController"))

local QuestController = {}
QuestController.Enabled = true
QuestController.Distance = nil :: number?
QuestController.Hint = nil :: string?

local player = Players.LocalPlayer
local folder: Folder
local a0: Attachment? = nil
local a1: Attachment
local beam: Beam
local marker: BillboardGui
local markerLabel: TextLabel
local target: BasePart? = nil

function QuestController.Current(): (any, number)
	local data = DataController.Data
	if not data or not data.Quest then
		return nil, 0
	end
	return Quests.Liste[data.Quest.Index], data.Quest.Index
end

local function attrsMatch(inst: Instance, attrs: { [string]: any }?): boolean
	if not attrs then
		return true
	end
	for k, v in attrs do
		if inst:GetAttribute(k) ~= v then
			return false
		end
	end
	return true
end

local function nearest(tag: string, attrs: { [string]: any }?, from: Vector3): BasePart?
	local best, bestDist = nil, math.huge
	for _, inst in CollectionService:GetTagged(tag) do
		if inst:IsA("BasePart") and attrsMatch(inst, attrs) then
			local d = (inst.Position - from).Magnitude
			if d < bestDist then
				best, bestDist = inst, d
			end
		end
	end
	return best
end

-- Welches Teil ist gerade das Ziel? (+ Hinweistext, falls erst gereist werden muss)
local function resolve(from: Vector3): (BasePart?, string?)
	local q = QuestController.Current()
	if not q or not q.Ziel then
		return nil, nil
	end
	local zone = (player:GetAttribute("Zone") :: number?) or 0
	local goal = q.Ziel
	if goal.Zone == zone then
		return nearest(goal.Tag, goal.Attr, from), nil
	end
	-- erst in die richtige Zone reisen
	if q.Art == "Zone" and q.Wert == zone + 1 and zone > 0 then
		return nearest("Portal", { Target = q.Wert }, from), "Geh durch das Portal zur nächsten Zone ➡️"
	end
	if zone == 0 then
		local z = Zones[goal.Zone]
		return nearest("ZoneTeleporter", { ZoneIndex = goal.Zone }, from), ("Erst zum Teleporter %d: %s"):format(goal.Zone, z and z.Name or "?")
	end
	if goal.Zone == zone + 1 then
		return nearest("Portal", { Target = goal.Zone }, from), "Geh durch das Portal zur nächsten Zone ➡️"
	end
	return nearest("Portal", { Target = 0 }, from), "Erst zurück in den Hub (Portal 🏝️ oder 🗺️ Karte)"
end

local function ensureRootAttachment(): Attachment?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	if a0 and a0.Parent == root then
		return a0
	end
	local att = Instance.new("Attachment")
	att.Name = "WegweiserStart"
	att.Position = Vector3.new(0, -1.5, 0)
	att.Parent = root
	a0 = att
	return att
end

function QuestController.SetEnabled(on: boolean)
	QuestController.Enabled = on
end

function QuestController.Init()
	folder = Instance.new("Folder")
	folder.Name = "Wegweiser"
	folder.Parent = workspace

	a1 = Instance.new("Attachment")
	a1.Name = "WegweiserZiel"

	beam = Instance.new("Beam")
	beam.Name = "Wegweiser"
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 225, 110), Color3.fromRGB(255, 170, 80))
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.15, 0.2), NumberSequenceKeypoint.new(1, 0.1) })
	beam.LightEmission = 1
	beam.Width0 = 0.5
	beam.Width1 = 1.2
	beam.FaceCamera = true
	beam.Segments = 12
	beam.CurveSize0 = 6
	beam.CurveSize1 = -4
	beam.Enabled = false
	beam.Parent = folder

	marker = Instance.new("BillboardGui")
	marker.Name = "ZielPfeil"
	marker.Size = UDim2.fromOffset(110, 90)
	marker.AlwaysOnTop = true
	marker.LightInfluence = 0
	marker.Enabled = false
	local arrow = Instance.new("TextLabel")
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.fromScale(1, 0.65)
	arrow.Font = Enum.Font.FredokaOne
	arrow.TextScaled = true
	arrow.TextColor3 = Color3.fromRGB(255, 215, 80)
	arrow.TextStrokeTransparency = 0.2
	arrow.Text = "⬇"
	arrow.Parent = marker
	markerLabel = Instance.new("TextLabel")
	markerLabel.BackgroundTransparency = 1
	markerLabel.Position = UDim2.fromScale(0, 0.65)
	markerLabel.Size = UDim2.fromScale(1, 0.35)
	markerLabel.Font = Enum.Font.FredokaOne
	markerLabel.TextScaled = true
	markerLabel.TextColor3 = Color3.new(1, 1, 1)
	markerLabel.TextStrokeTransparency = 0.2
	markerLabel.Parent = marker
	marker.Parent = player:WaitForChild("PlayerGui")
end

function QuestController.Start()
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		local t = os.clock()
		marker.StudsOffset = Vector3.new(0, 7 + math.sin(t * 4) * 0.8, 0)
		acc += dt
		if acc < 0.3 then
			return
		end
		acc = 0
		local start = ensureRootAttachment()
		local root = start and start.Parent :: BasePart?
		if not QuestController.Enabled or not root then
			beam.Enabled = false
			marker.Enabled = false
			QuestController.Distance = nil
			return
		end
		local part, hint = resolve(root.Position)
		QuestController.Hint = hint
		if part ~= target then
			target = part
			a1.Parent = part
			marker.Adornee = part
		end
		if part then
			local dist = (part.Position - root.Position).Magnitude
			QuestController.Distance = dist
			markerLabel.Text = ("%d m"):format(math.floor(dist / 3.5 + 0.5)) -- 1 Meter ≈ 3,5 Studs
			beam.Attachment0 = start
			beam.Attachment1 = a1
			-- ganz nah: Strahl ausblenden, nur der Pfeil bleibt
			beam.Enabled = dist > 18
			marker.Enabled = true
		else
			QuestController.Distance = nil
			beam.Enabled = false
			marker.Enabled = false
		end
	end)
end

return QuestController
