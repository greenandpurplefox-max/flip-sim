local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local WaveUI = {}

function WaveUI.init()
	local startWaveEvent = ReplicatedStorage:WaitForChild("StartWave") :: RemoteEvent

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WaveUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local button = Instance.new("TextButton")
	button.Name = "StartWaveButton"
	button.Size = UDim2.fromOffset(220, 52)
	button.Position = UDim2.new(0.5, -110, 0, 16)
	button.BackgroundColor3 = Color3.fromRGB(200, 45, 45)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = "Start Wave"
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 22
	button.AutoButtonColor = true
	button.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(120, 20, 20)
	stroke.Thickness = 2
	stroke.Parent = button

	button.MouseButton1Click:Connect(function()
		button.Text = "Wave Incoming..."
		button.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
		startWaveEvent:FireServer()

		task.delay(3, function()
			if button.Parent then
				button.Text = "Start Wave"
				button.BackgroundColor3 = Color3.fromRGB(200, 45, 45)
			end
		end)
	end)
end

return WaveUI
