--!strict

--// Services
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--// Modules
local JanitorModule = require(script.Parent.Janitor)

--// Variables
local GCCycleInterval = 180
local Channels = {}

--// Channel Object //--

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

	for Key, Value in t do
		assert(
			typeof(Key) == "number" and (typeof(Value) == "Instance" or typeof(Value) == "string"),
			string.format(
				"[SmartRaycast] Invalid base table stracture expected {instance | string} got { [%*]: %*}",
				typeof(Key),
				typeof(Value)
			)
		)
	end
end

local Channel = {}
Channel.__index = Channel

type ChannelProperties = {
	_Name: string,
	_BaseArray: { Instance },
	_BaseMap: { [Instance]: number? },
	_CanBeAdded: ((any) -> boolean | nil)?,
	RaycastParams: RaycastParams,
	_BaseCounter: number,
	_GCCoroutine: thread,
	_Janitor: JanitorModule.Janitor,
}

export type Channel = typeof(setmetatable({} :: ChannelProperties, Channel))

function Channel.new(
	Name: string,
	Base: { string | Instance }?,
	CanBeAdded: ((any) -> boolean | nil)?,
	FilterType: Enum.RaycastFilterType?,
	IgnoreWater: boolean?,
	CollisionGroup: string?,
	RespectCanCollide: boolean?,
	BruteForceAllSlow: boolean?
)
	local self = setmetatable({} :: ChannelProperties, Channel)

	-- Sanity check

	TypeCheck(Name, "string")
	TypeCheck(Base, "table", true)
	TypeCheck(CanBeAdded, "function", true)
	TypeCheck(FilterType, "EnumItem", true)
	TypeCheck(IgnoreWater, "boolean", true)
	TypeCheck(CollisionGroup, "string", true)
	TypeCheck(RespectCanCollide, "boolean", true)
	TypeCheck(BruteForceAllSlow, "boolean", true)

	TableMemberCheck(Base)

	assert(Channels[Name] == nil, "[SmartRaycast] A channel with this name already exist: " .. Name)

	-- Set Name

	self._Name = Name

	-- Create channel's RaycastParams

	self.RaycastParams = RaycastParams.new()

	-- Set the channel's RaycastParams Properties

	local RaycastParams = self.RaycastParams

	RaycastParams.FilterType = FilterType or Enum.RaycastFilterType.Exclude
	RaycastParams.IgnoreWater = IgnoreWater or false
	RaycastParams.CollisionGroup = CollisionGroup or "Default"
	RaycastParams.RespectCanCollide = RespectCanCollide or false
	RaycastParams.BruteForceAllSlow = BruteForceAllSlow or false

	-- Set the channel's CanBeAdded function

	self._CanBeAdded = CanBeAdded

	-- Create channel's main Janitor

	self._Janitor = JanitorModule.new()

	-- Handle provided Base

	self._BaseArray = {}
	self._BaseMap = {}
	self._BaseCounter = 0

	if Base then
		for _, Value in Base do
			self:AddToFilter(Value)
		end
	end

	-- Connect FDI update event
	-- This updates our base filter and resets the "cache" caused by our raycast operations

	RunService:BindToRenderStep("SmartRaycast: " .. Name, 0, function()
		RaycastParams.FilterDescendantsInstances = self._BaseArray
	end)

	-- Update FDI on channel creation

	RaycastParams.FilterDescendantsInstances = self._BaseArray

	-- Create Garbage collection coroutine

	self._GCCoroutine = coroutine.create(function()
		while true do
			wait(GCCycleInterval)

			local RemovalQueue = {}
			local c = 0

			for _, Inst in self._BaseArray do
				if Inst:FindFirstAncestorOfClass("DataModel") == nil then
					c += 1
					RemovalQueue[c] = Inst
				end
			end

			for _, Inst in RemovalQueue do
				self:_RemoveFromBase(Inst)
			end
		end
	end)

	coroutine.resume(self._GCCoroutine)

	-- Add new channel to the Channels table

	Channels[Name] = self

	return self
end

function Channel.Destroy(self: Channel)
	coroutine.close(self._GCCoroutine)
	self._Janitor:Destroy()
	RunService:UnbindFromRenderStep("SmartRaycast: " .. self._Name)
	Channels[self._Name] = nil
end

-- Public Method for adding tags/instances to the filter
-- If an already present instance is passed the events will be just overwriten, no duplicates will be added

function Channel.AddToFilter(self: Channel, ToAdd: Instance | string)
	if typeof(ToAdd) == "Instance" then
		-- Instance was provided:

		self:_AppendToBase(ToAdd)
	else
		-- collection service tag was provided:

		local InstancesToAdd = CollectionService:GetTagged(ToAdd)

		for _, Inst in InstancesToAdd do
			self:_AppendToBase(Inst)
		end

		self._Janitor:Add(
			CollectionService:GetInstanceAddedSignal(ToAdd):Connect(function(Inst: Instance)
				self:_AppendToBase(Inst)
			end),
			"Disconnect",
			ToAdd .. "Added"
		)

		self._Janitor:Add(
			CollectionService:GetInstanceRemovedSignal(ToAdd):Connect(function(Inst: Instance)
				self:_RemoveFromBase(Inst)
			end),
			"Disconnect",
			ToAdd .. "Removed"
		)
	end
end

function Channel.RemoveFromFilter(self: Channel, ToRemove: Instance | string)
	if typeof(ToRemove) == "Instance" then
		-- Instance was provided:

		self:_RemoveFromBase(ToRemove)
	else
		-- Collection service tag was provided:

		self._Janitor:Remove(ToRemove .. "Added")
		self._Janitor:Remove(ToRemove .. "Removed")

		local InstancesToRemove = CollectionService:GetTagged(ToRemove)

		for _, Inst in InstancesToRemove do
			self:_RemoveFromBase(Inst)
		end
	end
end

-- Adds an instance to the base array and map
-- Protects from duplicates

function Channel._AppendToBase(self: Channel, Inst: Instance)
	if self._BaseMap[Inst] == nil then
		self._BaseCounter += 1
		self._BaseArray[self._BaseCounter] = Inst
		self._BaseMap[Inst] = self._BaseCounter
	end
end

-- Removes an instance from the base array and map
-- Protects from removing non-existing instances

function Channel._RemoveFromBase(self: Channel, Inst: Instance)
	local IndexToRemove = self._BaseMap[Inst]
	local LastInstance = self._BaseArray[self._BaseCounter]

	if IndexToRemove then
		if IndexToRemove == self._BaseCounter then
			self._BaseMap[Inst] = nil
			self._BaseArray[self._BaseCounter] = nil
			self._BaseCounter -= 1
		else
			self._BaseMap[Inst] = nil
			self._BaseArray[IndexToRemove] = LastInstance
			self._BaseMap[LastInstance] = IndexToRemove
			self._BaseArray[self._BaseCounter] = nil
			self._BaseCounter -= 1
		end
	end
end

function Channel.ForceUpdateFilter(self: Channel)
	self.RaycastParams.FilterDescendantsInstances = self._BaseArray
end

function Channel.Cast(self: Channel, Origin: Vector3, Direction: Vector3, WorldRoot: WorldRoot?): RaycastResult?
	return self:_RaycastOperation("Raycast", WorldRoot, Origin, Direction)
end

function Channel.Blockcast(
	self: Channel,
	BlockOrigin: CFrame,
	Size: Vector3,
	Direction: Vector3,
	WorldRoot: WorldRoot?
): RaycastResult?
	return self:_RaycastOperation("Blockcast", WorldRoot, BlockOrigin, Size, Direction)
end

function Channel.Spherecast(
	self: Channel,
	Origin: Vector3,
	Radius: number,
	Direction: Vector3,
	WorldRoot: WorldRoot?
): RaycastResult?
	return self:_RaycastOperation("Spherecast", WorldRoot, Origin, Radius, Direction)
end

function Channel.Shapecast(self: Channel, Part: BasePart, Direction: Vector3, WorldRoot: WorldRoot): RaycastResult?
	return self:_RaycastOperation("Shapecast", WorldRoot, Part, Direction)
end

function Channel._RaycastOperation(self: Channel, CastToBeUsed: string, WorldRoot: WorldRoot?, ...)
	WorldRoot = WorldRoot or Workspace

	local RayParams = self.RaycastParams
	local ExcludeCast = RayParams.FilterType == Enum.RaycastFilterType.Exclude
	local CastRay = (WorldRoot :: WorldRoot)[CastToBeUsed] -- Don't think this will causes any issues

	local Args = { ... }
	Args[#Args + 1] = RayParams

	if self._CanBeAdded == nil or ExcludeCast == false then
		return CastRay(WorldRoot, table.unpack(Args))
	end

	local CanBeAdded = self._CanBeAdded
	local RaycastResult
	local Result

	repeat
		RaycastResult = CastRay(WorldRoot, table.unpack(Args))

		if RaycastResult then
			Result = CanBeAdded(RaycastResult.Instance)

			if Result ~= true then
				break
			else
				RayParams:AddToFilter(RaycastResult.Instance) -- Add to "cache"
			end
		end

	until RaycastResult :: RaycastResult? == nil

	return RaycastResult
end

--// Module functions //--

-- Returns a channel object by name that is within the module scope

function GetChannel(ChannelName: string): Channel?
	return Channels[ChannelName]
end

--// Module definitions //--

local SmartRaycast = {}

SmartRaycast.GCCycleInterval = GCCycleInterval

SmartRaycast.CreateChannel = Channel.new
SmartRaycast.GetChannel = GetChannel

return SmartRaycast
