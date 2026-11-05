--!strict
--[[
	PetService: Eier öffnen und Pets verwalten.
	Die ausgerüsteten Pets stehen als JSON im Spieler-Attribut "EquippedPets",
	damit jeder Client die Pets aller Spieler lokal anzeigen kann.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Pets = require(Config:WaitForChild("Pets")) :: any
local Util = require(Shared:WaitForChild("Util"))
local Tags = require(Shared:WaitForChild("Tags"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Progression = require(Shared:WaitForChild("Progression"))
local StatCalc = require(Shared:WaitForChild("StatCalc"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local BonusService = require(script.Parent:WaitForChild("BonusService"))
local QuestEvents = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("QuestEvents"))
local Validate = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Validate"))

local PetService = {}

local function findPet(data: any, uid: string): (any, number?)
	for i, p in data.Pets do
		if p.Id == uid then
			return p, i
		end
	end
	return nil, nil
end

local function isEquipped(data: any, uid: string): boolean
	return table.find(data.Equipped, uid) ~= nil
end

function PetService.UpdateAttribute(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local list = {}
	for _, uid in data.Equipped do
		local pet = findPet(data, uid)
		if pet then
			table.insert(list, { T = pet.Type, N = pet.Name, S = StatCalc.PetTier(pet) })
		end
	end
	player:SetAttribute("EquippedPets", HttpService:JSONEncode(list))
end

-- Pet direkt hinzufügen (für Belohnungen). Gibt den neuen Eintrag zurück.
function PetService.GivePet(player: Player, petType: string): any
	if not Pets.Liste[petType] then
		return nil
	end
	local stats = DataService.GetStats(player)
	return DataService.Update(player, function(d)
		if #d.Pets >= Settings.Pets.MaxInventar then
			return nil
		end
		d.PetCounter += 1
		local entry = { Id = "P" .. d.PetCounter, Type = petType, Name = "" }
		table.insert(d.Pets, entry)
		d.Stats.Hatched += 1
		-- automatisch ausrüsten, wenn noch Platz ist
		if stats and #d.Equipped < stats.PetSlots then
			table.insert(d.Equipped, entry.Id)
		end
		return entry
	end)
end

-- Ei-Inhalt würfeln und hinzufügen. free = Belohnung ohne Kosten/Station
function PetService.Hatch(player: Player, eggId: string, free: boolean): any
	local egg = Pets.Eier[eggId]
	local data = DataService.Get(player)
	if not egg or not data then
		return { ok = false, msg = "Dieses Ei gibt es nicht." }
	end
	if #data.Pets >= Settings.Pets.MaxInventar then
		return { ok = false, msg = "Dein Pet-Inventar ist voll! Lass ein Pet frei." }
	end
	if not free then
		if not Progression.IsZoneUnlocked(data, egg.Zone) then
			return { ok = false, msg = "Schalte zuerst die passende Zone frei." }
		end
		-- muss an der Eier-Station stehen
		local near = false
		for _, station in CollectionService:GetTagged(Tags.EggStation) do
			if station:IsA("BasePart") and station:GetAttribute("EggId") == eggId and Validate.Near(player, station.Position, 25) then
				near = true
				break
			end
		end
		if not near then
			return { ok = false, msg = "Geh näher an das Ei heran." }
		end
		if egg.Waehrung == "Rebirth" then
			if data.RebirthPoints < egg.Preis then
				return { ok = false, msg = "Du brauchst Rebirth-Punkte ♻️" }
			end
			DataService.Update(player, function(d)
				d.RebirthPoints -= egg.Preis
			end)
		else
			if not DataService.Spend(player, egg.Preis) then
				return { ok = false, msg = "Nicht genug Energie ⚡" }
			end
		end
	end
	-- Glücks-Events: seltene Pets (Episch, Legendär) öfter
	local chances = egg.Chancen
	local luck = BonusService.LuckFactor()
	if luck ~= 1 then
		chances = {}
		for id, w in egg.Chancen do
			local def = Pets.Liste[id]
			local rank = def and Pets.Seltenheiten[def.Seltenheit].Rang or 1
			chances[id] = if rank >= 3 then w * luck else w
		end
	end
	local petType = Util.WeightedPick(chances)
	if not petType then
		return { ok = false, msg = "Ei ist leer?!" }
	end
	local entry = PetService.GivePet(player, petType)
	PetService.UpdateAttribute(player)
	if entry then
		QuestEvents.Fire(player, "Ei", { Egg = eggId })
	end
	if entry and free then
		Remotes.Event("Toast"):FireClient(player, ("🥚 Gratis-Ei: %s!"):format(Pets.Liste[petType].Name), "gut")
	end
	return { ok = entry ~= nil, pet = entry, msg = if entry then nil else "Inventar voll." }
end

--[[
	Pet-Fusion: das gewählte Pet + (Anzahl - 1) weitere Pets derselben Art und Stufe
	werden zu einem Pet der nächsten Stufe. Name und Ausrüstung des gewählten Pets bleiben.
	Als „Futter“ werden zuerst nicht ausgerüstete Pets ohne Namen genommen.
]]
function PetService.Fuse(player: Player, uid: string): any
	local data = DataService.Get(player)
	if not data then
		return { ok = false }
	end
	local pet = findPet(data, uid)
	if not pet then
		return { ok = false, msg = "Dieses Pet gehört dir nicht." }
	end
	local tier = StatCalc.PetTier(pet)
	if tier >= #Pets.Fusion.Stufen then
		return { ok = false, msg = "Dieses Pet ist schon auf der höchsten Stufe! 🌈" }
	end
	local need = Pets.Fusion.Anzahl - 1
	local candidates = {}
	for _, other in data.Pets do
		if other.Id ~= uid and other.Type == pet.Type and StatCalc.PetTier(other) == tier then
			table.insert(candidates, other)
		end
	end
	if #candidates < need then
		return { ok = false, msg = ("Du brauchst %d gleiche Pets dieser Stufe (hast %d)."):format(Pets.Fusion.Anzahl, #candidates + 1) }
	end
	-- unwichtigste zuerst verbrauchen: nicht ausgerüstet, ohne Namen
	table.sort(candidates, function(a, b)
		local ea, eb = isEquipped(data, a.Id), isEquipped(data, b.Id)
		if ea ~= eb then
			return not ea
		end
		return (a.Name == "") and b.Name ~= ""
	end)
	local used = {}
	for i = 1, need do
		used[candidates[i].Id] = true
	end
	local newTier = tier + 1
	DataService.Update(player, function(d)
		for i = #d.Pets, 1, -1 do
			if used[d.Pets[i].Id] then
				table.remove(d.Pets, i)
			end
		end
		for i = #d.Equipped, 1, -1 do
			if used[d.Equipped[i]] then
				table.remove(d.Equipped, i)
			end
		end
		local target = findPet(d, uid)
		if target then
			target.Stufe = newTier
		end
		d.Stats.Fused = (d.Stats.Fused or 0) + 1
	end)
	PetService.UpdateAttribute(player)
	local stage = Pets.Fusion.Stufen[newTier]
	Remotes.Event("Effect"):FireAllClients("Fusion", { UserId = player.UserId, Tier = newTier })
	QuestEvents.Fire(player, "Fusion", { Tier = newTier })
	return { ok = true, msg = ("%s %s-%s entstanden!"):format(stage.Symbol, stage.Name, Pets.Liste[pet.Type].Name), tier = newTier }
end

function PetService.Init() end

function PetService.Start()
	DataService.OnLoaded(function(player)
		PetService.UpdateAttribute(player)
	end)

	Remotes.OnInvoke("HatchEgg", 3, function(player, eggId)
		if not Validate.Key(eggId, Pets.Eier) then
			return { ok = false, msg = "Unbekanntes Ei." }
		end
		return PetService.Hatch(player, eggId, false)
	end)

	Remotes.OnInvoke("FusePet", 2, function(player, uid)
		if not Validate.String(uid, 20) then
			return { ok = false }
		end
		return PetService.Fuse(player, uid)
	end)

	Remotes.OnInvoke("EquipPet", 6, function(player, uid)
		if not Validate.String(uid, 20) then
			return { ok = false }
		end
		local data = DataService.Get(player)
		local stats = DataService.GetStats(player)
		if not data or not stats then
			return { ok = false }
		end
		if not findPet(data, uid) then
			return { ok = false, msg = "Dieses Pet gehört dir nicht." }
		end
		if isEquipped(data, uid) then
			return { ok = true }
		end
		if #data.Equipped >= stats.PetSlots then
			return { ok = false, msg = ("Nur %d Pets gleichzeitig. Kaufe mehr Pet-Plätze!"):format(stats.PetSlots) }
		end
		DataService.Update(player, function(d)
			table.insert(d.Equipped, uid)
		end)
		PetService.UpdateAttribute(player)
		return { ok = true }
	end)

	Remotes.OnInvoke("UnequipPet", 6, function(player, uid)
		if not Validate.String(uid, 20) then
			return { ok = false }
		end
		DataService.Update(player, function(d)
			local i = table.find(d.Equipped, uid)
			if i then
				table.remove(d.Equipped, i)
			end
		end)
		PetService.UpdateAttribute(player)
		return { ok = true }
	end)

	Remotes.OnInvoke("EquipBest", 2, function(player)
		local data = DataService.Get(player)
		local stats = DataService.GetStats(player)
		if not data or not stats then
			return { ok = false }
		end
		local sorted = table.clone(data.Pets)
		table.sort(sorted, function(a, b)
			return StatCalc.PetValue(a) > StatCalc.PetValue(b)
		end)
		DataService.Update(player, function(d)
			d.Equipped = {}
			for i = 1, math.min(stats.PetSlots, #sorted) do
				table.insert(d.Equipped, sorted[i].Id)
			end
		end)
		PetService.UpdateAttribute(player)
		return { ok = true }
	end)

	-- Umbenennen nur mit vorgefertigten Namen (Index in Settings.PetNames, 0 = Name löschen)
	Remotes.OnInvoke("RenamePet", 4, function(player, uid, nameIndex)
		if not Validate.String(uid, 20) or not Validate.Int(nameIndex, 0, #Settings.PetNames) then
			return { ok = false }
		end
		local data = DataService.Get(player)
		if not data or not findPet(data, uid) then
			return { ok = false, msg = "Dieses Pet gehört dir nicht." }
		end
		DataService.Update(player, function(d)
			local pet = findPet(d, uid)
			if pet then
				pet.Name = if nameIndex == 0 then "" else Settings.PetNames[nameIndex]
			end
		end)
		PetService.UpdateAttribute(player)
		return { ok = true }
	end)

	Remotes.OnInvoke("ReleasePet", 4, function(player, uid)
		if not Validate.String(uid, 20) then
			return { ok = false }
		end
		local data = DataService.Get(player)
		if not data or not findPet(data, uid) then
			return { ok = false, msg = "Dieses Pet gehört dir nicht." }
		end
		DataService.Update(player, function(d)
			local _, idx = findPet(d, uid)
			if idx then
				table.remove(d.Pets, idx)
			end
			local e = table.find(d.Equipped, uid)
			if e then
				table.remove(d.Equipped, e)
			end
		end)
		PetService.UpdateAttribute(player)
		return { ok = true }
	end)
end

return PetService
