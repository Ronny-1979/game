--!strict
-- UpgradeService: Upgrades kaufen und Rebirth
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Upgrades = require(Config:WaitForChild("Upgrades")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local Progression = require(Shared:WaitForChild("Progression"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PetService = require(script.Parent:WaitForChild("PetService"))
local Validate = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Validate"))

local UpgradeService = {}

function UpgradeService.Buy(player: Player, id: string): any
	local u = Progression.GetUpgrade(id)
	local data = DataService.Get(player)
	if not u or not data then
		return { ok = false, msg = "Unbekanntes Upgrade." }
	end
	local lvl = data.Upgrades[id] or 0
	if lvl >= u.MaxStufe then
		return { ok = false, msg = "Schon auf Maximalstufe! ⭐" }
	end
	local cost = Progression.UpgradeCost(id, lvl)
	if not DataService.Spend(player, cost) then
		return { ok = false, msg = ("Du brauchst %s ⚡"):format(Util.FormatNumber(cost)) }
	end
	DataService.Update(player, function(d)
		d.Upgrades[id] = lvl + 1
	end)
	return { ok = true, level = lvl + 1 }
end

function UpgradeService.Rebirth(player: Player): any
	local data = DataService.Get(player)
	if not data then
		return { ok = false }
	end
	if data.Level < Settings.Rebirth.MindestLevel then
		return { ok = false, msg = ("Rebirth ab Level %d"):format(Settings.Rebirth.MindestLevel) }
	end
	local cost = Progression.RebirthCost(data.Rebirths)
	if data.Energy < cost then
		return { ok = false, msg = ("Du brauchst %s ⚡"):format(Util.FormatNumber(cost)) }
	end
	DataService.Update(player, function(d)
		d.Energy = 0
		for _, up in Upgrades do
			if not up.BehaltenBeiRebirth then
				d.Upgrades[up.Id] = 0
			end
		end
		d.Rebirths += 1
		d.RebirthPoints += Settings.Rebirth.PunkteProRebirth
	end)
	PetService.UpdateAttribute(player)
	Remotes.Event("Effect"):FireAllClients("LevelUp", { UserId = player.UserId })
	Remotes.Event("Toast"):FireClient(
		player,
		("♻️ Rebirth %d! Energie x%s für immer"):format(data.Rebirths, tostring(Progression.RebirthMultiplier(data.Rebirths))),
		"gut"
	)
	return { ok = true }
end

function UpgradeService.Init() end

function UpgradeService.Start()
	Remotes.OnInvoke("BuyUpgrade", 8, function(player, id)
		if not Validate.String(id, 30) then
			return { ok = false }
		end
		return UpgradeService.Buy(player, id)
	end)
	Remotes.OnInvoke("Rebirth", 0.5, function(player)
		return UpgradeService.Rebirth(player)
	end)
end

return UpgradeService
