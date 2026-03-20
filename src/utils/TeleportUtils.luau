--!strict
--[=[
	@class TeleportUtils
	@within Utils
	TeleportService wrappers for player, party, and reserved-server flows.
]=]

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local utilsRoot = assert(script.Parent, "TeleportUtils must be parented under Kitty")
local kittyRoot = utilsRoot.Parent
assert(kittyRoot, "TeleportUtils must be parented under Kitty")
local promiseModule = kittyRoot:FindFirstChild("Promise")
assert(promiseModule and promiseModule:IsA("ModuleScript"), "Missing Promise ModuleScript in Kitty")
local runContextModule = utilsRoot:FindFirstChild("RunContext")
assert(runContextModule and runContextModule:IsA("ModuleScript"), "Missing RunContext ModuleScript in Kitty.Utils")
local promiseOk, Promise = pcall(require, promiseModule)
assert(promiseOk, Promise)
local runContextOk, RunContext = pcall(require, runContextModule)
assert(runContextOk, RunContext)
local TeleportUtils = {}

-- Types
export type TeleportData = { [string]: any }

export type TeleportOptions = {
	ReservedServer: boolean?,
	ServerInstanceId: string?,
	TeleportData: TeleportData?,
	ShouldReserveServer: boolean?,
}

export type TeleportResult = {
	PrivateServerId: string?,
	AccessCode: string?,
}

-- Constants
local MAX_RETRIES = 3
local RETRY_DELAY = 2

--[[ 
	Teleports a single player to a place.
	@param player - The player to teleport
	@param placeId - The destination place ID
	@param options - Optional teleport options
	@return Promise resolving to TeleportResult
]]
function TeleportUtils.TeleportAsync(
	player: Player,
	placeId: number,
	options: TeleportOptions?
): typeof(Promise.new(function() end))
	return TeleportUtils.TeleportPlayersAsync({ player }, placeId, options)
end

--[[ 
	Teleports multiple players to a place.
	@param players - Array of players to teleport
	@param placeId - The destination place ID
	@param options - Optional teleport options
	@return Promise resolving to TeleportResult
]]
function TeleportUtils.TeleportPlayersAsync(
	players: { Player },
	placeId: number,
	options: TeleportOptions?
): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		if not RunContext.IsServer() then
			reject("TeleportUtils can only teleport from the server")
			return
		end

		if #players == 0 then
			reject("No players to teleport")
			return
		end

		local teleportOptions = Instance.new("TeleportOptions")

		if options then
			if options.ReservedServer then
				teleportOptions.ReservedServerAccessCode = options.ServerInstanceId or ""
			end

			if options.ShouldReserveServer then
				teleportOptions.ShouldReserveServer = true
			end

			if options.TeleportData then
				teleportOptions:SetTeleportData(options.TeleportData)
			end
		end

		local attempt = 0
		local lastError: string?

		while attempt < MAX_RETRIES do
			attempt += 1

			local success, result = pcall(function()
				return TeleportService:TeleportAsync(placeId, players, teleportOptions)
			end)

			if success then
				resolve({
					PrivateServerId = result.PrivateServerId,
					AccessCode = result.ReservedServerAccessCode,
				} :: TeleportResult)
				return
			end

			lastError = tostring(result)

			if attempt < MAX_RETRIES then
				task.wait(RETRY_DELAY)
			end
		end

		reject(`Teleport failed after {MAX_RETRIES} attempts: {lastError}`)
	end)
end

--[[ 
	Teleports all players in the server to a place.
	@param placeId - The destination place ID
	@param options - Optional teleport options
	@return Promise resolving to TeleportResult
]]
function TeleportUtils.TeleportAllAsync(placeId: number, options: TeleportOptions?): typeof(Promise.new(function() end))
	return TeleportUtils.TeleportPlayersAsync(Players:GetPlayers(), placeId, options)
end

--[[ 
	Creates a reserved server and gets the access code.
	@param placeId - The place ID to reserve
	@return Promise resolving to access code string
]]
function TeleportUtils.ReserveServerAsync(placeId: number): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		if not RunContext.IsServer() then
			reject("TeleportUtils.ReserveServerAsync can only be called on the server")
			return
		end

		local success, result = pcall(function()
			return TeleportService:ReserveServer(placeId)
		end)

		if success then
			resolve(result)
		else
			reject(result)
		end
	end)
end

--[[ 
	Teleports players to a reserved server.
	@param players - Array of players
	@param placeId - The destination place ID
	@param accessCode - The reserved server access code
	@param teleportData - Optional data to pass
	@return Promise
]]
function TeleportUtils.TeleportToReservedAsync(
	players: { Player },
	placeId: number,
	accessCode: string,
	teleportData: TeleportData?
): typeof(Promise.new(function() end))
	return TeleportUtils.TeleportPlayersAsync(players, placeId, {
		ReservedServer = true,
		ServerInstanceId = accessCode,
		TeleportData = teleportData,
	})
end

--[[ 
	Gets the teleport data that was passed when teleporting to this server.
	@return TeleportData or nil
]]
function TeleportUtils.GetLocalTeleportData(): TeleportData?
	if not RunContext.IsClient() then
		return nil
	end

	local player = Players.LocalPlayer
	local success, data = pcall(function()
		return player:GetJoinData().TeleportData
	end)

	if success and data then
		return data :: TeleportData
	end

	return nil
end

--[[ 
	Gets the teleport data for a specific player (server-side).
	@param player - The player
	@return TeleportData or nil
]]
function TeleportUtils.GetPlayerTeleportData(player: Player): TeleportData?
	local success, data = pcall(function()
		return player:GetJoinData().TeleportData
	end)

	if success and data then
		return data :: TeleportData
	end

	return nil
end

--[[ 
	Teleports a player to a friend's server.
	@param player - The player to teleport
	@param friendUserId - The friend's user ID
	@return Promise
]]
function TeleportUtils.TeleportToFriendAsync(player: Player, friendUserId: number): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		if not RunContext.IsServer() then
			reject("TeleportUtils.TeleportToFriendAsync can only be called on the server")
			return
		end

		local success, err = pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, "", player)
		end)

		if success then
			resolve()
		else
			reject(err)
		end
	end)
end

--[[ 
	Gets the current server's job ID.
	@return Server job ID string
]]
function TeleportUtils.GetServerJobId(): string
	return game.JobId
end

--[[ 
	Gets the current place ID.
	@return Place ID number
]]
function TeleportUtils.GetPlaceId(): number
	return game.PlaceId
end

--[[ 
	Gets the current game ID.
	@return Game ID number
]]
function TeleportUtils.GetGameId(): number
	return game.GameId
end

--[[ 
	Checks if the current server is a reserved/private server.
	@return Whether this is a reserved server
]]
function TeleportUtils.IsReservedServer(): boolean
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

--[[ 
	Checks if the current server is a VIP server.
	@return Whether this is a VIP server
]]
function TeleportUtils.IsVIPServer(): boolean
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end

--[[ 
	Gets the VIP server owner ID (if applicable).
	@return Owner user ID or 0
]]
function TeleportUtils.GetVIPServerOwner(): number
	return game.PrivateServerOwnerId
end

return TeleportUtils
