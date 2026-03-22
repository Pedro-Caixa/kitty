---
sidebar_position: 4
---

# Data And Sync

This guide shows how to use ProfileStore and Replica with Kitty for a server-authoritative, client-synced data flow.

## Model

Recommended architecture:

- ProfileStore owns persistent player data on server.
- Service layer reads/writes the profile.
- Replica mirrors a safe subset to clients.
- Controllers read replica data and update UI.

## ProfileStore In A Service

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kitty = require(ReplicatedStorage.Packages.Kitty)

local DataService = Kitty.Service("DataService", {
	_profiles = {},
})

local PROFILE_TEMPLATE = {
	coins = 0,
	level = 1,
}

local PlayerStore = Kitty.ProfileStore.New("PlayerData", PROFILE_TEMPLATE)

function DataService:Start()
	Players.PlayerAdded:Connect(function(player)
		local profile = PlayerStore:StartSessionAsync(tostring(player.UserId))
		if profile then
			self._profiles[player] = profile
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local profile = self._profiles[player]
		if profile then
			profile:EndSession()
			self._profiles[player] = nil
		end
	end)
end

function DataService:AddCoins(player, amount)
	local profile = self._profiles[player]
	if not profile then
		return
	end
	profile.Data.coins += amount
end

return DataService
```

## Replica For Client Sync

Use Replica to publish the client-safe shape of data.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kitty = require(ReplicatedStorage.Packages.Kitty)

local EconomyService = Kitty.Service("EconomyService", {
	_replicas = {},
})

function EconomyService:CreateReplicaFor(player, initialData)
	local replica = Kitty.Replica.New({
		ClassToken = Kitty.Replica.Token("PlayerEconomy"),
		Data = initialData,
		Replication = player,
	})

	self._replicas[player] = replica
	return replica
end

function EconomyService:SetCoins(player, value)
	local replica = self._replicas[player]
	if replica then
		replica:SetValue({"coins"}, value)
	end
end

return EconomyService
```

## Client Consumption Pattern

Controllers should react to replica updates and keep UI in sync.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kitty = require(ReplicatedStorage.Packages.Kitty)

local EconomyController = Kitty.Controller("EconomyController", {})

function EconomyController:Start()
	-- Subscribe to your replica class/token and update UI state.
	-- Keep write operations on server Services.
end

return EconomyController
```

## Practical Rules

- Persist on server with ProfileStore.
- Sync read-safe data to client with Replica.
- Never trust client writes for progression/currency.
- Keep schema changes backward-compatible.
- End profile sessions on player leave/shutdown.

For package-by-package usage details, see:

- [Built-In Packages](./built-in-packages.md)
