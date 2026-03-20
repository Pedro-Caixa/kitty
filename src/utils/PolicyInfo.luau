--!strict
--[=[
	@class PolicyInfo
	@within Utils
	PolicyService wrappers for compliance and external-link capability checks.
]=]

local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")

local kittyRoot = assert(script.Parent, "PolicyInfo must be parented under Kitty").Parent
assert(kittyRoot, "PolicyInfo must be parented under Kitty")
local promiseModule = kittyRoot:FindFirstChild("Promise")
assert(promiseModule and promiseModule:IsA("ModuleScript"), "Missing Promise ModuleScript in Kitty")
local promiseOk, Promise = pcall(require, promiseModule)
assert(promiseOk, Promise)

local PolicyInfo = {}

-- Types
export type ExternalLinkType = "X" | "GitHub" | "Twitch" | "Discord" | "Guilded" | "YouTube" | "Facebook"

export type ChatRestriction = "None" | "NoOne" | "Friends" | "Everyone"

export type PolicyResult = {
	AreAdsAllowed: boolean,
	ArePaidRandomItemsRestricted: boolean,
	AllowedExternalLinkReferences: { [ExternalLinkType]: boolean },
	IsEligibleToPurchaseCommerceProduct: boolean,
	IsEligibleToPurchaseSubscription: boolean,
	IsPaidItemTradingAllowed: boolean,
	IsSubjectToChinaPolicies: boolean,
	IsContentSharingAllowed: boolean,
	IsPhotoToAvatarAllowed: boolean,
}

export type ChatPrivacyResult = {
	CanChatWith: boolean,
	CanReceiveFrom: boolean,
}

-- Private state
local _promises: { [number]: any } = {}
local _chatCache: { [string]: any } = {}

local _defaultPolicy: PolicyResult = {
	AreAdsAllowed = false,
	ArePaidRandomItemsRestricted = false,
	AllowedExternalLinkReferences = {},
	IsEligibleToPurchaseCommerceProduct = false,
	IsEligibleToPurchaseSubscription = false,
	IsPaidItemTradingAllowed = false,
	IsSubjectToChinaPolicies = false,
	IsContentSharingAllowed = false,
	IsPhotoToAvatarAllowed = false,
}

-- Private functions
local function _getPolicyInfo(player: Player)
	return Promise.new(function(resolve, reject)
		local success, policyInfo = pcall(function()
			return PolicyService:GetPolicyInfoForPlayerAsync(player)
		end)

		if not success then
			reject(policyInfo)
			return
		end

		-- Convert allowed links array to dictionary for easier lookup
		local allowedLinks: { [ExternalLinkType]: boolean } = {}
		if policyInfo.AllowedExternalLinkReferences then
			for _, link in policyInfo.AllowedExternalLinkReferences do
				allowedLinks[link] = true
			end
		end

		local result: PolicyResult = {
			AreAdsAllowed = policyInfo.AreAdsAllowed or false,
			ArePaidRandomItemsRestricted = policyInfo.ArePaidRandomItemsRestricted or false,
			AllowedExternalLinkReferences = allowedLinks,
			IsEligibleToPurchaseCommerceProduct = policyInfo.IsEligibleToPurchaseCommerceProduct or false,
			IsEligibleToPurchaseSubscription = policyInfo.IsEligibleToPurchaseSubscription or false,
			IsPaidItemTradingAllowed = policyInfo.IsPaidItemTradingAllowed or false,
			IsSubjectToChinaPolicies = policyInfo.IsSubjectToChinaPolicies or false,
			IsContentSharingAllowed = policyInfo.IsContentSharingAllowed or false,
			IsPhotoToAvatarAllowed = policyInfo.IsPhotoToAvatarAllowed or false,
		}

		resolve(result)
	end)
end

local function _getChatCacheKey(userId1: number, userId2: number): string
	-- Always use consistent ordering for cache key
	if userId1 < userId2 then
		return `{userId1}:{userId2}`
	else
		return `{userId2}:{userId1}`
	end
end

--[[
	Gets a promise for a player's policy information.
	@param userId - Optional user ID (defaults to LocalPlayer on client)
	@return Promise that resolves to PolicyResult
]]
function PolicyInfo.GetAsync(userId: number?): any
	local player: Player?

	if userId then
		player = Players:GetPlayerByUserId(userId)
	else
		player = Players.LocalPlayer
	end

	if not player then
		return Promise.reject("Player not found!")
	end

	local playerId = player.UserId

	if _promises[playerId] then
		return _promises[playerId]
	end

	local promise = Promise.retry(function()
		return _getPolicyInfo(player :: Player)
	end, 5)

	_promises[playerId] = promise

	promise:catch(function()
		_promises[playerId] = nil
	end)

	return promise
end

--[[
	Synchronously gets policy info (blocks until resolved).
	@param userId - Optional user ID
	@return PolicyResult
]]
function PolicyInfo.Get(userId: number?): PolicyResult
	local success, result = PolicyInfo.GetAsync(userId):await()

	if success then
		return result
	end

	return _defaultPolicy
end

--[[
	Checks if a specific external link type is allowed for a player.
	@param linkType - The type of external link
	@param userId - Optional user ID
	@return Whether the link type is allowed
]]
function PolicyInfo.IsExternalLinkAllowed(linkType: ExternalLinkType, userId: number?): boolean
	local policy = PolicyInfo.Get(userId)
	return policy.AllowedExternalLinkReferences[linkType] == true
end

--[[
	Clears the cached policy for a player.
	@param userId - The user ID to clear cache for
]]
function PolicyInfo.ClearCache(userId: number): ()
	_promises[userId] = nil
end

return table.freeze(PolicyInfo)
