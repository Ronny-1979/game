--!strict
--[[
	UIController: Wurzel der gesamten Oberfläche (komplett per Code gebaut).
	- Toasts (Hinweis-Meldungen), schwebende Zahlen, Bildschirm-Blitz
	- Fenster-Verwaltung: immer nur ein Menü offen, Hintergrund abgedunkelt
	- Request(): RemoteFunction aufrufen + Fehler als Toast zeigen
	- Geräte: Handy/Tablet (Touch), PC (Maus), Xbox/PlayStation (Controller) – siehe Device.lua
	  · alles bleibt im sicheren Bereich (Notch, Roblox-Leiste oben)
	  · Fenster und HUD werden passend zur Bildschirmgröße skaliert (Konsole: größer für den Fernseher)
	  · Controller: Y = Menü, B = Fenster schließen, Steuerkreuz/Stick = auswählen, A = bestätigen
	  · PC: M = Menü
]]
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local C = require(script.Parent:WaitForChild("Components"))
local Device = require(script.Parent:WaitForChild("Device"))
local Controllers = script.Parent.Parent:WaitForChild("Controllers")
local DataController = require(Controllers:WaitForChild("DataController"))
local SoundController = require(Controllers:WaitForChild("SoundController"))

local UI = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local hudLayer: Frame
local windowLayer: Frame
local overlay: TextButton
local toastLayer: Frame
local flash: Frame
local effectHandler: ((string, Vector3) -> ())? = nil

type Menu = { Frame: GuiObject, Refresh: ((any) -> ())?, OnOpen: ((any) -> ())?, OnClose: (() -> ())?, Modal: boolean? }
local menus: { [string]: Menu } = {}
local openName: string? = nil

-- Grundgröße eines Fensters (wird je nach Bildschirm skaliert)
local WINDOW_BASE = Vector2.new(820, 580)
local windows: { Frame } = {}

UI.Gui = nil :: ScreenGui?
UI.Hud = nil :: Frame?
UI.Theme = Theme
UI.C = C
UI.Device = Device

-- Menü-Knöpfe (HUD-Leiste und ☰-Menü). Reihenfolge = Wichtigkeit: auf kleinen Bildschirmen
-- passen nicht alle in die Leiste, dann landen die hinteren nur im ☰-Menü.
UI.MenuButtons = {
	{ Icon = "🐾", Name = "Pets", Target = "Pets" },
	{ Icon = "🗺️", Name = "Karte", Target = "Karte" },
	{ Icon = "🛒", Name = "Shop", Target = "Shop" },
	{ Icon = "🎁", Name = "Bonus", Target = "Bonus" },
	{ Icon = "🌳", Name = "Skills", Target = "Skills" },
	{ Icon = "🏅", Name = "Erfolge", Target = "Erfolge" },
	{ Icon = "♻️", Name = "Rebirth", Target = "Rebirth" },
	{ Icon = "🏆", Name = "Beste", Target = "Bestenliste" },
	{ Icon = "💬", Name = "Chat", Target = "Chat" },
	{ Icon = "👥", Name = "Einladen", Target = "__invite" },
	{ Icon = "⚙️", Name = "Optionen", Target = "Einstellungen" },
}

function UI.CurrentZone(): number
	return (player:GetAttribute("Zone") :: number?) or 0
end

-- Wird gerade mit dem Finger gespielt? (wechselt live, z.B. Tablet mit Tastatur)
function UI.IsTouch(): boolean
	return Device.IsTouch()
end

-- Größe des sicheren Bildschirmbereichs (ohne Notch und Roblox-Leiste)
function UI.ScreenSize(): Vector2
	if gui and gui.AbsoluteSize.X > 0 then
		return gui.AbsoluteSize
	end
	local cam = workspace.CurrentCamera
	return if cam then cam.ViewportSize else Vector2.new(1280, 720)
end

-- Skalierung für HUD-Elemente: Handy kleiner, großer Monitor/Fernseher größer
function UI.HudScale(): number
	local vp = UI.ScreenSize()
	local s = math.clamp(math.min(vp.X / 1150, vp.Y / 680), 0.62, 1.3)
	if Device.IsConsole() then
		s = math.clamp(s * 1.12, 0.9, 1.45)
	end
	return s
end

local function windowScale(): number
	local vp = UI.ScreenSize()
	local fit = math.min(vp.X * 0.96 / WINDOW_BASE.X, vp.Y * 0.94 / WINDOW_BASE.Y)
	local cap = if Device.IsConsole() then 1.4 elseif vp.Y >= 1000 then 1.15 else 1
	return math.clamp(fit, 0.72, cap)
end

-- Fenstergröße an den Bildschirm anpassen (Inhalte sind für 820×580 gebaut)
local function layoutWindow(win: Frame)
	local vp = UI.ScreenSize()
	local s = windowScale()
	local w = math.min(WINDOW_BASE.X, vp.X * 0.96 / s)
	local h = math.min(WINDOW_BASE.Y, vp.Y * 0.94 / s)
	win.Size = UDim2.fromOffset(math.floor(w), math.floor(h))
	local scale = win:FindFirstChild("PopScale") :: UIScale?
	if scale then
		scale:SetAttribute("Target", s)
		scale.Scale = s
	end
end

local function layoutAll()
	for _, win in windows do
		layoutWindow(win)
	end
	-- Meldungen oben rechts: unter Roblox-Knöpfe rutschen, falls die dort im Bild liegen (manche Handys)
	if toastLayer and gui then
		local tb = GuiService.TopbarInset
		local y = 12
		if tb.Height > 0 then
			local inset = GuiService:GetGuiInset()
			local right = gui.AbsolutePosition.X + inset.X + gui.AbsoluteSize.X - 12
			local top = gui.AbsolutePosition.Y + inset.Y
			if right > tb.Max.X and top + 12 < tb.Max.Y then
				y = math.ceil(tb.Max.Y - top) + 8
			end
		end
		toastLayer.Position = UDim2.new(1, -12, 0, y)
	end
end

-- Einladen (Roblox-Fenster)
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

-- Ziel eines Menü-Knopfs ausführen
function UI.RunTarget(target: string)
	if target == "__invite" then
		UI.Close()
		invite()
	else
		UI.Toggle(target)
	end
end

-- ===== Controller-Auswahl =====
local function selectIn(frame: GuiObject)
	if not Device.IsGamepad() then
		return
	end
	task.defer(function()
		if not frame.Visible then
			return
		end
		local content = frame:FindFirstChild("Inhalt")
		local ok = pcall(function()
			GuiService:Select(content or frame)
		end)
		if (not ok or GuiService.SelectedObject == nil) and content then
			pcall(function()
				GuiService:Select(frame)
			end)
		end
	end)
end

local function clearSelection()
	local sel = GuiService.SelectedObject
	if sel and (sel:IsDescendantOf(windowLayer) or sel:IsDescendantOf(hudLayer)) then
		GuiService.SelectedObject = nil
	end
end

-- ===== Effekte, die andere Controller auslösen =====
function UI.SetEffectHandler(fn: (string, Vector3) -> ())
	effectHandler = fn
end

function UI.Effect(kind: string, pos: Vector3)
	if effectHandler then
		effectHandler(kind, pos)
	end
end

-- ===== Toasts =====
local TOAST_COLORS = {
	info = Theme.Info,
	gut = Theme.Good,
	fehler = Theme.Bad,
	boss = Theme.Boss,
}

function UI.Toast(text: string, kind: string?)
	if not toastLayer then
		return
	end
	local color = TOAST_COLORS[kind or "info"] or Theme.Info
	local frame = C.Frame({
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Theme.Panel,
		LayoutOrder = -math.floor(os.clock() * 100),
		Parent = toastLayer,
	})
	C.Stroke(frame, color, 3)
	C.Frame({ Size = UDim2.new(0, 8, 1, -10), Position = UDim2.fromOffset(6, 5), BackgroundColor3 = color, Parent = frame, Radius = 4 })
	C.Label({ Text = text, Size = UDim2.new(1, -26, 1, -8), Position = UDim2.fromOffset(20, 4), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 20, Parent = frame })
	local scale = Instance.new("UIScale")
	scale.Scale = 0.6
	scale.Parent = frame
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = math.min(UI.HudScale(), 1.2) }):Play()
	-- höchstens 5 Meldungen (Handy: 3)
	local items = {}
	for _, child in toastLayer:GetChildren() do
		if child:IsA("Frame") then
			table.insert(items, child)
		end
	end
	table.sort(items, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = (if UI.IsTouch() then 4 else 6), #items do
		items[i]:Destroy()
	end
	task.delay(3.6, function()
		if frame.Parent then
			TweenService:Create(scale, TweenInfo.new(0.2), { Scale = 0 }):Play()
			task.wait(0.22)
			frame:Destroy()
		end
	end)
	if kind == "fehler" then
		SoundController.Play("Fehler", 0.7)
	end
end

-- schwebender Text am Energie-Zähler
function UI.FloatHud(text: string)
	if not hudLayer then
		return
	end
	local label = C.Label({
		Text = text,
		Size = UDim2.fromOffset(200, 30),
		Position = UDim2.fromOffset(30, 70),
		TextColor3 = Theme.Energy,
		TextStrokeTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 20,
		Parent = hudLayer,
	})
	TweenService:Create(label, TweenInfo.new(1.2), { Position = UDim2.fromOffset(30, 20), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.25, function()
		label:Destroy()
	end)
end

function UI.Flash()
	if not flash then
		return
	end
	flash.BackgroundTransparency = 0.2
	TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
end

-- Ergebnis nach einer Strecke
function UI.ShowCourseResult(data: any)
	local Util = require(Shared:WaitForChild("Util"))
	local Settings = require(Shared:WaitForChild("Config"):WaitForChild("Settings")) :: any
	local panel = C.Frame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.38),
		Size = UDim2.fromOffset(380, 212),
		BackgroundColor3 = Theme.Panel,
		ZIndex = 30,
		Parent = gui,
	})
	C.Stroke(panel, Theme.Brass, 4)
	C.Label({ Text = "🏁 Geschafft!", Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 8), MaxTextSize = 40, ZIndex = 31, Parent = panel })
	C.Label({
		Text = ("%s · %s"):format(data.Name or "", data.Diff or ""),
		Size = UDim2.new(1, -20, 0, 26),
		Position = UDim2.fromOffset(10, 54),
		MaxTextSize = 22,
		ZIndex = 31,
		Parent = panel,
	})
	C.Label({
		Text = ("⏱ %s"):format(Util.FormatTime(data.Time or 0)),
		Size = UDim2.new(1, -20, 0, 36),
		Position = UDim2.fromOffset(10, 82),
		TextColor3 = Theme.Copper,
		MaxTextSize = 34,
		ZIndex = 31,
		Parent = panel,
	})
	local extra = if data.NewBest then "🏆 Neue Bestzeit!" else ("Bestzeit: %s"):format(Util.FormatTime(data.Best or 0))
	if data.First then
		extra ..= "  ⭐ Erstes Mal: doppelte Belohnung!"
	end
	C.Label({ Text = extra, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 124), MaxTextSize = 20, ZIndex = 31, Parent = panel })
	-- Zeit-Medaille + nächstes Ziel
	local medalText = "Keine Medaille – versuch's schneller!"
	local medal = data.Medal or 0
	if medal > 0 then
		local m = Settings.Medals[medal]
		medalText = ("%s %s-Medaille%s"):format(m.Symbol, m.Name, if data.NewMedal then " – NEU!" else "")
	end
	local nextMedal = (data.BestMedal or medal) + 1
	if data.MedalTimes and Settings.Medals[nextMedal] then
		local m = Settings.Medals[nextMedal]
		medalText ..= ("   · %s unter %s"):format(m.Symbol, Util.FormatTime(data.MedalTimes[nextMedal]))
	end
	C.Label({ Text = medalText, Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromOffset(10, 166), TextColor3 = if medal > 0 then Theme.BrassDark else Theme.Text, MaxTextSize = 20, ZIndex = 31, Parent = panel })
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = panel
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = math.clamp(UI.HudScale(), 0.75, 1.35) }):Play()
	task.delay(if medal > 0 then 5.5 else 4.5, function()
		TweenService:Create(scale, TweenInfo.new(0.25), { Scale = 0 }):Play()
		task.wait(0.3)
		panel:Destroy()
	end)
end

-- ===== RemoteFunction mit Rückmeldung =====
function UI.Request(name: string, ...: any): any
	local result = Remotes.Invoke(name, ...)
	if type(result) ~= "table" then
		return { ok = false }
	end
	if not result.ok and result.msg then
		UI.Toast(result.msg, "fehler")
	elseif result.ok and result.msg then
		UI.Toast(result.msg, "gut")
	end
	return result
end

-- ===== Fenster =====
function UI.Window(title: string, modal: boolean?): (Frame, Frame)
	local win = C.Frame({
		Name = "Fenster_" .. title,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WINDOW_BASE.X, WINDOW_BASE.Y),
		BackgroundColor3 = Theme.Bg,
		Visible = false,
		Radius = 18,
		Parent = windowLayer,
	})
	-- Controller: Auswahl bleibt im Fenster
	win.SelectionGroup = true
	win.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
	win.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
	win.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
	win.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
	C.Stroke(win, Theme.Brass, 4)
	local header = C.Frame({ Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = Theme.Brass, Radius = 18, Parent = win })
	C.Frame({ Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 1, -18), BackgroundColor3 = Theme.Brass, Radius = false, Parent = header })
	C.Label({ Text = title, Size = UDim2.new(1, -120, 1, -12), Position = UDim2.fromOffset(18, 6), TextColor3 = Theme.TextLight, TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 34, Parent = header })
	if not modal then
		C.Button({
			Text = "✖",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(46, 42),
			BackgroundColor3 = Theme.Bad,
			OnClick = function()
				UI.Close()
			end,
			Parent = header,
		})
	end
	local content = Instance.new("Frame")
	content.Name = "Inhalt"
	content.BackgroundTransparency = 1
	content.Position = UDim2.fromOffset(14, 64)
	content.Size = UDim2.new(1, -28, 1, -76)
	content.Parent = win
	local scale = Instance.new("UIScale")
	scale.Name = "PopScale"
	scale.Parent = win
	table.insert(windows, win)
	layoutWindow(win)
	return win, content
end

-- Menü-Modul registrieren. module.Build(UI) muss { Frame, Refresh?, OnOpen?, Modal? } liefern
function UI.Register(name: string, module: any)
	local ok, menu = pcall(module.Build, UI)
	if ok and menu then
		menus[name] = menu
	else
		warn("[UI] Menü konnte nicht gebaut werden:", name, menu)
	end
end

function UI.IsOpen(name: string?): boolean
	if name then
		return openName == name
	end
	return openName ~= nil
end

function UI.Close()
	if openName then
		local menu = menus[openName]
		if menu and menu.Modal then
			return -- Pflicht-Fenster (z.B. Klassenwahl) nicht wegklicken
		end
		if menu then
			menu.Frame.Visible = false
			if menu.OnClose then
				task.spawn(menu.OnClose)
			end
		end
	end
	openName = nil
	overlay.Visible = false
	clearSelection()
end

function UI.ForceClose()
	if openName and menus[openName] then
		menus[openName].Frame.Visible = false
	end
	openName = nil
	overlay.Visible = false
	clearSelection()
end

function UI.Open(name: string, args: any?)
	local menu = menus[name]
	if not menu then
		return
	end
	if openName and openName ~= name then
		local cur = menus[openName]
		if cur and cur.Modal then
			return
		end
		if cur then
			cur.Frame.Visible = false
			if cur.OnClose then
				task.spawn(cur.OnClose)
			end
		end
	end
	openName = name
	overlay.Visible = true
	menu.Frame.Visible = true
	if menu.OnOpen then
		menu.OnOpen(args or {})
	end
	if menu.Refresh and DataController.Data then
		menu.Refresh(DataController.Data)
	end
	local scale = menu.Frame:FindFirstChild("PopScale") :: UIScale?
	if scale then
		local target = (scale:GetAttribute("Target") :: number?) or 1
		scale.Scale = target * 0.85
		TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Scale = target }):Play()
	end
	selectIn(menu.Frame)
	SoundController.Play("Menue")
end

function UI.Toggle(name: string)
	if openName == name then
		UI.Close()
	else
		UI.Open(name)
	end
end

-- ScreenGui anlegen. safe = im sicheren Bereich (nicht unter Notch/Roblox-Leiste)
local function screenGui(name: string, order: number, safe: boolean): ScreenGui
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.ResetOnSpawn = false
	g.DisplayOrder = order
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.ScreenInsets = if safe then Enum.ScreenInsets.CoreUISafeInsets else Enum.ScreenInsets.None
	g.Parent = player:WaitForChild("PlayerGui")
	return g
end

function UI.Init()
	-- Ebenen (von unten nach oben): HUD · Abdunkeln · Fenster + Meldungen · Blitz
	local hudGui = screenGui("UhrwerkHUD", 1, true)
	local dimGui = screenGui("UhrwerkAbdunkeln", 2, false)
	gui = screenGui("UhrwerkUI", 3, true)
	local flashGui = screenGui("UhrwerkBlitz", 4, false)
	UI.Gui = gui

	hudLayer = Instance.new("Frame")
	hudLayer.Name = "HUD"
	hudLayer.BackgroundTransparency = 1
	hudLayer.Size = UDim2.fromScale(1, 1)
	hudLayer.Parent = hudGui
	UI.Hud = hudLayer

	overlay = Instance.new("TextButton")
	overlay.Name = "Abdunkeln"
	overlay.Text = ""
	overlay.AutoButtonColor = false
	overlay.Selectable = false
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.55
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Visible = false
	overlay.Parent = dimGui
	overlay.Activated:Connect(function()
		UI.Close()
	end)

	-- Controller: gut sichtbarer Rahmen um den ausgewählten Knopf
	local selection = Instance.new("Frame")
	selection.Name = "Auswahlrahmen"
	selection.BackgroundTransparency = 1
	selection.Size = UDim2.new(1, 10, 1, 10)
	selection.Position = UDim2.fromOffset(-5, -5)
	C.Corner(selection, 14)
	C.Stroke(selection, Theme.Copper, 4)
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	playerGui.SelectionImageObject = selection

	windowLayer = Instance.new("Frame")
	windowLayer.Name = "Fenster"
	windowLayer.BackgroundTransparency = 1
	windowLayer.Size = UDim2.fromScale(1, 1)
	windowLayer.ZIndex = 6
	windowLayer.Parent = gui

	toastLayer = Instance.new("Frame")
	toastLayer.Name = "Meldungen"
	toastLayer.BackgroundTransparency = 1
	toastLayer.AnchorPoint = Vector2.new(1, 0)
	toastLayer.Position = UDim2.new(1, -12, 0, 12)
	toastLayer.Size = UDim2.new(0.42, 0, 0.6, 0)
	toastLayer.ZIndex = 40
	toastLayer.Parent = gui
	local tl = Instance.new("UISizeConstraint")
	tl.MaxSize = Vector2.new(380, 2000)
	tl.Parent = toastLayer
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Parent = toastLayer

	flash = Instance.new("Frame")
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.Size = UDim2.fromScale(1, 1)
	flash.Active = false
	flash.Parent = flashGui

	C.SetClickSound(function()
		SoundController.Play("Menue")
	end)

	-- Menüs und HUD bauen
	local Menus = script.Parent:WaitForChild("Menus")
	local list = {
		Shop = "ShopMenu",
		Pets = "PetMenu",
		Ei = "EggMenu",
		Skills = "SkillMenu",
		Klasse = "ClassMenu",
		Rebirth = "RebirthMenu",
		Karte = "MapMenu",
		Einstellungen = "SettingsMenu",
		Bestenliste = "LeaderboardMenu",
		Chat = "ChatMenu",
		Admin = "AdminMenu",
		Aufgabe = "QuestMenu",
		Intro = "IntroMenu",
		Bonus = "DailyMenu",
		Erfolge = "AchievementsMenu",
		Turm = "TowerMenu",
		Insel = "IslandMenu",
		Menue = "MainMenu",
	}
	for name, moduleName in list do
		local ok, mod = pcall(require, Menus:WaitForChild(moduleName))
		if ok then
			UI.Register(name, mod)
		else
			warn("[UI] Menü-Modul fehlt:", moduleName, mod)
		end
	end
	local HUD = require(script.Parent:WaitForChild("HUD"))
	local ok, err = pcall(HUD.Build, UI)
	if not ok then
		warn("[UI] HUD-Fehler:", err)
	end
end

function UI.Start()
	-- Bildschirmgröße ändert sich (Handy drehen, Fenster am PC) → Fenster neu anpassen
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutAll)
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(layoutAll)
	layoutAll()

	-- Steuerung gewechselt: mit Controller sofort etwas im offenen Fenster auswählen
	Device.Changed:Connect(function()
		layoutAll()
		if openName and menus[openName] then
			if Device.IsGamepad() then
				selectIn(menus[openName].Frame)
			else
				clearSelection()
			end
		end
	end)

	-- Controller: Auswahl nicht verlieren, solange ein Fenster offen ist (z.B. nach dem Neuaufbau einer Liste)
	GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		local name = openName
		if not name or not Device.IsGamepad() then
			return
		end
		local menu = menus[name]
		local sel = GuiService.SelectedObject
		if menu and (sel == nil or not sel:IsDescendantOf(menu.Frame)) then
			task.delay(0.05, function()
				local now = GuiService.SelectedObject
				if openName == name and (now == nil or not now:IsDescendantOf(menu.Frame)) then
					selectIn(menu.Frame)
				end
			end)
		end
	end)

	-- Tasten: Y / M = Menü, B = Fenster schließen
	UserInputService.InputBegan:Connect(function(input, processed)
		local key = input.KeyCode
		if key == Enum.KeyCode.ButtonB then
			if openName then
				UI.Close()
			else
				clearSelection()
			end
		elseif key == Enum.KeyCode.ButtonY then
			UI.Toggle("Menue")
		elseif key == Enum.KeyCode.M and not processed and not UserInputService:GetFocusedTextBox() then
			UI.Toggle("Menue")
		end
	end)

	Remotes.Event("Toast").OnClientEvent:Connect(function(text: string, kind: string?)
		if type(text) == "string" then
			UI.Toast(text, kind)
		end
	end)
	local introShown = false
	local dailyShown = false
	local function checkClass(data: any)
		-- Noch keine Klasse? → Klassenwahl erzwingen
		if data.Class == "" and openName ~= "Klasse" then
			UI.ForceClose()
			UI.Open("Klasse", { Forced = true })
		elseif data.Class ~= "" and openName == "Klasse" and menus.Klasse and menus.Klasse.Modal then
			menus.Klasse.Modal = false
			UI.Close()
		end
		-- Nach der Klassenwahl einmal die Einführung zeigen
		if data.Class ~= "" and not data.Settings.IntroSeen and not introShown and openName == nil then
			introShown = true
			task.delay(0.6, function()
				if openName == nil then
					UI.Open("Intro", {})
				end
			end)
		end
		-- Tagesbonus einmal pro Besuch automatisch zeigen (nach Klasse + Einführung)
		if not dailyShown and data.Class ~= "" and data.Settings.IntroSeen and openName == nil then
			dailyShown = true
			local DailyMenu = require(script.Parent:WaitForChild("Menus"):WaitForChild("DailyMenu"))
			if DailyMenu.IsAvailable(data) then
				task.delay(2, function()
					if openName == nil then
						UI.Open("Bonus", {})
					end
				end)
			end
		end
	end
	if DataController.Data then
		checkClass(DataController.Data)
	end
	-- ab und zu ein Tipp
	task.spawn(function()
		local Quests = require(Shared:WaitForChild("Config"):WaitForChild("Quests")) :: any
		local last = 0
		while true do
			task.wait(Quests.TippIntervall)
			if #Quests.Tipps > 0 and openName == nil then
				local i = math.random(1, #Quests.Tipps)
				if i == last then
					i = (i % #Quests.Tipps) + 1
				end
				last = i
				UI.Toast("💡 " .. Quests.Tipps[i], "info")
			end
		end
	end)
	DataController.Changed:Connect(function(data)
		if openName and menus[openName] and menus[openName].Refresh then
			local ok, err = pcall(menus[openName].Refresh :: any, data)
			if not ok then
				warn("[UI] Refresh-Fehler:", openName, err)
			end
		end
		checkClass(data)
	end)
end

return UI
