--!strict
--[=[
	@class RobloxIcons
	Provides standard Unicode characters for common Roblox icons.
]=]

--[=[
	@prop Robux string
	@within RobloxIcons
	Unicode glyph for the Robux icon.
]=]

--[=[
	@prop Premium string
	@within RobloxIcons
	Unicode glyph for the Premium icon.
]=]

--[=[
	@prop Verified string
	@within RobloxIcons
	Unicode glyph for the Verified badge icon.
]=]

local RobloxIcons = {
	Robux = utf8.char(0xE002),
	Premium = utf8.char(0xE001),
	Verified = utf8.char(0xE000),
}

return RobloxIcons

