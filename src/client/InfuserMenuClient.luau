local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local InfuserConfig = require(ReplicatedStorage.Shared.InfuserConfig)
local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)
local SpellConfig = require(ReplicatedStorage.Shared.SpellConfig)
local SpellUpgradeConfig = require(ReplicatedStorage.Shared.SpellUpgradeConfig)

local InfuserMenuClient = {}

local GOLD = Color3.fromRGB(214, 176, 72)
local GOLD_DIM = Color3.fromRGB(140, 108, 42)
local PANEL = Color3.fromRGB(22, 16, 34)
local PANEL_LIGHT = Color3.fromRGB(42, 30, 58)
local TEXT = Color3.fromRGB(244, 228, 196)
local TEXT_DIM = Color3.fromRGB(170, 154, 128)
local LOCKED = Color3.fromRGB(110, 110, 110)
local ACCENT = Color3.fromRGB(120, 72, 180)
local SELECTED = Color3.fromRGB(88, 58, 128)

function InfuserMenuClient.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local infuseSpellEvent = ReplicatedStorage:WaitForChild("InfuseSpell") :: RemoteEvent
	local spellLoadoutUpdatedEvent = ReplicatedStorage:WaitForChild("SpellLoadoutUpdated") :: RemoteEvent
	local profileStateEvent = ReplicatedStorage:WaitForChild("PlayerProfileState") :: RemoteEvent
	local phaseStateEvent = ReplicatedStorage:WaitForChild("PlayerPhaseState") :: RemoteEvent

	local infusedSpellId = ""
	local selectedSpellId = ""
	local ownedSpells: { [string]: boolean } = {
		[LobbyConfig.STARTER_ACTIVE_SPELL] = true,
	}
	local spellLevels: { [string]: number } = {}
	local loadoutLocked = false
	local menuOpen = false
	local currentPhase = "Lobby"
	local pendingInfusion = false

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
	panel.Size = UDim2.fromOffset(440, 460)
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
	statusLabel.Size = UDim2.new(1, -32, 0, 52)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Text = "Select a learned spell, then infuse it to cast with E in dungeons."
	statusLabel.TextColor3 = TEXT
	statusLabel.TextSize = 14
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = panel

	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(16, 104)
	list.Size = UDim2.new(1, -32, 1, -188)
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

	local actionBar = Instance.new("Frame")
	actionBar.BackgroundTransparency = 1
	actionBar.AnchorPoint = Vector2.new(0, 1)
	actionBar.Position = UDim2.new(0, 16, 1, -16)
	actionBar.Size = UDim2.new(1, -32, 0, 72)
	actionBar.Parent = panel

	local previewLabel = Instance.new("TextLabel")
	previewLabel.BackgroundTransparency = 1
	previewLabel.Position = UDim2.fromOffset(0, 0)
	previewLabel.Size = UDim2.new(1, -148, 0, 72)
	previewLabel.Font = Enum.Font.Gotham
	previewLabel.Text = "Select a spell above."
	previewLabel.TextColor3 = TEXT_DIM
	previewLabel.TextSize = 14
	previewLabel.TextWrapped = true
	previewLabel.TextXAlignment = Enum.TextXAlignment.Left
	previewLabel.TextYAlignment = Enum.TextYAlignment.Center
	previewLabel.Parent = actionBar

	local infuseButton = Instance.new("TextButton")
	infuseButton.AnchorPoint = Vector2.new(1, 0.5)
	infuseButton.Position = UDim2.new(1, 0, 0.5, 0)
	infuseButton.Size = UDim2.fromOffset(132, 48)
	infuseButton.BackgroundColor3 = ACCENT
	infuseButton.BorderSizePixel = 0
	infuseButton.Font = Enum.Font.GothamBold
	infuseButton.Text = "Infuse"
	infuseButton.TextColor3 = Color3.new(1, 1, 1)
	infuseButton.TextSize = 18
	infuseButton.AutoButtonColor = false
	infuseButton.Parent = actionBar

	local infuseCorner = Instance.new("UICorner")
	infuseCorner.CornerRadius = UDim.new(0, 10)
	infuseCorner.Parent = infuseButton

	type SpellRow = {
		button: TextButton,
		stroke: UIStroke,
	}

	local spellRows: { [string]: SpellRow } = {}

	local function getEffectiveDisplayStats(spellId: string)
		return SpellUpgradeConfig.getEffectiveStats(spellId, spellLevels[spellId] or 1)
	end

	local function getDefaultSelection(): string
		if infusedSpellId ~= "" and ownedSpells[infusedSpellId] then
			return infusedSpellId
		end

		for _, spell in SpellConfig.getSpellList() do
			if ownedSpells[spell.id] then
				return spell.id
			end
		end

		return ""
	end

	local function canInfuseSelection(): boolean
		return selectedSpellId ~= ""
			and ownedSpells[selectedSpellId] == true
			and selectedSpellId ~= infusedSpellId
			and not loadoutLocked
			and currentPhase == "Lobby"
			and not pendingInfusion
	end

	local function updateActionBar()
		if selectedSpellId == "" or ownedSpells[selectedSpellId] ~= true then
			previewLabel.Text = "Select a learned spell above."
			previewLabel.TextColor3 = TEXT_DIM
			infuseButton.Text = "Infuse"
			infuseButton.BackgroundColor3 = LOCKED
			infuseButton.AutoButtonColor = false
			return
		end

		local stats = getEffectiveDisplayStats(selectedSpellId)
		if selectedSpellId == infusedSpellId then
			previewLabel.Text =
				`{stats.resolvedName} is already infused.\nPress E in dungeons to cast ({stats.staminaCost} stamina).`
			previewLabel.TextColor3 = GOLD
			infuseButton.Text = "Infused"
			infuseButton.BackgroundColor3 = GOLD_DIM
			infuseButton.AutoButtonColor = false
			return
		end

		previewLabel.Text =
			`Ready: {stats.displayName}  Lv {spellLevels[selectedSpellId] or 1}\n{stats.damageMin}-{stats.damageMax} dmg  |  {stats.staminaCost} stamina per cast (E)`
		previewLabel.TextColor3 = TEXT

		local ready = canInfuseSelection()
		infuseButton.Text = if pendingInfusion then "Infusing..." else "Infuse"
		infuseButton.BackgroundColor3 = if ready then ACCENT else LOCKED
		infuseButton.AutoButtonColor = ready
	end

	local function updateMenuState()
		local infusedName = if infusedSpellId ~= ""
			then getEffectiveDisplayStats(infusedSpellId).resolvedName
			else "None"

		if not pendingInfusion then
			statusLabel.Text =
				`Bind a spell to your weapon, then press E in dungeons to cast.\nCurrent infusion: {infusedName}`
		end

		local layoutOrder = 0
		for _, spell in SpellConfig.getSpellList() do
			layoutOrder += 1
			local spellId = spell.id
			local row = spellRows[spellId]
			if not row then
				continue
			end

			local stats = getEffectiveDisplayStats(spellId)
			local owned = ownedSpells[spellId] == true
			local infused = spellId == infusedSpellId
			local selected = spellId == selectedSpellId

			row.button.LayoutOrder = if owned then layoutOrder else layoutOrder + 100

			if not owned then
				row.button.Text = `{stats.displayName}  LOCKED\nFind this spell with a grimoire.`
				row.button.BackgroundColor3 = PANEL_LIGHT
				row.button.TextColor3 = LOCKED
				row.button.AutoButtonColor = false
				row.stroke.Color = PANEL_LIGHT
				row.stroke.Thickness = 1
			elseif infused then
				row.button.Text =
					`{stats.resolvedName}  INFUSED\nPress E in dungeons  |  {stats.staminaCost} stamina`
				row.button.BackgroundColor3 = GOLD_DIM
				row.button.TextColor3 = TEXT
				row.button.AutoButtonColor = false
				row.stroke.Color = GOLD
				row.stroke.Thickness = if selected then 2 else 1
			else
				row.button.Text =
					`{stats.displayName}  Lv {spellLevels[spellId] or 1}\nClick to select, then press Infuse`
				row.button.BackgroundColor3 = if selected then SELECTED else PANEL_LIGHT
				row.button.TextColor3 = if loadoutLocked or currentPhase ~= "Lobby" then LOCKED else TEXT
				row.button.AutoButtonColor = false
				row.stroke.Color = if selected then ACCENT else PANEL_LIGHT
				row.stroke.Thickness = if selected then 2 else 1
			end
		end

		updateActionBar()
	end

	for index, stats in SpellConfig.getSpellList() do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -4, 0, 72)
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

		local stroke = Instance.new("UIStroke")
		stroke.Color = PANEL_LIGHT
		stroke.Thickness = 1
		stroke.Parent = button

		button.MouseButton1Click:Connect(function()
			if ownedSpells[stats.id] ~= true then
				return
			end

			selectedSpellId = stats.id
			updateMenuState()
		end)

		spellRows[stats.id] = {
			button = button,
			stroke = stroke,
		}
	end

	local function setMenuOpen(open: boolean)
		menuOpen = open
		panel.Visible = open
		if open then
			selectedSpellId = getDefaultSelection()
			pendingInfusion = false
			updateMenuState()
		end
	end

	local function tryInfuseSelected()
		if not canInfuseSelection() then
			return
		end

		pendingInfusion = true
		updateActionBar()
		infuseSpellEvent:FireServer(selectedSpellId)
	end

	closeButton.MouseButton1Click:Connect(function()
		setMenuOpen(false)
	end)

	infuseButton.MouseButton1Click:Connect(tryInfuseSelected)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not menuOpen then
			return
		end

		if input.KeyCode == Enum.KeyCode.Escape then
			setMenuOpen(false)
		elseif input.KeyCode == Enum.KeyCode.Return then
			tryInfuseSelected()
		end
	end)

	spellLoadoutUpdatedEvent.OnClientEvent:Connect(function(activeInfusion: string, locked: boolean)
		pendingInfusion = false

		if typeof(activeInfusion) == "string" then
			local previousInfusion = infusedSpellId
			infusedSpellId = activeInfusion
			if activeInfusion ~= "" and activeInfusion ~= previousInfusion then
				local stats = getEffectiveDisplayStats(activeInfusion)
				statusLabel.Text = `{stats.resolvedName} infused! Press E in dungeons to cast.`
				selectedSpellId = activeInfusion
			end
		end

		loadoutLocked = locked == true
		if locked then
			setMenuOpen(false)
		end
		updateMenuState()
	end)

	profileStateEvent.OnClientEvent:Connect(function(snapshot)
		if typeof(snapshot) ~= "table" then
			return
		end

		if typeof(snapshot.infusedSpellId) == "string" then
			infusedSpellId = snapshot.infusedSpellId
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

		if menuOpen and (selectedSpellId == "" or ownedSpells[selectedSpellId] ~= true) then
			selectedSpellId = getDefaultSelection()
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
