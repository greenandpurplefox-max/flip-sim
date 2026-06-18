local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)
local UiCorner = require(script.Parent.UiCorner)

local TrainingZoneClient = {}

local DAMAGE_COLOR = Color3.fromRGB(255, 210, 96)
local SHADOW = Color3.fromRGB(8, 4, 10)

local function showWorldDamageNumber(screenGui: ScreenGui, amount: number, worldPosition: Vector3)
	if amount <= 0 then
		return
	end

	local anchor = Instance.new("Part")
	anchor.Name = "TrainingDamageAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(worldPosition)
	anchor.Parent = workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(96, 40)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.Fantasy
	label.Text = tostring(math.floor(amount))
	label.TextColor3 = DAMAGE_COLOR
	label.TextSize = 28
	label.TextStrokeColor3 = SHADOW
	label.TextStrokeTransparency = 0
	label.Parent = billboard

	local startPosition = worldPosition
	local elapsed = 0
	local duration = 1.1
	local rise = 3.5

	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(deltaTime)
		elapsed += deltaTime
		if elapsed >= duration then
			connection:Disconnect()
			anchor:Destroy()
			return
		end

		local alpha = elapsed / duration
		anchor.CFrame = CFrame.new(startPosition + Vector3.new(0, rise * alpha, 0))
		if alpha > 0.45 then
			local fade = (alpha - 0.45) / 0.55
			label.TextTransparency = fade
			label.TextStrokeTransparency = fade
		end
	end)
end

function TrainingZoneClient.init()
	if not LobbyConfig.USE_LOBBY then
		return
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local trainingZoneStateEvent = ReplicatedStorage:WaitForChild("TrainingZoneState") :: RemoteEvent
	local trainingDummyDamageEvent = ReplicatedStorage:WaitForChild("TrainingDummyDamage") :: RemoteEvent

	local inTrainingZone = player:GetAttribute("InTrainingZone") == true

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TrainingZoneUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local hintFrame = Instance.new("Frame")
	hintFrame.Name = "TrainingHint"
	hintFrame.AnchorPoint = Vector2.new(0.5, 1)
	hintFrame.Position = UDim2.new(0.5, 0, 1, -24)
	hintFrame.Size = UDim2.fromOffset(520, 56)
	hintFrame.BackgroundColor3 = Color3.fromRGB(24, 18, 16)
	hintFrame.BorderSizePixel = 0
	hintFrame.Visible = inTrainingZone
	hintFrame.Parent = screenGui

	UiCorner.apply(hintFrame, 10)

	local hintStroke = Instance.new("UIStroke")
	hintStroke.Color = Color3.fromRGB(255, 196, 96)
	hintStroke.Thickness = 2
	hintStroke.Parent = hintFrame

	local hintLabel = Instance.new("TextLabel")
	hintLabel.BackgroundTransparency = 1
	hintLabel.Size = UDim2.fromScale(1, 1)
	hintLabel.Font = Enum.Font.Gotham
	hintLabel.Text = "Training Grounds — swing your weapon or press E to cast. Walk back to the lobby to manage loadouts."
	hintLabel.TextColor3 = Color3.fromRGB(244, 228, 196)
	hintLabel.TextSize = 16
	hintLabel.TextWrapped = true
	hintLabel.Parent = hintFrame

	local function renderTrainingState()
		hintFrame.Visible = inTrainingZone
	end

	trainingZoneStateEvent.OnClientEvent:Connect(function(active: boolean)
		if typeof(active) == "boolean" then
			inTrainingZone = active
			renderTrainingState()
		end
	end)

	player:GetAttributeChangedSignal("InTrainingZone"):Connect(function()
		inTrainingZone = player:GetAttribute("InTrainingZone") == true
		renderTrainingState()
	end)

	trainingDummyDamageEvent.OnClientEvent:Connect(function(damage: number, worldPosition: Vector3)
		if typeof(damage) ~= "number" or typeof(worldPosition) ~= "Vector3" then
			return
		end

		showWorldDamageNumber(screenGui, damage, worldPosition)
	end)

	renderTrainingState()
end

return TrainingZoneClient
