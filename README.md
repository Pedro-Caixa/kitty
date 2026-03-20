# Kitty

Lifecycle-managed game framework for Roblox.

This repository contains the framework source, ready for Wally publishing and API documentation generation with Moonwave.

## Local Development

Build a local place file:

```bash
rojo build -o "Kitty-dev.rbxlx"
```

Open the file in Studio, then sync changes with:

```bash
rojo serve
```

## Use Kitty In Another Project

### 1. Add dependency in your game project

In your game's `wally.toml`:

```toml
[dependencies]
Kitty = "pedro-caixa/kitty@0.1.0"
```

Install packages:

```bash
wally install
```

### 2. Map Wally packages in your game `default.project.json`

Make sure your Rojo tree has:

```json
{
  "name": "my-game",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "Packages": {
        "$path": "Packages"
      }
    }
  }
}
```

You can then require Kitty from `ReplicatedStorage.Packages.Kitty`.

For this prototype repository itself (without Wally), require from `ReplicatedStorage.Kitty`.

## Studio Bootstrap Setup

Create these folders in your game:

- `ServerScriptService/Services`
- `StarterPlayer/StarterPlayerScripts/Controllers`

Create one server Script in `ServerScriptService`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kitty = require(ReplicatedStorage.Packages.Kitty)

Kitty.new({
	services = script.Parent.Services,
	-- Optional: user-defined utilities, loaded into Kitty.Utils
	utils = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"),
	-- Optional: user-defined package modules, loaded into Kitty.<ModuleName>
	packages = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"),
	devLogs = true,
})
```

Create one LocalScript in `StarterPlayerScripts`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kitty = require(ReplicatedStorage.Packages.Kitty)

Kitty.new({
	controllers = script.Parent.Controllers,
	utils = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"),
	packages = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"),
	devLogs = true,
})
```

## Prototype API Summary

- `Kitty.new(config)` starts bootstrap on current context (server or client).
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

## Publish To Wally

### 1. Prepare the release version

Update `version` in `wally.toml`.

### 2. Create and push a release tag

```bash
git tag v0.1.0
git push origin v0.1.0
```

Pushing a `v*` tag triggers `.github/workflows/release.yml`, which runs `wally publish` using `WALLY_AUTH_TOKEN`.

### 3. Configure required GitHub secret

In repository settings, add:

- `WALLY_AUTH_TOKEN`: your Wally auth token used for package publishing.

## Publish Moonwave Docs To GitHub Pages

This repo includes `.github/workflows/docs.yml`.

- Trigger: pushes to `main` or manual dispatch.
- Build command: `moonwave build --out-dir dist`.
- Deploy target: GitHub Pages environment.

### One-time GitHub setup

1. Open GitHub repository settings.
2. Go to Pages.
3. Set source to **GitHub Actions**.

Once enabled, docs will publish to `https://pedro-caixa.github.io/kitty/`.

For Rojo workflow details, see the official docs: https://rojo.space/docs.
