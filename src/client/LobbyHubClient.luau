local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)

local LobbyHubClient = {}

local GOLD = Color3.fromRGB(214, 176, 72)
local PANEL = Color3.fromRGB(24, 18, 16)
local TEXT = Color3.fromRGB(244, 228, 196)

function LobbyHubClient.init()
	if not LobbyConfig.USE_LOBBY then
		return
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local phaseStateEvent = ReplicatedStorage:WaitForChild("PlayerPhaseState") :: RemoteEvent
	local profileStateEvent = ReplicatedStorage:WaitForChild("PlayerProfileState") :: RemoteEvent

	local currentPhase = "Lobby"
	local walletGold = LobbyConfig.STARTER_GOLD

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LobbyHubUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = true
	screenGui.Parent = playerGui

	local walletFrame = Instance.new("Frame")
	walletFrame.Name = "Wallet"
	walletFrame.Size = UDim2.fromOffset(220, 54)
	walletFrame.Position = UDim2.new(1, -236, 0, 12)
	walletFrame.BackgroundColor3 = PANEL
	walletFrame.BorderSizePixel = 0
	walletFrame.Parent = screenGui

	local walletCorner = Instance.new("UICorner")
	walletCorner.CornerRadius = UDim.new(0, 10)
	walletCorner.Parent = walletFrame

	local walletStroke = Instance.new("UIStroke")
	walletStroke.Color = GOLD
	walletStroke.Thickness = 2
	walletStroke.Parent = walletFrame

	local walletLabel = Instance.new("TextLabel")
	walletLabel.BackgroundTransparency = 1
	walletLabel.Size = UDim2.fromScale(1, 1)
	walletLabel.Font = Enum.Font.GothamBold
	walletLabel.Text = `Gold: {walletGold}`
	walletLabel.TextColor3 = GOLD
	walletLabel.TextSize = 22
	walletLabel.Parent = walletFrame

	local hintFrame = Instance.new("Frame")
	hintFrame.Name = "LobbyHint"
	hintFrame.Size = UDim2.fromOffset(420, 72)
	hintFrame.Position = UDim2.new(0.5, -210, 1, -92)
	hintFrame.BackgroundColor3 = PANEL
	hintFrame.BorderSizePixel = 0
	hintFrame.Parent = screenGui

	local hintCorner = Instance.new("UICorner")
	hintCorner.CornerRadius = UDim.new(0, 10)
	hintCorner.Parent = hintFrame

	local hintStroke = Instance.new("UIStroke")
	hintStroke.Color = GOLD
	hintStroke.Thickness = 2
	hintStroke.Parent = hintFrame

	local hintLabel = Instance.new("TextLabel")
	hintLabel.BackgroundTransparency = 1
	hintLabel.Size = UDim2.fromScale(1, 1)
	hintLabel.Font = Enum.Font.Gotham
	hintLabel.Text = "Talk to Harold at the forge for dungeon tips.\nOpen Weapons to equip and upgrade. Stand on the green gate to enter."
	hintLabel.TextColor3 = TEXT
	hintLabel.TextSize = 16
	hintLabel.TextWrapped = true
	hintLabel.Parent = hintFrame

	local dungeonHint = Instance.new("TextLabel")
	dungeonHint.Name = "DungeonHint"
	dungeonHint.Size = UDim2.fromOffset(360, 48)
	dungeonHint.Position = UDim2.new(0.5, -180, 0, 12)
	dungeonHint.BackgroundColor3 = PANEL
	dungeonHint.BorderSizePixel = 0
	dungeonHint.Font = Enum.Font.GothamBold
	dungeonHint.Text = "Dungeon run active"
	dungeonHint.TextColor3 = Color3.fromRGB(255, 120, 96)
	dungeonHint.TextSize = 18
	dungeonHint.Visible = false
	dungeonHint.Parent = screenGui

	local dungeonCorner = Instance.new("UICorner")
	dungeonCorner.CornerRadius = UDim.new(0, 10)
	dungeonCorner.Parent = dungeonHint

	local function renderPhase()
		local inLobby = currentPhase == "Lobby"
		walletFrame.Visible = inLobby
		hintFrame.Visible = inLobby
		dungeonHint.Visible = not inLobby
	end

	local function renderWallet()
		walletLabel.Text = `Gold: {walletGold}`
	end

	profileStateEvent.OnClientEvent:Connect(function(snapshot)
		if typeof(snapshot) == "table" and typeof(snapshot.gold) == "number" then
			walletGold = snapshot.gold
			renderWallet()
		end
	end)

	phaseStateEvent.OnClientEvent:Connect(function(phase: string)
		if phase == "Lobby" or phase == "Dungeon" then
			currentPhase = phase
			renderPhase()
		end
	end)

	renderPhase()
	renderWallet()
end

return LobbyHubClient
