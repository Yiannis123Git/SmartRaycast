# How to use SmartRaycast 

## What is a channel?

Imagine the channel object as your new [RaycastParams](https://create.roblox.com/docs/reference/engine/datatypes/RaycastParams). Each channel object corresponds to a RaycastParams instance. We can access these channels and use them to cast rays.

## Creating a channel

Creating a channel is very simple and works similarly to creating a normal [RaycastParams](https://create.roblox.com/docs/reference/engine/datatypes/RaycastParams) instance, the difference being a couple of extra arguments that define how the module should manage the RaycastParams filter.

### Arguments

#### ChannelName

The name of our channel. Channel names should be unique and can be used to access the channel after creating it.

#### Base

Instances represented in this array will be included in the FilterDescendantsInstances. You should add instances that you **know** should be part of the channel's  FilterDescendantsInstances. You can pass instances directly into the array or a string that represents a [collection service](https://create.roblox.com/docs/reference/engine/classes/CollectionService) tag. Passing a string that represents a [collection service](https://create.roblox.com/docs/reference/engine/classes/CollectionService) tag will add all current and future tagged instances to the channel's filter. You can always remove an instance/tag from the filter by using the [`RemoveFromFilter`](Channel.md#removefromfilter) channel method, including the ones referenced in the base array.

#### CanBeAdded

This should be a **lightweight** function that accepts a single instance as its sole argument and returns `true` if that instance should be included in the filter. The function must be error-proof. For an example of an `CanBeAdded` function, see the example below. This function is utilized during raycast operations to determine which instances to exclude. It will be applied to instances not found in the channel's filter. If no function is provided, only the channel's filter will be used.

!!! Info
    Due to technical and performance reasons, the `CanBeAdded` functionality can only be used with an exclude [RaycastParams.FilterType](https://create.roblox.com/docs/reference/engine/datatypes/RaycastParams#FilterType).

#### ...

The rest of the channel creation arguments are generic RaycastParams parameters that can be found in the corresponding [Roblox documentation](https://create.roblox.com/docs/reference/engine/datatypes/RaycastParams#properties).

### Example

```lua
local SmartRaycastModule = PathToModule.smartraycast -- Our SmartRaycast module 

local OurChannelName = "ExampleChannelName" -- Our Channel's name

-- We want to include characters in our channel's filter, so we specify game.Workspace.Characters.
-- This is a folder that contains various characters.
-- We also want to include instances tagged with the collection service tag 'CatsAndDogs'.
-- These instances will be present in our channel's filter.

local Base = {game.Workspace.Characters, "CatsAndDogs"} 

local function CanBeAdded(Inst: Instance): boolean
    if Inst.Transparency and Inst.Transparency > 0.8 then 
        return true -- Add this instance to the channel's filter
    end

    return false -- optional 
end

local OurNewlyCreatedChannel = SmartRaycastModule.CreateChannel(
    ChannelName,
    Base,
    CanBeAdded,
    Enum.RaycastFilterType.Exclude, 
    -- ...
)

```
## Modifying the Channel's filter
It should be noted that updates to the channel's filter are not pushed immediately but are applied at the "end" of every frame. If you need the updates to be applied immediately, you can force the filter to update via the [`ForceUpdateFilter`](Channel.md#forceupdatefilter) channel method.

### Adding to the Channel's filter

You can add new tags/instances via the [`AddToFilter`](Channel.md#addtofilter) channel method. You can pass instances directly or a string that represents a [Collection Service](https://create.roblox.com/docs/reference/engine/classes/CollectionService) tag to add it to the channel's filter. 

```lua 
-- Peform changes 

Channel:AddToFilter("Tag1")
Channel:AddToFilter("Tag2")
Channel:AddToFilter(game.Workspace.Folder)

-- Push changes without waiting on the module (If needed)

Channel:ForceUpdateFilter()
```

### Removing from a Channel's filter

You can remove added tags/instances via the [`RemoveFromFilter`](Channel.md#removefromfilter) channel method. You can pass instances directly or a string that represents a [Collection Service](https://create.roblox.com/docs/reference/engine/classes/CollectionService) tag to remove it from the channel's filter. 

```lua 
-- Peform changes 

Channel:RemoveFromFilter("Tag1")
Channel:RemoveFromFilter("Tag2")
Channel:RemoveFromFilter(game.Workspace.Folder)

-- Push changes without waiting on the module (If needed)

Channel:ForceUpdateFilter()
```


## Destroying a channel

After a channel is destroyed, it should no longer be used. 

```lua
Channel:Destroy()
```

## Casting a ray

This works almost identically to the standard [workspace:Raycast](https://create.roblox.com/docs/reference/engine/classes/WorldRoot#Raycast) API, but with a minor tweak. To cast a ray using the channel's filter, you need to call the [`Cast`](Channel.md#cast) Channel method. The first two arguments, Origin and Direction, are the same as those in the [Roblox API](https://create.roblox.com/docs/reference/engine/classes/WorldRoot#Raycast). The third optional argument specifies the [`WorldRoot`](https://create.roblox.com/docs/reference/engine/classes/WorldRoot) where the ray should be cast. If nil, the `workspace` will be used. Shape casting, Sphere casting, and Block casting are supported, with each having their cast method and corresponding arguments. For more information, refer to the [Channel API](Channel.md#methods).

!!! Info
    This method can be run in parallel.

```lua
local RaycastResult = Channel:Cast(Origin,Direction,game.Workspace) -- the third arg is optional
```

## Accessing channels

You can access a channel by getting it through the [`:GetChannel`](SmartRaycast.md#getchannel) module function.

!!! Info
    This functionality can be limited when using [actors](https://create.roblox.com/docs/reference/engine/classes/Actor)

```lua
local Channel = SmartRaycastModule.GetChannel("ExampleChannelName")

if Channel ~= nil then
   Channel:Cast(Origin,Direction)
end
```

