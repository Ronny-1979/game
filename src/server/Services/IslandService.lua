--!strict
--[[
	IslandService: die eigene Werkstatt-Insel (Konfig: Deco.lua)
	- Jeder Spieler bekommt beim Beitreten eine freie Insel (wird beim Verlassen wieder abgebaut)
	- Deko kaufen + platzieren (Raster 10×10), abbauen (voller Preis zurück)
	- Besuchen: zu anderen Spielern auf dem Server reisen
	Spieler-Attribute: IslandPlot (Nummer), Ort = "Insel", IslandOwner (Name), IslandOwnerId
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Deco = require(Config:WaitForChild("Deco")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local Progression = require(Shared:WaitForChild("Progression"))
local DecoModels = require(Shared:WaitForChild("DecoModels"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local ZoneService = require(script.Parent:WaitForChild("ZoneService"))
local QuestEvents = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("QuestEvents"))
local Validate = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Validate"))
local Builders = ServerScriptService:WaitForChild("Server"):WaitForChild("World"):WaitForChild("Builders")
local Parts = require(Builders:WaitForChild("Parts"))
local DecorBuilder = require(Builders:WaitForChild("Decor"))

local IslandService = {}

local GRASS = Color3.fromRGB(165, 222, 140)
local BRASS = Color3.fromRGB(215, 170, 80)

local root: Folder
local plotOf: { [Player]: number } = {}
local ownerOf: { [number]: Player } = {}
local plotFolders: { [number]: Folder } = {}
local debounce: { [Player]: number } = {}

local function spawnPos(index: number): Vector3
	return Deco.PlotCenter(index) + Vector3.new(0, 3, -50)
end

local function buildBase(index: number, owner: Player): Folder
	local center = Deco.PlotCenter(index)
	local folder = Instance.new("Folder")
	folder.Name = ("Werkstatt_%d"):format(index)
	folder:SetAttribute("OwnerId", owner.UserId)
	Parts.Island(folder, center, 64, GRASS, BRASS)
	-- Bauplatz (leicht heller), damit man sieht, wo Deko hin darf
	local size = Deco.Zellen * Deco.Zelle
	Parts.Block(center + Vector3.new(0, 0.06, 0), Vector3.new(size, 0.1, size), {
		Name = "Bauplatz",
		Color = GRASS:Lerp(Color3.new(1, 1, 1), 0.18),
		Material = Enum.Material.Grass,
		CanCollide = false,
		CanQuery = true,
		Parent = folder,
	})
	-- Eingang: Spawn-Platte, Werkbank (Menü), Rückweg
	Parts.Cylinder(center + Vector3.new(0, 0.3, -50), 4, 0.3, { Name = "Ankunft", Color = Color3.fromRGB(255, 245, 210), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
	local bench = Parts.Block(center + Vector3.new(-12, 3, -50), Vector3.new(6, 3, 3), {
		Name = "Werkbank",
		Color = Color3.fromRGB(190, 140, 95),
		Material = Enum.Material.WoodPlanks,
		Tags = { "MenuPrompt" },
		Attrs = { Menu = "Insel" },
		Parent = folder,
	})
	Parts.Prompt(bench, "Bauen", "🏡 Werkstatt")
	local back = Parts.Cylinder(center + Vector3.new(12, 0.4, -50), 3, 0.4, {
		Name = "ZurueckZumHub",
		Color = Color3.fromRGB(150, 200, 255),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Tags = { "IslandLeave" },
		Parent = folder,
	})
	Parts.Billboard(back, "↩ Zurück zum Uhrturm-Platz", 3, Vector2.new(250, 40))
	local signPos = center + Vector3.new(0, 0, -58)
	local sign = Parts.Sign(folder, signPos, ("🏡 Werkstatt von\n%s"):format(owner.DisplayName), 14, 5, Vector3.new(0, 0, 1))
	sign.Name = "Namensschild"
	-- Deko am Rand (außerhalb des Bauplatzes)
	DecorBuilder.Scatter(folder, center, size * 0.72, 60, 26, { Boden = GRASS, Akzent = BRASS, Deko = Color3.fromRGB(255, 180, 200) }, 500 + index, function(rel)
		return rel.Z < -40 and math.abs(rel.X) < 22
	end)
	DecorBuilder.Clouds(folder, center, 64, 600 + index)
	local items = Instance.new("Folder")
	items.Name = "Deko"
	items.Parent = folder
	folder.Parent = root
	return folder
end

-- Alle Deko-Stücke eines Spielers (neu) bauen
local function rebuildItems(player: Player)
	local index = plotOf[player]
	local data = DataService.Get(player)
	local folder = index and plotFolders[index]
	if not index or not data or not folder then
		return
	end
	local itemsFolder = folder:FindFirstChild("Deko")
	if not itemsFolder then
		return
	end
	itemsFolder:ClearAllChildren()
	local center = Deco.PlotCenter(index)
	for i, entry in data.Island.Items do
		local item = Deco.Find(entry.Id)
		if item then
			local m = DecoModels.Build(item, Deco.Zelle)
			local pos = Deco.CellPos(center, entry.X, entry.Z, item.Groesse)
			m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, (entry.R or 0) * math.pi / 2, 0))
			m:SetAttribute("Index", i)
			m.Parent = itemsFolder
		end
	end
end

local function assign(player: Player)
	if plotOf[player] then
		return
	end
	local index = 1
	while ownerOf[index] do
		index += 1
	end
	ownerOf[index] = player
	plotOf[player] = index
	plotFolders[index] = buildBase(index, player)
	player:SetAttribute("IslandPlot", index)
	rebuildItems(player)
end

local function release(player: Player)
	local index = plotOf[player]
	if not index then
		return
	end
	-- Besucher auf dieser Insel zurück zum Uhrturm-Platz schicken
	for _, p in Players:GetPlayers() do
		if p ~= player and p:GetAttribute("Ort") == "Insel" and p:GetAttribute("IslandOwnerId") == player.UserId then
			ZoneService.TeleportToZone(p, 0)
			Remotes.Event("Toast"):FireClient(p, "Die Werkstatt wurde geschlossen – zurück am Uhrturm-Platz.", "info")
		end
	end
	if plotFolders[index] then
		plotFolders[index]:Destroy()
	end
	plotFolders[index] = nil
	ownerOf[index] = nil
	plotOf[player] = nil
end

local function goTo(player: Player, owner: Player): boolean
	local index = plotOf[owner]
	if not index then
		return false
	end
	local pos = spawnPos(index)
	ZoneService.TeleportTo(player, pos, 0, pos)
	player:SetAttribute("Ort", "Insel")
	player:SetAttribute("IslandOwner", owner.DisplayName)
	player:SetAttribute("IslandOwnerId", owner.UserId)
	return true
end

-- Ist Feld (x, z) mit Größe size auf der eigenen Insel frei? (ignore = Index, der nicht zählt)
local function isFree(data: any, x: number, z: number, size: number): boolean
	if x < 1 or z < 1 or x + size - 1 > Deco.Zellen or z + size - 1 > Deco.Zellen then
		return false
	end
	for _, entry in data.Island.Items do
		local item = Deco.Find(entry.Id)
		local s = if item then item.Groesse else 1
		if x < entry.X + s and entry.X < x + size and z < entry.Z + s and entry.Z < z + size then
			return false
		end
	end
	return true
end

local function onOwnIsland(player: Player): boolean
	return player:GetAttribute("Ort") == "Insel" and player:GetAttribute("IslandOwnerId") == player.UserId
end

function IslandService.Init()
	local old = workspace:FindFirstChild("Werkstaetten")
	if old then
		old:Destroy()
	end
	root = Instance.new("Folder")
	root.Name = "Werkstaetten"
	root.Parent = workspace
end

function IslandService.Start()
	DataService.OnLoaded(function(player)
		assign(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		release(player)
		debounce[player] = nil
	end)

	local function leavePad(part: Instance)
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				local player = Util.PlayerFromPart(hit)
				if not player then
					return
				end
				local now = os.clock()
				if (debounce[player] or 0) > now then
					return
				end
				debounce[player] = now + 2
				ZoneService.TeleportToZone(player, 0)
			end)
		end
	end
	for _, p in CollectionService:GetTagged("IslandLeave") do
		leavePad(p)
	end
	CollectionService:GetInstanceAddedSignal("IslandLeave"):Connect(leavePad)

	Remotes.OnInvoke("EnterIsland", 1, function(player)
		if not Validate.Alive(player) then
			return { ok = false, msg = "Warte, bis du wieder da bist." }
		end
		assign(player)
		local ok = goTo(player, player)
		if ok then
			Remotes.Event("Toast"):FireClient(player, "🏡 Willkommen in deiner Werkstatt! Bau dir was Schönes.", "info")
		end
		return { ok = ok }
	end)

	Remotes.OnInvoke("VisitIsland", 1, function(player, userId)
		if not Validate.Int(userId, 1, 1e12) then
			return { ok = false }
		end
		local owner = Players:GetPlayerByUserId(userId)
		if not owner or not plotOf[owner] then
			return { ok = false, msg = "Diese Werkstatt gibt es gerade nicht." }
		end
		if not Validate.Alive(player) then
			return { ok = false, msg = "Warte, bis du wieder da bist." }
		end
		goTo(player, owner)
		if owner ~= player then
			Remotes.Event("Toast"):FireClient(owner, ("👋 %s besucht deine Werkstatt!"):format(player.DisplayName), "info")
		end
		return { ok = true }
	end)

	Remotes.OnInvoke("PlaceDeco", 4, function(player, id, x, z, r)
		if not Validate.String(id, 30) or not Validate.Int(x, 1, Deco.Zellen) or not Validate.Int(z, 1, Deco.Zellen) or not Validate.Int(r, 0, 3) then
			return { ok = false }
		end
		local item = Deco.Find(id)
		local data = DataService.Get(player)
		if not item or not data then
			return { ok = false, msg = "Unbekannte Deko." }
		end
		if not onOwnIsland(player) then
			return { ok = false, msg = "Bauen geht nur auf deiner eigenen Werkstatt-Insel." }
		end
		local unlocked, why = Progression.DecoUnlocked(item, data)
		if not unlocked then
			return { ok = false, msg = why }
		end
		if #data.Island.Items >= Deco.MaxDeko then
			return { ok = false, msg = ("Deine Insel ist voll (%d Teile)."):format(Deco.MaxDeko) }
		end
		if item.Boss then
			for _, entry in data.Island.Items do
				if entry.Id == id then
					return { ok = false, msg = "Diesen Pokal hast du schon aufgestellt." }
				end
			end
		end
		if not isFree(data, x, z, item.Groesse) then
			return { ok = false, msg = "Da ist kein Platz." }
		end
		local price = Progression.DecoPrice(item, data)
		if price > 0 and not DataService.Spend(player, price) then
			return { ok = false, msg = "Nicht genug Energie ⚡" }
		end
		DataService.Update(player, function(d)
			table.insert(d.Island.Items, { Id = id, X = x, Z = z, R = r, P = price })
		end)
		rebuildItems(player)
		QuestEvents.Fire(player, "Deko", { Id = id })
		return { ok = true }
	end)

	Remotes.OnInvoke("RemoveDeco", 4, function(player, index)
		local data = DataService.Get(player)
		if not data or not Validate.Int(index, 1, #data.Island.Items) then
			return { ok = false }
		end
		if not onOwnIsland(player) then
			return { ok = false, msg = "Abbauen geht nur auf deiner eigenen Werkstatt-Insel." }
		end
		local entry = data.Island.Items[index]
		local refund = entry.P or 0
		-- Rückerstattung zählt nicht als „gesammelte“ Energie (sonst ließe sich die Statistik hochtreiben)
		DataService.Update(player, function(d)
			table.remove(d.Island.Items, index)
			d.Energy += refund
		end)
		rebuildItems(player)
		return { ok = true, msg = if refund > 0 then ("Abgebaut – %s ⚡ zurück"):format(Util.FormatNumber(refund)) else "Abgebaut" }
	end)
end

return IslandService
