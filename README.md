# Kitty

A **lifecycle-managed game framework** for Roblox that helps you organize server logic, client logic, and game components in a clean, scalable way.

## What is Kitty?

Kitty provides a structured way to build Roblox games by separating concerns into:

- **Services** – Server-side game logic (handling players, data, game state)
- **Controllers** – Client-side logic (UI, input handling, client-side state)
- **Components** – Tag-based objects that can be attached to any part in your game
- **Utilities** – Helper functions for common tasks
- **Packages** – Custom modules you can add to extend Kitty

It handles the lifecycle of these modules automatically, so you can focus on writing game logic instead of managing initialization order.

## Getting Started

### Step 1: Set Up Your Game Structure

Create these folders in Roblox Studio:

- **ServerScriptService** → Create a **Services** folder inside it
- **StarterPlayer** → **StarterPlayerScripts** → Create a **Controllers** folder inside it

### Step 2: Add Bootstrap Scripts

**Create a Script in ServerScriptService** (initialize Kitty on the server):

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kitty = require(ReplicatedStorage.Packages.Kitty)

Kitty.new({
	services = script.Parent.Services,
	devLogs = true,
})
```

**Create a LocalScript in StarterPlayer > StarterPlayerScripts** (initialize Kitty on the client):

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kitty = require(ReplicatedStorage.Packages.Kitty)

Kitty.new({
	controllers = script.Parent.Controllers,
	devLogs = true,
})
```

### Step 3: Create Your First Service

Create a **ModuleScript** named `ExampleService` inside `ServerScriptService > Services`:

```lua
local Kitty = require(game:GetService("ReplicatedStorage").Packages.Kitty)

local ExampleService = Kitty.Service("ExampleService", {})

function ExampleService:Init()
	print("ExampleService initialized!")
end

function ExampleService:Start()
	print("ExampleService started!")
end

return ExampleService
```

### Step 4: Create Your First Controller

Create a **LocalScript(as ModuleScript)** named `ExampleController` inside `StarterPlayer > StarterPlayerScripts > Controllers`:

```lua
local Kitty = require(game:GetService("ReplicatedStorage").Packages.Kitty)

local ExampleController = Kitty.Controller("ExampleController", {})

function ExampleController:Init()
	print("ExampleController initialized!")
end

function ExampleController:Start()
	print("ExampleController started!")
end

return ExampleController
```

## Core Features

### Services

Services run on the **server** and manage game logic like player data, scoring, or game state.

```lua
local PlayerService = Kitty.Service("PlayerService", {})

function PlayerService:Start()
	game:GetService("Players").PlayerAdded:Connect(function(player)
		print(player.Name .. " joined!")
	end)
end

return PlayerService
```

### Controllers

Controllers run on the **client** and handle UI, input, and client-side logic.

```lua
local InputController = Kitty.Controller("InputController", {})

function InputController:Start()
	local UserInputService = game:GetService("UserInputService")
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.E then
			print("E key pressed!")
		end
	end)
end

return InputController
```

### Components

Components are pieces of logic you can attach to game objects using tags.

```lua
local Kitty = require(game:GetService("ReplicatedStorage").Packages.Kitty)

local DamageComponent = Kitty.Component("Damage", {
	damage = 10,
})

function DamageComponent:Construct()
	-- Called when the component is created
	print("Damage component created")
end

function DamageComponent:Start()
	-- Called after all components are initialized
	self.Instance.Touched:Connect(function(hit)
		print("Hit: " .. hit.Name .. " for " .. self.damage .. " damage")
	end)
end

return DamageComponent
```

To use a component, add a `CollectionService` tag to a part in your game that matches the component name.

## Built-in Utilities

Kitty comes with helpful utilities in `Kitty.Utils`:

- **ProfileStore** – Save and load player data
- **Replica** – Sync data between server and client
- **Packet** – Send custom network packets
- **Promise** – Handle asynchronous operations
- **Trove** – Automatically clean up connections and objects
- **Observer** – Watch for object changes

Check the [API Documentation](https://github.com/Pedro-Caixa/Kitty) for detailed usage.

## Tips

- **Services** are singletons – only one instance per game
- **Controllers** are singletons on the client
- **Components** can have multiple instances (one per tagged object)
- Kitty automatically calls `Init()` then `Start()` on all modules in the right order
- Use `devLogs = true` in `Kitty.new()` to see debug messages (helpful for learning!)

## Need Help?

Check out the full [API documentation](https://github.com/Pedro-Caixa/Kitty) for more advanced features and examples.

- `config.devLogs` enables debug/info logs during development. By default, Kitty only prints warnings/errors.
- `config.utils` (optional) registers user utility ModuleScripts into `Kitty.Utils`.
- `config.packages` (optional) registers user package ModuleScripts into `Kitty.<ModuleName>`.
- `Kitty.Service(name, definition)` registers a service module.
- `Kitty.Controller(name, definition)` registers a controller module.
- `Kitty.Component(tag, definition)` binds behavior to tagged instances using Observers.
- `Kitty.DefineEnums(definition)` creates enum-like tables.
- `Kitty.Observer` provides built-in access to RbxObservers helpers (e.g. `observeTag`, `observePlayer`, `observeCharacter`).
- `Kitty.Packet` provides built-in access to ByteNet (`defineNamespace`, `definePacket`, `dataTypes`).
- `Kitty.Trove` provides built-in access to Trove (`new`).
- `Kitty.Promise` provides built-in access to Promise (`new`, `resolve`, `reject`, `try`, `all`).
- `Kitty.Utils` provides built-in and user-registered utility modules.
- `Kitty.RegisterUtils(folder)` manually registers custom utility ModuleScripts into `Kitty.Utils`.
- `Kitty.RegisterPackages(folder)` manually registers custom package ModuleScripts into Kitty root.

If a user utility or package has the same name as an existing Kitty utility/member,
the user module takes precedence and replaces the existing one.

## Utils

Use BigNumber from the built-in utils namespace:

```lua
local Kitty = require(ReplicatedStorage.Packages.Kitty)
local BigNumber = Kitty.Utils.BigNumber

local cash = BigNumber.from(1500)
cash = cash:mul(10)

print(cash:toString()) -- 15K
```

## Built-in Dependencies

Kitty now ships with built-in package integration for:

- `Observers` (`sleitnick/observers`)
- `ByteNet` (`ffrostflame/bytenet`)
- `Trove` (`sleitnick/trove`)
- `Promise` (`evaera/promise`)

Run `wally install` in your game project so `ReplicatedStorage.Packages` contains these modules.
