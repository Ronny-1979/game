--!strict
--[[
	TrackBuilder: baut eine Bahn (Leicht/Normal/Profi) einer Strecke – deterministisch.
	Gleicher Seed = gleiche Strecke. Start → Abschnitte (Hindernisse) → Checkpoints → Ziel.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Difficulty = require(Config:WaitForChild("Difficulty")) :: any
local Tags = require(Shared:WaitForChild("Tags"))
local Progression = require(Shared:WaitForChild("Progression"))
local Parts = require(script.Parent:WaitForChild("Parts"))
local Obstacles = require(script.Parent:WaitForChild("Obstacles"))

local TrackBuilder = {}

local THICK = Obstacles.THICK

export type LaneOptions = {
	ZoneIndex: number,
	TrackIndex: number,
	Track: any,
	Diff: string,
	LaneX: number,
	StartZ: number,
	Y: number,
	Colors: any,
	F: number,
	Hints: boolean,
	Seed: number,
	Turbo: number?,
}

-- Hindernis-Reihenfolge: gemischte Kopien der Liste, keine direkte Wiederholung
local function makeOrder(kinds: { string }, count: number, rng: Random): { string }
	local order = {}
	while #order < count do
		local copy = table.clone(kinds)
		for i = #copy, 2, -1 do
			local j = rng:NextInteger(1, i)
			copy[i], copy[j] = copy[j], copy[i]
		end
		if #order > 0 and #copy > 1 and copy[1] == order[#order] then
			copy[1], copy[2] = copy[2], copy[1]
		end
		for _, k in copy do
			if #order < count then
				table.insert(order, k)
			end
		end
	end
	return order
end

local function checkpoint(ctx: any, cur: Vector3, key: string, diff: string, index: number, color: Color3): Vector3
	local gap = math.min(Obstacles.Gap(ctx), 6)
	local top = Vector3.new(ctx.LaneX, cur.Y, cur.Z + gap + 6)
	local pad = Parts.Block(top, Vector3.new(12, THICK, 12), {
		Name = "Checkpoint" .. index,
		Color = color,
		Material = Enum.Material.SmoothPlastic,
		Tags = { Tags.Checkpoint },
		Attrs = { TrackKey = key, Diff = diff, Index = index },
		Parent = ctx.Folder,
	})
	-- Fahne
	local pole = Parts.Part({
		Name = "Fahnenmast",
		Size = Vector3.new(0.5, 8, 0.5),
		CFrame = CFrame.new(top + Vector3.new(5, 4, 5)),
		Color = Color3.fromRGB(230, 200, 140),
		Material = Enum.Material.Metal,
		CanCollide = false,
		Parent = ctx.Folder,
	})
	Parts.Part({
		Name = "Fahne",
		Size = Vector3.new(0.2, 2.2, 3.2),
		CFrame = pole.CFrame * CFrame.new(0, 2.6, -1.7),
		Color = color,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = ctx.Folder,
	})
	Parts.Billboard(pad, "🚩 " .. index, 4, Vector2.new(80, 40))
	if index == 1 then
		Obstacles.Hint(ctx, "Checkpoint", top)
	end
	ctx.LastX = ctx.LaneX
	return Vector3.new(ctx.LaneX, cur.Y, top.Z + 6)
end

function TrackBuilder.BuildLane(parent: Instance, o: LaneOptions): Model
	local P = Difficulty.Stufen[o.Diff]
	local lane = Parts.Model("Bahn_" .. o.Diff, parent)
	local rng = Random.new(o.Seed)
	local turbo = o.Turbo or 1
	local ctx: Obstacles.Ctx = {
		Folder = lane,
		P = P,
		F = o.F,
		Colors = o.Colors,
		Rng = rng,
		LaneX = o.LaneX,
		LastX = o.LaneX,
		StartY = o.Y,
		Size = math.clamp(P.Plattformgroesse * o.F ^ -0.15, Difficulty.MinPlattform, 20),
		Speed = P.Tempo * o.F ^ 0.5 * turbo,
		Takt = P.Takt / o.F ^ 0.3 / turbo,
		Hints = o.Hints and o.Diff == "Leicht",
		HintsShown = {},
	}
	local key = Progression.TrackKey(o.ZoneIndex, o.TrackIndex)

	-- Start
	local startTop = Vector3.new(o.LaneX, o.Y, o.StartZ + 6)
	local start = Parts.Part({
		Name = "Start",
		Size = Vector3.new(12, THICK, 12),
		CFrame = CFrame.lookAt(startTop - Vector3.new(0, THICK / 2, 0), startTop - Vector3.new(0, THICK / 2, 0) + Vector3.zAxis),
		Color = P.Farbe,
		Tags = { Tags.TrackStart },
		Attrs = {
			TrackKey = key,
			Diff = o.Diff,
			ZoneIndex = o.ZoneIndex,
			TrackIndex = o.TrackIndex,
			TrackName = o.Track.Name,
		},
		Parent = lane,
	})
	Parts.Billboard(start, P.Symbol .. " " .. P.Name, 5, Vector2.new(160, 50))
	local cur = Vector3.new(o.LaneX, o.Y, o.StartZ + 12)

	-- Abschnitte
	local order = makeOrder(o.Track.Hindernisse, o.Track.Abschnitte, rng)
	local cp = 0
	local waits = 0
	for s, kind in order do
		waits += Obstacles.WaitEstimate(kind, ctx)
		cur = Obstacles.Build(kind, ctx, cur)
		if s % P.CheckpointAlle == 0 and s < #order then
			cp += 1
			cur = checkpoint(ctx, cur, key, o.Diff, cp, P.Farbe)
		end
	end

	-- Ziel
	local gap = math.min(Obstacles.Gap(ctx), 6)
	local finishTop = Vector3.new(o.LaneX, cur.Y, cur.Z + gap + 9)
	local finish = Parts.Block(finishTop, Vector3.new(18, THICK, 18), {
		Name = "Ziel",
		Color = Color3.fromRGB(255, 215, 90),
		Material = Enum.Material.Metal,
		Tags = { Tags.TrackFinish },
		Attrs = { TrackKey = key, Diff = o.Diff },
		Parent = lane,
	})
	-- Ziel-Bogen
	for _, side in { -1, 1 } do
		Parts.Part({
			Name = "Bogen",
			Size = Vector3.new(1, 12, 1),
			CFrame = CFrame.new(finishTop + Vector3.new(side * 8.5, 6, -8)),
			Color = o.Colors.Akzent,
			Material = Enum.Material.Metal,
			Parent = lane,
		})
	end
	local banner = Parts.Part({
		Name = "Banner",
		Size = Vector3.new(18, 3, 0.6),
		CFrame = CFrame.new(finishTop + Vector3.new(0, 12, -8)),
		Color = Color3.fromRGB(255, 245, 220),
		CanCollide = false,
		Parent = lane,
	})
	Parts.SurfaceText(banner, "🏁 ZIEL 🏁", Enum.NormalId.Front)
	Parts.SurfaceText(banner, "🏁 ZIEL 🏁", Enum.NormalId.Back)
	local back = Parts.Cylinder(finishTop + Vector3.new(5, 0.5, 5), 2.5, 0.5, {
		Name = "Zurueck",
		Color = Color3.fromRGB(150, 200, 255),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Tags = { Tags.ReturnPad },
		Attrs = { ZoneIndex = o.ZoneIndex },
		Parent = lane,
	})
	Parts.Billboard(back, "↩ Zurück zum Platz", 3, Vector2.new(160, 40))

	local length = (finish.Position - start.Position).Magnitude
	start:SetAttribute("CheckpointCount", cp)
	start:SetAttribute("Length", length)
	-- Richtzeit für Zeit-Medaillen: Laufweg (ca. 12 Studs/s mit Springen) + Wartezeiten + kleiner Puffer
	start:SetAttribute("Par", math.floor((length / 12 + waits + cp * 0.8 + 2) * 10 + 0.5) / 10)
	return lane
end

return TrackBuilder
