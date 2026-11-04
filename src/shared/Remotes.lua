--!strict
--[[
	Remotes: zentrale Liste aller RemoteEvents und RemoteFunctions.
	Server: legt sie an und bietet OnEvent/OnInvoke mit Rate-Limit + pcall.
	Client: wartet auf sie.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Remotes = {}

Remotes.Events = {
	-- Server → Client
	"Data",
	"Toast",
	"Effect",
	"CourseEvent",
	"Bounce",
	"QuickChatShow",
	"BossUi",
	"AbilityUsed",
	-- Client → Server
	"UseAbility",
	"QuickChat",
	"ChangeSetting",
	"RequestData",
}

Remotes.Functions = {
	"BuyUpgrade",
	"Rebirth",
	"HatchEgg",
	"EquipPet",
	"UnequipPet",
	"EquipBest",
	"RenamePet",
	"ReleasePet",
	"ChooseClass",
	"UnlockSkill",
	"ResetSkills",
	"TeleportZone",
	"StartTrack",
	"GetLeaderboard",
	"Admin",
}

local FOLDER_NAME = "Remotes"
local folder: Folder

if RunService:IsServer() then
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	for _, name in Remotes.Events do
		local e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = folder
	end
	for _, name in Remotes.Functions do
		local f = Instance.new("RemoteFunction")
		f.Name = name
		f.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

function Remotes.Event(name: string): RemoteEvent
	local r = folder:WaitForChild(name, 10)
	assert(r and r:IsA("RemoteEvent"), "RemoteEvent fehlt: " .. name)
	return r
end

function Remotes.Function(name: string): RemoteFunction
	local r = folder:WaitForChild(name, 10)
	assert(r and r:IsA("RemoteFunction"), "RemoteFunction fehlt: " .. name)
	return r
end

-- ===== Rate-Limit (nur Server) =====
-- Token-Eimer pro Spieler und Remote: "perSecond" Aufrufe pro Sekunde, kurzer Puffer erlaubt.
type Bucket = { tokens: number, last: number }
local buckets: { [Player]: { [string]: Bucket } } = {}

local function allow(player: Player, name: string, perSecond: number): boolean
	local byName = buckets[player]
	if not byName then
		byName = {}
		buckets[player] = byName
	end
	local now = os.clock()
	local b = byName[name]
	local burst = math.max(2, perSecond * 2)
	if not b then
		b = { tokens = burst, last = now }
		byName[name] = b
	end
	b.tokens = math.min(burst, b.tokens + (now - b.last) * perSecond)
	b.last = now
	if b.tokens >= 1 then
		b.tokens -= 1
		return true
	end
	return false
end

if RunService:IsServer() then
	Players.PlayerRemoving:Connect(function(p)
		buckets[p] = nil
	end)
end

-- Server: RemoteEvent abhören (mit Rate-Limit und Fehlerschutz)
function Remotes.OnEvent(name: string, perSecond: number, handler: (Player, ...any) -> ())
	Remotes.Event(name).OnServerEvent:Connect(function(player: Player, ...)
		if not allow(player, name, perSecond) then
			return
		end
		local ok, err = pcall(handler, player, ...)
		if not ok then
			warn(("[Remotes] Fehler in %s: %s"):format(name, tostring(err)))
		end
	end)
end

-- Server: RemoteFunction beantworten. Handler gibt eine Tabelle {ok=..., msg=...} zurück.
function Remotes.OnInvoke(name: string, perSecond: number, handler: (Player, ...any) -> any)
	Remotes.Function(name).OnServerInvoke = function(player: Player, ...)
		if not allow(player, name, perSecond) then
			return { ok = false, msg = "Nicht so schnell! ⏳" }
		end
		local ok, result = pcall(handler, player, ...)
		if not ok then
			warn(("[Remotes] Fehler in %s: %s"):format(name, tostring(result)))
			return { ok = false, msg = "Da ist etwas schiefgelaufen." }
		end
		return result
	end
end

-- Client: RemoteFunction sicher aufrufen
function Remotes.Invoke(name: string, ...: any): any
	local ok, result = pcall(Remotes.Function(name).InvokeServer, Remotes.Function(name), ...)
	if not ok then
		warn("[Remotes] Aufruf fehlgeschlagen:", name, result)
		return { ok = false, msg = "Keine Verbindung zum Server." }
	end
	return result
end

return Remotes
