local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)
local WeaponConfig = require(ReplicatedStorage.Shared.WeaponConfig)
local WeaponUpgradeConfig = require(ReplicatedStorage.Shared.WeaponUpgradeConfig)

local WeaponMenuClient = {}

local GOLD = Color3.fromRGB(214, 176, 72)
local GOLD_DIM = Color3.fromRGB(140, 108, 42)
local PANEL = Color3.fromRGB(28, 22, 18)
local PANEL_LIGHT = Color3.fromRGB(48, 38, 32)
local TEXT = Color3.fromRGB(244, 228, 196)
local LOCKED = Color3.fromRGB(110, 110, 110)
local ACCENT = Color3.fromRGB(58, 92, 148)

function WeaponMenuClient.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local equipWeaponEvent = ReplicatedStorage:WaitForChild("EquipWeapon") :: RemoteEvent
	local upgradeWeaponEvent = ReplicatedStorage:WaitForChild("UpgradeWeapon") :: RemoteEvent
	local unlockWeaponEvent = ReplicatedStorage:WaitForChild("UnlockWeapon") :: RemoteEvent
	local loadoutUpdatedEvent = ReplicatedStorage:WaitForChild("LoadoutUpdated") :: RemoteEvent
	local profileStateEvent = ReplicatedStorage:WaitForChild("PlayerProfileState") :: RemoteEvent
	local phaseStateEvent = ReplicatedStorage:WaitForChild("PlayerPhaseState") :: RemoteEvent

	local equippedWeapon = WeaponConfig.DEFAULT_WEAPON
	local loadoutLocked = false
	local menuOpen = false
	local activeTab = "Equip"
	local walletGold = LobbyConfig.STARTER_GOLD
	local weaponLevels: { [string]: number } = {}
	local unlockedWeapons: { [string]: boolean } = {
		[LobbyConfig.STARTER_WEAPON] = true,
	}
	local currentPhase = "Lobby"

	for _, weapon in WeaponConfig.getWeaponList() do
		weaponLevels[weapon.id] = 1
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WeaponMenuUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local menuButton = Instance.new("TextButton")
	menuButton.Name = "WeaponsButton"
	menuButton.Size = UDim2.fromOffset(220, 52)
	menuButton.Position = UDim2.new(0.5, -110, 0, 76)
	menuButton.BackgroundColor3 = ACCENT
	menuButton.BorderSizePixel = 0
	menuButton.Font = Enum.Font.GothamBold
	menuButton.Text = "Weapons"
	menuButton.TextColor3 = Color3.new(1, 1, 1)
	menuButton.TextSize = 22
	menuButton.Parent = screenGui

	local menuCorner = Instance.new("UICorner")
	menuCorner.CornerRadius = UDim.new(0, 10)
	menuCorner.Parent = menuButton

	local panel = Instance.new("Frame")
	panel.Name = "WeaponPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.new(0.5, 0, 0, 136)
	panel.Size = UDim2.fromOffset(360, 360)
	panel.BackgroundColor3 = PANEL
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(16, 12)
	title.Size = UDim2.new(1, -32, 0, 28)
	title.Font = Enum.Font.GothamBold
	title.Text = "Blacksmith"
	title.TextColor3 = GOLD
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local statusLabel = Instance.new("TextLabel")
	statusLabel.BackgroundTransparency = 1
	statusLabel.Position = UDim2.fromOffset(16, 40)
	statusLabel.Size = UDim2.new(1, -32, 0, 36)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Text = "Equip and upgrade your weapons in the lobby."
	statusLabel.TextColor3 = TEXT
	statusLabel.TextSize = 14
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextWrapped = true
	statusLabel.Parent = panel

	local tabBar = Instance.new("Frame")
	tabBar.BackgroundTransparency = 1
	tabBar.Position = UDim2.fromOffset(16, 78)
	tabBar.Size = UDim2.new(1, -32, 0, 34)
	tabBar.Parent = panel

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.Parent = tabBar

	local equipTab = Instance.new("TextButton")
	equipTab.Size = UDim2.fromOffset(110, 32)
	equipTab.BackgroundColor3 = GOLD_DIM
	equipTab.BorderSizePixel = 0
	equipTab.Font = Enum.Font.GothamBold
	equipTab.Text = "Equip"
	equipTab.TextColor3 = TEXT
	equipTab.TextSize = 16
	equipTab.Parent = tabBar

	local upgradeTab = Instance.new("TextButton")
	upgradeTab.Size = UDim2.fromOffset(110, 32)
	upgradeTab.BackgroundColor3 = PANEL_LIGHT
	upgradeTab.BorderSizePixel = 0
	upgradeTab.Font = Enum.Font.GothamBold
	upgradeTab.Text = "Upgrade"
	upgradeTab.TextColor3 = TEXT
	upgradeTab.TextSize = 16
	upgradeTab.Parent = tabBar

	local list = Instance.new("ScrollingFrame")
	list.Name = "WeaponList"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(16, 120)
	list.Size = UDim2.new(1, -32, 1, -136)
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.ScrollBarThickness = 6
	list.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
	end)

	local weaponButtons: { [string]: TextButton } = {}

	local function getEffectiveDisplayStats(weaponId: string)
		local level = weaponLevels[weaponId] or 1
		return WeaponUpgradeConfig.getEffectiveStats(weaponId, level)
	end

	local function updateWeaponButtons()
		for weaponId, button in weaponButtons do
			local stats = getEffectiveDisplayStats(weaponId)
			local level = weaponLevels[weaponId] or 1
			local unlocked = unlockedWeapons[weaponId] == true
			local selected = weaponId == equippedWeapon

			if activeTab == "Equip" then
				if unlocked then
					button.Text = `{stats.displayName}  Lv {level}\n{stats.damageMin}-{stats.damageMax} dmg  |  {stats.cooldown}s`
					button.BackgroundColor3 = if selected then GOLD_DIM else PANEL_LIGHT
					button.TextColor3 = if loadoutLocked then LOCKED else TEXT
					button.AutoButtonColor = not loadoutLocked
				else
					local cost = WeaponUpgradeConfig.getUnlockCost(weaponId)
					button.Text = `{stats.displayName}  LOCKED\nUnlock for {cost} gold`
					button.BackgroundColor3 = PANEL_LIGHT
					button.TextColor3 = if walletGold >= cost and not loadoutLocked then GOLD else LOCKED
					button.AutoButtonColor = walletGold >= cost and not loadoutLocked
				end
			else
				if unlocked then
					local cost = WeaponUpgradeConfig.getUpgradeCost(weaponId, level)
					if level >= WeaponUpgradeConfig.MAX_LEVEL then
						button.Text = `{stats.displayName}  Lv {level} MAX\n{stats.damageMin}-{stats.damageMax} dmg`
						button.BackgroundColor3 = GOLD_DIM
						button.TextColor3 = TEXT
						button.AutoButtonColor = false
					else
						button.Text = `{stats.displayName}  Lv {level} -> {level + 1}\nUpgrade for {cost} gold`
						button.BackgroundColor3 = PANEL_LIGHT
						button.TextColor3 = if walletGold >= cost and not loadoutLocked then TEXT else LOCKED
						button.AutoButtonColor = walletGold >= cost and not loadoutLocked
					end
				else
					local cost = WeaponUpgradeConfig.getUnlockCost(weaponId)
					button.Text = `{stats.displayName}  LOCKED\nUnlock for {cost} gold`
					button.BackgroundColor3 = PANEL_LIGHT
					button.TextColor3 = if walletGold >= cost and not loadoutLocked then GOLD else LOCKED
					button.AutoButtonColor = walletGold >= cost and not loadoutLocked
				end
			end
		end
	end

	local function updateMenuState()
		local inLobby = currentPhase == "Lobby"
		menuButton.Visible = inLobby or not LobbyConfig.USE_LOBBY
		menuButton.BackgroundColor3 = if loadoutLocked or not inLobby then LOCKED else ACCENT
		menuButton.AutoButtonColor = not loadoutLocked and inLobby

		equipTab.BackgroundColor3 = if activeTab == "Equip" then GOLD_DIM else PANEL_LIGHT
		upgradeTab.BackgroundColor3 = if activeTab == "Upgrade" then GOLD_DIM else PANEL_LIGHT

		if loadoutLocked or not inLobby then
			statusLabel.Text = "Loadout locked during a dungeon run."
		elseif activeTab == "Equip" then
			statusLabel.Text = `Equipped: {WeaponConfig.getWeapon(equippedWeapon).displayName}  |  Gold: {walletGold}`
		else
			statusLabel.Text = `Spend gold to upgrade weapons. Wallet: {walletGold}`
		end

		updateWeaponButtons()
	end

	for index, stats in WeaponConfig.getWeaponList() do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -4, 0, 78)
		button.BackgroundColor3 = PANEL_LIGHT
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.TextSize = 15
		button.TextWrapped = true
		button.LayoutOrder = index
		button.Parent = list

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = button

		button.MouseButton1Click:Connect(function()
			if loadoutLocked or currentPhase ~= "Lobby" then
				return
			end

			local unlocked = unlockedWeapons[stats.id] == true
			if activeTab == "Equip" then
				if unlocked then
					equipWeaponEvent:FireServer(stats.id)
				else
					unlockWeaponEvent:FireServer(stats.id)
				end
			else
				if unlocked then
					upgradeWeaponEvent:FireServer(stats.id)
				else
					unlockWeaponEvent:FireServer(stats.id)
				end
			end
		end)

		weaponButtons[stats.id] = button
	end

	equipTab.MouseButton1Click:Connect(function()
		activeTab = "Equip"
		updateMenuState()
	end)

	upgradeTab.MouseButton1Click:Connect(function()
		activeTab = "Upgrade"
		updateMenuState()
	end)

	menuButton.MouseButton1Click:Connect(function()
		if loadoutLocked or currentPhase ~= "Lobby" then
			menuOpen = false
			panel.Visible = false
			return
		end

		menuOpen = not menuOpen
		panel.Visible = menuOpen
	end)

	loadoutUpdatedEvent.OnClientEvent:Connect(function(weaponId: string, locked: boolean)
		equippedWeapon = weaponId
		loadoutLocked = locked
		if locked then
			menuOpen = false
			panel.Visible = false
		end
		updateMenuState()
	end)

	profileStateEvent.OnClientEvent:Connect(function(snapshot)
		if typeof(snapshot) ~= "table" then
			return
		end

		if typeof(snapshot.gold) == "number" then
			walletGold = snapshot.gold
		end
		if typeof(snapshot.equippedWeapon) == "string" then
			equippedWeapon = snapshot.equippedWeapon
		end
		if typeof(snapshot.weaponLevels) == "table" then
			for weaponId, level in snapshot.weaponLevels do
				if typeof(level) == "number" then
					weaponLevels[weaponId] = level
				end
			end
		end
		if typeof(snapshot.unlockedWeapons) == "table" then
			for weaponId, unlocked in snapshot.unlockedWeapons do
				if typeof(unlocked) == "boolean" then
					unlockedWeapons[weaponId] = unlocked
				end
			end
		end

		updateMenuState()
	end)

	phaseStateEvent.OnClientEvent:Connect(function(phase: string)
		if phase == "Lobby" or phase == "Dungeon" then
			currentPhase = phase
			if phase == "Dungeon" then
				menuOpen = false
				panel.Visible = false
			end
			updateMenuState()
		end
	end)

	updateMenuState()
end

return WeaponMenuClient
