--!strict
--[[
	IslandController: Bauen auf der eigenen Werkstatt-Insel
	- Platzieren: durchsichtige Vorschau folgt Maus/Finger im Raster (grün = frei, rot = belegt)
	  Klick/Tippen = platzieren, T oder ↻ = drehen, ✖ = fertig
	- Abbauen: Deko unter der Maus leuchtet, Klick/Tippen = abbauen
	- Controller (Xbox/PlayStation): Zielkreuz in der Bildschirmmitte,
	  X/□ = bauen bzw. abbauen, LT/L2 = drehen, B/○ = fertig
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Deco = require(Shared:WaitForChild("Config"):WaitForChild("Deco")) :: any
local DecoModels = require(Shared:WaitForChild("DecoModels"))
local Util = require(Shared:WaitForChild("Util"))
local Progression = require(Shared:WaitForChild("Progression"))
local DataController = require(script.Parent:WaitForChild("DataController"))
local UI = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("UIController"))
local Device = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Device"))

local IslandController = {}

local player = Players.LocalPlayer
local mode: string? = nil -- "place" | "remove"
local current: any = nil
local rotation = 0
local ghost: Model? = nil
local cellX, cellZ = 1, 1
local canPlace = false
local highlight: Highlight
local hovered: Model? = nil
local panel: Frame? = nil
local panelLabel: TextLabel? = nil
local busy = false
local previewSet = false
local crosshair: Frame? = nil
local panelScale: UIScale? = nil

-- wird weiter unten festgelegt (StartPlace braucht sie schon vorher)
local updatePlace: (pos: Vector2?) -> ()

-- Controller zielt mit der Bildschirmmitte
local function screenCenter(): Vector2?
	local cam = workspace.CurrentCamera
	return if cam then cam.ViewportSize / 2 else nil
end

local function onOwnIsland(): boolean
	return player:GetAttribute("Ort") == "Insel" and player:GetAttribute("IslandOwnerId") == player.UserId
end

local function plotFolder(): Instance?
	local index = player:GetAttribute("IslandPlot")
	local root = workspace:FindFirstChild("Werkstaetten")
	return root and root:FindFirstChild(("Werkstatt_%s"):format(tostring(index)))
end

local function center(): Vector3
	return Deco.PlotCenter((player:GetAttribute("IslandPlot") :: number?) or 1)
end

-- Ist das Feld frei? (gleiche Regel wie auf dem Server)
local function isFree(x: number, z: number, size: number): boolean
	if x < 1 or z < 1 or x + size - 1 > Deco.Zellen or z + size - 1 > Deco.Zellen then
		return false
	end
	local data = DataController.Data
	for _, entry in (data and data.Island and data.Island.Items) or {} do
		local item = Deco.Find(entry.Id)
		local s = if item then item.Groesse else 1
		if x < entry.X + s and entry.X < x + size and z < entry.Z + s and entry.Z < z + size then
			return false
		end
	end
	return true
end

local function screenRay(pos: Vector2?): (Vector3?, Vector3?)
	local cam = workspace.CurrentCamera
	if not cam then
		return nil, nil
	end
	local p = pos or UserInputService:GetMouseLocation()
	local ray = cam:ViewportPointToRay(p.X, p.Y)
	return ray.Origin, ray.Direction * 600
end

local function setPanel(text: string?)
	if panel and panelLabel then
		panel.Visible = text ~= nil
		panelLabel.Text = text or ""
	end
end

function IslandController.Stop()
	mode = nil
	current = nil
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	hovered = nil
	highlight.Adornee = nil
	setPanel(nil)
	if crosshair then
		crosshair.Visible = false
	end
end

local function updatePanelText()
	local kind = Device.Kind()
	if crosshair then
		crosshair.Visible = mode ~= nil and kind == "Gamepad"
	end
	if panelScale then
		panelScale.Scale = math.clamp(UI.HudScale(), 0.75, 1.3)
	end
	if panel then
		-- über der Skill-Leiste (die liegt unten in der Mitte)
		panel.Position = UDim2.new(0.5, 0, 1, -math.floor(24 + 96 * UI.HudScale()))
	end
	if mode == "place" and current then
		local data = DataController.Data
		local price = if data then Progression.DecoPrice(current, data) else 0
		local how = if kind == "Touch"
			then "Tippen = Vorschau, nochmal tippen = bauen"
			elseif kind == "Gamepad" then ("%s = bauen, %s = drehen, %s = fertig"):format(Device.ButtonText(Enum.KeyCode.ButtonX), Device.ButtonText(Enum.KeyCode.ButtonL2), Device.ButtonText(Enum.KeyCode.ButtonB))
			else "Klicken = bauen, T = drehen"
		setPanel(("%s %s – %s   ·   %s"):format(current.Symbol, current.Name, if price > 0 then Util.FormatNumber(price) .. " ⚡" else "gratis", how))
	elseif mode == "remove" then
		local how = if kind == "Touch"
			then "tippe auf ein Deko-Stück"
			elseif kind == "Gamepad" then ("ziele mit dem Kreuz, %s = abbauen"):format(Device.ButtonText(Enum.KeyCode.ButtonX))
			else "klicke auf ein Deko-Stück"
		setPanel(("🔨 Abbauen: %s (du bekommst den Preis zurück)"):format(how))
	end
end

function IslandController.StartPlace(item: any)
	IslandController.Stop()
	if not onOwnIsland() then
		UI.Toast("Geh zuerst in deine Werkstatt (Menü → „Zur Werkstatt“).", "info")
		return
	end
	mode = "place"
	current = item
	rotation = 0
	previewSet = false
	local m = DecoModels.Build(item, Deco.Zelle)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanQuery = false
			d.Transparency = math.max(d.Transparency, 0.45)
		elseif d:IsA("PointLight") or d:IsA("ParticleEmitter") then
			d.Enabled = false
		end
	end
	m.Parent = workspace
	ghost = m
	highlight.Adornee = m
	cellX, cellZ = math.floor(Deco.Zellen / 2), math.floor(Deco.Zellen / 2)
	updatePlace(if Device.IsGamepad() then screenCenter() else nil)
	updatePanelText()
end

function IslandController.StartRemove()
	IslandController.Stop()
	if not onOwnIsland() then
		UI.Toast("Geh zuerst in deine Werkstatt (Menü → „Zur Werkstatt“).", "info")
		return
	end
	mode = "remove"
	updatePanelText()
end

local function hitTest(pos: Vector2?): RaycastResult?
	local origin, dir = screenRay(pos)
	local folder = plotFolder()
	if not origin or not dir or not folder then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { folder }
	return workspace:Raycast(origin, dir, params)
end

function updatePlace(pos: Vector2?)
	if not ghost or not current then
		return
	end
	local hit = hitTest(pos)
	local size = current.Groesse or 1
	if hit then
		local c = center()
		local half = Deco.Zellen * Deco.Zelle / 2
		-- Feld unter dem Zeiger (bei 2×2 ist der Zeiger in der Mitte)
		local fx = (hit.Position.X - (c.X - half)) / Deco.Zelle - (size - 1) / 2
		local fz = (hit.Position.Z - (c.Z - half)) / Deco.Zelle - (size - 1) / 2
		cellX = math.clamp(math.floor(fx) + 1, 1, Deco.Zellen - size + 1)
		cellZ = math.clamp(math.floor(fz) + 1, 1, Deco.Zellen - size + 1)
	end
	local p = Deco.CellPos(center(), cellX, cellZ, size)
	ghost:PivotTo(CFrame.new(p) * CFrame.Angles(0, rotation * math.pi / 2, 0))
	canPlace = isFree(cellX, cellZ, size)
	highlight.FillColor = if canPlace then Color3.fromRGB(120, 230, 140) else Color3.fromRGB(255, 110, 110)
	highlight.OutlineColor = highlight.FillColor
end

local function updateRemove(pos: Vector2?)
	local hit = hitTest(pos)
	local model: Instance? = hit and hit.Instance
	while model and not (model:IsA("Model") and model:GetAttribute("Index")) do
		model = model.Parent
	end
	hovered = model :: Model?
	highlight.Adornee = hovered
	highlight.FillColor = Color3.fromRGB(255, 120, 120)
	highlight.OutlineColor = Color3.fromRGB(255, 80, 80)
end

local function confirm(pos: Vector2?)
	if busy then
		return
	end
	if mode == "place" and current then
		updatePlace(pos)
		if not canPlace then
			UI.Toast("Da ist kein Platz.", "fehler")
			return
		end
		busy = true
		local r = UI.Request("PlaceDeco", current.Id, cellX, cellZ, rotation)
		busy = false
		if r.ok and current and current.Boss then
			IslandController.Stop() -- Pokale gibt es nur einmal
		end
	elseif mode == "remove" then
		updateRemove(pos)
		local m = hovered
		if m then
			busy = true
			UI.Request("RemoveDeco", m:GetAttribute("Index"))
			busy = false
			hovered = nil
			highlight.Adornee = nil
		end
	end
end

function IslandController.Init()
	highlight = Instance.new("Highlight")
	highlight.Name = "BauVorschau"
	highlight.FillTransparency = 0.6
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	-- Ohne Ziel würde ein Highlight die ganze Welt einfärben → nur an, wenn etwas markiert ist
	highlight.Enabled = false
	highlight:GetPropertyChangedSignal("Adornee"):Connect(function()
		highlight.Enabled = highlight.Adornee ~= nil
	end)
	highlight.Parent = workspace
end

function IslandController.Start()
	-- kleine Leiste unten: was wird gebaut + Knöpfe
	local C, Theme = UI.C, UI.Theme
	local hud = UI.Hud
	if hud then
		local f = C.Frame({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -112),
			Size = UDim2.fromOffset(560, 54),
			BackgroundColor3 = Theme.Panel,
			Visible = false,
			Parent = hud,
		})
		C.Stroke(f, Theme.Brass, 3)
		local ps = Instance.new("UIScale")
		ps.Parent = f
		panelScale = ps
		panelLabel = C.Label({ Text = "", Size = UDim2.new(1, -230, 1, -8), Position = UDim2.fromOffset(10, 4), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 18, Parent = f })
		C.Button({ Text = "↻ Drehen", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -116, 0.5, 0), Size = UDim2.fromOffset(104, 40), BackgroundColor3 = Theme.Info, OnClick = function()
			rotation = (rotation + 1) % 4
		end, Parent = f })
		C.Button({ Text = "✖ Fertig", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(104, 40), BackgroundColor3 = Theme.Bad, OnClick = function()
			IslandController.Stop()
		end, Parent = f })
		panel = f
	end

	-- Zielkreuz für den Controller (ganzer Bildschirm, damit die Mitte genau stimmt)
	local aimGui = Instance.new("ScreenGui")
	aimGui.Name = "UhrwerkZiel"
	aimGui.ResetOnSpawn = false
	aimGui.ScreenInsets = Enum.ScreenInsets.None
	aimGui.DisplayOrder = 1
	aimGui.Parent = player:WaitForChild("PlayerGui")
	local cross = Instance.new("Frame")
	cross.AnchorPoint = Vector2.new(0.5, 0.5)
	cross.Position = UDim2.fromScale(0.5, 0.5)
	cross.Size = UDim2.fromOffset(18, 18)
	cross.BackgroundColor3 = Color3.new(1, 1, 1)
	cross.BackgroundTransparency = 0.2
	cross.Visible = false
	cross.Parent = aimGui
	C.Corner(cross, 9)
	C.Stroke(cross, Theme.Copper, 3)
	crosshair = cross
	Device.Changed:Connect(function()
		if mode then
			updatePanelText()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not mode or processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			task.spawn(confirm, nil)
		elseif input.UserInputType == Enum.UserInputType.Touch then
			-- Touch-Position ist ohne die obere Leiste → für den Strahl wieder dazurechnen
			local inset = GuiService:GetGuiInset()
			local p = Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)
			if mode == "place" then
				-- 1. Tippen = Vorschau dorthin, 2. Tippen aufs selbe Feld = bauen
				local oldX, oldZ = cellX, cellZ
				updatePlace(p)
				if previewSet and oldX == cellX and oldZ == cellZ then
					task.spawn(confirm, p)
				end
				previewSet = true
			else
				task.spawn(confirm, p)
			end
		elseif input.KeyCode == Enum.KeyCode.T and mode == "place" then
			rotation = (rotation + 1) % 4
		elseif input.KeyCode == Enum.KeyCode.ButtonX then
			task.spawn(confirm, screenCenter())
		elseif input.KeyCode == Enum.KeyCode.ButtonL2 and mode == "place" then
			rotation = (rotation + 1) % 4
		elseif input.KeyCode == Enum.KeyCode.ButtonB then
			IslandController.Stop()
		end
	end)

	RunService.RenderStepped:Connect(function()
		if not mode then
			return
		end
		if not onOwnIsland() then
			IslandController.Stop()
			return
		end
		if UI.IsTouch() then
			return -- Touch: Vorschau springt nur beim Tippen
		end
		local pos = if Device.IsGamepad() then screenCenter() else nil
		if mode == "place" then
			updatePlace(pos)
		elseif mode == "remove" then
			updateRemove(pos)
		end
	end)

	DataController.Changed:Connect(function()
		if mode then
			updatePanelText()
		end
	end)
	player:GetAttributeChangedSignal("Ort"):Connect(function()
		if mode and not onOwnIsland() then
			IslandController.Stop()
		end
	end)
end

return IslandController
