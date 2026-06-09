local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local TreasureChestPreview = require(script.Parent.TreasureChestPreview)

local TreasureChestClient = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GOLD = Color3.fromRGB(228, 188, 84)
local GOLD_BRIGHT = Color3.fromRGB(255, 228, 140)
local SHADOW = Color3.fromRGB(8, 4, 10)
local REQUIRED_TAPS = 3

local screenGui: ScreenGui
local backdrop: Frame
local container: Frame
local goldLabel: TextLabel
local tapHintLabel: TextLabel
local viewportHost: Frame
local activeToken = 0

local function smoothstep(alpha: number): number
	alpha = math.clamp(alpha, 0, 1)
	return alpha * alpha * (3 - 2 * alpha)
end

local function ensureUI()
	if screenGui then
		return
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TreasureChestOpenUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 20
	screenGui.Enabled = true
	screenGui.Parent = playerGui

	backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.42
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.Visible = false
	backdrop.ZIndex = 1
	backdrop.Parent = screenGui

	container = Instance.new("Frame")
	container.Name = "ChestOpenContainer"
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.Size = UDim2.fromOffset(620, 540)
	container.Visible = false
	container.ZIndex = 2
	container.Parent = screenGui

	goldLabel = Instance.new("TextLabel")
	goldLabel.Name = "GoldReward"
	goldLabel.AnchorPoint = Vector2.new(0.5, 0)
	goldLabel.BackgroundTransparency = 1
	goldLabel.Position = UDim2.new(0.5, 0, 0, 0)
	goldLabel.Size = UDim2.fromOffset(360, 52)
	goldLabel.Font = Enum.Font.Antique
	goldLabel.Text = ""
	goldLabel.TextColor3 = GOLD_BRIGHT
	goldLabel.TextSize = 38
	goldLabel.TextStrokeColor3 = SHADOW
	goldLabel.TextStrokeTransparency = 0.1
	goldLabel.TextTransparency = 1
	goldLabel.ZIndex = 4
	goldLabel.Parent = container

	tapHintLabel = Instance.new("TextLabel")
	tapHintLabel.Name = "TapHint"
	tapHintLabel.AnchorPoint = Vector2.new(0.5, 1)
	tapHintLabel.BackgroundTransparency = 1
	tapHintLabel.Position = UDim2.new(0.5, 0, 1, -4)
	tapHintLabel.Size = UDim2.fromOffset(420, 36)
	tapHintLabel.Font = Enum.Font.Antique
	tapHintLabel.Text = "Tap the chest to open!"
	tapHintLabel.TextColor3 = GOLD
	tapHintLabel.TextSize = 24
	tapHintLabel.TextStrokeColor3 = SHADOW
	tapHintLabel.TextStrokeTransparency = 0.15
	tapHintLabel.ZIndex = 4
	tapHintLabel.Parent = container

	viewportHost = Instance.new("Frame")
	viewportHost.Name = "ViewportHost"
	viewportHost.BackgroundTransparency = 1
	viewportHost.Position = UDim2.fromOffset(0, 58)
	viewportHost.Size = UDim2.new(1, 0, 1, -108)
	viewportHost.ClipsDescendants = false
	viewportHost.Parent = container
end

local function spawnGoldBurst(parent: Instance, tierGlow: Color3)
	local origin = UDim2.new(0.5, 0, 0.58, 0)
	for index = 1, 18 do
		local coin = Instance.new("Frame")
		coin.Name = `GoldCoin_{index}`
		coin.AnchorPoint = Vector2.new(0.5, 0.5)
		coin.BackgroundColor3 = if index % 3 == 0 then tierGlow else GOLD
		coin.BorderSizePixel = 0
		coin.Position = origin
		coin.Rotation = math.random(-25, 25)
		coin.Size = UDim2.fromOffset(16, 16)
		coin.ZIndex = 5
		coin.Parent = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = coin

		local angle = (index / 18) * math.pi * 2 + math.random() * 0.35
		local distance = 90 + math.random(30, 110)
		local target = UDim2.new(
			0.5,
			math.cos(angle) * distance,
			0.58,
			math.sin(angle) * distance - math.random(30, 70)
		)

		TweenService:Create(coin, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = target,
			Rotation = coin.Rotation + math.random(-90, 90),
			BackgroundTransparency = 1,
		}):Play()

		task.delay(0.75, function()
			if coin.Parent then
				coin:Destroy()
			end
		end)
	end
end

local function playTapWobble(model: Model, basePivot: CFrame, intensity: number)
	for step = 1, 10 do
		local progress = step / 10
		local roll = math.sin(progress * math.pi * 5) * math.rad(intensity)
		local pitch = math.sin(progress * math.pi * 4) * math.rad(intensity * 0.45)
		model:PivotTo(basePivot * CFrame.Angles(pitch, 0, roll))
		RunService.RenderStepped:Wait()
	end
	model:PivotTo(basePivot)
end

local function runOpenSequence(
	token: number,
	model: Model,
	basePivot: CFrame,
	parts: TreasureChestPreview.ChestModelParts,
	gold: number
)
	local openDuration = 0.38
	local openStart = os.clock()
	while os.clock() - openStart < openDuration do
		if token ~= activeToken then
			return
		end

		local alpha = smoothstep((os.clock() - openStart) / openDuration)
		parts.lid.CFrame = parts.lidClosedCFrame:Lerp(parts.lidOpenCFrame, alpha)
		parts.glow.Transparency = 0.35 + alpha * 0.25
		model:PivotTo(basePivot)
		RunService.RenderStepped:Wait()
	end

	if token ~= activeToken then
		return
	end

	parts.lid.CFrame = parts.lidOpenCFrame
	spawnGoldBurst(container, parts.glow.Color)

	TweenService:Create(goldLabel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		TextStrokeTransparency = 0.1,
	}):Play()

	task.wait(2.6)
	if token ~= activeToken then
		return
	end

	local fade = TweenService:Create(goldLabel, TweenInfo.new(0.35), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	fade:Play()
	fade.Completed:Wait()

	if token == activeToken then
		backdrop.Visible = false
		container.Visible = false
		for _, child in viewportHost:GetChildren() do
			child:Destroy()
		end
	end
end

local function playOpeningAnimation(loot: any)
	if typeof(loot) ~= "table" or typeof(loot.gold) ~= "number" then
		return
	end

	local tierId = if typeof(loot.tierId) == "string" then loot.tierId else "Common"
	local gold = math.floor(loot.gold)

	ensureUI()
	activeToken += 1
	local token = activeToken

	for _, child in viewportHost:GetChildren() do
		child:Destroy()
	end

	backdrop.Visible = true
	container.Visible = true
	goldLabel.Text = `+{gold} Gold`
	goldLabel.TextTransparency = 1
	goldLabel.TextStrokeTransparency = 1
	tapHintLabel.Visible = true
	tapHintLabel.Text = `Tap the chest to open! (0/{REQUIRED_TAPS})`

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "ChestViewport"
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundTransparency = 1
	viewport.ZIndex = 2
	viewport.Parent = viewportHost

	local parts = TreasureChestPreview.buildChestModel(tierId)
	local model = parts.model
	local basePivot = CFrame.Angles(0, math.rad(24), math.rad(-10))
	model:PivotTo(basePivot)
	model.Parent = viewport

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(4.4, 3.1, 4.6), Vector3.new(0, 0.8, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	parts.lid.CFrame = parts.lidClosedCFrame
	parts.glow.Transparency = 0.35

	local tapButton = Instance.new("TextButton")
	tapButton.Name = "TapTarget"
	tapButton.Size = UDim2.fromScale(1, 1)
	tapButton.BackgroundTransparency = 1
	tapButton.Text = ""
	tapButton.AutoButtonColor = false
	tapButton.ZIndex = 10
	tapButton.Parent = viewportHost

	local tapCount = 0
	local finished = false

	local tapConnection: RBXScriptConnection
	tapConnection = tapButton.MouseButton1Click:Connect(function()
		if finished or token ~= activeToken then
			return
		end

		tapCount += 1
		tapHintLabel.Text = if tapCount < REQUIRED_TAPS
			then `Tap the chest to open! ({tapCount}/{REQUIRED_TAPS})`
			else "Opening..."

		task.spawn(function()
			playTapWobble(model, basePivot, 6 + tapCount)
		end)

		if tapCount < REQUIRED_TAPS then
			return
		end

		finished = true
		tapConnection:Disconnect()
		tapButton:Destroy()
		tapHintLabel.Visible = false

		task.spawn(function()
			runOpenSequence(token, model, basePivot, parts, gold)
		end)
	end)
end

function TreasureChestClient.init()
	local chestOpenedEvent = ReplicatedStorage:WaitForChild("TreasureChestOpened") :: RemoteEvent
	chestOpenedEvent.OnClientEvent:Connect(playOpeningAnimation)
end

return TreasureChestClient
