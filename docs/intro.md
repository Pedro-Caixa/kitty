---
sidebar_position: 1
---

# Intro

Kitty is a lifecycle-managed Roblox framework for organizing services, controllers, components, and utilities.

It gives you a predictable startup flow and a clear architecture split between server systems, client systems, and shared helpers.

## How To Use These Docs

- Start with this page for the big picture.
- Read Core Systems to understand Services, Controllers, Components, and Logger usage.
- Read Built-In Packages to learn practical use of Trove, Promise, Observer, Packet, ProfileStore, and Replica.
- Read Data and Sync to learn practical patterns for ProfileStore and Replica in Kitty projects.
- Use the API section for exact signatures and full reference.

## Kitty Lifecycle

Kitty bootstraps modules in two phases:

1. Init phase: use for dependency wiring and setup.
2. Start phase: use for gameplay logic, listeners, loops, and networking hooks.

This happens in a deterministic order so systems can safely depend on each other.

## Quick Bootstrap

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kitty = require(ReplicatedStorage.Packages.Kitty)

Kitty.new({
	services = game:GetService("ServerScriptService"):WaitForChild("Services"),
	devLogs = true,
})
```

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kitty = require(ReplicatedStorage.Packages.Kitty)

Kitty.new({
	controllers = game:GetService("StarterPlayer").StarterPlayerScripts:WaitForChild("Controllers"),
	devLogs = true,
})
```

## Guides

- [Core Systems](./core-systems.md)
- [Built-In Packages](./built-in-packages.md)
- [Data and Sync (ProfileStore + Replica)](./data-and-sync.md)
