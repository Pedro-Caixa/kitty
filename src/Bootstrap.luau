--!strict
--[=[
	@class Bootstrap
	Internal lifecycle bootstrapper that discovers and runs services/controllers.
]=]

local RunService = game:GetService("RunService")
local Logger = require(script.Parent.Logger)

export type KittyConfig = {
	services: Instance?,
	controllers: Instance?,
	utils: Instance?,
	packages: Instance?,
	shared: Instance?,
	devLogs: boolean?,
	verbose: boolean?,
}

local _services: { [string]: any } = {}
local _controllers: { [string]: any } = {}
local _isServer = RunService:IsServer()

local Bootstrap = {}

local function _collectModules(folder: Instance): { ModuleScript }
	local moduleScripts: { ModuleScript } = {}
	for _, child in folder:GetDescendants() do
		if child:IsA("ModuleScript") then
			table.insert(moduleScripts, child)
		end
	end

	table.sort(moduleScripts, function(a, b)
		return a:GetFullName() < b:GetFullName()
	end)

	return moduleScripts
end

local function _parseMissingDependency(err: string, kind: "Service" | "Controller"): string?
	if kind == "Service" then
		return string.match(err, '%[Kitty%] Service "(.-)" not found')
	end

	return string.match(err, '%[Kitty%] Controller "(.-)" not found')
end

local function _loadModulesWithDependencies(
	moduleScripts: { ModuleScript },
	kind: "Service" | "Controller",
	registry: { [string]: any }
): { any }
	local loaded: { any } = {}
	local pending: { ModuleScript } = table.clone(moduleScripts)
	local lastErrors: { [ModuleScript]: string } = {}

	while #pending > 0 do
		local progressed = false
		local nextPending: { ModuleScript } = {}

		for _, moduleScript in pending do
			local ok, result = pcall(require, moduleScript)
			if ok and type(result) == "table" then
				local name = result._kittyName or moduleScript.Name
				registry[name] = result
				table.insert(loaded, result)
				progressed = true
			else
				local err = tostring(result)
				lastErrors[moduleScript] = err
				table.insert(nextPending, moduleScript)
			end
		end

		if not progressed then
			for _, moduleScript in nextPending do
				local err = lastErrors[moduleScript] or "Unknown error"
				local missingDependency = _parseMissingDependency(err, kind)
				if missingDependency then
					Logger.warn(
						"Bootstrap",
						`Could not resolve {kind} dependency for {moduleScript:GetFullName()}: missing {kind} '{missingDependency}'`
					)
				else
					Logger.warn("Bootstrap", `Failed to require {moduleScript:GetFullName()}: {err}`)
				end
			end
			break
		end

		pending = nextPending
	end

	return loaded
end

local function runPhase(modules: { any }, phase: string)
	for _, mod in modules do
		if type(mod[phase]) == "function" then
			local ok, err = pcall(mod[phase], mod)
			if not ok then
				Logger.warn("Bootstrap", `{phase} error in {mod._kittyName or "?"}: {err}`)
			end
		end
	end
end

--[=[
	Initializes framework modules and executes KittyInit/KittyStart phases.

	@param config KittyConfig
]=]
function Bootstrap.init(config: KittyConfig)
	if config.devLogs or config.verbose then
		Logger.setLevel("debug")
	else
		Logger.setLevel("warn")
	end

	Logger.info("Bootstrap", `Starting Kitty ({if _isServer then "server" else "client"})`)

	local modules: { any } = {}

	if _isServer and config.services then
		local found = _loadModulesWithDependencies(_collectModules(config.services), "Service", _services)
		for _, m in found do
			table.insert(modules, m)
		end
	end

	if not _isServer and config.controllers then
		local found = _loadModulesWithDependencies(_collectModules(config.controllers), "Controller", _controllers)
		for _, m in found do
			table.insert(modules, m)
		end
	end

	Logger.info("Bootstrap", `Phase: KittyInit`)
	runPhase(modules, "KittyInit")

	Logger.info("Bootstrap", `Phase: KittyStart`)
	runPhase(modules, "KittyStart")

	Logger.info("Bootstrap", "Kitty ready.")
end

--[=[
	Returns a registered service by name.

	@param name string
	@return any
]=]
function Bootstrap.getService(name: string): any
	local s = _services[name]
	assert(s, `[Kitty] Service "{name}" not found. Is it registered and on the server?`)
	return s
end

--[=[
	Returns a registered controller by name.

	@param name string
	@return any
]=]
function Bootstrap.getController(name: string): any
	local c = _controllers[name]
	assert(c, `[Kitty] Controller "{name}" not found. Is it registered and on the client?`)
	return c
end

return Bootstrap
