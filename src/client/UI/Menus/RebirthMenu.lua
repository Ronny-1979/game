--!strict
-- RebirthMenu: Energie + Upgrades zurücksetzen → dauerhafter Multiplikator + Rebirth-Punkte
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = require(Shared:WaitForChild("Config"):WaitForChild("Settings")) :: any
local Util = require(Shared:WaitForChild("Util"))
local Progression = require(Shared:WaitForChild("Progression"))

local RebirthMenu = {}

function RebirthMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("♻️ Rebirth")
	local info = C.Label({ Text = "", Size = UDim2.new(1, 0, 0.42, 0), MaxTextSize = 26, Parent = content })
	local bar = C.Bar({ Position = UDim2.new(0.1, 0, 0.46, 0), Size = UDim2.new(0.8, 0, 0, 26), Parent = content }, Theme.Energy)
	local barText = C.Label({ Text = "", Size = UDim2.fromScale(1, 1), TextColor3 = Theme.TextLight, TextStrokeTransparency = 0.4, MaxTextSize = 18, ZIndex = 3, Parent = bar.Frame })
	C.Label({
		Text = "Setzt Energie und Upgrades zurück (Pet-Plätze, Pets, Level und Skills bleiben!).\nDafür bekommst du für immer mehr Energie und einen Rebirth-Punkt für das Rebirth-Ei.",
		Size = UDim2.new(1, 0, 0.2, 0),
		Position = UDim2.fromScale(0, 0.56),
		TextColor3 = Theme.BrassDark,
		MaxTextSize = 18,
		Parent = content,
	})
	local confirm = false
	local button: TextButton
	button = C.Button({
		Text = "♻️ Rebirth!",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(0.5, 0, 0, 60),
		BackgroundColor3 = Theme.Copper,
		OnClick = function()
			if not confirm then
				confirm = true
				button.Text = "Wirklich? Nochmal tippen!"
				task.delay(3, function()
					confirm = false
					button.Text = "♻️ Rebirth!"
				end)
				return
			end
			confirm = false
			button.Text = "♻️ Rebirth!"
			UI.Request("Rebirth")
		end,
		Parent = content,
	})
	local function refresh(data: any)
		local cost = Progression.RebirthCost(data.Rebirths)
		local now = Progression.RebirthMultiplier(data.Rebirths)
		local nxt = Progression.RebirthMultiplier(data.Rebirths + 1)
		info.Text = ("Rebirths: %d   ·   Rebirth-Punkte: %d\nEnergie-Bonus: x%s → x%s\nBenötigt: Level %d und %s ⚡"):format(
			data.Rebirths,
			data.RebirthPoints,
			tostring(now),
			tostring(nxt),
			Settings.Rebirth.MindestLevel,
			Util.FormatNumber(cost)
		)
		bar.Set(data.Energy / cost)
		barText.Text = ("%s / %s ⚡"):format(Util.FormatNumber(data.Energy), Util.FormatNumber(cost))
		button.BackgroundColor3 = if data.Energy >= cost and data.Level >= Settings.Rebirth.MindestLevel then Theme.Good else Theme.Locked
	end
	return { Frame = win, Refresh = refresh }
end

return RebirthMenu
