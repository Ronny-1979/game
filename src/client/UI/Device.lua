--!strict
--[[
	Device: Welches Gerät / welche Steuerung wird gerade benutzt?
	- Device.Kind(): "Touch" (Handy/Tablet), "Gamepad" (Xbox, PlayStation, Controller am PC) oder "Maus" (PC)
	- Device.IsConsole(): läuft das Spiel auf einer Konsole (Fernseher)?
	- Device.Changed: feuert, wenn der Spieler die Steuerung wechselt (z.B. Controller am PC angesteckt)
	- Device.ButtonText(KeyCode): kurzer Name einer Controller-Taste (Xbox: "Y", PlayStation: "△")
	- Device.ButtonImage(KeyCode): passendes Tasten-Bild von Roblox (leer, wenn es keins gibt)
]]
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Device = {}

local changed = Instance.new("BindableEvent")
Device.Changed = changed.Event

local GAMEPAD_TYPES = {
	[Enum.UserInputType.Gamepad1] = true,
	[Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true,
	[Enum.UserInputType.Gamepad4] = true,
}
local MOUSE_TYPES = {
	[Enum.UserInputType.Keyboard] = true,
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.MouseButton2] = true,
	[Enum.UserInputType.MouseButton3] = true,
	[Enum.UserInputType.MouseWheel] = true,
	[Enum.UserInputType.MouseMovement] = true,
}

local function initialKind(): string
	if GuiService:IsTenFootInterface() then
		return "Gamepad"
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "Touch"
	end
	if UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
		return "Gamepad"
	end
	return "Maus"
end

local kind = initialKind()

local function setKind(new: string)
	if new ~= kind then
		kind = new
		changed:Fire(kind)
	end
end

UserInputService.LastInputTypeChanged:Connect(function(t)
	if GAMEPAD_TYPES[t] then
		setKind("Gamepad")
	elseif t == Enum.UserInputType.Touch then
		setKind("Touch")
	elseif MOUSE_TYPES[t] then
		-- Mausbewegungen auf der Konsole gibt es nicht; am PC zurück zur Maus
		if not GuiService:IsTenFootInterface() then
			setKind("Maus")
		end
	end
end)

function Device.Kind(): string
	return kind
end

function Device.IsTouch(): boolean
	return kind == "Touch"
end

function Device.IsGamepad(): boolean
	return kind == "Gamepad"
end

function Device.IsConsole(): boolean
	return GuiService:IsTenFootInterface()
end

-- PlayStation-Controller erkennt man an den Symbol-Namen der Tasten
local function isPlayStation(): boolean
	local ok, s = pcall(function()
		return UserInputService:GetStringForKeyCode(Enum.KeyCode.ButtonA)
	end)
	return ok and s == "ButtonCross"
end

local XBOX = {
	[Enum.KeyCode.ButtonA] = "A",
	[Enum.KeyCode.ButtonB] = "B",
	[Enum.KeyCode.ButtonX] = "X",
	[Enum.KeyCode.ButtonY] = "Y",
	[Enum.KeyCode.ButtonL1] = "LB",
	[Enum.KeyCode.ButtonR1] = "RB",
	[Enum.KeyCode.ButtonL2] = "LT",
	[Enum.KeyCode.ButtonR2] = "RT",
}
local PLAYSTATION = {
	[Enum.KeyCode.ButtonA] = "✕",
	[Enum.KeyCode.ButtonB] = "○",
	[Enum.KeyCode.ButtonX] = "□",
	[Enum.KeyCode.ButtonY] = "△",
	[Enum.KeyCode.ButtonL1] = "L1",
	[Enum.KeyCode.ButtonR1] = "R1",
	[Enum.KeyCode.ButtonL2] = "L2",
	[Enum.KeyCode.ButtonR2] = "R2",
}
local DPAD = {
	[Enum.KeyCode.DPadLeft] = "◀",
	[Enum.KeyCode.DPadRight] = "▶",
	[Enum.KeyCode.DPadUp] = "▲",
	[Enum.KeyCode.DPadDown] = "▼",
}

function Device.ButtonText(code: Enum.KeyCode): string
	if DPAD[code] then
		return DPAD[code]
	end
	local map = if isPlayStation() then PLAYSTATION else XBOX
	return map[code] or code.Name
end

function Device.ButtonImage(code: Enum.KeyCode): string
	local ok, img = pcall(function()
		return UserInputService:GetImageForKeyCode(code)
	end)
	if ok and type(img) == "string" then
		return img
	end
	return ""
end

return Device
