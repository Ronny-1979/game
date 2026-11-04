--!strict
--[[
	ProfileStore: eigenes DataStore-Modul
	- Session-Lock: nur ein Server darf ein Profil gleichzeitig benutzen
	- Wiederholversuche mit wachsender Wartezeit
	- Schema-Version + Migrationen + Vorlage für fehlende Felder
	- Funktioniert ohne DataStore-Zugriff (Studio) mit einem Ersatz-Profil, das nicht gespeichert wird
]]
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Util"))

export type Options = {
	Name: string,
	Template: { [string]: any },
	Version: number,
	Migrations: { [number]: (any) -> any },
	Retries: number,
	RetryDelay: number,
	LockTimeout: number,
	LockWaitTries: number,
}

local ProfileStore = {}
ProfileStore.__index = ProfileStore

local JOB_ID = if game.JobId ~= "" then game.JobId else ("studio-" .. HttpService:GenerateGUID(false))
-- Im Studio gibt es nur eine Test-Sitzung: alte Sperren vom letzten Test ignorieren
local IS_STUDIO = RunService:IsStudio()

function ProfileStore.new(options: Options)
	local self = setmetatable({}, ProfileStore)
	self.Options = options
	self.Offline = false
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(options.Name)
	end)
	if ok then
		self.Store = store
	else
		warn("[ProfileStore] Kein DataStore-Zugriff – Spielstände werden NICHT gespeichert:", store)
		self.Offline = true
	end
	return self
end

local function keyFor(userId: number): string
	return "Spieler_" .. tostring(userId)
end

-- Ruft fn mit Wiederholversuchen auf. Gibt (ok, ergebnis) zurück.
function ProfileStore:_retry(label: string, fn: () -> any): (boolean, any)
	local delay = self.Options.RetryDelay
	local lastErr
	for attempt = 1, self.Options.Retries do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		local msg = tostring(result)
		-- Studio ohne API-Zugriff: sofort aufgeben und offline weiterspielen
		local lower = string.lower(msg)
		if string.find(lower, "studio access") or string.find(lower, "studioaccesstoapisnotallowed") or string.find(msg, "403") or string.find(lower, "publish") then
			self.Offline = true
			warn("[ProfileStore] Studio hat keinen API-Zugriff (Game Settings → Security). Offline-Modus.")
			return false, result
		end
		warn(("[ProfileStore] %s fehlgeschlagen (Versuch %d): %s"):format(label, attempt, msg))
		task.wait(delay)
		delay *= 1.5
	end
	return false, lastErr
end

function ProfileStore:_prepare(data: any): any
	if type(data) ~= "table" then
		data = Util.DeepCopy(self.Options.Template)
	end
	local version = data.Version or 1
	while version < self.Options.Version do
		local migrate = self.Options.Migrations[version + 1]
		if migrate then
			local ok, result = pcall(migrate, data)
			if ok and type(result) == "table" then
				data = result
			else
				warn("[ProfileStore] Migration auf Version", version + 1, "fehlgeschlagen:", result)
			end
		end
		version += 1
	end
	data.Version = self.Options.Version
	Util.Reconcile(data, self.Options.Template)
	return data
end

--[[
	Lädt ein Profil und setzt die Sitzungs-Sperre.
	Rückgabe: data (oder nil), Fehlertext
]]
function ProfileStore:Load(userId: number): (any, string?)
	if self.Offline then
		return self:_prepare(nil), nil
	end
	local key = keyFor(userId)
	for _ = 1, self.Options.LockWaitTries do
		local lockedByOther = false
		local ok, result = self:_retry("Laden", function()
			return self.Store:UpdateAsync(key, function(old)
				old = if type(old) == "table" then old else { Data = nil, Lock = nil }
				local lock = old.Lock
				if lock and lock.JobId ~= JOB_ID and os.time() - (lock.Time or 0) < self.Options.LockTimeout and not IS_STUDIO then
					lockedByOther = true
					return nil -- nichts schreiben
				end
				old.Lock = { JobId = JOB_ID, Time = os.time() }
				return old
			end)
		end)
		if not ok then
			if self.Offline then
				return self:_prepare(nil), nil
			end
			return nil, "Laden fehlgeschlagen"
		end
		if not lockedByOther then
			local stored = if type(result) == "table" then result.Data else nil
			return self:_prepare(stored), nil
		end
		-- Ein anderer Server hält das Profil noch (z.B. gerade gewechselt) → kurz warten
		task.wait(3)
	end
	return nil, "Dein Spielstand wird noch von einem anderen Server benutzt. Bitte in einer Minute neu beitreten."
end

-- Speichert ein Profil. release = Sperre freigeben (beim Verlassen)
function ProfileStore:Save(userId: number, data: any, release: boolean): boolean
	if self.Offline then
		return true
	end
	local key = keyFor(userId)
	local lostLock = false
	local ok = self:_retry("Speichern", function()
		return self.Store:UpdateAsync(key, function(old)
			old = if type(old) == "table" then old else {}
			local lock = old.Lock
			if lock and lock.JobId ~= JOB_ID and os.time() - (lock.Time or 0) < self.Options.LockTimeout and not IS_STUDIO then
				lostLock = true
				return nil -- fremde Sperre: nicht überschreiben
			end
			old.Data = data
			old.Lock = if release then nil else { JobId = JOB_ID, Time = os.time() }
			return old
		end)
	end)
	if lostLock then
		warn("[ProfileStore] Sperre verloren für", userId, "– nicht gespeichert")
		return false
	end
	return ok
end

return ProfileStore
