local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local BroadswordConfig = require(ReplicatedStorage.Shared.BroadswordConfig)

local BroadswordClient = {}

local player = Players.LocalPlayer
local swinging = false
local lastSwing = 0
local swingConnection: RBXScriptConnection? = nil

local function getLeftHand(character: Model): BasePart?
	return (character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")) :: BasePart?
end

local function attachLeftHand(character: Model, tool: Tool): Weld?
	local leftHand = getLeftHand(character)
	local leftGrip = tool:FindFirstChild("LeftHandGrip") :: BasePart?
	if not leftHand or not leftGrip then
		return nil
	end

	local existing = leftHand:FindFirstChild("TwoHandWeld")
	if existing then
		existing:Destroy()
	end

	local weld = Instance.new("Weld")
	weld.Name = "TwoHandWeld"
	weld.Part0 = leftHand
	weld.Part1 = leftGrip
	weld.C0 = CFrame.new(0, -0.05, 0) * CFrame.Angles(math.rad(-90), 0, math.rad(90))
	weld.C1 = CFrame.new()
	weld.Parent = leftHand
	return weld
end

local function detachLeftHand(character: Model)
	local leftHand = getLeftHand(character)
	if not leftHand then
		return
	end

	local weld = leftHand:FindFirstChild("TwoHandWeld")
	if weld then
		weld:Destroy()
	end
end

local function applyBodyRotation(root: BasePart, startCFrame: CFrame, elapsed: number)
	local lookVector = startCFrame.LookVector
	local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
	if flatLook.Magnitude < 0.001 then
		return
	end

	local baseCFrame = CFrame.new(startCFrame.Position, startCFrame.Position + flatLook.Unit)
	root.CFrame = baseCFrame * BroadswordConfig.getBodyOffset(elapsed)
end

local function stopSwing(tool: Tool, character: Model?, startRootCFrame: CFrame?)
	if swingConnection then
		swingConnection:Disconnect()
		swingConnection = nil
	end

	if character then
		detachLeftHand(character)
	end

	if character and startRootCFrame then
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local lookVector = startRootCFrame.LookVector
			local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
			if flatLook.Magnitude > 0.001 then
				root.CFrame = CFrame.new(root.Position, root.Position + flatLook.Unit)
			end
		end
	end

	tool.Grip = BroadswordConfig.SHOULDER_GRIP
	swinging = false
end

local function playSwing(character: Model, tool: Tool)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		swinging = false
		return
	end

	local swingDuration = BroadswordConfig.getSwingDuration()
	local startRootCFrame = root.CFrame
	local leftHandWeld: Weld? = nil

	tool.Grip = BroadswordConfig.SHOULDER_GRIP

	local startTime = os.clock()

	if swingConnection then
		swingConnection:Disconnect()
	end

	swingConnection = RunService.RenderStepped:Connect(function()
		if not character.Parent or tool.Parent ~= character then
			stopSwing(tool, character, startRootCFrame)
			return
		end

		local elapsed = os.clock() - startTime

		tool.Grip = BroadswordConfig.getGripForSwing(elapsed)
		applyBodyRotation(root, startRootCFrame, elapsed)

		if BroadswordConfig.isTwoHandPhase(elapsed) then
			if not leftHandWeld or not leftHandWeld.Parent then
				leftHandWeld = attachLeftHand(character, tool)
			end
		elseif leftHandWeld then
			detachLeftHand(character)
			leftHandWeld = nil
		end

		if elapsed >= swingDuration then
			stopSwing(tool, character, startRootCFrame)
		end
	end)
end

local function onToolActivated(tool: Tool)
	if swinging then
		return
	end

	local character = tool.Parent
	if not character or not character:IsA("Model") or character ~= player.Character then
		return
	end

	local now = os.clock()
	if now - lastSwing < BroadswordConfig.SWING_COOLDOWN then
		return
	end

	swinging = true
	lastSwing = now
	playSwing(character, tool)
end

local function bindTool(tool: Tool)
	if tool:GetAttribute("ClientBound") then
		return
	end

	tool:SetAttribute("ClientBound", true)

	tool.Equipped:Connect(function()
		tool.Grip = BroadswordConfig.SHOULDER_GRIP
	end)

	tool.Activated:Connect(function()
		onToolActivated(tool)
	end)
end

local function bindCharacter(character: Model)
	for _, child in character:GetChildren() do
		if child:IsA("Tool") and child.Name == "Broadsword" then
			bindTool(child)
		end
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == "Broadsword" then
			bindTool(child)
		end
	end)
end

function BroadswordClient.init()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)

	if player.Character then
		bindCharacter(player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		bindCharacter(character)
	end)
end

return BroadswordClient
