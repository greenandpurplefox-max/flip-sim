local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local BroadswordConfig = require(ReplicatedStorage.Shared.BroadswordConfig)

local BroadswordClient = {}

local player = Players.LocalPlayer
local swinging = false
local lastSwing = 0
local swingConnection: RBXScriptConnection? = nil
local slashTracks: { [Humanoid]: AnimationTrack } = {}

local function getSlashAnimationIds(character: Model): { string }
	if character:FindFirstChild("UpperTorso") then
		return BroadswordConfig.R15_SLASH_ANIMATIONS
	end
	return BroadswordConfig.R6_SLASH_ANIMATIONS
end

local function getAnimator(humanoid: Humanoid): Animator
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	return animator
end

local function tryLoadSlashTrack(humanoid: Humanoid, character: Model): AnimationTrack?
	local animator = getAnimator(humanoid)

	for _, animationId in getSlashAnimationIds(character) do
		local animation = Instance.new("Animation")
		animation.AnimationId = animationId

		local preloadOk = pcall(function()
			ContentProvider:PreloadAsync({ animation })
		end)

		if not preloadOk then
			continue
		end

		local loadOk, track = pcall(function()
			return animator:LoadAnimation(animation)
		end)

		if loadOk and track and track.Length > 0 then
			track.Priority = Enum.AnimationPriority.Action4
			track.Looped = false
			return track
		end
	end

	return nil
end

local function getSlashTrack(humanoid: Humanoid, character: Model): AnimationTrack?
	local existingTrack = slashTracks[humanoid]
	if existingTrack then
		return existingTrack
	end

	local track = tryLoadSlashTrack(humanoid, character)
	if track then
		slashTracks[humanoid] = track
	end
	return track
end

local function clearSlashTrack(humanoid: Humanoid)
	local track = slashTracks[humanoid]
	if track then
		track:Stop(0)
		slashTracks[humanoid] = nil
	end
end

local function stopSwing(tool: Tool)
	if swingConnection then
		swingConnection:Disconnect()
		swingConnection = nil
	end

	tool.Grip = BroadswordConfig.SHOULDER_GRIP
	swinging = false
end

local function playSwing(character: Model, tool: Tool)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		swinging = false
		return
	end

	local slashTrack = getSlashTrack(humanoid, character)
	local usesAnimation = slashTrack ~= nil
	local swingDuration = BroadswordConfig.getSwingDuration(usesAnimation, slashTrack and slashTrack.Length)

	if usesAnimation then
		tool.Grip = BroadswordConfig.COMBAT_GRIP
		slashTrack:Stop(0.05)
		slashTrack:Play(0.08, 1, 1)
	else
		tool.Grip = BroadswordConfig.SHOULDER_GRIP
	end

	local startTime = os.clock()
	local recovering = false
	local recoveryStart = 0
	local recoveryDuration = 0.12

	if swingConnection then
		swingConnection:Disconnect()
	end

	swingConnection = RunService.RenderStepped:Connect(function()
		if not character.Parent or tool.Parent ~= character then
			if slashTrack then
				slashTrack:Stop(0.05)
			end
			stopSwing(tool)
			return
		end

		local elapsed = os.clock() - startTime

		if recovering then
			local recoveryElapsed = os.clock() - recoveryStart
			local alpha = math.clamp(recoveryElapsed / recoveryDuration, 0, 1)
			tool.Grip = BroadswordConfig.COMBAT_GRIP:Lerp(BroadswordConfig.SHOULDER_GRIP, alpha)
			if recoveryElapsed >= recoveryDuration then
				stopSwing(tool)
			end
			return
		end

		if usesAnimation then
			tool.Grip = BroadswordConfig.COMBAT_GRIP
		else
			tool.Grip = BroadswordConfig.sample(elapsed)
		end

		if elapsed >= swingDuration then
			if slashTrack then
				slashTrack:Stop(0.1)
			end
			recovering = true
			recoveryStart = os.clock()
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
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			clearSlashTrack(humanoid)
		end)
	end

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

	character.AncestryChanged:Connect(function(_, parent)
		if parent == nil and humanoid then
			clearSlashTrack(humanoid)
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
		slashTracks = {}
		bindCharacter(character)
	end)
end

return BroadswordClient
