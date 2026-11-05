--!strict
-- IslandMenu: eigene Werkstatt-Insel – Deko kaufen/platzieren, abbauen, andere Werkstätten besuchen
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Deco = require(Shared:WaitForChild("Config"):WaitForChild("Deco")) :: any
local Util = require(Shared:WaitForChild("Util"))
local Progression = require(Shared:WaitForChild("Progression"))
local Controllers = script.Parent.Parent.Parent:WaitForChild("Controllers")
local DataController = require(Controllers:WaitForChild("DataController"))
local IslandController = require(Controllers:WaitForChild("IslandController"))

local IslandMenu = {}

local player = Players.LocalPlayer

function IslandMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("🏡 Meine Werkstatt")

	local header = C.Frame({ Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = Theme.Mint, Parent = content })
	local headerLabel = C.Label({ Text = "", Size = UDim2.new(0.62, -10, 1, -6), Position = UDim2.fromOffset(8, 3), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 18, Parent = header })
	local goButton = C.Button({
		Text = "🏡 Zur Werkstatt",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(0.36, 0, 0, 38),
		BackgroundColor3 = Theme.Good,
		OnClick = function()
			local r = UI.Request("EnterIsland")
			if r.ok then
				UI.Close()
			end
		end,
		Parent = header,
	})

	local catalog = C.List({ Position = UDim2.fromOffset(0, 54), Size = UDim2.new(0.66, -6, 1, -54), Parent = content }, UDim2.fromOffset(120, 128))
	local side = C.Frame({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 54), Size = UDim2.new(0.34, -4, 1, -54), BackgroundColor3 = Theme.Panel, Parent = content })
	C.Stroke(side, Theme.PanelDark, 2)
	C.Button({
		Text = "🔨 Abbauen",
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(1, -16, 0, 42),
		BackgroundColor3 = Theme.Copper,
		OnClick = function()
			UI.Close()
			IslandController.StartRemove()
		end,
		Parent = side,
	})
	C.Label({ Text = "👥 Werkstätten besuchen", Position = UDim2.fromOffset(8, 58), Size = UDim2.new(1, -16, 0, 26), MaxTextSize = 18, Parent = side })
	local visits = C.List({ Position = UDim2.fromOffset(4, 88), Size = UDim2.new(1, -8, 1, -92), Parent = side })

	local lastSig = ""
	local function refresh(data: any)
		local onOwn = player:GetAttribute("Ort") == "Insel" and player:GetAttribute("IslandOwnerId") == player.UserId
		local items = data.Island and data.Island.Items or {}
		local bonus = math.min(#items * Deco.BonusProDeko, Deco.BonusMax)
		headerLabel.Text = ("Werkstatt-Bonus: +%d %% Energie   ·   %d/%d Teile\nJedes Deko-Stück: +%s %% (bis +%d %%)"):format(
			math.floor(bonus * 100 + 0.5),
			#items,
			Deco.MaxDeko,
			tostring(Deco.BonusProDeko * 100),
			math.floor(Deco.BonusMax * 100)
		)
		goButton.Visible = not onOwn
		local names = {}
		for _, p in Players:GetPlayers() do
			table.insert(names, p.UserId)
		end
		local sig = HttpService:JSONEncode({ math.floor(data.Energy), items, data.UnlockedZones, data.BossesDefeated, onOwn, names, Progression.BestZone(data) })
		if sig == lastSig then
			return
		end
		lastSig = sig

		C.Clear(catalog)
		for i, item in Deco.Katalog do
			local unlocked, why = Progression.DecoUnlocked(item, data)
			local price = Progression.DecoPrice(item, data)
			local placedTrophy = false
			if item.Boss then
				for _, e in items do
					if e.Id == item.Id then
						placedTrophy = true
					end
				end
			end
			local card = C.Button({
				Text = "",
				BackgroundColor3 = if unlocked and not placedTrophy then Theme.Panel else Theme.PanelDark,
				LayoutOrder = i,
				OnClick = function()
					if not unlocked then
						UI.Toast(why or "Noch gesperrt.", "info")
						return
					end
					if placedTrophy then
						UI.Toast("Diesen Pokal hast du schon aufgestellt.", "info")
						return
					end
					if not onOwn then
						UI.Toast("Geh zuerst in deine Werkstatt („🏡 Zur Werkstatt“).", "info")
						return
					end
					UI.Close()
					IslandController.StartPlace(item)
				end,
				Parent = catalog,
			})
			C.Stroke(card, if item.Boss then Theme.Brass else Theme.PanelDark, 2)
			C.Label({ Text = item.Symbol, Size = UDim2.new(1, 0, 0, 46), Position = UDim2.fromOffset(0, 4), MaxTextSize = 38, Parent = card })
			C.Label({ Text = item.Name, Size = UDim2.new(1, -6, 0, 36), Position = UDim2.fromOffset(3, 50), MaxTextSize = 15, Parent = card })
			local priceText = if not unlocked then (why or "🔒") elseif placedTrophy then "✅ steht schon" elseif price > 0 then Util.FormatNumber(price) .. " ⚡" else "gratis"
			C.Label({
				Text = priceText,
				Size = UDim2.new(1, -6, 0, 30),
				Position = UDim2.fromOffset(3, 90),
				TextColor3 = if unlocked and price <= data.Energy then Theme.BrassDark else Theme.Bad,
				MaxTextSize = 14,
				Parent = card,
			})
			if (item.Groesse or 1) > 1 then
				C.Label({ Text = "2×2", Size = UDim2.fromOffset(34, 18), Position = UDim2.fromOffset(4, 4), TextColor3 = Theme.Copper, MaxTextSize = 13, Parent = card })
			end
		end

		C.Clear(visits)
		local order = 0
		for _, p in Players:GetPlayers() do
			order += 1
			local mine = p == player
			C.Button({
				Text = if mine then "🏡 Meine" else ("👋 " .. p.DisplayName),
				Size = UDim2.new(1, -6, 0, 40),
				BackgroundColor3 = if mine then Theme.Good else Theme.Info,
				LayoutOrder = if mine then 0 else order,
				MaxTextSize = 18,
				OnClick = function()
					local r = UI.Request(if mine then "EnterIsland" else "VisitIsland", if mine then nil else p.UserId)
					if r.ok then
						UI.Close()
					end
				end,
				Parent = visits,
			})
		end
	end

	local function onOpen(_args: any)
		lastSig = ""
	end

	return { Frame = win, Refresh = refresh, OnOpen = onOpen }
end

return IslandMenu
