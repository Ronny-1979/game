--!strict
--[[
	DecoModels: baut die Deko-Stücke für die Werkstatt-Insel (Konfig: Deco.lua).
	Server (echte Deko) und Client (Vorschau beim Platzieren) benutzen dieselben Modelle.
	Jedes Modell steht mit der Unterseite auf y = 0 und ist um den Ursprung zentriert.
]]
local DecoModels = {}

local BRASS = Color3.fromRGB(215, 170, 80)
local WOOD = Color3.fromRGB(170, 120, 80)
local DARKWOOD = Color3.fromRGB(130, 90, 60)
local LEAF = Color3.fromRGB(120, 195, 110)
local STONE = Color3.fromRGB(215, 205, 190)

type Builder = (Model, number, any) -> ()

local function P(m: Model, props: { [string]: any }): BasePart
	local p: BasePart = if props.Wedge then Instance.new("WedgePart") else Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		if k ~= "Wedge" and k ~= "At" then
			(p :: any)[k] = v
		end
	end
	if props.At then
		p.CFrame = props.At
	end
	p.Parent = m
	return p
end

local function ball(m: Model, pos: Vector3, size: Vector3, color: Color3, mat: Enum.Material?): BasePart
	return P(m, { Shape = Enum.PartType.Ball, Size = size, At = CFrame.new(pos), Color = color, Material = mat or Enum.Material.SmoothPlastic })
end

local function cyl(m: Model, bottom: Vector3, radius: number, height: number, color: Color3, mat: Enum.Material?): BasePart
	return P(m, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, radius * 2, radius * 2),
		At = CFrame.new(bottom + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = mat or Enum.Material.SmoothPlastic,
	})
end

local function box(m: Model, bottom: Vector3, size: Vector3, color: Color3, mat: Enum.Material?): BasePart
	return P(m, { Size = size, At = CFrame.new(bottom + Vector3.new(0, size.Y / 2, 0)), Color = color, Material = mat or Enum.Material.SmoothPlastic })
end

local function light(part: BasePart, color: Color3, range: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = 1.2
	l.Shadows = false
	l.Parent = part
end

local B: { [string]: Builder } = {}

B.Blumenbeet = function(m, fp)
	local w = fp * 0.85
	box(m, Vector3.zero, Vector3.new(w, 0.8, w), WOOD, Enum.Material.WoodPlanks)
	box(m, Vector3.new(0, 0.8, 0), Vector3.new(w - 0.8, 0.1, w - 0.8), Color3.fromRGB(120, 85, 60), Enum.Material.Ground)
	local colors = { Color3.fromRGB(255, 150, 180), Color3.fromRGB(255, 220, 100), Color3.fromRGB(180, 150, 255), Color3.fromRGB(255, 255, 255) }
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		local pos = Vector3.new(math.cos(a) * w * 0.25, 0.9, math.sin(a) * w * 0.25)
		box(m, pos, Vector3.new(0.2, 1.2, 0.2), Color3.fromRGB(110, 180, 90))
		ball(m, pos + Vector3.new(0, 1.3, 0), Vector3.new(0.9, 0.6, 0.9), colors[i % #colors + 1])
	end
end

B.Hecke = function(m, fp)
	local w = fp * 0.9
	box(m, Vector3.zero, Vector3.new(w, 3, 2.6), LEAF, Enum.Material.Grass)
	for i = -1, 1 do
		ball(m, Vector3.new(i * w * 0.3, 3.1, 0), Vector3.new(2.6, 1.8, 2.6), LEAF:Lerp(Color3.fromRGB(80, 160, 80), 0.3), Enum.Material.Grass)
	end
end

B.Zaun = function(m, fp)
	local w = fp
	for _, x in { -w / 2 + 0.3, w / 2 - 0.3 } do
		box(m, Vector3.new(x, 0, 0), Vector3.new(0.5, 3, 0.5), WOOD, Enum.Material.Wood)
	end
	for _, y in { 0.9, 2.1 } do
		box(m, Vector3.new(0, y, 0), Vector3.new(w, 0.4, 0.25), Color3.fromRGB(240, 225, 200), Enum.Material.Wood)
	end
end

B.Baum = function(m)
	box(m, Vector3.zero, Vector3.new(1.4, 7, 1.4), Color3.fromRGB(150, 105, 70), Enum.Material.Wood)
	ball(m, Vector3.new(0, 8.5, 0), Vector3.new(7, 6.5, 7), LEAF, Enum.Material.Grass)
	ball(m, Vector3.new(1.2, 10.8, 0.6), Vector3.new(4.5, 4, 4.5), LEAF:Lerp(Color3.fromRGB(170, 230, 140), 0.4), Enum.Material.Grass)
end

B.Pilze = function(m)
	for i, d in { { -1.3, 0, 1.8, Color3.fromRGB(240, 90, 90) }, { 1.1, 0.8, 1.2, Color3.fromRGB(190, 140, 230) }, { 0.2, -1.2, 0.9, Color3.fromRGB(240, 90, 90) } } do
		local h = d[3] :: number
		local pos = Vector3.new(d[1] :: number, 0, d[2] :: number)
		cyl(m, pos, 0.35 * h, h, Color3.fromRGB(250, 240, 220))
		ball(m, pos + Vector3.new(0, h, 0), Vector3.new(1.9, 1, 1.9) * h, d[4] :: Color3)
		if i == 1 then
			ball(m, pos + Vector3.new(0.4, h + 0.4, -0.5), Vector3.new(0.35, 0.2, 0.35), Color3.new(1, 1, 1))
		end
	end
end

B.Laterne = function(m)
	cyl(m, Vector3.zero, 0.8, 0.5, DARKWOOD, Enum.Material.Metal)
	box(m, Vector3.new(0, 0.5, 0), Vector3.new(0.4, 6.5, 0.4), Color3.fromRGB(90, 75, 65), Enum.Material.Metal)
	box(m, Vector3.new(0, 7, 0), Vector3.new(1.6, 0.3, 1.6), BRASS, Enum.Material.Metal)
	local lamp = box(m, Vector3.new(0, 7.3, 0), Vector3.new(1.2, 1.4, 1.2), Color3.fromRGB(255, 225, 150), Enum.Material.Neon)
	box(m, Vector3.new(0, 8.7, 0), Vector3.new(1.8, 0.4, 1.8), BRASS, Enum.Material.Metal)
	light(lamp, Color3.fromRGB(255, 220, 170), 18)
end

B.Bank = function(m)
	box(m, Vector3.new(0, 1.4, 0), Vector3.new(6, 0.4, 1.8), WOOD, Enum.Material.WoodPlanks)
	box(m, Vector3.new(0, 1.8, 0.75), Vector3.new(6, 1.6, 0.3), WOOD, Enum.Material.WoodPlanks)
	for _, x in { -2.5, 2.5 } do
		box(m, Vector3.new(x, 0, 0), Vector3.new(0.4, 1.4, 1.6), Color3.fromRGB(90, 75, 65), Enum.Material.Metal)
	end
end

B.Kristall = function(m)
	cyl(m, Vector3.zero, 1.6, 0.8, STONE, Enum.Material.Slate)
	local c = P(m, { Size = Vector3.new(1.6, 5, 1.6), At = CFrame.new(0, 3.2, 0) * CFrame.Angles(0, 0.6, math.rad(10)), Color = Color3.fromRGB(140, 230, 255), Material = Enum.Material.Neon, Transparency = 0.15 })
	P(m, { Size = Vector3.new(0.9, 2.6, 0.9), At = CFrame.new(0.9, 1.9, 0.4) * CFrame.Angles(0, 0.2, math.rad(-25)), Color = Color3.fromRGB(200, 160, 255), Material = Enum.Material.Neon, Transparency = 0.15 })
	light(c, Color3.fromRGB(140, 230, 255), 14)
end

B.Haus = function(m, fp)
	local w = fp * 0.7
	box(m, Vector3.zero, Vector3.new(w, 6, w), Color3.fromRGB(255, 235, 205), Enum.Material.Brick)
	-- Dach aus zwei Keilen
	for _, side in { -1, 1 } do
		P(m, {
			Wedge = true,
			Size = Vector3.new(w + 1, 3.5, (w + 1) / 2),
			At = CFrame.new(0, 7.75, side * (w + 1) / 4) * CFrame.Angles(0, if side == 1 then math.rad(180) else 0, 0),
			Color = Color3.fromRGB(215, 110, 90),
			Material = Enum.Material.Slate,
		})
	end
	box(m, Vector3.new(0, 0, -w / 2 - 0.05), Vector3.new(2.4, 3.6, 0.3), DARKWOOD, Enum.Material.Wood)
	for _, x in { -w * 0.3, w * 0.3 } do
		local win = box(m, Vector3.new(x, 3.4, -w / 2 - 0.05), Vector3.new(1.6, 1.6, 0.25), Color3.fromRGB(255, 230, 150), Enum.Material.Neon)
		if x > 0 then
			light(win, Color3.fromRGB(255, 220, 160), 12)
		end
	end
	ball(m, Vector3.new(0, 5.2, -w / 2 - 0.2), Vector3.new(1.2, 1.2, 0.3), BRASS, Enum.Material.Metal)
end

local function gear(m: Model, cf: CFrame, radius: number, thick: number, teeth: number, color: Color3)
	P(m, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(thick, radius * 2, radius * 2), At = cf * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = Enum.Material.Metal })
	for i = 1, teeth do
		local a = i / teeth * math.pi * 2
		P(m, { Size = Vector3.new(radius * 0.35, thick, radius * 0.3), At = cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -radius * 1.1), Color = color:Lerp(Color3.new(0, 0, 0), 0.12), Material = Enum.Material.Metal })
	end
end

B.Zahnradskulptur = function(m)
	box(m, Vector3.zero, Vector3.new(6, 1.2, 4), STONE, Enum.Material.Marble)
	gear(m, CFrame.new(-0.8, 6.2, 0) * CFrame.Angles(math.rad(90), 0, 0), 4.2, 0.9, 12, BRASS)
	gear(m, CFrame.new(3.4, 4.2, 0.6) * CFrame.Angles(math.rad(90), 0, 0), 2.2, 0.7, 9, Color3.fromRGB(200, 120, 75))
end

B.Brunnen = function(m)
	cyl(m, Vector3.zero, 6.5, 1.6, STONE, Enum.Material.Marble)
	cyl(m, Vector3.new(0, 0.2, 0), 5.8, 1.5, Color3.fromRGB(120, 200, 240), Enum.Material.Glass).Transparency = 0.3
	cyl(m, Vector3.new(0, 1.6, 0), 0.8, 3.5, STONE, Enum.Material.Marble)
	cyl(m, Vector3.new(0, 5.1, 0), 2.2, 0.6, STONE, Enum.Material.Marble)
	local top = ball(m, Vector3.new(0, 6, 0), Vector3.new(1.2, 1.2, 1.2), Color3.fromRGB(160, 225, 255), Enum.Material.Neon)
	local spray = Instance.new("ParticleEmitter")
	spray.Rate = 30
	spray.Lifetime = NumberRange.new(0.8, 1.2)
	spray.Speed = NumberRange.new(6, 9)
	spray.SpreadAngle = Vector2.new(20, 20)
	spray.Acceleration = Vector3.new(0, -18, 0)
	spray.Size = NumberSequence.new(0.35, 0.1)
	spray.Color = ColorSequence.new(Color3.fromRGB(200, 240, 255))
	spray.Transparency = NumberSequence.new(0.2, 0.8)
	spray.Parent = top
end

B.Uhrturm = function(m)
	box(m, Vector3.zero, Vector3.new(7, 1, 7), Color3.fromRGB(200, 120, 75), Enum.Material.Brick)
	box(m, Vector3.new(0, 1, 0), Vector3.new(5, 12, 5), Color3.fromRGB(255, 240, 210), Enum.Material.Brick)
	box(m, Vector3.new(0, 13, 0), Vector3.new(6, 0.8, 6), BRASS, Enum.Material.Metal)
	for i = 0, 3 do
		local face = CFrame.new(0, 10, 0) * CFrame.Angles(0, i * math.pi / 2, 0) * CFrame.new(0, 0, -2.6)
		P(m, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 3.6, 3.6), At = face * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(255, 252, 240) })
		P(m, { Size = Vector3.new(0.3, 1.4, 0.15), At = face * CFrame.new(0, 0.6, -0.2), Color = Color3.fromRGB(60, 45, 35) })
		P(m, { Size = Vector3.new(1.0, 0.25, 0.15), At = face * CFrame.new(0.4, 0, -0.2), Color = Color3.fromRGB(60, 45, 35) })
	end
	for i = 0, 3 do
		P(m, {
			Wedge = true,
			Size = Vector3.new(6, 3.5, 3),
			At = CFrame.new(0, 15.55, 0) * CFrame.Angles(0, i * math.pi / 2, 0) * CFrame.new(0, 0, -1.5),
			Color = Color3.fromRGB(120, 175, 210),
			Material = Enum.Material.Slate,
		})
	end
	ball(m, Vector3.new(0, 17.6, 0), Vector3.new(1, 1, 1), BRASS, Enum.Material.Metal)
end

B.Amboss = function(m)
	box(m, Vector3.zero, Vector3.new(2.6, 1.6, 2), DARKWOOD, Enum.Material.Wood)
	box(m, Vector3.new(0, 1.6, 0), Vector3.new(1.4, 1, 1.2), Color3.fromRGB(90, 90, 100), Enum.Material.Metal)
	box(m, Vector3.new(0, 2.6, 0), Vector3.new(3.6, 0.9, 1.6), Color3.fromRGB(110, 110, 120), Enum.Material.Metal)
	P(m, { Wedge = true, Size = Vector3.new(1.6, 0.9, 1.4), At = CFrame.new(-2.5, 3.05, 0) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(110, 110, 120), Material = Enum.Material.Metal })
end

B.Pendeluhr = function(m)
	box(m, Vector3.zero, Vector3.new(3, 9, 2), DARKWOOD, Enum.Material.Wood)
	P(m, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 2.4, 2.4), At = CFrame.new(0, 7.3, -1.05) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(255, 250, 235) })
	box(m, Vector3.new(0, 1.2, -1.02), Vector3.new(2.2, 4.4, 0.1), Color3.fromRGB(200, 230, 245), Enum.Material.Glass).Transparency = 0.4
	box(m, Vector3.new(0, 2.6, -0.8), Vector3.new(0.15, 3, 0.15), BRASS, Enum.Material.Metal)
	ball(m, Vector3.new(0, 2.3, -0.8), Vector3.new(1, 1, 0.3), BRASS, Enum.Material.Metal)
	box(m, Vector3.new(0, 9, 0), Vector3.new(3.4, 0.6, 2.4), BRASS, Enum.Material.Metal)
end

B.Prisma = function(m)
	cyl(m, Vector3.zero, 1.8, 1, STONE, Enum.Material.Marble)
	local c = P(m, { Size = Vector3.new(1.8, 8, 1.8), At = CFrame.new(0, 5, 0) * CFrame.Angles(0, math.rad(45), 0), Color = Color3.fromRGB(190, 160, 255), Material = Enum.Material.Neon, Transparency = 0.2 })
	light(c, Color3.fromRGB(190, 160, 255), 16)
end

B.Teleskop = function(m)
	for i = 0, 2 do
		local a = i / 3 * math.pi * 2
		P(m, { Size = Vector3.new(0.3, 4.4, 0.3), At = CFrame.new(math.cos(a) * 0.9, 2, math.sin(a) * 0.9) * CFrame.Angles(math.sin(a) * 0.35, 0, -math.cos(a) * 0.35), Color = DARKWOOD, Material = Enum.Material.Wood })
	end
	P(m, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, 1, 1), At = CFrame.new(0, 4.6, 0) * CFrame.Angles(0, math.rad(90), math.rad(35)), Color = BRASS, Material = Enum.Material.Metal })
	P(m, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 1.4, 1.4), At = CFrame.new(0, 6, 2) * CFrame.Angles(0, math.rad(90), math.rad(35)), Color = Color3.fromRGB(150, 205, 255), Material = Enum.Material.Neon })
end

B.Koralle = function(m)
	local colors = { Color3.fromRGB(255, 130, 160), Color3.fromRGB(255, 180, 110), Color3.fromRGB(200, 140, 255) }
	cyl(m, Vector3.zero, 2.4, 0.6, Color3.fromRGB(240, 225, 190), Enum.Material.Sand)
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2
		local h = 2 + (i % 3)
		local base = Vector3.new(math.cos(a) * 1.2, 0.6, math.sin(a) * 1.2)
		P(m, { Size = Vector3.new(0.5, h, 0.5), At = CFrame.new(base + Vector3.new(0, h / 2, 0)) * CFrame.Angles(math.sin(a) * 0.4, 0, -math.cos(a) * 0.4), Color = colors[i % 3 + 1] })
		ball(m, base + Vector3.new(math.cos(a) * h * 0.38, h, math.sin(a) * h * 0.38), Vector3.new(0.9, 0.9, 0.9), colors[(i + 1) % 3 + 1])
	end
end

B.Pokal = function(m, _fp, item)
	box(m, Vector3.zero, Vector3.new(2.6, 1.4, 2.6), DARKWOOD, Enum.Material.Wood)
	local plate = box(m, Vector3.new(0, 0.3, -1.32), Vector3.new(2.2, 0.8, 0.1), BRASS, Enum.Material.Metal)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(70, 50, 35)
	label.Text = (string.gsub(item and item.Name or "Pokal", "%-Pokal$", ""))
	label.Parent = gui
	gui.Parent = plate
	local gold = Color3.fromRGB(255, 205, 60)
	cyl(m, Vector3.new(0, 1.4, 0), 0.8, 0.4, gold, Enum.Material.Metal)
	cyl(m, Vector3.new(0, 1.8, 0), 0.25, 1.2, gold, Enum.Material.Metal)
	local cup = cyl(m, Vector3.new(0, 3, 0), 1.1, 1.8, gold, Enum.Material.Metal)
	for _, side in { -1, 1 } do
		P(m, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.25, 1.1, 1.1), At = CFrame.new(side * 1.3, 4, 0) * CFrame.Angles(0, math.rad(90), 0), Color = gold, Material = Enum.Material.Metal })
	end
	light(cup, gold, 10)
end

--[[
	Ein Deko-Stück bauen. item = Eintrag aus Deco.Katalog, cellSize = Studs pro Feld.
	Gibt ein Model zurück (Pivot = Boden-Mitte). Unbekannte Modelle werden ein einfacher Block.
]]
function DecoModels.Build(item: any, cellSize: number): Model
	local m = Instance.new("Model")
	m.Name = item.Id
	local fp = (item.Groesse or 1) * cellSize
	local builder = B[item.Modell]
	if builder then
		builder(m, fp, item)
	else
		box(m, Vector3.zero, Vector3.new(fp * 0.8, 2, fp * 0.8), BRASS)
	end
	m.WorldPivot = CFrame.new()
	return m
end

return DecoModels
