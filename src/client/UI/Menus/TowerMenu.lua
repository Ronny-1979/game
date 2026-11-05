--!strict
-- TowerMenu: Endlos-Turm – Start-Etage wählen, Wochen-Bestenliste und Rekorde
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tower = require(Shared:WaitForChild("Config"):WaitForChild("Tower")) :: any
local Controllers = script.Parent.Parent.Parent:WaitForChild("Controllers")
local DataController = require(Controllers:WaitForChild("DataController"))

local TowerMenu = {}

local function duration(seconds: number): string
	local d = math.floor(seconds / 86400)
	local h = math.floor((seconds % 86400) / 3600)
	if d > 0 then
		return ("%d Tag%s %d Std."):format(d, if d == 1 then "" else "e", h)
	end
	return ("%d Std. %d Min."):format(h, math.floor((seconds % 3600) / 60))
end

function TowerMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("🗼 Endlos-Turm")

	local info = C.Label({
		Text = "",
		Size = UDim2.new(1, 0, 0, 52),
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 18,
		Parent = content,
	})
	local mine = C.Frame({ Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.Mint, Parent = content })
	local mineLabel = C.Label({ Text = "", Size = UDim2.new(1, -12, 1, -6), Position = UDim2.fromOffset(6, 3), MaxTextSize = 22, Parent = mine })
	C.Label({ Text = "Wo willst du starten?", Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 100), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 20, Parent = content })
	local starts = Instance.new("ScrollingFrame")
	starts.BackgroundTransparency = 1
	starts.BorderSizePixel = 0
	starts.Position = UDim2.fromOffset(0, 128)
	starts.Size = UDim2.new(1, 0, 0, 56)
	starts.ScrollingDirection = Enum.ScrollingDirection.X
	starts.AutomaticCanvasSize = Enum.AutomaticSize.X
	starts.CanvasSize = UDim2.new()
	starts.ScrollBarThickness = 6
	starts.Parent = content
	local sl = Instance.new("UIListLayout")
	sl.FillDirection = Enum.FillDirection.Horizontal
	sl.Padding = UDim.new(0, 8)
	sl.SortOrder = Enum.SortOrder.LayoutOrder
	sl.Parent = starts

	local function column(x: number, title: string): ScrollingFrame
		C.Label({ Text = title, Size = UDim2.new(0.5, -6, 0, 28), Position = UDim2.new(x, if x > 0 then 6 else 0, 0, 192), MaxTextSize = 20, Parent = content })
		return C.List({ Position = UDim2.new(x, if x > 0 then 6 else 0, 0, 222), Size = UDim2.new(0.5, -6, 1, -222), Parent = content })
	end
	local weekList = column(0, "📅 Diese Woche")
	local recordList = column(0.5, "🏆 Rekorde")

	local function fill(list: ScrollingFrame, entries: { any })
		C.Clear(list)
		if #entries == 0 then
			C.Label({ Text = "Noch niemand – sei die/der Erste! 🗼", Size = UDim2.new(1, -6, 0, 36), Parent = list })
			return
		end
		local medals = { "🥇", "🥈", "🥉" }
		for i, e in entries do
			local row = C.Frame({ Size = UDim2.new(1, -6, 0, 36), BackgroundColor3 = if i % 2 == 0 then Theme.Panel else Theme.Bg, LayoutOrder = i, Parent = list })
			C.Label({ Text = medals[i] or tostring(i), Size = UDim2.new(0.16, 0, 1, -6), Position = UDim2.fromOffset(4, 3), MaxTextSize = 20, Parent = row })
			C.Label({ Text = e.Name, Size = UDim2.new(0.56, 0, 1, -6), Position = UDim2.new(0.16, 0, 0, 3), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 18, Parent = row })
			C.Label({ Text = "Etage " .. tostring(e.Floor), Size = UDim2.new(0.28, -4, 1, -6), Position = UDim2.new(0.72, 0, 0, 3), TextColor3 = Theme.Copper, MaxTextSize = 18, Parent = row })
		end
	end

	local loading = false
	local function load()
		if loading then
			return
		end
		loading = true
		C.Clear(starts)
		C.Label({ Text = "Lade …", Size = UDim2.fromOffset(160, 50), Parent = starts })
		local r = UI.Request("GetTowerBoard")
		loading = false
		if not r.ok then
			return
		end
		local data = DataController.Data
		local t = data and data.Tower or { WeekBest = 0, Best = 0 }
		info.Text = ("Klettere Etage für Etage nach oben – jede Etage ist ein kleiner Hindernis-Parcours. Alle %d Etagen: Gratis-Ei + neuer Startpunkt.\nJeden Montag gibt es einen neuen Turm (noch %s)."):format(Tower.MeilensteinAlle, duration(r.secondsLeft or 0))
		mineLabel.Text = ("Diese Woche: Etage %d   ·   Dein Rekord: Etage %d"):format(t.WeekBest or 0, t.Best or 0)
		C.Clear(starts)
		for i, floor in r.starts do
			C.Button({
				Text = ("▶ Etage %d"):format(floor),
				Size = UDim2.fromOffset(150, 50),
				BackgroundColor3 = if i == #r.starts then Theme.Good else Theme.Info,
				LayoutOrder = i,
				OnClick = function()
					local res = UI.Request("EnterTower", floor)
					if res.ok then
						UI.Close()
					end
				end,
				Parent = starts,
			})
		end
		fill(weekList, r.week or {})
		fill(recordList, r.record or {})
	end

	local function onOpen(_args: any)
		task.spawn(load)
	end

	return { Frame = win, OnOpen = onOpen }
end

return TowerMenu
