local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)
local SpellConfig = require(ReplicatedStorage.Shared.SpellConfig)
local SpellUpgradeConfig = require(ReplicatedStorage.Shared.SpellUpgradeConfig)
local WeaponConfig = require(ReplicatedStorage.Shared.WeaponConfig)
local UiCorner = require(script.Parent.UiCorner)

local SpellMenuClient = {}

local GOLD = Color3.fromRGB(214, 176, 72)
local GOLD_DIM = Color3.fromRGB(140, 108, 42)
local PANEL = Color3.fromRGB(24, 20, 34)
local PANEL_LIGHT = Color3.fromRGB(42, 34, 52)
local TEXT = Color3.fromRGB(244, 228, 196)
local TEXT_DIM = Color3.fromRGB(170, 154, 128)
local LOCKED = Color3.fromRGB(110, 110, 110)
local ACCENT = Color3.fromRGB(96, 58, 148)
local ACTIVE_BADGE = Color3.fromRGB(255, 120, 48)

function SpellMenuClient.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local upgradeSpellEvent = ReplicatedStorage:WaitForChild("UpgradeSpell") :: RemoteEvent
	local spellLoadoutUpdatedEvent = ReplicatedStorage:WaitForChild("SpellLoadoutUpdated") :: RemoteEvent
	local profileStateEvent = ReplicatedStorage:WaitForChild("PlayerProfileState") :: RemoteEvent
	local phaseStateEvent = ReplicatedStorage:WaitForChild("PlayerPhaseState") :: RemoteEvent

	local infusedSpellId = ""
	local equippedWeapon = LobbyConfig.STARTER_WEAPON
	local weaponInfusions: { [string]: string } = {}
	local loadoutLocked = false
	local menuOpen = false
	local activeTab = "Collection"
	local walletGold = LobbyConfig.STARTER_GOLD
	local spellLevels: { [string]: number } = {}
	local ownedSpells: { [string]: boolean } = {
		[LobbyConfig.STARTER_ACTIVE_SPELL] = true,
	}
	local currentPhase = "Lobby"

	for _, spell in SpellConfig.getSpellList() do
		spellLevels[spell.id] = 1
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpellMenuUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local menuButton = Instance.new("TextButton")
	menuButton.Name = "SpellsButton"
	menuButton.AnchorPoint = Vector2.new(0, 1)
	menuButton.Size = UDim2.fromOffset(220, 52)
	menuButton.Position = UDim2.new(0.5, 6, 1, -12)
	menuButton.BackgroundColor3 = ACCENT
	menuButton.BorderSizePixel = 0
	menuButton.Font = Enum.Font.GothamBold
	menuButton.Text = "Spells"
	menuButton.TextColor3 = Color3.new(1, 1, 1)
	menuButton.TextSize = 22
	menuButton.Parent = screenGui

	UiCorner.apply(menuButton, 10)

	local panel = Instance.new("Frame")
	panel.Name = "SpellPanel"
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
	title.Text = "Spellbook"
	title.TextColor3 = GOLD
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local statusLabel = Instance.new("TextLabel")
	statusLabel.BackgroundTransparency = 1
	statusLabel.Position = UDim2.fromOffset(16, 40)
	statusLabel.Size = UDim2.new(1, -32, 0, 48)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Text = "Learn spells from grimoires, then upgrade them here."
	statusLabel.TextColor3 = TEXT
	statusLabel.TextSize = 14
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextWrapped = true
	statusLabel.Parent = panel

	local tabBar = Instance.new("Frame")
	tabBar.BackgroundTransparency = 1
	tabBar.Position = UDim2.fromOffset(16, 90)
	tabBar.Size = UDim2.new(1, -32, 0, 34)
	tabBar.Parent = panel

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.Parent = tabBar

	local equipTab = Instance.new("TextButton")
	equipTab.Size = UDim2.fromOffset(120, 32)
	equipTab.BackgroundColor3 = GOLD_DIM
	equipTab.BorderSizePixel = 0
	equipTab.Font = Enum.Font.GothamBold
	equipTab.Text = "Collection"
	equipTab.TextColor3 = TEXT
	equipTab.TextSize = 15
	equipTab.Parent = tabBar

	local upgradeTab = Instance.new("TextButton")
	upgradeTab.Size = UDim2.fromOffset(120, 32)
	upgradeTab.BackgroundColor3 = PANEL_LIGHT
	upgradeTab.BorderSizePixel = 0
	upgradeTab.Font = Enum.Font.GothamBold
	upgradeTab.Text = "Upgrade"
	upgradeTab.TextColor3 = TEXT
	upgradeTab.TextSize = 15
	upgradeTab.Parent = tabBar

	for _, tab in { equipTab, upgradeTab } do
		UiCorner.apply(tab, 8)
	end

	local list = Instance.new("ScrollingFrame")
	list.Name = "SpellList"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(16, 132)
	list.Size = UDim2.new(1, -32, 1, -148)
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

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.Name = "EmptySpells"
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Size = UDim2.new(1, -32, 0, 96)
	emptyLabel.Position = UDim2.fromOffset(16, 148)
	emptyLabel.Font = Enum.Font.Gotham
	emptyLabel.Text = "No spells discovered yet.\nUse grimoires from the chest menu to learn new spells."
	emptyLabel.TextColor3 = TEXT_DIM
	emptyLabel.TextSize = 15
	emptyLabel.TextWrapped = true
	emptyLabel.Visible = false
	emptyLabel.Parent = panel

	local spellButtons: { [string]: TextButton } = {}

	local function getEffectiveDisplayStats(spellId: string)
		local level = spellLevels[spellId] or 1
		return SpellUpgradeConfig.getEffectiveStats(spellId, level)
	end

	local function updateSpellButtons()
		local ownedCount = 0

		for spellId, button in spellButtons do
			local stats = getEffectiveDisplayStats(spellId)
			local level = spellLevels[spellId] or 1
			local owned = ownedSpells[spellId] == true
			button.Visible = owned
			if not owned then
				continue
			end

			ownedCount += 1
			local infused = spellId == (weaponInfusions[equippedWeapon] or infusedSpellId)
			local ultimateTag = if stats.isUltimate then "  ULT" else ""

			if activeTab == "Collection" then
				if infused then
					button.Text =
						`{stats.resolvedName}{ultimateTag}  INFUSED  Lv {level}\n[Press E]  {stats.damageMin}-{stats.damageMax} dmg  |  {stats.staminaCost} ST`
					button.BackgroundColor3 = GOLD_DIM
				else
					button.Text =
						`{stats.resolvedName}{ultimateTag}  Lv {level}\nInfuse at Mira onto a weapon, then press E`
					button.BackgroundColor3 = PANEL_LIGHT
				end
				button.TextColor3 = TEXT
				button.AutoButtonColor = false
			else
				local cost = SpellUpgradeConfig.getUpgradeCost(spellId, level)
				if level >= SpellUpgradeConfig.MAX_LEVEL then
					button.Text =
						`{stats.resolvedName}{ultimateTag}  Lv {level} MAX\n{stats.damageMin}-{stats.damageMax} dmg  |  {stats.staminaCost} ST`
					button.BackgroundColor3 = GOLD_DIM
					button.TextColor3 = TEXT
					button.AutoButtonColor = false
				elseif level >= SpellUpgradeConfig.ULTIMATE_LEVEL - 1 and level < SpellUpgradeConfig.ULTIMATE_LEVEL then
					button.Text =
						`{stats.displayName}  Lv {level} -> ULTIMATE\nUpgrade for {cost} gold`
					button.BackgroundColor3 = PANEL_LIGHT
					button.TextColor3 = if walletGold >= cost and not loadoutLocked then GOLD else LOCKED
					button.AutoButtonColor = walletGold >= cost and not loadoutLocked
				else
					button.Text = `{stats.displayName}  Lv {level} -> {level + 1}\nUpgrade for {cost} gold`
					button.BackgroundColor3 = PANEL_LIGHT
					button.TextColor3 = if walletGold >= cost and not loadoutLocked then TEXT else LOCKED
					button.AutoButtonColor = walletGold >= cost and not loadoutLocked
				end
			end
		end

		emptyLabel.Visible = ownedCount == 0
		list.Visible = ownedCount > 0
	end

	local function updateMenuState()
		local inLobby = currentPhase == "Lobby"
		menuButton.Visible = inLobby or not LobbyConfig.USE_LOBBY
		menuButton.BackgroundColor3 = if loadoutLocked or not inLobby then LOCKED else ACCENT
		menuButton.AutoButtonColor = not loadoutLocked and inLobby

		equipTab.BackgroundColor3 = if activeTab == "Collection" then GOLD_DIM else PANEL_LIGHT
		upgradeTab.BackgroundColor3 = if activeTab == "Upgrade" then GOLD_DIM else PANEL_LIGHT

		local equippedInfusion = weaponInfusions[equippedWeapon] or infusedSpellId
		local weaponName = WeaponConfig.getWeapon(equippedWeapon).displayName
		local infusedName = if equippedInfusion ~= ""
			then getEffectiveDisplayStats(equippedInfusion).resolvedName
			else "None"

		if loadoutLocked or not inLobby then
			statusLabel.Text = "Spell loadout locked during a dungeon run."
		elseif activeTab == "Collection" then
			statusLabel.Text =
				`{weaponName} infusion: {infusedName}  |  Press E while wielding it.\nGold: {walletGold}`
		else
			statusLabel.Text =
				`Upgrade discovered spells. Ultimates unlock at level {SpellUpgradeConfig.ULTIMATE_LEVEL}. Wallet: {walletGold}`
		end

		updateSpellButtons()
	end

	for index, stats in SpellConfig.getSpellList() do
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

		local badge = Instance.new("Frame")
		badge.Size = UDim2.fromOffset(6, 78)
		badge.BorderSizePixel = 0
		badge.BackgroundColor3 = ACTIVE_BADGE
		badge.Parent = button

		UiCorner.apply(badge, 8)

		button.MouseButton1Click:Connect(function()
			if loadoutLocked or currentPhase ~= "Lobby" or ownedSpells[stats.id] ~= true then
				return
			end

			if activeTab == "Upgrade" then
				upgradeSpellEvent:FireServer(stats.id)
			end
		end)

		spellButtons[stats.id] = button
	end

	equipTab.MouseButton1Click:Connect(function()
		activeTab = "Collection"
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

	spellLoadoutUpdatedEvent.OnClientEvent:Connect(function(activeInfusion: string, locked: boolean)
		if typeof(activeInfusion) == "string" then
			infusedSpellId = activeInfusion
		end
		loadoutLocked = locked == true
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
		if typeof(snapshot.weaponInfusions) == "table" then
			weaponInfusions = {}
			for weaponId, spellId in snapshot.weaponInfusions do
				if typeof(spellId) == "string" and spellId ~= "" then
					weaponInfusions[weaponId] = spellId
				end
			end
		end
		if typeof(snapshot.infusedSpellId) == "string" then
			infusedSpellId = snapshot.infusedSpellId
		end
		if typeof(snapshot.spellLevels) == "table" then
			for spellId, level in snapshot.spellLevels do
				if typeof(level) == "number" then
					spellLevels[spellId] = level
				end
			end
		end
		if typeof(snapshot.ownedSpells) == "table" then
			for spellId, owned in snapshot.ownedSpells do
				if typeof(owned) == "boolean" then
					ownedSpells[spellId] = owned
				end
			end
		elseif typeof(snapshot.unlockedSpells) == "table" then
			for spellId, unlocked in snapshot.unlockedSpells do
				if typeof(unlocked) == "boolean" then
					ownedSpells[spellId] = unlocked
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

	SpellMenuClient._openToTab = function(tab: string)
		if loadoutLocked or currentPhase ~= "Lobby" then
			return
		end

		if tab == "Collection" or tab == "Upgrade" or tab == "Equip" then
			activeTab = if tab == "Equip" then "Collection" else tab
		end

		menuOpen = true
		panel.Visible = true
		updateMenuState()
	end

	updateMenuState()
end

function SpellMenuClient.openToTab(tab: string)
	if SpellMenuClient._openToTab then
		SpellMenuClient._openToTab(tab)
	end
end

return SpellMenuClient
