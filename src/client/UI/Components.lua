--!strict
-- Components: wiederverwendbare UI-Bausteine (Buttons, Fenster, Listen, Leisten, Kreis-Anzeige)
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent:WaitForChild("Theme"))

local C = {}

local clickSound: (() -> ())? = nil
function C.SetClickSound(fn: () -> ())
	clickSound = fn
end

function C.Corner(inst: GuiObject, radius: number?): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = inst
	return c
end

function C.Stroke(inst: GuiObject, color: Color3?, thickness: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.BrassDark
	s.Thickness = thickness or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

function C.Padding(inst: GuiObject, px: number)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.Parent = inst
end

local function apply(inst: Instance, props: { [string]: any })
	for k, v in props do
		if k ~= "Parent" and k ~= "OnClick" and k ~= "MaxTextSize" and k ~= "Radius" then
			(inst :: any)[k] = v
		end
	end
	if props.Parent then
		inst.Parent = props.Parent
	end
end

function C.Frame(props: { [string]: any }): Frame
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Theme.Panel
	f.BorderSizePixel = 0
	apply(f, props)
	if props.Radius ~= false then
		C.Corner(f, props.Radius)
	end
	return f
end

function C.Label(props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Theme.Font
	l.TextColor3 = Theme.Text
	l.TextScaled = true
	l.TextWrapped = true
	apply(l, props)
	local max = Instance.new("UITextSizeConstraint")
	max.MaxTextSize = props.MaxTextSize or 28
	max.MinTextSize = 8
	max.Parent = l
	return l
end

-- Großer, gut klickbarer Button mit Feder-Animation
function C.Button(props: { [string]: any }): TextButton
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundColor3 = Theme.Brass
	b.Font = Theme.Font
	b.TextColor3 = Theme.TextLight
	b.TextScaled = true
	b.TextWrapped = true
	b.BorderSizePixel = 0
	apply(b, props)
	C.Corner(b, props.Radius or 12)
	local stroke = C.Stroke(b, Color3.new(0, 0, 0), 2)
	stroke.Transparency = 0.75
	local max = Instance.new("UITextSizeConstraint")
	max.MaxTextSize = props.MaxTextSize or 26
	max.MinTextSize = 8
	max.Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.Parent = b
	local scale = Instance.new("UIScale")
	scale.Parent = b
	b.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.05 }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
	end)
	b.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.08), { Scale = 0.93 }):Play()
	end)
	b.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end)
	if props.OnClick then
		b.Activated:Connect(function()
			if clickSound then
				clickSound()
			end
			props.OnClick()
		end)
	end
	return b
end

-- Scroll-Liste. grid = Zellgröße (dann Raster statt Liste)
function C.List(props: { [string]: any }, grid: UDim2?): ScrollingFrame
	local s = Instance.new("ScrollingFrame")
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 8
	s.ScrollBarImageColor3 = Theme.BrassDark
	s.CanvasSize = UDim2.new()
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.ScrollingDirection = Enum.ScrollingDirection.Y
	apply(s, props)
	if grid then
		local g = Instance.new("UIGridLayout")
		g.CellSize = grid
		g.CellPadding = UDim2.fromOffset(8, 8)
		g.SortOrder = Enum.SortOrder.LayoutOrder
		g.Parent = s
	else
		local l = Instance.new("UIListLayout")
		l.Padding = UDim.new(0, 8)
		l.SortOrder = Enum.SortOrder.LayoutOrder
		l.Parent = s
	end
	local pad = Instance.new("UIPadding")
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.Parent = s
	return s
end

-- alle Einträge löschen (Layouts bleiben)
function C.Clear(container: Instance)
	for _, child in container:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

export type Bar = { Frame: Frame, Fill: Frame, Set: (number) -> () }

function C.Bar(props: { [string]: any }, color: Color3?): Bar
	local back = C.Frame({ BackgroundColor3 = Color3.fromRGB(90, 70, 55), Radius = 8 })
	apply(back, props)
	local fill = C.Frame({ BackgroundColor3 = color or Theme.Good, Size = UDim2.fromScale(0, 1), Parent = back, Radius = 8 })
	local function set(p: number)
		TweenService:Create(fill, TweenInfo.new(0.25), { Size = UDim2.fromScale(math.clamp(p, 0, 1), 1) }):Play()
	end
	return { Frame = back, Fill = fill, Set = set }
end

export type Radial = { Frame: Frame, Set: (number) -> () }

-- Kreis-Anzeige für Abklingzeiten (p = 0..1 Anteil, der noch abgedunkelt ist)
function C.Radial(parent: GuiObject, color: Color3?): Radial
	local holder = Instance.new("Frame")
	holder.Name = "Abklingkreis"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = (parent.ZIndex or 1) + 2
	holder.Parent = parent
	local function half(isRight: boolean): UIGradient
		local clip = Instance.new("Frame")
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		clip.Size = UDim2.fromScale(0.5, 1)
		clip.Position = UDim2.fromScale(if isRight then 0.5 else 0, 0)
		clip.ZIndex = holder.ZIndex
		clip.Parent = holder
		local circle = Instance.new("Frame")
		circle.BackgroundColor3 = color or Color3.new(0, 0, 0)
		circle.BackgroundTransparency = 0.45
		circle.BorderSizePixel = 0
		circle.Size = UDim2.fromScale(2, 1)
		circle.Position = UDim2.fromScale(if isRight then -1 else 0, 0)
		circle.ZIndex = holder.ZIndex
		circle.Parent = clip
		C.Corner(circle, 999)
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.499, 0),
			NumberSequenceKeypoint.new(0.5, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		g.Parent = circle
		return g
	end
	local right = half(true)
	local left = half(false)
	local function set(p: number)
		p = math.clamp(p, 0, 1)
		holder.Visible = p > 0.001
		-- rechte Hälfte zeigt 0–50 %, linke 50–100 % (im Uhrzeigersinn ab 12 Uhr)
		right.Rotation = math.min(p, 0.5) * 360
		left.Rotation = 180 + math.max(p - 0.5, 0) * 360
	end
	set(0)
	return { Frame = holder, Set = set }
end

return C
