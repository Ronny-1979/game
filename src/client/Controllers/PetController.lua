--!strict
--[[
	PetController: baut die Pets ALLER Spieler lokal (aus dem Attribut "EquippedPets")
	und lässt sie dem Spieler folgen. Nichts davon wird über das Netz geschickt.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Pets = require(Shared:WaitForChild("Config"):WaitForChild("Pets")) :: any
local Janitor = require(Shared:WaitForChild("Janitor"))

local PetController = {}

type PetVisual = { Model: Model, Body: BasePart, Gear: BasePart, Offset: Vector3, Cf: CFrame }
local byPlayer: { [Player]: { PetVisual } } = {}
local janitors: { [Player]: any } = {}
local folder: Folder

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

-- Ein Pet aus Grundformen bauen (Form aus der Konfig)
function PetController.BuildModel(petType: string, name: string?): (Model?, BasePart?, BasePart?)
	local def = Pets.Liste[petType]
	if not def then
		return nil, nil, nil
	end
	local m = Instance.new("Model")
	m.Name = def.Name
	local size = 2
	local body: BasePart
	if def.Form == "Kugel" then
		body = part({ Shape = Enum.PartType.Ball, Size = Vector3.new(size, size, size), Color = def.Farbe })
	elseif def.Form == "Zylinder" then
		body = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(size * 1.1, size, size), Color = def.Farbe })
	elseif def.Form == "Zahnrad" then
		body = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(size * 0.7, size * 1.1, size * 1.1), Color = def.Farbe, Material = Enum.Material.Metal })
	else
		body = part({ Size = Vector3.new(size, size, size), Color = def.Farbe })
	end
	body.Name = "Koerper"
	body:SetAttribute("Form", def.Form)
	body.Parent = m
	m.PrimaryPart = body
	local white = Color3.new(1, 1, 1)
	for _, side in { -1, 1 } do
		local eye = part({ Name = "Auge", Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.6, 0.6), Color = white })
		eye:SetAttribute("Off", Vector3.new(side * 0.42, 0.25, -0.85))
		eye.Parent = m
		local pupil = part({ Name = "Pupille", Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), Color = Color3.fromRGB(40, 30, 30) })
		pupil:SetAttribute("Off", Vector3.new(side * 0.42, 0.25, -1.08))
		pupil.Parent = m
	end
	local gear = part({ Name = "Zahnrad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.25, 1, 1), Color = Color3.fromRGB(230, 190, 90), Material = Enum.Material.Metal })
	gear:SetAttribute("Off", Vector3.new(0, 1.25, 0))
	gear.Parent = m
	local rarity = Pets.Seltenheiten[def.Seltenheit]
	if def.Seltenheit == "Episch" or def.Seltenheit == "Legendaer" then
		local light = Instance.new("PointLight")
		light.Color = rarity.Farbe
		light.Range = 8
		light.Brightness = 1.5
		light.Parent = body
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Rate = 4
		sparkle.Lifetime = NumberRange.new(0.6, 1)
		sparkle.Speed = NumberRange.new(0.5, 1.5)
		sparkle.Size = NumberSequence.new(0.25, 0)
		sparkle.Color = ColorSequence.new(rarity.Farbe)
		sparkle.LightEmission = 1
		sparkle.Parent = body
	end
	if name and name ~= "" then
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(100, 24)
		gui.StudsOffset = Vector3.new(0, 2, 0)
		gui.MaxDistance = 40
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = rarity.Farbe
		label.TextStrokeTransparency = 0.3
		label.Text = name
		label.Parent = gui
		gui.Parent = body
	end
	return m, body, gear
end

local function pose(model: Model, cf: CFrame, spin: number)
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") then
			if p.Name == "Koerper" then
				local form = p:GetAttribute("Form")
				if form == "Zylinder" then
					p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90)) -- aufrecht
				elseif form == "Zahnrad" then
					p.CFrame = cf * CFrame.Angles(0, math.rad(90), 0) -- wie ein Rad nach vorne
				else
					p.CFrame = cf
				end
			else
				local off = p:GetAttribute("Off")
				if typeof(off) == "Vector3" then
					local c = cf * CFrame.new(off)
					if p.Name == "Zahnrad" then
						c = c * CFrame.Angles(0, spin, math.rad(90))
					end
					p.CFrame = c
				end
			end
		end
	end
end

local function clear(plr: Player)
	for _, v in byPlayer[plr] or {} do
		v.Model:Destroy()
	end
	byPlayer[plr] = nil
end

local function rebuild(plr: Player)
	clear(plr)
	local raw = plr:GetAttribute("EquippedPets")
	if type(raw) ~= "string" then
		return
	end
	local ok, list = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or type(list) ~= "table" then
		return
	end
	local visuals = {}
	local n = #list
	for i, entry in list do
		local m, body, gear = PetController.BuildModel(entry.T, entry.N)
		if m and body and gear then
			-- im Halbkreis hinter dem Spieler
			local spread = if n > 1 then (i - 1) / (n - 1) - 0.5 else 0
			local offset = Vector3.new(spread * 7, 0, 4.5 + math.abs(spread) * 1.5)
			m.Parent = folder
			table.insert(visuals, { Model = m, Body = body, Gear = gear, Offset = offset, Cf = CFrame.new(0, -500, 0) })
		end
	end
	byPlayer[plr] = visuals
end

local function watch(plr: Player)
	local j = Janitor.new()
	janitors[plr] = j
	j:Add(plr:GetAttributeChangedSignal("EquippedPets"):Connect(function()
		rebuild(plr)
	end))
	j:Add(function()
		clear(plr)
	end)
	rebuild(plr)
end

function PetController.Init()
	folder = Instance.new("Folder")
	folder.Name = "LokalePets"
	folder.Parent = workspace
end

function PetController.Start()
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(plr)
		local j = janitors[plr]
		janitors[plr] = nil
		if j then
			j:Cleanup()
		else
			clear(plr)
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		local cam = workspace.CurrentCamera
		for plr, visuals in byPlayer do
			local char = plr.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and cam and (root.Position - cam.CFrame.Position).Magnitude < 250 then
				for i, v in visuals do
					local bob = math.sin(t * 3 + i) * 0.35
					local target = root.CFrame * CFrame.new(v.Offset + Vector3.new(0, -1 + bob, 0))
					if (v.Cf.Position - target.Position).Magnitude > 40 then
						v.Cf = target
					else
						v.Cf = v.Cf:Lerp(target, math.min(1, dt * 7))
					end
					pose(v.Model, v.Cf, t * 4)
				end
			end
		end
	end)
end

return PetController
