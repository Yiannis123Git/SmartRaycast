--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

--// Modules
local SmartRaycast = require(ReplicatedStorage.Packages.SmartRaycast)

-- Channel Creation

local Channel1 = SmartRaycast.CreateChannel(
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

print(SmartRaycast.Cast(game.Workspace.RayOrigin.CFrame.Position, Vector3.new(100, 0, 0), "TestChannel"))
print(Workspace:Raycast(game.Workspace.RayOrigin.CFrame.Position, Vector3.new(100, 0, 0), Channel1.RayParams))

local Channel2 = SmartRaycast.CreateChannel(
	"TestChannel2",
	{ game.Workspace.RayOrigin },
	{ game.Workspace },
	function(Inst: Instance)
		if Inst.Name == "PartToIgnore" then
			return true
		end
	end,
	Enum.RaycastFilterType.Exclude
)

print(SmartRaycast.Cast(game.Workspace.RayOrigin.CFrame.Position, Vector3.new(100, 0, 0), "TestChannel2"))
print(Workspace:Raycast(game.Workspace.RayOrigin.CFrame.Position, Vector3.new(100, 0, 0), Channel2.RayParams))
