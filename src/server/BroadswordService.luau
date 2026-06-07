local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local BroadswordConfig = require(ReplicatedStorage.Shared.BroadswordConfig)
local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)

local BroadswordService = {}

local TOOL_NAME = "Broadsword"
local swordTemplate: Tool
local slashTracks: { [Humanoid]: AnimationTrack } = {}

local function weld(part0: BasePart, part1: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part0
end

local function createBroadswordTemplate(): Tool
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = "Your trusty broadsword"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.35, 1.1, 0.35)
	handle.Color = Color3.fromRGB(92, 58, 34)
	handle.Material = Enum.Material.Fabric
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(1.5, 0.22, 0.55)
	guard.Color = Color3.fromRGB(120, 92, 48)
	guard.Material = Enum.Material.Metal
	guard.CanCollide = false
	guard.Massless = true
	guard.CFrame = handle.CFrame * CFrame.new(0, -0.55, 0)
	guard.Parent = tool

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(0.28, 4.8, 1.15)
	blade.Color = Color3.fromRGB(188, 194, 204)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.Massless = true
	blade.CFrame = handle.CFrame * CFrame.new(0, -3.1, 0)
	blade.Parent = tool

	local bladeTip = Instance.new("Part")
	bladeTip.Name = "BladeTip"
	bladeTip.Size = Vector3.new(0.24, 0.8, 0.95)
	bladeTip.Color = Color3.fromRGB(210, 214, 222)
	bladeTip.Material = Enum.Material.Metal
	bladeTip.CanCollide = false
	bladeTip.Massless = true
	bladeTip.CFrame = blade.CFrame * CFrame.new(0, -2.7, 0)
	bladeTip.Parent = tool

	weld(handle, guard)
	weld(handle, blade)
	weld(blade, bladeTip)

	tool.Grip = BroadswordConfig.SHOULDER_GRIP

	return tool
end

local function findBroadsword(container: Instance): Tool?
	for _, child in container:GetChildren() do
		if child:IsA("Tool") and child.Name == TOOL_NAME then
			return child
		end
	end
	return nil
end

local function equipBroadsword(character: Model, tool: Tool)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 and tool.Parent then
		humanoid:EquipTool(tool)
	end
end

local function getMonstersFolder(): Folder?
	return workspace:FindFirstChild("WaveMonsters") :: Folder?
end

local function getBladeHitParts(tool: Tool): { BasePart }
	local parts: { BasePart } = {}
	for _, name in { "Blade", "BladeTip" } do
		local part = tool:FindFirstChild(name) :: BasePart?
		if part then
			table.insert(parts, part)
		end
	end
	return parts
end

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

local function applyMonsterDamage(monster: Model, humanoid: Humanoid, alreadyHit: { [Model]: boolean })
	if alreadyHit[monster] or humanoid.Health <= 0 then
		return
	end

	alreadyHit[monster] = true
	humanoid:TakeDamage(math.random(WaveConfig.SWORD_DAMAGE_MIN, WaveConfig.SWORD_DAMAGE_MAX))
end

local function damageMonstersInSwing(tool: Tool, alreadyHit: { [Model]: boolean })
	local monstersFolder = getMonstersFolder()
	if not monstersFolder then
		return
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { monstersFolder }

	local reach = WaveConfig.SWORD_HITBOX_REACH
	local hitScale = Vector3.new(
		reach.X * WaveConfig.SWORD_HITBOX_SCALE,
		reach.Y * WaveConfig.SWORD_HITBOX_SCALE,
		reach.Z * WaveConfig.SWORD_HITBOX_SCALE
	)

	for _, part in getBladeHitParts(tool) do
		local hitParts = workspace:GetPartBoundsInBox(part.CFrame, part.Size * hitScale, overlapParams)
		for _, hitPart in hitParts do
			local monster = hitPart:FindFirstAncestorOfClass("Model")
			if monster and monster.Name == "WaveMonster" then
				local humanoid = monster:FindFirstChildOfClass("Humanoid")
				if humanoid then
					applyMonsterDamage(monster, humanoid, alreadyHit)
				end
			end
		end
	end
end

local function runSwingHitChecks(tool: Tool, character: Model, humanoid: Humanoid)
	local hitMonsters: { [Model]: boolean } = {}
	local slashTrack = getSlashTrack(humanoid, character)
	local usesAnimation = slashTrack ~= nil
	local swingDuration = BroadswordConfig.getSwingDuration(usesAnimation, slashTrack and slashTrack.Length)

	tool.Grip = BroadswordConfig.SHOULDER_GRIP

	if usesAnimation then
		slashTrack:Stop(BroadswordConfig.ANIMATION_FADE_OUT)
		slashTrack:Play(BroadswordConfig.ANIMATION_FADE_IN, 1, 1)
	else
		tool.Grip = BroadswordConfig.SHOULDER_GRIP
	end

	local startTime = os.clock()
	local recoveryStart = 0

	while os.clock() - startTime < swingDuration do
		if not tool.Parent or tool.Parent ~= character then
			break
		end

		local elapsed = os.clock() - startTime
		tool.Grip = BroadswordConfig.getGripForSwing(elapsed, swingDuration, usesAnimation)

		if BroadswordConfig.isStrikePhase(elapsed, swingDuration) then
			damageMonstersInSwing(tool, hitMonsters)
		end

		task.wait(1 / 60)
	end

	if slashTrack then
		slashTrack:Stop(BroadswordConfig.ANIMATION_FADE_OUT)
	end

	recoveryStart = os.clock()
	while os.clock() - recoveryStart < BroadswordConfig.RECOVERY_DURATION do
		if not tool.Parent then
			break
		end
		tool.Grip = BroadswordConfig.getRecoveryGrip(os.clock() - recoveryStart)
		task.wait(1 / 60)
	end

	tool.Grip = BroadswordConfig.SHOULDER_GRIP
end

local function bindCombat(tool: Tool)
	local swinging = false
	local lastSwing = 0

	tool.Equipped:Connect(function()
		tool.Grip = BroadswordConfig.SHOULDER_GRIP
	end)

	tool.Activated:Connect(function()
		if swinging then
			return
		end

		local character = tool.Parent
		if not character or not character:IsA("Model") then
			return
		end

		local now = os.clock()
		if now - lastSwing < WaveConfig.SWORD_SWING_COOLDOWN then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		swinging = true
		lastSwing = now

		task.spawn(function()
			runSwingHitChecks(tool, character, humanoid)
			swinging = false
		end)
	end)
end

local function bindPermanentEquip(player: Player, tool: Tool)
	tool.Unequipped:Connect(function()
		task.defer(function()
			local character = player.Character
			if tool.Parent and character and character:FindFirstChildOfClass("Humanoid") then
				equipBroadsword(character, tool)
			end
		end)
	end)
end

local function giveBroadsword(player: Player, character: Model)
	local backpack = player:WaitForChild("Backpack")

	for _, child in backpack:GetChildren() do
		if child:IsA("Tool") and child.Name == TOOL_NAME then
			child:Destroy()
		end
	end

	local equipped = findBroadsword(character)
	if equipped then
		equipped:Destroy()
	end

	local sword = swordTemplate:Clone()
	sword.Parent = backpack
	bindPermanentEquip(player, sword)
	bindCombat(sword)
	sword.Grip = BroadswordConfig.SHOULDER_GRIP
	equipBroadsword(character, sword)
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		slashTracks[humanoid] = nil
	end

	task.defer(function()
		giveBroadsword(player, character)
	end)
end

function BroadswordService.init()
	swordTemplate = createBroadswordTemplate()
	swordTemplate.Parent = ServerStorage

	for _, player in Players:GetPlayers() do
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end)
end

return BroadswordService
