--!strict
--[=[
	@class Component
	@within Kitty
	Tag-based component system backed by observer lifecycle hooks.
]=]

local Logger = require(script.Parent.Logger)
local Observer = require(script.Parent.Observer)

export type ComponentDef = {
	Init: ((self: any) -> ())?,
	Destroy: ((self: any) -> ())?,
	[string]: any,
}

type RegistryEntry = {
	instances: { [Instance]: any },
	def: ComponentDef,
	stop: (() -> ())?,
}

local _registry: { [string]: RegistryEntry } = {}

local Component = {}

--[=[
	Registers a component definition for a CollectionService tag.

	@param tag string
	@param def ComponentDef
	@return any
]=]
function Component.new(tag: string, def: ComponentDef)
	assert(type(tag) == "string", "Component tag must be a string")

	local existing = _registry[tag]
	if existing and existing.stop then
		existing.stop()
	end

	local entry: RegistryEntry = { instances = {}, def = def, stop = nil }
	_registry[tag] = entry

	local function attach(inst: Instance)
		local obj = setmetatable({ Instance = inst }, { __index = def })
		entry.instances[inst] = obj
		if obj.Init then
			local ok, err = pcall(function()
				obj.Init(obj)
			end)
			if not ok then
				Logger.warn("Component", `Init error on {tag}: {err}`)
			end
		end
	end

	local function detach(inst: Instance)
		local obj = entry.instances[inst]
		if obj and obj.Destroy then
			local ok, err = pcall(function()
				obj.Destroy(obj)
			end)
			if not ok then
				Logger.warn("Component", `Destroy error on {tag}: {err}`)
			end
		end
		entry.instances[inst] = nil
	end

	entry.stop = Observer.observeTag(tag, function(inst: Instance)
		attach(inst)
		return function()
			detach(inst)
		end
	end)

	Logger.debug("Component", `Registered component for tag: {tag}`)

	return {
		GetAll = function()
			local list = {}
			for _, obj in entry.instances do
				table.insert(list, obj)
			end
			return list
		end,
		FromInstance = function(inst: Instance)
			return entry.instances[inst]
		end,
		Destroy = function()
			if _registry[tag] ~= entry then
				return
			end
			if entry.stop then
				entry.stop()
			end
			_registry[tag] = nil
		end,
	}
end

return Component
