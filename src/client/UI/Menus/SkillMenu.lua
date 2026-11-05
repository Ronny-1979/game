--!strict
-- SkillMenu: Skill-Baum mit 3 Ästen pro Klasse
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Classes = require(Config:WaitForChild("Classes")) :: any
local Skills = require(Config:WaitForChild("Skills")) :: any
local Settings = require(Config:WaitForChild("Settings")) :: any
local Util = require(Shared:WaitForChild("Util"))

local SkillMenu = {}

function SkillMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("🌳 Skill-Baum")
	local header = C.Label({ Text = "", Size = UDim2.new(1, 0, 0, 32), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 24, Parent = content })
	local columns = Instance.new("Frame")
	columns.BackgroundTransparency = 1
	columns.Position = UDim2.fromOffset(0, 38)
	columns.Size = UDim2.new(1, 0, 1, -100)
	columns.Parent = content
	local footer = Instance.new("Frame")
	footer.BackgroundTransparency = 1
	footer.AnchorPoint = Vector2.new(0, 1)
	footer.Position = UDim2.fromScale(0, 1)
	footer.Size = UDim2.new(1, 0, 0, 54)
	footer.Parent = content
	local fl = Instance.new("UIListLayout")
	fl.FillDirection = Enum.FillDirection.Horizontal
	fl.Padding = UDim.new(0, 10)
	fl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	fl.Parent = footer

	local atTeacher = false
	local lastSig = ""

	local function refresh(data: any)
		local sig = HttpService:JSONEncode({ data.Class, data.SkillPoints, data.Skills, atTeacher })
		if sig == lastSig then
			return
		end
		lastSig = sig
		C.Clear(columns)
		C.Clear(footer)
		local cls = Classes[data.Class]
		if not cls then
			header.Text = "Wähle zuerst eine Klasse."
			return
		end
		header.Text = ("%s %s  ·  Skill-Punkte: %d"):format(cls.Symbol, cls.Name, data.SkillPoints)
		local tree = Skills.Baeume[data.Class] or {}
		for b, branch in tree do
			local col = C.Frame({
				Position = UDim2.fromScale((b - 1) / 3, 0),
				Size = UDim2.new(1 / 3, -8, 1, 0),
				BackgroundColor3 = Theme.Panel,
				Parent = columns,
			})
			C.Stroke(col, cls.Farbe, 2)
			C.Label({ Text = branch.Name, Size = UDim2.new(1, -8, 0, 30), Position = UDim2.fromOffset(4, 4), MaxTextSize = 22, Parent = col })
			local n = #branch.Knoten
			for i, node in branch.Knoten do
				local owned = data.Skills[node.Id] == true
				local prevOk = i == 1 or data.Skills[branch.Knoten[i - 1].Id] == true
				local canBuy = not owned and prevOk and data.SkillPoints >= node.Kosten
				local color = if owned then Theme.Good elseif canBuy then Theme.Brass else Theme.Locked
				local btn = C.Button({
					Text = "",
					Position = UDim2.new(0, 6, (i - 1) / n, 38 - (i - 1) * 38 / n),
					Size = UDim2.new(1, -12, 1 / n, -44 / n - 6),
					BackgroundColor3 = color,
					OnClick = function()
						if not owned then
							UI.Request("UnlockSkill", node.Id)
						end
					end,
					Parent = col,
				})
				C.Label({ Text = (if owned then "✅ " else "") .. node.Name, Size = UDim2.new(1, 0, 0.45, 0), TextColor3 = Theme.TextLight, MaxTextSize = 18, Parent = btn })
				C.Label({
					Text = ("%s  (%d 🔹)"):format(node.Beschreibung, node.Kosten),
					Size = UDim2.new(1, 0, 0.5, 0),
					Position = UDim2.fromScale(0, 0.48),
					TextColor3 = Theme.TextLight,
					MaxTextSize = 14,
					Parent = btn,
				})
			end
		end
		if atTeacher then
			C.Button({
				Text = ("🎓 Klasse wechseln (%s ⚡)"):format(Util.FormatNumber(Settings.ClassChangeCost)),
				Size = UDim2.fromOffset(280, 50),
				BackgroundColor3 = Theme.Info,
				OnClick = function()
					UI.Open("Klasse", { Forced = false })
				end,
				Parent = footer,
			})
			C.Button({
				Text = "↩ Punkte zurücksetzen",
				Size = UDim2.fromOffset(240, 50),
				BackgroundColor3 = Theme.Copper,
				OnClick = function()
					UI.Request("ResetSkills")
				end,
				Parent = footer,
			})
		else
			C.Label({ Text = "Klasse wechseln & Punkte zurücksetzen: beim 🎓 Skill-Lehrer am Uhrturm-Platz", Size = UDim2.fromScale(1, 1), TextColor3 = Theme.BrassDark, MaxTextSize = 18, Parent = footer })
		end
	end

	local function onOpen(args: any)
		atTeacher = args.AtTeacher == true
		lastSig = ""
	end

	return { Frame = win, Refresh = refresh, OnOpen = onOpen }
end

return SkillMenu
