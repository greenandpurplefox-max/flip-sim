local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

function InfuserMenuClient.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local infuseSpellEvent = ReplicatedStorage:WaitForChild("InfuseSpell") :: RemoteEvent
	local spellLoadoutUpdatedEvent = ReplicatedStorage:WaitForChild("SpellLoadoutUpdated") :: RemoteEvent
	local profileStateEvent = ReplicatedStorage:WaitForChild("PlayerProfileState") :: RemoteEvent
	local phaseStateEvent = ReplicatedStorage:WaitForChild("PlayerPhaseState") :: RemoteEvent

	local infusedSpellId = ""
	local ownedSpells: { [string]: boolean } = {
		[LobbyConfig.STARTER_ACTIVE_SPELL] = true,
	}
	local spellLevels: { [string]: number } = {}
	local loadoutLocked = false
	local menuOpen = false
	local currentPhase = "Lobby"

	for _, spell in SpellConfig.getSpellList() do
		spellLevels[spell.id] = 1
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InfuserMenuUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "InfuserPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(420, 420)
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
	title.Text = "Weapon Infusion"
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
	statusLabel.Size = UDim2.new(1, -32, 0, 44)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Text = "Choose a spell to bind into your equipped weapon."
	statusLabel.TextColor3 = TEXT
	statusLabel.TextSize = 14
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = panel

	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(16, 96)
	list.Size = UDim2.new(1, -32, 1, -112)
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

	local spellButtons: { [string]: TextButton } = {}

	local function getEffectiveDisplayStats(spellId: string)
		return SpellUpgradeConfig.getEffectiveStats(spellId, spellLevels[spellId] or 1)
	end

	local function updateMenuState()
		local infusedName = if infusedSpellId ~= ""
			then getEffectiveDisplayStats(infusedSpellId).resolvedName
			else "None"
		statusLabel.Text =
			`Infuse spells into your sword so they trigger when you attack.\nCurrent infusion: {infusedName}`

		for spellId, button in spellButtons do
			local stats = getEffectiveDisplayStats(spellId)
			local owned = ownedSpells[spellId] == true
			local infused = spellId == infusedSpellId

			if not owned then
				button.Text = `{stats.displayName}  LOCKED\nFind this spell with a grimoire.`
				button.BackgroundColor3 = PANEL_LIGHT
				button.TextColor3 = LOCKED
				button.AutoButtonColor = false
			elseif infused then
				button.Text =
					`{stats.resolvedName}  INFUSED\n{stats.damageMin}-{stats.damageMax} dmg  |  {stats.staminaCost} stamina`
				button.BackgroundColor3 = GOLD_DIM
				button.TextColor3 = TEXT
				button.AutoButtonColor = false
			else
				button.Text =
					`{stats.displayName}  Lv {spellLevels[spellId] or 1}\nInfuse for {stats.staminaCost} stamina per cast`
				button.BackgroundColor3 = PANEL_LIGHT
				button.TextColor3 = if loadoutLocked or currentPhase ~= "Lobby" then LOCKED else TEXT
				button.AutoButtonColor = not loadoutLocked and currentPhase == "Lobby"
			end
		end
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

		button.MouseButton1Click:Connect(function()
			if loadoutLocked or currentPhase ~= "Lobby" or ownedSpells[stats.id] ~= true then
				return
			end
			if stats.id == infusedSpellId then
				return
			end
			infuseSpellEvent:FireServer(stats.id)
		end)

		spellButtons[stats.id] = button
	end

	local function setMenuOpen(open: boolean)
		menuOpen = open
		panel.Visible = open
		if open then
			updateMenuState()
		end
	end

	closeButton.MouseButton1Click:Connect(function()
		setMenuOpen(false)
	end)

	spellLoadoutUpdatedEvent.OnClientEvent:Connect(function(activeInfusion: string, locked: boolean)
		if typeof(activeInfusion) == "string" then
			infusedSpellId = activeInfusion
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
