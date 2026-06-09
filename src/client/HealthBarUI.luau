local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local TreasureConfig = require(ReplicatedStorage.Shared.TreasureConfig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HealthBarUI = {}

local HIT_SOUND_ID = "rbxassetid://12222216"
local BASE_PITCH = 1
local PITCH_STEP = 0.07
local MAX_PITCH = 1.85
local PITCH_RESET_SECONDS = 5

local screenGui: ScreenGui
local container: Frame
local fillBar: Frame
local fillGlow: Frame
local healthLabel: TextLabel
local emblemLabel: TextLabel
local chestNotifyLabel: TextLabel
local hitSound: Sound

local segmentCount = 24
local lastHealth = 0
local activeCharacter: Model? = nil
local characterConnections: { RBXScriptConnection } = {}
local damageIndicatorIndex = 0
local hitPitch = BASE_PITCH
local pitchResetToken = 0
local chestNotifyToken = 0

local PALETTE = {
	shadow = Color3.fromRGB(8, 4, 10),
	woodDark = Color3.fromRGB(36, 18, 14),
	woodMid = Color3.fromRGB(58, 30, 22),
	woodLight = Color3.fromRGB(82, 48, 34),
	gold = Color3.fromRGB(228, 188, 84),
	goldBright = Color3.fromRGB(255, 228, 140),
	goldDim = Color3.fromRGB(148, 112, 42),
	ruby = Color3.fromRGB(168, 24, 48),
	emerald = Color3.fromRGB(36, 148, 88),
	crimson = Color3.fromRGB(132, 20, 32),
	parchment = Color3.fromRGB(244, 228, 196),
	parchmentDim = Color3.fromRGB(196, 170, 132),
	damage = Color3.fromRGB(255, 96, 96),
	manaGlow = Color3.fromRGB(255, 120, 120),
}

local function disconnectCharacterConnections()
	for _, connection in characterConnections do
		connection:Disconnect()
	end
	table.clear(characterConnections)
end

local function styleFantasyText(label: TextLabel, size: number, color: Color3?)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Antique
	label.TextColor3 = color or PALETTE.parchment
	label.TextSize = size
	label.TextStrokeColor3 = PALETTE.shadow
	label.TextStrokeTransparency = 0.15
end

local function addStroke(instance: GuiObject, color: Color3, thickness: number, transparency: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.Parent = instance
	return stroke
end

local function addCorner(instance: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
	return corner
end

local function createGem(parent: Instance, position: UDim2, zIndex: number)
	local gem = Instance.new("Frame")
	gem.Name = "CornerGem"
	gem.AnchorPoint = Vector2.new(0.5, 0.5)
	gem.BackgroundColor3 = PALETTE.ruby
	gem.BorderSizePixel = 0
	gem.Position = position
	gem.Rotation = 45
	gem.Size = UDim2.fromOffset(10, 10)
	gem.ZIndex = zIndex
	gem.Parent = parent
	addStroke(gem, PALETTE.goldBright, 1)
	addCorner(gem, 1)

	local gemGlow = Instance.new("Frame")
	gemGlow.BackgroundColor3 = PALETTE.goldBright
	gemGlow.BackgroundTransparency = 0.55
	gemGlow.BorderSizePixel = 0
	gemGlow.Size = UDim2.fromOffset(4, 4)
	gemGlow.Position = UDim2.fromOffset(2, 2)
	gemGlow.ZIndex = zIndex + 1
	gemGlow.Parent = gem
end

local function createDivider(parent: Instance, position: UDim2, size: UDim2, zIndex: number)
	local divider = Instance.new("Frame")
	divider.BackgroundColor3 = PALETTE.goldDim
	divider.BorderSizePixel = 0
	divider.Position = position
	divider.Size = size
	divider.ZIndex = zIndex
	divider.Parent = parent

	local shine = Instance.new("Frame")
	shine.BackgroundColor3 = PALETTE.goldBright
	shine.BackgroundTransparency = 0.35
	shine.BorderSizePixel = 0
	shine.Size = UDim2.new(1, 0, 0, 1)
	shine.ZIndex = zIndex + 1
	shine.Parent = divider
end

local function getHealthColor(health: number, maxHealth: number): Color3
	local ratio = if maxHealth > 0 then health / maxHealth else 0
	if ratio > 0.55 then
		return PALETTE.emerald
	elseif ratio > 0.25 then
		return PALETTE.gold
	end
	return PALETTE.crimson
end

local function playHitSound()
	hitPitch = math.min(hitPitch + PITCH_STEP, MAX_PITCH)
	hitSound.PlaybackSpeed = hitPitch
	hitSound:Play()

	pitchResetToken += 1
	local token = pitchResetToken
	task.delay(PITCH_RESET_SECONDS, function()
		if pitchResetToken == token then
			hitPitch = BASE_PITCH
		end
	end)
end

local function pulseBarOnHit()
	local originalPosition = container.Position
	TweenService:Create(container, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = originalPosition + UDim2.fromOffset(4, 0),
	}):Play()
	task.delay(0.08, function()
		if container.Parent then
			TweenService:Create(container, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = originalPosition,
			}):Play()
		end
	end)

	TweenService:Create(fillGlow, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.45,
	}):Play()
	task.delay(0.12, function()
		if fillGlow.Parent then
			TweenService:Create(fillGlow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.78,
			}):Play()
		end
	end)
end

local function updateBar(health: number, maxHealth: number)
	local ratio = if maxHealth > 0 then math.clamp(health / maxHealth, 0, 1) else 0
	local color = getHealthColor(health, maxHealth)

	fillBar.BackgroundColor3 = color
	fillGlow.BackgroundColor3 = color:Lerp(PALETTE.goldBright, 0.35)
	TweenService:Create(fillBar, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(ratio, 0, 1, 0),
	}):Play()

	healthLabel.Text = `{math.floor(health)} / {math.floor(maxHealth)}`
	emblemLabel.Text = if ratio > 0.25 then "♥" else "♡"
	emblemLabel.TextColor3 = if ratio > 0.25 then PALETTE.ruby else PALETTE.parchmentDim
end

local function showDamageIndicator(amount: number)
	if amount <= 0 then
		return
	end

	damageIndicatorIndex += 1
	local indicator = Instance.new("TextLabel")
	indicator.Name = `DamageIndicator_{damageIndicatorIndex}`
	indicator.AnchorPoint = Vector2.new(0.5, 0.5)
	indicator.BackgroundTransparency = 1
	indicator.Size = UDim2.fromOffset(72, 24)
	indicator.Text = `-{math.floor(amount)}`
	indicator.TextColor3 = PALETTE.damage
	indicator.TextSize = 18
	indicator.Font = Enum.Font.Fantasy
	indicator.TextStrokeColor3 = PALETTE.shadow
	indicator.TextStrokeTransparency = 0
	indicator.ZIndex = 30
	indicator.Parent = screenGui

	local barPos = container.AbsolutePosition
	local barSize = container.AbsoluteSize
	local startX = barPos.X + math.random(math.floor(barSize.X * 0.18), math.floor(barSize.X * 0.88))
	local startY = barPos.Y + math.random(8, math.floor(barSize.Y * 0.55))
	indicator.Position = UDim2.fromOffset(startX, startY)

	local velocity = Vector2.new(math.random(35, 100), -math.random(100, 170))
	local gravity = 430
	local lifetime = 0

	task.spawn(function()
		while indicator.Parent and lifetime < 2.5 do
			local deltaTime = RunService.RenderStepped:Wait()
			lifetime += deltaTime
			velocity += Vector2.new(0, gravity * deltaTime)
			startX += velocity.X * deltaTime
			startY += velocity.Y * deltaTime
			indicator.Position = UDim2.fromOffset(startX, startY)

			if lifetime > 0.9 then
				local fade = math.clamp((lifetime - 0.9) * 2.2, 0, 1)
				indicator.TextTransparency = fade
				indicator.TextStrokeTransparency = fade
			end

			local screenSize = screenGui.AbsoluteSize
			if startY > screenSize.Y + 40 or startX < -40 or startX > screenSize.X + 40 then
				break
			end
		end

		if indicator.Parent then
			indicator:Destroy()
		end
	end)
end

local function onDamageTaken(amount: number)
	playHitSound()
	pulseBarOnHit()
	showDamageIndicator(amount)
end

local function bindCharacter(character: Model)
	disconnectCharacterConnections()
	activeCharacter = character

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	lastHealth = humanoid.Health
	updateBar(humanoid.Health, humanoid.MaxHealth)

	table.insert(characterConnections, humanoid.HealthChanged:Connect(function(newHealth)
		if newHealth < lastHealth then
			onDamageTaken(lastHealth - newHealth)
		end
		lastHealth = newHealth
		updateBar(newHealth, humanoid.MaxHealth)
	end))

	table.insert(characterConnections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		updateBar(humanoid.Health, humanoid.MaxHealth)
	end))

	table.insert(characterConnections, character.AncestryChanged:Connect(function(_, parent)
		if parent == nil and activeCharacter == character then
			disconnectCharacterConnections()
			activeCharacter = nil
			updateBar(0, humanoid.MaxHealth)
		end
	end))
end

local function createUI()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HealthBarUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	hitSound = Instance.new("Sound")
	hitSound.Name = "HitSound"
	hitSound.SoundId = HIT_SOUND_ID
	hitSound.Volume = 0.55
	hitSound.Parent = screenGui

	local glowBackdrop = Instance.new("Frame")
	glowBackdrop.Name = "GlowBackdrop"
	glowBackdrop.AnchorPoint = Vector2.new(0, 1)
	glowBackdrop.BackgroundColor3 = PALETTE.gold
	glowBackdrop.BackgroundTransparency = 0.82
	glowBackdrop.BorderSizePixel = 0
	glowBackdrop.Position = UDim2.new(0, 10, 1, -10)
	glowBackdrop.Size = UDim2.fromOffset(318, 98)
	glowBackdrop.Parent = screenGui
	addCorner(glowBackdrop, 12)

	container = Instance.new("Frame")
	container.Name = "HealthBarContainer"
	container.AnchorPoint = Vector2.new(0, 1)
	container.BackgroundColor3 = PALETTE.woodDark
	container.BorderSizePixel = 0
	container.Position = UDim2.new(0, 16, 1, -16)
	container.Size = UDim2.fromOffset(300, 86)
	container.Parent = screenGui
	addCorner(container, 10)
	addStroke(container, PALETTE.gold, 2)
	addStroke(container, PALETTE.shadow, 4, 0.35)

	createGem(container, UDim2.fromOffset(0, 0), 8)
	createGem(container, UDim2.new(1, 0, 0, 0), 8)
	createGem(container, UDim2.new(0, 0, 1, 0), 8)
	createGem(container, UDim2.new(1, 0, 1, 0), 8)

	local crestBand = Instance.new("Frame")
	crestBand.Name = "CrestBand"
	crestBand.BackgroundColor3 = PALETTE.woodMid
	crestBand.BorderSizePixel = 0
	crestBand.Position = UDim2.fromOffset(10, 8)
	crestBand.Size = UDim2.new(1, -20, 0, 28)
	crestBand.ZIndex = 2
	crestBand.Parent = container
	addCorner(crestBand, 6)
	addStroke(crestBand, PALETTE.goldDim, 1)

	local crestShine = Instance.new("Frame")
	crestShine.BackgroundColor3 = PALETTE.goldBright
	crestShine.BackgroundTransparency = 0.78
	crestShine.BorderSizePixel = 0
	crestShine.Size = UDim2.new(1, 0, 0, 8)
	crestShine.ZIndex = 3
	crestShine.Parent = crestBand

	emblemLabel = Instance.new("TextLabel")
	emblemLabel.Name = "Emblem"
	emblemLabel.BackgroundTransparency = 1
	emblemLabel.Position = UDim2.fromOffset(8, 2)
	emblemLabel.Size = UDim2.fromOffset(24, 24)
	emblemLabel.Text = "♥"
	emblemLabel.ZIndex = 4
	styleFantasyText(emblemLabel, 22, PALETTE.ruby)
	emblemLabel.Parent = crestBand

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(34, 4)
	title.Size = UDim2.fromOffset(120, 20)
	title.Text = "VITALITY"
	title.ZIndex = 4
	styleFantasyText(title, 18, PALETTE.goldBright)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = crestBand

	healthLabel = Instance.new("TextLabel")
	healthLabel.Name = "HealthLabel"
	healthLabel.BackgroundTransparency = 1
	healthLabel.Position = UDim2.new(1, -108, 0, 5)
	healthLabel.Size = UDim2.fromOffset(96, 20)
	healthLabel.Text = "0 / 0"
	healthLabel.ZIndex = 4
	styleFantasyText(healthLabel, 16, PALETTE.parchment)
	healthLabel.TextXAlignment = Enum.TextXAlignment.Right
	healthLabel.Parent = crestBand

	createDivider(container, UDim2.new(0.5, -70, 0, 38), UDim2.fromOffset(140, 2), 3)

	local barFrame = Instance.new("Frame")
	barFrame.Name = "BarFrame"
	barFrame.BackgroundColor3 = PALETTE.woodLight
	barFrame.BorderSizePixel = 0
	barFrame.Position = UDim2.fromOffset(14, 46)
	barFrame.Size = UDim2.new(1, -28, 0, 24)
	barFrame.ZIndex = 2
	barFrame.ClipsDescendants = true
	barFrame.Parent = container
	addCorner(barFrame, 5)
	addStroke(barFrame, PALETTE.goldDim, 1)

	local barInset = Instance.new("Frame")
	barInset.Name = "BarInset"
	barInset.BackgroundColor3 = PALETTE.shadow
	barInset.BorderSizePixel = 0
	barInset.Position = UDim2.fromOffset(3, 3)
	barInset.Size = UDim2.new(1, -6, 1, -6)
	barInset.ZIndex = 3
	barInset.ClipsDescendants = true
	barInset.Parent = barFrame
	addCorner(barInset, 4)

	fillBar = Instance.new("Frame")
	fillBar.Name = "Fill"
	fillBar.BackgroundColor3 = PALETTE.emerald
	fillBar.BorderSizePixel = 0
	fillBar.Size = UDim2.new(1, 0, 1, 0)
	fillBar.ZIndex = 4
	fillBar.Parent = barInset

	fillGlow = Instance.new("Frame")
	fillGlow.Name = "FillGlow"
	fillGlow.BackgroundColor3 = PALETTE.emerald
	fillGlow.BackgroundTransparency = 0.78
	fillGlow.BorderSizePixel = 0
	fillGlow.Size = UDim2.new(1, 0, 0.45, 0)
	fillGlow.ZIndex = 5
	fillGlow.Parent = fillBar

	for index = 1, segmentCount - 1 do
		local notch = Instance.new("Frame")
		notch.Name = `Notch_{index}`
		notch.BackgroundColor3 = PALETTE.shadow
		notch.BackgroundTransparency = 0.25
		notch.BorderSizePixel = 0
		notch.Size = UDim2.new(0, 1, 1, 0)
		notch.Position = UDim2.new(index / segmentCount, 0, 0, 0)
		notch.ZIndex = 6
		notch.Parent = barInset
	end

	local leftScroll = Instance.new("TextLabel")
	leftScroll.BackgroundTransparency = 1
	leftScroll.Font = Enum.Font.Antique
	leftScroll.Position = UDim2.fromOffset(2, 42)
	leftScroll.Size = UDim2.fromOffset(12, 30)
	leftScroll.Text = "✦"
	leftScroll.TextColor3 = PALETTE.gold
	leftScroll.TextSize = 14
	leftScroll.ZIndex = 5
	leftScroll.Parent = container

	local rightScroll = leftScroll:Clone()
	rightScroll.Position = UDim2.new(1, -14, 0, 42)
	rightScroll.Parent = container

	local bottomRunes = Instance.new("TextLabel")
	bottomRunes.BackgroundTransparency = 1
	bottomRunes.Font = Enum.Font.Antique
	bottomRunes.Position = UDim2.new(0.5, -48, 1, -14)
	bottomRunes.Size = UDim2.fromOffset(96, 12)
	bottomRunes.Text = "◆ ◇ ◆"
	bottomRunes.TextColor3 = PALETTE.goldDim
	bottomRunes.TextSize = 10
	bottomRunes.ZIndex = 5
	bottomRunes.Parent = container

	chestNotifyLabel = Instance.new("TextLabel")
	chestNotifyLabel.Name = "ChestNotify"
	chestNotifyLabel.AnchorPoint = Vector2.new(0, 1)
	chestNotifyLabel.BackgroundTransparency = 1
	chestNotifyLabel.Position = UDim2.new(0, 16, 1, -106)
	chestNotifyLabel.Size = UDim2.fromOffset(300, 24)
	chestNotifyLabel.Font = Enum.Font.Antique
	chestNotifyLabel.Text = ""
	chestNotifyLabel.TextColor3 = PALETTE.goldBright
	chestNotifyLabel.TextSize = 16
	chestNotifyLabel.TextStrokeColor3 = PALETTE.shadow
	chestNotifyLabel.TextStrokeTransparency = 0.1
	chestNotifyLabel.TextTransparency = 1
	chestNotifyLabel.TextXAlignment = Enum.TextXAlignment.Center
	chestNotifyLabel.ZIndex = 12
	chestNotifyLabel.Visible = false
	chestNotifyLabel.Parent = screenGui
end

local function showChestAwarded(payload: any)
	if typeof(payload) ~= "table" then
		return
	end

	local tierId = if typeof(payload.tierId) == "string" then payload.tierId else "Common"
	local tier = TreasureConfig.getTier(tierId)
	local tierName = if typeof(payload.tierName) == "string" then payload.tierName else tier.displayName

	chestNotifyLabel.Text = `{tierName} secured!`
	chestNotifyLabel.TextColor3 = tier.glowColor
	chestNotifyLabel.TextTransparency = 0
	chestNotifyLabel.Visible = true

	chestNotifyToken += 1
	local token = chestNotifyToken
	task.delay(3.2, function()
		if chestNotifyToken ~= token or not chestNotifyLabel.Parent then
			return
		end
		local fade = TweenService:Create(chestNotifyLabel, TweenInfo.new(0.35), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		fade:Play()
		fade.Completed:Connect(function()
			if chestNotifyToken == token then
				chestNotifyLabel.Visible = false
				chestNotifyLabel.TextStrokeTransparency = 0.1
			end
		end)
	end)
end

function HealthBarUI.init()
	createUI()

	local awardedEvent = ReplicatedStorage:WaitForChild("TreasureChestAwarded") :: RemoteEvent
	awardedEvent.OnClientEvent:Connect(showChestAwarded)

	if player.Character then
		bindCharacter(player.Character)
	end

	player.CharacterAdded:Connect(bindCharacter)
end

return HealthBarUI
