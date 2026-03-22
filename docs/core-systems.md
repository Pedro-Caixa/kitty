---
sidebar_position: 2
---

# Core Systems

This guide explains the core architecture primitives in Kitty and when to use each one.

## Service

Services are server-side singletons for game state and authoritative logic.

Use Services for:

- player/session state
- economy and progression logic
- server-only integrations

Example:

```lua
local Kitty = require(game:GetService("ReplicatedStorage").Packages.Kitty)

local InventoryService = Kitty.Service("InventoryService", {
	_data = {},
})

function InventoryService:Init()
	-- Wire dependencies here.
end

function InventoryService:Start()
	-- Run listeners/gameplay logic here.
end

function InventoryService:GetCoins(player)
	local state = self._data[player]
	return if state then state.coins else 0
end

return InventoryService
```

## Controller

Controllers are client-side singletons for UI, input, camera, and visual state.

Use Controllers for:

- UI orchestration
- client input mapping
- local-only feedback and effects

Example:

```lua
local Kitty = require(game:GetService("ReplicatedStorage").Packages.Kitty)

local HUDController = Kitty.Controller("HUDController", {})

function HUDController:Init()
	-- Load refs to UI modules/widgets.
end

function HUDController:Start()
	-- Connect buttons/input and start local flows.
end

return HUDController
```

## Component

Components attach behavior to tagged instances and are ideal for world objects.

Use Components for:

- interactables
- pickups
- trigger zones
- reusable object behavior

Example:

```lua
local Kitty = require(game:GetService("ReplicatedStorage").Packages.Kitty)

local CoinComponent = Kitty.Component("Coin", {
	value = 1,
})

function CoinComponent:Construct()
	-- self.Instance is the tagged Instance.
end

function CoinComponent:Start()
	self.Instance.Touched:Connect(function(hit)
		-- Handle pickup.
	end)
end

return CoinComponent
```

## Logger

Kitty Logger gives consistent logs across systems.

Use Logger to:

- label log sources
- separate warnings/errors from debug traces
- keep logs readable in larger projects

Example:

```lua
local Kitty = require(game:GetService("ReplicatedStorage").Packages.Kitty)

Kitty.Logger.info("InventoryService", "Inventory initialized")
Kitty.Logger.warn("InventoryService", "Missing cached state for player")
Kitty.Logger.error("InventoryService", "Failed to grant item")
```

## Recommended Pattern

Use this split as a default:

- Service: authoritative state and rules
- Controller: presentation and local UX
- Component: per-instance world behavior
- Logger: diagnostics and runtime visibility

## Built-In Integrations

Kitty exposes several external packages through the root API.

- `Kitty.Trove`
- `Kitty.Promise`
- `Kitty.Observer`
- `Kitty.Packet`
- `Kitty.ProfileStore`
- `Kitty.Replica`

Use the dedicated guide for practical usage patterns and examples:

- [Built-In Packages](./built-in-packages.md)
