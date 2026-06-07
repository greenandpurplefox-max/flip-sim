local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage.Shared.MovementConfig)

local DashService = {}

local dashEvent: RemoteEvent
local lastDashTimes: { [Player]: number } = {}
local activeDashes: { [Player]: boolean } = {}

local function flattenDirection(direction: Vector3): Vector3
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 0.05 then
		return Vector3.zero
	end
	return flat.Unit
end

local function applyDash(player: Player, direction: Vector3)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end

	local dashDirection = flattenDirection(direction)
	if dashDirection == Vector3.zero then
		dashDirection = flattenDirection(root.CFrame.LookVector)
	end
	if dashDirection == Vector3.zero then
		return
	end

	activeDashes[player] = true

	local velocity = dashDirection * MovementConfig.DASH_SPEED
	local currentVelocity = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(velocity.X, currentVelocity.Y, velocity.Z)

	task.delay(MovementConfig.DASH_DURATION, function()
		if root.Parent then
			local settledVelocity = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(0, settledVelocity.Y, 0)
		end
		activeDashes[player] = nil
	end)
end

local function onDashRequested(player: Player, direction: Vector3)
	if typeof(direction) ~= "Vector3" or activeDashes[player] then
		return
	end

	local now = os.clock()
	local lastDash = lastDashTimes[player] or 0
	if now - lastDash < MovementConfig.DASH_COOLDOWN then
		return
	end

	lastDashTimes[player] = now
	applyDash(player, direction)
end

function DashService.init()
	dashEvent = Instance.new("RemoteEvent")
	dashEvent.Name = "Dash"
	dashEvent.Parent = ReplicatedStorage

	dashEvent.OnServerEvent:Connect(onDashRequested)

	Players.PlayerRemoving:Connect(function(player)
		lastDashTimes[player] = nil
		activeDashes[player] = nil
	end)
end

return DashService
