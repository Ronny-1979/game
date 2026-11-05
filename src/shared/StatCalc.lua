--!strict
--[[
	StatCalc: berechnet alle Werte eines Spielers aus dem Profil.
	Reihenfolge: Grundwerte → Upgrades (Plus) → Klasse + Skills (Plus, dann Mal) → abgeleitete Werte.
]]
local Config = script.Parent:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Upgrades = require(Config:WaitForChild("Upgrades")) :: any
local Classes = require(Config:WaitForChild("Classes")) :: any
local Skills = require(Config:WaitForChild("Skills")) :: any
local Pets = require(Config:WaitForChild("Pets")) :: any
local Deco = require(Config:WaitForChild("Deco")) :: any
local Progression = require(script.Parent:WaitForChild("Progression"))

local StatCalc = {}

-- Liste aller Stats (für Doku und Prüfung)
StatCalc.Names = {
	"WalkSpeed", "JumpPower", "MaxHealth", "ClickPower", "CollectRadius", "FieldEnergy",
	"EnergyMult", "XPMult", "PetPower", "PetSlots", "StompDamage",
	"SlowDuration", "SlowRadius", "SlowFactor", "SlowCooldown", "SlowCost",
	"RewindSeconds", "RewindCooldown", "RewindCost",
	"BoostSpeed", "BoostDuration", "BoostCooldown", "BoostCost",
	"ThrowDamage", "ThrowRange", "ThrowCooldown", "ThrowCost",
	"PlatformDuration", "PlatformSize", "PlatformCooldown", "PlatformCost",
}

local function baseStats(): { [string]: number }
	local A = Skills.Faehigkeiten
	return {
		WalkSpeed = Settings.Player.WalkSpeed,
		JumpPower = Settings.Player.JumpPower,
		MaxHealth = Settings.Player.MaxHealth,
		ClickPower = 1,
		CollectRadius = Settings.Energy.BaseCollectRadius,
		FieldEnergy = 1,
		EnergyMult = 1,
		XPMult = 1,
		PetPower = 1,
		PetSlots = Settings.Pets.StartSlots,
		StompDamage = 25,
		SlowDuration = A.Verlangsamen.Dauer,
		SlowRadius = A.Verlangsamen.Radius,
		SlowFactor = A.Verlangsamen.Faktor,
		SlowCooldown = A.Verlangsamen.Abklingzeit,
		SlowCost = A.Verlangsamen.Kosten,
		RewindSeconds = A.Zurueckspulen.Sekunden,
		RewindCooldown = A.Zurueckspulen.Abklingzeit,
		RewindCost = A.Zurueckspulen.Kosten,
		BoostSpeed = A.Beschleunigen.Tempo,
		BoostDuration = A.Beschleunigen.Dauer,
		BoostCooldown = A.Beschleunigen.Abklingzeit,
		BoostCost = A.Beschleunigen.Kosten,
		ThrowDamage = A.ZeitWurf.Schaden,
		ThrowRange = A.ZeitWurf.Reichweite,
		ThrowCooldown = A.ZeitWurf.Abklingzeit,
		ThrowCost = A.ZeitWurf.Kosten,
		PlatformDuration = A.Hilfsplattform.Dauer,
		PlatformSize = A.Hilfsplattform.Groesse,
		PlatformCooldown = A.Hilfsplattform.Abklingzeit,
		PlatformCost = A.Hilfsplattform.Kosten,
	}
end

-- Alle Skill-Knoten einer Klasse als Liste
function StatCalc.GetTreeNodes(classId: string): { any }
	local list = {}
	local tree = Skills.Baeume[classId]
	if tree then
		for _, branch in tree do
			for _, node in branch.Knoten do
				table.insert(list, node)
			end
		end
	end
	return list
end

function StatCalc.FindNode(classId: string, nodeId: string): (any, number?, number?)
	local tree = Skills.Baeume[classId]
	if not tree then
		return nil, nil, nil
	end
	for b, branch in tree do
		for i, node in branch.Knoten do
			if node.Id == nodeId then
				return node, b, i
			end
		end
	end
	return nil, nil, nil
end

-- Fusions-Stufe eines Pets (0 = normal, 1 = Gold, 2 = Regenbogen)
function StatCalc.PetTier(pet: any): number
	local s = pet and pet.Stufe
	if type(s) ~= "number" then
		return 0
	end
	return math.clamp(math.floor(s), 0, #Pets.Fusion.Stufen)
end

-- Bonus eines einzelnen Pets (Multiplikator - 1, mit Fusions-Faktor)
function StatCalc.PetBonus(pet: any): number
	local def = Pets.Liste[pet.Type]
	if not def then
		return 0
	end
	local tier = StatCalc.PetTier(pet)
	local factor = if tier > 0 then Pets.Fusion.Stufen[tier].Faktor else 1
	return (def.Multiplikator - 1) * factor
end

-- Angezeigter Multiplikator eines Pets (z.B. x1.53)
function StatCalc.PetValue(pet: any): number
	return 1 + StatCalc.PetBonus(pet)
end

-- Pet-Multiplikator: 1 + Summe(Bonus der ausgerüsteten Pets) * PetPower
function StatCalc.PetMultiplier(profile: any, petPower: number): number
	local bonus = 0
	local equipped = {}
	for _, id in profile.Equipped or {} do
		equipped[id] = true
	end
	for _, pet in profile.Pets or {} do
		if equipped[pet.Id] then
			bonus += StatCalc.PetBonus(pet)
		end
	end
	return 1 + bonus * petPower
end

function StatCalc.Compute(profile: any): { [string]: number }
	local s = baseStats()

	-- Upgrades (immer Plus pro Stufe)
	for _, u in Upgrades do
		local lvl = (profile.Upgrades and profile.Upgrades[u.Id]) or 0
		if lvl > 0 and u.Effekt and s[u.Effekt.Stat] ~= nil then
			s[u.Effekt.Stat] += (u.Effekt.Plus or 0) * lvl
		end
	end

	-- Effekte aus Klasse und Skills sammeln
	local effects = {}
	local class = Classes[profile.Class or ""]
	if class and class.Boni then
		for _, e in class.Boni do
			table.insert(effects, e)
		end
	end
	for _, node in StatCalc.GetTreeNodes(profile.Class or "") do
		if profile.Skills and profile.Skills[node.Id] then
			for _, e in node.Effekte do
				table.insert(effects, e)
			end
		end
	end
	for _, e in effects do
		if s[e.Stat] ~= nil and e.Plus then
			s[e.Stat] += e.Plus
		end
	end
	for _, e in effects do
		if s[e.Stat] ~= nil and e.Mal then
			s[e.Stat] *= e.Mal
		end
	end

	-- Level macht Angriffe stärker
	local levelScale = 1 + 0.12 * ((profile.Level or 1) - 1)
	s.ThrowDamage *= levelScale
	s.StompDamage *= levelScale

	-- Untergrenzen, damit nichts kaputtgeht
	s.SlowCooldown = math.max(2, s.SlowCooldown)
	s.RewindCooldown = math.max(2, s.RewindCooldown)
	s.BoostCooldown = math.max(2, s.BoostCooldown)
	s.ThrowCooldown = math.max(0.3, s.ThrowCooldown)
	s.PlatformCooldown = math.max(1.5, s.PlatformCooldown)
	s.SlowFactor = math.clamp(s.SlowFactor, 0.1, 1)
	s.PetSlots = math.floor(s.PetSlots)

	-- Werkstatt-Bonus: jedes Deko-Stück auf der eigenen Insel gibt etwas mehr Energie
	local items = profile.Island and profile.Island.Items
	s.IslandBonus = math.min((if items then #items else 0) * Deco.BonusProDeko, Deco.BonusMax)
	s.EnergyMult *= 1 + s.IslandBonus

	-- Gesamt-Multiplikator für Energie
	s.PetMult = StatCalc.PetMultiplier(profile, s.PetPower)
	s.RebirthMult = Progression.RebirthMultiplier(profile.Rebirths or 0)
	s.TotalEnergyMult = s.EnergyMult * s.PetMult * s.RebirthMult
	return s
end

return StatCalc
