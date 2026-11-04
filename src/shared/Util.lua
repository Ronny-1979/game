--!strict
-- Kleine Helfer, die überall gebraucht werden
local Util = {}

local SUFFIXES = { "", "K", "Mio", "Mrd", "Bio", "Brd", "Trio" }

-- 1234567 → "1,23 Mio"
function Util.FormatNumber(n: number): string
	n = math.floor(n + 0.5)
	if math.abs(n) < 1000 then
		return tostring(n)
	end
	local i = 1
	local v = n
	while math.abs(v) >= 1000 and i < #SUFFIXES do
		v /= 1000
		i += 1
	end
	local text = if math.abs(v) >= 100 then string.format("%.0f", v) else string.format("%.2f", v)
	text = string.gsub(text, "%.", ",")
	return text .. " " .. SUFFIXES[i]
end

-- 83.456 → "1:23,45"
function Util.FormatTime(seconds: number): string
	if seconds ~= seconds or seconds == math.huge then
		return "--:--"
	end
	local m = math.floor(seconds / 60)
	local s = seconds - m * 60
	local text = string.format("%d:%05.2f", m, s)
	return (string.gsub(text, "%.", ","))
end

function Util.DeepCopy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in value :: any do
		out[Util.DeepCopy(k)] = Util.DeepCopy(v)
	end
	return out :: any
end

-- Fehlende Felder aus der Vorlage ergänzen (vorhandene bleiben)
function Util.Reconcile(target: { [any]: any }, template: { [any]: any })
	for k, v in template do
		if target[k] == nil then
			target[k] = Util.DeepCopy(v)
		elseif type(v) == "table" and type(target[k]) == "table" and next(v) ~= nil and #v == 0 then
			-- nur Wörterbücher rekursiv ergänzen, keine Listen
			Util.Reconcile(target[k], v)
		end
	end
end

-- Gewichteter Zufall: { A = 10, B = 1 } → "A" (meistens)
function Util.WeightedPick(weights: { [string]: number }, rng: Random?): string?
	local total = 0
	local keys = {}
	for k, w in weights do
		total += w
		table.insert(keys, k)
	end
	table.sort(keys) -- feste Reihenfolge, damit der Zufall nachvollziehbar bleibt
	if total <= 0 then
		return nil
	end
	local r = if rng then rng:NextNumber() * total else math.random() * total
	for _, k in keys do
		r -= weights[k]
		if r <= 0 then
			return k
		end
	end
	return keys[#keys]
end

function Util.Chances(weights: { [string]: number }): { { Id: string, Prozent: number } }
	local total = 0
	for _, w in weights do
		total += w
	end
	local list = {}
	for k, w in weights do
		table.insert(list, { Id = k, Prozent = if total > 0 then w / total * 100 else 0 })
	end
	table.sort(list, function(a, b)
		return a.Prozent > b.Prozent
	end)
	return list
end

function Util.IsFiniteNumber(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

function Util.IsFiniteVector(v: any): boolean
	return typeof(v) == "Vector3" and Util.IsFiniteNumber(v.X) and Util.IsFiniteNumber(v.Y) and Util.IsFiniteNumber(v.Z)
end

function Util.Count(t: { [any]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

-- Spieler zu einem Teil finden (z.B. bei Touched)
function Util.PlayerFromPart(part: Instance): Player?
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		local plr = game:GetService("Players"):GetPlayerFromCharacter(model)
		if plr then
			return plr
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

function Util.Lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

return Util
