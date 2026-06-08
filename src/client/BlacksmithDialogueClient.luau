local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BlacksmithConfig = require(ReplicatedStorage.Shared.BlacksmithConfig)
local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)

local BlacksmithDialogueClient = {}

local GOLD = Color3.fromRGB(214, 176, 72)
local PANEL = Color3.fromRGB(24, 18, 16)
local PANEL_LIGHT = Color3.fromRGB(42, 34, 28)
local TEXT = Color3.fromRGB(244, 228, 196)
local TEXT_DIM = Color3.fromRGB(170, 154, 128)

function BlacksmithDialogueClient.init()
	if not LobbyConfig.USE_LOBBY then
		return
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local phaseStateEvent = ReplicatedStorage:WaitForChild("PlayerPhaseState") :: RemoteEvent

	local currentPhase = "Lobby"
	local dialogueOpen = false
	local dialogueIndex = 1
	local dialogueLines = BlacksmithConfig.getDialogueLines()

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BlacksmithDialogueUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "DialoguePanel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -24)
	panel.Size = UDim2.fromOffset(560, 190)
	panel.BackgroundColor3 = PANEL
	panel.BorderSizePixel = 0
	panel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 14)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = GOLD
	panelStroke.Thickness = 2
	panelStroke.Parent = panel

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(20, 14)
	nameLabel.Size = UDim2.new(1, -40, 0, 28)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = BlacksmithConfig.PROMPT_OBJECT_TEXT
	nameLabel.TextColor3 = GOLD
	nameLabel.TextSize = 22
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = panel

	local bodyLabel = Instance.new("TextLabel")
	bodyLabel.BackgroundTransparency = 1
	bodyLabel.Position = UDim2.fromOffset(20, 48)
	bodyLabel.Size = UDim2.new(1, -40, 0, 88)
	bodyLabel.Font = Enum.Font.Gotham
	bodyLabel.Text = ""
	bodyLabel.TextColor3 = TEXT
	bodyLabel.TextSize = 17
	bodyLabel.TextWrapped = true
	bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
	bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
	bodyLabel.Parent = panel

	local progressLabel = Instance.new("TextLabel")
	progressLabel.BackgroundTransparency = 1
	progressLabel.AnchorPoint = Vector2.new(1, 1)
	progressLabel.Position = UDim2.new(1, -20, 1, -16)
	progressLabel.Size = UDim2.fromOffset(80, 22)
	progressLabel.Font = Enum.Font.Gotham
	progressLabel.Text = "1/5"
	progressLabel.TextColor3 = TEXT_DIM
	progressLabel.TextSize = 14
	progressLabel.TextXAlignment = Enum.TextXAlignment.Right
	progressLabel.Parent = panel

	local continueButton = Instance.new("TextButton")
	continueButton.AnchorPoint = Vector2.new(0, 1)
	continueButton.Position = UDim2.new(0, 20, 1, -16)
	continueButton.Size = UDim2.fromOffset(140, 40)
	continueButton.BackgroundColor3 = GOLD
	continueButton.BorderSizePixel = 0
	continueButton.Font = Enum.Font.GothamBold
	continueButton.Text = "Continue"
	continueButton.TextColor3 = Color3.fromRGB(24, 18, 12)
	continueButton.TextSize = 16
	continueButton.Parent = panel

	local continueCorner = Instance.new("UICorner")
	continueCorner.CornerRadius = UDim.new(0, 10)
	continueCorner.Parent = continueButton

	local leaveButton = Instance.new("TextButton")
	leaveButton.AnchorPoint = Vector2.new(0, 1)
	leaveButton.Position = UDim2.new(0, 170, 1, -16)
	leaveButton.Size = UDim2.fromOffset(120, 40)
	leaveButton.BackgroundColor3 = PANEL_LIGHT
	leaveButton.BorderSizePixel = 0
	leaveButton.Font = Enum.Font.GothamBold
	leaveButton.Text = "Leave"
	leaveButton.TextColor3 = TEXT
	leaveButton.TextSize = 16
	leaveButton.Parent = panel

	local leaveCorner = Instance.new("UICorner")
	leaveCorner.CornerRadius = UDim.new(0, 10)
	leaveCorner.Parent = leaveButton

	local function renderLine()
		bodyLabel.Text = dialogueLines[dialogueIndex] or ""
		progressLabel.Text = `{dialogueIndex}/{#dialogueLines}`
		local onLastLine = dialogueIndex >= #dialogueLines
		continueButton.Text = if onLastLine then "Done" else "Continue"
		continueButton.Visible = true
	end

	local function closeDialogue()
		dialogueOpen = false
		screenGui.Enabled = false
	end

	local function openDialogue()
		if currentPhase ~= "Lobby" then
			return
		end

		dialogueIndex = 1
		dialogueOpen = true
		screenGui.Enabled = true
		renderLine()
	end

	local function advanceDialogue()
		if dialogueIndex >= #dialogueLines then
			closeDialogue()
			return
		end

		dialogueIndex += 1
		renderLine()
	end

	continueButton.MouseButton1Click:Connect(advanceDialogue)
	leaveButton.MouseButton1Click:Connect(closeDialogue)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not dialogueOpen then
			return
		end

		if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return then
			advanceDialogue()
		elseif input.KeyCode == Enum.KeyCode.Escape then
			closeDialogue()
		end
	end)

	phaseStateEvent.OnClientEvent:Connect(function(phase: string)
		if phase == "Lobby" or phase == "Dungeon" then
			currentPhase = phase
			if phase ~= "Lobby" then
				closeDialogue()
			end
		end
	end)

	local function bindBlacksmith(model: Model)
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			return
		end

		local prompt = root:FindFirstChildOfClass("ProximityPrompt")
		if not prompt then
			return
		end

		prompt.Triggered:Connect(function(triggerPlayer)
			if triggerPlayer ~= player or currentPhase ~= "Lobby" then
				return
			end

			if dialogueOpen then
				advanceDialogue()
			else
				openDialogue()
			end
		end)
	end

	task.spawn(function()
		local lobby = workspace:WaitForChild("Lobby", 30)
		if not lobby then
			return
		end

		local existing = lobby:FindFirstChild("Blacksmith")
		if existing and existing:IsA("Model") then
			bindBlacksmith(existing)
		end

		lobby.ChildAdded:Connect(function(child)
			if child.Name == "Blacksmith" and child:IsA("Model") then
				bindBlacksmith(child)
			end
		end)
	end)
end

return BlacksmithDialogueClient
