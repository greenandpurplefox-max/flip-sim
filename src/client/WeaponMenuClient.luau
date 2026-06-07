local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponConfig = require(ReplicatedStorage.Shared.WeaponConfig)

local WeaponMenuClient = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GOLD = Color3.fromRGB(214, 176, 72)
local GOLD_DIM = Color3.fromRGB(140, 108, 42)
local PANEL = Color3.fromRGB(28, 22, 18)
local PANEL_LIGHT = Color3.fromRGB(48, 38, 32)
local TEXT = Color3.fromRGB(244, 228, 196)
local LOCKED = Color3.fromRGB(110, 110, 110)

function WeaponMenuClient.init()
	local equipWeaponEvent = ReplicatedStorage:WaitForChild("EquipWeapon") :: RemoteEvent
	local loadoutUpdatedEvent = ReplicatedStorage:WaitForChild("LoadoutUpdated") :: RemoteEvent
	local waveStateEvent = ReplicatedStorage:WaitForChild("WaveState") :: RemoteEvent

	local equippedWeapon = WeaponConfig.DEFAULT_WEAPON
	local loadoutLocked = false
	local menuOpen = false

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WeaponMenuUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local menuButton = Instance.new("TextButton")
	menuButton.Name = "WeaponsButton"
	menuButton.Size = UDim2.fromOffset(220, 52)
	menuButton.Position = UDim2.new(0.5, -110, 0, 76)
	menuButton.BackgroundColor3 = Color3.fromRGB(58, 92, 148)
	menuButton.BorderSizePixel = 0
	menuButton.Font = Enum.Font.GothamBold
	menuButton.Text = "Weapons"
	menuButton.TextColor3 = Color3.new(1, 1, 1)
	menuButton.TextSize = 22
	menuButton.Parent = screenGui

	local menuCorner = Instance.new("UICorner")
	menuCorner.CornerRadius = UDim.new(0, 10)
	menuCorner.Parent = menuButton

	local menuStroke = Instance.new("UIStroke")
	menuStroke.Color = Color3.fromRGB(34, 58, 92)
	menuStroke.Thickness = 2
	menuStroke.Parent = menuButton

	local panel = Instance.new("Frame")
	panel.Name = "WeaponPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.new(0.5, 0, 0, 136)
	panel.Size = UDim2.fromOffset(320, 280)
	panel.BackgroundColor3 = PANEL
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = GOLD_DIM
	panelStroke.Thickness = 2
	panelStroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(16, 12)
	title.Size = UDim2.new(1, -32, 0, 28)
	title.Font = Enum.Font.GothamBold
	title.Text = "Choose Your Weapon"
	title.TextColor3 = GOLD
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.BackgroundTransparency = 1
	statusLabel.Position = UDim2.fromOffset(16, 40)
	statusLabel.Size = UDim2.new(1, -32, 0, 20)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Text = "Change loadout before starting a wave."
	statusLabel.TextColor3 = TEXT
	statusLabel.TextSize = 14
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextWrapped = true
	statusLabel.Parent = panel

	local list = Instance.new("Frame")
	list.Name = "WeaponList"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromOffset(16, 72)
	list.Size = UDim2.new(1, -32, 1, -88)
	list.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local weaponButtons: { [string]: TextButton } = {}

	local function updateMenuState()
		local statusText = if loadoutLocked
			then "Loadout locked during an active wave."
			else `Equipped: {WeaponConfig.getWeapon(equippedWeapon).displayName}`

		statusLabel.Text = statusText
		menuButton.BackgroundColor3 = if loadoutLocked then LOCKED else Color3.fromRGB(58, 92, 148)
		menuButton.AutoButtonColor = not loadoutLocked

		for weaponId, button in weaponButtons do
			local stats = WeaponConfig.getWeapon(weaponId)
			local selected = weaponId == equippedWeapon
			button.Text = `{stats.displayName}\n{stats.damageMin}-{stats.damageMax} dmg  |  {stats.cooldown}s`
			button.BackgroundColor3 = if selected then GOLD_DIM else PANEL_LIGHT
			button.TextColor3 = if loadoutLocked then LOCKED else TEXT
			button.AutoButtonColor = not loadoutLocked
		end
	end

	for index, stats in WeaponConfig.getWeaponList() do
		local button = Instance.new("TextButton")
		button.Name = `{stats.id}Button`
		button.Size = UDim2.new(1, 0, 0, 72)
		button.BackgroundColor3 = PANEL_LIGHT
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.TextSize = 16
		button.TextWrapped = true
		button.LayoutOrder = index
		button.Parent = list

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = button

		button.MouseButton1Click:Connect(function()
			if loadoutLocked then
				return
			end

			equipWeaponEvent:FireServer(stats.id)
		end)

		weaponButtons[stats.id] = button
	end

	local function setLoadoutState(weaponId: string, locked: boolean)
		equippedWeapon = weaponId
		loadoutLocked = locked
		updateMenuState()
	end

	menuButton.MouseButton1Click:Connect(function()
		if loadoutLocked then
			menuOpen = false
			panel.Visible = false
			return
		end

		menuOpen = not menuOpen
		panel.Visible = menuOpen
	end)

	loadoutUpdatedEvent.OnClientEvent:Connect(function(weaponId: string, locked: boolean)
		setLoadoutState(weaponId, locked)
	end)

	waveStateEvent.OnClientEvent:Connect(function(_inProgress, _remaining, _total, _wave, _status, locked: boolean)
		loadoutLocked = locked
		if locked then
			menuOpen = false
			panel.Visible = false
		end
		updateMenuState()
	end)

	updateMenuState()
end

return WeaponMenuClient
