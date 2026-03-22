--!strict
--[=[
	@class Enum
	Utility for defining read-only enum tables with reverse lookups.
]=]

export type EnumItem = {
	Name: string,
	Value: number,
}

export type KittyEnum = {
	[string]: EnumItem,
	fromValue: (self: KittyEnum, value: number) -> EnumItem?,
	fromName: (self: KittyEnum, name: string) -> EnumItem?,
}

local Enum = {}

--[=[
	Defines one or more Kitty enums.

	@param defs { [string]: { string } }
	@return { [string]: KittyEnum }
]=]
function Enum.define(defs: { [string]: { string } }): { [string]: KittyEnum }
	local result: { [string]: KittyEnum } = {}

	for enumName, values in defs do
		local enum: any = {}

		-- build items
		for i, name in values do
			local item: EnumItem = { Name = name, Value = i }
			enum[name] = item
		end

		-- lookup helpers
		function enum:fromValue(v: number): EnumItem?
			for _, item in self do
				if type(item) == "table" and item.Value == v then
					return item
				end
			end
			return nil
		end

		function enum:fromName(n: string): EnumItem?
			return self[n]
		end

		-- lock against typos
		setmetatable(enum, {
			__index = function(_, key)
				error(`KittyEnum "{enumName}" has no member "{key}"`, 2)
			end,
			__newindex = function()
				error(`KittyEnum "{enumName}" is read-only`, 2)
			end,
		})

		result[enumName] = enum
	end

	return result
end

return Enum
