--!strict
-- Janitor: sammelt Verbindungen, Instanzen und Funktionen und räumt alles mit :Cleanup() auf
local Janitor = {}
Janitor.__index = Janitor

export type Janitor = typeof(setmetatable({} :: { _items: { any } }, Janitor))

function Janitor.new(): Janitor
	return setmetatable({ _items = {} }, Janitor)
end

function Janitor.Add<T>(self: Janitor, item: T): T
	table.insert(self._items, item)
	return item
end

local function clean(item: any)
	local t = typeof(item)
	if t == "RBXScriptConnection" then
		item:Disconnect()
	elseif t == "Instance" then
		item:Destroy()
	elseif t == "function" then
		item()
	elseif t == "thread" then
		pcall(task.cancel, item)
	elseif t == "table" then
		if item.Disconnect then
			item:Disconnect()
		elseif item.Destroy then
			item:Destroy()
		elseif item.Cleanup then
			item:Cleanup()
		end
	end
end

function Janitor.Cleanup(self: Janitor)
	local items = self._items
	self._items = {}
	for i = #items, 1, -1 do
		local ok, err = pcall(clean, items[i])
		if not ok then
			warn("[Janitor] Fehler beim Aufräumen:", err)
		end
	end
end

Janitor.Destroy = Janitor.Cleanup

return Janitor
