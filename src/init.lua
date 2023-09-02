--!strict

--//Services
local CollectionService = game:GetService("CollectionService")

--// Modules
local JanitorModule = require(script.Parent.Janitor)

--// Variables
local ChannelLog = {}
local CollectionServiceTag = "SRaycast"

--// Settings
local Warnings = true
local SanityCheck = true

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

type Channel = typeof(setmetatable({} :: ChannelProperties, Channel))

-- Return "ClassName" when tostring is called on Channel

function Channel.__tostring()
	return "SmartRaycast Channel"
end

--// Constructor

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

	if SanityCheck == true then
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
			local Success, Result = pcall(function()
				return InstanceLogic(Inst)
			end)

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
					local Success, Result = pcall(function()
						return InstanceLogic(Descendant)
					end)

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

function Channel:Destroy()
	if not ChannelLog[self._Name] then
		-- Channel has already been destroyed:

		if Warnings == true then
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
	local Replacement = self._MaintenanceCopy[self._FilterCounter]

	self._MaintenanceCopy[self._FilterCounter] = nil
	self._FilterCounter -= 1

	self._MaintenanceCopy[IndexToRemove :: number] = Replacement

	self.RayParams.FilterDescendantsInstances = self._MaintenanceCopy
end

--// Module Functions //--

--// Destroy Channel Module Alternative function

function DestroyChannel(WhatToDestroy: string | Channel)
	if IsChannel(WhatToDestroy) == true and typeof(WhatToDestroy) ~= "string" then
		-- WhatToDestroy is a channel:

		WhatToDestroy:Destroy()
	else
		assert(ChannelLog[WhatToDestroy], "[SmartRaycast] Cannot destroy channel because channel does not exist")

		ChannelLog[WhatToDestroy]:Destroy()
	end
end

--// Raycast Function

function Cast(Origin: Vector3, Direction: Vector3, ChannelName: string)
	assert(ChannelLog[ChannelName], "[SmartRaycast] No channel found with Name: " .. ChannelName)

	return workspace:Raycast(Origin, Direction, ChannelLog[ChannelName].RayParams)
end

--// Module Definitions

local SmartRaycast = {}

SmartRaycast.CreateChannel = Channel.new
SmartRaycast.DestroyChannel = DestroyChannel
SmartRaycast.Cast = Cast

return SmartRaycast
