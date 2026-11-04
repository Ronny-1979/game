--!strict
-- AdminMenu: Test-Befehle (der Server prüft, ob du Admin bist)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Zones = require(Config:WaitForChild("Zones")) :: any
local Pets = require(Config:WaitForChild("Pets")) :: any

local AdminMenu = {}

function AdminMenu.Build(UI: any)
	local C, Theme = UI.C, UI.Theme
	local win, content = UI.Window("🔧 Admin / Test")
	local list = C.List({ Size = UDim2.fromScale(1, 1), Parent = content }, UDim2.fromOffset(180, 56))

	local function cmd(text: string, color: Color3, name: string, arg: any)
		C.Button({
			Text = text,
			BackgroundColor3 = color,
			OnClick = function()
				UI.Request("Admin", name, arg)
			end,
			Parent = list,
		})
	end

	cmd("+1.000 ⚡", Theme.Info, "Energie", 1000)
	cmd("+1 Mio ⚡", Theme.Info, "Energie", 1e6)
	cmd("+1 Mrd ⚡", Theme.Info, "Energie", 1e9)
	cmd("+500 XP", Theme.Lilac, "XP", 500)
	cmd("Level 10", Theme.Lilac, "Level", 10)
	cmd("Level 30", Theme.Lilac, "Level", 30)
	cmd("+10 Skillpunkte", Theme.Lilac, "SkillPunkte", 10)
	cmd("+5 Rebirth-Punkte", Theme.Copper, "RebirthPunkte", 5)
	cmd("Alle Zonen frei", Theme.Good, "AlleZonen", nil)
	for i, z in ipairs(Zones) do
		cmd(("➡ Zone %d %s"):format(i, z.Name), z.Farben.Akzent, "Teleport", i)
	end
	for _, eggId in Pets.EierReihenfolge do
		cmd("🥚 " .. Pets.Eier[eggId].Name, Pets.Eier[eggId].Farbe:Lerp(Theme.BrassDark, 0.3), "Ei", eggId)
	end
	cmd("⚠️ Profil zurücksetzen", Theme.Bad, "Reset", nil)
	return { Frame = win }
end

return AdminMenu
