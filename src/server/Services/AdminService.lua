--!strict
--[[
	AdminService: Test-Befehle – nur für UserIds aus Settings.AdminUserIds
	(und im Studio, wenn Settings.AdminInStudio = true).
	Befehle: Energie, Level, XP, Zone, AlleZonen, SkillPunkte, RebirthPunkte, Ei, Reset, Teleport
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Pets = require(Config:WaitForChild("Pets")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlayerService = require(script.Parent:WaitForChild("PlayerService"))
local LevelService = require(script.Parent:WaitForChild("LevelService"))
local PetService = require(script.Parent:WaitForChild("PetService"))
local ZoneService = require(script.Parent:WaitForChild("ZoneService"))
local Validate = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Validate"))

local AdminService = {}

local Commands: { [string]: (Player, any) -> string } = {}

Commands.Energie = function(player, n)
	n = if Validate.Number(n, 1, 1e15) then n else 1000
	DataService.AddEnergy(player, n)
	return "Energie gegeben"
end

Commands.Level = function(player, n)
	if not Validate.Int(n, 1, Settings.XP.MaxLevel) then
		return "Level 1–" .. Settings.XP.MaxLevel
	end
	DataService.Update(player, function(d)
		local diff = n - d.Level
		d.Level = n
		d.XP = 0
		if diff > 0 then
			d.SkillPoints += diff * Settings.XP.SkillPunkteProLevel
		end
	end)
	LevelService.CheckUnlocks(player)
	return "Level gesetzt"
end

Commands.XP = function(player, n)
	LevelService.AddXP(player, if Validate.Number(n, 1, 1e9) then n else 500, true)
	return "XP gegeben"
end

Commands.Zone = function(player, n)
	if not Validate.Int(n, 1, #Zones) then
		return "Zone 1–" .. #Zones
	end
	DataService.Update(player, function(d)
		for i = 1, n do
			d.UnlockedZones[Zones[i].Id] = true
		end
	end)
	return "Zonen freigeschaltet"
end

Commands.AlleZonen = function(player)
	return Commands.Zone(player, #Zones)
end

Commands.SkillPunkte = function(player, n)
	DataService.Update(player, function(d)
		d.SkillPoints += if Validate.Int(n, 1, 1000) then n else 10
	end)
	return "Skill-Punkte gegeben"
end

Commands.RebirthPunkte = function(player, n)
	DataService.Update(player, function(d)
		d.RebirthPoints += if Validate.Int(n, 1, 1000) then n else 5
	end)
	return "Rebirth-Punkte gegeben"
end

Commands.Ei = function(player, eggId)
	if not Validate.Key(eggId, Pets.Eier) then
		return "Unbekanntes Ei"
	end
	PetService.Hatch(player, eggId, true)
	return "Ei geöffnet"
end

Commands.Bonus = function(player)
	DataService.Update(player, function(d)
		d.Daily.LastDay = 0
	end)
	return "Tagesbonus wieder verfügbar"
end

Commands.Reset = function(player)
	DataService.ResetProfile(player)
	PetService.UpdateAttribute(player)
	return "Profil zurückgesetzt"
end

Commands.Teleport = function(player, n)
	if not Validate.Int(n, 0, #Zones) then
		return "Zone 0–" .. #Zones
	end
	local spawn = ZoneService.GetZoneSpawn(n)
	if spawn then
		ZoneService.TeleportTo(player, spawn, n)
	end
	return "Teleportiert"
end

function AdminService.Init() end

function AdminService.Start()
	Remotes.OnInvoke("Admin", 4, function(player, cmd, arg)
		if not PlayerService.IsAdmin(player) then
			warn("[Admin] Nicht erlaubt:", player.Name)
			return { ok = false, msg = "Keine Admin-Rechte." }
		end
		if type(cmd) ~= "string" or not Commands[cmd] then
			return { ok = false, msg = "Unbekannter Befehl." }
		end
		local msg = Commands[cmd](player, arg)
		print(("[Admin] %s: %s %s → %s"):format(player.Name, cmd, tostring(arg), msg))
		return { ok = true, msg = msg }
	end)
end

return AdminService
