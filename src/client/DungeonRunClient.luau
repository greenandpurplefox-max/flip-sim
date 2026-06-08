local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardConfig = require(ReplicatedStorage.Shared.CardConfig)
local DungeonConfig = require(ReplicatedStorage.Shared.DungeonConfig)
local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)

local DungeonRunClient = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GOLD = Color3.fromRGB(214, 176, 72)
local PANEL = Color3.fromRGB(24, 18, 16)
local TEXT = Color3.fromRGB(244, 228, 196)

local screenGui: ScreenGui
local statusLabel: TextLabel
local cardPanel: Frame
local cardButtons: { TextButton } = {}
local cardConnections: { RBXScriptConnection } = {}

local function createUI()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DungeonRunUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "RunStatus"
	statusLabel.Size = UDim2.fromOffset(360, 72)
	statusLabel.Position = UDim2.new(0.5, -180, 0, 12)
	statusLabel.BackgroundColor3 = PANEL
	statusLabel.BorderSizePixel = 0
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.Text = "Entering the dungeon..."
	statusLabel.TextColor3 = TEXT
	statusLabel.TextSize = 18
	statusLabel.TextWrapped = true
	statusLabel.Parent = screenGui

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 10)
	statusCorner.Parent = statusLabel

	local statusStroke = Instance.new("UIStroke")
	statusStroke.Color = GOLD
	statusStroke.Thickness = 2
	statusStroke.Parent = statusLabel

	cardPanel = Instance.new("Frame")
	cardPanel.Name = "CardDraftPanel"
	cardPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	cardPanel.Position = UDim2.fromScale(0.5, 0.5)
	cardPanel.Size = UDim2.fromOffset(720, 260)
	cardPanel.BackgroundColor3 = PANEL
	cardPanel.BorderSizePixel = 0
	cardPanel.Visible = false
	cardPanel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 14)
	panelCorner.Parent = cardPanel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = GOLD
	panelStroke.Thickness = 2
	panelStroke.Parent = cardPanel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(20, 16)
	title.Size = UDim2.new(1, -40, 0, 28)
	title.Font = Enum.Font.GothamBold
	title.Text = "Choose a Relic"
	title.TextColor3 = GOLD
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = cardPanel

	local subtitle = Instance.new("TextLabel")
	subtitle.BackgroundTransparency = 1
	subtitle.Position = UDim2.fromOffset(20, 44)
	subtitle.Size = UDim2.new(1, -40, 0, 20)
	subtitle.Font = Enum.Font.Gotham
	subtitle.Text = "Pick one card to empower your dungeon run."
	subtitle.TextColor3 = TEXT
	subtitle.TextSize = 14
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = cardPanel

	local list = Instance.new("Frame")
	list.Name = "CardList"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromOffset(20, 82)
	list.Size = UDim2.new(1, -40, 1, -98)
	list.Parent = cardPanel

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	for index = 1, 3 do
		local button = Instance.new("TextButton")
		button.Name = `CardButton{index}`
		button.Size = UDim2.fromOffset(210, 140)
		button.BackgroundColor3 = Color3.fromRGB(42, 32, 28)
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.TextColor3 = TEXT
		button.TextSize = 16
		button.TextWrapped = true
		button.Visible = false
		button.LayoutOrder = index
		button.Parent = list

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = button

		table.insert(cardButtons, button)
	end
end

local function clearCardConnections()
	for _, connection in cardConnections do
		connection:Disconnect()
	end
	table.clear(cardConnections)
end

local function hideCardDraft()
	clearCardConnections()
	cardPanel.Visible = false
	for _, button in cardButtons do
		button.Visible = false
	end
end

local function showCardDraft(options: { string }, pickEvent: RemoteEvent)
	clearCardConnections()

	for index, cardId in options do
		local card = CardConfig.getCard(cardId)
		local button = cardButtons[index]
		if card and button then
			button.Text = `{card.name}\n\n{card.description}`
			button.Visible = true
			table.insert(
				cardConnections,
				button.MouseButton1Click:Connect(function()
					pickEvent:FireServer(cardId)
					hideCardDraft()
				end)
			)
		end
	end

	cardPanel.Visible = true
end

local function renderRunState(state: any)
	if not state then
		statusLabel.Text = "Run ended."
		hideCardDraft()
		return
	end

	local bossText = if state.isBossRoom then "  |  BOSS ROOM" else ""
	local cardCount = if state.activeCards then #state.activeCards else 0

	if state.status == "fighting" then
		statusLabel.Text =
			`Depth {state.room}{bossText}  |  Beasts left: {state.monstersRemaining}  |  Gold: {state.gold}  |  Relics: {cardCount}`
	elseif state.status == "card_draft" then
		statusLabel.Text = `Depth {state.room} cleared  |  Gold: {state.gold}  |  Choose a relic...`
	elseif state.status == "intermission" then
		statusLabel.Text = `Depth {state.room} cleared  |  Gold: {state.gold}  |  Deeper...`
	else
		statusLabel.Text = `Depth {state.room}  |  Gold: {state.gold}  |  Relics: {cardCount}`
	end
end

function DungeonRunClient.init()
	if not DungeonConfig.USE_DUNGEON_MODE then
		return
	end

	createUI()

	local dungeonRunStateEvent = ReplicatedStorage:WaitForChild("DungeonRunState") :: RemoteEvent
	local cardDraftPickEvent = ReplicatedStorage:WaitForChild("CardDraftPick") :: RemoteEvent

	local waveUi = playerGui:FindFirstChild("WaveUI")
	if waveUi and waveUi:IsA("ScreenGui") then
		waveUi.Enabled = false
	end

	dungeonRunStateEvent.OnClientEvent:Connect(function(state, draftOptions: { string }?)
		renderRunState(state)
		if draftOptions and #draftOptions > 0 then
			showCardDraft(draftOptions, cardDraftPickEvent)
		elseif not state or state.status ~= "card_draft" then
			hideCardDraft()
		end
	end)

	if LobbyConfig.USE_LOBBY then
		local phaseStateEvent = ReplicatedStorage:WaitForChild("PlayerPhaseState") :: RemoteEvent
		phaseStateEvent.OnClientEvent:Connect(function(phase: string)
			screenGui.Enabled = phase == "Dungeon"
			if phase ~= "Dungeon" then
				hideCardDraft()
			end
		end)
	end
end

return DungeonRunClient
