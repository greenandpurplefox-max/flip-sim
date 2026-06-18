local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)
local TreasureConfig = require(ReplicatedStorage.Shared.TreasureConfig)
local WeaponConfig = require(ReplicatedStorage.Shared.WeaponConfig)
local WeaponUpgradeConfig = require(ReplicatedStorage.Shared.WeaponUpgradeConfig)
local TreasureChestPreview = require(script.Parent.TreasureChestPreview)
local GrimoireOpenClient = require(script.Parent.GrimoireOpenClient)
local UiCorner = require(script.Parent.UiCorner)

local WeaponMenuClient = {}

local GOLD = Color3.fromRGB(214, 176, 72)
local GOLD_DIM = Color3.fromRGB(140, 108, 42)
local PANEL = Color3.fromRGB(28, 22, 18)
local PANEL_LIGHT = Color3.fromRGB(48, 38, 32)
local TEXT = Color3.fromRGB(244, 228, 196)
local TEXT_DIM = Color3.fromRGB(170, 154, 128)
local LOCKED = Color3.fromRGB(110, 110, 110)
local ACCENT = Color3.fromRGB(58, 92, 148)
local GRIMOIRE_ACCENT = Color3.fromRGB(120, 72, 180)

type ChestEntry = {
	tierId: string,
	roomDepth: number,
	tierName: string,
}

function WeaponMenuClient.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local equipWeaponEvent = ReplicatedStorage:WaitForChild("EquipWeapon") :: RemoteEvent
	local upgradeWeaponEvent = ReplicatedStorage:WaitForChild("UpgradeWeapon") :: RemoteEvent
	local unlockWeaponEvent = ReplicatedStorage:WaitForChild("UnlockWeapon") :: RemoteEvent
	local loadoutUpdatedEvent = ReplicatedStorage:WaitForChild("LoadoutUpdated") :: RemoteEvent
	local profileStateEvent = ReplicatedStorage:WaitForChild("PlayerProfileState") :: RemoteEvent
	local phaseStateEvent = ReplicatedStorage:WaitForChild("PlayerPhaseState") :: RemoteEvent
	local chestStateEvent = ReplicatedStorage:WaitForChild("TreasureChestState") :: RemoteEvent
	local openChestEvent = ReplicatedStorage:WaitForChild("OpenTreasureChest") :: RemoteEvent
	local chestOpenedEvent = ReplicatedStorage:WaitForChild("TreasureChestOpened") :: RemoteEvent
	local grimoireUsedEvent = ReplicatedStorage:WaitForChild("GrimoireUsed") :: RemoteEvent

	local equippedWeapon = WeaponConfig.DEFAULT_WEAPON
	local loadoutLocked = false
	local menuOpen = false
	local activeTab = "Equip"
	local walletGold = LobbyConfig.STARTER_GOLD
	local lobbyChests: { ChestEntry } = {}
	local grimoireCount = 0
	local weaponLevels: { [string]: number } = {}
	local unlockedWeapons: { [string]: boolean } = {
		[LobbyConfig.STARTER_WEAPON] = true,
	}
	local currentPhase = "Lobby"
	local inTrainingZone = false

	for _, weapon in WeaponConfig.getWeaponList() do
		weaponLevels[weapon.id] = 1
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WeaponMenuUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local menuButton = Instance.new("TextButton")
	menuButton.Name = "WeaponsButton"
	menuButton.AnchorPoint = Vector2.new(1, 1)
	menuButton.Size = UDim2.fromOffset(220, 52)
	menuButton.Position = UDim2.new(0.5, -6, 1, -12)
	menuButton.BackgroundColor3 = ACCENT
	menuButton.BorderSizePixel = 0
	menuButton.Font = Enum.Font.GothamBold
	menuButton.Text = "Weapons"
	menuButton.TextColor3 = Color3.new(1, 1, 1)
	menuButton.TextSize = 22
	menuButton.Parent = screenGui

	UiCorner.apply(menuButton, 10)

	local panel = Instance.new("Frame")
	panel.Name = "WeaponPanel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -70)
	panel.Size = UDim2.fromOffset(360, 360)
	panel.BackgroundColor3 = PANEL
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screenGui

	UiCorner.apply(panel, 12)

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
	equipTab.Size = UDim2.fromOffset(100, 32)
	equipTab.BackgroundColor3 = GOLD_DIM
	equipTab.BorderSizePixel = 0
	equipTab.Font = Enum.Font.GothamBold
	equipTab.Text = "Equip"
	equipTab.TextColor3 = TEXT
	equipTab.TextSize = 15
	equipTab.Parent = tabBar

	local upgradeTab = Instance.new("TextButton")
	upgradeTab.Size = UDim2.fromOffset(100, 32)
	upgradeTab.BackgroundColor3 = PANEL_LIGHT
	upgradeTab.BorderSizePixel = 0
	upgradeTab.Font = Enum.Font.GothamBold
	upgradeTab.Text = "Upgrade"
	upgradeTab.TextColor3 = TEXT
	upgradeTab.TextSize = 15
	upgradeTab.Parent = tabBar

	local chestsTab = Instance.new("TextButton")
	chestsTab.Size = UDim2.fromOffset(100, 32)
	chestsTab.BackgroundColor3 = PANEL_LIGHT
	chestsTab.BorderSizePixel = 0
	chestsTab.Font = Enum.Font.GothamBold
	chestsTab.Text = "Chests"
	chestsTab.TextColor3 = TEXT
	chestsTab.TextSize = 15
	chestsTab.Parent = tabBar

	for _, tab in { equipTab, upgradeTab, chestsTab } do
		UiCorner.apply(tab, 8)
	end

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

	local chestList = Instance.new("ScrollingFrame")
	chestList.Name = "ChestList"
	chestList.BackgroundTransparency = 1
	chestList.BorderSizePixel = 0
	chestList.Position = UDim2.fromOffset(16, 120)
	chestList.Size = UDim2.new(1, -32, 1, -136)
	chestList.CanvasSize = UDim2.fromOffset(0, 0)
	chestList.ScrollBarThickness = 6
	chestList.Visible = false
	chestList.Parent = panel

	local chestLayout = Instance.new("UIListLayout")
	chestLayout.Padding = UDim.new(0, 10)
	chestLayout.SortOrder = Enum.SortOrder.LayoutOrder
	chestLayout.Parent = chestList

	chestLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		chestList.CanvasSize = UDim2.fromOffset(0, chestLayout.AbsoluteContentSize.Y + 8)
	end)

	local emptyChestLabel = Instance.new("TextLabel")
	emptyChestLabel.Name = "EmptyChests"
	emptyChestLabel.BackgroundTransparency = 1
	emptyChestLabel.Size = UDim2.new(1, -32, 0, 80)
	emptyChestLabel.Position = UDim2.fromOffset(16, 200)
	emptyChestLabel.Font = Enum.Font.Gotham
	emptyChestLabel.Text = "No chests or grimoires yet.\nClear dungeon rooms for treasure and grimoires."
	emptyChestLabel.TextColor3 = TEXT_DIM
	emptyChestLabel.TextSize = 15
	emptyChestLabel.TextWrapped = true
	emptyChestLabel.Visible = false
	emptyChestLabel.Parent = panel

	local weaponButtons: { [string]: TextButton } = {}

	local function getEffectiveDisplayStats(weaponId: string)
		local level = weaponLevels[weaponId] or 1
		return WeaponUpgradeConfig.getEffectiveStats(weaponId, level)
	end

	local function getChestTabCount(): number
		return #lobbyChests + grimoireCount
	end

	local function renderChestList()
		for _, child in chestList:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		local totalEntries = getChestTabCount()
		emptyChestLabel.Visible = activeTab == "Chests" and totalEntries == 0
		chestList.Visible = activeTab == "Chests" and totalEntries > 0

		local layoutOrder = 0

		for index, chest in lobbyChests do
			layoutOrder += 1
			local tier = TreasureConfig.getTier(chest.tierId)
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -4, 0, 96)
			row.BackgroundColor3 = PANEL_LIGHT
			row.BorderSizePixel = 0
			row.LayoutOrder = layoutOrder
			row.Parent = chestList

			UiCorner.apply(row, 8)

			local previewHost = Instance.new("Frame")
			previewHost.BackgroundTransparency = 1
			previewHost.Position = UDim2.fromOffset(8, 8)
			previewHost.Size = UDim2.fromOffset(80, 80)
			previewHost.Parent = row
			TreasureChestPreview.mount(previewHost, chest.tierId, 80)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.BackgroundTransparency = 1
			nameLabel.Position = UDim2.fromOffset(96, 14)
			nameLabel.Size = UDim2.new(1, -220, 0, 24)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.Text = chest.tierName
			nameLabel.TextColor3 = TEXT
			nameLabel.TextSize = 17
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = row

			local depthLabel = Instance.new("TextLabel")
			depthLabel.BackgroundTransparency = 1
			depthLabel.Position = UDim2.fromOffset(96, 40)
			depthLabel.Size = UDim2.new(1, -220, 0, 20)
			depthLabel.Font = Enum.Font.Gotham
			depthLabel.Text = `Depth {chest.roomDepth}`
			depthLabel.TextColor3 = TEXT_DIM
			depthLabel.TextSize = 14
			depthLabel.TextXAlignment = Enum.TextXAlignment.Left
			depthLabel.Parent = row

			local openButton = Instance.new("TextButton")
			openButton.AnchorPoint = Vector2.new(1, 0.5)
			openButton.Position = UDim2.new(1, -8, 0.5, 0)
			openButton.Size = UDim2.fromOffset(96, 40)
			openButton.BackgroundColor3 = tier.trimColor
			openButton.BorderSizePixel = 0
			openButton.Font = Enum.Font.GothamBold
			openButton.Text = "Open"
			openButton.TextColor3 = Color3.new(0.08, 0.06, 0.05)
			openButton.TextSize = 16
			openButton.Parent = row

			UiCorner.apply(openButton, 8)

			openButton.MouseButton1Click:Connect(function()
				if loadoutLocked or currentPhase ~= "Lobby" then
					return
				end
				openChestEvent:FireServer(index)
			end)
		end

		for grimoireIndex = 1, grimoireCount do
			layoutOrder += 1
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -4, 0, 96)
			row.BackgroundColor3 = PANEL_LIGHT
			row.BorderSizePixel = 0
			row.LayoutOrder = layoutOrder
			row.Parent = chestList

			UiCorner.apply(row, 8)

			local previewHost = Instance.new("Frame")
			previewHost.BackgroundTransparency = 1
			previewHost.Position = UDim2.fromOffset(8, 8)
			previewHost.Size = UDim2.fromOffset(80, 80)
			previewHost.Parent = row
			GrimoireOpenClient.mountPreview(previewHost, 80)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.BackgroundTransparency = 1
			nameLabel.Position = UDim2.fromOffset(96, 14)
			nameLabel.Size = UDim2.new(1, -220, 0, 24)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.Text = "Grimoire"
			nameLabel.TextColor3 = Color3.fromRGB(220, 180, 255)
			nameLabel.TextSize = 17
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = row

			local detailLabel = Instance.new("TextLabel")
			detailLabel.BackgroundTransparency = 1
			detailLabel.Position = UDim2.fromOffset(96, 40)
			detailLabel.Size = UDim2.new(1, -220, 0, 36)
			detailLabel.Font = Enum.Font.Gotham
			detailLabel.Text = "Open to learn a random spell."
			detailLabel.TextColor3 = TEXT_DIM
			detailLabel.TextSize = 14
			detailLabel.TextWrapped = true
			detailLabel.TextXAlignment = Enum.TextXAlignment.Left
			detailLabel.Parent = row

			local openButton = Instance.new("TextButton")
			openButton.AnchorPoint = Vector2.new(1, 0.5)
			openButton.Position = UDim2.new(1, -8, 0.5, 0)
			openButton.Size = UDim2.fromOffset(96, 40)
			openButton.BackgroundColor3 = GRIMOIRE_ACCENT
			openButton.BorderSizePixel = 0
			openButton.Font = Enum.Font.GothamBold
			openButton.Text = "Open"
			openButton.TextColor3 = Color3.new(1, 1, 1)
			openButton.TextSize = 16
			openButton.Parent = row

			UiCorner.apply(openButton, 8)

			openButton.MouseButton1Click:Connect(function()
				if loadoutLocked or currentPhase ~= "Lobby" or grimoireCount <= 0 then
					return
				end

				panel.Visible = false
				menuOpen = false
				GrimoireOpenClient.open(function()
					if currentPhase == "Lobby" then
						activeTab = "Chests"
						menuOpen = true
						panel.Visible = true
					end
					updateMenuState()
				end)
			end)
		end
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

	local function showLobbyMenus(): boolean
		return currentPhase == "Lobby" and not inTrainingZone
	end

	local function updateMenuState()
		local inLobby = showLobbyMenus()
		menuButton.Visible = inLobby or not LobbyConfig.USE_LOBBY
		menuButton.BackgroundColor3 = if loadoutLocked or not inLobby then LOCKED else ACCENT
		menuButton.AutoButtonColor = not loadoutLocked and inLobby

		equipTab.BackgroundColor3 = if activeTab == "Equip" then GOLD_DIM else PANEL_LIGHT
		upgradeTab.BackgroundColor3 = if activeTab == "Upgrade" then GOLD_DIM else PANEL_LIGHT
		chestsTab.BackgroundColor3 = if activeTab == "Chests" then GOLD_DIM else PANEL_LIGHT
		chestsTab.Text = if getChestTabCount() > 0 then `Chests ({getChestTabCount()})` else "Chests"

		list.Visible = activeTab ~= "Chests"
		renderChestList()

		if loadoutLocked or not inLobby then
			statusLabel.Text = "Loadout locked during a dungeon run."
		elseif activeTab == "Equip" then
			statusLabel.Text = `Equipped: {WeaponConfig.getWeapon(equippedWeapon).displayName}  |  Gold: {walletGold}`
		elseif activeTab == "Upgrade" then
			statusLabel.Text = `Spend gold to upgrade weapons. Wallet: {walletGold}`
		elseif activeTab == "Chests" then
			if getChestTabCount() > 0 then
				statusLabel.Text =
					`{#lobbyChests} chest(s), {grimoireCount} grimoire(s). Open them here to claim rewards.`
			else
				statusLabel.Text = "Find chests and grimoires in the dungeon, then open them here."
			end
		else
			statusLabel.Text = "Find chests in the dungeon, then open them here."
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

		UiCorner.apply(button, 8)

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

	chestsTab.MouseButton1Click:Connect(function()
		activeTab = "Chests"
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
		if typeof(snapshot.grimoireCount) == "number" then
			grimoireCount = snapshot.grimoireCount
		end

		updateMenuState()
	end)

	phaseStateEvent.OnClientEvent:Connect(function(phase: string)
		if phase == "Lobby" or phase == "Dungeon" then
			currentPhase = phase
			if phase == "Dungeon" then
				menuOpen = false
				panel.Visible = false
			elseif showLobbyMenus() and (#lobbyChests > 0 or grimoireCount > 0) then
				activeTab = "Chests"
				menuOpen = true
				panel.Visible = true
			end
			updateMenuState()
		end
	end)

	player:GetAttributeChangedSignal("InTrainingZone"):Connect(function()
		inTrainingZone = player:GetAttribute("InTrainingZone") == true
		if inTrainingZone then
			menuOpen = false
			panel.Visible = false
		end
		updateMenuState()
	end)

	inTrainingZone = player:GetAttribute("InTrainingZone") == true

	chestStateEvent.OnClientEvent:Connect(function(payload)
		lobbyChests = {}
		if typeof(payload) == "table" then
			for _, entry in payload do
				if typeof(entry) == "table" and typeof(entry.tierId) == "string" then
					table.insert(lobbyChests, {
						tierId = entry.tierId,
						roomDepth = if typeof(entry.roomDepth) == "number" then entry.roomDepth else 1,
						tierName = if typeof(entry.tierName) == "string"
							then entry.tierName
							else TreasureConfig.getTier(entry.tierId).displayName,
					})
				end
			end
		end

		if showLobbyMenus() and getChestTabCount() > 0 then
			activeTab = "Chests"
			menuOpen = true
			panel.Visible = true
		end
		updateMenuState()
	end)

	chestOpenedEvent.OnClientEvent:Connect(function(loot)
		if typeof(loot) == "table" and typeof(loot.gold) == "number" then
			local tierName = if typeof(loot.tierName) == "string" then loot.tierName else "Chest"
			local message = `{tierName} opened for {loot.gold} gold!`
			if loot.grimoireDropped == true then
				message ..= " You found a grimoire!"
			end
			statusLabel.Text = message
		end
		if typeof(loot) == "table" and typeof(loot.grimoireCount) == "number" then
			grimoireCount = loot.grimoireCount
		end
		updateMenuState()
	end)

	grimoireUsedEvent.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end

		if typeof(payload.grimoireCount) == "number" then
			grimoireCount = payload.grimoireCount
		end
		if typeof(payload.message) == "string" then
			statusLabel.Text = payload.message
		end
		updateMenuState()
	end)

	WeaponMenuClient._openToTab = function(tab: string)
		if loadoutLocked or not showLobbyMenus() then
			return
		end

		if tab == "Equip" or tab == "Upgrade" or tab == "Chests" then
			activeTab = tab
		end

		menuOpen = true
		panel.Visible = true
		updateMenuState()
	end

	updateMenuState()
end

function WeaponMenuClient.openToTab(tab: string)
	if WeaponMenuClient._openToTab then
		WeaponMenuClient._openToTab(tab)
	end
end

return WeaponMenuClient
