--!strict
--[[
	LevelService: XP, Level-Ups, Skill-Punkte, Zonen freischalten, Belohnungen.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Progression = require(Shared:WaitForChild("Progression"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PetService = require(script.Parent:WaitForChild("PetService"))

local LevelService = {}

local function toast(player: Player, text: string, kind: string?)
	Remotes.Event("Toast"):FireClient(player, text, kind or "info")
end

-- Neue Zonen freischalten, wenn Level oder Boss-Sieg passen
function LevelService.CheckUnlocks(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	for i, zone in ipairs(Zones) do
		if not data.UnlockedZones[zone.Id] and Progression.IsZoneUnlocked(data, i) then
			DataService.Update(player, function(d)
				d.UnlockedZones[zone.Id] = true
			end)
			toast(player, ("🗺️ Neue Zone frei: %s!"):format(zone.Name), "gut")
		end
	end
end

function LevelService.AddXP(player: Player, amount: number, ignoreMult: boolean?)
	local stats = DataService.GetStats(player)
	local data = DataService.Get(player)
	if not stats or not data or amount <= 0 then
		return
	end
	local gain = math.floor(amount * (if ignoreMult then 1 else stats.XPMult) + 0.5)
	local levelsGained = 0
	DataService.Update(player, function(d)
		d.XP += gain
		while d.Level < Settings.XP.MaxLevel and d.XP >= Progression.XPForLevel(d.Level) do
			d.XP -= Progression.XPForLevel(d.Level)
			d.Level += 1
			d.SkillPoints += Settings.XP.SkillPunkteProLevel
			levelsGained += 1
		end
		if d.Level >= Settings.XP.MaxLevel then
			d.XP = 0
		end
	end)
	if levelsGained > 0 then
		toast(player, ("⭐ Level %d! +%d Skill-Punkt"):format(data.Level, levelsGained * Settings.XP.SkillPunkteProLevel), "gut")
		Remotes.Event("Effect"):FireAllClients("LevelUp", { UserId = player.UserId })
		LevelService.CheckUnlocks(player)
	end
end

--[[
	Belohnung verteilen. reward = { Energie = 100, XP = 50, Ei = "WiesenEi", Titel = "..." }
	Energie wird mit dem Energie-Multiplikator (Pets, Rebirth, Upgrades) verrechnet.
]]
function LevelService.Grant(player: Player, reward: any, factor: number?): (number, number)
	local stats = DataService.GetStats(player)
	if not stats then
		return 0, 0
	end
	local f = factor or 1
	local energy = 0
	local xp = 0
	if reward.Energie and reward.Energie > 0 then
		energy = math.floor(reward.Energie * f * stats.TotalEnergyMult)
		DataService.AddEnergy(player, energy)
	end
	if reward.XP and reward.XP > 0 then
		xp = math.floor(reward.XP * f)
		LevelService.AddXP(player, xp)
	end
	if reward.Ei then
		PetService.Hatch(player, reward.Ei, true)
	end
	if reward.Titel then
		DataService.Update(player, function(d)
			if not table.find(d.Titles, reward.Titel) then
				table.insert(d.Titles, reward.Titel)
			end
			d.ActiveTitle = reward.Titel
		end)
		toast(player, ("🏅 Neuer Titel: %s"):format(reward.Titel), "gut")
	end
	if energy > 0 or xp > 0 then
		toast(player, ("+%s ⚡   +%s XP"):format(Util.FormatNumber(energy), Util.FormatNumber(xp)), "gut")
	end
	return energy, xp
end

function LevelService.Init() end

function LevelService.Start()
	DataService.OnLoaded(function(player)
		LevelService.CheckUnlocks(player)
	end)
end

return LevelService
