--!strict
--[[
	AbilityController: Zeit-Fähigkeiten per Taste (PC), Knopf (Handy/Tablet) oder Gamepad.
	Der Server prüft alles; hier merken wir uns nur die Abklingzeit für die Anzeige.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skills = require(Shared:WaitForChild("Config"):WaitForChild("Skills")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataController = require(script.Parent:WaitForChild("DataController"))

local AbilityController = {}

local cooldownEnd: { [string]: number } = {}
local cooldownTotal: { [string]: number } = {}
local lastSent: { [string]: number } = {}

local GAMEPAD = {
	[Enum.KeyCode.DPadLeft] = "Verlangsamen",
	[Enum.KeyCode.DPadUp] = "Zurueckspulen",
	[Enum.KeyCode.DPadRight] = "Beschleunigen",
	[Enum.KeyCode.ButtonR1] = "ZeitWurf",
	[Enum.KeyCode.ButtonL1] = "Hilfsplattform",
}

-- Controller-Taste einer Fähigkeit (für die Anzeige im HUD)
function AbilityController.GamepadKey(name: string): Enum.KeyCode?
	for code, n in GAMEPAD do
		if n == name then
			return code
		end
	end
	return nil
end

-- Welche Fähigkeiten hat der Spieler gerade?
function AbilityController.Available(): { string }
	local list = {}
	local data = DataController.Data
	for _, name in Skills.Reihenfolge do
		local def = Skills.Faehigkeiten[name]
		if def and (not def.NurKlasse or (data and data.Class == def.NurKlasse)) then
			table.insert(list, name)
		end
	end
	return list
end

-- Rest-Abklingzeit, Gesamt-Abklingzeit
function AbilityController.GetCooldown(name: string): (number, number)
	local left = math.max(0, (cooldownEnd[name] or 0) - os.clock())
	return left, cooldownTotal[name] or 1
end

function AbilityController.Use(name: string)
	if (cooldownEnd[name] or 0) > os.clock() then
		return
	end
	if os.clock() - (lastSent[name] or 0) < 0.25 then
		return
	end
	lastSent[name] = os.clock()
	local cam = workspace.CurrentCamera
	local dir = if cam then cam.CFrame.LookVector else Vector3.zAxis
	-- Handy und Controller: in Laufrichtung werfen
	local lastInput = UserInputService:GetLastInputType()
	if lastInput == Enum.UserInputType.Touch or lastInput.Name:match("^Gamepad") then
		local char = Players.LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			dir = root.CFrame.LookVector
		end
	end
	Remotes.Event("UseAbility"):FireServer(name, dir)
end

function AbilityController.Init() end

function AbilityController.Start()
	local keys: { [Enum.KeyCode]: string } = {}
	for name, def in Skills.Faehigkeiten do
		local ok, code = pcall(function()
			return (Enum.KeyCode :: any)[def.Taste]
		end)
		if ok and code then
			keys[code] = name
		end
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		local name = keys[input.KeyCode] or GAMEPAD[input.KeyCode]
		if name and table.find(AbilityController.Available(), name) then
			AbilityController.Use(name)
		end
	end)
	Remotes.Event("AbilityUsed").OnClientEvent:Connect(function(name: string, cd: number)
		cooldownEnd[name] = os.clock() + cd
		cooldownTotal[name] = cd
	end)
end

return AbilityController
