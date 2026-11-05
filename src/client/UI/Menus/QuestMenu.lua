--!strict
-- QuestMenu: aktuelle Aufgabe ausführlich, Belohnung, Wegweiser an/aus, nächste Aufgaben
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Quests = require(Shared:WaitForChild("Config"):WaitForChild("Quests")) :: any
local Util = require(Shared:WaitForChild("Util"))
local QuestController = require(script.Parent.Parent.Parent:WaitForChild("Controllers"):WaitForChild("QuestController"))

local QuestMenu = {}

function QuestMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("📜 Deine Aufgabe")
	local title = C.Label({ Text = "", Size = UDim2.new(1, 0, 0, 40), MaxTextSize = 32, Parent = content })
	local text = C.Label({ Text = "", Size = UDim2.new(1, -20, 0, 70), Position = UDim2.fromOffset(10, 44), MaxTextSize = 22, Parent = content })
	local tip = C.Label({ Text = "", Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 116), TextColor3 = Theme.BrassDark, MaxTextSize = 18, Parent = content })
	local bar = C.Bar({ Position = UDim2.new(0.15, 0, 0, 166), Size = UDim2.new(0.7, 0, 0, 24), Parent = content }, Theme.Good)
	local barText = C.Label({ Text = "", Size = UDim2.fromScale(1, 1), TextColor3 = Theme.TextLight, TextStrokeTransparency = 0.4, MaxTextSize = 16, ZIndex = 3, Parent = bar.Frame })
	local reward = C.Label({ Text = "", Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 196), TextColor3 = Theme.Copper, MaxTextSize = 20, Parent = content })
	local upcoming = C.Label({ Text = "", Size = UDim2.new(1, -20, 1, -300), Position = UDim2.fromOffset(10, 230), TextColor3 = Theme.Locked, TextYAlignment = Enum.TextYAlignment.Top, MaxTextSize = 17, Parent = content })

	local guide: TextButton
	guide = C.Button({
		Text = "",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(0.48, 0, 0, 54),
		BackgroundColor3 = Theme.Info,
		OnClick = function()
			QuestController.SetEnabled(not QuestController.Enabled)
			guide.Text = if QuestController.Enabled then "🧭 Wegweiser: AN" else "🧭 Wegweiser: AUS"
		end,
		Parent = content,
	})
	C.Button({
		Text = "👋 Einführung",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.new(0.48, 0, 0, 54),
		BackgroundColor3 = Theme.Lilac,
		OnClick = function()
			UI.Open("Intro", {})
		end,
		Parent = content,
	})

	local function refresh(data: any)
		guide.Text = if QuestController.Enabled then "🧭 Wegweiser: AN" else "🧭 Wegweiser: AUS"
		local index = data.Quest and data.Quest.Index or 1
		local q = Quests.Liste[index]
		if not q then
			title.Text = "🏆 Alles geschafft!"
			text.Text = "Du hast alle Aufgaben erledigt. Jag jetzt Bestzeiten auf 🔴 Profi, sammle legendäre Pets und mach Rebirths!"
			tip.Text = ""
			reward.Text = ""
			upcoming.Text = ""
			bar.Set(1)
			barText.Text = ("%d/%d"):format(#Quests.Liste, #Quests.Liste)
			return
		end
		title.Text = ("Aufgabe %d/%d: %s"):format(index, #Quests.Liste, q.Titel)
		text.Text = q.Text
		local hint = QuestController.Hint
		tip.Text = if hint then ("🧭 " .. hint) elseif q.Tipp then ("💡 " .. q.Tipp) else ""
		local need = q.Anzahl or 1
		local have = if q.Art == "Level" then data.Level else (data.Quest.Progress or 0)
		if q.Art == "Level" then
			need = q.Wert or 1
		end
		bar.Set(have / math.max(1, need))
		barText.Text = ("%s / %s"):format(Util.FormatNumber(have), Util.FormatNumber(need))
		local parts = {}
		if q.Belohnung then
			if q.Belohnung.Energie then
				table.insert(parts, Util.FormatNumber(q.Belohnung.Energie) .. " ⚡")
			end
			if q.Belohnung.XP and q.Belohnung.XP > 0 then
				table.insert(parts, Util.FormatNumber(q.Belohnung.XP) .. " XP")
			end
			if q.Belohnung.Ei then
				table.insert(parts, "🥚 Ei")
			end
		end
		reward.Text = if #parts > 0 then ("🎁 Belohnung: " .. table.concat(parts, " + ")) else ""
		local nextLines = {}
		for i = index + 1, math.min(index + 3, #Quests.Liste) do
			table.insert(nextLines, ("Danach: %s"):format(Quests.Liste[i].Titel))
		end
		upcoming.Text = table.concat(nextLines, "\n")
	end

	return { Frame = win, Refresh = refresh }
end

return QuestMenu
