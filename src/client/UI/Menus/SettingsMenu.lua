--!strict
-- SettingsMenu: Lautstärke, Grafik, Standard-Schwierigkeit, Hilfe
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Difficulty = require(Shared:WaitForChild("Config"):WaitForChild("Difficulty")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataController = require(script.Parent.Parent.Parent:WaitForChild("Controllers"):WaitForChild("DataController"))

local SettingsMenu = {}

function SettingsMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("⚙️ Einstellungen")
	local list = C.List({ Size = UDim2.fromScale(1, 1), Parent = content })

	local function set(key: string, value: any)
		Remotes.Event("ChangeSetting"):FireServer(key, value)
	end

	local function row(order: number, title: string): Frame
		local r = C.Frame({ Size = UDim2.new(1, -6, 0, 64), BackgroundColor3 = Theme.Panel, LayoutOrder = order, Parent = list })
		C.Stroke(r, Theme.PanelDark, 2)
		C.Label({ Text = title, Size = UDim2.new(0.4, -10, 1, -8), Position = UDim2.fromOffset(12, 4), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 22, Parent = r })
		return r
	end

	local musicRow = row(1, "🎵 Musik")
	local sfxRow = row(2, "🔊 Effekte")
	local gfxRow = row(3, "🖼️ Grafik")
	local diffRow = row(4, "🎚️ Schwierigkeit")
	local help = C.Frame({ Size = UDim2.new(1, -6, 0, 190), BackgroundColor3 = Theme.Panel, LayoutOrder = 5, Parent = list })
	C.Stroke(help, Theme.PanelDark, 2)
	C.Label({
		Text = "❓ Hilfe\nPC: WASD laufen · Leertaste springen · Q Verlangsamen · X Zurückspulen · R Sprint · F Zeit-Wurf · G Plattform (Mechaniker)\nHandy/Tablet: Knöpfe unten rechts\nGegner: draufspringen oder Zeit-Wurf · Boss: rote Flächen meiden, bei 💤 angreifen!\nCo-op: Zwei-Spieler-Rätsel gibt es ab Zone 2.",
		Size = UDim2.new(1, -20, 1, -10),
		Position = UDim2.fromOffset(10, 5),
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 17,
		Parent = help,
	})

	local function stepper(parent: Frame, key: string, value: number)
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.AnchorPoint = Vector2.new(1, 0.5)
		holder.Position = UDim2.new(1, -10, 0.5, 0)
		holder.Size = UDim2.new(0.55, 0, 0, 48)
		holder.Parent = parent
		C.Button({ Text = "➖", Size = UDim2.new(0.25, 0, 1, 0), BackgroundColor3 = Theme.Copper, OnClick = function()
			set(key, math.max(0, math.floor((value - 0.1) * 10 + 0.5) / 10))
		end, Parent = holder })
		C.Label({ Text = ("%d %%"):format(math.floor(value * 100 + 0.5)), Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.fromScale(0.3, 0), MaxTextSize = 24, Parent = holder })
		C.Button({ Text = "➕", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.25, 0, 1, 0), BackgroundColor3 = Theme.Good, OnClick = function()
			set(key, math.min(1, math.floor((value + 0.1) * 10 + 0.5) / 10))
		end, Parent = holder })
		return holder
	end

	local function choices(parent: Frame, key: string, current: string, options: { { string } })
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.AnchorPoint = Vector2.new(1, 0.5)
		holder.Position = UDim2.new(1, -10, 0.5, 0)
		holder.Size = UDim2.new(0.55, 0, 0, 48)
		holder.Parent = parent
		local l = Instance.new("UIListLayout")
		l.FillDirection = Enum.FillDirection.Horizontal
		l.Padding = UDim.new(0, 6)
		l.HorizontalAlignment = Enum.HorizontalAlignment.Right
		l.Parent = holder
		for _, opt in options do
			C.Button({
				Text = opt[2],
				Size = UDim2.new(1 / #options, -6, 1, 0),
				BackgroundColor3 = if current == opt[1] then Theme.Good else Theme.Locked,
				OnClick = function()
					set(key, opt[1])
				end,
				Parent = holder,
			})
		end
		return holder
	end

	local holders: { [Frame]: Instance } = {}
	local function place(r: Frame, h: Instance)
		if holders[r] then
			holders[r]:Destroy()
		end
		holders[r] = h
	end

	local lastSig = ""
	local function refresh(data: any)
		local sig = HttpService:JSONEncode(data.Settings)
		if sig == lastSig then
			return
		end
		lastSig = sig
		place(musicRow, stepper(musicRow, "Music", data.Settings.Music))
		place(sfxRow, stepper(sfxRow, "Sfx", data.Settings.Sfx))
		place(gfxRow, choices(gfxRow, "Graphics", data.Settings.Graphics, { { "Hoch", "Hoch ✨" }, { "Niedrig", "Niedrig 🔋" } }))
		local opts = {}
		for _, d in Difficulty.Reihenfolge do
			table.insert(opts, { d, Difficulty.Stufen[d].Symbol .. " " .. d })
		end
		place(diffRow, choices(diffRow, "Difficulty", data.Settings.Difficulty, opts))
	end

	-- Grafik-Einstellung lokal anwenden (auch wenn das Menü zu ist)
	local function applyGraphics(data: any)
		local Lighting = game:GetService("Lighting")
		for _, e in Lighting:GetChildren() do
			if e:IsA("BloomEffect") or e:IsA("SunRaysEffect") then
				e.Enabled = data.Settings.Graphics ~= "Niedrig"
			end
		end
	end
	DataController.Changed:Connect(applyGraphics)

	return { Frame = win, Refresh = refresh }
end

return SettingsMenu
