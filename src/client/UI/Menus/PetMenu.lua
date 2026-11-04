--!strict
-- PetMenu: Pet-Inventar – ausrüsten, ablegen, umbenennen (nur vorgefertigte Namen), freilassen
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Pets = require(Config:WaitForChild("Pets")) :: any
local Settings = require(Config:WaitForChild("Settings")) :: any
local Controllers = script.Parent.Parent.Parent:WaitForChild("Controllers")
local DataController = require(Controllers:WaitForChild("DataController"))
local PetController = require(Controllers:WaitForChild("PetController"))

local PetMenu = {}

local FORM_ICON = { Kugel = "⚪", Wuerfel = "🟧", Zylinder = "🥫", Zahnrad = "⚙️" }

-- kleine 3D-Vorschau eines Pets
function PetMenu.Preview(parent: GuiObject, petType: string): ViewportFrame
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.LightColor = Color3.fromRGB(255, 240, 220)
	vp.Ambient = Color3.fromRGB(180, 170, 160)
	vp.Parent = parent
	local model = PetController.BuildModel(petType, nil)
	if model then
		-- Teile wie im Spiel anordnen
		for _, p in model:GetChildren() do
			if p:IsA("BasePart") then
				local off = p:GetAttribute("Off")
				if typeof(off) == "Vector3" then
					p.CFrame = CFrame.new(off) * (if p.Name == "Zahnrad" then CFrame.Angles(0, 0, math.rad(90)) else CFrame.identity)
				else
					local form = p:GetAttribute("Form")
					p.CFrame = if form == "Zylinder" then CFrame.Angles(0, 0, math.rad(90)) elseif form == "Zahnrad" then CFrame.Angles(0, math.rad(90), 0) else CFrame.identity
				end
			end
		end
		model.Parent = vp
		local cam = Instance.new("Camera")
		cam.CFrame = CFrame.lookAt(Vector3.new(2.2, 1.6, -4.2), Vector3.new(0, 0.3, 0))
		cam.FieldOfView = 45
		cam.Parent = vp
		vp.CurrentCamera = cam
	end
	return vp
end

function PetMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("🐾 Meine Pets")

	local header = C.Label({ Text = "", Size = UDim2.new(0.6, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 22, Parent = content })
	C.Button({
		Text = "⭐ Beste ausrüsten",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(0.6, 0, 0, 0),
		Size = UDim2.new(0, 190, 0, 34),
		BackgroundColor3 = Theme.Good,
		OnClick = function()
			UI.Request("EquipBest")
		end,
		Parent = content,
	})
	local grid = C.List({ Position = UDim2.fromOffset(0, 40), Size = UDim2.new(0.6, -8, 1, -40), Parent = content }, UDim2.fromOffset(104, 118))
	local detail = C.Frame({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.4, -4, 1, 0), BackgroundColor3 = Theme.Panel, Parent = content })
	C.Stroke(detail, Theme.PanelDark, 2)
	local previewHolder = Instance.new("Frame")
	previewHolder.BackgroundTransparency = 1
	previewHolder.Size = UDim2.new(1, 0, 0.34, 0)
	previewHolder.Parent = detail
	local dName = C.Label({ Text = "Wähle ein Pet", Size = UDim2.new(1, -16, 0, 30), Position = UDim2.new(0, 8, 0.34, 0), MaxTextSize = 24, Parent = detail })
	local dInfo = C.Label({ Text = "", Size = UDim2.new(1, -16, 0, 48), Position = UDim2.new(0, 8, 0.34, 32), TextColor3 = Theme.BrassDark, MaxTextSize = 16, Parent = detail })
	local actions = Instance.new("Frame")
	actions.BackgroundTransparency = 1
	actions.AnchorPoint = Vector2.new(0, 1)
	actions.Position = UDim2.new(0, 8, 1, -8)
	actions.Size = UDim2.new(1, -16, 0, 160)
	actions.Parent = detail
	local al = Instance.new("UIListLayout")
	al.Padding = UDim.new(0, 6)
	al.SortOrder = Enum.SortOrder.LayoutOrder
	al.Parent = actions

	local selected: string? = nil
	local releaseConfirm = false

	-- Namensauswahl (vorgefertigte Namen)
	local namePicker = C.Frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Bg, Visible = false, ZIndex = 10, Parent = content })
	C.Stroke(namePicker, Theme.Brass, 3)
	C.Label({ Text = "Wähle einen Namen", Size = UDim2.new(1, 0, 0, 32), MaxTextSize = 24, ZIndex = 11, Parent = namePicker })
	local names = C.List({ Position = UDim2.fromOffset(8, 38), Size = UDim2.new(1, -16, 1, -46), ZIndex = 11, Parent = namePicker }, UDim2.fromOffset(150, 46))
	local function rename(index: number)
		if selected then
			UI.Request("RenamePet", selected, index)
		end
		namePicker.Visible = false
	end
	C.Button({ Text = "❌ Kein Name", BackgroundColor3 = Theme.Locked, LayoutOrder = 0, ZIndex = 12, OnClick = function()
		rename(0)
	end, Parent = names })
	for i, n in Settings.PetNames do
		C.Button({ Text = n, BackgroundColor3 = Theme.Lilac, TextColor3 = Theme.Text, LayoutOrder = i, ZIndex = 12, OnClick = function()
			rename(i)
		end, Parent = names })
	end

	local function findPet(data: any, uid: string): any
		for _, p in data.Pets do
			if p.Id == uid then
				return p
			end
		end
		return nil
	end

	local function showDetail(data: any)
		C.Clear(actions)
		for _, child in previewHolder:GetChildren() do
			child:Destroy()
		end
		local pet = selected and findPet(data, selected)
		if not pet then
			dName.Text = "Wähle ein Pet"
			dInfo.Text = "Pets geben dir mehr Energie. Öffne Eier im Hub!"
			return
		end
		local def = Pets.Liste[pet.Type]
		local rarity = Pets.Seltenheiten[def.Seltenheit]
		PetMenu.Preview(previewHolder, pet.Type)
		dName.Text = if pet.Name ~= "" then ("%s (%s)"):format(pet.Name, def.Name) else def.Name
		dName.TextColor3 = rarity.Farbe:Lerp(Theme.Text, 0.35)
		dInfo.Text = ("%s · x%s Energie\n%s"):format(rarity.Name, tostring(def.Multiplikator), def.Beschreibung)
		local equipped = table.find(data.Equipped, pet.Id) ~= nil
		C.Button({
			Text = if equipped then "📦 Ablegen" else "✅ Ausrüsten",
			Size = UDim2.new(1, 0, 0, 46),
			BackgroundColor3 = if equipped then Theme.Copper else Theme.Good,
			LayoutOrder = 1,
			OnClick = function()
				UI.Request(if equipped then "UnequipPet" else "EquipPet", pet.Id)
			end,
			Parent = actions,
		})
		C.Button({
			Text = "🏷️ Umbenennen",
			Size = UDim2.new(1, 0, 0, 46),
			BackgroundColor3 = Theme.Info,
			LayoutOrder = 2,
			OnClick = function()
				namePicker.Visible = true
			end,
			Parent = actions,
		})
		local release: TextButton
		release = C.Button({
			Text = "👋 Freilassen",
			Size = UDim2.new(1, 0, 0, 46),
			BackgroundColor3 = Theme.Bad,
			LayoutOrder = 3,
			OnClick = function()
				if not releaseConfirm then
					releaseConfirm = true
					release.Text = "Sicher? Nochmal tippen"
					task.delay(3, function()
						releaseConfirm = false
						if release.Parent then
							release.Text = "👋 Freilassen"
						end
					end)
					return
				end
				releaseConfirm = false
				UI.Request("ReleasePet", pet.Id)
				selected = nil
			end,
			Parent = actions,
		})
	end

	local lastSig = ""
	local function refresh(data: any)
		local stats = DataController.Stats
		header.Text = ("Ausgerüstet %d/%d · Pet-Bonus x%.2f · %d/%d Pets"):format(
			#data.Equipped,
			stats and stats.PetSlots or 3,
			stats and stats.PetMult or 1,
			#data.Pets,
			Settings.Pets.MaxInventar
		)
		-- nur neu bauen, wenn sich an den Pets etwas geändert hat
		local sig = HttpService:JSONEncode({ data.Pets, data.Equipped, selected or "" })
		if sig == lastSig then
			return
		end
		lastSig = sig
		C.Clear(grid)
		local sorted = table.clone(data.Pets)
		table.sort(sorted, function(a, b)
			local ea = table.find(data.Equipped, a.Id) ~= nil
			local eb = table.find(data.Equipped, b.Id) ~= nil
			if ea ~= eb then
				return ea
			end
			local ma = Pets.Liste[a.Type] and Pets.Liste[a.Type].Multiplikator or 0
			local mb = Pets.Liste[b.Type] and Pets.Liste[b.Type].Multiplikator or 0
			return ma > mb
		end)
		for i, pet in sorted do
			local def = Pets.Liste[pet.Type]
			if def then
				local rarity = Pets.Seltenheiten[def.Seltenheit]
				local equipped = table.find(data.Equipped, pet.Id) ~= nil
				local card = C.Button({
					Text = "",
					BackgroundColor3 = if pet.Id == selected then Theme.PanelDark else Theme.Panel,
					LayoutOrder = i,
					OnClick = function()
						selected = pet.Id
						refresh(DataController.Data)
					end,
					Parent = grid,
				})
				C.Stroke(card, rarity.Farbe, 3)
				local icon = C.Frame({ Size = UDim2.fromOffset(52, 52), Position = UDim2.new(0.5, -26, 0, 4), BackgroundColor3 = def.Farbe, Radius = 26, Parent = card })
				C.Label({ Text = FORM_ICON[def.Form] or "⚙️", Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.15, 0.15), MaxTextSize = 26, Parent = icon })
				C.Label({ Text = if pet.Name ~= "" then pet.Name else def.Name, Size = UDim2.new(1, -4, 0, 22), Position = UDim2.fromOffset(2, 60), MaxTextSize = 16, Parent = card })
				C.Label({ Text = "x" .. tostring(def.Multiplikator), Size = UDim2.new(1, -4, 0, 20), Position = UDim2.fromOffset(2, 82), TextColor3 = rarity.Farbe:Lerp(Theme.Text, 0.4), MaxTextSize = 16, Parent = card })
				if equipped then
					C.Label({ Text = "✅", Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(2, 2), MaxTextSize = 20, Parent = card })
				end
			end
		end
		showDetail(data)
	end

	return { Frame = win, Refresh = refresh }
end

return PetMenu
