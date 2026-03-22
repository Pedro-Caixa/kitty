--!strict
--[=[
	@class PackageResolver
	Resolves Wally package ModuleScripts by alias and case-insensitive fallback.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PackageResolver = {}

local function _toModuleScript(instance: Instance?): ModuleScript?
	if not instance then
		return nil
	end

	if instance:IsA("ModuleScript") then
		return instance
	end

	if instance:IsA("Folder") then
		local initModule = instance:FindFirstChild("init")
		if initModule and initModule:IsA("ModuleScript") then
			return initModule
		end
	end

	return nil
end

local function _findModule(packages: Instance, names: { string }): ModuleScript?
	for _, name in names do
		local child = packages:FindFirstChild(name)
		local moduleScript = _toModuleScript(child)
		if moduleScript then
			return moduleScript
		end
	end

	local loweredNameMap: { [string]: ModuleScript } = {}
	for _, child in packages:GetChildren() do
		local moduleScript = _toModuleScript(child)
		if moduleScript then
			loweredNameMap[string.lower(child.Name)] = moduleScript
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

local function _requireModule(moduleScript: ModuleScript): any
	local ok, result = pcall(require, moduleScript)
	assert(ok, `[Kitty] Failed to require package module {moduleScript:GetFullName()}: {tostring(result)}`)
	return result
end

--[=[
	Requires a package module from ReplicatedStorage.Packages by trying aliases.

	@param names { string }
	@param errorLabel string
	@return any
]=]
function PackageResolver.requirePackage(names: { string }, errorLabel: string): any
	-- In an installed Wally package, transitive dependencies may sit next to this
	-- package inside Packages/_Index/<owner_name@version>.
	local srcContainer = script.Parent
	local packageRoot = if srcContainer then srcContainer.Parent else nil
	local packageIndexEntry = if packageRoot then packageRoot.Parent else nil
	if packageIndexEntry then
		local localModuleScript = _findModule(packageIndexEntry, names)
		if localModuleScript then
			return _requireModule(localModuleScript)
		end
	end

	local packages = ReplicatedStorage:FindFirstChild("Packages")
	assert(packages, "[Kitty] Missing ReplicatedStorage.Packages. Run wally install.")

	local moduleScript = _findModule(packages, names)
	assert(moduleScript, `[Kitty] Missing package: {errorLabel}. Tried aliases: {table.concat(names, ", ")}`)

	return _requireModule(moduleScript)
end

return PackageResolver
