--!strict
--[=[
	@class Utils
	Kitty utility namespace that groups helper modules for gameplay, platform, and formatting tasks.

]=]

local Utils = {}

--[=[
	@prop BigNumber BigNumber
	@within Utils
	Formatting and conversion helpers for large numeric values.
]=]

--[=[
	@prop BadgeUtils BadgeUtils
	@within Utils
	Helpers for Roblox badge APIs.
]=]

--[=[
	@prop PlayerUtils PlayerUtils
	@within Utils
	Helpers related to players and player state.
]=]

--[=[
	@prop ServerUtils ServerUtils
	@within Utils
	Helpers for server-side environment checks.
]=]

--[=[
	@prop Time TimeUtils
	@within Utils
	Time and duration helper utilities.
]=]

--[=[
	@prop Queue Queue
	@within Utils
	Queue data structure helpers.
]=]

--[=[
	@prop Guid Guid
	@within Utils
	GUID generation helpers.
]=]

--[=[
	@prop RunContext RunContext
	@within Utils
	Helpers for determining the current run context.
]=]

--[=[
	@prop RobloxIcons RobloxIcons
	@within Utils
	Constants for Roblox icon glyphs.
]=]

--[=[
	@prop Abbreviations Abbreviations
	@within Utils
	Number and text abbreviation helpers.
]=]

local function _require(name: string): any
	local child = script:FindFirstChild(name)
	assert(child and child:IsA("ModuleScript"), `Missing ModuleScript '{name}' in Kitty.Utils`)
	local ok, result = pcall(require, child)
	assert(ok, result)
	return result
end

Utils.BigNumber = _require("BigNumber")
Utils.BadgeUtils = _require("BadgeUtils")
Utils.PlayerUtils = _require("PlayerUtils")
Utils.ServerUtils = _require("ServerUtils")
Utils.Time = _require("Time")
Utils.Queue = _require("Queue")
Utils.Guid = _require("Guid")
Utils.RunContext = _require("RunContext")
Utils.RobloxIcons = _require("RobloxIcons")
Utils.Abbreviations = _require("Abbreviations")

return Utils

