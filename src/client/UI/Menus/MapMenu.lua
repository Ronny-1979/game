--!strict
-- MapMenu: Zonen-Karte mit Teleport und Schnellstart der Strecken
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Zones = require(Config:WaitForChild("Zones")) :: any
local Difficulty = require(Config:WaitForChild("Difficulty")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local Progression = require(Shared:WaitForChild("Progression"))

local MapMenu = {}

function MapMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("🗺️ Karte")
	local diffRow = Instance.new("Frame")
	diffRow.BackgroundTransparency = 1
	diffRow.Size = UDim2.new(1, 0, 0, 42)
	diffRow.Parent = content
	local dl = Instance.new("UIListLayout")
	dl.FillDirection = Enum.FillDirection.Horizontal
	dl.Padding = UDim.new(0, 8)
	dl.Parent = diffRow
	local list = C.List({ Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -50), Parent = content })

	local lastSig = ""
	local function refresh(data: any)
		local sig = HttpService:JSONEncode({ data.Level, data.UnlockedZones, data.BossesDefeated, data.BestTimes, data.Settings.Difficulty })
		if sig == lastSig then
			return
		end
		lastSig = sig
		C.Clear(diffRow)
		C.Label({ Text = "Schwierigkeit:", Size = UDim2.fromOffset(140, 40), MaxTextSize = 20, Parent = diffRow })
		for _, d in Difficulty.Reihenfolge do
			local cfg = Difficulty.Stufen[d]
			local active = data.Settings.Difficulty == d
			C.Button({
				Text = cfg.Symbol .. " " .. cfg.Name,
				Size = UDim2.fromOffset(130, 40),
				BackgroundColor3 = if active then cfg.Farbe else Theme.Locked,
				TextColor3 = Theme.Text,
				OnClick = function()
					Remotes.Event("ChangeSetting"):FireServer("Difficulty", d)
				end,
				Parent = diffRow,
			})
		end

		C.Clear(list)
		local hub = C.Frame({ Size = UDim2.new(1, -6, 0, 60), BackgroundColor3 = Theme.Panel, LayoutOrder = 0, Parent = list })
		C.Stroke(hub, Theme.Brass, 2)
		C.Label({ Text = "🏝️ Hub-Insel – Shop, Eier, Rebirth, Skills", Size = UDim2.new(0.7, -10, 1, -8), Position = UDim2.fromOffset(10, 4), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 22, Parent = hub })
		C.Button({ Text = "Hinreisen", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.25, 0, 0, 44), BackgroundColor3 = Theme.Info, OnClick = function()
			UI.Request("TeleportZone", 0)
			UI.Close()
		end, Parent = hub })

		local diff = data.Settings.Difficulty
		for i, zone in ipairs(Zones) do
			local unlocked = Progression.IsZoneUnlocked(data, i)
			local row = C.Frame({ Size = UDim2.new(1, -6, 0, 150), BackgroundColor3 = if unlocked then Theme.Panel else Theme.PanelDark, LayoutOrder = i, Parent = list })
			C.Stroke(row, zone.Farben.Akzent, 3)
			C.Frame({ Size = UDim2.new(0, 10, 1, -12), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = zone.Farben.Boden, Radius = 4, Parent = row })
			local boss = if data.BossesDefeated[zone.Id] then "  👑✔" else ""
			C.Label({
				Text = ("%d · %s%s"):format(i, zone.Name, boss),
				Size = UDim2.new(0.7, -24, 0, 32),
				Position = UDim2.fromOffset(22, 4),
				TextXAlignment = Enum.TextXAlignment.Left,
				MaxTextSize = 24,
				Parent = row,
			})
			local status = if unlocked then zone.Beschreibung else ("🔒 Ab Level %d oder nach dem Boss der vorherigen Zone"):format(zone.FreischaltLevel)
			C.Label({ Text = status, Size = UDim2.new(0.7, -24, 0, 36), Position = UDim2.fromOffset(22, 36), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.BrassDark, MaxTextSize = 16, Parent = row })
			C.Button({
				Text = if unlocked then "Hinreisen" else "🔒",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -8, 0, 8),
				Size = UDim2.new(0.25, 0, 0, 44),
				BackgroundColor3 = if unlocked then Theme.Info else Theme.Locked,
				OnClick = function()
					local r = UI.Request("TeleportZone", i)
					if r.ok then
						UI.Close()
					end
				end,
				Parent = row,
			})
			-- Schnellstart der 3 Strecken
			for t, track in zone.Strecken do
				local key = Progression.TrackKey(i, t)
				local best = data.BestTimes[key] and data.BestTimes[key][diff]
				C.Button({
					Text = ("▶ %s\n%s"):format(track.Name, if best then ("🏆 " .. Util.FormatTime(best)) else "noch keine Zeit"),
					Position = UDim2.new((t - 1) / 3, 22 - (t - 1) * 8, 0, 78),
					Size = UDim2.new(1 / 3, -16, 0, 62),
					BackgroundColor3 = if unlocked then Difficulty.Stufen[diff].Farbe else Theme.Locked,
					TextColor3 = Theme.Text,
					MaxTextSize = 17,
					OnClick = function()
						local r = UI.Request("StartTrack", i, t, diff)
						if r.ok then
							UI.Close()
						end
					end,
					Parent = row,
				})
			end
		end
	end

	return { Frame = win, Refresh = refresh }
end

return MapMenu
