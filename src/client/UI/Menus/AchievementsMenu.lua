--!strict
-- AchievementsMenu: Zonen-Herausforderungen 🎯 und Sammel-Abzeichen 🏅
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Challenges = require(Config:WaitForChild("Challenges")) :: any
local Badges = require(Config:WaitForChild("Badges")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Util = require(Shared:WaitForChild("Util"))
local Goals = require(Shared:WaitForChild("Goals"))
local Progression = require(Shared:WaitForChild("Progression"))

local AchievementsMenu = {}

function AchievementsMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("🏅 Erfolge")
	local tab = "Herausforderungen"
	local zone = 1
	local lastSig = ""

	local tabs = Instance.new("Frame")
	tabs.BackgroundTransparency = 1
	tabs.Size = UDim2.new(1, 0, 0, 44)
	tabs.Parent = content
	local tl = Instance.new("UIListLayout")
	tl.FillDirection = Enum.FillDirection.Horizontal
	tl.Padding = UDim.new(0, 8)
	tl.Parent = tabs
	local zoneRow = Instance.new("Frame")
	zoneRow.BackgroundTransparency = 1
	zoneRow.Position = UDim2.fromOffset(0, 50)
	zoneRow.Size = UDim2.new(1, 0, 0, 40)
	zoneRow.Parent = content
	local zl = Instance.new("UIListLayout")
	zl.FillDirection = Enum.FillDirection.Horizontal
	zl.Padding = UDim.new(0, 6)
	zl.Parent = zoneRow
	local list = C.List({ Position = UDim2.fromOffset(0, 96), Size = UDim2.new(1, 0, 1, -96), Parent = content })
	local grid = C.List({ Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 1, -52), Visible = false, Parent = content }, UDim2.fromOffset(150, 132))

	local refresh: (any) -> ()

	local function rewardText(b: any): string
		local parts = {}
		if b.Energie then
			table.insert(parts, Util.FormatNumber(b.Energie) .. " ⚡")
		end
		if b.XP then
			table.insert(parts, Util.FormatNumber(b.XP) .. " XP")
		end
		if b.Ei then
			table.insert(parts, "🥚")
		end
		return table.concat(parts, " + ")
	end

	local function buildTabs(data: any)
		C.Clear(tabs)
		local doneC = Util.Count(data.Challenges)
		local totalC = 0
		for _, l in Challenges do
			totalC += #l
		end
		local doneB = Util.Count(data.Badges)
		for _, t in { { "Herausforderungen", ("🎯 Herausforderungen %d/%d"):format(doneC, totalC) }, { "Abzeichen", ("🏅 Abzeichen %d/%d"):format(doneB, #Badges) } } do
			C.Button({
				Text = t[2],
				Size = UDim2.new(0.5, -4, 1, 0),
				BackgroundColor3 = if tab == t[1] then Theme.Copper else Theme.Locked,
				OnClick = function()
					tab = t[1]
					lastSig = ""
					refresh(data)
				end,
				Parent = tabs,
			})
		end
	end

	local function showChallenges(data: any)
		C.Clear(zoneRow)
		for i, z in ipairs(Zones) do
			C.Button({
				Text = ("%d %s"):format(i, if Progression.IsZoneUnlocked(data, i) then "" else "🔒"),
				Size = UDim2.new(0.2, -6, 1, 0),
				BackgroundColor3 = if i == zone then z.Farben.Akzent else Theme.Locked,
				OnClick = function()
					zone = i
					lastSig = ""
					refresh(data)
				end,
				Parent = zoneRow,
			})
		end
		C.Clear(list)
		C.Label({ Text = Zones[zone].Name, Size = UDim2.new(1, -6, 0, 30), LayoutOrder = 0, MaxTextSize = 24, Parent = list })
		for i, ch in Challenges[zone] or {} do
			local done = data.Challenges[ch.Id] == true
			local have, need = Goals.Challenge(ch, data, zone)
			local row = C.Frame({ Size = UDim2.new(1, -6, 0, 76), BackgroundColor3 = if done then Theme.Mint else Theme.Panel, LayoutOrder = i, Parent = list })
			C.Stroke(row, if done then Theme.Good else Theme.PanelDark, 2)
			C.Label({ Text = (if done then "✅ " else "🎯 ") .. ch.Titel, Size = UDim2.new(0.6, -10, 0, 28), Position = UDim2.fromOffset(10, 4), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 20, Parent = row })
			C.Label({ Text = ch.Text, Size = UDim2.new(0.6, -10, 0, 22), Position = UDim2.fromOffset(10, 32), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.BrassDark, MaxTextSize = 16, Parent = row })
			C.Label({ Text = "🎁 " .. rewardText(ch.Belohnung or {}), Size = UDim2.new(0.6, -10, 0, 18), Position = UDim2.fromOffset(10, 54), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.Copper, MaxTextSize = 14, Parent = row })
			local bar = C.Bar({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.36, 0, 0, 24), Parent = row }, Theme.Good)
			bar.Set(if done then 1 else have / math.max(1, need))
			C.Label({ Text = if done then "geschafft!" else ("%s / %s"):format(Util.FormatNumber(have), Util.FormatNumber(need)), Size = UDim2.fromScale(1, 1), TextColor3 = Theme.TextLight, TextStrokeTransparency = 0.4, MaxTextSize = 15, ZIndex = 3, Parent = bar.Frame })
		end
	end

	local function showBadges(data: any)
		C.Clear(grid)
		for i, b in Badges do
			local done = data.Badges[b.Id] == true
			local card = C.Frame({ BackgroundColor3 = if done then Color3.fromRGB(255, 240, 190) else Theme.PanelDark, LayoutOrder = (if done then 0 else 1000) + i, Parent = grid })
			C.Stroke(card, if done then Theme.Brass else Theme.Locked, if done then 3 else 2)
			local icon = C.Label({ Text = b.Symbol, Size = UDim2.new(1, 0, 0.4, 0), MaxTextSize = 40, Parent = card })
			if not done then
				icon.TextTransparency = 0.6
			end
			C.Label({ Text = b.Name, Size = UDim2.new(1, -6, 0.2, 0), Position = UDim2.new(0, 3, 0.4, 0), MaxTextSize = 17, Parent = card })
			local value = math.min(Goals.BadgeValue(b.Art, data), b.Wert)
			C.Label({
				Text = if done then b.Text else ("%s\n%s / %s"):format(b.Text, Util.FormatNumber(value), Util.FormatNumber(b.Wert)),
				Size = UDim2.new(1, -6, 0.38, 0),
				Position = UDim2.new(0, 3, 0.6, 0),
				TextColor3 = Theme.BrassDark,
				MaxTextSize = 13,
				Parent = card,
			})
		end
	end

	refresh = function(data: any)
		local sig = HttpService:JSONEncode({ tab, zone, data.Challenges, data.Badges, data.ZoneStats, data.Completed, data.Level })
		if sig == lastSig then
			return
		end
		lastSig = sig
		buildTabs(data)
		local isChallenges = tab == "Herausforderungen"
		zoneRow.Visible = isChallenges
		list.Visible = isChallenges
		grid.Visible = not isChallenges
		if isChallenges then
			showChallenges(data)
		else
			showBadges(data)
		end
	end

	local function onOpen(_args: any)
		local z = UI.CurrentZone()
		if z > 0 then
			zone = z
		end
		lastSig = ""
	end

	return { Frame = win, Refresh = refresh, OnOpen = onOpen }
end

return AchievementsMenu
