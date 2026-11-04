--!strict
--[[
	Uhrwerk-Insel – Client-Einstieg
	Das einzige LocalScript. Lädt alle Controller, ruft Init() und danach Start() auf.
]]
local order = {
	"Controllers/DataController",
	"Controllers/SoundController",
	"UI/UIController",
	"Controllers/ObstacleController",
	"Controllers/CourseController",
	"Controllers/PetController",
	"Controllers/EffectController",
	"Controllers/AbilityController",
	"Controllers/PromptController",
	"Controllers/ChatController",
}

local function find(path: string): Instance
	local node: Instance = script
	for part in string.gmatch(path, "[^/]+") do
		node = node:WaitForChild(part)
	end
	return node
end

local controllers = {}
for _, path in order do
	local ok, mod = pcall(require, find(path))
	if ok then
		table.insert(controllers, { path, mod })
	else
		warn("[Client] Konnte nicht laden:", path, mod)
	end
end

for _, entry in controllers do
	local mod = entry[2]
	if mod.Init then
		local ok, err = pcall(mod.Init)
		if not ok then
			warn("[Client] Init-Fehler:", entry[1], err)
		end
	end
end

for _, entry in controllers do
	local mod = entry[2]
	if mod.Start then
		task.spawn(function()
			local ok, err = pcall(mod.Start)
			if not ok then
				warn("[Client] Start-Fehler:", entry[1], err)
			end
		end)
	end
end
