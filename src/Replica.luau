--!strict
--[=[
	@class Replica
	@within Kitty
	Wrapper around Replica package for server-authoritative state replication.
]=]

local PackageResolver = require(script.Parent.PackageResolver)

local _cached: any = nil

local function _getReplica(): any
	if _cached then
		return _cached
	end

	_cached = PackageResolver.requirePackage({ "replica", "Replica" }, "Replica")
	return _cached
end

local Replica = {}

--[=[
	Returns the raw Replica package export.

	@return any
]=]
function Replica.raw(): any
	return _getReplica()
end

function Replica.Token(...: any): any
	return _getReplica().Token(...)
end

function Replica.New(...: any): any
	return _getReplica().New(...)
end

function Replica.FromId(...: any): any
	return _getReplica().FromId(...)
end

function Replica.RequestData(...: any): any
	local r = _getReplica()
	if r.RequestData then
		return r.RequestData(...)
	end
	return nil
end

function Replica.OnNew(...: any): any
	local r = _getReplica()
	if r.OnNew then
		return r.OnNew(...)
	end
	return nil
end

return Replica
