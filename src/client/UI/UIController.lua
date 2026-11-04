--!strict
--[[
	UIController: Wurzel der gesamten Oberfläche (komplett per Code gebaut).
	- Toasts (Hinweis-Meldungen), schwebende Zahlen, Bildschirm-Blitz
	- Fenster-Verwaltung: immer nur ein Menü offen, Hintergrund abgedunkelt
	- Request(): RemoteFunction aufrufen + Fehler als Toast zeigen
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local C = require(script.Parent:WaitForChild("Components"))
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

type Menu = { Frame: GuiObject, Refresh: ((any) -> ())?, OnOpen: ((any) -> ())?, Modal: boolean? }
local menus: { [string]: Menu } = {}
local openName: string? = nil

UI.Gui = nil :: ScreenGui?
UI.Hud = nil :: Frame?
UI.Theme = Theme
UI.C = C

function UI.CurrentZone(): number
	return (player:GetAttribute("Zone") :: number?) or 0
end

function UI.IsTouch(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
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
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	-- höchstens 5 Meldungen
	local items = {}
	for _, child in toastLayer:GetChildren() do
		if child:IsA("Frame") then
			table.insert(items, child)
		end
	end
	table.sort(items, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = 6, #items do
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
	local panel = C.Frame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.38),
		Size = UDim2.fromOffset(360, 170),
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
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = panel
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(4.5, function()
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
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.94, 0.86),
		BackgroundColor3 = Theme.Bg,
		Visible = false,
		Radius = 18,
		Parent = windowLayer,
	})
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(820, 580)
	limit.Parent = win
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
		end
	end
	openName = nil
	overlay.Visible = false
end

function UI.ForceClose()
	if openName and menus[openName] then
		menus[openName].Frame.Visible = false
	end
	openName = nil
	overlay.Visible = false
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
		scale.Scale = 0.85
		TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	SoundController.Play("Menue")
end

function UI.Toggle(name: string)
	if openName == name then
		UI.Close()
	else
		UI.Open(name)
	end
end

function UI.Init()
	gui = Instance.new("ScreenGui")
	gui.Name = "UhrwerkUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	UI.Gui = gui

	hudLayer = Instance.new("Frame")
	hudLayer.Name = "HUD"
	hudLayer.BackgroundTransparency = 1
	hudLayer.Size = UDim2.fromScale(1, 1)
	hudLayer.Parent = gui
	UI.Hud = hudLayer

	overlay = Instance.new("TextButton")
	overlay.Name = "Abdunkeln"
	overlay.Text = ""
	overlay.AutoButtonColor = false
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.55
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Visible = false
	overlay.ZIndex = 5
	overlay.Parent = gui
	overlay.Activated:Connect(function()
		UI.Close()
	end)

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
	toastLayer.Position = UDim2.new(1, -12, 0, 60)
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
	flash.ZIndex = 50
	flash.Active = false
	flash.Parent = gui

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
	Remotes.Event("Toast").OnClientEvent:Connect(function(text: string, kind: string?)
		if type(text) == "string" then
			UI.Toast(text, kind)
		end
	end)
	local function checkClass(data: any)
		-- Noch keine Klasse? → Klassenwahl erzwingen
		if data.Class == "" and openName ~= "Klasse" then
			UI.ForceClose()
			UI.Open("Klasse", { Forced = true })
		elseif data.Class ~= "" and openName == "Klasse" and menus.Klasse and menus.Klasse.Modal then
			menus.Klasse.Modal = false
			UI.Close()
		end
	end
	if DataController.Data then
		checkClass(DataController.Data)
	end
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
