local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BlacksmithConfig = require(ReplicatedStorage.Shared.BlacksmithConfig)
local BobConfig = require(ReplicatedStorage.Shared.BobConfig)
local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)
local UiCorner = require(script.Parent.UiCorner)
local InfuserMenuClient = require(script.Parent.InfuserMenuClient)
local WeaponMenuClient = require(script.Parent.WeaponMenuClient)

local BlacksmithDialogueClient = {}

local GOLD = Color3.fromRGB(214, 176, 72)
local PANEL = Color3.fromRGB(24, 18, 16)
local PANEL_LIGHT = Color3.fromRGB(42, 34, 28)
local TEXT = Color3.fromRGB(244, 228, 196)
local TEXT_DIM = Color3.fromRGB(170, 154, 128)

type DialogueNpc = {
	objectText: string,
	lines: { string },
}

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
	local activeNpc: DialogueNpc? = nil

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NpcDialogueUI"
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

	UiCorner.apply(panel, 14)

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = GOLD
	panelStroke.Thickness = 2
	panelStroke.Parent = panel

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(20, 14)
	nameLabel.Size = UDim2.new(1, -40, 0, 28)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = ""
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

	UiCorner.apply(continueButton, 10)

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

	UiCorner.apply(leaveButton, 10)

	local function renderLine()
		if not activeNpc then
			return
		end

		nameLabel.Text = activeNpc.objectText
		bodyLabel.Text = activeNpc.lines[dialogueIndex] or ""
		progressLabel.Text = `{dialogueIndex}/{#activeNpc.lines}`
		continueButton.Text = if dialogueIndex >= #activeNpc.lines then "Done" else "Continue"
	end

	local function closeDialogue()
		dialogueOpen = false
		activeNpc = nil
		screenGui.Enabled = false
	end

	local function openDialogue(npc: DialogueNpc)
		if currentPhase ~= "Lobby" then
			return
		end

		activeNpc = npc
		dialogueIndex = 1
		dialogueOpen = true
		screenGui.Enabled = true
		renderLine()
	end

	local function advanceDialogue()
		if not activeNpc then
			return
		end

		if dialogueIndex >= #activeNpc.lines then
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

	local function bindDialogueNpc(model: Model, npc: DialogueNpc)
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

			if dialogueOpen and activeNpc == npc then
				advanceDialogue()
			else
				openDialogue(npc)
			end
		end)
	end

	local function bindInfuser(model: Model)
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

			InfuserMenuClient.open()
		end)
	end

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

			WeaponMenuClient.openToTab("Upgrade")
		end)
	end

	local bobNpc: DialogueNpc = {
		objectText = BobConfig.PROMPT_OBJECT_TEXT,
		lines = BobConfig.getDialogueLines(),
	}

	task.spawn(function()
		local lobby = workspace:WaitForChild("Lobby", 30)
		if not lobby then
			return
		end

		local function tryBind(child: Instance)
			if not child:IsA("Model") then
				return
			end

			if child.Name == "Blacksmith" then
				bindBlacksmith(child)
			elseif child.Name == "Bob" then
				bindDialogueNpc(child, bobNpc)
			elseif child.Name == "Infuser" then
				bindInfuser(child)
			end
		end

		for _, child in lobby:GetChildren() do
			tryBind(child)
		end

		lobby.ChildAdded:Connect(tryBind)
	end)
end

return BlacksmithDialogueClient
