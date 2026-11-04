--!strict
--[[
	ObstacleMath: berechnet aus der (virtuellen) Zeit, wo ein Hindernis gerade ist.
	Virtuelle Zeit vt = VTBase + VTScale * (jetzt - VTAt)
	Ohne Attribute gilt vt = jetzt. So laufen Server und alle Clients synchron.
]]
local ObstacleMath = {}

local TAU = math.pi * 2

function ObstacleMath.VirtualTime(inst: Instance, now: number): number
	local at = inst:GetAttribute("VTAt")
	if type(at) ~= "number" then
		return now
	end
	local base = (inst:GetAttribute("VTBase") :: number?) or 0
	local scale = (inst:GetAttribute("VTScale") :: number?) or 1
	return base + scale * (now - at)
end

function ObstacleMath.Scale(inst: Instance): number
	return (inst:GetAttribute("VTScale") :: number?) or 1
end

-- Neue Zeitskala setzen, ohne dass das Hindernis springt
function ObstacleMath.Rebase(inst: Instance, now: number, newScale: number)
	local vt = ObstacleMath.VirtualTime(inst, now)
	inst:SetAttribute("VTBase", vt)
	inst:SetAttribute("VTAt", now)
	inst:SetAttribute("VTScale", newScale)
end

-- Pose (CFrame) für bewegte Hindernisse
function ObstacleMath.Pose(kind: string, base: CFrame, attrs: { [string]: any }, vt: number): CFrame
	local phase = attrs.Phase or 0
	if kind == "Spin" then
		local axis: Vector3 = attrs.Axis or Vector3.yAxis
		return base * CFrame.fromAxisAngle(axis, (attrs.Speed or 1) * vt + phase)
	elseif kind == "Swing" then
		local axis: Vector3 = attrs.Axis or Vector3.zAxis
		local period = attrs.Period or 3
		return base * CFrame.fromAxisAngle(axis, (attrs.Amp or 1) * math.sin(TAU * vt / period + phase))
	elseif kind == "Slide" then
		local period = attrs.Period or 4
		local offset: Vector3 = attrs.Offset or Vector3.zero
		local t = 0.5 - 0.5 * math.cos(TAU * vt / period + phase)
		return base + base:VectorToWorldSpace(offset * t)
	elseif kind == "Wobble" then
		local period = attrs.Period or 3
		local amp = attrs.Amp or 0.2
		local w = TAU * vt / period + phase
		return base * CFrame.Angles(amp * math.sin(w), 0, amp * 0.7 * math.sin(w * 0.73 + 1.3))
	end
	return base
end

-- Takt-Hindernisse: ist es gerade "an"? Zweiter Wert: kurz vor dem Ausgehen (Warnblinken)
function ObstacleMath.Blink(attrs: { [string]: any }, vt: number): (boolean, boolean)
	local period = attrs.Period or 3
	local onTime = attrs.OnTime or period * 0.6
	local t = (vt + (attrs.Phase or 0)) % period
	local on = t < onTime
	local warn = on and t > onTime - math.min(0.7, onTime * 0.35)
	return on, warn
end

return ObstacleMath
