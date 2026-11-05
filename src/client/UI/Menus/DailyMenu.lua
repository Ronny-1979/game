--!strict
-- DailyMenu: tägliche Belohnung mit 7-Tage-Serie
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Daily = require(Config:WaitForChild("Daily")) :: any
local Zones = require(Config:WaitForChild("Zones")) :: any
local Util = require(Shared:WaitForChild("Util"))
local Goals = require(Shared:WaitForChild("Goals"))
local Progression = require(Shared:WaitForChild("Progression"))
local Controllers = script.Parent.Parent.Parent:WaitForChild("Controllers")
local DataController = require(Controllers:WaitForChild("DataController"))
local SoundController = require(Controllers:WaitForChild("SoundController"))

local DailyMenu = {}

function DailyMenu.IsAvailable(data: any): boolean
	if not data then
		return false
	end
	local ok = Goals.DailyState(data, Goals.Day(workspace:GetServerTimeNow()), #Daily.Belohnungen)
	return ok
end

function DailyMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("🎁 Täglicher Bonus")
	local info = C.Label({ Text = "", Size = UDim2.new(1, 0, 0, 34), MaxTextSize = 22, Parent = content })
	local grid = Instance.new("Frame")
	grid.BackgroundTransparency = 1
	grid.Position = UDim2.fromOffset(0, 42)
	grid.Size = UDim2.new(1, 0, 1, -116)
	grid.Parent = content
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0.25, -8, 0.5, -8)
	layout.CellPadding = UDim2.fromOffset(8, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	local claim = C.Button({
		Text = "🎁 Abholen!",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(0.5, 0, 0, 60),
		BackgroundColor3 = Theme.Good,
		OnClick = function()
			local r = UI.Request("ClaimDaily")
			if r.ok then
				SoundController.Play("Ei", 1.2)
				UI.Flash()
			end
		end,
		Parent = content,
	})

	local function refresh(data: any)
		C.Clear(grid)
		local today = Goals.Day(workspace:GetServerTimeNow())
		local available, nextDay = Goals.DailyState(data, today, #Daily.Belohnungen)
		local stats = DataController.Stats
		local best = 1
		for i = 1, #Zones do
			if Progression.IsZoneUnlocked(data, i) then
				best = i
			end
		end
		local zoneValue = Zones[best].Energiewert
		for day, reward in Daily.Belohnungen do
			local done = if available then day < nextDay else day <= nextDay
			local isNext = available and day == nextDay
			local card = C.Frame({
				BackgroundColor3 = if isNext then Color3.fromRGB(255, 240, 180) elseif done then Theme.Mint else Theme.Panel,
				LayoutOrder = day,
				Parent = grid,
			})
			C.Stroke(card, if isNext then Theme.Copper else Theme.PanelDark, if isNext then 4 else 2)
			C.Label({ Text = ("Tag %d"):format(day), Size = UDim2.new(1, 0, 0.2, 0), MaxTextSize = 20, Parent = card })
			C.Label({ Text = if done then "✅" else reward.Symbol, Size = UDim2.new(1, 0, 0.36, 0), Position = UDim2.fromScale(0, 0.2), MaxTextSize = 44, Parent = card })
			local lines = {}
			if reward.Energie then
				local mult = if stats then stats.TotalEnergyMult else 1
				table.insert(lines, Util.FormatNumber(reward.Energie * zoneValue * mult) .. " ⚡")
			end
			if reward.XP then
				table.insert(lines, reward.XP .. " XP")
			end
			if reward.Ei then
				table.insert(lines, "🥚 Ei")
			end
			if reward.RebirthPunkte then
				table.insert(lines, "♻️ +" .. reward.RebirthPunkte)
			end
			C.Label({ Text = table.concat(lines, "\n"), Size = UDim2.new(1, -6, 0.42, 0), Position = UDim2.new(0, 3, 0.56, 0), TextColor3 = Theme.BrassDark, MaxTextSize = 15, Parent = card })
		end
		if available then
			info.Text = ("Serie: Tag %d – hol dir deine Belohnung!"):format(nextDay)
			claim.Visible = true
		else
			local left = 86400 - (workspace:GetServerTimeNow() % 86400)
			info.Text = ("✅ Heute abgeholt! Nächster Bonus in %d h %d min"):format(math.floor(left / 3600), math.floor(left % 3600 / 60))
			claim.Visible = false
		end
	end

	return { Frame = win, Refresh = refresh }
end

return DailyMenu
