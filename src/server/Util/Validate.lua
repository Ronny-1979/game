--!strict
-- Prüf-Helfer für alles, was vom Client kommt
local Validate = {}

function Validate.String(v: any, maxLen: number): boolean
	return type(v) == "string" and #v > 0 and #v <= maxLen
end

function Validate.Int(v: any, min: number, max: number): boolean
	return type(v) == "number" and v == v and v % 1 == 0 and v >= min and v <= max
end

function Validate.Number(v: any, min: number, max: number): boolean
	return type(v) == "number" and v == v and v >= min and v <= max
end

function Validate.Vector(v: any, maxMagnitude: number): boolean
	if typeof(v) ~= "Vector3" then
		return false
	end
	local m = v.Magnitude
	return m == m and m <= maxMagnitude
end

-- Ist der Schlüssel in der Tabelle vorhanden?
function Validate.Key(v: any, t: { [any]: any }): boolean
	return type(v) == "string" and t[v] ~= nil
end

-- Lebt der Charakter? Gibt (root, humanoid) zurück
function Validate.Alive(player: Player): (BasePart?, Humanoid?)
	local char = player.Character
	if not char then
		return nil, nil
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or hum.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil, nil
	end
	return root, hum
end

-- Ist der Spieler nah genug an einer Position?
function Validate.Near(player: Player, pos: Vector3, maxDist: number): boolean
	local root = Validate.Alive(player)
	return root ~= nil and (root.Position - pos).Magnitude <= maxDist
end

return Validate
