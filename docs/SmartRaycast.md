# SmartRaycast
This section refers to the module itself.

## Properties

------

### GCCycleInterval

_SmartRaycast.GCCycleInterval: <span style="color: teal;">number</span>_  
  
How often the module cleans filter references to removed instances.

## Functions

-------

### CreateChannel

_SmartRaycast.CreateChannel(ChannelName: <span style="color: teal;">string</span>, BaseArray: {<span style="color: teal;">Instance</span> | <span style="color: teal;">string</span>}?, CanBeAdded: ((<span style="color: teal;">Instance</span>) → <span style="color: teal;">boolean</span> | <span style="color: teal;">nil</span>)?, FilterType: <span style="color: teal;">Enum.RaycastFilterType</span>?, IgnoreWater: <span style="color: teal;">boolean</span>?, CollisionGroup: <span style="color: teal;">string</span>?, RespectCanCollide: <span style="color: teal;">boolean</span>?, BruteForceAllSlow: <span style="color: teal;">boolean</span>?): <span style="color: teal;">[Channel](Channel.md)</span>_
  
Creates a new channel object.

!!! info
    For more information, please refer to the '[How to Use](HowToUse.md)' section in the Docs, specifically the '[Creating a Channel](HowToUse.md#creating-a-channel)' part.


### GetChannel
_SmartRaycast.GetChannel(ChannelName: <span style="color: teal;">string</span>): <span style="color: teal;">[Channel](Channel.md)</span>?_

You can use this function to get a Channel Object by providing the name of the Channel, if the Channel does not exist then nil will be returned.

!!! Info
    This functionality can be limited when using [actors](https://create.roblox.com/docs/reference/engine/classes/Actor)




