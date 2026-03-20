--!strict
--[=[
	@class Trove
	@within Kitty
	Wrapper around Trove for deterministic cleanup management.
]=]

local PackageResolver = require(script.Parent.PackageResolver)

local _cached: any = nil

local function _getTrove(): any
	if _cached then
		return _cached
	end

	_cached = PackageResolver.requirePackage({ "trove", "Trove" }, "Trove")
	return _cached
end

local Trove = {}

--[=[
	Returns the raw Trove package export.

	@return any
]=]
function Trove.raw(): any
	return _getTrove()
end

function Trove.new(...: any): any
	return _getTrove().new(...)
end

return Trove
