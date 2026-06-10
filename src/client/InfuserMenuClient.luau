local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local InfuserConfig = require(ReplicatedStorage.Shared.InfuserConfig)
local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)
local SpellConfig = require(ReplicatedStorage.Shared.SpellConfig)
local SpellUpgradeConfig = require(ReplicatedStorage.Shared.SpellUpgradeConfig)
local WeaponConfig = require(ReplicatedStorage.Shared.WeaponConfig)

local InfuserMenuClient = {}

local GOLD = Color3.fromRGB(214, 176, 72)
local GOLD_DIM = Color3.fromRGB(140, 108, 42)
local PANEL = Color3.fromRGB(22, 16, 34)
local PANEL_LIGHT = Color3.fromRGB(42, 30, 58)
local TEXT = Color3.fromRGB(244, 228, 196)
local TEXT_DIM = Color3.fromRGB(170, 154, 128)
local LOCKED = Color3.fromRGB(110, 110, 110)
local ACCENT = Color3.fromRGB(120, 72, 180)
local WEAPON_ACCENT = Color3.fromRGB(58, 92, 148)
local SELECTED = Color3.fromRGB(88, 58, 128)

function InfuserMenuClient.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local infuseSpellEvent = ReplicatedStorage:WaitForChild("InfuseSpell") :: RemoteEvent
	local purgeWeaponInfusionEvent = ReplicatedStorage:WaitForChild("PurgeWeaponInfusion") :: RemoteEvent
	local spellLoadoutUpdatedEvent = ReplicatedStorage:WaitForChild("SpellLoadoutUpdated") :: RemoteEvent
	local profileStateEvent = ReplicatedStorage:WaitForChild("PlayerProfileState") :: RemoteEvent
	local phaseStateEvent = ReplicatedStorage:WaitForChild("PlayerPhaseState") :: RemoteEvent

	local selectedWeaponId = LobbyConfig.STARTER_WEAPON
	local selectedSpellId = ""
	local equippedWeapon = LobbyConfig.STARTER_WEAPON
	local walletGold = LobbyConfig.STARTER_GOLD
	local grimoireCount = 0
	local weaponInfusions: { [string]: string } = {}
	local unlockedWeapons: { [string]: boolean } = {
		[LobbyConfig.STARTER_WEAPON] = true,
	}
	local ownedSpells: { [string]: boolean } = {
		[LobbyConfig.STARTER_ACTIVE_SPELL] = true,
	}
	local spellLevels: { [string]: number } = {}
	local loadoutLocked = false
	local menuOpen = false
	local currentPhase = "Lobby"
	local pendingAction = false

	for _, spell in SpellConfig.getSpellList() do
		spellLevels[spell.id] = 1
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InfuserMenuUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 12
	screenGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "InfuserPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(560, 480)
	panel.BackgroundColor3 = PANEL
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = ACCENT
	panelStroke.Thickness = 2
	panelStroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(16, 12)
	title.Size = UDim2.new(1, -64, 0, 28)
	title.Font = Enum.Font.GothamBold
	title.Text = InfuserConfig.DISPLAY_NAME
	title.TextColor3 = GOLD
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local closeButton = Instance.new("TextButton")
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, -12, 0, 12)
	closeButton.Size = UDim2.fromOffset(36, 36)
	closeButton.BackgroundColor3 = PANEL_LIGHT
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Text = "X"
	closeButton.TextColor3 = TEXT
	closeButton.TextSize = 18
	closeButton.Parent = panel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	local statusLabel = Instance.new("TextLabel")
	statusLabel.BackgroundTransparency = 1
	statusLabel.Position = UDim2.fromOffset(16, 44)
	statusLabel.Size = UDim2.new(1, -32, 0, 48)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Text = "Pick a weapon and learned spell. Infusing costs 1 grimoire and is permanent until purged."
	statusLabel.TextColor3 = TEXT
	statusLabel.TextSize = 14
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = panel

	local columns = Instance.new("Frame")
	columns.BackgroundTransparency = 1
	columns.Position = UDim2.fromOffset(16, 100)
	columns.Size = UDim2.new(1, -32, 1, -188)
	columns.Parent = panel

	local weaponHeader = Instance.new("TextLabel")
	weaponHeader.BackgroundTransparency = 1
	weaponHeader.Size = UDim2.new(0.48, 0, 0, 22)
	weaponHeader.Font = Enum.Font.GothamBold
	weaponHeader.Text = "Weapon"
	weaponHeader.TextColor3 = WEAPON_ACCENT
	weaponHeader.TextSize = 16
	weaponHeader.TextXAlignment = Enum.TextXAlignment.Left
	weaponHeader.Parent = columns

	local spellHeader = Instance.new("TextLabel")
	spellHeader.BackgroundTransparency = 1
	spellHeader.Position = UDim2.new(0.52, 0, 0, 0)
	spellHeader.Size = UDim2.new(0.48, 0, 0, 22)
	spellHeader.Font = Enum.Font.GothamBold
	spellHeader.Text = "Spell"
	spellHeader.TextColor3 = ACCENT
	spellHeader.TextSize = 16
	spellHeader.TextXAlignment = Enum.TextXAlignment.Left
	spellHeader.Parent = columns

	local weaponList = Instance.new("ScrollingFrame")
	weaponList.BackgroundTransparency = 1
	weaponList.BorderSizePixel = 0
	weaponList.Position = UDim2.new(0, 0, 0, 28)
	weaponList.Size = UDim2.new(0.48, -6, 1, -28)
	weaponList.CanvasSize = UDim2.fromOffset(0, 0)
	weaponList.ScrollBarThickness = 6
	weaponList.Parent = columns

	local weaponLayout = Instance.new("UIListLayout")
	weaponLayout.Padding = UDim.new(0, 8)
	weaponLayout.SortOrder = Enum.SortOrder.LayoutOrder
	weaponLayout.Parent = weaponList

	local spellList = Instance.new("ScrollingFrame")
	spellList.BackgroundTransparency = 1
	spellList.BorderSizePixel = 0
	spellList.Position = UDim2.new(0.52, 0, 0, 28)
	spellList.Size = UDim2.new(0.48, -6, 1, -28)
	spellList.CanvasSize = UDim2.fromOffset(0, 0)
	spellList.ScrollBarThickness = 6
	spellList.Parent = columns

	local spellLayout = Instance.new("UIListLayout")
	spellLayout.Padding = UDim.new(0, 8)
	spellLayout.SortOrder = Enum.SortOrder.LayoutOrder
	spellLayout.Parent = spellList

	weaponLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		weaponList.CanvasSize = UDim2.fromOffset(0, weaponLayout.AbsoluteContentSize.Y + 8)
	end)
	spellLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		spellList.CanvasSize = UDim2.fromOffset(0, spellLayout.AbsoluteContentSize.Y + 8)
	end)

	local actionBar = Instance.new("Frame")
	actionBar.BackgroundTransparency = 1
	actionBar.AnchorPoint = Vector2.new(0, 1)
	actionBar.Position = UDim2.new(0, 16, 1, -16)
	actionBar.Size = UDim2.new(1, -32, 0, 72)
	actionBar.Parent = panel

	local previewLabel = Instance.new("TextLabel")
	previewLabel.BackgroundTransparency = 1
	previewLabel.Position = UDim2.fromOffset(0, 0)
	previewLabel.Size = UDim2.new(1, -280, 0, 72)
	previewLabel.Font = Enum.Font.Gotham
	previewLabel.Text = "Select a weapon and spell."
	previewLabel.TextColor3 = TEXT_DIM
	previewLabel.TextSize = 14
	previewLabel.TextWrapped = true
	previewLabel.TextXAlignment = Enum.TextXAlignment.Left
	previewLabel.TextYAlignment = Enum.TextYAlignment.Center
	previewLabel.Parent = actionBar

	local infuseButton = Instance.new("TextButton")
	infuseButton.AnchorPoint = Vector2.new(1, 0.5)
	infuseButton.Position = UDim2.new(1, -144, 0.5, 0)
	infuseButton.Size = UDim2.fromOffset(124, 48)
	infuseButton.BackgroundColor3 = ACCENT
	infuseButton.BorderSizePixel = 0
	infuseButton.Font = Enum.Font.GothamBold
	infuseButton.Text = "Infuse"
	infuseButton.TextColor3 = Color3.new(1, 1, 1)
	infuseButton.TextSize = 17
	infuseButton.AutoButtonColor = false
	infuseButton.Parent = actionBar

	local infuseCorner = Instance.new("UICorner")
	infuseCorner.CornerRadius = UDim.new(0, 10)
	infuseCorner.Parent = infuseButton

	local purgeButton = Instance.new("TextButton")
	purgeButton.AnchorPoint = Vector2.new(1, 0.5)
	purgeButton.Position = UDim2.new(1, 0, 0.5, 0)
	purgeButton.Size = UDim2.fromOffset(132, 48)
	purgeButton.BackgroundColor3 = PANEL_LIGHT
	purgeButton.BorderSizePixel = 0
	purgeButton.Font = Enum.Font.GothamBold
	purgeButton.Text = `Purge ({InfuserConfig.PURGE_COST}g)`
	purgeButton.TextColor3 = TEXT
	purgeButton.TextSize = 15
	purgeButton.AutoButtonColor = false
	purgeButton.Parent = actionBar

	local purgeCorner = Instance.new("UICorner")
	purgeCorner.CornerRadius = UDim.new(0, 10)
	purgeCorner.Parent = purgeButton

	type Row = {
		button: TextButton,
		stroke: UIStroke,
	}

	local weaponRows: { [string]: Row } = {}
	local spellRows: { [string]: Row } = {}

	local function getEffectiveDisplayStats(spellId: string)
		return SpellUpgradeConfig.getEffectiveStats(spellId, spellLevels[spellId] or 1)
	end

	local function getWeaponInfusion(weaponId: string): string
		return weaponInfusions[weaponId] or ""
	end

	local function weaponHasInfusion(weaponId: string): boolean
		local infusion = getWeaponInfusion(weaponId)
		return infusion ~= ""
	end

	local function getDefaultSpellSelection(): string
		for _, spell in SpellConfig.getSpellList() do
			if ownedSpells[spell.id] then
				return spell.id
			end
		end
		return ""
	end

	local function canInfuseSelection(): boolean
		return selectedWeaponId ~= ""
			and selectedSpellId ~= ""
			and unlockedWeapons[selectedWeaponId] == true
			and ownedSpells[selectedSpellId] == true
			and not weaponHasInfusion(selectedWeaponId)
			and grimoireCount >= InfuserConfig.INFUSION_GRIMOIRE_COST
			and not loadoutLocked
			and currentPhase == "Lobby"
			and not pendingAction
	end

	local function canPurgeSelection(): boolean
		return selectedWeaponId ~= ""
			and unlockedWeapons[selectedWeaponId] == true
			and weaponHasInfusion(selectedWeaponId)
			and walletGold >= InfuserConfig.PURGE_COST
			and not loadoutLocked
			and currentPhase == "Lobby"
			and not pendingAction
	end

	local function updateActionBar()
		local weapon = WeaponConfig.getWeapon(selectedWeaponId)
		local weaponName = if weapon then weapon.displayName else "Weapon"
		local infusionId = getWeaponInfusion(selectedWeaponId)

		if infusionId ~= "" then
			local stats = getEffectiveDisplayStats(infusionId)
			previewLabel.Text =
				`{weaponName} is bound to {stats.resolvedName}.\nPress E in dungeons while wielding it. Purge costs {InfuserConfig.PURGE_COST} gold.`
			previewLabel.TextColor3 = GOLD
			infuseButton.Text = "Infused"
			infuseButton.BackgroundColor3 = LOCKED
			infuseButton.AutoButtonColor = false
			purgeButton.Text = if pendingAction then "Purging..." else `Purge ({InfuserConfig.PURGE_COST}g)`
			purgeButton.BackgroundColor3 = if canPurgeSelection() then Color3.fromRGB(92, 58, 58) else LOCKED
			purgeButton.AutoButtonColor = canPurgeSelection()
			return
		end

		if selectedSpellId == "" or ownedSpells[selectedSpellId] ~= true then
			previewLabel.Text = `{weaponName} has no infusion yet.\nLearn spells with grimoires, then infuse (costs 1 grimoire).`
			previewLabel.TextColor3 = TEXT_DIM
		else
			local stats = getEffectiveDisplayStats(selectedSpellId)
			local grimoireReady = grimoireCount >= InfuserConfig.INFUSION_GRIMOIRE_COST
			previewLabel.Text = if grimoireReady
				then `Bind {stats.displayName} to {weaponName} for 1 grimoire.\nCast with E while wielding it ({stats.staminaCost} stamina).`
				else `Need 1 grimoire to infuse {stats.displayName} into {weaponName}.`
			previewLabel.TextColor3 = if grimoireReady then TEXT else TEXT_DIM
		end

		local ready = canInfuseSelection()
		infuseButton.Text = if pendingAction then "Infusing..." else "Infuse"
		infuseButton.BackgroundColor3 = if ready then ACCENT else LOCKED
		infuseButton.AutoButtonColor = ready
		purgeButton.Text = `Purge ({InfuserConfig.PURGE_COST}g)`
		purgeButton.BackgroundColor3 = LOCKED
		purgeButton.AutoButtonColor = false
	end

	local function updateMenuState()
		if not pendingAction then
			statusLabel.Text =
				`Grimoires: {grimoireCount}  |  Infuse cost: 1  |  Purge: {InfuserConfig.PURGE_COST} gold  |  Wallet: {walletGold}`
		end

		for index, weapon in WeaponConfig.getWeaponList() do
			local row = weaponRows[weapon.id]
			if not row then
				continue
			end

			local unlocked = unlockedWeapons[weapon.id] == true
			local selected = weapon.id == selectedWeaponId
			local infusionId = getWeaponInfusion(weapon.id)
			local equippedTag = if weapon.id == equippedWeapon then "  EQUIPPED" else ""

			if not unlocked then
				row.button.Text = `{weapon.displayName}  LOCKED`
				row.button.BackgroundColor3 = PANEL_LIGHT
				row.button.TextColor3 = LOCKED
				row.stroke.Color = PANEL_LIGHT
			elseif infusionId ~= "" then
				local spellName = getEffectiveDisplayStats(infusionId).resolvedName
				row.button.Text = `{weapon.displayName}{equippedTag}\n{spellName} infused`
				row.button.BackgroundColor3 = if selected then GOLD_DIM else PANEL_LIGHT
				row.button.TextColor3 = TEXT
				row.stroke.Color = if selected then GOLD else WEAPON_ACCENT
			else
				row.button.Text = `{weapon.displayName}{equippedTag}\nNo infusion`
				row.button.BackgroundColor3 = if selected then SELECTED else PANEL_LIGHT
				row.button.TextColor3 = TEXT
				row.stroke.Color = if selected then WEAPON_ACCENT else PANEL_LIGHT
			end
			row.stroke.Thickness = if selected then 2 else 1
			row.button.LayoutOrder = index
		end

		local weaponInfused = weaponHasInfusion(selectedWeaponId)
		local ownedSpellCount = 0
		for index, spell in SpellConfig.getSpellList() do
			local row = spellRows[spell.id]
			if not row then
				continue
			end

			local owned = ownedSpells[spell.id] == true
			row.button.Visible = owned
			if not owned then
				continue
			end

			ownedSpellCount += 1
			local selected = spell.id == selectedSpellId
			local stats = getEffectiveDisplayStats(spell.id)

			if weaponInfused then
				row.button.Text = `{stats.displayName}  Lv {spellLevels[spell.id] or 1}\nPurge the weapon to change spells.`
				row.button.BackgroundColor3 = PANEL_LIGHT
				row.button.TextColor3 = TEXT_DIM
				row.stroke.Color = PANEL_LIGHT
				row.button.AutoButtonColor = false
			else
				row.button.Text =
					`{stats.displayName}  Lv {spellLevels[spell.id] or 1}\n{stats.damageMin}-{stats.damageMax} dmg  |  {stats.staminaCost} ST`
				row.button.BackgroundColor3 = if selected then SELECTED else PANEL_LIGHT
				row.button.TextColor3 = TEXT
				row.stroke.Color = if selected then ACCENT else PANEL_LIGHT
				row.button.AutoButtonColor = false
			end
			row.stroke.Thickness = if selected and not weaponInfused then 2 else 1
			row.button.LayoutOrder = index
		end

		spellHeader.Text = if ownedSpellCount > 0 then "Spell" else "Spell (learn with grimoires)"

		updateActionBar()
	end

	for index, weapon in WeaponConfig.getWeaponList() do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -4, 0, 64)
		button.BackgroundColor3 = PANEL_LIGHT
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.TextSize = 14
		button.TextWrapped = true
		button.LayoutOrder = index
		button.Parent = weaponList

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = button

		local stroke = Instance.new("UIStroke")
		stroke.Color = PANEL_LIGHT
		stroke.Thickness = 1
		stroke.Parent = button

		button.MouseButton1Click:Connect(function()
			if unlockedWeapons[weapon.id] ~= true then
				return
			end
			selectedWeaponId = weapon.id
			if weaponHasInfusion(weapon.id) then
				selectedSpellId = getWeaponInfusion(weapon.id)
			elseif selectedSpellId == "" or ownedSpells[selectedSpellId] ~= true then
				selectedSpellId = getDefaultSpellSelection()
			end
			updateMenuState()
		end)

		weaponRows[weapon.id] = { button = button, stroke = stroke }
	end

	for index, spell in SpellConfig.getSpellList() do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -4, 0, 64)
		button.BackgroundColor3 = PANEL_LIGHT
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.TextSize = 14
		button.TextWrapped = true
		button.LayoutOrder = index
		button.Parent = spellList

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = button

		local stroke = Instance.new("UIStroke")
		stroke.Color = PANEL_LIGHT
		stroke.Thickness = 1
		stroke.Parent = button

		button.MouseButton1Click:Connect(function()
			if ownedSpells[spell.id] ~= true or weaponHasInfusion(selectedWeaponId) then
				return
			end
			selectedSpellId = spell.id
			updateMenuState()
		end)

		spellRows[spell.id] = { button = button, stroke = stroke }
	end

	local function setMenuOpen(open: boolean)
		menuOpen = open
		panel.Visible = open
		if open then
			selectedWeaponId = equippedWeapon
			selectedSpellId = getDefaultSpellSelection()
			pendingAction = false
			updateMenuState()
		end
	end

	local function tryInfuseSelected()
		if not canInfuseSelection() then
			return
		end

		pendingAction = true
		updateActionBar()
		infuseSpellEvent:FireServer(selectedWeaponId, selectedSpellId)
	end

	local function tryPurgeSelected()
		if not canPurgeSelection() then
			return
		end

		pendingAction = true
		updateActionBar()
		purgeWeaponInfusionEvent:FireServer(selectedWeaponId)
	end

	closeButton.MouseButton1Click:Connect(function()
		setMenuOpen(false)
	end)

	infuseButton.MouseButton1Click:Connect(tryInfuseSelected)
	purgeButton.MouseButton1Click:Connect(tryPurgeSelected)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not menuOpen then
			return
		end

		if input.KeyCode == Enum.KeyCode.Escape then
			setMenuOpen(false)
		end
	end)

	spellLoadoutUpdatedEvent.OnClientEvent:Connect(function(_activeInfusion: string, locked: boolean)
		loadoutLocked = locked == true
		if locked then
			pendingAction = false
			setMenuOpen(false)
		end
		updateMenuState()
	end)

	profileStateEvent.OnClientEvent:Connect(function(snapshot)
		if typeof(snapshot) ~= "table" then
			return
		end

		local previousInfusion = getWeaponInfusion(selectedWeaponId)

		if typeof(snapshot.gold) == "number" then
			walletGold = snapshot.gold
		end
		if typeof(snapshot.grimoireCount) == "number" then
			grimoireCount = snapshot.grimoireCount
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
		elseif typeof(snapshot.infusedSpellId) == "string" and snapshot.infusedSpellId ~= "" then
			weaponInfusions[equippedWeapon] = snapshot.infusedSpellId
		end
		if typeof(snapshot.unlockedWeapons) == "table" then
			for weaponId, unlocked in snapshot.unlockedWeapons do
				if typeof(unlocked) == "boolean" then
					unlockedWeapons[weaponId] = unlocked
				end
			end
		end
		if typeof(snapshot.ownedSpells) == "table" then
			for spellId, owned in snapshot.ownedSpells do
				if typeof(owned) == "boolean" then
					ownedSpells[spellId] = owned
				end
			end
		end
		if typeof(snapshot.spellLevels) == "table" then
			for spellId, level in snapshot.spellLevels do
				if typeof(level) == "number" then
					spellLevels[spellId] = level
				end
			end
		end

		if menuOpen then
			local infusionId = getWeaponInfusion(selectedWeaponId)
			if infusionId ~= "" then
				selectedSpellId = infusionId
			elseif selectedSpellId == "" or ownedSpells[selectedSpellId] ~= true then
				selectedSpellId = getDefaultSpellSelection()
			end

			if pendingAction then
				pendingAction = false
				local weapon = WeaponConfig.getWeapon(selectedWeaponId)
				local weaponName = if weapon then weapon.displayName else "Weapon"
				local newInfusion = getWeaponInfusion(selectedWeaponId)
				if newInfusion ~= "" and newInfusion ~= previousInfusion then
					local stats = getEffectiveDisplayStats(newInfusion)
					statusLabel.Text = `{stats.resolvedName} infused into {weaponName}! Press E while wielding it.`
				elseif previousInfusion ~= "" and newInfusion == "" then
					statusLabel.Text = `Infusion removed from {weaponName} for {InfuserConfig.PURGE_COST} gold.`
				end
			end
		end

		updateMenuState()
	end)

	phaseStateEvent.OnClientEvent:Connect(function(phase: string)
		if phase == "Lobby" or phase == "Dungeon" then
			currentPhase = phase
			if phase == "Dungeon" then
				setMenuOpen(false)
			end
			updateMenuState()
		end
	end)

	InfuserMenuClient._open = function()
		if loadoutLocked or currentPhase ~= "Lobby" then
			return
		end
		setMenuOpen(true)
	end

	updateMenuState()
end

function InfuserMenuClient.open()
	if InfuserMenuClient._open then
		InfuserMenuClient._open()
	end
end

return InfuserMenuClient
