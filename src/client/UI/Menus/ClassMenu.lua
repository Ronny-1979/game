--!strict
-- ClassMenu: Klassenwahl am Anfang (Pflicht) und Klassenwechsel beim Skill-Lehrer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Classes = require(Config:WaitForChild("Classes")) :: any
local Skills = require(Config:WaitForChild("Skills")) :: any
local Settings = require(Config:WaitForChild("Settings")) :: any
local Util = require(Shared:WaitForChild("Util"))

local ClassMenu = {}

local STAT_NAMES = {
	WalkSpeed = "Lauftempo",
	JumpPower = "Sprungkraft",
	MaxHealth = "Leben",
	SlowDuration = "s Verlangsamen",
	SlowRadius = "Radius Verlangsamen",
	PetPower = "Pet-Stärke",
	PlatformDuration = "s Hilfsplattform",
	ThrowDamage = "Wurf-Schaden",
	BoostSpeed = "Sprint-Tempo",
	BoostDuration = "s Sprint",
	BoostCooldown = "s Sprint-Abklingzeit",
}

function ClassMenu.Describe(effect: any): string
	local name = STAT_NAMES[effect.Stat] or effect.Stat
	if effect.Plus then
		local sign = if effect.Plus >= 0 then "+" else ""
		return ("%s%s %s"):format(sign, tostring(effect.Plus), name)
	elseif effect.Mal then
		if effect.Stat == "SlowFactor" then
			return ("Verlangsamen %d %% stärker"):format(math.floor((1 - effect.Mal) * 100 + 0.5))
		end
		return ("%s +%d %%"):format(name, math.floor((effect.Mal - 1) * 100 + 0.5))
	end
	return name
end

function ClassMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("🎓 Wähle deine Klasse", true)
	local hint = C.Label({ Text = "", Size = UDim2.new(1, 0, 0, 30), MaxTextSize = 20, Parent = content })
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromOffset(0, 36)
	row.Size = UDim2.new(1, 0, 1, -36)
	row.Parent = content
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0.015, 0)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row

	local self: any = { Frame = win, Modal = false }
	local closeBtn = C.Button({
		Text = "✖",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, -58),
		Size = UDim2.fromOffset(46, 42),
		BackgroundColor3 = Theme.Bad,
		Visible = false,
		OnClick = function()
			UI.Close()
		end,
		Parent = content,
	})

	for i, id in Classes.Reihenfolge do
		local cls = Classes[id]
		local card = C.Frame({ Size = UDim2.new(0.32, 0, 1, 0), BackgroundColor3 = Theme.Panel, LayoutOrder = i, Parent = row })
		C.Stroke(card, cls.Farbe, 4)
		C.Label({ Text = cls.Symbol, Size = UDim2.new(1, 0, 0.16, 0), MaxTextSize = 48, Parent = card })
		C.Label({ Text = cls.Name, Size = UDim2.new(1, -12, 0.1, 0), Position = UDim2.new(0, 6, 0.16, 0), MaxTextSize = 30, Parent = card })
		C.Label({ Text = cls.Beschreibung, Size = UDim2.new(1, -16, 0.2, 0), Position = UDim2.new(0, 8, 0.27, 0), TextColor3 = Theme.BrassDark, MaxTextSize = 17, Parent = card })
		local lines = {}
		for _, e in cls.Boni do
			table.insert(lines, "• " .. ClassMenu.Describe(e))
		end
		local start = Skills.Faehigkeiten[cls.Startfaehigkeit]
		if start then
			table.insert(lines, ("• Stärke: %s %s"):format(start.Symbol, start.Name))
		end
		C.Label({ Text = table.concat(lines, "\n"), Size = UDim2.new(1, -16, 0.32, 0), Position = UDim2.new(0, 8, 0.48, 0), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 16, Parent = card })
		C.Button({
			Text = "Wählen",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(1, -20, 0.13, 0),
			BackgroundColor3 = cls.Farbe,
			TextColor3 = Theme.Text,
			OnClick = function()
				UI.Request("ChooseClass", id)
			end,
			Parent = card,
		})
	end

	function self.OnOpen(args: any)
		self.Modal = args.Forced == true
		closeBtn.Visible = not self.Modal
		if self.Modal then
			hint.Text = "Willkommen! Wähle eine Klasse – du kannst sie später im Hub wechseln."
		else
			hint.Text = ("Klassenwechsel kostet %s ⚡ (Skill-Punkte bekommst du zurück)"):format(Util.FormatNumber(Settings.ClassChangeCost))
		end
	end

	return self
end

return ClassMenu
