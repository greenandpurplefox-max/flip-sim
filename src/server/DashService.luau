local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MovementConfig = require(ReplicatedStorage.Shared.MovementConfig)

local DashService = {}

local dashEvent: RemoteEvent
local lastDashTimes: { [Player]: number } = {}
local activeDashes: { [Player]: boolean } = {}

local function smoothstep(alpha: number): number
	alpha = math.clamp(alpha, 0, 1)
	return alpha * alpha * (3 - 2 * alpha)
end

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

	local attachment = root:FindFirstChild("RootRigAttachment") or root:FindFirstChild("RootAttachment") :: Attachment?
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "DashAttachment"
		attachment.Parent = root
	end

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "DashVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.MaxForce = MovementConfig.DASH_MAX_FORCE
	linearVelocity.VectorVelocity = dashDirection * MovementConfig.DASH_SPEED
	linearVelocity.Parent = root

	local startTime = os.clock()
	local dashConnection: RBXScriptConnection

	dashConnection = RunService.Heartbeat:Connect(function()
		if not root.Parent or not linearVelocity.Parent then
			if dashConnection then
				dashConnection:Disconnect()
			end
			activeDashes[player] = nil
			return
		end

		local elapsed = os.clock() - startTime
		if elapsed >= MovementConfig.DASH_DURATION then
			dashConnection:Disconnect()
			linearVelocity:Destroy()
			activeDashes[player] = nil
			return
		end

		local progress = elapsed / MovementConfig.DASH_DURATION
		local ease = 1 - smoothstep(progress)
		linearVelocity.VectorVelocity = dashDirection * MovementConfig.DASH_SPEED * ease
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
