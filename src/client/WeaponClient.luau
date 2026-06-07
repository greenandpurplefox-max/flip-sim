local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local BroadswordPose = require(ReplicatedStorage.Shared.BroadswordPose)
local WeaponCombatConfig = require(ReplicatedStorage.Shared.WeaponCombatConfig)
local WeaponConfig = require(ReplicatedStorage.Shared.WeaponConfig)
local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)

local WeaponClient = {}

local player = Players.LocalPlayer
local swinging = false
local lastSwing = 0
local swingConnection: RBXScriptConnection? = nil
local activeCharacter: Model? = nil
local activeTool: Tool? = nil
local activeMotors: BroadswordPose.ArmMotors = {}
local activeCombatConfig = WeaponCombatConfig.getConfig(WeaponConfig.DEFAULT_WEAPON)

local POSE_BIND = "FlipSimWeaponPose"

local function isWaveWeapon(tool: Tool): boolean
	return WeaponConfig.getWeapon(tool:GetAttribute(WeaponConfig.WEAPON_ATTRIBUTE) :: string) ~= nil
end

local function stopIdlePose()
	RunService:UnbindFromRenderStep(POSE_BIND)

	if activeCharacter and activeTool and activeMotors.rightShoulder then
		BroadswordPose.reset(activeMotors, activeTool, activeCombatConfig.SHOULDER_GRIP)
	end
end

local function startIdlePose(character: Model, tool: Tool)
	stopIdlePose()

	activeCharacter = character
	activeTool = tool
	activeMotors = BroadswordPose.getMotors(character)
	activeCombatConfig = WeaponCombatConfig.getConfigForTool(tool)

	RunService:BindToRenderStep(POSE_BIND, Enum.RenderPriority.Last.Value, function()
		if not character.Parent or tool.Parent ~= character then
			stopIdlePose()
			return
		end

		if swinging then
			return
		end

		BroadswordPose.apply(activeMotors, activeCombatConfig.SHOULDER_POSE, tool)
	end)
end

local function stopSwing(tool: Tool, character: Model?)
	if swingConnection then
		swingConnection:Disconnect()
		swingConnection = nil
	end

	swinging = false

	if character and tool.Parent == character then
		startIdlePose(character, tool)
	end
end

local function playSwing(character: Model, tool: Tool)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		swinging = false
		return
	end

	local combatConfig = WeaponCombatConfig.getConfigForTool(tool)
	stopIdlePose()

	local motors = BroadswordPose.getMotors(character)
	local swingDuration = combatConfig.getSwingDuration()
	local startTime = os.clock()

	BroadswordPose.apply(motors, combatConfig.SHOULDER_POSE, tool)

	if swingConnection then
		swingConnection:Disconnect()
	end

	swingConnection = RunService.RenderStepped:Connect(function()
		if not character.Parent or tool.Parent ~= character then
			stopSwing(tool, character)
			return
		end

		local elapsed = os.clock() - startTime
		local pose = combatConfig.getPoseForSwing(elapsed)
		BroadswordPose.apply(motors, pose, tool)

		if elapsed >= swingDuration then
			stopSwing(tool, character)
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

	local stats = WeaponConfig.getStatsForTool(tool)
	local now = os.clock()
	if now - lastSwing < stats.cooldown then
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

	if not isWaveWeapon(tool) then
		return
	end

	tool:SetAttribute("ClientBound", true)

	tool.Equipped:Connect(function()
		local character = tool.Parent
		if character and character:IsA("Model") then
			startIdlePose(character, tool)
		end
	end)

	tool.Unequipped:Connect(function()
		if activeTool == tool then
			stopIdlePose()
			activeCharacter = nil
			activeTool = nil
			activeMotors = {}
		end
	end)

	tool.Activated:Connect(function()
		onToolActivated(tool)
	end)

	if tool.Parent and tool.Parent == player.Character then
		startIdlePose(tool.Parent, tool)
	end
end

local function bindCharacter(character: Model)
	for _, child in character:GetChildren() do
		if child:IsA("Tool") and isWaveWeapon(child) then
			bindTool(child)
		end
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and isWaveWeapon(child) then
			bindTool(child)
		end
	end)

	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			stopIdlePose()
			if activeTool then
				stopSwing(activeTool, character)
			end
		end
	end)
end

function WeaponClient.init()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)

	local swordHitEvent = ReplicatedStorage:WaitForChild("SwordHitMonster") :: RemoteEvent
	local hitSound = Instance.new("Sound")
	hitSound.Name = "SwordHitSound"
	hitSound.SoundId = WaveConfig.SWORD_HIT_SOUND_ID
	hitSound.Volume = 0.65
	hitSound.Parent = player:WaitForChild("PlayerGui")

	swordHitEvent.OnClientEvent:Connect(function()
		hitSound.PlaybackSpeed = 0.92 + math.random() * 0.16
		hitSound:Play()
	end)

	if player.Character then
		bindCharacter(player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		bindCharacter(character)
	end)
end

return WeaponClient
