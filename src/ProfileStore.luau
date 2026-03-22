--!strict
--[=[
	@class ProfileStore
	Wrapper around ProfileStore package for persistent player/session data.
]=]

local PackageResolver = require(script.Parent.PackageResolver)

local _cached: any = nil

local function _getProfileStore(): any
	if _cached then
		return _cached
	end

	_cached = PackageResolver.requirePackage({ "profilestore", "ProfileStore" }, "ProfileStore")
	return _cached
end

local ProfileStore = {}

--[=[
	Returns the raw ProfileStore package export.

	@return any
]=]
function ProfileStore.raw(): any
	return _getProfileStore()
end

function ProfileStore.New(...: any): any
	return _getProfileStore().New(...)
end

function ProfileStore.SetConstant(...: any): any
	return _getProfileStore().SetConstant(...)
end

return ProfileStore
