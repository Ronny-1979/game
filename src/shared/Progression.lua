--!strict
-- Formeln für Level, Kosten und Freischaltungen (Server und Client nutzen dieselben)
local Config = script.Parent:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Upgrades = require(Config:WaitForChild("Upgrades")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any

local Progression = {}

-- XP, die man von "level" bis zum nächsten Level braucht
function Progression.XPForLevel(level: number): number
	return math.floor(Settings.XP.Basis * level ^ Settings.XP.Exponent)
end

function Progression.GetUpgrade(id: string): any
	for _, u in Upgrades do
		if u.Id == id then
			return u
		end
	end
	return nil
end

-- Preis für die nächste Stufe (Stufe = aktuelle Stufe)
function Progression.UpgradeCost(id: string, currentLevel: number): number
	local u = Progression.GetUpgrade(id)
	if not u then
		return math.huge
	end
	return math.floor(u.Basiskosten * u.Kostenfaktor ^ currentLevel)
end

function Progression.RebirthCost(rebirths: number): number
	return math.floor(Settings.Rebirth.Basiskosten * Settings.Rebirth.Kostenfaktor ^ rebirths)
end

function Progression.RebirthMultiplier(rebirths: number): number
	return 1 + rebirths * Settings.Rebirth.MultiplikatorProRebirth
end

-- Ist Zone "index" für dieses Profil erreichbar?
function Progression.IsZoneUnlocked(profile: any, index: number): boolean
	local zone = Zones[index]
	if not zone then
		return false
	end
	if index == 1 then
		return true
	end
	if profile.UnlockedZones and profile.UnlockedZones[zone.Id] then
		return true
	end
	if profile.Level >= zone.FreischaltLevel then
		return true
	end
	local prev = Zones[index - 1]
	return prev ~= nil and profile.BossesDefeated ~= nil and profile.BossesDefeated[prev.Id] == true
end

function Progression.ZoneIndexById(id: string): number?
	for i, z in ipairs(Zones) do
		if z.Id == id then
			return i
		end
	end
	return nil
end

function Progression.TrackKey(zoneIndex: number, trackIndex: number): string
	return ("Z%d_T%d"):format(zoneIndex, trackIndex)
end

return Progression
