local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TreasureConfig = require(ReplicatedStorage.Shared.TreasureConfig)

local TreasureChestClient = {}

local GOLD = Color3.fromRGB(214, 176, 72)
local PANEL = Color3.fromRGB(24, 18, 16)
local TEXT = Color3.fromRGB(244, 228, 196)

function TreasureChestClient.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local treasureEvent = ReplicatedStorage:WaitForChild("TreasureChestOpened") :: RemoteEvent

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TreasureChestUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = true
	screenGui.Parent = playerGui

	local popup = Instance.new("Frame")
	popup.Name = "TreasurePopup"
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Position = UDim2.fromScale(0.5, 0.42)
	popup.Size = UDim2.fromOffset(360, 150)
	popup.BackgroundColor3 = PANEL
	popup.BorderSizePixel = 0
	popup.Visible = false
	popup.Parent = screenGui

	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 14)
	popupCorner.Parent = popup

	local popupStroke = Instance.new("UIStroke")
	popupStroke.Thickness = 2
	popupStroke.Parent = popup

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.fromOffset(20, 16)
	titleLabel.Size = UDim2.new(1, -40, 0, 30)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = "Treasure Found!"
	titleLabel.TextColor3 = GOLD
	titleLabel.TextSize = 24
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = popup

	local lootLabel = Instance.new("TextLabel")
	lootLabel.BackgroundTransparency = 1
	lootLabel.Position = UDim2.fromOffset(20, 52)
	lootLabel.Size = UDim2.new(1, -40, 0, 48)
	lootLabel.Font = Enum.Font.Gotham
	lootLabel.Text = "+0 gold"
	lootLabel.TextColor3 = TEXT
	lootLabel.TextSize = 20
	lootLabel.TextWrapped = true
	lootLabel.TextXAlignment = Enum.TextXAlignment.Left
	lootLabel.TextYAlignment = Enum.TextYAlignment.Top
	lootLabel.Parent = popup

	local totalLabel = Instance.new("TextLabel")
	totalLabel.BackgroundTransparency = 1
	totalLabel.Position = UDim2.fromOffset(20, 104)
	totalLabel.Size = UDim2.new(1, -40, 0, 24)
	totalLabel.Font = Enum.Font.GothamBold
	totalLabel.Text = "Run gold: 0"
	totalLabel.TextColor3 = GOLD
	totalLabel.TextSize = 16
	totalLabel.TextXAlignment = Enum.TextXAlignment.Left
	totalLabel.Parent = popup

	local hideToken = 0

	local function hidePopup()
		popup.Visible = false
	end

	local function showPopup(loot: any, totalGold: number)
		if typeof(loot) ~= "table" then
			return
		end

		local tierId = if typeof(loot.tierId) == "string" then loot.tierId else "Common"
		local tier = TreasureConfig.getTier(tierId)
		local gold = if typeof(loot.gold) == "number" then loot.gold else 0
		local tierName = if typeof(loot.tierName) == "string" then loot.tierName else tier.displayName

		popupStroke.Color = tier.glowColor
		titleLabel.Text = `{tierName} Opened!`
		lootLabel.Text = `You found {gold} bonus gold from the chest.`
		totalLabel.Text = `Run gold: {totalGold}`

		popup.Size = UDim2.fromOffset(360, 150)
		popup.Visible = true

		hideToken += 1
		local token = hideToken
		task.delay(2.8, function()
			if hideToken ~= token then
				return
			end
			local tween = TweenService:Create(popup, TweenInfo.new(0.25), {
				BackgroundTransparency = 1,
			})
			tween:Play()
			tween.Completed:Connect(function()
				popup.BackgroundTransparency = 0
				hidePopup()
			end)
		end)
	end

	treasureEvent.OnClientEvent:Connect(showPopup)
end

return TreasureChestClient
