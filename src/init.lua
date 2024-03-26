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
			typeof(Key) == "number" and (typeof(Value) == "Instance" or typeof(Value) == "string"),
			"[SmartRaycast] Invalid table stracture expected {instance | string}"
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
	_ChannelTag: string,
	_HookedInstancesChannelTag: string,
	_MaintenanceCopy: { Instance },
	_FilterCounter: number,
}

export type Channel = typeof(setmetatable({} :: ChannelProperties, Channel))

-- Return "ClassName" when tostring is called on Channel

function Channel.__tostring()
	return "SmartRaycast Channel"
end

--// Constructor

function Channel.new(
	ChannelName: string,
	BaseArray: { Instance | string }?,
	InstancesToCheck: { Instance | string }?,
	InstanceLogic: ((any) -> boolean | nil)?,
	AccountForRuntimeChanges: boolean?,
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
		TypeCheck(AccountForRuntimeChanges, "boolean", true)
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

		if InstancesToCheck then
			for _, Value in InstancesToCheck do
				if typeof(Value) == "Instance" then
					for _, v in InstancesToCheck do
						if typeof(v) == "Instance" and v ~= Value and Value:IsDescendantOf(v) then
							error(
								"[SmartRaycast] InstancesToCheck cannot contain instances that are descendants of other instances in the array"
							)
						end
					end
				end
			end
		end
	end

	-- Set Channel name

	self._Name = ChannelName

	-- Set Channel Tag

	self._ChannelTag = self._Name .. CollectionServiceTag

	-- Set .Changed Channel Tag

	self._HookedInstancesChannelTag = self._Name .. "HookedInstances" .. CollectionServiceTag

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

	for Key, Value in RayParamProperties do
		self.RayParams[Key] = Value -- Ingnore this warning, just a clean way of setting the properties of RayParams
	end

	-- Create janitor instance

	self._Janitor = JanitorModule.new()

	-- Define Collection service tag arrays (Used during checks that determine if a tag can be removed from an instance)

	local CollectionServiceTags = {}

	local InstancesToCheckTags = {}

	-- Define MaintenanceCopy

	local MaintenanceCopy = {}

	-- Define FilterCounter

	self._FilterCounter = 0

	-- Connect GetInstanceRemovedSignal to channel tag

	self._Janitor:Add(
		CollectionService:GetInstanceRemovedSignal(self._ChannelTag):Connect(function(Inst: Instance)
			self:_RemoveFromFDI(Inst)
		end),
		"Disconnect"
	)

	-- Connect GetInstanceRemovedSignal to hooked instances channel tag

	self._Janitor:Add(
		CollectionService:GetInstanceRemovedSignal(self._HookedInstancesChannelTag):Connect(function(Inst: Instance)
			self._Janitor:Remove(Inst)
		end),
		"Disconnect"
	)

	-- Handle BaseArray

	if BaseArray then
		for _, Value in BaseArray do
			if typeof(Value) == "Instance" then
				-- User provided an instance:

				MaintenanceCopy[#MaintenanceCopy + 1] = Value
			else
				-- User provided a collection service tag:

				local Instances = CollectionService:GetTagged(Value)

				for _, Inst in Instances do
					MaintenanceCopy[#MaintenanceCopy + 1] = Inst
				end

				self._Janitor:Add(
					CollectionService:GetInstanceAddedSignal(Value):Connect(function(Inst: Instance)
						self:AppendToFDI(Inst)
					end),
					"Disconnect"
				)

				-- Add tag to CollectionServiceTags

				CollectionServiceTags[#CollectionServiceTags + 1] = Value
			end
		end

		-- Update FilterCounter

		self._FilterCounter = #MaintenanceCopy
	end

	-- Set FilterDescendantsInstances to MaintenanceCopy

	self._MaintenanceCopy = MaintenanceCopy
	self.RayParams.FilterDescendantsInstances = MaintenanceCopy

	-- Handle InstancesToCheck

	if InstancesToCheck ~= nil and InstanceLogic ~= nil then
		local function CanBeRemoved(Inst: Instance): boolean
			for _, Tag in CollectionServiceTags do
				if Inst:HasTag(Tag) then
					return false
				end
			end

			return true
		end

		local function CanBeUnhooked(Inst: Instance): boolean
			for _, Tag in InstancesToCheckTags do
				if Inst:HasTag(Tag :: string) then
					return false
				end
			end
			return true
		end

		local function HookForChanges(Inst)
			if AccountForRuntimeChanges then
				self._Janitor:Add(
					Inst.Changed:Connect(function()
						local _Success, Result = pcall(InstanceLogic, Inst)

						if Result == true and Inst:HasTag(self._ChannelTag) == false then
							self:AppendToFDI(Inst)
						elseif Result ~= true and Inst:HasTag(self._ChannelTag) == true then
							Inst:RemoveTag(self._ChannelTag) -- Automatically removes from FilterDescendantsInstances
						end
					end),
					"Disconnect",
					Inst -- This also makes it so duplicate hooks cannot occur on the same instance
				)

				Inst:AddTag(self._HookedInstancesChannelTag)
			end
		end

		local function RecursiveLogic(Inst: Instance)
			local _Success, Result = pcall(InstanceLogic, Inst)

			if Result == true then
				self:AppendToFDI(Inst)
			end

			HookForChanges(Inst)

			local InstanceChildren = Inst:GetChildren()

			for _, Child in InstanceChildren do
				RecursiveLogic(Child)
			end
		end

		for _, Value in pairs(InstancesToCheck) do
			if typeof(Value) == "Instance" then
				-- User provided an instance:

				RecursiveLogic(Value)

				self._Janitor:Add(
					Value.DescendantAdded:Connect(function(Descendant)
						local _Success, Result = pcall(InstanceLogic, Descendant)

						if Result == true then
							self:AppendToFDI(Descendant)
						end

						HookForChanges(Descendant)
					end),
					"Disconnect"
				)

				self._Janitor:Add(
					Value.DescendantRemoving:Connect(function(Descendant)
						if Descendant:HasTag(self._ChannelTag) and CanBeRemoved(Descendant) then
							Descendant:RemoveTag(self._ChannelTag) -- Automatically removes from filter
						end

						if Descendant:HasTag(self._HookedInstancesChannelTag) and CanBeUnhooked(Descendant) then
							Descendant:RemoveTag(self._HookedInstancesChannelTag)
						end
					end),
					"Disconnect"
				)
			else
				-- User provided a collection service tag:

				local Instances = CollectionService:GetTagged(Value)

				for _, Inst in Instances do
					local _Success, Result = pcall(InstanceLogic, Inst)

					if Result == true then
						self:AppendToFDI(Inst)
					end

					HookForChanges(Inst)
				end

				self._Janitor:Add(
					CollectionService:GetInstanceAddedSignal(Value):Connect(function(Inst: Instance)
						local _Success, Result = pcall(InstanceLogic, Inst)

						if Result == true then
							self:AppendToFDI(Inst)
						end

						HookForChanges(Inst)
					end),
					"Disconnect"
				)

				-- Add tag to the appropriate arrays

				CollectionServiceTags[#CollectionServiceTags + 1] = Value
				InstancesToCheckTags[#InstancesToCheckTags + 1] = Value
			end
		end
	end

	-- Add newly created Channel to ChannelLog table

	ChannelLog[self._Name] = self

	return self
end

--// Destroy Method

--[=[
	Destroys a channel by cleaning up references and disconnecting events. After ``:Destroy`` is called, the corresponding FilterDescendantsInstances will no longer be actively maintained and the channel's methods should no longer be used.
]=]
function Channel:Destroy()
	if not ChannelLog[self._Name] then
		-- Channel has already been destroyed:

		if SmartRaycast.Warnings == true then
			warn("[SmartRaycast] Called destroy method on channel that has already been destroyed. Memory leak?")
		end

		return
	end

	-- Destroy Janitor (we need to do this before removing tags from instances to avoid event spam)

	self._Janitor:Destroy()

	-- Remove SmartRaycast Tags from all tagged objects

	local TaggedObjects = CollectionService:GetTagged(self._ChannelTag)

	for _, Inst in pairs(TaggedObjects) do
		CollectionService:RemoveTag(Inst, self._ChannelTag)
	end

	TaggedObjects = CollectionService:GetTagged(self._HookedInstancesChannelTag)

	for _, Inst in pairs(TaggedObjects) do
		CollectionService:RemoveTag(Inst, self._HookedInstancesChannelTag)
	end

	-- Remove destroyed channel from ChannelLog table

	ChannelLog[self.Name] = nil
end

--[=[
	@param Inst Instance -- The Instance to be added to FilterDescendantsInstances

	Adds an instance to FilterDescendantsInstances.
]=]
function Channel:AppendToFDI(Inst: Instance)
	self._FilterCounter += 1
	self._MaintenanceCopy[self._FilterCounter] = Inst
	self.RayParams:AddToFilter({ Inst })

	CollectionService:AddTag(Inst, self._ChannelTag)
end

function Channel:_RemoveFromFDI(Inst: Instance)
	local IndexToRemove = table.find(self._MaintenanceCopy, Inst)
	self._MaintenanceCopy[IndexToRemove :: number] = self._MaintenanceCopy[self._FilterCounter]
	self._MaintenanceCopy[self._FilterCounter] = nil
	self._FilterCounter -= 1
	self.RayParams.FilterDescendantsInstances = self._MaintenanceCopy
end
--[=[
	@param Inst Instance -- The Instance to be removed from FilterDescendantsInstances

	Removes an Instance from FilterDescendantsInstances.

	:::warning 
	Do not use ``_RemoveFromFDI`` instead of ``RemoveFromFDI``. ``RemoveFromFDI`` should be used to manualy remove instances, ``_RemoveFromFDI`` should never be used and is only used internally.
	:::
]=]
function Channel:RemoveFromFDI(Inst: Instance)
	-- Check if Instance has already been automaticly removed

	local Exists = Inst:HasTag(self._ChannelTag)

	if Exists then
		-- Remove Tag from instance (triggers removal)

		CollectionService:RemoveTag(Inst, self._ChannelTag)
	end
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
	@param BaseArray { Instance | string }? -- Instances/Collection Service tags that will always remain present in the FilterDescendantsInstances Array.
	@param InstancesToCheck { Instance | string }? -- Instances/Collection Service tags, that will be checked in runtime using the 'InstanceLogic' function.
	@param InstanceLogic ((any) -> boolean | nil)? -- A function that should recieve an instance and return true if the instance should be added in the channel's filter.
	@param FilterType Enum.RaycastFilterType?
	@param IgnoreWater boolean?
	@param CollisionGroup string?
	@param RespectCanCollide boolean?
	@param BruteForceAllSlow boolean?
	@return Channel

	:::info  
	For more information, please refer to the 'How to Use' section in the Docs, specifically the 'Creating a Channel' part.
	:::

	Creates a new channel.
]=]

--// Module Definitions

SmartRaycast.CreateChannel = Channel.new

SmartRaycast.DestroyChannel = DestroyChannel
SmartRaycast.GetChannelObject = GetChannelObject
SmartRaycast.Cast = Cast

return SmartRaycast
