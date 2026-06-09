local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local BossConfig = require(ReplicatedStorage.Shared.BossConfig)
local DungeonConfig = require(ReplicatedStorage.Shared.DungeonConfig)
local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)

local BossHealthBarUI = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PALETTE = {
	shadow = Color3.fromRGB(8, 4, 10),
	woodDark = Color3.fromRGB(36, 18, 14),
	woodMid = Color3.fromRGB(58, 30, 22),
	gold = Color3.fromRGB(228, 188, 84),
	goldBright = Color3.fromRGB(255, 228, 140),
	goldDim = Color3.fromRGB(148, 112, 42),
	ruby = Color3.fromRGB(168, 24, 48),
	crimson = Color3.fromRGB(132, 20, 32),
	parchment = Color3.fromRGB(244, 228, 196),
	bossRed = Color3.fromRGB(220, 60, 60),
	bossRedBright = Color3.fromRGB(255, 110, 90),
}

local screenGui: ScreenGui
local container: Frame
local fillBar: Frame
local fillGlow: Frame
local nameLabel: TextLabel
local healthLabel: TextLabel

local watchingBossFight = false
local inDungeon = false
local boundBoss: Model? = nil
local boundHumanoid: Humanoid? = nil
local bossConnections: { RBXScriptConnection } = {}

local function disconnectBoss()
	for _, connection in bossConnections do
		connection:Disconnect()
	end
	table.clear(bossConnections)
	boundBoss = nil
	boundHumanoid = nil
end

local function addCorner(instance: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function addStroke(instance: GuiObject, color: Color3, thickness: number, transparency: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.Parent = instance
end

local function styleText(label: TextLabel, size: number, color: Color3?)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Antique
	label.TextColor3 = color or PALETTE.parchment
	label.TextSize = size
	label.TextStrokeColor3 = PALETTE.shadow
	label.TextStrokeTransparency = 0.15
end

local function updateBar(health: number, maxHealth: number)
	local ratio = if maxHealth > 0 then math.clamp(health / maxHealth, 0, 1) else 0

	fillBar.BackgroundColor3 = PALETTE.bossRed
	fillGlow.BackgroundColor3 = PALETTE.bossRedBright
	TweenService:Create(fillBar, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(ratio, 0, 1, 0),
	}):Play()

	healthLabel.Text = `{math.floor(health)} / {math.floor(maxHealth)}`
end

local function hideBar()
	disconnectBoss()
	container.Visible = false
end

local function showBar(humanoid: Humanoid)
	container.Visible = true
	updateBar(humanoid.Health, humanoid.MaxHealth)
end

local function bindBoss(boss: Model, humanoid: Humanoid)
	if boundBoss == boss then
		return
	end

	disconnectBoss()
	boundBoss = boss
	boundHumanoid = humanoid

	nameLabel.Text = BossConfig.DISPLAY_NAME
	showBar(humanoid)

	table.insert(bossConnections, humanoid.HealthChanged:Connect(function(newHealth)
		updateBar(newHealth, humanoid.MaxHealth)
		if newHealth <= 0 then
			hideBar()
		end
	end))

	table.insert(bossConnections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		updateBar(humanoid.Health, humanoid.MaxHealth)
	end))

	table.insert(bossConnections, boss.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			hideBar()
		end
	end))

	table.insert(bossConnections, humanoid.Died:Connect(function()
		hideBar()
	end))
end

local function findPlayerBoss(): (Model?, Humanoid?)
	local monstersFolder = workspace:FindFirstChild("WaveMonsters")
	if not monstersFolder then
		return nil, nil
	end

	for _, child in monstersFolder:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("IsBoss") == true then
			if child:GetAttribute("DungeonOwner") == player.UserId then
				local humanoid = child:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					return child, humanoid
				end
			end
		end
	end

	return nil, nil
end

local function refreshBossBinding()
	if not inDungeon or not watchingBossFight then
		hideBar()
		return
	end

	local boss, humanoid = findPlayerBoss()
	if boss and humanoid then
		bindBoss(boss, humanoid)
	elseif boundBoss then
		hideBar()
	end
end

local function setWatchingBossFight(active: boolean)
	watchingBossFight = active
	if not active then
		hideBar()
	end
end

local function createUI()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BossHealthBarUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = true
	screenGui.Parent = playerGui

	container = Instance.new("Frame")
	container.Name = "BossHealthContainer"
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundColor3 = PALETTE.woodDark
	container.BorderSizePixel = 0
	container.Position = UDim2.new(0.5, 0, 0, 14)
	container.Size = UDim2.fromOffset(420, 58)
	container.Visible = false
	container.ZIndex = 20
	container.Parent = screenGui
	addCorner(container, 10)
	addStroke(container, PALETTE.gold, 2)
	addStroke(container, PALETTE.shadow, 4, 0.35)

	local crestBand = Instance.new("Frame")
	crestBand.Name = "CrestBand"
	crestBand.BackgroundColor3 = PALETTE.woodMid
	crestBand.BorderSizePixel = 0
	crestBand.Position = UDim2.fromOffset(10, 8)
	crestBand.Size = UDim2.new(1, -20, 0, 18)
	crestBand.ZIndex = 21
	crestBand.Parent = container
	addCorner(crestBand, 5)
	addStroke(crestBand, PALETTE.goldDim, 1)

	nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "BossName"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(8, 0)
	nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
	nameLabel.Text = BossConfig.DISPLAY_NAME
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 22
	styleText(nameLabel, 16, PALETTE.goldBright)
	nameLabel.Parent = crestBand

	healthLabel = Instance.new("TextLabel")
	healthLabel.Name = "HealthLabel"
	healthLabel.BackgroundTransparency = 1
	healthLabel.Position = UDim2.new(1, -108, 0, 0)
	healthLabel.Size = UDim2.fromOffset(100, 18)
	healthLabel.Text = "0 / 0"
	healthLabel.TextXAlignment = Enum.TextXAlignment.Right
	healthLabel.ZIndex = 22
	styleText(healthLabel, 14, PALETTE.parchment)
	healthLabel.Parent = crestBand

	local barFrame = Instance.new("Frame")
	barFrame.Name = "BarFrame"
	barFrame.BackgroundColor3 = PALETTE.shadow
	barFrame.BorderSizePixel = 0
	barFrame.Position = UDim2.fromOffset(12, 32)
	barFrame.Size = UDim2.new(1, -24, 0, 16)
	barFrame.ClipsDescendants = true
	barFrame.ZIndex = 21
	barFrame.Parent = container
	addCorner(barFrame, 4)
	addStroke(barFrame, PALETTE.goldDim, 1)

	local barInset = Instance.new("Frame")
	barInset.Name = "BarInset"
	barInset.BackgroundColor3 = Color3.fromRGB(18, 12, 14)
	barInset.BorderSizePixel = 0
	barInset.Size = UDim2.new(1, -4, 1, -4)
	barInset.Position = UDim2.fromOffset(2, 2)
	barInset.ClipsDescendants = true
	barInset.ZIndex = 22
	barInset.Parent = barFrame
	addCorner(barInset, 3)

	fillBar = Instance.new("Frame")
	fillBar.Name = "Fill"
	fillBar.BackgroundColor3 = PALETTE.bossRed
	fillBar.BorderSizePixel = 0
	fillBar.Size = UDim2.fromScale(1, 1)
	fillBar.ZIndex = 23
	fillBar.Parent = barInset

	fillGlow = Instance.new("Frame")
	fillGlow.Name = "FillGlow"
	fillGlow.BackgroundColor3 = PALETTE.bossRedBright
	fillGlow.BackgroundTransparency = 0.65
	fillGlow.BorderSizePixel = 0
	fillGlow.Size = UDim2.new(1, 0, 0.45, 0)
	fillGlow.ZIndex = 24
	fillGlow.Parent = fillBar
end

function BossHealthBarUI.init()
	if not DungeonConfig.USE_DUNGEON_MODE then
		return
	end

	createUI()

	local dungeonRunStateEvent = ReplicatedStorage:WaitForChild("DungeonRunState") :: RemoteEvent
	dungeonRunStateEvent.OnClientEvent:Connect(function(state: any)
		if not state then
			setWatchingBossFight(false)
			return
		end

		local shouldWatch = state.status == "fighting" and state.isBossRoom == true
		setWatchingBossFight(shouldWatch)
		refreshBossBinding()
	end)

	if LobbyConfig.USE_LOBBY then
		local phaseStateEvent = ReplicatedStorage:WaitForChild("PlayerPhaseState") :: RemoteEvent
		phaseStateEvent.OnClientEvent:Connect(function(phase: string)
			inDungeon = phase == "Dungeon"
			if not inDungeon then
				setWatchingBossFight(false)
			end
		end)
	else
		inDungeon = true
	end

	RunService.Heartbeat:Connect(function()
		if watchingBossFight and inDungeon and not boundBoss then
			refreshBossBinding()
		end
	end)
end

return BossHealthBarUI
