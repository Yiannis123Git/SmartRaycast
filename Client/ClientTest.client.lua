--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

--// Modules
local SmartRaycast = require(ReplicatedStorage.Packages.SmartRaycast)

-- Channel Creation

local Channel = SmartRaycast.CreateChannel(
	"TestChannel",
	{ game.Workspace.RayOrigin },
	{ game.Workspace },
	function(Inst: Instance)
		if Inst.Name == "PartToIgnore" then
			return true
		end
	end,
	Enum.RaycastFilterType.Include
)

coroutine.wrap(function()
	task.wait(2)
	game.Workspace.PartToIgnore:Destroy()
end)()

while true do
	task.wait(0.5)
	print(Channel.RayParams.FilterDescendantsInstances)
end
