--!strict
-- Ein einfaches Signal (wie ein eigenes Event)
export type Connection = { Disconnect: (self: Connection) -> (), Connected: boolean }

local Signal = {}
Signal.__index = Signal

export type Signal = typeof(setmetatable({} :: { _handlers: { [any]: (...any) -> () } }, Signal))

function Signal.new(): Signal
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal.Connect(self: Signal, fn: (...any) -> ()): Connection
	local key = {}
	self._handlers[key] = fn
	local conn = { Connected = true }
	function conn.Disconnect(c)
		c.Connected = false
		self._handlers[key] = nil
	end
	return conn :: any
end

function Signal.Fire(self: Signal, ...: any)
	for _, fn in self._handlers do
		task.spawn(fn, ...)
	end
end

function Signal.Wait(self: Signal): ...any
	local thread = coroutine.running()
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal.DisconnectAll(self: Signal)
	table.clear(self._handlers)
end

return Signal
