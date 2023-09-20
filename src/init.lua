--!strict

--//Services
local CollectionService = game:GetService("CollectionService")

--// Modules
local JanitorModule = require(script.Parent.Janitor)

--// Variables
local SmartRaycast = {}
local ChannelLog = {}
local CollectionServiceTag = "SRaycast"

--// Settings
SmartRaycast.SanityCheck = true
SmartRaycast.Warnings = true

--[=[
	@class SmartRaycast
]=]

--[=[
	@prop SanityCheck boolean
	@within SmartRaycast

	Setting this property to false will disable sanity checking.
]=]

--[=[
	@prop Warnings boolean
	@within SmartRaycast

	Setting this property to false will disable warnings.
]=]

--// Misc //--

function IsChannel(X: any): boolean
	if typeof(X) ~= "table" or X.Name == nil or X.RayParams == nil or tostring(X) ~= "SmartRaycast Channel" then -- don't question this
		return false
	end

	return true
end

function TypeCheck(Thing: any, ExpectedType: string, CanBeNil: boolean?)
	assert(
		typeof(Thing) == ExpectedType or (typeof(Thing) == "nil" and CanBeNil == true),
		string.format("[SmartRaycast] Expected " .. ExpectedType .. " got %*", typeof(Thing))
	)
end

function TableMemberCheck(t: { [any]: any }?)
	if t == nil then
		return
	end

	for Key, Value in pairs(t) do
		assert(
			typeof(Key) == "number" and typeof(Value) == "Instance",
			"[SmartRaycast] Invalid table stracture expected {[number] : instance}"
		)
	end
end

--// Channel Object //--

--[=[
	A set of RayParams ties to this object. Think of this object as your new RaycastParams.

	@class Channel
]=]

--[=[
	@prop _Name string 
	@readonly
	@within Channel

	Name used to identify channels internaly.
]=]

--[=[
	@prop RayParams RaycastParams
	@within Channel

	RaycastParams tied to the Channel. All properties of the RaycastParams can be changed in runtime **excluding FilterDescendantsInstances**
]=]

--[=[
	@prop _Janitor Janitor
	@readonly
	@within Channel

	[Janitor](https://github.com/howmanysmall/Janitor) Object used for cleanup.
]=]

--[=[
	@prop _ChannelTag string? 
	@readonly
	@within Channel

	Collection Service Tag used to tag instances associated with the Channel.
]=]

--[=[
	@prop _MaintenanceCopy { Instance? } 
	@readonly
	@within Channel

	A copy of FilterDescendantsInstances used to maintain the actual FilterDescendantsInstances.
]=]

--[=[
	@prop _FilterCounter number 
	@readonly
	@within Channel

	Keeps track of the number of instances in FilterDescendantsInstances.
]=]

local Channel = {}
Channel.__index = Channel

type ChannelProperties = {
	_Name: string,
	RayParams: RaycastParams,
	_Janitor: JanitorModule.Janitor,
	_ChannelTag: string?,
	_MaintenanceCopy: { Instance? },
	_FilterCounter: number,
}

export type Channel = typeof(setmetatable({} :: ChannelProperties, Channel))

-- Return "ClassName" when tostring is called on Channel

function Channel.__tostring()
	return "SmartRaycast Channel"
end

--// Constructor

--[=[
	:::info
	The ``CreateChannel`` module function is used to create new channels 
	:::
	Creates a new Channel object.
	@return Channel
]=]
function Channel.new(
	ChannelName: string,
	BaseArray: { Instance }?,
	InstancesToCheck: { Instance }?,
	InstanceLogic: ((Instance) -> boolean)?,
	FilterType: Enum.RaycastFilterType?,
	IgnoreWater: boolean?,
	CollisionGroup: string?,
	RespectCanCollide: boolean?,
	BruteForceAllSlow: boolean?
): Channel
	local self = setmetatable({} :: ChannelProperties, Channel)

	-- Sanity Check (this can be potential overhead if you rely on constant channel creation/destruction)

	if SmartRaycast.SanityCheck == true then
		TypeCheck(ChannelName, "string")
		TypeCheck(BaseArray, "table", true)
		TypeCheck(InstancesToCheck, "table", true)
		TypeCheck(InstanceLogic, "function", true)
		TypeCheck(FilterType, "EnumItem", true)
		TypeCheck(IgnoreWater, "boolean", true)
		TypeCheck(CollisionGroup, "string", true)
		TypeCheck(RespectCanCollide, "boolean", true)
		TypeCheck(BruteForceAllSlow, "boolean", true)

		TableMemberCheck(BaseArray)
		TableMemberCheck(InstancesToCheck)

		assert(
			not (
					(InstancesToCheck == nil and InstanceLogic ~= nil)
					or (InstancesToCheck ~= nil and InstanceLogic == nil)
				),
			"[SmartRaycast] InstancesToCheck and InstanceLogic must both be nil or none of them must be nil"
		)

		assert(ChannelLog[ChannelName] == nil, "[SmartRaycast] A channel with this name already exist: " .. ChannelName)
	end

	-- Set Channel name

	self._Name = ChannelName

	-- Create and set object RayParams

	local RayParams = RaycastParams.new() -- due to typechecking problem

	self.RayParams = RayParams

	-- Set Static RayParams

	local RayParamProperties = {}

	RayParamProperties["FilterType"] = FilterType
	RayParamProperties["IgnoreWater"] = IgnoreWater
	RayParamProperties["CollisionGroup"] = CollisionGroup
	RayParamProperties["RespectCanCollide"] = RespectCanCollide
	RayParamProperties["BruteForceAllSlow"] = BruteForceAllSlow

	for Key, Value in pairs(RayParamProperties) do
		self.RayParams[Key] = Value
	end

	-- Define MaintenanceCopy

	local MaintenanceCopy

	-- Define FilterCounter

	self._FilterCounter = 0

	-- Unpack BaseArray into MaintenanceCopy (if needed)

	if BaseArray then
		MaintenanceCopy = { table.unpack(BaseArray) }
		self._FilterCounter = #MaintenanceCopy
	else
		MaintenanceCopy = {}
	end

	-- Set FilterDescendantsInstances to MaintenanceCopy

	self._MaintenanceCopy = MaintenanceCopy
	self.RayParams.FilterDescendantsInstances = MaintenanceCopy

	-- InstancesToCheck handling

	if InstancesToCheck ~= nil and InstanceLogic ~= nil then
		-- Define ChannelTag

		self._ChannelTag = self._Name .. CollectionServiceTag

		-- Create Janitor for channel

		self._Janitor = JanitorModule.new()

		-- Define Recursive Logic Function

		local function RecursiveLogic(Inst: Instance)
			local Success, Result = pcall(InstanceLogic, Inst)
			if Success == true and Result == true then
				self:_AppendToFDI(Inst)
			end

			local InstanceChildren = Inst:GetChildren()

			for _, Child in pairs(InstanceChildren) do
				RecursiveLogic(Child)
			end
		end

		-- Connect GetInstanceRemovedSignal to Channel Tag to catch the destruction of MaintenanceCopy members

		self._Janitor:Add(
			CollectionService:GetInstanceRemovedSignal(self._ChannelTag):Connect(function(Inst: Instance)
				self:_RemoveFromFDI(Inst)
			end),
			"Disconnect"
		)

		-- Pass descendants of the Instances in InstancesToCheck array threw the InstanceLogic function

		for _, Inst in pairs(InstancesToCheck) do
			RecursiveLogic(Inst)
		end

		-- Connect DescendantAdded event to Instances in InstancesToCheck array

		for _, Inst in pairs(InstancesToCheck) do
			self._Janitor:Add(
				Inst.DescendantAdded:Connect(function(Descendant)
					local Success, Result = pcall(InstanceLogic, Descendant)

					if Success == true and Result == true then
						self:_AppendToFDI(Descendant)
					end
				end),
				"Disconnect"
			)
		end
	end

	-- Add newly created Channel to ChannelLog table

	ChannelLog[self._Name] = self

	return self
end

--// Destroy Method

--[=[
	Destroys a channel by cleaning up references and disconnecting events. After ``:Destroy`` is called, the corresponding FilterDescendantsInstances will no longer be actively maintained.
]=]
function Channel:Destroy()
	if not ChannelLog[self._Name] then
		-- Channel has already been destroyed:

		if SmartRaycast.Warnings == true then
			warn("[SmartRaycast] Called destroy method on channel that has already been destroyed. Memory leak?")
		end

		return
	end

	if self._Janitor ~= nil then
		-- Destroy Janitor (we need to do this before removing channel tag from instances to avoid event spam)

		self._Janitor:Destroy()

		-- Remove Channel Tag from all tagged objects

		local TaggedObjects = CollectionService:GetTagged(self._ChannelTag)

		for _, Inst in pairs(TaggedObjects) do
			CollectionService:RemoveTag(Inst, self._ChannelTag)
		end
	end

	-- Remove destroyed channel from ChannelLog table

	ChannelLog[self.Name] = nil
end

function Channel:_AppendToFDI(Inst: Instance)
	CollectionService:AddTag(Inst, self._ChannelTag)

	self._FilterCounter += 1
	self._MaintenanceCopy[self._FilterCounter] = Inst
	self.RayParams:AddToFilter({ Inst })
end

function Channel:_RemoveFromFDI(Inst: Instance)
	local IndexToRemove = table.find(self._MaintenanceCopy, Inst)
	self._MaintenanceCopy[IndexToRemove :: number] = self._MaintenanceCopy[self._FilterCounter]
	self._MaintenanceCopy[self._FilterCounter] = nil
	self._FilterCounter -= 1
	self.RayParams.FilterDescendantsInstances = self._MaintenanceCopy
end

--// Module Functions //--

--// Destroy Channel Module Alternative function

--[=[
	@within SmartRaycast

	You can use this to destroy channels instead of calling ``:Destroy()`` on a channel.
]=]
function DestroyChannel(WhatToDestroy: string | Channel)
	if IsChannel(WhatToDestroy) == true and typeof(WhatToDestroy) ~= "string" then
		-- WhatToDestroy is a channel:

		WhatToDestroy:Destroy()
	else
		assert(ChannelLog[WhatToDestroy], "[SmartRaycast] Cannot destroy channel because channel does not exist")

		ChannelLog[WhatToDestroy]:Destroy()
	end
end

--[=[
	@within SmartRaycast
	@return Channel? 

	You can use this function to get a Channel Object by providing the name of the Channel, if the Channel does not exist then nil will be returned 
]=]
function GetChannelObject(ChannelName: string): Channel?
	return ChannelLog[ChannelName]
end

--// Raycast Function

--[=[
	@within SmartRaycast

	Cast a ray similiar to ``workspace:Raycast()``. If you want identical usage as the normal roblox method you can do the following:

	```lua
	local SmartRaycast = PathToModule
	local Channel = SmartRaycast.CreateChannel("ExampleChannel")

	local MyResult = workspace:Raycast(Origin,Direction,Channel.RayParams)
	```
]=]
function Cast(Origin: Vector3, Direction: Vector3, ChannelName: string)
	assert(ChannelLog[ChannelName], "[SmartRaycast] No channel found with Name: " .. ChannelName)

	return workspace:Raycast(Origin, Direction, ChannelLog[ChannelName].RayParams)
end

--[=[
	@within SmartRaycast
	@function CreateChannel
	@param ChannelName string -- Name of the channel that will be created. 
	@param BaseArray { Instance }? -- Instances that will always remain present in the FilterDescendantsInstances Array.
	@param InstancesToCheck { Instance }? -- Instances that will have their Descendants checked in runtime using the 'InstanceLogic' function.
	@param InstanceLogic ((Instance) -> boolean)? -- A function that should recieve an instance and return true if the instance should be added in the FilterDescendantsInstances Array. This function is run in protected call so you don't need to worry about any errors.
	@param FilterType Enum.RaycastFilterType?
	@param IgnoreWater boolean?
	@param CollisionGroup string?
	@param RespectCanCollide boolean?
	@param BruteForceAllSlow boolean?
	@return Channel

	:::warning 
	If you rely on constantly creating and destroying channels, you should set the ``.SanityCheck`` property of the module to false to avoid potential overhead.
	:::

	:::note
	InstanceLogic Example:
	```lua
	local function InstanceLogic(Inst: Instance)
		if Inst.Size.X > 100 then -- this will never error due pcall so it is safe
			return true 
		end
	end
	```
	:::
	Creates a new channel.
]=]

--// Module Definitions

SmartRaycast.CreateChannel = Channel.new

SmartRaycast.DestroyChannel = DestroyChannel
SmartRaycast.GetChannelObject = GetChannelObject
SmartRaycast.Cast = Cast

return SmartRaycast
