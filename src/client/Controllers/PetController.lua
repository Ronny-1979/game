--!strict
--[[
	PetController: baut die Pets ALLER Spieler lokal (aus dem Attribut "EquippedPets")
	und lässt sie dem Spieler folgen. Nichts davon wird über das Netz geschickt.

	Aussehen eines Pets:
	  Form (Kugel, Würfel, Zylinder, Zahnrad) bestimmt Körper + Extras (Aufziehschlüssel, Ohren, Antenne, Zähne)
	  Seltenheit: Episch = Flügel, Legendär = Krone
	  Fusions-Stufe: Gold = goldener Glanz, Regenbogen = wechselnde Farben (+ etwas größer)
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

local GOLD = Color3.fromRGB(255, 205, 60)
local DARK = Color3.fromRGB(70, 55, 45)
local BRASS = Color3.fromRGB(230, 190, 90)

local function part(props: { [string]: any }): BasePart
	local p: BasePart = if props.Wedge then Instance.new("WedgePart") else Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		if k ~= "Wedge" then
			(p :: any)[k] = v
		end
	end
	return p
end

-- Anbau-Teil: sitzt relativ zum Körper (Off), optional gedreht (Rot, Bogenmaß)
local function attach(m: Model, s: number, name: string, off: Vector3, props: { [string]: any }, extra: { [string]: any }?): BasePart
	props.Name = name
	if props.Size then
		props.Size = props.Size * s
	end
	local p = part(props)
	p:SetAttribute("Off", off * s)
	if extra then
		for k, v in extra do
			p:SetAttribute(k, v)
		end
	end
	p.Parent = m
	return p
end

-- Ein Pet aus Grundformen bauen. tier = Fusions-Stufe (0, 1 = Gold, 2 = Regenbogen)
function PetController.BuildModel(petType: string, name: string?, tier: number?): (Model?, BasePart?, BasePart?)
	local def = Pets.Liste[petType]
	if not def then
		return nil, nil, nil
	end
	local t = tier or 0
	local stage = if t > 0 then Pets.Fusion.Stufen[t] else nil
	local s = 1 + 0.15 * t -- Fusions-Pets sind etwas größer
	local color: Color3 = def.Farbe
	if t == 1 then
		color = color:Lerp(GOLD, 0.6)
	end
	local bodyMat = if t == 1 then Enum.Material.Metal else Enum.Material.SmoothPlastic

	local m = Instance.new("Model")
	m.Name = def.Name
	local size = 2 * s
	local body: BasePart
	if def.Form == "Kugel" then
		body = part({ Shape = Enum.PartType.Ball, Size = Vector3.new(size, size, size), Color = color, Material = bodyMat })
	elseif def.Form == "Zylinder" then
		body = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(size * 1.1, size, size), Color = color, Material = bodyMat })
	elseif def.Form == "Zahnrad" then
		body = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(size * 0.7, size * 1.1, size * 1.1), Color = color, Material = Enum.Material.Metal })
	else
		body = part({ Size = Vector3.new(size, size, size), Color = color, Material = bodyMat })
	end
	body.Name = "Koerper"
	body:SetAttribute("Form", def.Form)
	if t == 2 then
		body:SetAttribute("Rainbow", true)
	end
	body.Parent = m
	m.PrimaryPart = body

	-- Gesicht: Augen mit Glanzpunkt, Bäckchen
	local white = Color3.new(1, 1, 1)
	local faceZ = if def.Form == "Zahnrad" then -0.45 else -0.85
	for _, side in { -1, 1 } do
		attach(m, s, "Auge", Vector3.new(side * 0.42, 0.25, faceZ), { Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.6, 0.6), Color = white })
		attach(m, s, "Pupille", Vector3.new(side * 0.42, 0.25, faceZ - 0.23), { Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), Color = Color3.fromRGB(40, 30, 30) })
		attach(m, s, "Glanz", Vector3.new(side * 0.42 + 0.07, 0.33, faceZ - 0.36), { Shape = Enum.PartType.Ball, Size = Vector3.new(0.1, 0.1, 0.1), Color = white, Material = Enum.Material.Neon })
		if def.Form ~= "Zahnrad" then
			attach(m, s, "Baeckchen", Vector3.new(side * 0.68, -0.12, faceZ + 0.12), { Shape = Enum.PartType.Ball, Size = Vector3.new(0.34, 0.2, 0.1), Color = Color3.fromRGB(255, 150, 170) })
		end
	end
	-- Füßchen
	if def.Form ~= "Zahnrad" then
		for _, side in { -1, 1 } do
			attach(m, s, "Fuss", Vector3.new(side * 0.5, -1.0, -0.15), { Shape = Enum.PartType.Ball, Size = Vector3.new(0.55, 0.35, 0.7), Color = color:Lerp(DARK, 0.45) })
		end
	end

	-- Form-Extras
	if def.Form == "Kugel" or def.Form == "Zylinder" then
		-- Aufziehschlüssel hinten (dreht sich)
		attach(m, s, "Schluesselstift", Vector3.new(0, 0.1, 1.1), { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 0.25, 0.25), Color = BRASS, Material = Enum.Material.Metal }, { Rot = Vector3.new(0, math.rad(90), 0) })
		attach(m, s, "Schluessel", Vector3.new(0, 0.1, 1.4), { Size = Vector3.new(1.1, 0.4, 0.12), Color = BRASS, Material = Enum.Material.Metal }, { Key = true })
	end
	if def.Form == "Wuerfel" then
		for _, side in { -1, 1 } do
			attach(m, s, "Ohr", Vector3.new(side * 0.6, 1.25, 0), { Wedge = true, Size = Vector3.new(0.18, 0.55, 0.5), Color = color:Lerp(DARK, 0.2) }, { Rot = Vector3.new(0, math.rad(90), 0) })
		end
	end
	if def.Form == "Zylinder" then
		attach(m, s, "Antenne", Vector3.new(0.45, 1.45, 0), { Size = Vector3.new(0.08, 0.7, 0.08), Color = DARK })
		attach(m, s, "Antennenlicht", Vector3.new(0.45, 1.85, 0), { Shape = Enum.PartType.Ball, Size = Vector3.new(0.28, 0.28, 0.28), Color = Color3.fromRGB(255, 120, 120), Material = Enum.Material.Neon })
	end
	if def.Form == "Zahnrad" then
		for i = 1, 10 do
			local a = i / 10 * math.pi * 2
			attach(m, s, "Zahn", Vector3.new(math.cos(a) * 1.18, math.sin(a) * 1.18, 0), { Size = Vector3.new(0.4, 0.4, 0.6), Color = color:Lerp(DARK, 0.15), Material = Enum.Material.Metal }, { Rot = Vector3.new(0, 0, a) })
		end
	end

	-- Seltenheits-Schmuck
	local top: BasePart
	if def.Seltenheit == "Legendaer" then
		top = attach(m, s, "Krone", Vector3.new(0, 1.15, 0), { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 1.0, 1.0), Color = GOLD, Material = Enum.Material.Metal }, { Rot = Vector3.new(0, 0, math.rad(90)) })
		for i = 1, 5 do
			local a = i / 5 * math.pi * 2
			attach(m, s, "Zacke", Vector3.new(math.cos(a) * 0.42, 1.42, math.sin(a) * 0.42), { Size = Vector3.new(0.16, 0.38, 0.16), Color = GOLD, Material = Enum.Material.Metal })
		end
		attach(m, s, "Juwel", Vector3.new(0, 1.15, -0.52), { Shape = Enum.PartType.Ball, Size = Vector3.new(0.22, 0.22, 0.22), Color = Color3.fromRGB(255, 80, 120), Material = Enum.Material.Neon })
	else
		top = attach(m, s, "Zahnrad", Vector3.new(0, 1.25, 0), { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.25, 1, 1), Color = BRASS, Material = Enum.Material.Metal }, { Spin = true })
	end
	if def.Seltenheit == "Episch" or def.Seltenheit == "Legendaer" then
		for _, side in { -1, 1 } do
			attach(m, s, "Fluegel", Vector3.new(side * 1.25, 0.35, 0.35), { Size = Vector3.new(0.1, 0.8, 1.3), Color = Color3.fromRGB(255, 255, 255), Transparency = 0.2 }, { Flap = side })
		end
	end

	-- Leuchten für seltene Pets und Fusions-Pets
	local rarity = Pets.Seltenheiten[def.Seltenheit]
	local glow: Color3? = if stage then stage.Farbe elseif def.Seltenheit == "Episch" or def.Seltenheit == "Legendaer" then rarity.Farbe else nil
	if glow then
		local light = Instance.new("PointLight")
		light.Color = glow
		light.Range = 8 + t * 2
		light.Brightness = 1.5
		light.Parent = body
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Rate = 4 + t * 4
		sparkle.Lifetime = NumberRange.new(0.6, 1)
		sparkle.Speed = NumberRange.new(0.5, 1.5)
		sparkle.Size = NumberSequence.new(0.25 * s, 0)
		if t == 2 then
			sparkle.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 90)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 230, 90)),
				ColorSequenceKeypoint.new(0.66, Color3.fromRGB(90, 220, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 120, 255)),
			})
		else
			sparkle.Color = ColorSequence.new(glow)
		end
		sparkle.LightEmission = 1
		sparkle.Parent = body
	end
	if name and name ~= "" or stage then
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(110, 24)
		gui.StudsOffset = Vector3.new(0, 2 * s, 0)
		gui.MaxDistance = 40
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = if stage then stage.Farbe else rarity.Farbe
		label.TextStrokeTransparency = 0.3
		label.Text = (if stage then stage.Symbol .. " " else "") .. (if name and name ~= "" then name else def.Name)
		label.Parent = gui
		gui.Parent = body
	end
	return m, body, top
end

-- Alle Teile eines Pet-Modells relativ zu cf anordnen. t = Zeit (für Drehen/Flattern/Farben)
local function pose(model: Model, cf: CFrame, t: number)
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
				if p:GetAttribute("Rainbow") then
					p.Color = Color3.fromHSV((t * 0.12) % 1, 0.45, 1)
				end
			else
				local off = p:GetAttribute("Off")
				if typeof(off) == "Vector3" then
					local c = cf * CFrame.new(off)
					local rot = p:GetAttribute("Rot")
					if typeof(rot) == "Vector3" then
						c = c * CFrame.fromEulerAnglesXYZ(rot.X, rot.Y, rot.Z)
					end
					if p:GetAttribute("Spin") then
						c = c * CFrame.Angles(0, t * 4, math.rad(90))
					elseif p:GetAttribute("Key") then
						c = c * CFrame.Angles(0, 0, t * 3)
					end
					local flap = p:GetAttribute("Flap")
					if type(flap) == "number" then
						c = c * CFrame.Angles(0, 0, flap * (0.3 + math.sin(t * 12) * 0.35))
					end
					p.CFrame = c
				end
			end
		end
	end
end

-- Für Vorschauen (Menüs): Pet in Ruhehaltung um den Ursprung anordnen
function PetController.PoseStatic(model: Model, t: number?)
	pose(model, CFrame.identity, t or 0)
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
		local m, body, gear = PetController.BuildModel(entry.T, entry.N, tonumber(entry.S) or 0)
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
					pose(v.Model, v.Cf, t + i)
				end
			end
		end
	end)
end

return PetController
