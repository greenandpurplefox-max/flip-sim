local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local TreasureChestPreview = require(script.Parent.TreasureChestPreview)
local UiCorner = require(script.Parent.UiCorner)

local TreasureChestClient = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GOLD = Color3.fromRGB(228, 188, 84)
local GOLD_BRIGHT = Color3.fromRGB(255, 228, 140)
local GRIMOIRE = Color3.fromRGB(180, 120, 255)
local GRIMOIRE_BRIGHT = Color3.fromRGB(220, 180, 255)
local SHADOW = Color3.fromRGB(8, 4, 10)
local REQUIRED_TAPS = 3

local screenGui: ScreenGui
local backdrop: Frame
local container: Frame
local goldLabel: TextLabel
local grimoireLabel: TextLabel
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

	grimoireLabel = Instance.new("TextLabel")
	grimoireLabel.Name = "GrimoireReward"
	grimoireLabel.AnchorPoint = Vector2.new(0.5, 0)
	grimoireLabel.BackgroundTransparency = 1
	grimoireLabel.Position = UDim2.new(0.5, 0, 0, 52)
	grimoireLabel.Size = UDim2.fromOffset(360, 44)
	grimoireLabel.Font = Enum.Font.Antique
	grimoireLabel.Text = ""
	grimoireLabel.TextColor3 = GRIMOIRE_BRIGHT
	grimoireLabel.TextSize = 30
	grimoireLabel.TextStrokeColor3 = SHADOW
	grimoireLabel.TextStrokeTransparency = 0.1
	grimoireLabel.TextTransparency = 1
	grimoireLabel.Visible = false
	grimoireLabel.ZIndex = 4
	grimoireLabel.Parent = container

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

local function spawnViewportGoldStream(
	model: Model,
	parts: TreasureChestPreview.ChestModelParts,
	gold: number,
	tierGlow: Color3
)
	local origin = parts.lidOpenCFrame.Position + Vector3.new(0, 0.15, 0.35)
	local coinCount = math.clamp(math.floor(gold / 6), 16, 42)

	for index = 1, coinCount do
		task.delay((index - 1) * 0.035, function()
			if not model.Parent then
				return
			end

			local coin = Instance.new("Part")
			coin.Name = `GoldCoin_{index}`
			coin.Size = Vector3.new(0.32, 0.1, 0.32)
			coin.Color = if index % 4 == 0 then tierGlow else GOLD_BRIGHT
			coin.Material = Enum.Material.Neon
			coin.Anchored = true
			coin.CanCollide = false
			coin.CFrame = CFrame.new(origin)
				* CFrame.new(math.random(-20, 20) / 100, math.random(-5, 10) / 100, math.random(-15, 15) / 100)
				* CFrame.Angles(math.random() * math.pi, math.random() * math.pi, math.random() * math.pi)
			coin.Parent = model

			local horizontal = Vector3.new(math.random(-18, 18) / 10, 0, math.random(-18, 18) / 10)
			local rise = Vector3.new(0, math.random(12, 28) / 10, 0)
			local fall = Vector3.new(horizontal.X, -math.random(28, 52) / 10, horizontal.Z)
			local mid = origin + rise + horizontal * 0.45
			local endPos = origin + fall

			local duration = 0.55 + math.random() * 0.35
			local startTime = os.clock()
			local startCFrame = coin.CFrame
			local startRotation = startCFrame - startCFrame.Position

			local connection: RBXScriptConnection
			connection = RunService.RenderStepped:Connect(function()
				if not coin.Parent then
					connection:Disconnect()
					return
				end

				local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
				local eased = smoothstep(alpha)
				local arcAlpha = math.sin(eased * math.pi)
				local position = startCFrame.Position:Lerp(mid, arcAlpha):Lerp(endPos, eased)
				coin.CFrame = CFrame.new(position) * startRotation * CFrame.Angles(0, eased * math.pi * 2, 0)

				if alpha >= 1 then
					connection:Disconnect()
					coin:Destroy()
				end
			end)
		end)
	end
end

local function spawnViewportGrimoire(model: Model, parts: TreasureChestPreview.ChestModelParts)
	local origin = parts.lidOpenCFrame.Position + Vector3.new(0, 0.35, 0.2)

	local book = Instance.new("Part")
	book.Name = "GrimoireDrop"
	book.Size = Vector3.new(0.55, 0.75, 0.12)
	book.Color = GRIMOIRE
	book.Material = Enum.Material.Neon
	book.Anchored = true
	book.CanCollide = false
	book.CFrame = CFrame.new(origin) * CFrame.Angles(math.rad(-18), math.rad(24), math.rad(8))
	book.Parent = model

	local target = origin + Vector3.new(0.8, 1.6, -0.4)
	TweenService:Create(book, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = CFrame.new(target) * CFrame.Angles(math.rad(-28), math.rad(40), math.rad(-12)),
		Transparency = 0.15,
	}):Play()

	task.delay(1.1, function()
		if book.Parent then
			TweenService:Create(book, TweenInfo.new(0.35), { Transparency = 1 }):Play()
			task.delay(0.4, function()
				if book.Parent then
					book:Destroy()
				end
			end)
		end
	end)
end

local function spawnGoldBurst(parent: Instance, tierGlow: Color3, gold: number)
	local origin = UDim2.new(0.5, 0, 0.58, 0)
	local burstCount = math.clamp(math.floor(gold / 10), 14, 28)

	for index = 1, burstCount do
		local coin = Instance.new("Frame")
		coin.Name = `GoldCoin_{index}`
		coin.AnchorPoint = Vector2.new(0.5, 0.5)
		coin.BackgroundColor3 = if index % 3 == 0 then tierGlow else GOLD
		coin.BorderSizePixel = 0
		coin.Position = origin
		coin.Rotation = math.random(-25, 25)
		coin.Size = UDim2.fromOffset(14 + math.random(0, 6), 14 + math.random(0, 6))
		coin.ZIndex = 5
		coin.Parent = parent

		UiCorner.apply(coin, UDim.new(1, 0))

		local angle = (index / burstCount) * math.pi * 2 + math.random() * 0.35
		local distance = 70 + math.random(40, 130)
		local fall = math.random(40, 120)
		local target = UDim2.new(
			0.5,
			math.cos(angle) * distance,
			0.58,
			math.sin(angle) * distance * 0.35 + fall
		)

		TweenService:Create(coin, TweenInfo.new(0.85 + math.random() * 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = target,
			Rotation = coin.Rotation + math.random(-120, 120),
			BackgroundTransparency = 1,
		}):Play()

		task.delay(1.1, function()
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
	gold: number,
	grimoireDropped: boolean
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
	spawnViewportGoldStream(model, parts, gold, parts.glow.Color)
	spawnGoldBurst(container, parts.glow.Color, gold)
	if grimoireDropped then
		spawnViewportGrimoire(model, parts)
	end

	TweenService:Create(goldLabel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		TextStrokeTransparency = 0.1,
	}):Play()

	if grimoireDropped then
		grimoireLabel.Visible = true
		TweenService:Create(grimoireLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextTransparency = 0,
			TextStrokeTransparency = 0.1,
		}):Play()
	end

	task.wait(if grimoireDropped then 3.1 else 2.6)
	if token ~= activeToken then
		return
	end

	local fadeGold = TweenService:Create(goldLabel, TweenInfo.new(0.35), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	fadeGold:Play()

	if grimoireDropped then
		local fadeGrimoire = TweenService:Create(grimoireLabel, TweenInfo.new(0.35), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		fadeGrimoire:Play()
		fadeGrimoire.Completed:Wait()
	else
		fadeGold.Completed:Wait()
	end

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
	local grimoireDropped = loot.grimoireDropped == true

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
	grimoireLabel.Text = "+1 Grimoire"
	grimoireLabel.TextTransparency = 1
	grimoireLabel.TextStrokeTransparency = 1
	grimoireLabel.Visible = grimoireDropped
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
			runOpenSequence(token, model, basePivot, parts, gold, grimoireDropped)
		end)
	end)
end

function TreasureChestClient.init()
	local chestOpenedEvent = ReplicatedStorage:WaitForChild("TreasureChestOpened") :: RemoteEvent
	chestOpenedEvent.OnClientEvent:Connect(playOpeningAnimation)
end

return TreasureChestClient
