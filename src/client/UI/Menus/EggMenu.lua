--!strict
-- EggMenu: Ei-Station – Chancen ansehen und Ei öffnen (mit kleiner Animation)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Pets = require(Shared:WaitForChild("Config"):WaitForChild("Pets")) :: any
local Util = require(Shared:WaitForChild("Util"))
local SoundController = require(script.Parent.Parent.Parent:WaitForChild("Controllers"):WaitForChild("SoundController"))
local PetMenu = require(script.Parent:WaitForChild("PetMenu"))

local EggMenu = {}

function EggMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("🥚 Pet-Ei")
	local title = C.Label({ Text = "", Size = UDim2.new(0.5, 0, 0, 40), MaxTextSize = 30, Parent = content })
	local price = C.Label({ Text = "", Size = UDim2.new(0.5, 0, 0, 30), Position = UDim2.fromOffset(0, 42), TextColor3 = Theme.Copper, MaxTextSize = 24, Parent = content })
	local chances = C.List({ Position = UDim2.fromOffset(0, 80), Size = UDim2.new(0.5, -8, 1, -80), Parent = content })
	local stage = C.Frame({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.5, -4, 1, -70), BackgroundColor3 = Theme.Panel, Parent = content })
	C.Stroke(stage, Theme.PanelDark, 2)
	local eggIcon = C.Label({ Text = "🥚", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.6, 0.6), MaxTextSize = 120, Parent = stage })
	local result = C.Label({ Text = "", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -12, 0, 50), MaxTextSize = 24, Parent = stage })
	local preview = Instance.new("Frame")
	preview.BackgroundTransparency = 1
	preview.Size = UDim2.fromScale(1, 0.8)
	preview.Parent = stage

	local eggId: string? = nil
	local busy = false

	C.Button({
		Text = "🥚 Öffnen!",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.new(0.5, -4, 0, 60),
		BackgroundColor3 = Theme.Good,
		OnClick = function()
			if busy or not eggId then
				return
			end
			busy = true
			for _, c in preview:GetChildren() do
				c:Destroy()
			end
			eggIcon.Visible = true
			result.Text = "..."
			-- Wackeln, während der Server würfelt
			local wobble = TweenService:Create(eggIcon, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 6, true), { Rotation = 18 })
			wobble:Play()
			local r = UI.Request("HatchEgg", eggId)
			task.wait(0.9)
			eggIcon.Rotation = 0
			if r.ok and r.pet then
				local def = Pets.Liste[r.pet.Type]
				local rarity = Pets.Seltenheiten[def.Seltenheit]
				eggIcon.Visible = false
				PetMenu.Preview(preview, r.pet.Type)
				result.Text = ("%s! (%s, x%s)"):format(def.Name, rarity.Name, tostring(def.Multiplikator))
				result.TextColor3 = rarity.Farbe:Lerp(Theme.Text, 0.3)
				SoundController.Play("Ei", if rarity.Rang >= 3 then 1.4 else 1)
				if rarity.Rang >= 3 then
					UI.Flash()
				end
			else
				result.Text = ""
			end
			busy = false
		end,
		Parent = content,
	})

	local function onOpen(args: any)
		eggId = args.EggId
		local egg = eggId and Pets.Eier[eggId]
		C.Clear(chances)
		for _, c in preview:GetChildren() do
			c:Destroy()
		end
		eggIcon.Visible = true
		result.Text = ""
		if not egg then
			title.Text = "?"
			return
		end
		title.Text = egg.Name
		eggIcon.TextColor3 = egg.Farbe
		price.Text = if egg.Waehrung == "Rebirth" then ("Preis: %d ♻️ Rebirth-Punkt"):format(egg.Preis) else ("Preis: %s ⚡"):format(Util.FormatNumber(egg.Preis))
		for i, entry in Util.Chances(egg.Chancen) do
			local def = Pets.Liste[entry.Id]
			if def then
				local rarity = Pets.Seltenheiten[def.Seltenheit]
				local row = C.Frame({ Size = UDim2.new(1, -6, 0, 40), BackgroundColor3 = Theme.Panel, LayoutOrder = i, Parent = chances })
				C.Stroke(row, rarity.Farbe, 2)
				C.Label({ Text = def.Name, Size = UDim2.new(0.5, -8, 1, -6), Position = UDim2.fromOffset(8, 3), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 18, Parent = row })
				C.Label({ Text = "x" .. tostring(def.Multiplikator), Size = UDim2.new(0.2, 0, 1, -6), Position = UDim2.new(0.5, 0, 0, 3), MaxTextSize = 18, Parent = row })
				C.Label({ Text = string.format("%.1f %%", entry.Prozent), Size = UDim2.new(0.3, -8, 1, -6), Position = UDim2.new(0.7, 0, 0, 3), TextColor3 = rarity.Farbe:Lerp(Theme.Text, 0.4), MaxTextSize = 18, Parent = row })
			end
		end
	end

	return { Frame = win, OnOpen = onOpen }
end

return EggMenu
