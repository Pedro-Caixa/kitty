--!strict
--[=[
	@class Controller
	Factory for creating Kitty controller definitions.
]=]

local Logger = require(script.Parent.Logger)

export type ControllerDef = {
	KittyInit: ((self: any) -> ())?,
	KittyStart: ((self: any) -> ())?,
	[string]: any,
}

local Controller = {}

--[=[
	Creates a controller definition with framework metadata.

	@param name string
	@param def ControllerDef
	@return ControllerDef
]=]
function Controller.new(name: string, def: ControllerDef): ControllerDef
	assert(type(name) == "string", "Controller name must be a string")
	assert(type(def) == "table", "Controller definition must be a table")

	def._kittyName = name
	def._kittyType = "Controller"

	Logger.debug("Controller", `Registered controller: {name}`)
	return def
end

return Controller
