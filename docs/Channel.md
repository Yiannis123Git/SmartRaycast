# Channel
This section refers to the channel object.

## Properties
!!! warning
    Any property that starts with the character `_` is not meant to be changed

------

### RayParams

_Channel.RayParams: <span style="color: teal;">[RaycastParams](https://create.roblox.com/docs/reference/engine/datatypes/RaycastParams)</span>_  
  
RaycastParams tied to the Channel. All properties of the RaycastParams can be changed in runtime **excluding FilterDescendantsInstances**

## Methods 

!!! warning
    Any method that starts with the character `_` is not meant to be called. 

----

### Cast
  
_Channel:Cast(Origin: <span style="color: teal;">[Vector3](https://create.roblox.com/docs/reference/engine/datatypes/Vector3)</span>, Direction: <span style="color: teal;">[Vector3](https://create.roblox.com/docs/reference/engine/datatypes/Vector3)</span>, WorldRoot: <span style="color: teal;">[WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot)</span>?): <span style="color: teal;">[RaycastResult](https://create.roblox.com/docs/reference/engine/datatypes/RaycastResult)</span>?_
  
Casts a ray with the given origin and direction at the specified [WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot) using the Channel's filter. If no [WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot) is provided, then `Workspace` will be used instead.

!!! Info
    This method can be run in parallel.

### Blockcast
  
_Channel:Blockcast(BlockOrigin: <span style="color: teal;">[CFrame](https://create.roblox.com/docs/reference/engine/datatypes/CFrame)</span>, Size: <span style="color: teal;">[Vector3](https://create.roblox.com/docs/reference/engine/datatypes/Vector3)</span>, Direction: <span style="color: teal;">[Vector3](https://create.roblox.com/docs/reference/engine/datatypes/Vector3)</span>, WorldRoot: <span style="color: teal;">[WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot)</span>?): <span style="color: teal;">[RaycastResult](https://create.roblox.com/docs/reference/engine/datatypes/RaycastResult)</span>?_ 

Casts a block shape in a given direction at the specified [WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot) using the Channel's filter.  If no [WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot) is provided, then `Workspace` will be used instead. For more info on how Blockcasts work visit [this page](https://create.roblox.com/docs/reference/engine/classes/WorldRoot#Blockcast)


!!! Info
    This method can be run in parallel.

### Spherecast   
  
_Channel:Spherecast(Origin: <span style="color: teal;">[Vector3](https://create.roblox.com/docs/reference/engine/datatypes/Vector3)</span>, Radius: <span style="color: teal;">number</span>, Direction: <span style="color: teal;">[Vector3](https://create.roblox.com/docs/reference/engine/datatypes/Vector3)</span>, WorldRoot: <span style="color: teal;">[WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot)</span>?): <span style="color: teal;">[RaycastResult](https://create.roblox.com/docs/reference/engine/datatypes/RaycastResult)</span>?_   
  
Casts a spherical shape in a given direction at the specified [WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot) using the Channel's filter.  If no [WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot) is provided, then `Workspace` will be used instead. For more info on how Spherecasts work visit [this page](https://create.roblox.com/docs/reference/engine/classes/WorldRoot#Spherecast)

!!! Info
    This method can be run in parallel.

### Shapecast
  
_Channel:Shapecast(Part: <span style="color: teal;">[BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart)</span>, Direction: <span style="color: teal;">[Vector3](https://create.roblox.com/docs/reference/engine/datatypes/Vector3)</span>, WorldRoot: <span style="color: teal;">[WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot)</span>?): <span style="color: teal;">[RaycastResult](https://create.roblox.com/docs/reference/engine/datatypes/RaycastResult)</span>?_  
  
Casts the 3D shape in a given direction at the specified [WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot) using the Channel's filter.  If no [WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot) is provided, then `Workspace` will be used instead. For more info on how Shapecasts work visit [this page](https://devforum.roblox.com/t/introducing-shapecasts/2320655)

!!! Info
    This method can be run in parallel.

### Destroy

_Channel:Destroy()_ 

Destroys a channel by cleaning up references and disconnecting events. After `:Destroy` is called, the corresponding FilterDescendantsInstances will no longer be actively maintained and the channel should no longer be used.

### AddToFilter

_Channel:AddToFilter(ToAdd: <span style="color: teal;">[Instance](https://create.roblox.com/docs/reference/engine/datatypes/Instance)</span> | <span style="color: teal;">string</span> )_
  
Adds an instance or [collection service](https://create.roblox.com/docs/reference/engine/classes/CollectionService) tag to the FilterDescendantsInstances. This method protects you from adding duplicate entries.

!!! Info
    This method can be run in parallel when adding instances.


### RemoveFromFilter

_Channel:RemoveFromFilter(ToRemove: <span style="color: teal;">[Instance](https://create.roblox.com/docs/reference/engine/datatypes/Instance)</span> | <span style="color: teal;">string</span> )_
  
Removes an Instance or [collection service](https://create.roblox.com/docs/reference/engine/classes/CollectionService) tag from the FilterDescendantsInstances. This method will not error if you try to remove a tag/instance that does not exist.

!!! Info
    This method can be run in parallel when removing instances.

### ForceUpdateFilter

_Channel:ForceUpdateFilter()_

Forcefully updates the Channel's filter instead of waiting for the next module update at the "end" of a frame.

