--!strict
--[=[
	@class Service
	@within Kitty
	Factory for creating Kitty service definitions.
]=]

local Logger = require(script.Parent.Logger)

export type ServiceDef = {
	KittyInit: ((self: any) -> ())?,
	KittyStart: ((self: any) -> ())?,
	Client: { [string]: (self: any, player: Player, ...any) -> any }?,
	[string]: any,
}

local Service = {}

--[=[
	Creates a service definition with framework metadata.

	@param name string
	@param def ServiceDef
	@return ServiceDef
]=]
function Service.new(name: string, def: ServiceDef): ServiceDef
	assert(type(name) == "string", "Service name must be a string")
	assert(type(def) == "table", "Service definition must be a table")

	def._kittyName = name
	def._kittyType = "Service"

	Logger.debug("Service", `Registered service: {name}`)
	return def
end

return Service
