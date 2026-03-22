--!strict
--[=[
	@class Signal
	Lightweight signal implementation for event-style communication.
]=]

type Connection = {
	disconnect: (self: Connection) -> (),
	_fn: (...any) -> (),
	_next: Connection?,
}

export type Signal<T...> = {
	connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	fire: (self: Signal<T...>, T...) -> (),
	disconnectAll: (self: Signal<T...>) -> (),
	wait: (self: Signal<T...>) -> T...,
}

local Connection = {}
Connection.__index = Connection

function Connection:disconnect()
	self._fn = function() end
end

local Signal = {}
Signal.__index = Signal

--[=[
	Constructs a new signal.

	@return Signal<T...>
]=]
function Signal.new<T...>(): Signal<T...>
	return setmetatable({ _head = nil }, Signal) :: any
end

function Signal:connect(fn)
	local conn = setmetatable({ _fn = fn, _next = self._head }, Connection)
	self._head = conn
	return conn
end

function Signal:fire(...)
	local node = self._head
	while node do
		node._fn(...)
		node = node._next
	end
end

function Signal:disconnectAll()
	self._head = nil
end

function Signal:wait()
	local thread = coroutine.running()
	local conn
	conn = self:connect(function(...)
		conn:disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

return Signal
