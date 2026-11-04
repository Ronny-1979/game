--!strict
-- PromptController: ProximityPrompts an Stationen öffnen das passende Menü
local ProximityPromptService = game:GetService("ProximityPromptService")

local UI = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("UIController"))
local SoundController = require(script.Parent:WaitForChild("SoundController"))

local PromptController = {}

function PromptController.Init() end

function PromptController.Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local holder = prompt.Parent
		if not holder then
			return
		end
		local menu = holder:GetAttribute("Menu")
		if type(menu) ~= "string" then
			return
		end
		SoundController.Play("Menue")
		if menu == "Ei" then
			UI.Open("Ei", { EggId = holder:GetAttribute("EggId") })
		elseif menu == "Skills" then
			UI.Open("Skills", { AtTeacher = true })
		else
			UI.Open(menu, {})
		end
	end)
end

return PromptController
