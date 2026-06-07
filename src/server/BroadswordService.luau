local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local BroadswordConfig = require(ReplicatedStorage.Shared.BroadswordConfig)
local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)

local BroadswordService = {}

local TOOL_NAME = "Broadsword"
local swordTemplate: Tool

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

	local leftHandGrip = Instance.new("Part")
	leftHandGrip.Name = "LeftHandGrip"
	leftHandGrip.Size = Vector3.new(0.2, 0.2, 0.2)
	leftHandGrip.Transparency = 1
	leftHandGrip.CanCollide = false
	leftHandGrip.Massless = true
	leftHandGrip.CFrame = handle.CFrame * BroadswordConfig.LEFT_HAND_GRIP_OFFSET
	leftHandGrip.Parent = tool

	weld(handle, leftHandGrip)

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

local function applyBodyRotation(root: BasePart, startCFrame: CFrame, elapsed: number)
	local lookVector = startCFrame.LookVector
	local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
	if flatLook.Magnitude < 0.001 then
		return
	end

	local baseCFrame = CFrame.new(startCFrame.Position, startCFrame.Position + flatLook.Unit)
	root.CFrame = baseCFrame * BroadswordConfig.getBodyOffset(elapsed)
end

local function runSwingHitChecks(tool: Tool, character: Model)
	local hitMonsters: { [Model]: boolean } = {}
	local swingDuration = BroadswordConfig.getSwingDuration()
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local startRootCFrame = if root then root.CFrame else CFrame.new()

	tool.Grip = BroadswordConfig.SHOULDER_GRIP

	local startTime = os.clock()

	while os.clock() - startTime < swingDuration do
		if not tool.Parent or tool.Parent ~= character then
			break
		end

		local elapsed = os.clock() - startTime
		tool.Grip = BroadswordConfig.getGripForSwing(elapsed)

		if root then
			applyBodyRotation(root, startRootCFrame, elapsed)
		end

		if BroadswordConfig.isStrikePhase(elapsed) then
			damageMonstersInSwing(tool, hitMonsters)
		end

		task.wait(1 / 60)
	end

	if root then
		local lookVector = startRootCFrame.LookVector
		local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
		if flatLook.Magnitude > 0.001 then
			root.CFrame = CFrame.new(root.Position, root.Position + flatLook.Unit)
		end
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
			runSwingHitChecks(tool, character)
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
