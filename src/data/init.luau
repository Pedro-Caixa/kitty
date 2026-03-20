--!strict
--[=[
	@class Data
	@within Kitty
	Compatibility data-store bridge that can be configured with ProfileStore/Replica implementations.
]=]
export type DataStore = {
	LoadProfile: (self: DataStore, player: Player) -> (),
	ReleaseProfile: (self: DataStore, player: Player) -> (),
	GetProfile: (self: DataStore, player: Player) -> any,
	GetReplica: (self: DataStore, player: Player) -> any,
}

local Data = {}

--[=[
	Creates a data store adapter after `Data.configure` is provided.

	@param name string
	@param template { [string]: any }
	@return DataStore
]=]
function Data.CreateStore(name: string, template: { [string]: any }): DataStore
	error(
		`[Kitty.Data] CreateStore called but peer dependencies (ProfileStore, Replica) `
			.. `are not configured. Call Data.configure(ProfileStore, Replica) first.`,
		2
	)
end

--[=[
	Configures the data adapter factory with ProfileStore and Replica backends.

	@param ProfileStore any
	@param Replica any
]=]
function Data.configure(ProfileStore: any, Replica: any)
	Data.CreateStore = function(name: string, template: { [string]: any }): DataStore
		local store = ProfileStore.New(name, template)
		local replicas: { [Player]: any } = {}

		local impl: DataStore = {} :: any
		setmetatable(impl, { __index = impl })

		function impl:LoadProfile(player)
			local profile = store:LoadProfileAsync("player_" .. player.UserId)
			if profile then
				profile:AddUserId(player.UserId)
				profile:Reconcile()
				local replica = Replica.new({
					ClassToken = Replica.NewClassToken(name),
					Data = profile.Data,
					Replication = "All",
				})
				replicas[player] = replica
			end
		end

		function impl:ReleaseProfile(player)
			local replica = replicas[player]
			if replica then
				replica:Destroy()
			end
			replicas[player] = nil
		end

		function impl:GetReplica(player)
			return replicas[player]
		end

		return impl
	end
end

return Data
