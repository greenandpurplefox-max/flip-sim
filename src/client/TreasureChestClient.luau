local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TreasureConfig = require(ReplicatedStorage.Shared.TreasureConfig)

local TreasureChestClient = {}

local GOLD = Color3.fromRGB(214, 176, 72)
local PANEL = Color3.fromRGB(24, 18, 16)
local PANEL_LIGHT = Color3.fromRGB(42, 34, 28)
local TEXT = Color3.fromRGB(244, 228, 196)
local TEXT_DIM = Color3.fromRGB(170, 154, 128)

type ChestEntry = {
	tierId: string,
	roomDepth: number,
	tierName: string,
}

local function buildChestModel(tierId: string): Model
	local tier = TreasureConfig.getTier(tierId)
	local model = Instance.new("Model")
	model.Name = "PreviewChest"

	local base = Instance.new("Part")
	base.Name = "ChestBase"
	base.Size = Vector3.new(3.2, 1.6, 2.4)
	base.Color = tier.bodyColor
	base.Material = Enum.Material.Wood
	base.Anchored = true
	base.CanCollide = false
	base.CFrame = CFrame.new(0, 0, 0)
	base.Parent = model

	local trim = Instance.new("Part")
	trim.Size = Vector3.new(3.35, 0.28, 2.55)
	trim.Color = tier.trimColor
	trim.Material = Enum.Material.Metal
	trim.Anchored = true
	trim.CanCollide = false
	trim.CFrame = base.CFrame * CFrame.new(0, 0.72, 0)
	trim.Parent = model

	local lid = Instance.new("Part")
	lid.Size = Vector3.new(3.2, 0.85, 2.4)
	lid.Color = tier.bodyColor
	lid.Material = Enum.Material.Wood
	lid.Anchored = true
	lid.CanCollide = false
	lid.CFrame = base.CFrame * CFrame.new(0, 1.05, -0.35)
	lid.Parent = model

	local glow = Instance.new("Part")
	glow.Size = Vector3.new(2.4, 0.12, 1.8)
	glow.Color = tier.glowColor
	glow.Material = Enum.Material.Neon
	glow.Anchored = true
	glow.CanCollide = false
	glow.Transparency = 0.35
	glow.CFrame = base.CFrame * CFrame.new(0, 1.55, 0)
	glow.Parent = model

	model.PrimaryPart = base
	return model
end

local function mountChestPreview(parent: Instance, tierId: string, size: number): ViewportFrame
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.fromOffset(size, size)
	viewport.BackgroundTransparency = 1
	viewport.Parent = parent

	local model = buildChestModel(tierId)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	model:PivotTo(CFrame.Angles(0, math.rad(28), math.rad(-12)))
	model.Parent = viewport

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(5, 3.5, 5), model:GetPivot().Position)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	return viewport
end

function TreasureChestClient.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local awardedEvent = ReplicatedStorage:WaitForChild("TreasureChestAwarded") :: RemoteEvent
	local chestStateEvent = ReplicatedStorage:WaitForChild("TreasureChestState") :: RemoteEvent
	local openedEvent = ReplicatedStorage:WaitForChild("TreasureChestOpened") :: RemoteEvent
	local openChestEvent = ReplicatedStorage:WaitForChild("OpenTreasureChest") :: RemoteEvent
	local phaseStateEvent = ReplicatedStorage:WaitForChild("PlayerPhaseState") :: RemoteEvent

	local currentPhase = "Lobby"
	local lobbyChests: { ChestEntry } = {}

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TreasureChestUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = true
	screenGui.Parent = playerGui

	local popupOverlay = Instance.new("Frame")
	popupOverlay.Name = "DungeonChestPopup"
	popupOverlay.Size = UDim2.fromScale(1, 1)
	popupOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	popupOverlay.BackgroundTransparency = 0.45
	popupOverlay.BorderSizePixel = 0
	popupOverlay.Visible = false
	popupOverlay.ZIndex = 20
	popupOverlay.Parent = screenGui

	local popupPanel = Instance.new("Frame")
	popupPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	popupPanel.Position = UDim2.fromScale(0.5, 0.5)
	popupPanel.Size = UDim2.fromOffset(320, 360)
	popupPanel.BackgroundColor3 = PANEL
	popupPanel.BorderSizePixel = 0
	popupPanel.ZIndex = 21
	popupPanel.Parent = popupOverlay

	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 16)
	popupCorner.Parent = popupPanel

	local popupStroke = Instance.new("UIStroke")
	popupStroke.Color = GOLD
	popupStroke.Thickness = 2
	popupStroke.Parent = popupPanel

	local popupTitle = Instance.new("TextLabel")
	popupTitle.BackgroundTransparency = 1
	popupTitle.Position = UDim2.fromOffset(16, 14)
	popupTitle.Size = UDim2.new(1, -32, 0, 28)
	popupTitle.Font = Enum.Font.GothamBold
	popupTitle.Text = "Treasure Chest!"
	popupTitle.TextColor3 = GOLD
	popupTitle.TextSize = 24
	popupTitle.ZIndex = 22
	popupTitle.Parent = popupPanel

	local popupSubtitle = Instance.new("TextLabel")
	popupSubtitle.BackgroundTransparency = 1
	popupSubtitle.Position = UDim2.fromOffset(16, 44)
	popupSubtitle.Size = UDim2.new(1, -32, 0, 40)
	popupSubtitle.Font = Enum.Font.Gotham
	popupSubtitle.Text = "Chest secured. Return to the lobby to open it."
	popupSubtitle.TextColor3 = TEXT_DIM
	popupSubtitle.TextWrapped = true
	popupSubtitle.TextSize = 15
	popupSubtitle.ZIndex = 22
	popupSubtitle.Parent = popupPanel

	local previewHost = Instance.new("Frame")
	previewHost.BackgroundTransparency = 1
	previewHost.Position = UDim2.fromOffset(40, 92)
	previewHost.Size = UDim2.fromOffset(240, 200)
	previewHost.ZIndex = 22
	previewHost.Parent = popupPanel

	local popupCount = Instance.new("TextLabel")
	popupCount.BackgroundTransparency = 1
	popupCount.Position = UDim2.fromOffset(16, 300)
	popupCount.Size = UDim2.new(1, -32, 0, 24)
	popupCount.Font = Enum.Font.GothamBold
	popupCount.Text = "Run chests: 0"
	popupCount.TextColor3 = TEXT
	popupCount.TextSize = 16
	popupCount.ZIndex = 22
	popupCount.Parent = popupPanel

	local lobbyOverlay = Instance.new("Frame")
	lobbyOverlay.Name = "LobbyChestMenu"
	lobbyOverlay.Size = UDim2.fromScale(1, 1)
	lobbyOverlay.BackgroundColor3 = Color3.fromRGB(8, 6, 5)
	lobbyOverlay.BackgroundTransparency = 0.12
	lobbyOverlay.BorderSizePixel = 0
	lobbyOverlay.Visible = false
	lobbyOverlay.ZIndex = 30
	lobbyOverlay.Parent = screenGui

	local lobbyPanel = Instance.new("Frame")
	lobbyPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	lobbyPanel.Position = UDim2.fromScale(0.5, 0.5)
	lobbyPanel.Size = UDim2.new(0.92, 0, 0.82, 0)
	lobbyPanel.BackgroundColor3 = PANEL
	lobbyPanel.BorderSizePixel = 0
	lobbyPanel.ZIndex = 31
	lobbyPanel.Parent = lobbyOverlay

	local lobbyCorner = Instance.new("UICorner")
	lobbyCorner.CornerRadius = UDim.new(0, 16)
	lobbyCorner.Parent = lobbyPanel

	local lobbyStroke = Instance.new("UIStroke")
	lobbyStroke.Color = GOLD
	lobbyStroke.Thickness = 2
	lobbyStroke.Parent = lobbyPanel

	local lobbyTitle = Instance.new("TextLabel")
	lobbyTitle.BackgroundTransparency = 1
	lobbyTitle.Position = UDim2.fromOffset(24, 18)
	lobbyTitle.Size = UDim2.new(1, -160, 0, 34)
	lobbyTitle.Font = Enum.Font.GothamBold
	lobbyTitle.Text = "Treasure Chests"
	lobbyTitle.TextColor3 = GOLD
	lobbyTitle.TextSize = 30
	lobbyTitle.TextXAlignment = Enum.TextXAlignment.Left
	lobbyTitle.ZIndex = 32
	lobbyTitle.Parent = lobbyPanel

	local lobbyHint = Instance.new("TextLabel")
	lobbyHint.BackgroundTransparency = 1
	lobbyHint.Position = UDim2.fromOffset(24, 54)
	lobbyHint.Size = UDim2.new(1, -48, 0, 24)
	lobbyHint.Font = Enum.Font.Gotham
	lobbyHint.Text = "Open the chests you found in the dungeon."
	lobbyHint.TextColor3 = TEXT_DIM
	lobbyHint.TextSize = 16
	lobbyHint.TextXAlignment = Enum.TextXAlignment.Left
	lobbyHint.ZIndex = 32
	lobbyHint.Parent = lobbyPanel

	local closeButton = Instance.new("TextButton")
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, -24, 0, 18)
	closeButton.Size = UDim2.fromOffset(120, 42)
	closeButton.BackgroundColor3 = PANEL_LIGHT
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Text = "Close"
	closeButton.TextColor3 = TEXT
	closeButton.TextSize = 18
	closeButton.ZIndex = 32
	closeButton.Parent = lobbyPanel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 10)
	closeCorner.Parent = closeButton

	local chestList = Instance.new("ScrollingFrame")
	chestList.BackgroundTransparency = 1
	chestList.BorderSizePixel = 0
	chestList.Position = UDim2.fromOffset(24, 92)
	chestList.Size = UDim2.new(1, -48, 1, -116)
	chestList.CanvasSize = UDim2.fromOffset(0, 0)
	chestList.ScrollBarThickness = 8
	chestList.ZIndex = 32
	chestList.Parent = lobbyPanel

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 12)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = chestList

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		chestList.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 8)
	end)

	local resultPopup = Instance.new("Frame")
	resultPopup.Name = "OpenResultPopup"
	resultPopup.AnchorPoint = Vector2.new(0.5, 0.5)
	resultPopup.Position = UDim2.fromScale(0.5, 0.5)
	resultPopup.Size = UDim2.fromOffset(360, 150)
	resultPopup.BackgroundColor3 = PANEL
	resultPopup.BorderSizePixel = 0
	resultPopup.Visible = false
	resultPopup.ZIndex = 40
	resultPopup.Parent = screenGui

	local resultCorner = Instance.new("UICorner")
	resultCorner.CornerRadius = UDim.new(0, 14)
	resultCorner.Parent = resultPopup

	local resultStroke = Instance.new("UIStroke")
	resultStroke.Thickness = 2
	resultStroke.Parent = resultPopup

	local resultTitle = Instance.new("TextLabel")
	resultTitle.BackgroundTransparency = 1
	resultTitle.Position = UDim2.fromOffset(20, 16)
	resultTitle.Size = UDim2.new(1, -40, 0, 30)
	resultTitle.Font = Enum.Font.GothamBold
	resultTitle.Text = "Chest Opened!"
	resultTitle.TextColor3 = GOLD
	resultTitle.TextSize = 24
	resultTitle.TextXAlignment = Enum.TextXAlignment.Left
	resultTitle.Parent = resultPopup

	local resultBody = Instance.new("TextLabel")
	resultBody.BackgroundTransparency = 1
	resultBody.Position = UDim2.fromOffset(20, 52)
	resultBody.Size = UDim2.new(1, -40, 0, 72)
	resultBody.Font = Enum.Font.Gotham
	resultBody.Text = ""
	resultBody.TextColor3 = TEXT
	resultBody.TextWrapped = true
	resultBody.TextSize = 18
	resultBody.TextXAlignment = Enum.TextXAlignment.Left
	resultBody.TextYAlignment = Enum.TextYAlignment.Top
	resultBody.Parent = resultPopup

	local popupHideToken = 0
	local resultHideToken = 0

	local function hideDungeonPopup()
		popupOverlay.Visible = false
		for _, child in previewHost:GetChildren() do
			child:Destroy()
		end
	end

	local function showDungeonPopup(payload: any)
		if typeof(payload) ~= "table" then
			return
		end

		local tierId = if typeof(payload.tierId) == "string" then payload.tierId else "Common"
		local tier = TreasureConfig.getTier(tierId)
		local tierName = if typeof(payload.tierName) == "string" then payload.tierName else tier.displayName
		local runChestCount = if typeof(payload.runChestCount) == "number" then payload.runChestCount else 1

		popupStroke.Color = tier.glowColor
		popupTitle.Text = `{tierName} Found!`
		popupCount.Text = `Run chests secured: {runChestCount}`
		for _, child in previewHost:GetChildren() do
			child:Destroy()
		end
		mountChestPreview(previewHost, tierId, 240)

		popupPanel.Size = UDim2.fromOffset(280, 320)
		popupOverlay.Visible = true
		popupPanel.BackgroundTransparency = 0

		local tween = TweenService:Create(popupPanel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(320, 360),
		})
		tween:Play()

		popupHideToken += 1
		local token = popupHideToken
		task.delay(TreasureConfig.DUNGEON_POPUP_SECONDS, function()
			if popupHideToken ~= token then
				return
			end
			hideDungeonPopup()
		end)
	end

	local function renderLobbyMenu()
		for _, child in chestList:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		for index, chest in lobbyChests do
			local tier = TreasureConfig.getTier(chest.tierId)
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -8, 0, 112)
			row.BackgroundColor3 = PANEL_LIGHT
			row.BorderSizePixel = 0
			row.LayoutOrder = index
			row.ZIndex = 33
			row.Parent = chestList

			local rowCorner = Instance.new("UICorner")
			rowCorner.CornerRadius = UDim.new(0, 12)
			rowCorner.Parent = row

			local previewFrame = Instance.new("Frame")
			previewFrame.BackgroundTransparency = 1
			previewFrame.Position = UDim2.fromOffset(12, 8)
			previewFrame.Size = UDim2.fromOffset(96, 96)
			previewFrame.ZIndex = 34
			previewFrame.Parent = row
			mountChestPreview(previewFrame, chest.tierId, 96)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.BackgroundTransparency = 1
			nameLabel.Position = UDim2.fromOffset(120, 16)
			nameLabel.Size = UDim2.new(1, -260, 0, 28)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.Text = chest.tierName
			nameLabel.TextColor3 = TEXT
			nameLabel.TextSize = 22
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.ZIndex = 34
			nameLabel.Parent = row

			local depthLabel = Instance.new("TextLabel")
			depthLabel.BackgroundTransparency = 1
			depthLabel.Position = UDim2.fromOffset(120, 46)
			depthLabel.Size = UDim2.new(1, -260, 0, 24)
			depthLabel.Font = Enum.Font.Gotham
			depthLabel.Text = `Found at depth {chest.roomDepth}`
			depthLabel.TextColor3 = TEXT_DIM
			depthLabel.TextSize = 15
			depthLabel.TextXAlignment = Enum.TextXAlignment.Left
			depthLabel.ZIndex = 34
			depthLabel.Parent = row

			local openButton = Instance.new("TextButton")
			openButton.AnchorPoint = Vector2.new(1, 0.5)
			openButton.Position = UDim2.new(1, -12, 0.5, 0)
			openButton.Size = UDim2.fromOffset(120, 44)
			openButton.BackgroundColor3 = tier.trimColor
			openButton.BorderSizePixel = 0
			openButton.Font = Enum.Font.GothamBold
			openButton.Text = "Open"
			openButton.TextColor3 = Color3.new(0.08, 0.06, 0.05)
			openButton.TextSize = 18
			openButton.ZIndex = 34
			openButton.Parent = row

			local openCorner = Instance.new("UICorner")
			openCorner.CornerRadius = UDim.new(0, 10)
			openCorner.Parent = openButton

			openButton.MouseButton1Click:Connect(function()
				openChestEvent:FireServer(index)
			end)
		end
	end

	local reopenButton = Instance.new("TextButton")
	reopenButton.Name = "ReopenTreasureMenu"
	reopenButton.AnchorPoint = Vector2.new(0, 1)
	reopenButton.Position = UDim2.new(0, 16, 1, -16)
	reopenButton.Size = UDim2.fromOffset(180, 48)
	reopenButton.BackgroundColor3 = PANEL
	reopenButton.BorderSizePixel = 0
	reopenButton.Font = Enum.Font.GothamBold
	reopenButton.Text = "Treasure Chests"
	reopenButton.TextColor3 = GOLD
	reopenButton.TextSize = 16
	reopenButton.Visible = false
	reopenButton.ZIndex = 25
	reopenButton.Parent = screenGui

	local reopenCorner = Instance.new("UICorner")
	reopenCorner.CornerRadius = UDim.new(0, 10)
	reopenCorner.Parent = reopenButton

	local function updateReopenButton()
		reopenButton.Visible = currentPhase == "Lobby" and #lobbyChests > 0 and not lobbyOverlay.Visible
		reopenButton.Text = `Treasure Chests ({#lobbyChests})`
	end

	local function updateLobbyMenuVisibility()
		local shouldShow = currentPhase == "Lobby" and #lobbyChests > 0
		lobbyOverlay.Visible = shouldShow
		if shouldShow then
			renderLobbyMenu()
		end
		updateReopenButton()
	end

	local function showOpenResult(loot: any)
		if typeof(loot) ~= "table" then
			return
		end

		local tierId = if typeof(loot.tierId) == "string" then loot.tierId else "Common"
		local tier = TreasureConfig.getTier(tierId)
		local gold = if typeof(loot.gold) == "number" then loot.gold else 0
		local tierName = if typeof(loot.tierName) == "string" then loot.tierName else tier.displayName
		local remaining = if typeof(loot.remainingChests) == "number" then loot.remainingChests else 0

		resultStroke.Color = tier.glowColor
		resultTitle.Text = `{tierName} Opened!`
		resultBody.Text = `You earned {gold} gold.\n{remaining} chest(s) remaining.`
		resultPopup.Visible = true

		resultHideToken += 1
		local token = resultHideToken
		task.delay(2.4, function()
			if resultHideToken ~= token then
				return
			end
			resultPopup.Visible = false
		end)
	end

	awardedEvent.OnClientEvent:Connect(showDungeonPopup)

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
		updateLobbyMenuVisibility()
	end)

	openedEvent.OnClientEvent:Connect(function(loot)
		showOpenResult(loot)
		updateLobbyMenuVisibility()
	end)

	phaseStateEvent.OnClientEvent:Connect(function(phase: string)
		if phase == "Lobby" or phase == "Dungeon" then
			currentPhase = phase
			if phase == "Dungeon" then
				hideDungeonPopup()
				lobbyOverlay.Visible = false
				updateReopenButton()
			else
				updateLobbyMenuVisibility()
			end
		end
	end)

	closeButton.MouseButton1Click:Connect(function()
		lobbyOverlay.Visible = false
		updateReopenButton()
	end)

	reopenButton.MouseButton1Click:Connect(function()
		lobbyOverlay.Visible = true
		updateReopenButton()
	end)
end

return TreasureChestClient
