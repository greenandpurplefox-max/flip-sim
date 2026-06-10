local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local StaminaConfig = require(ReplicatedStorage.Shared.StaminaConfig)

local StaminaBarUI = {}

local PALETTE = {
	shadow = Color3.fromRGB(8, 4, 10),
	frame = Color3.fromRGB(36, 18, 14),
	inset = Color3.fromRGB(18, 10, 8),
	fill = Color3.fromRGB(72, 168, 255),
	fillLow = Color3.fromRGB(255, 170, 72),
	fillEmpty = Color3.fromRGB(120, 60, 60),
	gold = Color3.fromRGB(228, 188, 84),
}

local player = Players.LocalPlayer
local billboard: BillboardGui?
local fillBar: Frame?
local valueLabel: TextLabel?
local characterConnections: { RBXScriptConnection } = {}

local function disconnectCharacterConnections()
	for _, connection in characterConnections do
		connection:Disconnect()
	end
	table.clear(characterConnections)
end

local function getStaminaRatio(): number
	local maxStamina = player:GetAttribute("MaxStamina") or StaminaConfig.MAX
	local stamina = player:GetAttribute("Stamina") or maxStamina
	if maxStamina <= 0 then
		return 0
	end
	return math.clamp(stamina / maxStamina, 0, 1)
end

local function getFillColor(ratio: number): Color3
	if ratio <= 0.01 then
		return PALETTE.fillEmpty
	end
	if ratio <= 0.25 then
		return PALETTE.fillLow
	end
	return PALETTE.fill
end

local function updateBar()
	if not fillBar or not valueLabel then
		return
	end

	local maxStamina = player:GetAttribute("MaxStamina") or StaminaConfig.MAX
	local stamina = player:GetAttribute("Stamina") or maxStamina
	local ratio = getStaminaRatio()
	local color = getFillColor(ratio)

	fillBar.BackgroundColor3 = color
	valueLabel.Text = `{math.floor(stamina)}`
	TweenService:Create(fillBar, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, ratio, 0),
	}):Play()
end

local function mountBar(character: Model)
	disconnectCharacterConnections()

	if billboard then
		billboard:Destroy()
		billboard = nil
		fillBar = nil
		valueLabel = nil
	end

	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	local gui = Instance.new("BillboardGui")
	gui.Name = "StaminaBar"
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Size = UDim2.fromOffset(18, 88)
	gui.StudsOffset = Vector3.new(-3.4, 0.75, 0)
	gui.Adornee = root
	gui.Parent = root
	billboard = gui

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.BackgroundColor3 = PALETTE.frame
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = PALETTE.gold
	stroke.Thickness = 1.5
	stroke.Parent = frame

	local inset = Instance.new("Frame")
	inset.Name = "Inset"
	inset.AnchorPoint = Vector2.new(0.5, 1)
	inset.Position = UDim2.new(0.5, 0, 1, -4)
	inset.Size = UDim2.new(1, -8, 1, -22)
	inset.BackgroundColor3 = PALETTE.inset
	inset.BorderSizePixel = 0
	inset.ClipsDescendants = true
	inset.Parent = frame

	local insetCorner = Instance.new("UICorner")
	insetCorner.CornerRadius = UDim.new(0, 4)
	insetCorner.Parent = inset

	fillBar = Instance.new("Frame")
	fillBar.Name = "Fill"
	fillBar.AnchorPoint = Vector2.new(0.5, 1)
	fillBar.Position = UDim2.fromScale(0.5, 1)
	fillBar.Size = UDim2.new(1, 0, 1, 0)
	fillBar.BackgroundColor3 = PALETTE.fill
	fillBar.BorderSizePixel = 0
	fillBar.Parent = inset

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fillBar

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 16)
	title.Position = UDim2.fromOffset(0, 2)
	title.Font = Enum.Font.GothamBold
	title.Text = "ST"
	title.TextColor3 = PALETTE.gold
	title.TextSize = 10
	title.Parent = frame

	valueLabel = Instance.new("TextLabel")
	valueLabel.BackgroundTransparency = 1
	valueLabel.AnchorPoint = Vector2.new(0.5, 0)
	valueLabel.Position = UDim2.new(0.5, 0, 0, 18)
	valueLabel.Size = UDim2.new(1, 0, 0, 12)
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.Text = "0"
	valueLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
	valueLabel.TextSize = 9
	valueLabel.Parent = frame

	table.insert(characterConnections, player:GetAttributeChangedSignal("Stamina"):Connect(updateBar))
	table.insert(characterConnections, player:GetAttributeChangedSignal("MaxStamina"):Connect(updateBar))
	table.insert(characterConnections, humanoid.HealthChanged:Connect(function(health)
		if health <= 0 and billboard then
			billboard.Enabled = false
		elseif billboard then
			billboard.Enabled = true
		end
	end))

	updateBar()
end

function StaminaBarUI.init()
	if player.Character then
		mountBar(player.Character)
	end

	player.CharacterAdded:Connect(mountBar)
end

return StaminaBarUI
