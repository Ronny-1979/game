--!strict
--[[
	MainMenu (☰): alle Menüs als große Kacheln.
	Öffnen: Knopf „☰ Mehr“ (wenn nicht alle Knöpfe auf den Bildschirm passen), Controller Y, Taste M.
	Gut mit Finger und Controller bedienbar.
]]
local Players = game:GetService("Players")

local MainMenu = {}

function MainMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local player = Players.LocalPlayer
	local win, content = UI.Window("☰ Menü")
	local list = C.List({ Size = UDim2.fromScale(1, 1), Parent = content }, UDim2.fromOffset(176, 112))

	local entries = {}
	for _, def in UI.MenuButtons do
		table.insert(entries, def)
	end
	table.insert(entries, { Icon = "📜", Name = "Aufgabe", Target = "Aufgabe" })
	table.insert(entries, { Icon = "📖", Name = "Einführung", Target = "Intro" })
	table.insert(entries, { Icon = "🔧", Name = "Admin", Target = "Admin", Admin = true })

	local colors = { Theme.Panel, Theme.PanelDark }
	local adminTiles = {}
	for i, def in entries do
		local tile = C.Button({
			Text = "",
			BackgroundColor3 = colors[(i % 2) + 1],
			LayoutOrder = i,
			OnClick = function()
				UI.RunTarget(def.Target)
			end,
			Parent = list,
		})
		C.Stroke(tile, Theme.Brass, 3)
		C.Label({ Text = def.Icon, Size = UDim2.new(1, 0, 0.6, 0), Position = UDim2.fromScale(0, 0.04), MaxTextSize = 46, Parent = tile })
		C.Label({ Text = def.Name, Size = UDim2.new(1, 0, 0.3, 0), Position = UDim2.fromScale(0, 0.64), MaxTextSize = 22, Parent = tile })
		if def.Admin then
			table.insert(adminTiles, tile)
		end
	end

	local function updateAdmin()
		for _, tile in adminTiles do
			tile.Visible = player:GetAttribute("IsAdmin") == true
		end
	end
	player:GetAttributeChangedSignal("IsAdmin"):Connect(updateAdmin)
	updateAdmin()

	return { Frame = win }
end

return MainMenu
