--!strict
-- ShopMenu: Upgrades kaufen (Kosten steigen pro Stufe)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Upgrades = require(Shared:WaitForChild("Config"):WaitForChild("Upgrades")) :: any
local Util = require(Shared:WaitForChild("Util"))
local Progression = require(Shared:WaitForChild("Progression"))
local SoundController = require(script.Parent.Parent.Parent:WaitForChild("Controllers"):WaitForChild("SoundController"))

local ShopMenu = {}

function ShopMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("🛒 Upgrade-Shop")
	local list = C.List({ Size = UDim2.fromScale(1, 1), Parent = content })
	type Row = { Level: TextLabel, Buy: TextButton, Id: string }
	local rows: { Row } = {}
	for i, u in Upgrades do
		local row = C.Frame({ Size = UDim2.new(1, -6, 0, 78), BackgroundColor3 = Theme.Panel, LayoutOrder = i, Parent = list })
		C.Stroke(row, Theme.PanelDark, 2)
		C.Label({ Text = u.Symbol, Size = UDim2.fromOffset(56, 56), Position = UDim2.fromOffset(10, 11), MaxTextSize = 40, Parent = row })
		C.Label({ Text = u.Name, Size = UDim2.new(0.55, -70, 0, 30), Position = UDim2.fromOffset(72, 6), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 24, Parent = row })
		C.Label({ Text = u.Beschreibung, Size = UDim2.new(0.55, -70, 0, 22), Position = UDim2.fromOffset(72, 36), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.BrassDark, MaxTextSize = 16, Parent = row })
		local level = C.Label({ Text = "", Size = UDim2.new(0.18, 0, 0, 30), Position = UDim2.new(0.55, 0, 0, 24), MaxTextSize = 20, Parent = row })
		local buy = C.Button({
			Text = "",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.new(0.25, 0, 0, 54),
			BackgroundColor3 = Theme.Good,
			OnClick = function()
				local r = UI.Request("BuyUpgrade", u.Id)
				if r.ok then
					SoundController.Play("Kaufen", 1.2)
				end
			end,
			Parent = row,
		})
		table.insert(rows, { Level = level, Buy = buy, Id = u.Id })
	end

	local function refresh(data: any)
		for _, r in rows do
			local u = Progression.GetUpgrade(r.Id)
			local lvl = data.Upgrades[r.Id] or 0
			r.Level.Text = ("Stufe %d/%d"):format(lvl, u.MaxStufe)
			if lvl >= u.MaxStufe then
				r.Buy.Text = "⭐ MAX"
				r.Buy.BackgroundColor3 = Theme.Locked
			else
				local cost = Progression.UpgradeCost(r.Id, lvl)
				r.Buy.Text = "⚡ " .. Util.FormatNumber(cost)
				r.Buy.BackgroundColor3 = if data.Energy >= cost then Theme.Good else Theme.Locked
			end
		end
	end

	return { Frame = win, Refresh = refresh }
end

return ShopMenu
