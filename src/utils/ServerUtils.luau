--!strict
--[=[
	@class ServerUtils
	@within Utils
	Server metadata and runtime health helpers for matchmaking and diagnostics.
]=]

local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local LocalizationService = game:GetService("LocalizationService")
local RunService = game:GetService("RunService")

local kittyRoot = assert(script.Parent, "ServerUtils must be parented under Kitty").Parent
assert(kittyRoot, "ServerUtils must be parented under Kitty")
local promiseModule = kittyRoot:FindFirstChild("Promise")
assert(promiseModule and promiseModule:IsA("ModuleScript"), "Missing Promise ModuleScript in Kitty")
local promiseOk, Promise = pcall(require, promiseModule)
assert(promiseOk, Promise)

local ServerUtils = {}

-- Server start time (captured at module load)
local _serverStartTime = os.time()
local _serverStartClock = os.clock()
local _heartbeatTimeMs: number? = nil

RunService.Heartbeat:Connect(function(dt)
	_heartbeatTimeMs = dt * 1000
end)

-- Types
export type ServerInfo = {
	JobId: string,
	PlaceId: number,
	GameId: number,
	PlaceVersion: number,
	ServerType: "Public" | "VIP" | "Reserved" | "Studio",
	VIPServerOwner: number?,
	PrivateServerId: string?,
}

export type ServerStats = {
	PlayerCount: number,
	MaxPlayers: number,
	UptimeSeconds: number,
	UptimeFormatted: string,
	MemoryUsageMB: number?,
	HeartbeatTimeMs: number?,
	ServerFPS: number?,
}

export type RegionInfo = {
	CountryCode: string?,
	Region: string?,
	FullName: string?,
}

--[[ 
	Gets the server's job ID (unique identifier for this server instance).
	@return Job ID string
]]
function ServerUtils.GetJobId(): string
	return game.JobId
end

--[[ 
	Gets the current place ID.
	@return Place ID number
]]
function ServerUtils.GetPlaceId(): number
	return game.PlaceId
end

--[[ 
	Gets the current game/universe ID.
	@return Game ID number
]]
function ServerUtils.GetGameId(): number
	return game.GameId
end

--[[ 
	Gets the place version number.
	@return Version number
]]
function ServerUtils.GetPlaceVersion(): number
	return game.PlaceVersion
end

--[[ 
	Gets the current player count.
	@return Number of players
]]
function ServerUtils.GetPlayerCount(): number
	return #Players:GetPlayers()
end

--[[ 
	Gets the maximum player capacity.
	@return Max players number
]]
function ServerUtils.GetMaxPlayers(): number
	return Players.MaxPlayers
end

--[[ 
	Checks if the server is full.
	@return Whether server is at capacity
]]
function ServerUtils.IsFull(): boolean
	return #Players:GetPlayers() >= Players.MaxPlayers
end

--[[ 
	Gets available player slots.
	@return Number of open slots
]]
function ServerUtils.GetAvailableSlots(): number
	return math.max(0, Players.MaxPlayers - #Players:GetPlayers())
end

--[[ 
	Gets the server uptime in seconds.
	@return Uptime in seconds
]]
function ServerUtils.GetUptimeSeconds(): number
	return os.time() - _serverStartTime
end

--[[ 
	Gets the server uptime formatted as a string.
	@param short - Use short format (1h 2m 3s vs 1 hour 2 minutes 3 seconds)
	@return Formatted uptime string
]]
function ServerUtils.GetUptimeFormatted(short: boolean?): string
	local seconds = ServerUtils.GetUptimeSeconds()
	local useShort = short ~= false

	local hours = math.floor(seconds / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)

	local parts = {}

	if hours > 0 then
		table.insert(parts, useShort and `{hours}h` or `{hours} hour{hours > 1 and "s" or ""}`)
	end
	if mins > 0 then
		table.insert(parts, useShort and `{mins}m` or `{mins} minute{mins > 1 and "s" or ""}`)
	end
	if secs > 0 or #parts == 0 then
		table.insert(parts, useShort and `{secs}s` or `{secs} second{secs > 1 and "s" or ""}`)
	end

	return table.concat(parts, " ")
end

--[[ 
	Gets the Unix timestamp when the server started.
	@return Unix timestamp
]]
function ServerUtils.GetStartTime(): number
	return _serverStartTime
end

--[[ 
	Checks if running in Roblox Studio.
	@return Whether in Studio
]]
function ServerUtils.IsStudio(): boolean
	return RunService:IsStudio()
end

--[[ 
	Checks if this is a public server.
	@return Whether public
]]
function ServerUtils.IsPublicServer(): boolean
	return game.PrivateServerId == ""
end

--[[ 
	Checks if this is a VIP server (player-owned private server).
	@return Whether VIP server
]]
function ServerUtils.IsVIPServer(): boolean
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end

--[[ 
	Checks if this is a reserved server (game-created private server).
	@return Whether reserved server
]]
function ServerUtils.IsReservedServer(): boolean
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

--[[ 
	Gets the server type as a string.
	@return "Public", "VIP", "Reserved", or "Studio"
]]
function ServerUtils.GetServerType(): "Public" | "VIP" | "Reserved" | "Studio"
	if RunService:IsStudio() then
		return "Studio"
	elseif ServerUtils.IsVIPServer() then
		return "VIP"
	elseif ServerUtils.IsReservedServer() then
		return "Reserved"
	else
		return "Public"
	end
end

--[[ 
	Gets the VIP server owner's user ID (if applicable).
	@return Owner user ID or nil
]]
function ServerUtils.GetVIPServerOwner(): number?
	if ServerUtils.IsVIPServer() then
		return game.PrivateServerOwnerId
	end
	return nil
end

--[[ 
	Gets the private server ID (if applicable).
	@return Private server ID or nil
]]
function ServerUtils.GetPrivateServerId(): string?
	if game.PrivateServerId ~= "" then
		return game.PrivateServerId
	end
	return nil
end

--[[ 
	Gets the server's country/region code.
	@return Promise resolving to RegionInfo
]]
function ServerUtils.GetRegionAsync(): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		local player = Players:GetPlayers()[1]
		if not player then
			resolve({
				CountryCode = "Unknown",
				Region = "Unknown",
				FullName = "Unknown",
			} :: RegionInfo)
			return
		end

		local success, result = pcall(function()
			return LocalizationService:GetCountryRegionForPlayerAsync(player)
		end)

		if success then
			resolve({
				CountryCode = result,
				Region = result,
				FullName = result,
			} :: RegionInfo)
		else
			-- Fallback - try to get from RobloxLocaleId
			local localeId = LocalizationService.RobloxLocaleId
			resolve({
				CountryCode = localeId:match("%-(%w+)$") or "Unknown",
				Region = localeId,
				FullName = localeId,
			} :: RegionInfo)
		end
	end)
end

--[[ 
	Gets basic server info as a table.
	@return ServerInfo table
]]
function ServerUtils.GetServerInfo(): ServerInfo
	return {
		JobId = game.JobId,
		PlaceId = game.PlaceId,
		GameId = game.GameId,
		PlaceVersion = game.PlaceVersion,
		ServerType = ServerUtils.GetServerType(),
		VIPServerOwner = ServerUtils.GetVIPServerOwner(),
		PrivateServerId = ServerUtils.GetPrivateServerId(),
	}
end

--[[ 
	Gets server statistics.
	@return ServerStats table
]]
function ServerUtils.GetServerStats(): ServerStats
	local stats: ServerStats = {
		PlayerCount = ServerUtils.GetPlayerCount(),
		MaxPlayers = ServerUtils.GetMaxPlayers(),
		UptimeSeconds = ServerUtils.GetUptimeSeconds(),
		UptimeFormatted = ServerUtils.GetUptimeFormatted(true),
		MemoryUsageMB = nil,
		HeartbeatTimeMs = nil,
		ServerFPS = nil,
	}

	-- Try to get performance stats (may not be available on client)
	stats.HeartbeatTimeMs = _heartbeatTimeMs

	-- Calculate approximate server FPS from heartbeat
	if stats.HeartbeatTimeMs and stats.HeartbeatTimeMs > 0 then
		stats.ServerFPS = math.round(1000 / stats.HeartbeatTimeMs)
	end

	return stats
end

--[[ 
	Gets the current memory usage in MB (server-side only).
	@return Memory usage or nil
]]
function ServerUtils.GetMemoryUsageMB(): number?
	if not RunService:IsServer() then
		return nil
	end

	local success, result = pcall(function()
		return Stats:GetTotalMemoryUsageMb()
	end)

	return if success then result else nil
end

--[[ 
	Gets the server's heartbeat time in milliseconds.
	@return Heartbeat time or nil
]]
function ServerUtils.GetHeartbeatMs(): number?
	return _heartbeatTimeMs
end

--[[ 
	Gets approximate server FPS based on heartbeat.
	@return FPS number or nil
]]
function ServerUtils.GetServerFPS(): number?
	local heartbeat = ServerUtils.GetHeartbeatMs()
	if heartbeat and heartbeat > 0 then
		return math.round(1000 / heartbeat)
	end
	return nil
end

--[[ 
	Checks if the server is considered "laggy" based on heartbeat.
	@param threshold - FPS threshold (default: 30)
	@return Whether server FPS is below threshold
]]
function ServerUtils.IsServerLagging(threshold: number?): boolean
	local fps = ServerUtils.GetServerFPS()
	if not fps then
		return false
	end
	return fps < (threshold or 30)
end

--[[ 
	Gets a formatted server description string.
	@return Description string like "Public Server | 5/12 Players | Uptime: 1h 23m"
]]
function ServerUtils.GetServerDescription(): string
	local serverType = ServerUtils.GetServerType()
	local playerCount = ServerUtils.GetPlayerCount()
	local maxPlayers = ServerUtils.GetMaxPlayers()
	local uptime = ServerUtils.GetUptimeFormatted(true)

	return `{serverType} Server | {playerCount}/{maxPlayers} Players | Uptime: {uptime}`
end

--[[ 
	Creates a unique identifier for this server session.
	Combines JobId with start time for uniqueness.
	@return Unique session ID
]]
function ServerUtils.GetSessionId(): string
	return `{game.JobId}_{_serverStartTime}`
end

return ServerUtils
