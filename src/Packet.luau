--!strict
--[=[
	@class Packet
	@within Kitty
	Wrapper around ByteNet for packet and namespace definition.
]=]

local PackageResolver = require(script.Parent.PackageResolver)

local _cached: any = nil

local function _getByteNet(): any
	if _cached then
		return _cached
	end

	_cached = PackageResolver.requirePackage({ "bytenet", "ByteNet" }, "ByteNet")
	return _cached
end

local Packet = {}

--[=[
	Returns the raw ByteNet package export.

	@return any
]=]
function Packet.raw(): any
	return _getByteNet()
end

function Packet.defineNamespace(name: string, mapFactory: () -> any): any
	return _getByteNet().defineNamespace(name, mapFactory)
end

function Packet.definePacket(definition: any): any
	return _getByteNet().definePacket(definition)
end

function Packet.dataTypes(): any
	return _getByteNet().dataTypes
end

return Packet
