--!strict
-- IntroMenu: Willkommens-Seiten beim ersten Start (auch über ⚙️ oder 📜 erneut aufrufbar)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Quests = require(Shared:WaitForChild("Config"):WaitForChild("Quests")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))

local IntroMenu = {}

function IntroMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("👋 Willkommen!")
	local pages = Quests.Einfuehrung
	local page = 1

	local symbol = C.Label({ Text = "", Size = UDim2.new(1, 0, 0.26, 0), MaxTextSize = 80, Parent = content })
	local title = C.Label({ Text = "", Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.fromScale(0, 0.27), MaxTextSize = 34, Parent = content })
	local text = C.Label({ Text = "", Size = UDim2.new(0.9, 0, 0.36, 0), Position = UDim2.fromScale(0.05, 0.4), MaxTextSize = 24, Parent = content })
	local dots = C.Label({ Text = "", Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 1, -86), TextColor3 = Theme.Brass, MaxTextSize = 22, Parent = content })

	local back = C.Button({
		Text = "◀ Zurück",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(0.35, 0, 0, 56),
		BackgroundColor3 = Theme.Locked,
		Parent = content,
	})
	local nextBtn = C.Button({
		Text = "Weiter ▶",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.new(0.5, 0, 0, 56),
		BackgroundColor3 = Theme.Good,
		Parent = content,
	})

	local function show()
		local p = pages[page]
		symbol.Text = p.Symbol
		title.Text = p.Titel
		text.Text = p.Text
		local d = {}
		for i = 1, #pages do
			table.insert(d, if i == page then "●" else "○")
		end
		dots.Text = table.concat(d, " ")
		back.Visible = page > 1
		nextBtn.Text = if page == #pages then "Los geht's! 🚀" else "Weiter ▶"
		local s = symbol:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		s.Parent = symbol
		s.Scale = 0.5
		TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end

	back.Activated:Connect(function()
		if page > 1 then
			page -= 1
			show()
		end
	end)
	nextBtn.Activated:Connect(function()
		if page < #pages then
			page += 1
			show()
		else
			UI.Close()
		end
	end)

	local function onOpen(_args: any)
		page = 1
		show()
	end

	-- beim Schließen merken, dass die Einführung gesehen wurde
	local function onClose()
		Remotes.Event("ChangeSetting"):FireServer("IntroSeen", true)
	end

	return { Frame = win, OnOpen = onOpen, OnClose = onClose }
end

return IntroMenu
