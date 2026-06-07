local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local WaveUI = {}

local START_COLOR = Color3.fromRGB(200, 45, 45)
local START_STROKE = Color3.fromRGB(120, 20, 20)
local DISABLED_COLOR = Color3.fromRGB(140, 140, 140)
local DISABLED_STROKE = Color3.fromRGB(90, 90, 90)

function WaveUI.init()
	local startWaveEvent = ReplicatedStorage:WaitForChild("StartWave") :: RemoteEvent
	local waveStateEvent = ReplicatedStorage:WaitForChild("WaveState") :: RemoteEvent

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WaveUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local button = Instance.new("TextButton")
	button.Name = "StartWaveButton"
	button.Size = UDim2.fromOffset(260, 52)
	button.Position = UDim2.new(0.5, -130, 0, 16)
	button.BackgroundColor3 = START_COLOR
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = "Start Wave"
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 20
	button.AutoButtonColor = true
	button.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = START_STROKE
	stroke.Thickness = 2
	stroke.Parent = button

	local waveLocked = false

	local function setWaveState(
		inProgress: boolean,
		remaining: number,
		total: number,
		wave: number,
		status: string,
		_loadoutLocked: boolean?
	)
		waveLocked = inProgress or status == "intermission"

		if status == "intermission" then
			button.Text = "Next wave starting..."
			button.BackgroundColor3 = DISABLED_COLOR
			stroke.Color = DISABLED_STROKE
			button.AutoButtonColor = false
		elseif inProgress and total > 0 then
			button.Text = `Wave {wave}: {remaining}/{total} left`
			button.BackgroundColor3 = DISABLED_COLOR
			stroke.Color = DISABLED_STROKE
			button.AutoButtonColor = false
		else
			button.Text = if wave > 0 then "Start Wave" else "Start Wave 1"
			button.BackgroundColor3 = START_COLOR
			stroke.Color = START_STROKE
			button.AutoButtonColor = true
		end
	end

	button.MouseButton1Click:Connect(function()
		if waveLocked then
			return
		end

		startWaveEvent:FireServer()
	end)

	waveStateEvent.OnClientEvent:Connect(setWaveState)
end

return WaveUI
