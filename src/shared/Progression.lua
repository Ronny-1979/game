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

-- Höchste freigeschaltete Zone (1 … #Zones)
function Progression.BestZone(profile: any): number
	local best = 1
	for i = 1, #Zones do
		if Progression.IsZoneUnlocked(profile, i) then
			best = i
		end
	end
	return best
end

-- Werkstatt-Deko: Preis (passt sich der besten Zone an) und Freischaltung
function Progression.DecoPrice(item: any, profile: any): number
	local zone = Zones[Progression.BestZone(profile)]
	return math.floor((item.Preis or 0) * zone.Energiewert)
end

function Progression.DecoUnlocked(item: any, profile: any): (boolean, string?)
	if item.Zone and not Progression.IsZoneUnlocked(profile, item.Zone) then
		local z = Zones[item.Zone]
		return false, ("🔒 ab Zone %d (%s)"):format(item.Zone, z and z.Name or "?")
	end
	if item.Boss and not (profile.BossesDefeated and profile.BossesDefeated[item.Boss]) then
		local idx = Progression.ZoneIndexById(item.Boss)
		return false, ("🔒 Boss von Zone %d besiegen"):format(idx or 0)
	end
	return true, nil
end

-- Zeit für eine Medaille (1 = Bronze, 2 = Silber, 3 = Gold) bei Richtzeit "par"
function Progression.MedalTime(par: number, medal: number): number
	local m = Settings.Medals[medal]
	return if m then math.floor(par * m.Faktor * 10 + 0.5) / 10 else math.huge
end

-- Beste Medaille für eine Zeit (0 = keine)
function Progression.MedalFor(seconds: number, par: number?): number
	if not par or par <= 0 then
		return 0
	end
	local best = 0
	for i = 1, #Settings.Medals do
		if seconds <= Progression.MedalTime(par, i) then
			best = i
		end
	end
	return best
end

return Progression
