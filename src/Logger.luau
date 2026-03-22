--!strict
--[=[
	@class Logger
	Structured logging helper used by framework internals and user modules.
]=]

export type LogLevel = "debug" | "info" | "warn" | "error"

local LEVELS: { [LogLevel]: number } = {
	debug = 1,
	info = 2,
	warn = 3,
	error = 4,
}

local Logger = {}
Logger.__index = Logger
Logger._minLevel = "info"

--[=[
	Sets the minimum log level.

	@param level LogLevel
]=]
function Logger.setLevel(level: LogLevel)
	Logger._minLevel = level
end

local function log(level: LogLevel, tag: string, message: string)
	if LEVELS[level] < LEVELS[Logger._minLevel] then
		return
	end
	local prefix = `[Kitty:{tag}] `
	if level == "warn" then
		warn(prefix .. message)
	elseif level == "error" then
		error(prefix .. message, 2)
	else
		print(prefix .. message)
	end
end

function Logger.debug(tag: string, msg: string)
	log("debug", tag, msg)
end
function Logger.info(tag: string, msg: string)
	log("info", tag, msg)
end
function Logger.warn(tag: string, msg: string)
	log("warn", tag, msg)
end
function Logger.error(tag: string, msg: string)
	log("error", tag, msg)
end

return Logger
