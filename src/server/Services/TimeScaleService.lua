--!strict
--[[
	TimeScaleService: Zeit-Blasen (Verlangsamen).
	- Gegner und Bosse fragen GetScale(pos) ab.
	- Hindernisse bekommen eine neue virtuelle Zeit (VTBase/VTAt/VTScale), damit sie
	  auf allen Clients gleichzeitig und ohne Sprung langsamer werden.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tags = require(Shared:WaitForChild("Tags"))
local ObstacleMath = require(Shared:WaitForChild("ObstacleMath"))

local TimeScaleService = {}

type Region = { Pos: Vector3, Radius: number, Factor: number, Ends: number }
local regions: { [number]: Region } = {}
local nextId = 0

function TimeScaleService.GetScale(pos: Vector3): number
	local scale = 1
	for _, r in regions do
		if (pos - r.Pos).Magnitude <= r.Radius then
			scale = math.min(scale, r.Factor)
		end
	end
	return scale
end

local function obstaclePos(model: Instance): Vector3?
	if model:IsA("Model") then
		local base = model:GetAttribute("BasePivot")
		if typeof(base) == "CFrame" then
			return base.Position
		end
		return model:GetPivot().Position
	elseif model:IsA("BasePart") then
		return model.Position
	end
	return nil
end

-- Alle Hindernisse in der Nähe von pos neu einstellen
local function refreshAround(pos: Vector3, radius: number)
	local now = workspace:GetServerTimeNow()
	for _, obs in CollectionService:GetTagged(Tags.Obstacle) do
		local p = obstaclePos(obs)
		if p and (p - pos).Magnitude <= radius + 30 then
			local want = TimeScaleService.GetScale(p)
			if math.abs(ObstacleMath.Scale(obs) - want) > 0.001 then
				ObstacleMath.Rebase(obs, now, want)
			end
		end
	end
end

-- Neue Zeit-Blase. duration = nil → bleibt, bis RemoveRegion aufgerufen wird
function TimeScaleService.AddRegion(pos: Vector3, radius: number, factor: number, duration: number?): number
	nextId += 1
	local id = nextId
	regions[id] = { Pos = pos, Radius = radius, Factor = factor, Ends = if duration then os.clock() + duration else math.huge }
	refreshAround(pos, radius)
	if duration then
		task.delay(duration, function()
			TimeScaleService.RemoveRegion(id)
		end)
	end
	return id
end

function TimeScaleService.RemoveRegion(id: number)
	local r = regions[id]
	if not r then
		return
	end
	regions[id] = nil
	refreshAround(r.Pos, r.Radius)
end

function TimeScaleService.Init() end
function TimeScaleService.Start() end

return TimeScaleService
