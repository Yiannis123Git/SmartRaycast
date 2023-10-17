"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[317],{60904:e=>{e.exports=JSON.parse('{"functions":[{"name":"new","desc":":::info\\nThis is the same function as the ``CreateChannel`` module function \\n:::\\n\\n\\nCreates a new Channel","params":[{"name":"ChannelName","desc":"Name of the channel that will be created.","lua_type":"string"},{"name":"BaseArray","desc":"Instances that will always remain present in the FilterDescendantsInstances Array.","lua_type":"{ Instance }?"},{"name":"InstancesToCheck","desc":"Instances that will have their Descendants checked in runtime using the \'InstanceLogic\' function.","lua_type":"{ Instance }?"},{"name":"InstanceLogic","desc":"A function that should recieve an instance and return true if the instance should be added in the FilterDescendantsInstances Array. This function is run in protected call so you don\'t need to worry about any errors.","lua_type":"((any) -> boolean | nil)?"},{"name":"FilterType","desc":"","lua_type":"Enum.RaycastFilterType?"},{"name":"IgnoreWater","desc":"","lua_type":"boolean?"},{"name":"CollisionGroup","desc":"","lua_type":"string?"},{"name":"RespectCanCollide","desc":"","lua_type":"boolean?"},{"name":"BruteForceAllSlow","desc":"","lua_type":"boolean?"}],"returns":[{"desc":"","lua_type":"Channel"}],"function_type":"static","source":{"line":161,"path":"src/init.lua"}},{"name":"Destroy","desc":"Destroys a channel by cleaning up references and disconnecting events. After ``:Destroy`` is called, the corresponding FilterDescendantsInstances will no longer be actively maintained and the channel\'s methods should no longer be used.","params":[],"returns":[],"function_type":"method","source":{"line":316,"path":"src/init.lua"}},{"name":"AppendToFDI","desc":"Adds an instance to FilterDescendantsInstances.","params":[{"name":"Inst","desc":"The Instance to be added to FilterDescendantsInstances","lua_type":"Instance"}],"returns":[],"function_type":"method","source":{"line":351,"path":"src/init.lua"}},{"name":"RemoveFromFDI","desc":"Removes an Instance from FilterDescendantsInstances.\\n\\n:::warning \\nDo not use ``_RemoveFromFDI`` instead of ``RemoveFromFDI``. ``RemoveFromFDI`` should be used to manualy remove instances, ``_RemoveFromFDI`` should never be used and is only used internally.\\n:::","params":[{"name":"Inst","desc":"The Instance to be removed from FilterDescendantsInstances","lua_type":"Instance"}],"returns":[],"function_type":"method","source":{"line":375,"path":"src/init.lua"}}],"properties":[{"name":"_Name","desc":"Name used to identify channels internaly.","lua_type":"string","readonly":true,"source":{"line":81,"path":"src/init.lua"}},{"name":"RayParams","desc":"RaycastParams tied to the Channel. All properties of the RaycastParams can be changed in runtime **excluding FilterDescendantsInstances**","lua_type":"RaycastParams","source":{"line":88,"path":"src/init.lua"}},{"name":"_Janitor","desc":"[Janitor](https://github.com/howmanysmall/Janitor) Object used for cleanup.","lua_type":"Janitor","readonly":true,"source":{"line":96,"path":"src/init.lua"}},{"name":"_ChannelTag","desc":"Collection Service Tag used to tag instances associated with the Channel.","lua_type":"string?","readonly":true,"source":{"line":104,"path":"src/init.lua"}},{"name":"_MaintenanceCopy","desc":"A copy of FilterDescendantsInstances used to maintain the actual FilterDescendantsInstances.","lua_type":"{ Instance? }","readonly":true,"source":{"line":112,"path":"src/init.lua"}},{"name":"_FilterCounter","desc":"Keeps track of the number of instances in FilterDescendantsInstances.","lua_type":"number","readonly":true,"source":{"line":120,"path":"src/init.lua"}}],"types":[],"name":"Channel","desc":"A set of RayParams ties to this object. Think of this object as your new RaycastParams.","source":{"line":73,"path":"src/init.lua"}}')}}]);