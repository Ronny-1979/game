--!strict
--[[
	Backdrop: große Kulissen weit hinter den Inseln – damit jede Zone wie ein riesiges Uhrwerk wirkt.
	- Riesen-Uhr mit drehenden Zeigern hinter der Boss-Arena
	- Riesen-Zahnräder, die sich langsam drehen
	- Zonen-Extras: Blumen (Wiese), Schornsteine mit Dampf (Werkstatt), Felsnadeln + Pendel (Schlucht),
	  Kristalltürme (Kristall), Riesen-Pendel (Uhrwerk), Planeten (Sternwarte), Seetang + Blasen (Tiefsee)
	Alles ohne Kollision und ohne Schatten. Bewegung macht der Client (Tag "Obstacle", Range = Sichtweite).
]]
local Parts = require(script.Parent:WaitForChild("Parts"))

local Backdrop = {}

local RANGE = 1500 -- so weit weg drehen sich die Kulissen noch
local BRASS = Color3.fromRGB(215, 170, 80)
local COPPER = Color3.fromRGB(200, 120, 75)
local CREAM = Color3.fromRGB(255, 248, 230)

local function deco(props: { [string]: any }): BasePart
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	props.CastShadow = false
	return Parts.Part(props)
end

-- Riesen-Zahnrad (wenige große Zähne, damit es schnell bleibt)
local function bigGear(parent: Instance, cf: CFrame, radius: number, color: Color3, speed: number)
	local m = Parts.Obstacle(parent, "RiesenZahnrad", "Spin", cf, { Axis = Vector3.yAxis, Speed = speed, Phase = 0, Range = RANGE })
	local thick = math.max(3, radius * 0.12)
	deco({ Name = "Scheibe", Shape = Enum.PartType.Cylinder, Size = Vector3.new(thick, radius * 2, radius * 2), CFrame = cf * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = Enum.Material.Metal, Parent = m })
	deco({ Name = "Nabe", Shape = Enum.PartType.Cylinder, Size = Vector3.new(thick * 1.6, radius * 0.5, radius * 0.5), CFrame = cf * CFrame.Angles(0, 0, math.rad(90)), Color = color:Lerp(Color3.new(0, 0, 0), 0.2), Material = Enum.Material.Metal, Parent = m })
	local teeth = math.clamp(math.floor(radius / 3), 10, 22)
	for i = 1, teeth do
		local a = i / teeth * math.pi * 2
		deco({
			Name = "Zahn",
			Size = Vector3.new(radius * 2 * math.pi / teeth * 0.5, thick, radius * 0.18),
			CFrame = cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -(radius + radius * 0.08)),
			Color = color:Lerp(Color3.new(0, 0, 0), 0.1),
			Material = Enum.Material.Metal,
			Parent = m,
		})
	end
	-- Speichen-Löcher als dunkle Kreise (wirkt mechanischer)
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2
		deco({
			Name = "Loch",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(thick + 0.4, radius * 0.38, radius * 0.38),
			CFrame = cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -radius * 0.55) * CFrame.Angles(0, 0, math.rad(90)),
			Color = color:Lerp(Color3.new(0, 0, 0), 0.45),
			Material = Enum.Material.Metal,
			Parent = m,
		})
	end
end

-- Riesen-Uhr, schaut in Richtung "look"
local function bigClock(parent: Instance, center: Vector3, look: Vector3, radius: number, rim: Color3)
	local cf = CFrame.lookAt(center, center + look)
	deco({ Name = "Zifferblatt", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, radius * 2, radius * 2), CFrame = cf * CFrame.Angles(0, math.rad(90), 0), Color = CREAM, Material = Enum.Material.SmoothPlastic, Parent = parent })
	deco({ Name = "Uhrrand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.6, radius * 2 + 8, radius * 2 + 8), CFrame = cf * CFrame.new(0, 0, 1) * CFrame.Angles(0, math.rad(90), 0), Color = rim, Material = Enum.Material.Metal, Parent = parent })
	-- Stundenstriche
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		local big = i % 3 == 0
		deco({
			Name = "Strich",
			Size = Vector3.new(if big then radius * 0.07 else radius * 0.04, radius * (if big then 0.18 else 0.11), 1),
			CFrame = cf * CFrame.Angles(0, 0, -a) * CFrame.new(0, radius * 0.82, -1.8),
			Color = Color3.fromRGB(70, 55, 45),
			Parent = parent,
		})
	end
	-- Zeiger drehen sich um die Blick-Achse (lokal Z)
	local pivot = cf * CFrame.new(0, 0, -2.2)
	local hour = Parts.Obstacle(parent, "RiesenStundenzeiger", "Spin", pivot, { Axis = Vector3.zAxis, Speed = -0.02, Phase = 1, Range = RANGE })
	deco({ Name = "Zeiger", Size = Vector3.new(radius * 0.07, radius * 0.5, 1), CFrame = pivot * CFrame.new(0, radius * 0.22, 0), Color = Color3.fromRGB(60, 45, 35), Parent = hour })
	local minute = Parts.Obstacle(parent, "RiesenMinutenzeiger", "Spin", pivot * CFrame.new(0, 0, -1), { Axis = Vector3.zAxis, Speed = -0.12, Phase = 3, Range = RANGE })
	deco({ Name = "Zeiger", Size = Vector3.new(radius * 0.045, radius * 0.75, 1), CFrame = pivot * CFrame.new(0, radius * 0.34, -1), Color = COPPER, Parent = minute })
	deco({ Name = "Mitte", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, radius * 0.12, radius * 0.12), CFrame = pivot * CFrame.new(0, 0, -1.5) * CFrame.Angles(0, math.rad(90), 0), Color = BRASS, Material = Enum.Material.Metal, Parent = parent })
end

local function smoke(part: BasePart, color: Color3, size: number)
	local p = Instance.new("ParticleEmitter")
	p.Rate = 6
	p.Lifetime = NumberRange.new(5, 8)
	p.Speed = NumberRange.new(8, 14)
	p.SpreadAngle = Vector2.new(12, 12)
	p.Acceleration = Vector3.new(2, 1, 0)
	p.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.4), NumberSequenceKeypoint.new(1, size * 1.6) })
	p.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	p.Color = ColorSequence.new(color)
	p.Rotation = NumberRange.new(0, 360)
	p.RotSpeed = NumberRange.new(-20, 20)
	p.LightInfluence = 0.6
	p.Parent = part
end

-- ===== Zonen-Extras =====

local Extras: { [string]: (Instance, Vector3, any, Random) -> () } = {}

-- 🌼 Wiese: Riesen-Blumen mit Zahnrad-Blüten
Extras.Wiese = function(f, O, C, rng)
	for i = 1, 6 do
		local base = O + Vector3.new(rng:NextNumber(-520, 520), -40, rng:NextNumber(-560, -380))
		local h = rng:NextNumber(90, 150)
		deco({ Name = "Stiel", Size = Vector3.new(4, h, 4), CFrame = CFrame.new(base + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, rng:NextNumber(-0.08, 0.08)), Color = Color3.fromRGB(120, 190, 100), Material = Enum.Material.Grass, Parent = f })
		local top = base + Vector3.new(0, h, 0)
		bigGear(f, CFrame.new(top) * CFrame.Angles(math.rad(90), 0, 0), rng:NextNumber(14, 22), C.Deko:Lerp(Color3.fromRGB(255, 200, 220), i * 0.1), if i % 2 == 0 then 0.1 else -0.1)
		deco({ Name = "Bluetenmitte", Shape = Enum.PartType.Ball, Size = Vector3.new(10, 10, 6), CFrame = CFrame.new(top + Vector3.new(0, 0, 2)), Color = Color3.fromRGB(255, 225, 110), Material = Enum.Material.Neon, Parent = f })
	end
end

-- 🔧 Werkstatt: Schornsteine mit Dampf und Rohre
Extras.Werkstatt = function(f, O, C, rng)
	for i = 1, 5 do
		local base = O + Vector3.new(-480 + i * 160 + rng:NextNumber(-30, 30), -60, rng:NextNumber(-520, -420))
		local h = rng:NextNumber(150, 220)
		deco({ Name = "Schornstein", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 18, 18), CFrame = CFrame.new(base + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(190, 110, 80), Material = Enum.Material.Brick, Parent = f })
		local rimPart = deco({ Name = "Schornsteinrand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 22, 22), CFrame = CFrame.new(base + Vector3.new(0, h, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = C.Akzent, Material = Enum.Material.Metal, Parent = f })
		smoke(rimPart, Color3.fromRGB(240, 235, 235), 18)
	end
	-- dicke Rohre zwischen den Schornsteinen
	for i = 1, 3 do
		local y = rng:NextNumber(20, 70)
		deco({ Name = "Rohr", Shape = Enum.PartType.Cylinder, Size = Vector3.new(700, 8, 8), CFrame = CFrame.new(O + Vector3.new(0, y, -470 - i * 18)), Color = C.Akzent:Lerp(COPPER, 0.5), Material = Enum.Material.Metal, Parent = f })
	end
end

-- 🌉 Schlucht: Felsnadeln mit schwingendem Riesen-Pendel
Extras.Schlucht = function(f, O, C, rng)
	for _, side in { -1, 1 } do
		local base = O + Vector3.new(side * 330, -120, -470)
		deco({ Name = "Felsnadel", Size = Vector3.new(60, 340, 60), CFrame = CFrame.new(base + Vector3.new(0, 170, 0)) * CFrame.Angles(0, rng:NextNumber(0, 1), 0), Color = Color3.fromRGB(150, 135, 175), Material = Enum.Material.Slate, Parent = f })
	end
	deco({ Name = "Pendelbalken", Size = Vector3.new(700, 14, 14), CFrame = CFrame.new(O + Vector3.new(0, 215, -470)), Color = C.Akzent, Material = Enum.Material.Metal, Parent = f })
	local pivot = CFrame.new(O + Vector3.new(0, 210, -470))
	local m = Parts.Obstacle(f, "RiesenPendel", "Swing", pivot, { Axis = Vector3.zAxis, Amp = 0.45, Period = 9, Phase = 0, Range = RANGE })
	deco({ Name = "Stange", Size = Vector3.new(4, 200, 4), CFrame = pivot * CFrame.new(0, -100, 0), Color = C.Akzent, Material = Enum.Material.Metal, Parent = m })
	deco({ Name = "Gewicht", Shape = Enum.PartType.Cylinder, Size = Vector3.new(10, 50, 50), CFrame = pivot * CFrame.new(0, -205, 0) * CFrame.Angles(0, math.rad(90), 0), Color = BRASS, Material = Enum.Material.Metal, Parent = m })
end

-- 💎 Kristall: leuchtende Kristalltürme
Extras.Kristall = function(f, O, C, rng)
	for i = 1, 9 do
		local base = O + Vector3.new(rng:NextNumber(-560, 560), -80, rng:NextNumber(-580, -380))
		local h = rng:NextNumber(110, 220)
		local w = rng:NextNumber(18, 34)
		local color = (if i % 2 == 0 then C.Deko else C.Akzent):Lerp(Color3.fromRGB(200, 240, 255), 0.4)
		local c = deco({
			Name = "Kristallturm",
			Size = Vector3.new(w, h, w),
			CFrame = CFrame.new(base + Vector3.new(0, h / 2, 0)) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), rng:NextNumber(0, 1.5), rng:NextNumber(-0.15, 0.15)),
			Color = color,
			Material = Enum.Material.Neon,
			Transparency = 0.25,
			Parent = f,
		})
		if i % 3 == 0 then
			local light = Instance.new("PointLight")
			light.Color = color
			light.Range = 60
			light.Brightness = 1
			light.Parent = c
		end
	end
end

-- 🕰️ Uhrwerk: Riesen-Pendel und zusätzliche Zahnräder
Extras.Uhrwerk = function(f, O, C, rng)
	local pivot = CFrame.new(O + Vector3.new(-380, 230, -430))
	local m = Parts.Obstacle(f, "UnruhPendel", "Swing", pivot, { Axis = Vector3.zAxis, Amp = 0.35, Period = 7, Phase = 0, Range = RANGE })
	deco({ Name = "Stange", Size = Vector3.new(5, 220, 5), CFrame = pivot * CFrame.new(0, -110, 0), Color = C.Akzent, Material = Enum.Material.Metal, Parent = m })
	deco({ Name = "Gewicht", Shape = Enum.PartType.Cylinder, Size = Vector3.new(12, 60, 60), CFrame = pivot * CFrame.new(0, -225, 0) * CFrame.Angles(0, math.rad(90), 0), Color = BRASS, Material = Enum.Material.Metal, Parent = m })
	for i = 1, 3 do
		bigGear(f, CFrame.new(O + Vector3.new(380 + rng:NextNumber(-40, 40), 60 + i * 60, -420 - i * 30)) * CFrame.Angles(math.rad(90), 0, 0), 35 - i * 6, if i % 2 == 0 then BRASS else COPPER, if i % 2 == 0 then 0.15 else -0.2)
	end
end

-- 🔭 Sternwarte: Planeten mit Ringen
Extras.Sternwarte = function(f, O, C, rng)
	local colors = { Color3.fromRGB(255, 180, 130), Color3.fromRGB(160, 200, 255), Color3.fromRGB(220, 170, 255), Color3.fromRGB(255, 225, 140) }
	for i = 1, 4 do
		local pos = O + Vector3.new(rng:NextNumber(-600, 600), rng:NextNumber(140, 300), rng:NextNumber(-650, -420))
		local r = rng:NextNumber(30, 70)
		deco({ Name = "Planet", Shape = Enum.PartType.Ball, Size = Vector3.new(r * 2, r * 2, r * 2), CFrame = CFrame.new(pos), Color = colors[i], Material = Enum.Material.SmoothPlastic, Parent = f })
		if i % 2 == 1 then
			local ring = Parts.Obstacle(f, "PlanetRing", "Spin", CFrame.new(pos) * CFrame.Angles(rng:NextNumber(0.2, 0.5), 0, rng:NextNumber(-0.3, 0.3)), { Axis = Vector3.yAxis, Speed = 0.05, Phase = 0, Range = RANGE })
			deco({ Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.5, r * 3.4, r * 3.4), CFrame = CFrame.new(pos) * CFrame.Angles(rng:NextNumber(0.2, 0.5), 0, math.rad(90)), Color = Color3.fromRGB(255, 240, 200), Material = Enum.Material.Neon, Transparency = 0.45, Parent = ring })
		end
	end
	-- kleine Sternwarte-Kuppel auf einem Felsen
	local base = O + Vector3.new(-430, 40, -260)
	deco({ Name = "Felsen", Shape = Enum.PartType.Ball, Size = Vector3.new(70, 60, 70), CFrame = CFrame.new(base - Vector3.new(0, 30, 0)), Color = Color3.fromRGB(95, 90, 130), Material = Enum.Material.Slate, Parent = f })
	deco({ Name = "Turm", Shape = Enum.PartType.Cylinder, Size = Vector3.new(24, 30, 30), CFrame = CFrame.new(base + Vector3.new(0, 10, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = CREAM, Material = Enum.Material.Brick, Parent = f })
	deco({ Name = "Kuppel", Shape = Enum.PartType.Ball, Size = Vector3.new(30, 30, 30), CFrame = CFrame.new(base + Vector3.new(0, 22, 0)), Color = Color3.fromRGB(200, 205, 230), Material = Enum.Material.Metal, Parent = f })
	deco({ Name = "Fernrohr", Shape = Enum.PartType.Cylinder, Size = Vector3.new(26, 5, 5), CFrame = CFrame.new(base + Vector3.new(6, 32, 4)) * CFrame.Angles(0, math.rad(30), math.rad(40)), Color = BRASS, Material = Enum.Material.Metal, Parent = f })
end

-- 🫧 Tiefsee: Seetang, Blasen und Lichtstrahlen
Extras.Tiefsee = function(f, O, C, rng)
	for i = 1, 14 do
		local base = O + Vector3.new(rng:NextNumber(-600, 600), -150, rng:NextNumber(-600, -300))
		local h = rng:NextNumber(160, 260)
		local pivot = CFrame.new(base)
		local m = Parts.Obstacle(f, "Seetang", "Wobble", pivot, { Period = rng:NextNumber(6, 9), Amp = 0.06, Phase = i, Range = RANGE })
		local segs = 4
		for s = 1, segs do
			deco({
				Name = "Tang",
				Size = Vector3.new(6, h / segs + 2, 2),
				CFrame = pivot * CFrame.new(math.sin(s * 1.3 + i) * 4, (s - 0.5) * h / segs, 0) * CFrame.Angles(0, 0, math.sin(s + i) * 0.1),
				Color = Color3.fromRGB(80, 170, 120):Lerp(Color3.fromRGB(140, 220, 150), s / segs),
				Material = Enum.Material.Grass,
				Parent = m,
			})
		end
	end
	-- aufsteigende Blasen unter den Inseln
	for _ = 1, 6 do
		local emitterPart = deco({ Name = "Blasenquelle", Size = Vector3.new(60, 1, 60), CFrame = CFrame.new(O + Vector3.new(rng:NextNumber(-260, 260), -60, rng:NextNumber(-300, 200))), Transparency = 1, Parent = f })
		local p = Instance.new("ParticleEmitter")
		p.Rate = 5
		p.Lifetime = NumberRange.new(8, 12)
		p.Speed = NumberRange.new(6, 10)
		p.EmissionDirection = Enum.NormalId.Top
		p.SpreadAngle = Vector2.new(10, 10)
		p.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1.6) })
		p.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.8, 0.5), NumberSequenceKeypoint.new(1, 1) })
		p.Color = ColorSequence.new(Color3.fromRGB(220, 250, 255))
		p.LightEmission = 0.5
		p.Parent = emitterPart
	end
	-- Lichtstrahlen von oben (schräge, durchsichtige Säulen)
	for i = 1, 5 do
		deco({
			Name = "Lichtstrahl",
			Size = Vector3.new(30, 500, 6),
			CFrame = CFrame.new(O + Vector3.new(-400 + i * 150, 120, rng:NextNumber(-250, 150))) * CFrame.Angles(0, rng:NextNumber(0, 3), math.rad(18)),
			Color = Color3.fromRGB(220, 255, 250),
			Material = Enum.Material.Neon,
			Transparency = 0.93,
			Parent = f,
		})
	end
end

-- Kulisse für Zone i (Mitte O, Konfig zone)
function Backdrop.Zone(parent: Instance, index: number, zone: any, O: Vector3)
	local f = Parts.Folder("Kulisse", parent)
	local rng = Random.new(index * 777)
	local C = zone.Farben
	bigClock(f, O + Vector3.new(0, 95, -600), Vector3.new(0, 0, 1), 95, C.Akzent)
	-- Zahnräder links und rechts hinten, teils ineinander
	bigGear(f, CFrame.new(O + Vector3.new(-250, 50, -540)) * CFrame.Angles(math.rad(90), 0, 0), 60, C.Akzent, 0.08)
	bigGear(f, CFrame.new(O + Vector3.new(-160, 150, -560)) * CFrame.Angles(math.rad(90), 0, 0), 34, COPPER, -0.14)
	bigGear(f, CFrame.new(O + Vector3.new(260, 30, -520)) * CFrame.Angles(math.rad(90), 0, 0), 52, BRASS, -0.09)
	bigGear(f, CFrame.new(O + Vector3.new(560, 70, -260)) * CFrame.Angles(math.rad(90), math.rad(70), 0), 70, C.Akzent:Lerp(BRASS, 0.5), 0.06)
	bigGear(f, CFrame.new(O + Vector3.new(-580, 40, -200)) * CFrame.Angles(math.rad(90), math.rad(-70), 0), 64, COPPER:Lerp(C.Akzent, 0.4), -0.07)
	local extra = Extras[zone.Id]
	if extra then
		extra(f, O, C, rng)
	end
end

-- Kulisse hinter dem Hub
function Backdrop.Hub(parent: Instance, H: Vector3)
	local f = Parts.Folder("Kulisse", parent)
	bigClock(f, H + Vector3.new(0, 110, -460), Vector3.new(0, 0, 1), 110, BRASS)
	bigGear(f, CFrame.new(H + Vector3.new(-300, 60, -400)) * CFrame.Angles(math.rad(90), 0, 0), 70, COPPER, 0.07)
	bigGear(f, CFrame.new(H + Vector3.new(300, 80, -380)) * CFrame.Angles(math.rad(90), 0, 0), 60, BRASS, -0.08)
	bigGear(f, CFrame.new(H + Vector3.new(-190, 190, -430)) * CFrame.Angles(math.rad(90), 0, 0), 36, BRASS, -0.15)
end

return Backdrop
