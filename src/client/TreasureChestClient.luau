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

local function weld(part0: BasePart, part1: BasePart)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = part0
	weldConstraint.Part1 = part1
	weldConstraint.Parent = part0
end

local function createViewportCoin(color: Color3, accent: Color3): Model
	local coinModel = Instance.new("Model")
	coinModel.Name = "GoldCoin"

	local disc = Instance.new("Part")
	disc.Name = "Disc"
	disc.Shape = Enum.PartType.Cylinder
	disc.Size = Vector3.new(0.07, 0.34, 0.34)
	disc.Color = color
	disc.Material = Enum.Material.Metal
	disc.Anchored = true
	disc.CanCollide = false
	disc.Parent = coinModel

	local rim = Instance.new("Part")
	rim.Name = "Rim"
	rim.Shape = Enum.PartType.Cylinder
	rim.Size = Vector3.new(0.045, 0.36, 0.36)
	rim.Color = accent
	rim.Material = Enum.Material.Neon
	rim.Anchored = true
	rim.CanCollide = false
	rim.Transparency = 0.12
	rim.Parent = coinModel

	local face = Instance.new("Part")
	face.Name = "Face"
	face.Shape = Enum.PartType.Cylinder
	face.Size = Vector3.new(0.02, 0.22, 0.22)
	face.Color = GOLD_BRIGHT
	face.Material = Enum.Material.Neon
	face.Anchored = true
	face.CanCollide = false
	face.Transparency = 0.25
	face.Parent = coinModel

	disc.CFrame = CFrame.new()
	rim.CFrame = disc.CFrame
	face.CFrame = disc.CFrame * CFrame.new(0.028, 0, 0)

	weld(disc, rim)
	weld(disc, face)

	coinModel.PrimaryPart = disc
	return coinModel
end

local function animateViewportPart(
	model: Model,
	mid: Vector3,
	endPos: Vector3,
	duration: number,
	spin: Vector3
)
	local root = model.PrimaryPart
	if not root then
		model:Destroy()
		return
	end

	local startCFrame = model:GetPivot()
	local startTime = os.clock()
	local connection: RBXScriptConnection

	connection = RunService.RenderStepped:Connect(function()
		if not model.Parent then
			connection:Disconnect()
			return
		end

		local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
		local eased = smoothstep(alpha)
		local arcAlpha = math.sin(eased * math.pi)
		local position = startCFrame.Position:Lerp(mid, arcAlpha):Lerp(endPos, eased)
		local spinOffset = CFrame.Angles(spin.X * eased, spin.Y * eased, spin.Z * eased)
		model:PivotTo(CFrame.new(position) * (startCFrame - startCFrame.Position) * spinOffset)

		if alpha >= 1 then
			connection:Disconnect()
			model:Destroy()
		end
	end)
end

local function spawnViewportGoldStream(
	model: Model,
	parts: TreasureChestPreview.ChestModelParts,
	gold: number,
	tierGlow: Color3
)
	local origin = parts.lidOpenCFrame.Position + Vector3.new(0, 0.12, 0.42)
	local coinCount = math.clamp(math.floor(gold / 5), 20, 48)

	for index = 1, coinCount do
		task.delay((index - 1) * 0.03, function()
			if not model.Parent then
				return
			end

			local coinModel = createViewportCoin(
				if index % 5 == 0 then tierGlow else GOLD,
				if index % 3 == 0 then GOLD_BRIGHT else tierGlow
			)
			coinModel:PivotTo(
				CFrame.new(origin)
					* CFrame.new(math.random(-18, 18) / 100, math.random(-4, 8) / 100, math.random(-12, 12) / 100)
					* CFrame.Angles(math.random() * math.pi, math.random() * math.pi, math.random() * math.pi)
			)
			coinModel.Parent = model

			local horizontal = Vector3.new(math.random(-22, 22) / 10, 0, math.random(-22, 22) / 10)
			local rise = Vector3.new(0, math.random(14, 32) / 10, 0)
			local fall = Vector3.new(horizontal.X, -math.random(32, 58) / 10, horizontal.Z)
			local mid = origin + rise + horizontal * 0.5
			local endPos = origin + fall
			local duration = 0.65 + math.random() * 0.4
			local spin = Vector3.new(math.random(4, 9), math.random(5, 11), math.random(3, 8))

			animateViewportPart(coinModel, mid, endPos, duration, spin)
		end)
	end
end

local function createViewportGrimoireModel(): Model
	local grimoireModel = Instance.new("Model")
	grimoireModel.Name = "GrimoireDrop"

	local cover = Instance.new("Part")
	cover.Name = "Cover"
	cover.Size = Vector3.new(0.62, 0.82, 0.1)
	cover.Color = GRIMOIRE
	cover.Material = Enum.Material.SmoothPlastic
	cover.Anchored = true
	cover.CanCollide = false
	cover.Parent = grimoireModel

	local spine = Instance.new("Part")
	spine.Name = "Spine"
	spine.Size = Vector3.new(0.12, 0.82, 0.14)
	spine.Color = Color3.fromRGB(92, 58, 128)
	spine.Material = Enum.Material.SmoothPlastic
	spine.Anchored = true
	spine.CanCollide = false
	spine.Parent = grimoireModel

	local pages = Instance.new("Part")
	pages.Name = "Pages"
	pages.Size = Vector3.new(0.56, 0.76, 0.08)
	pages.Color = Color3.fromRGB(236, 224, 196)
	pages.Material = Enum.Material.SmoothPlastic
	pages.Anchored = true
	pages.CanCollide = false
	pages.Parent = grimoireModel

	local clasp = Instance.new("Part")
	clasp.Name = "Clasp"
	clasp.Size = Vector3.new(0.14, 0.14, 0.14)
	clasp.Shape = Enum.PartType.Ball
	clasp.Color = GRIMOIRE_BRIGHT
	clasp.Material = Enum.Material.Neon
	clasp.Anchored = true
	clasp.CanCollide = false
	clasp.Parent = grimoireModel

	local rune = Instance.new("Part")
	rune.Name = "Rune"
	rune.Size = Vector3.new(0.24, 0.24, 0.04)
	rune.Color = GRIMOIRE_BRIGHT
	rune.Material = Enum.Material.Neon
	rune.Anchored = true
	rune.CanCollide = false
	rune.Parent = grimoireModel

	cover.CFrame = CFrame.new()
	spine.CFrame = cover.CFrame * CFrame.new(-0.33, 0, 0)
	pages.CFrame = cover.CFrame * CFrame.new(0.02, 0, -0.04)
	clasp.CFrame = cover.CFrame * CFrame.new(0.18, -0.24, 0.08)
	rune.CFrame = cover.CFrame * CFrame.new(0.08, 0.12, 0.06)

	weld(cover, spine)
	weld(cover, pages)
	weld(cover, clasp)
	weld(cover, rune)

	local light = Instance.new("PointLight")
	light.Color = GRIMOIRE_BRIGHT
	light.Brightness = 2.2
	light.Range = 6
	light.Parent = cover

	grimoireModel.PrimaryPart = cover
	return grimoireModel
end

local function spawnViewportGrimoire(model: Model, parts: TreasureChestPreview.ChestModelParts)
	local origin = parts.lidOpenCFrame.Position + Vector3.new(0, 0.28, 0.28)
	local grimoireModel = createViewportGrimoireModel()
	grimoireModel:PivotTo(CFrame.new(origin) * CFrame.Angles(math.rad(-24), math.rad(18), math.rad(10)))
	grimoireModel.Parent = model

	local horizontal = Vector3.new(0.55, 0, -0.35)
	local mid = origin + Vector3.new(0.25, 1.35, -0.15)
	local endPos = origin + horizontal + Vector3.new(0.9, 1.85, -0.55)
	local duration = 1.15
	local startPivot = grimoireModel:GetPivot()
	local startTime = os.clock()

	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		if not grimoireModel.Parent then
			connection:Disconnect()
			return
		end

		local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
		local eased = smoothstep(alpha)
		local arcAlpha = math.sin(eased * math.pi)
		local position = startPivot.Position:Lerp(mid, arcAlpha):Lerp(endPos, eased)
		grimoireModel:PivotTo(
			CFrame.new(position)
				* CFrame.Angles(
					math.rad(-24 + eased * 18),
					math.rad(18 + eased * 50),
					math.rad(10 - eased * 22)
				)
		)

		for _, descendant in grimoireModel:GetDescendants() do
			if descendant:IsA("BasePart") and (descendant.Name == "Rune" or descendant.Name == "Clasp") then
				descendant.Transparency = 0.1 + math.sin(os.clock() * 8) * 0.08
			end
		end

		if alpha >= 1 then
			connection:Disconnect()
			for _, descendant in grimoireModel:GetDescendants() do
				if descendant:IsA("BasePart") then
					TweenService:Create(descendant, TweenInfo.new(0.4), { Transparency = 1 }):Play()
				elseif descendant:IsA("PointLight") then
					TweenService:Create(descendant, TweenInfo.new(0.4), { Brightness = 0 }):Play()
				end
			end
			task.delay(0.45, function()
				if grimoireModel.Parent then
					grimoireModel:Destroy()
				end
			end)
		end
	end)
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
