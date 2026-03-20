--!strict
--[=[
	@class Utils
	Kitty utility namespace that groups helper modules for gameplay, platform, and formatting tasks.

	@prop BigNumber BigNumber
	@prop BadgeUtils BadgeUtils
	@prop PlayerUtils PlayerUtils
	@prop ServerUtils ServerUtils
	@prop Time TimeUtils
	@prop Queue Queue
	@prop Guid Guid
	@prop RunContext RunContext
	@prop RobloxIcons RobloxIcons
	@prop Abbreviations Abbreviations
]=]

local Utils = {}

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
