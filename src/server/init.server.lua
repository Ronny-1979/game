--!strict
--[[
	Uhrwerk-Insel – Server-Einstieg
	Das einzige Server-Script. Lädt alle Services, ruft Init() und danach Start() auf.
]]
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Settings = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Settings")) :: any

Players.RespawnTime = Settings.RespawnTime
Players.CharacterAutoLoads = true

-- 1) Welt bauen, falls noch keine da ist (oder wenn gewünscht neu)
local WorldBuilder = require(script:WaitForChild("World"):WaitForChild("WorldBuilder"))
if Settings.RebuildWorldOnStart or not workspace:FindFirstChild("UhrwerkWelt") then
	local ok, err = pcall(WorldBuilder.Build)
	if not ok then
		warn("[Server] WorldBuilder-Fehler:", err)
	end
else
	WorldBuilder.ApplyLighting()
end

-- 2) Services in fester Reihenfolge laden
local order = {
	"DataService",
	"PlayerService",
	"LevelService",
	"PetService",
	"QuestService",
	"ZoneService",
	"TimeScaleService",
	"ObstacleService",
	"LeaderboardService",
	"CourseService",
	"EnergyService",
	"UpgradeService",
	"ClassService",
	"EnemyService",
	"BossService",
	"AbilityService",
	"CoopService",
	"ChatService",
	"AdminService",
}

local servicesFolder = script:WaitForChild("Services")
local services = {}
for _, name in order do
	local module = servicesFolder:WaitForChild(name)
	local ok, svc = pcall(require, module)
	if ok then
		services[name] = svc
	else
		warn("[Server] Konnte Service nicht laden:", name, svc)
	end
end

for _, name in order do
	local svc = services[name]
	if svc and svc.Init then
		local ok, err = pcall(svc.Init)
		if not ok then
			warn("[Server] Init-Fehler in", name, err)
		end
	end
end

for _, name in order do
	local svc = services[name]
	if svc and svc.Start then
		task.spawn(function()
			local ok, err = pcall(svc.Start)
			if not ok then
				warn("[Server] Start-Fehler in", name, err)
			end
		end)
	end
end

print("[Server] Uhrwerk-Insel gestartet ⚙️", ServerScriptService.Name)
