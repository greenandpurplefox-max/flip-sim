local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)

local BroadswordService = {}

local TOOL_NAME = "Broadsword"
local swordTemplate: Tool

local SHOULDER_GRIP = CFrame.new(1.15, 0.15, 0.55) * CFrame.Angles(math.rad(118), math.rad(12), math.rad(108))
local WINDUP_GRIP = CFrame.new(0.85, 0.35, 0.15) * CFrame.Angles(math.rad(95), math.rad(-25), math.rad(130))
local SWING_GRIP = CFrame.new(-0.15, -0.35, -1.85) * CFrame.Angles(math.rad(-15), math.rad(92), math.rad(8))

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

	tool.Grip = SHOULDER_GRIP

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

local function getHitParts(tool: Tool): { BasePart }
	local parts: { BasePart } = {}
	for _, name in { "Blade", "BladeTip", "Guard", "Handle" } do
		local part = tool:FindFirstChild(name) :: BasePart?
		if part then
			table.insert(parts, part)
		end
	end
	return parts
end

local function damageMonstersInSwing(tool: Tool, alreadyHit: { [Model]: boolean })
	local monstersFolder = getMonstersFolder()
	if not monstersFolder then
		return
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { monstersFolder }

	for _, part in getHitParts(tool) do
		local hitParts = workspace:GetPartBoundsInBox(part.CFrame, part.Size * Vector3.new(1.35, 1.35, 1.35), overlapParams)
		for _, hitPart in hitParts do
			local monster = hitPart:FindFirstAncestorOfClass("Model")
			if monster and monster.Name == "WaveMonster" and not alreadyHit[monster] then
				local humanoid = monster:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					alreadyHit[monster] = true
					humanoid:TakeDamage(math.random(WaveConfig.SWORD_DAMAGE_MIN, WaveConfig.SWORD_DAMAGE_MAX))
				end
			end
		end
	end
end

local function tweenGrip(tool: Tool, fromGrip: CFrame, toGrip: CFrame, duration: number, steps: number, onStep: ((number) -> ())?)
	for step = 1, steps do
		if not tool.Parent then
			return
		end

		local alpha = step / steps
		tool.Grip = fromGrip:Lerp(toGrip, alpha)

		if onStep then
			onStep(alpha)
		end

		task.wait(duration / steps)
	end
end

local function bindCombat(tool: Tool)
	local swinging = false
	local lastSwing = 0

	tool.Equipped:Connect(function()
		tool.Grip = SHOULDER_GRIP
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

		local hitMonsters: { [Model]: boolean } = {}

		tweenGrip(tool, SHOULDER_GRIP, WINDUP_GRIP, 0.08, 4)
		tweenGrip(tool, WINDUP_GRIP, SWING_GRIP, 0.14, 7, function()
			damageMonstersInSwing(tool, hitMonsters)
		end)
		damageMonstersInSwing(tool, hitMonsters)

		tweenGrip(tool, SWING_GRIP, SHOULDER_GRIP, 0.18, 8)

		swinging = false
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
	sword.Grip = SHOULDER_GRIP
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
