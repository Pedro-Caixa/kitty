---
sidebar_position: 3
---

# Built-In Packages

Kitty wraps several external libraries so you can access them from a consistent API.

## Why Wrappers Exist

Kitty wrappers give you:

- stable entry points (`Kitty.Trove`, `Kitty.Promise`, etc.)
- simpler migration between package path/layout changes
- a single place to discover framework dependencies

For advanced or package-specific APIs, use the raw export:

```lua
local Kitty = require(game:GetService("ReplicatedStorage").Packages.Kitty)
local TrovePackage = Kitty.Trove.raw()
```

## Trove

Use Trove to clean up connections, tasks, instances, and observers when a system is destroyed.

Typical pattern inside a Service or Controller:

```lua
local Kitty = require(game:GetService("ReplicatedStorage").Packages.Kitty)

local ExampleController = Kitty.Controller("ExampleController", {})

function ExampleController:Init()
	self._trove = Kitty.Trove.new()
end

function ExampleController:Start()
	local connection = game:GetService("UserInputService").InputBegan:Connect(function() end)
	self._trove:Add(connection)
end

function ExampleController:Destroy()
	if self._trove then
		self._trove:Destroy()
	end
end

return ExampleController
```

Rule of thumb:

- create one trove per lifetime scope
- add every connection/task/object you create in that scope
- destroy that trove when the scope ends

## Promise

Use Promise for async flows with clear success/failure handling.

```lua
local Kitty = require(game:GetService("ReplicatedStorage").Packages.Kitty)

local function getUserData(userId)
	return Kitty.Promise.new(function(resolve, reject)
		local ok, result = pcall(function()
			return { userId = userId, coins = 100 }
		end)

		if ok then
			resolve(result)
		else
			reject(result)
		end
	end)
end
```

Useful helpers:

- `Kitty.Promise.resolve(...)`
- `Kitty.Promise.reject(...)`
- `Kitty.Promise.try(...)`
- `Kitty.Promise.all({...})`

## Observer

Use Observer helpers to react to runtime changes without manual polling.

```lua
local Kitty = require(game:GetService("ReplicatedStorage").Packages.Kitty)

local stop = Kitty.Observer.observeTag("DamageZone", function(instance)
	print("Tagged instance observed", instance:GetFullName())

	return function()
		print("Tagged instance removed", instance:GetFullName())
	end
end)

-- Later: stop observing
stop()
```

Common wrappers:

- `observeTag`
- `observePlayer`
- `observeCharacter`
- `observeAttribute`
- `observeProperty`

## Packet (ByteNet)

Use Packet wrappers for strongly-defined network contracts.

```lua
local Kitty = require(game:GetService("ReplicatedStorage").Packages.Kitty)
local t = Kitty.Packet.dataTypes()

local Net = Kitty.Packet.defineNamespace("Game", function()
	return {
		CoinDelta = Kitty.Packet.definePacket({
			value = t.int32,
		}),
	}
end)
```

Recommended pattern:

- define packet schemas in one shared module
- fire packets from Services
- consume packets from Controllers

## ProfileStore

Use ProfileStore for persistent server-authoritative data.

```lua
local Kitty = require(game:GetService("ReplicatedStorage").Packages.Kitty)

local PROFILE_TEMPLATE = {
	coins = 0,
	level = 1,
}

local Store = Kitty.ProfileStore.New("PlayerData", PROFILE_TEMPLATE)
```

Best practices:

- load profiles on player join
- mutate only on server
- release/end sessions when players leave
- keep templates backward-compatible

## Replica

Use Replica to mirror server data to clients.

```lua
local Kitty = require(game:GetService("ReplicatedStorage").Packages.Kitty)

local token = Kitty.Replica.Token("PlayerState")

local replica = Kitty.Replica.New({
	ClassToken = token,
	Data = { coins = 0, level = 1 },
	Replication = player,
})

replica:SetValue({"coins"}, 25)
```

Recommended flow:

- Service owns the source-of-truth state
- Service updates Replica as state changes
- Controller reads Replica and updates UI

## Choosing Between ProfileStore And Replica

Use ProfileStore when data must persist across sessions.
Use Replica when data must stay in sync between server and clients in real time.
Use both together for most progression systems.
