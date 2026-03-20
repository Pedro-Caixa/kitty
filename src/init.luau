--!strict
--[=[
	@class Kitty
	Kitty framework root API.

	@prop Service (name: string, def: ServiceDef) -> ServiceDef
	@prop Controller (name: string, def: ControllerDef) -> ControllerDef
	@prop Component (tag: string, def: ComponentDef) -> any
	@prop DefineEnums (defs: { [string]: { string } }) -> { [string]: KittyEnum }
	@prop Observer Observer
	@prop Packet Packet
	@prop Trove Trove
	@prop Promise Promise
	@prop ProfileStore ProfileStore
	@prop Replica Replica
	@prop Utils Utils
]=]
local Bootstrap = require(script.Bootstrap)
local Service = require(script.Service)
local Controller = require(script.Controller)
local Enum = require(script.Enum)
local Component = require(script.Component)
local Logger = require(script.Logger)
local Observer = require(script.Observer)
local Packet = require(script.Packet)
local Trove = require(script.Trove)
local Promise = require(script.Promise)
local ProfileStore = require(script.ProfileStore)
local Replica = require(script.Replica)
local Utils = require(script.utils)

export type KittyConfig = Bootstrap.KittyConfig
export type ServiceDef = Service.ServiceDef
export type ControllerDef = Controller.ControllerDef

local Kitty = {}

local function _collectModuleScripts(folder: Instance): { ModuleScript }
	local modules: { ModuleScript } = {}
	for _, child in folder:GetDescendants() do
		if child:IsA("ModuleScript") then
			table.insert(modules, child)
		end
	end

	table.sort(modules, function(a, b)
		return a:GetFullName() < b:GetFullName()
	end)

	return modules
end

local function _registerFromFolder(target: { [string]: any }, folder: Instance, namespace: string)
	for _, moduleScript in _collectModuleScripts(folder) do
		local ok, result = pcall(require, moduleScript)
		if ok then
			if result ~= nil then
				target[moduleScript.Name] = result
			else
				Logger.warn("Kitty", `{namespace} module {moduleScript:GetFullName()} returned nil and was skipped`)
			end
		else
			Logger.warn("Kitty", `Failed loading {namespace} module {moduleScript:GetFullName()}: {result}`)
		end
	end
end

--[=[
	Registers utility modules from a folder into Kitty.Utils.

	If a utility name matches an existing utility, the custom one replaces it.

	@param utilsFolder Instance
]=]
function Kitty.RegisterUtils(utilsFolder: Instance)
	_registerFromFolder(Kitty.Utils, utilsFolder, "Utils")
end

--[=[
	Registers package modules from a folder into Kitty root.

	Each ModuleScript is exposed as Kitty.<ModuleScriptName>. If a name matches
	an existing Kitty member, the custom package replaces it.

	@param packagesFolder Instance
]=]
function Kitty.RegisterPackages(packagesFolder: Instance)
	_registerFromFolder(Kitty, packagesFolder, "Packages")
end

--[=[
	Bootstraps Kitty and runs lifecycle phases.

	@param config KittyConfig
]=]
function Kitty.new(config: Bootstrap.KittyConfig)
	if config.utils then
		Kitty.RegisterUtils(config.utils)
	end

	if config.packages then
		Kitty.RegisterPackages(config.packages)
	end

	Bootstrap.init(config)
end

Kitty.Service = Service.new
Kitty.Controller = Controller.new
Kitty.Component = Component.new
Kitty.DefineEnums = Enum.define
Kitty.Observer = Observer
Kitty.Packet = Packet
Kitty.Trove = Trove
Kitty.Promise = Promise
Kitty.ProfileStore = ProfileStore
Kitty.Replica = Replica
Kitty.Utils = Utils

Kitty.GetService = Bootstrap.getService
Kitty.GetController = Bootstrap.getController

Kitty.Logger = Logger

return Kitty
