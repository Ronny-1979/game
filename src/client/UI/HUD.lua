--!strict
--[[
	HUD: Energie, XP-Leiste, Level, Zone, Streckenzeit, Boss-Leiste,
	Menü-Knöpfe (links) und Skill-Leiste mit Abklingzeit-Kreisen (unten).
	Passt sich an PC, Tablet und Handy an (UIScale + größere Knöpfe bei Touch).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Zones = require(Config:WaitForChild("Zones")) :: any
local Skills = require(Config:WaitForChild("Skills")) :: any
local Difficulty = require(Config:WaitForChild("Difficulty")) :: any
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Progression = require(Shared:WaitForChild("Progression"))
local Controllers = script.Parent.Parent:WaitForChild("Controllers")
local DataController = require(Controllers:WaitForChild("DataController"))
local AbilityController = require(Controllers:WaitForChild("AbilityController"))
local SoundController = require(Controllers:WaitForChild("SoundController"))
local QuestController = require(Controllers:WaitForChild("QuestController"))
local Quests = require(Config:WaitForChild("Quests")) :: any
local Events = require(Config:WaitForChild("Events")) :: any

local HUD = {}

local player = Players.LocalPlayer

local function addScale(frame: GuiObject): UIScale
	local s = Instance.new("UIScale")
	s.Parent = frame
	return s
end

function HUD.Build(UI: any)
	local C = UI.C
	local Theme = UI.Theme
	local root: Frame = UI.Hud
	local rescaleNow: () -> () = function() end
	local touch = UI.IsTouch()
	local scales: { UIScale } = {}

	-- ===== Oben links: Energie, Level, XP =====
	local stats = C.Frame({ Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(270, 112), BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.08, Parent = root })
	C.Stroke(stats, Theme.Brass, 3)
	table.insert(scales, addScale(stats))
	local energy = C.Label({ Text = "⚡ 0", Size = UDim2.new(1, -16, 0, 40), Position = UDim2.fromOffset(10, 6), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(40, 140, 200), MaxTextSize = 34, Parent = stats })
	local levelBadge = C.Frame({ Position = UDim2.fromOffset(10, 50), Size = UDim2.fromOffset(62, 30), BackgroundColor3 = Theme.Copper, Parent = stats })
	local levelLabel = C.Label({ Text = "Lv 1", Size = UDim2.fromScale(1, 1), TextColor3 = Theme.TextLight, MaxTextSize = 22, Parent = levelBadge })
	local xpBar = C.Bar({ Position = UDim2.fromOffset(80, 54), Size = UDim2.new(1, -92, 0, 22), Parent = stats }, Theme.Lilac)
	local xpLabel = C.Label({ Text = "0 / 50 XP", Size = UDim2.fromScale(1, 1), TextColor3 = Theme.TextLight, TextStrokeTransparency = 0.5, MaxTextSize = 16, ZIndex = 3, Parent = xpBar.Frame })
	local multi = C.Label({ Text = "", Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(10, 84), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 18, Parent = stats })

	-- ===== Aufgaben-Anzeige (unter Energie) =====
	local quest = C.Button({
		Text = "",
		Position = UDim2.fromOffset(12, 132),
		Size = UDim2.fromOffset(270, 66),
		BackgroundColor3 = Color3.fromRGB(255, 248, 215),
		OnClick = function()
			UI.Toggle("Aufgabe")
		end,
		Parent = root,
	})
	C.Stroke(quest, Theme.Copper, 3)
	local questScale = addScale(quest)
	table.insert(scales, questScale)
	local questTitle = C.Label({ Text = "", Size = UDim2.new(1, -12, 0, 28), Position = UDim2.fromOffset(6, 3), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 20, Parent = quest })
	local questInfo = C.Label({ Text = "", Size = UDim2.new(1, -12, 0, 26), Position = UDim2.fromOffset(6, 33), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.BrassDark, MaxTextSize = 16, Parent = quest })
	local lastQuestIndex = -1

	-- ===== Event- und Freunde-Banner (unter der Aufgabe) =====
	local banner = C.Frame({ Position = UDim2.fromOffset(12, 206), Size = UDim2.fromOffset(270, 34), BackgroundColor3 = Color3.fromRGB(255, 225, 150), Visible = false, Parent = root })
	C.Stroke(banner, Theme.Boss, 3)
	table.insert(scales, addScale(banner))
	local bannerLabel = C.Label({ Text = "", Size = UDim2.new(1, -12, 1, -6), Position = UDim2.fromOffset(6, 3), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 16, Parent = banner })
	local function updateBanner()
		local parts = {}
		local names = ReplicatedStorage:GetAttribute("EventNames")
		if type(names) == "string" and names ~= "" then
			table.insert(parts, "🎉 " .. names)
		end
		local friends = (player:GetAttribute("FriendCount") :: number?) or 0
		if friends > 0 then
			table.insert(parts, ("👥 %d Freund%s da: +%d %% ⚡"):format(friends, if friends == 1 then "" else "e", math.floor(math.min(friends * Events.Freunde.ProFreund, Events.Freunde.Maximal) * 100 + 0.5)))
		end
		banner.Visible = #parts > 0
		bannerLabel.Text = table.concat(parts, "\n")
		banner.Size = UDim2.fromOffset(270, if #parts > 1 or (names and #tostring(names) > 34) then 52 else 34)
	end
	ReplicatedStorage:GetAttributeChangedSignal("EventNames"):Connect(updateBanner)
	player:GetAttributeChangedSignal("FriendCount"):Connect(updateBanner)
	updateBanner()

	-- ===== Oben Mitte: Zone, Streckenzeit, Boss =====
	local top = Instance.new("Frame")
	top.BackgroundTransparency = 1
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.new(0.5, 0, 0, 10)
	top.Size = UDim2.fromOffset(420, 160)
	top.Parent = root
	table.insert(scales, addScale(top))
	local zoneFrame = C.Frame({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(300, 38), BackgroundColor3 = Theme.Brass, Parent = top })
	local zoneLabel = C.Label({ Text = "📍 Hub-Insel", Size = UDim2.new(1, -12, 1, -6), Position = UDim2.fromOffset(6, 3), TextColor3 = Theme.TextLight, MaxTextSize = 24, Parent = zoneFrame })
	local timer = C.Frame({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 44), Size = UDim2.fromOffset(320, 44), BackgroundColor3 = Theme.Panel, Visible = false, Parent = top })
	C.Stroke(timer, Theme.Copper, 3)
	local timerLabel = C.Label({ Text = "⏱ 0:00,00", Size = UDim2.new(1, -12, 1, -6), Position = UDim2.fromOffset(6, 3), TextColor3 = Theme.Copper, MaxTextSize = 30, Parent = timer })
	local boss = C.Frame({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 94), Size = UDim2.fromOffset(400, 58), BackgroundColor3 = Theme.Panel, Visible = false, Parent = top })
	C.Stroke(boss, Theme.Boss, 3)
	local bossName = C.Label({ Text = "", Size = UDim2.new(1, -12, 0, 24), Position = UDim2.fromOffset(6, 3), MaxTextSize = 22, Parent = boss })
	local bossBar = C.Bar({ Position = UDim2.fromOffset(10, 30), Size = UDim2.new(1, -20, 0, 20), Parent = boss }, Theme.Boss)

	-- ===== Links: Menü-Knöpfe =====
	local menu = Instance.new("Frame")
	menu.BackgroundTransparency = 1
	menu.AnchorPoint = Vector2.new(0, 0.5)
	menu.Position = UDim2.new(0, 12, 0.62, 0)
	menu.Size = UDim2.new(0, 150, 0.54, 0)
	menu.Parent = root
	table.insert(scales, addScale(menu))
	local grid = Instance.new("UIGridLayout")
	local cell = if touch then 64 else 60
	grid.CellSize = UDim2.fromOffset(cell, cell)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.FillDirection = Enum.FillDirection.Vertical
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = menu

	local buttons = {
		{ "🎁", "Bonus", "Bonus" },
		{ "🏅", "Erfolge", "Erfolge" },
		{ "🛒", "Shop", "Shop" },
		{ "🐾", "Pets", "Pets" },
		{ "🌳", "Skills", "Skills" },
		{ "♻️", "Rebirth", "Rebirth" },
		{ "🗺️", "Karte", "Karte" },
		{ "🏆", "Beste", "Bestenliste" },
		{ "💬", "Chat", "Chat" },
		{ "👥", "Einladen", "__invite" },
		{ "⚙️", "Optionen", "Einstellungen" },
	}
	local function invite()
		local ok, can = pcall(function()
			return SocialService:CanSendGameInviteAsync(player)
		end)
		if ok and can then
			pcall(function()
				SocialService:PromptGameInvite(player)
			end)
		else
			UI.Toast("Einladen ist hier gerade nicht möglich.", "info")
		end
	end
	local function menuButton(icon: string, caption: string, target: string, order: number): TextButton
		local b = C.Button({
			Text = "",
			BackgroundColor3 = Theme.Panel,
			LayoutOrder = order,
			OnClick = function()
				if target == "__invite" then
					invite()
				else
					UI.Toggle(target)
				end
			end,
			Parent = menu,
		})
		C.Stroke(b, Theme.Brass, 3)
		C.Label({ Text = icon, Size = UDim2.new(1, 0, 0.66, 0), MaxTextSize = 30, Parent = b })
		C.Label({ Text = caption, Size = UDim2.new(1, 0, 0.32, 0), Position = UDim2.fromScale(0, 0.66), MaxTextSize = 13, Parent = b })
		return b
	end
	local bonusButton: TextButton? = nil
	for i, def in buttons do
		local b = menuButton(def[1], def[2], def[3], i)
		if def[3] == "Bonus" then
			bonusButton = b
		end
	end
	-- roter Punkt, wenn der Tagesbonus bereit ist
	local dot = C.Frame({ Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -12, 0, -4), BackgroundColor3 = Theme.Bad, Radius = 8, Visible = false, ZIndex = 5, Parent = bonusButton })
	local DailyMenu = require(script.Parent:WaitForChild("Menus"):WaitForChild("DailyMenu"))
	task.spawn(function()
		while true do
			dot.Visible = DailyMenu.IsAvailable(DataController.Data)
			task.wait(2)
		end
	end)
	local adminButton = menuButton("🔧", "Admin", "Admin", 99)
	adminButton.Visible = player:GetAttribute("IsAdmin") == true
	player:GetAttributeChangedSignal("IsAdmin"):Connect(function()
		adminButton.Visible = player:GetAttribute("IsAdmin") == true
	end)

	-- ===== Unten: Skill-Leiste =====
	local bar = Instance.new("Frame")
	bar.BackgroundTransparency = 1
	local size = if touch then 74 else 68
	if touch then
		-- über dem Sprung-Knopf von Roblox
		bar.AnchorPoint = Vector2.new(1, 1)
		bar.Position = UDim2.new(1, -14, 1, -168)
	else
		bar.AnchorPoint = Vector2.new(0.5, 1)
		bar.Position = UDim2.new(0.5, 0, 1, -18)
	end
	bar.Size = UDim2.fromOffset(5 * (size + 10), size + 22)
	bar.Parent = root
	table.insert(scales, addScale(bar))
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = if touch then Enum.HorizontalAlignment.Right else Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.Padding = UDim.new(0, 10)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = bar

	type Slot = { Name: string, Frame: GuiObject, Radial: any, Time: TextLabel }
	local slots: { Slot } = {}
	local function buildSlots()
		for _, s in slots do
			s.Frame:Destroy()
		end
		table.clear(slots)
		for i, name in AbilityController.Available() do
			local def = Skills.Faehigkeiten[name]
			local b = C.Button({
				Text = "",
				Size = UDim2.fromOffset(size, size),
				BackgroundColor3 = Theme.Panel,
				LayoutOrder = i,
				Radius = 999,
				OnClick = function()
					AbilityController.Use(name)
				end,
				Parent = bar,
			})
			C.Stroke(b, Theme.Brass, 3)
			C.Label({ Text = def.Symbol, Size = UDim2.fromScale(0.62, 0.62), Position = UDim2.fromScale(0.19, 0.12), MaxTextSize = 34, Parent = b })
			if not touch then
				local key = C.Frame({ Size = UDim2.fromOffset(22, 22), Position = UDim2.new(0, -4, 0, -4), BackgroundColor3 = Theme.Copper, Radius = 6, ZIndex = 5, Parent = b })
				C.Label({ Text = def.Taste, Size = UDim2.fromScale(1, 1), TextColor3 = Theme.TextLight, MaxTextSize = 16, ZIndex = 6, Parent = key })
			end
			C.Label({ Text = if def.Kosten > 0 then (def.Kosten .. "⚡") else def.Name, Size = UDim2.new(1, 8, 0, 16), Position = UDim2.new(0, -4, 1, 2), MaxTextSize = 13, Parent = b })
			local radial = C.Radial(b)
			local t = C.Label({ Text = "", Size = UDim2.fromScale(0.6, 0.5), Position = UDim2.fromScale(0.2, 0.25), TextColor3 = Theme.TextLight, TextStrokeTransparency = 0.2, MaxTextSize = 26, ZIndex = b.ZIndex + 5, Parent = b })
			table.insert(slots, { Name = name, Frame = b, Radial = radial, Time = t })
		end
	end
	buildSlots()

	-- ===== Responsiv =====
	local function rescale()
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local vp = cam.ViewportSize
		local s = math.clamp(math.min(vp.X / 1150, vp.Y / 680), 0.62, 1.3)
		for _, sc in scales do
			sc.Scale = s
		end
	end
	rescaleNow = rescale
	rescale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end

	-- ===== Werte aktualisieren =====
	local lastClass = ""
	local function refresh(data: any)
		local s = DataController.Stats
		energy.Text = "⚡ " .. Util.FormatNumber(data.Energy)
		levelLabel.Text = "Lv " .. data.Level
		local need = Progression.XPForLevel(data.Level)
		xpBar.Set(data.XP / math.max(1, need))
		xpLabel.Text = ("%s / %s XP"):format(Util.FormatNumber(data.XP), Util.FormatNumber(need))
		if s then
			local m = s.TotalEnergyMult
			local mText = if m < 1000 then string.format("%.1f", m) else Util.FormatNumber(m)
			multi.Text = ("✨ x%s Energie   ♻️ %d"):format(mText, data.Rebirths)
		end
		-- Aufgabe
		local qi = data.Quest and data.Quest.Index or 1
		local q = Quests.Liste[qi]
		if q then
			questTitle.Text = "📜 " .. q.Titel
		else
			questTitle.Text = "🏆 Alle Aufgaben geschafft!"
			questInfo.Text = "Jetzt: Bestzeiten & Profi-Bahnen!"
		end
		if qi ~= lastQuestIndex then
			-- neue Aufgabe: kurz aufploppen
			if lastQuestIndex ~= -1 then
				questScale.Scale *= 1.15
				task.delay(0.25, function()
					rescaleNow()
				end)
			end
			lastQuestIndex = qi
		end
		if data.Class ~= lastClass then
			lastClass = data.Class
			buildSlots()
		end
	end
	DataController.Changed:Connect(refresh)
	if DataController.Data then
		refresh(DataController.Data)
	end

	local function updateZone()
		local ort = player:GetAttribute("Ort")
		if ort == "Turm" then
			zoneLabel.Text = ("🗼 Endlos-Turm · Etage %d"):format((player:GetAttribute("TowerFloor") :: number?) or 1)
			return
		elseif ort == "Insel" then
			local owner = player:GetAttribute("IslandOwner")
			zoneLabel.Text = if owner and owner ~= player.Name then ("🏡 Werkstatt von %s"):format(tostring(owner)) else "🏡 Meine Werkstatt"
			return
		end
		local z = (player:GetAttribute("Zone") :: number?) or 0
		local zone = Zones[z]
		zoneLabel.Text = if zone then ("📍 %s"):format(zone.Name) else "📍 Hub-Insel"
	end
	player:GetAttributeChangedSignal("Zone"):Connect(updateZone)
	player:GetAttributeChangedSignal("Ort"):Connect(updateZone)
	player:GetAttributeChangedSignal("TowerFloor"):Connect(updateZone)
	player:GetAttributeChangedSignal("IslandOwner"):Connect(updateZone)
	updateZone()

	Remotes.Event("BossUi").OnClientEvent:Connect(function(info: any)
		if type(info) == "table" then
			boss.Visible = true
			bossName.Text = ("👑 %s – Phase %d%s"):format(info.Name, info.Phase, if info.Tired then "  💤" else "")
			bossBar.Set(info.Hp / math.max(1, info.Max))
			SoundController.SetMusic("Boss")
		else
			boss.Visible = false
			SoundController.UpdateZoneMusic()
		end
	end)

	RunService.RenderStepped:Connect(function()
		-- Streckenzeit
		local start = player:GetAttribute("CourseStart")
		if type(start) == "number" then
			timer.Visible = true
			local diff = Difficulty.Stufen[(player:GetAttribute("CourseDiff") :: string?) or ""]
			timerLabel.Text = ("%s ⏱ %s"):format(diff and diff.Symbol or "", Util.FormatTime(workspace:GetServerTimeNow() - start))
		else
			timer.Visible = false
		end
		-- Aufgaben-Zeile 2: Fortschritt + Entfernung
		local data = DataController.Data
		local q = data and data.Quest and Quests.Liste[data.Quest.Index]
		if q then
			local parts = {}
			local need = q.Anzahl or 1
			if q.Art == "Level" then
				table.insert(parts, ("Lv %d/%d"):format(data.Level, q.Wert or 1))
			elseif need > 1 then
				table.insert(parts, ("%d/%d"):format(data.Quest.Progress, need))
			end
			if QuestController.Hint then
				table.insert(parts, "🧭 " .. QuestController.Hint)
			elseif QuestController.Distance then
				table.insert(parts, ("🧭 %d m"):format(math.floor(QuestController.Distance / 3.5 + 0.5)))
			else
				table.insert(parts, "Tippen für Infos")
			end
			questInfo.Text = table.concat(parts, "  ·  ")
		end
		-- Abklingzeiten
		for _, s in slots do
			local left, total = AbilityController.GetCooldown(s.Name)
			s.Radial.Set(if total > 0 then left / total else 0)
			s.Time.Text = if left > 0 then tostring(math.ceil(left)) else ""
		end
	end)
end

return HUD
