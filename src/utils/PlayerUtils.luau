--!strict
--[=[
	@class PlayerUtils
	Player-related helper methods for profile, social, and avatar queries.
]=]

local Players = game:GetService("Players")

local kittyRoot = assert(script.Parent, "PlayerUtils must be parented under Kitty").Parent
assert(kittyRoot, "PlayerUtils must be parented under Kitty")
local promiseModule = kittyRoot:FindFirstChild("Promise")
assert(promiseModule and promiseModule:IsA("ModuleScript"), "Missing Promise ModuleScript in Kitty")
local promiseOk, Promise = pcall(require, promiseModule)
assert(promiseOk, Promise)

local PlayerUtils = {}

-- Constants
local HEADSHOT_SIZE = Enum.ThumbnailSize.Size150x150
local BUST_SIZE = Enum.ThumbnailSize.Size150x150
local FULL_BODY_SIZE = Enum.ThumbnailSize.Size420x420

export type PlayerInfo = {
	UserId: number,
	Username: string,
	DisplayName: string,
	AccountAge: number,
	IsPremium: boolean,
	IsVerified: boolean,
}

export type ThumbnailResult = {
	Image: string,
	IsReady: boolean,
}

--[=[
	Gets a player's headshot thumbnail URL.
	@param userId - The user ID
	@param size - Optional thumbnail size (default: Size150x150)
	@return Promise resolving to ThumbnailResult
]=]
function PlayerUtils.GetHeadshotAsync(userId: number, size: Enum.ThumbnailSize?): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		local success, content, isReady = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, size or HEADSHOT_SIZE)
		end)

		if success then
			resolve({
				Image = content,
				IsReady = isReady,
			} :: ThumbnailResult)
		else
			reject(content)
		end
	end)
end

--[=[
	Gets a player's bust (upper body) thumbnail URL.
	@param userId - The user ID
	@param size - Optional thumbnail size (default: Size150x150)
	@return Promise resolving to ThumbnailResult
]=]
function PlayerUtils.GetBustAsync(userId: number, size: Enum.ThumbnailSize?): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		local success, content, isReady = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.AvatarBust, size or BUST_SIZE)
		end)

		if success then
			resolve({
				Image = content,
				IsReady = isReady,
			} :: ThumbnailResult)
		else
			reject(content)
		end
	end)
end

--[=[
	Gets a player's full body thumbnail URL.
	@param userId - The user ID
	@param size - Optional thumbnail size (default: Size420x420)
	@return Promise resolving to ThumbnailResult
]=]
function PlayerUtils.GetFullBodyAsync(userId: number, size: Enum.ThumbnailSize?): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		local success, content, isReady = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.AvatarThumbnail, size or FULL_BODY_SIZE)
		end)

		if success then
			resolve({
				Image = content,
				IsReady = isReady,
			} :: ThumbnailResult)
		else
			reject(content)
		end
	end)
end

--[=[
	Gets a player's username from their user ID.
	@param userId - The user ID
	@return Promise resolving to username string
]=]
function PlayerUtils.GetUsernameAsync(userId: number): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		local success, username = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)

		if success then
			resolve(username)
		else
			reject(username)
		end
	end)
end

--[=[
	Gets a user ID from a username.
	@param username - The username
	@return Promise resolving to user ID number
]=]
function PlayerUtils.GetUserIdAsync(username: string): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		local success, userId = pcall(function()
			return Players:GetUserIdFromNameAsync(username)
		end)

		if success then
			resolve(userId)
		else
			reject(userId)
		end
	end)
end

--[=[
	Gets a player's friend count.
	@param player - The player
	@return Promise resolving to friend count number
]=]
function PlayerUtils.GetFriendCountAsync(player: Player): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		local success, pages = pcall(function()
			return Players:GetFriendsAsync(player.UserId)
		end)

		if not success then
			reject(pages)
			return
		end

		local count = 0
		while true do
			for _ in pages:GetCurrentPage() do
				count += 1
			end

			if pages.IsFinished then
				break
			end

			local nextSuccess, err = pcall(function()
				pages:AdvanceToNextPageAsync()
			end)

			if not nextSuccess then
				reject(err)
				return
			end
		end

		resolve(count)
	end)
end

--[=[
	Checks if two players are friends.
	@param player - The first player
	@param otherPlayer - The second player (or user ID)
	@return Promise resolving to boolean
]=]
function PlayerUtils.AreFriendsAsync(player: Player, otherPlayer: Player | number): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		local otherUserId = if typeof(otherPlayer) == "Instance" then otherPlayer.UserId else otherPlayer

		local success, isFriend = pcall(function()
			return player:IsFriendsWithAsync(otherUserId)
		end)

		if success then
			resolve(isFriend)
		else
			reject(isFriend)
		end
	end)
end

--[=[
	Gets basic info for a player currently in the game.
	@param player - The player
	@return PlayerInfo table
]=]
function PlayerUtils.GetPlayerInfo(player: Player): PlayerInfo
	return {
		UserId = player.UserId,
		Username = player.Name,
		DisplayName = player.DisplayName,
		AccountAge = player.AccountAge,
		IsPremium = player.MembershipType == Enum.MembershipType.Premium,
		IsVerified = player.HasVerifiedBadge,
	}
end

--[=[
	Gets the player's account age in a human-readable format.
	@param player - The player
	@return Formatted string (e.g., "2 years", "3 months", "5 days")
]=]
function PlayerUtils.GetAccountAgeFormatted(player: Player): string
	local days = player.AccountAge

	if days >= 365 then
		local years = math.floor(days / 365)
		return `{years} year{if years > 1 then "s" else ""}`
	elseif days >= 30 then
		local months = math.floor(days / 30)
		return `{months} month{if months > 1 then "s" else ""}`
	else
		return `{days} day{if days ~= 1 then "s" else ""}`
	end
end

--[=[
	Checks if a player's account is considered "new" (less than specified days).
	@param player - The player
	@param thresholdDays - Days threshold (default: 30)
	@return Whether the account is new
]=]
function PlayerUtils.IsNewAccount(player: Player, thresholdDays: number?): boolean
	return player.AccountAge < (thresholdDays or 30)
end

--[=[
	Gets a player's character if it exists and is loaded.
	@param player - The player
	@return The character or nil
]=]
function PlayerUtils.GetCharacter(player: Player): Model?
	local character = player.Character
	if character and character:FindFirstChild("Humanoid") then
		return character
	end
	return nil
end

--[=[
	Gets a player's humanoid if character exists.
	@param player - The player
	@return The humanoid or nil
]=]
function PlayerUtils.GetHumanoid(player: Player): Humanoid?
	local character = player.Character
	if character then
		return character:FindFirstChildOfClass("Humanoid")
	end
	return nil
end

--[=[
	Gets a player's root part if character exists.
	@param player - The player
	@return The HumanoidRootPart or nil
]=]
function PlayerUtils.GetRootPart(player: Player): BasePart?
	local character = player.Character
	if character then
		return character:FindFirstChild("HumanoidRootPart") :: BasePart?
	end
	return nil
end

--[=[
	Gets a player's position in the world.
	@param player - The player
	@return Position Vector3 or nil if no character
]=]
function PlayerUtils.GetPosition(player: Player): Vector3?
	local rootPart = PlayerUtils.GetRootPart(player)
	if rootPart then
		return rootPart.Position
	end
	return nil
end

--[=[
	Gets the distance between two players.
	@param player1 - First player
	@param player2 - Second player
	@return Distance in studs, or nil if either player has no character
]=]
function PlayerUtils.GetDistanceBetween(player1: Player, player2: Player): number?
	local pos1 = PlayerUtils.GetPosition(player1)
	local pos2 = PlayerUtils.GetPosition(player2)

	if pos1 and pos2 then
		return (pos1 - pos2).Magnitude
	end
	return nil
end

--[=[
	Gets the local player (client-side only).
	@return The local player
]=]
function PlayerUtils.GetLocalPlayer(): Player?
	return Players.LocalPlayer
end

--[=[
	Gets a player by their user ID.
	@param userId - The user ID
	@return The player or nil if not in game
]=]
function PlayerUtils.GetPlayerByUserId(userId: number): Player?
	return Players:GetPlayerByUserId(userId)
end

--[=[
	Gets a player by their username.
	@param username - The username (case-insensitive)
	@return The player or nil if not in game
]=]
function PlayerUtils.GetPlayerByName(username: string): Player?
	return Players:FindFirstChild(username) :: Player?
end

--[=[
	Gets all players in the game.
	@return Array of players
]=]
function PlayerUtils.GetAllPlayers(): { Player }
	return Players:GetPlayers()
end

--[=[
	Gets the player count in the game.
	@return Number of players
]=]
function PlayerUtils.GetPlayerCount(): number
	return #Players:GetPlayers()
end

return PlayerUtils

