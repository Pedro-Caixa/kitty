--!strict
--[=[
	@class TimeUtils
	@within Utils
	Utility functions for time formatting, cooldowns, and timestamps.
]=]

local TimeUtils = {}

-- Types
export type CooldownTracker = {
	cooldowns: { [string]: number },
	IsOnCooldown: (self: CooldownTracker, key: string) -> boolean,
	StartCooldown: (self: CooldownTracker, key: string, duration: number) -> (),
	GetRemaining: (self: CooldownTracker, key: string) -> number,
	Clear: (self: CooldownTracker, key: string) -> (),
	ClearAll: (self: CooldownTracker) -> (),
}

--[[ 
	Formats seconds into MM:SS format.
	@param seconds - Total seconds
	@return Formatted string "MM:SS"
]]
function TimeUtils.FormatMMSS(seconds: number): string
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d", mins, secs)
end

--[[ 
	Formats seconds into HH:MM:SS format.
	@param seconds - Total seconds
	@return Formatted string "HH:MM:SS"
]]
function TimeUtils.FormatHHMMSS(seconds: number): string
	local hours = math.floor(seconds / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d:%02d", hours, mins, secs)
end

--[[ 
	Formats seconds into a human-readable duration.
	@param seconds - Total seconds
	@param short - Use short format (1h 2m 3s vs 1 hour 2 minutes 3 seconds)
	@return Formatted string
]]
function TimeUtils.FormatDuration(seconds: number, short: boolean?): string
	local useShort = short ~= false

	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)

	local parts = {}

	if days > 0 then
		table.insert(parts, useShort and `{days}d` or `{days} day{days > 1 and "s" or ""}`)
	end
	if hours > 0 or (useShort and #parts > 0) then
		local h = if useShort
			then (if #parts > 0 then string.format("%02dh", hours) else `{hours}h`)
			else `{hours} hour{hours > 1 and "s" or ""}`
		table.insert(parts, h)
	end
	if mins > 0 or (useShort and #parts > 0) then
		local m = if useShort
			then (if #parts > 0 then string.format("%02dm", mins) else `{mins}m`)
			else `{mins} minute{mins > 1 and "s" or ""}`
		table.insert(parts, m)
	end
	if secs > 0 or #parts == 0 or (useShort and #parts > 0) then
		local s = if useShort
			then (if #parts > 0 then string.format("%02ds", secs) else `{secs}s`)
			else `{secs} second{secs > 1 and "s" or ""}`
		table.insert(parts, s)
	end

	return table.concat(parts, if useShort then ":" else " ")
end

--[[ 
	Gets the current Unix timestamp.
	@return Unix timestamp in seconds
]]
function TimeUtils.GetTimestamp(): number
	return os.time()
end

--[[ 
	Gets the current time with millisecond precision.
	@return Time in seconds (with decimals)
]]
function TimeUtils.GetPreciseTime(): number
	return os.clock()
end

--[[ 
	Formats a Unix timestamp to a date string.
	@param timestamp - Unix timestamp
	@param format - Optional strftime format (default: "%Y-%m-%d %H:%M:%S")
	@return Formatted date string
]]
function TimeUtils.FormatTimestamp(timestamp: number, format: string?): string
	return os.date(format or "%Y-%m-%d %H:%M:%S", timestamp) :: string
end

--[[ 
	Gets the time elapsed since a timestamp.
	@param timestamp - Unix timestamp
	@return Seconds elapsed
]]
function TimeUtils.GetElapsed(timestamp: number): number
	return os.time() - timestamp
end

--[[ 
	Checks if a timestamp has expired.
	@param timestamp - Unix timestamp when something started
	@param duration - Duration in seconds
	@return Whether the duration has passed
]]
function TimeUtils.HasExpired(timestamp: number, duration: number): boolean
	return os.time() >= timestamp + duration
end

--[[ 
	Creates a cooldown tracker for managing multiple cooldowns.
	@return CooldownTracker instance
]]
function TimeUtils.CreateCooldownTracker(): CooldownTracker
	local cooldowns: { [string]: number } = {}

	local tracker: CooldownTracker = {
		cooldowns = cooldowns,
		IsOnCooldown = function(self: CooldownTracker, key: string): boolean
			local endTime = self.cooldowns[key]
			if not endTime then
				return false
			end

			if os.clock() >= endTime then
				self.cooldowns[key] = nil
				return false
			end

			return true
		end,
		StartCooldown = function(self: CooldownTracker, key: string, duration: number): ()
			self.cooldowns[key] = os.clock() + duration
		end,
		GetRemaining = function(self: CooldownTracker, key: string): number
			local endTime = self.cooldowns[key]
			if not endTime then
				return 0
			end

			local remaining = endTime - os.clock()
			return math.max(0, remaining)
		end,
		Clear = function(self: CooldownTracker, key: string): ()
			self.cooldowns[key] = nil
		end,
		ClearAll = function(self: CooldownTracker): ()
			table.clear(self.cooldowns)
		end,
	}

	return tracker
end

--[[ 
	Converts milliseconds to seconds.
	@param ms - Milliseconds
	@return Seconds
]]
function TimeUtils.MsToSeconds(ms: number): number
	return ms / 1000
end

--[[ 
	Converts seconds to milliseconds.
	@param seconds - Seconds
	@return Milliseconds
]]
function TimeUtils.SecondsToMs(seconds: number): number
	return seconds * 1000
end

--[[ 
	Creates a simple debounce function.
	@param duration - Cooldown duration in seconds
	@return Function that returns true if not on cooldown (and starts cooldown)
]]
function TimeUtils.CreateDebounce(duration: number): () -> boolean
	local lastTime = 0

	return function(): boolean
		local now = os.clock()
		if now - lastTime >= duration then
			lastTime = now
			return true
		end
		return false
	end
end

--[[ 
	Creates a throttle function that limits calls to once per duration.
	@param callback - Function to throttle
	@param duration - Minimum time between calls
	@return Throttled function
]]
function TimeUtils.Throttle<T...>(callback: (T...) -> (), duration: number): (T...) -> ()
	local lastTime = 0

	return function(...: T...)
		local now = os.clock()
		if now - lastTime >= duration then
			lastTime = now
			callback(...)
		end
	end
end

return TimeUtils
