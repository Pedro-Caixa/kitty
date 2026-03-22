--!strict
--[=[
	@class Promise
	Wrapper around Promise for async composition and control flow.
]=]

local PackageResolver = require(script.Parent.PackageResolver)

local _cached: any = nil

local function _getPromise(): any
	if _cached then
		return _cached
	end

	_cached = PackageResolver.requirePackage({ "promise", "Promise" }, "Promise")
	return _cached
end

local Promise = {}

--[=[
	Returns the raw Promise package export.

	@return any
]=]
function Promise.raw(): any
	return _getPromise()
end

function Promise.new(...: any): any
	return _getPromise().new(...)
end

function Promise.resolve(...: any): any
	return _getPromise().resolve(...)
end

function Promise.reject(...: any): any
	return _getPromise().reject(...)
end

function Promise.try(...: any): any
	return _getPromise().try(...)
end

function Promise.all(...: any): any
	return _getPromise().all(...)
end

return Promise
