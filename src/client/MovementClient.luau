local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Shared.MovementConfig)

local MovementClient = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local dashEvent: RemoteEvent
local lastDash = 0
local dashing = false
local shiftLockEnabled = false
local shiftLockConnection: RBXScriptConnection? = nil
local shiftLockCursor: ScreenGui? = nil
local defaultFov = 70

local DASH_ACTION = "FlipSimDash"
local SHIFT_LOCK_ACTION = "FlipSimShiftLock"

local CURSOR_COLOR = Color3.fromRGB(228, 198, 98)
local CURSOR_SHADOW = Color3.fromRGB(40, 28, 16)

local function createShiftLockCursor(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShiftLockCursor"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 100
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	local center = Instance.new("Frame")
	center.Name = "Center"
	center.AnchorPoint = Vector2.new(0.5, 0.5)
	center.Position = UDim2.fromScale(0.5, 0.5)
	center.Size = UDim2.fromOffset(26, 26)
	center.BackgroundTransparency = 1
	center.Parent = screenGui

	local function createLine(name: string, size: UDim2, position: UDim2)
		local shadow = Instance.new("Frame")
		shadow.Name = `{name}Shadow`
		shadow.Size = size
		shadow.Position = position + UDim2.fromOffset(1, 1)
		shadow.BackgroundColor3 = CURSOR_SHADOW
		shadow.BorderSizePixel = 0
		shadow.Parent = center

		local line = Instance.new("Frame")
		line.Name = name
		line.Size = size
		line.Position = position
		line.BackgroundColor3 = CURSOR_COLOR
		line.BorderSizePixel = 0
		line.Parent = center

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = line
	end

	createLine("Horizontal", UDim2.fromOffset(18, 2), UDim2.new(0.5, -9, 0.5, -1))
	createLine("Vertical", UDim2.fromOffset(2, 18), UDim2.new(0.5, -1, 0.5, -9))

	local dotShadow = Instance.new("Frame")
	dotShadow.Name = "DotShadow"
	dotShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	dotShadow.Position = UDim2.new(0.5, 1, 0.5, 1)
	dotShadow.Size = UDim2.fromOffset(4, 4)
	dotShadow.BackgroundColor3 = CURSOR_SHADOW
	dotShadow.BorderSizePixel = 0
	dotShadow.Parent = center

	local dot = Instance.new("Frame")
	dot.Name = "Dot"
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(4, 4)
	dot.BackgroundColor3 = CURSOR_COLOR
	dot.BorderSizePixel = 0
	dot.Parent = center

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = dot

	return screenGui
end

local function setCursorVisible(visible: boolean)
	if not shiftLockCursor then
		shiftLockCursor = createShiftLockCursor()
	end

	shiftLockCursor.Enabled = visible
	UserInputService.MouseIconEnabled = not visible
end

local function playDashEffects(character: Model, direction: Vector3)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local camera = workspace.CurrentCamera
	if camera then
		defaultFov = camera.FieldOfView
		TweenService:Create(camera, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FieldOfView = defaultFov + 8,
		}):Play()
		task.delay(MovementConfig.DASH_DURATION + 0.05, function()
			if camera.Parent then
				TweenService:Create(camera, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					FieldOfView = defaultFov,
				}):Play()
			end
		end)
	end

	local effects = Instance.new("Attachment")
	effects.Name = "DashEffects"
	effects.CFrame = CFrame.lookAt(Vector3.zero, direction)
	effects.Parent = root

	local burst = Instance.new("ParticleEmitter")
	burst.Name = "DashBurst"
	burst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	burst.Lifetime = NumberRange.new(0.15, 0.35)
	burst.Speed = NumberRange.new(14, 24)
	burst.SpreadAngle = Vector2.new(18, 18)
	burst.Rate = 0
	burst.LightEmission = 0.8
	burst.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 220, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 170, 255)),
	})
	burst.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9),
		NumberSequenceKeypoint.new(1, 0),
	})
	burst.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	burst.Parent = effects
	burst:Emit(28)

	local trail = Instance.new("ParticleEmitter")
	trail.Name = "DashTrail"
	trail.Texture = "rbxasset://textures/particles/smoke_main.dds"
	trail.Lifetime = NumberRange.new(0.2, 0.45)
	trail.Speed = NumberRange.new(6, 12)
	trail.SpreadAngle = Vector2.new(12, 12)
	trail.Rate = 80
	trail.LightEmission = 0.35
	trail.Color = ColorSequence.new(Color3.fromRGB(150, 190, 255))
	trail.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Parent = effects

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(150, 200, 255)
	light.Brightness = 2
	light.Range = 10
	light.Parent = root

	TweenService:Create(light, TweenInfo.new(MovementConfig.DASH_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Brightness = 0,
	}):Play()

	task.delay(MovementConfig.DASH_DURATION, function()
		trail.Enabled = false
	end)

	Debris:AddItem(effects, 0.6)
	Debris:AddItem(light, 0.6)
end

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

	local direction = getDashDirection(humanoid, root)
	lastDash = now
	dashing = true
	playDashEffects(character, direction)
	dashEvent:FireServer(direction)

	task.delay(MovementConfig.DASH_DURATION + 0.05, function()
		dashing = false
	end)
end

local function disableDefaultShiftLock()
	local playerScripts = player:FindFirstChild("PlayerScripts")
	if not playerScripts then
		return
	end

	local ok, playerModule = pcall(function()
		return require(playerScripts:WaitForChild("PlayerModule"))
	end)

	if ok and playerModule then
		local mouseLockController = playerModule:GetMouseLockController()
		if mouseLockController then
			mouseLockController.BoundKeys = {}
		end
	end
end

local function setShiftLockEnabled(enabled: boolean)
	shiftLockEnabled = enabled
	setCursorVisible(enabled)

	if shiftLockConnection then
		shiftLockConnection:Disconnect()
		shiftLockConnection = nil
	end

	if enabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		shiftLockConnection = RunService.RenderStepped:Connect(function()
			local character = player.Character
			if not character then
				return
			end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not humanoid or not root or humanoid.Health <= 0 then
				return
			end

			local camera = workspace.CurrentCamera
			if not camera then
				return
			end

			local lookVector = camera.CFrame.LookVector
			local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
			if flatLook.Magnitude > 0.001 then
				root.CFrame = CFrame.new(root.Position, root.Position + flatLook.Unit)
			end
		end)
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

local function toggleShiftLock()
	setShiftLockEnabled(not shiftLockEnabled)
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

function MovementClient.init()
	dashEvent = ReplicatedStorage:WaitForChild("Dash") :: RemoteEvent
	shiftLockCursor = createShiftLockCursor()

	local camera = workspace.CurrentCamera
	if camera then
		defaultFov = camera.FieldOfView
	end

	bindInputActions()

	task.spawn(function()
		player:WaitForChild("PlayerScripts")
		for _ = 1, 15 do
			disableDefaultShiftLock()
			task.wait(0.2)
		end
	end)

	player.CharacterAdded:Connect(function()
		setShiftLockEnabled(false)
		task.defer(disableDefaultShiftLock)
	end)
end

return MovementClient
