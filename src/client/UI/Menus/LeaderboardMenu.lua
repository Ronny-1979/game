--!strict
-- LeaderboardMenu: Bestenliste pro Strecke und Schwierigkeit
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Zones = require(Config:WaitForChild("Zones")) :: any
local Difficulty = require(Config:WaitForChild("Difficulty")) :: any
local Util = require(Shared:WaitForChild("Util"))
local Progression = require(Shared:WaitForChild("Progression"))

local LeaderboardMenu = {}

function LeaderboardMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("🏆 Bestenliste")
	local zone, track, diff = 1, 1, "Normal"

	local function row(y: number): Frame
		local f = Instance.new("Frame")
		f.BackgroundTransparency = 1
		f.Position = UDim2.fromOffset(0, y)
		f.Size = UDim2.new(1, 0, 0, 40)
		f.Parent = content
		local l = Instance.new("UIListLayout")
		l.FillDirection = Enum.FillDirection.Horizontal
		l.Padding = UDim.new(0, 6)
		l.Parent = f
		return f
	end
	local zoneRow = row(0)
	local trackRow = row(46)
	local diffRow = row(92)
	local list = C.List({ Position = UDim2.fromOffset(0, 140), Size = UDim2.new(1, 0, 1, -140), Parent = content })
	local loading = false

	local load: () -> ()

	local function tabs()
		C.Clear(zoneRow)
		C.Clear(trackRow)
		C.Clear(diffRow)
		for i, z in ipairs(Zones) do
			C.Button({ Text = tostring(i), Size = UDim2.new(0.2, -6, 1, 0), BackgroundColor3 = if i == zone then z.Farben.Akzent else Theme.Locked, OnClick = function()
				zone = i
				load()
			end, Parent = zoneRow })
		end
		for t, tr in Zones[zone].Strecken do
			C.Button({ Text = tr.Name, Size = UDim2.new(1 / 3, -6, 1, 0), BackgroundColor3 = if t == track then Theme.Brass else Theme.Locked, OnClick = function()
				track = t
				load()
			end, Parent = trackRow })
		end
		for _, d in Difficulty.Reihenfolge do
			local cfg = Difficulty.Stufen[d]
			C.Button({ Text = cfg.Symbol .. " " .. d, Size = UDim2.new(1 / 3, -6, 1, 0), BackgroundColor3 = if d == diff then cfg.Farbe else Theme.Locked, TextColor3 = Theme.Text, OnClick = function()
				diff = d
				load()
			end, Parent = diffRow })
		end
	end

	load = function()
		tabs()
		if loading then
			return
		end
		loading = true
		C.Clear(list)
		C.Label({ Text = "Lade …", Size = UDim2.new(1, 0, 0, 40), Parent = list })
		local r = UI.Request("GetLeaderboard", Progression.TrackKey(zone, track), diff)
		loading = false
		C.Clear(list)
		if not r.ok then
			return
		end
		if r.mine then
			local mine = C.Frame({ Size = UDim2.new(1, -6, 0, 42), BackgroundColor3 = Theme.Mint, LayoutOrder = 0, Parent = list })
			C.Label({ Text = ("⭐ Deine Bestzeit: %s"):format(Util.FormatTime(r.mine)), Size = UDim2.new(1, -12, 1, -6), Position = UDim2.fromOffset(6, 3), MaxTextSize = 22, Parent = mine })
		end
		if #r.list == 0 then
			C.Label({ Text = "Noch keine Zeiten – sei die/der Erste! 🏁", Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 1, Parent = list })
		end
		local medals = { "🥇", "🥈", "🥉" }
		for i, e in r.list do
			local f = C.Frame({ Size = UDim2.new(1, -6, 0, 40), BackgroundColor3 = if i % 2 == 0 then Theme.Panel else Theme.Bg, LayoutOrder = i, Parent = list })
			C.Label({ Text = medals[i] or tostring(i), Size = UDim2.new(0.12, 0, 1, -6), Position = UDim2.fromOffset(4, 3), MaxTextSize = 22, Parent = f })
			C.Label({ Text = e.Name, Size = UDim2.new(0.56, 0, 1, -6), Position = UDim2.new(0.12, 0, 0, 3), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 20, Parent = f })
			C.Label({ Text = Util.FormatTime(e.Time), Size = UDim2.new(0.3, 0, 1, -6), Position = UDim2.new(0.68, 0, 0, 3), TextColor3 = Theme.Copper, MaxTextSize = 20, Parent = f })
		end
	end

	local function onOpen(_args: any)
		local z = UI.CurrentZone and UI.CurrentZone() or 0
		if z > 0 then
			zone = z
		end
		task.spawn(load)
	end

	return { Frame = win, OnOpen = onOpen }
end

return LeaderboardMenu
