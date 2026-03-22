--!strict
--[=[
	@class Kitty

	Kitty is a lifecycle-managed game framework for Roblox that provides structured
	service and controller management with automatic dependency resolution.

	## Installation

	Install via Wally:
	```toml
	[dependencies]
	Kitty = "pedro-caixa/kitty@0.1.0"
	```

	## Quick Start

	```lua
	local Kitty = require(ReplicatedStorage.Packages.Kitty)

	-- Server-side
	Kitty.new({
		services = ServerScriptService.Services
	})

	-- Client-side
	Kitty.new({
		controllers = StarterPlayer.StarterPlayerScripts.Controllers
	})
	```

	@return Kitty
]=]

return require(script.src)
