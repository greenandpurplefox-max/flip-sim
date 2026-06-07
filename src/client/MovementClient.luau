local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Shared.MovementConfig)

local MovementClient = {}

local player = Players.LocalPlayer
local dashEvent: RemoteEvent
local lastDash = 0
local dashing = false

local function getDashDirection(humanoid: Humanoid, root: BasePart): Vector3
	local moveDirection = humanoid.MoveDirection
	if moveDirection.Magnitude > 0.05 then
		return Vector3.new(moveDirection.X, 0, moveDirection.Z).Unit
	end

	local lookDirection = root.CFrame.LookVector
	local flatLook = Vector3.new(lookDirection.X, 0, lookDirection.Z)
	if flatLook.Magnitude > 0.05 then
		return flatLook.Unit
	end

	return Vector3.new(0, 0, -1)
end

local function requestDash()
	if dashing then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end

	local now = os.clock()
	if now - lastDash < MovementConfig.DASH_COOLDOWN then
		return
	end

	lastDash = now
	dashing = true
	dashEvent:FireServer(getDashDirection(humanoid, root))

	task.delay(MovementConfig.DASH_DURATION, function()
		dashing = false
	end)
end

local function bindShiftLockToCtrl()
	local playerScripts = player:WaitForChild("PlayerScripts")

	task.defer(function()
		local ok, playerModule = pcall(function()
			return require(playerScripts:WaitForChild("PlayerModule"))
		end)

		if not ok or not playerModule then
			return
		end

		local mouseLockController = playerModule:GetMouseLockController()
		if mouseLockController then
			mouseLockController.BoundKeys = { Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl }
		end
	end)
end

local function bindCharacter(_character: Model)
	bindShiftLockToCtrl()
end

function MovementClient.init()
	dashEvent = ReplicatedStorage:WaitForChild("Dash") :: RemoteEvent

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			requestDash()
		end
	end)

	bindShiftLockToCtrl()

	if player.Character then
		bindCharacter(player.Character)
	end

	player.CharacterAdded:Connect(bindCharacter)
end

return MovementClient
