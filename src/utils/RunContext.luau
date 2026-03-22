--!strict
--[=[
	@class RunContext
	Runtime environment metadata for server/client/studio capability checks.
]=]

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local VRService = game:GetService("VRService")

local _isEdit = false
local _isServer = RunService:IsServer()
local _isClient = RunService:IsClient()
local _isStudio = RunService:IsStudio()

local _isOnline = game.JobId ~= ""
local _isRCC = _isOnline and _isServer

pcall(function()
	_isEdit = RunService:IsEdit()
end)

export type Label = "Edit" | "Server" | "Client"

--[=[
	@prop Identity Label
	@within RunContext
	Identity label of the current run context.
]=]

--[=[
	@prop IsRCC boolean
	@within RunContext
	Whether this is a dedicated Roblox cloud server process.
]=]

--[=[
	@prop IsEdit boolean
	@within RunContext
	Whether Studio is in edit mode.
]=]

--[=[
	@prop IsTestRun boolean
	@within RunContext
	Whether Studio is currently running a test session.
]=]

--[=[
	@prop IsServer boolean
	@within RunContext
	Whether the code is running on server.
]=]

--[=[
	@prop IsClient boolean
	@within RunContext
	Whether the code is running on client.
]=]

--[=[
	@prop IsStudio boolean
	@within RunContext
	Whether the runtime is Roblox Studio.
]=]

--[=[
	@prop IsOnline boolean
	@within RunContext
	Whether there is an online server job attached to this session.
]=]

--[=[
	@prop IsTenFoot boolean
	@within RunContext
	Whether the current experience is using ten-foot interface mode.
]=]

--[=[
	@prop IsTouch boolean
	@within RunContext
	Whether touch input is available on this device.
]=]

--[=[
	@prop IsVR boolean
	@within RunContext
	Whether VR is enabled in the current runtime.
]=]

local RunContext = table.freeze({
	--- The identity of the current run context.
	Identity = (if _isEdit then "Edit" elseif _isServer then "Server" else "Client") :: Label,

	--- Is this running on a dedicated Roblox server? (RCC = Roblox Cloud Compute)
	IsRCC = _isRCC,

	--- Is the current run an edit session?
	IsEdit = _isEdit,

	--- Is the current run a test session in Studio?
	IsTestRun = _isStudio and not _isEdit,

	--- Is this running from a server context?
	IsServer = _isServer,

	--- Is this running from a client context?
	IsClient = _isClient,

	--- Is this running in Roblox Studio?
	IsStudio = _isStudio,

	--- Is there a dedicated server instance associated with this session?
	IsOnline = _isOnline,

	--- Is the current device using a ten-foot interface (e.g. console)?
	IsTenFoot = GuiService:IsTenFootInterface(),

	--- Is the current device a touch-enabled device (e.g. mobile)?
	IsTouch = UserInputService.TouchEnabled,

	--- Is the current device a VR device?
	IsVR = VRService.VREnabled,
})

return RunContext

