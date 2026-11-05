--!strict
--[[
	Decor: Deko für mehr Gemütlichkeit – Blumen, Gras, Felsen, Büsche, Pilze, Zahnräder,
	Wolken unter den Inseln und kleine schwebende Inseln.
	Alles ohne Kollision (man bleibt nirgends hängen) und ohne Schatten (schont die Leistung).
	Zufall mit festem Startwert → die Deko sieht bei jedem Bauen gleich aus.
]]
local Parts = require(script.Parent:WaitForChild("Parts"))

local Decor = {}

local FLOWER_COLORS = {
	Color3.fromRGB(255, 150, 180),
	Color3.fromRGB(255, 220, 100),
	Color3.fromRGB(180, 150, 255),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 170, 110),
	Color3.fromRGB(140, 210, 255),
}

local function deco(props: { [string]: any }): Part
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	props.CastShadow = false
	return Parts.Part(props)
end

local function flower(parent: Instance, pos: Vector3, rng: Random)
	local h = rng:NextNumber(1, 2)
	deco({ Name = "Stiel", Size = Vector3.new(0.2, h, 0.2), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)), Color = Color3.fromRGB(110, 180, 90), Parent = parent })
	local c = FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)]
	deco({ Name = "Bluete", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.6, 0.9), CFrame = CFrame.new(pos + Vector3.new(0, h + 0.1, 0)), Color = c, Parent = parent })
	deco({ Name = "Mitte", Shape = Enum.PartType.Ball, Size = Vector3.new(0.35, 0.35, 0.35), CFrame = CFrame.new(pos + Vector3.new(0, h + 0.3, 0)), Color = Color3.fromRGB(255, 230, 120), Material = Enum.Material.Neon, Parent = parent })
end

local function grass(parent: Instance, pos: Vector3, rng: Random, color: Color3)
	for i = 1, 3 do
		local h = rng:NextNumber(1, 1.8)
		deco({
			Name = "Gras",
			Size = Vector3.new(0.25, h, 0.25),
			CFrame = CFrame.new(pos + Vector3.new((i - 2) * 0.3, h / 2, rng:NextNumber(-0.2, 0.2))) * CFrame.Angles(0, 0, math.rad((i - 2) * 18)),
			Color = color:Lerp(Color3.fromRGB(60, 140, 60), rng:NextNumber(0.1, 0.4)),
			Material = Enum.Material.Grass,
			Parent = parent,
		})
	end
end

local function rock(parent: Instance, pos: Vector3, rng: Random)
	local s = rng:NextNumber(1.5, 4)
	deco({
		Name = "Fels",
		Size = Vector3.new(s, s * 0.7, s * 0.9),
		CFrame = CFrame.new(pos + Vector3.new(0, s * 0.25, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)),
		Color = Color3.fromRGB(175, 165, 155):Lerp(Color3.fromRGB(140, 125, 115), rng:NextNumber()),
		Material = Enum.Material.Slate,
		Parent = parent,
	})
end

local function bush(parent: Instance, pos: Vector3, rng: Random, color: Color3)
	for i = 1, 3 do
		local s = rng:NextNumber(2, 3.4)
		deco({
			Name = "Busch",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(s, s * 0.85, s),
			CFrame = CFrame.new(pos + Vector3.new((i - 2) * 1.2, s * 0.35, rng:NextNumber(-0.6, 0.6))),
			Color = color:Lerp(Color3.fromRGB(80, 160, 80), 0.55 + rng:NextNumber(-0.1, 0.1)),
			Material = Enum.Material.Grass,
			Parent = parent,
		})
	end
	if rng:NextNumber() < 0.5 then
		deco({ Name = "Beere", Shape = Enum.PartType.Ball, Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(pos + Vector3.new(0.6, 1.8, -0.9)), Color = Color3.fromRGB(255, 90, 110), Parent = parent })
	end
end

local function mushroom(parent: Instance, pos: Vector3, rng: Random)
	local h = rng:NextNumber(0.8, 1.6)
	deco({ Name = "PilzStiel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 0.6, 0.6), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(250, 240, 220), Parent = parent })
	deco({
		Name = "PilzHut",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.8, 0.9, 1.8),
		CFrame = CFrame.new(pos + Vector3.new(0, h, 0)),
		Color = if rng:NextNumber() < 0.5 then Color3.fromRGB(240, 90, 90) else Color3.fromRGB(190, 140, 230),
		Parent = parent,
	})
end

local function buriedGear(parent: Instance, pos: Vector3, rng: Random, color: Color3)
	local r = rng:NextNumber(1.5, 3)
	local cf = CFrame.new(pos + Vector3.new(0, r * 0.4, 0)) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, 6), math.rad(90) + rng:NextNumber(-0.25, 0.25))
	local list = Parts.Gear(parent, cf, r, 0.5, 8, color, false)
	for _, p in list do
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
	end
end

--[[
	Deko im Ring zwischen innerR und outerR um center verteilen.
	avoid(rel) = true → an dieser Stelle (relativ zur Mitte) nichts hinstellen
]]
function Decor.Scatter(parent: Instance, center: Vector3, innerR: number, outerR: number, count: number, colors: any, seed: number, avoid: ((Vector3) -> boolean)?)
	local folder = Parts.Folder("Deko", parent)
	local rng = Random.new(seed)
	local placed = 0
	local tries = 0
	while placed < count and tries < count * 4 do
		tries += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber(innerR * innerR, outerR * outerR))
		local rel = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		if not avoid or not avoid(rel) then
			placed += 1
			local pos = center + rel
			local roll = rng:NextNumber()
			if roll < 0.32 then
				flower(folder, pos, rng)
			elseif roll < 0.55 then
				grass(folder, pos, rng, colors.Boden)
			elseif roll < 0.68 then
				rock(folder, pos, rng)
			elseif roll < 0.82 then
				bush(folder, pos, rng, colors.Boden)
			elseif roll < 0.92 then
				mushroom(folder, pos, rng)
			else
				buriedGear(folder, pos, rng, colors.Akzent)
			end
		end
	end
end

-- Weiche Wolken unter einer Insel
function Decor.Clouds(parent: Instance, center: Vector3, radius: number, seed: number)
	local rng = Random.new(seed)
	local folder = Parts.Folder("Wolken", parent)
	for _ = 1, math.clamp(math.floor(radius / 12), 3, 10) do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(radius * 0.3, radius * 1.1)
		local base = center + Vector3.new(math.cos(a) * d, -rng:NextNumber(14, 30), math.sin(a) * d)
		for i = 1, 3 do
			local s = rng:NextNumber(10, 20)
			deco({
				Name = "Wolke",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(s * 1.6, s * 0.8, s * 1.2),
				CFrame = CFrame.new(base + Vector3.new((i - 2) * s * 0.7, rng:NextNumber(-2, 2), rng:NextNumber(-3, 3))),
				Color = Color3.fromRGB(255, 252, 250),
				Material = Enum.Material.SmoothPlastic,
				Transparency = 0.25,
				Parent = folder,
			})
		end
	end
end

-- Kleine schwebende Inseln mit Baum, Kristall oder Zahnrad
function Decor.FloatingIslands(parent: Instance, center: Vector3, ringR: number, count: number, colors: any, seed: number, avoid: ((Vector3) -> boolean)?)
	local rng = Random.new(seed)
	local folder = Parts.Folder("SchwebeInseln", parent)
	for i = 1, count do
		local a = (i / count) * math.pi * 2 + rng:NextNumber(-0.25, 0.25)
		local r = ringR * rng:NextNumber(0.85, 1.15)
		local top = center + Vector3.new(math.cos(a) * r, rng:NextNumber(-25, 40), math.sin(a) * r)
		local size = rng:NextNumber(7, 14)
		if avoid and avoid(top - center) then
			continue
		end
		deco({ Name = "MiniInsel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.5, size * 2, size * 2), CFrame = CFrame.new(top - Vector3.new(0, 1.25, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = colors.Boden, Material = Enum.Material.Grass, Parent = folder })
		deco({ Name = "MiniFels", Shape = Enum.PartType.Ball, Size = Vector3.new(size * 1.6, size * 1.4, size * 1.6), CFrame = CFrame.new(top - Vector3.new(0, size * 0.7, 0)), Color = Color3.fromRGB(170, 145, 125), Material = Enum.Material.Slate, Parent = folder })
		local kind = rng:NextInteger(1, 3)
		if kind == 1 then
			deco({ Name = "Stamm", Size = Vector3.new(1.2, 6, 1.2), CFrame = CFrame.new(top + Vector3.new(0, 3, 0)), Color = Color3.fromRGB(150, 105, 70), Material = Enum.Material.Wood, Parent = folder })
			deco({ Name = "Krone", Shape = Enum.PartType.Ball, Size = Vector3.new(7, 6, 7), CFrame = CFrame.new(top + Vector3.new(0, 7.5, 0)), Color = colors.Deko:Lerp(Color3.fromRGB(150, 220, 140), 0.5), Material = Enum.Material.Grass, Parent = folder })
		elseif kind == 2 then
			deco({ Name = "Kristall", Size = Vector3.new(2.5, 7, 2.5), CFrame = CFrame.new(top + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), math.rad(10)), Color = colors.Deko, Material = Enum.Material.Neon, Transparency = 0.2, Parent = folder })
		else
			local list = Parts.Gear(folder, CFrame.new(top + Vector3.new(0, 4, 0)) * CFrame.Angles(math.rad(90), rng:NextNumber(0, 6), 0), 3.5, 0.8, 10, colors.Akzent, false)
			for _, p in list do
				p.CanQuery = false
				p.CastShadow = false
			end
		end
		for _ = 1, 3 do
			flower(folder, top + Vector3.new(rng:NextNumber(-size * 0.6, size * 0.6), 0, rng:NextNumber(-size * 0.6, size * 0.6)), rng)
		end
	end
end

return Decor
