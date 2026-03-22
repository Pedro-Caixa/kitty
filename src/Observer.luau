--!strict
--[=[
	@class Observer
	Wrapper around Observers package for tag, player, and property observation.
]=]

local PackageResolver = require(script.Parent.PackageResolver)

local _cached: any = nil

local function _getObservers(): any
	if _cached then
		return _cached
	end

	_cached = PackageResolver.requirePackage({ "observers", "Observers" }, "Observers")
	return _cached
end

local Observer = {}

--[=[
	Returns the raw Observers package export.

	@return any
]=]
function Observer.raw(): any
	return _getObservers()
end

function Observer.observeTag(tag: string, callback: (...any) -> ...any, ancestors: { Instance }?): () -> ()
	return _getObservers().observeTag(tag, callback, ancestors)
end

function Observer.observePlayer(callback: (...any) -> ...any): () -> ()
	return _getObservers().observePlayer(callback)
end

function Observer.observeCharacter(callback: (...any) -> ...any, allowedPlayers: { Player }?): () -> ()
	return _getObservers().observeCharacter(callback, allowedPlayers)
end

function Observer.observeAttribute(
	instance: Instance,
	name: string,
	callback: (...any) -> ...any,
	guard: ((any) -> boolean)?
): () -> ()
	return _getObservers().observeAttribute(instance, name, callback, guard)
end

function Observer.observeProperty(instance: Instance, property: string, callback: (...any) -> ...any): () -> ()
	return _getObservers().observeProperty(instance, property, callback)
end

function Observer.observeLocalCharacter(callback: (...any) -> ...any): () -> ()
	return _getObservers().observeLocalCharacter(callback)
end

return Observer
