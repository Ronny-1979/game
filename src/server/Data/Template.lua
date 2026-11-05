--!strict
-- Standard-Vorlage für neue Spieler (Schema-Version 2)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Upgrades = require(Config:WaitForChild("Upgrades")) :: any

local upgradeLevels = {}
for _, u in Upgrades do
	upgradeLevels[u.Id] = 0
end

local Template = {
	Version = Settings.SchemaVersion,
	Level = 1,
	XP = 0,
	Class = "", -- leer = noch keine Klasse gewählt
	Energy = 0,
	TotalEnergy = 0,
	Upgrades = upgradeLevels,
	Rebirths = 0,
	RebirthPoints = 0,
	Pets = {}, -- { {Id="P1", Type="Tick", Name=""} }
	Equipped = {}, -- { "P1" }
	PetCounter = 0,
	UnlockedZones = { Wiese = true },
	BossesDefeated = {},
	BestTimes = {}, -- ["Z1_T1"] = { Leicht = 32.5 }
	Completed = {}, -- ["Z1_T1_Leicht"] = true
	SkillPoints = 0,
	Skills = {},
	Titles = {},
	ActiveTitle = "",
	CoopSolved = {},
	Settings = { Music = 0.5, Sfx = 0.8, Graphics = "Hoch", Difficulty = "Normal", IntroSeen = false },
	Quest = { Index = 1, Progress = 0 }, -- Aufgaben-Fortschritt (Quests.lua)
	Stats = { PlayTime = 0, Defeated = 0, Courses = 0, Hatched = 0 },
}

return Template
