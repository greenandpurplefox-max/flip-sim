local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Shared.MovementConfig)

local MovementClient = {}

local player = Players.LocalPlayer
local dashEvent: RemoteEvent
local lastDash = 0
local dashing = false
local mouseLockController: any = nil

local DASH_ACTION = "FlipSimDash"
local SHIFT_LOCK_ACTION = "FlipSimShiftLock"

local SHIFT_LOCK_KEYS = { Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl }

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

	task.delay(MovementConfig.DASH_DURATION + 0.05, function()
		dashing = false
	end)
end

local function toggleShiftLock()
	if mouseLockController then
		mouseLockController:OnMouseLockButtonPressed()
	end
end

local function onDashAction(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject)
	if inputState == Enum.UserInputState.Begin then
		requestDash()
	end
	return Enum.ContextActionResult.Sink
end

local function onShiftLockAction(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject)
	if inputState == Enum.UserInputState.Begin then
		toggleShiftLock()
	end
	return Enum.ContextActionResult.Sink
end

local function remapShiftLockOffShift()
	local playerScripts = player:WaitForChild("PlayerScripts")

	for _ = 1, 12 do
		local ok, playerModule = pcall(function()
			return require(playerScripts:WaitForChild("PlayerModule"))
		end)

		if ok and playerModule then
			local controller = playerModule:GetMouseLockController()
			if controller then
				mouseLockController = controller
				controller.BoundKeys = SHIFT_LOCK_KEYS
				return true
			end
		end

		task.wait(0.2)
	end

	return false
end

local function bindInputActions()
	ContextActionService:UnbindAction(DASH_ACTION)
	ContextActionService:UnbindAction(SHIFT_LOCK_ACTION)

	ContextActionService:BindActionAtPriority(
		DASH_ACTION,
		onDashAction,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.LeftShift,
		Enum.KeyCode.RightShift
	)

	ContextActionService:BindActionAtPriority(
		SHIFT_LOCK_ACTION,
		onShiftLockAction,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.LeftControl,
		Enum.KeyCode.RightControl
	)
end

local function setupShiftLockRemap()
	task.spawn(remapShiftLockOffShift)
end

function MovementClient.init()
	dashEvent = ReplicatedStorage:WaitForChild("Dash") :: RemoteEvent

	bindInputActions()
	setupShiftLockRemap()

	player.CharacterAdded:Connect(function()
		setupShiftLockRemap()
	end)

	-- Block the default Shift shift-lock binding if PlayerModule re-applies it.
	UserInputService.InputBegan:Connect(function(input, _gameProcessed)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			if mouseLockController and mouseLockController.BoundKeys then
				mouseLockController.BoundKeys = SHIFT_LOCK_KEYS
			end
		end
	end)
end

return MovementClient
