--!strict
-- ChatMenu: vorgefertigte Schnellnachrichten (kein freier Text)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Settings")) :: any
local ChatController = require(script.Parent.Parent.Parent:WaitForChild("Controllers"):WaitForChild("ChatController"))

local ChatMenu = {}

function ChatMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("💬 Schnellnachrichten")
	local list = C.List({ Size = UDim2.fromScale(1, 1), Parent = content }, UDim2.fromOffset(236, 62))
	for i, text in Settings.QuickChat do
		C.Button({
			Text = text,
			BackgroundColor3 = if i % 2 == 0 then Theme.Mint else Theme.Lilac,
			TextColor3 = Theme.Text,
			LayoutOrder = i,
			OnClick = function()
				ChatController.Send(i)
				UI.Close()
			end,
			Parent = list,
		})
	end
	return { Frame = win }
end

return ChatMenu
