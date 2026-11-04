--!strict
-- Parts: kleine Bau-Helfer für den WorldBuilder (Parts, Zylinder, Schilder, Inseln, Brücken, Zahnräder)
local CollectionService = game:GetService("CollectionService")

local Parts = {}

export type Props = { [string]: any }

-- Normales Part. Besondere Schlüssel: Tags = {..}, Attrs = {..}
function Parts.Part(props: Props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	local parent = props.Parent
	for k, v in props do
		if k ~= "Parent" and k ~= "Tags" and k ~= "Attrs" then
			(p :: any)[k] = v
		end
	end
	if props.Tags then
		for _, t in props.Tags do
			CollectionService:AddTag(p, t)
		end
	end
	if props.Attrs then
		for k, v in props.Attrs do
			p:SetAttribute(k, v)
		end
	end
	if parent then
		p.Parent = parent
	end
	return p
end

-- Stehender Zylinder. topCenter = Mitte der Oberseite
function Parts.Cylinder(topCenter: Vector3, radius: number, height: number, props: Props): Part
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(height, radius * 2, radius * 2)
	props.CFrame = CFrame.new(topCenter - Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	return Parts.Part(props)
end

-- Block, dessen Oberseite bei topCenter liegt
function Parts.Block(topCenter: Vector3, size: Vector3, props: Props): Part
	props.Size = size
	props.CFrame = CFrame.new(topCenter - Vector3.new(0, size.Y / 2, 0))
	return Parts.Part(props)
end

function Parts.Model(name: string, parent: Instance?): Model
	local m = Instance.new("Model")
	m.Name = name
	if parent then
		m.Parent = parent
	end
	return m
end

function Parts.Folder(name: string, parent: Instance?): Folder
	local f = Instance.new("Folder")
	f.Name = name
	if parent then
		f.Parent = parent
	end
	return f
end

-- Text auf eine Fläche eines Parts schreiben
function Parts.SurfaceText(part: BasePart, text: string, face: Enum.NormalId, color: Color3?, bg: Color3?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.2
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = bg or Color3.fromRGB(255, 246, 225)
	label.BackgroundTransparency = if bg then 0 else 1
	label.TextColor3 = color or Color3.fromRGB(70, 50, 35)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextWrapped = true
	label.Text = text
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.PaddingTop = UDim.new(0.06, 0)
	pad.PaddingBottom = UDim.new(0.06, 0)
	pad.Parent = label
	label.Parent = gui
	gui.Parent = part
end

-- Hinweis-Schild auf zwei Pfosten. pos = Boden-Mitte, Schild schaut Richtung -Z (zum Spieler, der in +Z läuft)
function Parts.Sign(parent: Instance, pos: Vector3, text: string, width: number?, height: number?, facing: Vector3?): Model
	local w = width or 10
	local h = height or 5
	local model = Parts.Model("Schild", parent)
	local dir = facing or Vector3.new(0, 0, -1)
	local boardCf = CFrame.lookAt(pos + Vector3.new(0, 3 + h / 2, 0), pos + Vector3.new(0, 3 + h / 2, 0) + dir)
	local board = Parts.Part({
		Name = "Tafel",
		Size = Vector3.new(w, h, 0.6),
		CFrame = boardCf,
		Color = Color3.fromRGB(255, 240, 205),
		Material = Enum.Material.Wood,
		Parent = model,
	})
	Parts.SurfaceText(board, text, Enum.NormalId.Front)
	Parts.SurfaceText(board, text, Enum.NormalId.Back)
	for _, side in { -1, 1 } do
		Parts.Part({
			Name = "Pfosten",
			Size = Vector3.new(0.6, 3 + h, 0.6),
			CFrame = boardCf * CFrame.new(side * (w / 2 - 0.5), -1.5, 0.4),
			Color = Color3.fromRGB(170, 120, 75),
			Material = Enum.Material.Wood,
			Parent = model,
		})
	end
	return model
end

-- Schwebende Insel: obere Scheibe + kleiner werdende Felsen darunter
function Parts.Island(parent: Instance, topCenter: Vector3, radius: number, color: Color3, rimColor: Color3): Part
	local top = Parts.Cylinder(topCenter, radius, 4, {
		Name = "Insel",
		Color = color,
		Material = Enum.Material.Grass,
		Parent = parent,
	})
	Parts.Cylinder(topCenter - Vector3.new(0, 3.6, 0), radius + 1.2, 1.4, {
		Name = "Rand",
		Color = rimColor,
		Material = Enum.Material.Metal,
		Parent = parent,
	})
	local rock = Color3.fromRGB(175, 150, 130)
	local r = radius * 0.85
	local y = topCenter.Y - 4.5
	for i = 1, 3 do
		Parts.Cylinder(Vector3.new(topCenter.X, y, topCenter.Z), r, 7, {
			Name = "Fels",
			Color = rock:Lerp(Color3.fromRGB(120, 100, 90), i * 0.15),
			Material = Enum.Material.Slate,
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
		y -= 7
		r *= 0.65
	end
	return top
end

-- Gerade Brücke von a nach b (Oberseite auf Höhe von a.Y)
function Parts.Bridge(parent: Instance, a: Vector3, b: Vector3, width: number, color: Color3): Part
	local flatB = Vector3.new(b.X, a.Y, b.Z)
	local mid = (a + flatB) / 2
	local length = (flatB - a).Magnitude
	local cf = CFrame.lookAt(mid - Vector3.new(0, 0.71, 0), mid - Vector3.new(0, 0.71, 0) + (flatB - a).Unit)
	local bridge = Parts.Part({
		Name = "Bruecke",
		Size = Vector3.new(width, 1.5, length),
		CFrame = cf,
		Color = color,
		Material = Enum.Material.WoodPlanks,
		Parent = parent,
	})
	-- Geländer
	for _, side in { -1, 1 } do
		Parts.Part({
			Name = "Gelaender",
			Size = Vector3.new(0.5, 2.5, length),
			CFrame = cf * CFrame.new(side * (width / 2 - 0.25), 2, 0),
			Color = Color3.fromRGB(205, 160, 80),
			Material = Enum.Material.Metal,
			Parent = parent,
		})
	end
	return bridge
end

-- Zahnrad aus Scheibe + Zähnen. cf = Mitte, Drehachse = lokale Y-Achse von cf
function Parts.Gear(parent: Instance, cf: CFrame, radius: number, thickness: number, teeth: number, color: Color3, collide: boolean?): { BasePart }
	local list = {}
	local disk = Parts.Part({
		Name = "Scheibe",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(thickness, radius * 2, radius * 2),
		CFrame = cf * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = Enum.Material.Metal,
		CanCollide = if collide == nil then true else collide,
		Parent = parent,
	})
	table.insert(list, disk)
	local toothW = math.max(1, radius * 2 * math.pi / teeth * 0.45)
	for i = 1, teeth do
		local a = i / teeth * math.pi * 2
		local tooth = Parts.Part({
			Name = "Zahn",
			Size = Vector3.new(toothW, thickness, radius * 0.22 + 0.6),
			CFrame = cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -(radius + radius * 0.11)),
			Color = color:Lerp(Color3.new(0, 0, 0), 0.12),
			Material = Enum.Material.Metal,
			CanCollide = if collide == nil then true else collide,
			Parent = parent,
		})
		table.insert(list, tooth)
	end
	return list
end

function Parts.Prompt(part: BasePart, action: string, object: string, hold: number?): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = hold or 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

function Parts.Billboard(part: BasePart, text: string, offsetY: number, size: Vector2?, color: Color3?): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset((size and size.X) or 220, (size and size.Y) or 60)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = 140
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.35
	label.Text = text
	label.Parent = gui
	gui.Parent = part
	return label
end

-- Hindernis-Modell: wird vom Client animiert (Tag "Obstacle")
function Parts.Obstacle(parent: Instance, name: string, kind: string, basePivot: CFrame, attrs: { [string]: any }): Model
	local m = Instance.new("Model")
	m.Name = name
	m.WorldPivot = basePivot
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m:SetAttribute("Kind", kind)
	m:SetAttribute("BasePivot", basePivot)
	for k, v in attrs do
		m:SetAttribute(k, v)
	end
	CollectionService:AddTag(m, "Obstacle")
	m.Parent = parent
	return m
end

return Parts
