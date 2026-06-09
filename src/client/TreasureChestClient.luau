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

local screenGui: ScreenGui
local container: Frame
local goldLabel: TextLabel
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

	container = Instance.new("Frame")
	container.Name = "ChestOpenContainer"
	container.AnchorPoint = Vector2.new(0, 0)
	container.BackgroundTransparency = 1
	container.Position = UDim2.fromOffset(18, 18)
	container.Size = UDim2.fromOffset(250, 220)
	container.Visible = false
	container.Parent = screenGui

	goldLabel = Instance.new("TextLabel")
	goldLabel.Name = "GoldReward"
	goldLabel.AnchorPoint = Vector2.new(0.5, 1)
	goldLabel.BackgroundTransparency = 1
	goldLabel.Position = UDim2.new(0.5, 0, 0, -2)
	goldLabel.Size = UDim2.fromOffset(220, 40)
	goldLabel.Font = Enum.Font.Antique
	goldLabel.Text = ""
	goldLabel.TextColor3 = GOLD_BRIGHT
	goldLabel.TextSize = 28
	goldLabel.TextStrokeColor3 = SHADOW
	goldLabel.TextStrokeTransparency = 0.1
	goldLabel.TextTransparency = 1
	goldLabel.ZIndex = 4
	goldLabel.Parent = container

	viewportHost = Instance.new("Frame")
	viewportHost.Name = "ViewportHost"
	viewportHost.BackgroundTransparency = 1
	viewportHost.Position = UDim2.fromOffset(0, 36)
	viewportHost.Size = UDim2.fromOffset(250, 184)
	viewportHost.ClipsDescendants = false
	viewportHost.Parent = container
end

local function spawnGoldBurst(parent: Instance, tierGlow: Color3)
	local origin = UDim2.new(0.5, 0, 0.62, 0)
	for index = 1, 14 do
		local coin = Instance.new("Frame")
		coin.Name = `GoldCoin_{index}`
		coin.AnchorPoint = Vector2.new(0.5, 0.5)
		coin.BackgroundColor3 = if index % 3 == 0 then tierGlow else GOLD
		coin.BorderSizePixel = 0
		coin.Position = origin
		coin.Rotation = math.random(-25, 25)
		coin.Size = UDim2.fromOffset(12, 12)
		coin.ZIndex = 5
		coin.Parent = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = coin

		local angle = (index / 14) * math.pi * 2 + math.random() * 0.35
		local distance = 48 + math.random(18, 52)
		local target = UDim2.new(
			0.5,
			math.cos(angle) * distance,
			0.62,
			math.sin(angle) * distance - math.random(18, 42)
		)

		TweenService:Create(coin, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = target,
			Rotation = coin.Rotation + math.random(-90, 90),
			BackgroundTransparency = 1,
		}):Play()

		task.delay(0.7, function()
			if coin.Parent then
				coin:Destroy()
			end
		end)
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

	container.Visible = true
	goldLabel.Text = `+{gold} Gold`
	goldLabel.TextTransparency = 1
	goldLabel.TextStrokeTransparency = 1

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "ChestViewport"
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundTransparency = 1
	viewport.Parent = viewportHost

	local parts = TreasureChestPreview.buildChestModel(tierId)
	local model = parts.model
	local basePivot = CFrame.Angles(0, math.rad(24), math.rad(-10))
	model:PivotTo(basePivot)
	model.Parent = viewport

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(5.2, 3.6, 5.4), Vector3.new(0, 0.8, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	parts.lid.CFrame = parts.lidClosedCFrame
	parts.glow.Transparency = 0.35

	task.spawn(function()
		local wobbleDuration = 0.75
		local wobbleStart = os.clock()
		while os.clock() - wobbleStart < wobbleDuration do
			if token ~= activeToken then
				return
			end

			local elapsed = os.clock() - wobbleStart
			local roll = math.sin(elapsed * 26) * math.rad(5)
			local pitch = math.sin(elapsed * 34) * math.rad(3)
			local yaw = math.sin(elapsed * 18) * math.rad(2)
			model:PivotTo(basePivot * CFrame.Angles(pitch, yaw, roll))
			RunService.RenderStepped:Wait()
		end

		local openDuration = 0.35
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

		parts.lid.CFrame = parts.lidOpenCFrame
		spawnGoldBurst(container, parts.glow.Color)

		TweenService:Create(goldLabel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextTransparency = 0,
			TextStrokeTransparency = 0.1,
		}):Play()

		task.wait(2.4)
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
			container.Visible = false
			for _, child in viewportHost:GetChildren() do
				child:Destroy()
			end
		end
	end)
end

function TreasureChestClient.init()
	local chestOpenedEvent = ReplicatedStorage:WaitForChild("TreasureChestOpened") :: RemoteEvent
	chestOpenedEvent.OnClientEvent:Connect(playOpeningAnimation)
end

return TreasureChestClient
