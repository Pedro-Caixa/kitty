--!strict
--[=[
	@class BadgeUtils
	@within Utils
	Badge query and award helpers with cooldown support.
]=]

local BadgeService = game:GetService("BadgeService")

local utilsRoot = assert(script.Parent, "BadgeUtils must be parented under Kitty")
local kittyRoot = utilsRoot.Parent
assert(kittyRoot, "BadgeUtils must be parented under Kitty")
local promiseModule = kittyRoot:FindFirstChild("Promise")
assert(promiseModule and promiseModule:IsA("ModuleScript"), "Missing Promise ModuleScript in Kitty")
local runContextModule = utilsRoot:FindFirstChild("RunContext")
assert(runContextModule and runContextModule:IsA("ModuleScript"), "Missing RunContext ModuleScript in Kitty.Utils")
local promiseOk, Promise = pcall(require, promiseModule)
assert(promiseOk, Promise)
local runContextOk, RunContext = pcall(require, runContextModule)
assert(runContextOk, RunContext)

local BadgeUtils = {}

-- Types
export type BadgeInfo = {
	Name: string,
	Description: string,
	IconImageId: number,
	IsEnabled: boolean,
}

-- Cooldown tracking to prevent spam
local _awardCooldowns: { [string]: number } = {}
local COOLDOWN_DURATION = 1 -- Seconds between award attempts per player/badge combo

--[[ 
	Awards a badge to a player (server-side only).
	@param player - The player to award
	@param badgeId - The badge ID
	@return Promise resolving to boolean (true if awarded, false if already owned)
]]
function BadgeUtils.AwardAsync(player: Player, badgeId: number): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		if not RunContext.IsServer then
			reject("BadgeUtils.AwardAsync can only be called on the server")
			return
		end

		-- Check cooldown
		local cooldownKey = `{player.UserId}_{badgeId}`
		local now = os.clock()
		if _awardCooldowns[cooldownKey] and now < _awardCooldowns[cooldownKey] then
			resolve(false)
			return
		end
		_awardCooldowns[cooldownKey] = now + COOLDOWN_DURATION

		-- Check if already owned
		local hasSuccess, hasBadge = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
		end)

		if not hasSuccess then
			reject(tostring(hasBadge))
			return
		end

		if hasBadge then
			resolve(false) -- Already has badge
			return
		end

		-- Award badge
		local awardSuccess, err = pcall(function()
			return BadgeService:AwardBadgeAsync(player.UserId, badgeId)
		end)

		if awardSuccess then
			resolve(true)
		else
			reject(tostring(err))
		end
	end)
end

--[[ 
	Checks if a player owns a badge.
	@param userId - The user ID
	@param badgeId - The badge ID
	@return Promise resolving to boolean
]]
function BadgeUtils.HasBadgeAsync(userId: number, badgeId: number): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		local success, result = pcall(function()
			return BadgeService:UserHasBadgeAsync(userId, badgeId)
		end)

		if success then
			resolve(result)
		else
			reject(result)
		end
	end)
end

--[[ 
	Gets information about a badge.
	@param badgeId - The badge ID
	@return Promise resolving to BadgeInfo
]]
function BadgeUtils.GetInfoAsync(badgeId: number): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		local success, result = pcall(function()
			return BadgeService:GetBadgeInfoAsync(badgeId)
		end)

		if success then
			resolve({
				Name = result.Name,
				Description = result.Description,
				IconImageId = result.IconImageId,
				IsEnabled = result.IsEnabled,
			} :: BadgeInfo)
		else
			reject(result)
		end
	end)
end

--[[ 
	Checks multiple badges at once for a player.
	@param userId - The user ID
	@param badgeIds - Array of badge IDs
	@return Promise resolving to { [badgeId]: boolean }
]]
function BadgeUtils.CheckMultipleAsync(userId: number, badgeIds: { number }): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		local results: { [number]: boolean } = {}
		local promises = {}

		for _, badgeId in badgeIds do
			table.insert(
				promises,
				BadgeUtils.HasBadgeAsync(userId, badgeId):andThen(function(hasBadge)
					results[badgeId] = hasBadge
				end)
			)
		end

		Promise.all(promises)
			:andThen(function()
				resolve(results)
			end)
			:catch(function(err)
				reject(err)
			end)
	end)
end

--[[ 
	Awards multiple badges to a player.
	@param player - The player
	@param badgeIds - Array of badge IDs
	@return Promise resolving to { [badgeId]: boolean } (true if newly awarded)
]]
function BadgeUtils.AwardMultipleAsync(player: Player, badgeIds: { number }): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		if not RunContext.IsServer then
			reject("BadgeUtils.AwardMultipleAsync can only be called on the server")
			return
		end

		local results: { [number]: boolean } = {}
		local promises = {}

		for _, badgeId in badgeIds do
			table.insert(
				promises,
				BadgeUtils.AwardAsync(player, badgeId):andThen(function(awarded)
					results[badgeId] = awarded
				end)
			)
		end

		Promise.all(promises)
			:andThen(function()
				resolve(results)
			end)
			:catch(function(err)
				reject(err)
			end)
	end)
end

--[[ 
	Checks if a badge is enabled.
	@param badgeId - The badge ID
	@return Promise resolving to boolean
]]
function BadgeUtils.IsEnabledAsync(badgeId: number): typeof(Promise.new(function() end))
	return BadgeUtils.GetInfoAsync(badgeId):andThen(function(info: BadgeInfo)
		return info.IsEnabled
	end)
end

--[[ 
	Gets the badge icon image ID.
	@param badgeId - The badge ID
	@return Promise resolving to image asset string
]]
function BadgeUtils.GetIconAsync(badgeId: number): typeof(Promise.new(function() end))
	return BadgeUtils.GetInfoAsync(badgeId):andThen(function(info: BadgeInfo)
		return `rbxassetid://{info.IconImageId}`
	end)
end

--[[ 
	Clears award cooldowns (useful for testing).
]]
function BadgeUtils.ClearCooldowns(): ()
	table.clear(_awardCooldowns)
end

return BadgeUtils
