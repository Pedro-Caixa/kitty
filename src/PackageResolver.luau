--!strict
--[=[
	@class PackageResolver
	Resolves Wally package ModuleScripts by alias and case-insensitive fallback.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PackageResolver = {}

local function _findModule(packages: Instance, names: { string }): ModuleScript?
	for _, name in names do
		local child = packages:FindFirstChild(name)
		if child and child:IsA("ModuleScript") then
			return child
		end
	end

	local loweredNameMap: { [string]: ModuleScript } = {}
	for _, child in packages:GetChildren() do
		if child:IsA("ModuleScript") then
			loweredNameMap[string.lower(child.Name)] = child
		end
	end

	for _, name in names do
		local found = loweredNameMap[string.lower(name)]
		if found then
			return found
		end
	end

	return nil
end

--[=[
	Requires a package module from ReplicatedStorage.Packages by trying aliases.

	@param names { string }
	@param errorLabel string
	@return any
]=]
function PackageResolver.requirePackage(names: { string }, errorLabel: string): any
	local packages = ReplicatedStorage:FindFirstChild("Packages")
	assert(packages, "[Kitty] Missing ReplicatedStorage.Packages. Run wally install.")

	local moduleScript = _findModule(packages, names)
	assert(moduleScript, `[Kitty] Missing package: {errorLabel}. Tried aliases: {table.concat(names, ", ")}`)

	return require(moduleScript)
end

return PackageResolver
