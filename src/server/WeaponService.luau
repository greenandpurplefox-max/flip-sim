local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local BroadswordConfig = require(ReplicatedStorage.Shared.BroadswordConfig)
local BroadswordPose = require(ReplicatedStorage.Shared.BroadswordPose)
local RapierConfig = require(ReplicatedStorage.Shared.RapierConfig)
local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)
local WeaponCombatConfig = require(ReplicatedStorage.Shared.WeaponCombatConfig)
local WeaponConfig = require(ReplicatedStorage.Shared.WeaponConfig)

local WaveService = require(script.Parent.WaveService)

local WeaponService = {}

local weaponTemplates: { [string]: Tool } = {}
local playerWeapons: { [Player]: string } = {}
local swordHitEvent: RemoteEvent
local equipWeaponEvent: RemoteEvent
local loadoutUpdatedEvent: RemoteEvent

local function getSwordHitEvent(): RemoteEvent
	if swordHitEvent then
		return swordHitEvent
	end

	swordHitEvent = ReplicatedStorage:FindFirstChild("SwordHitMonster") :: RemoteEvent?
	if not swordHitEvent then
		swordHitEvent = Instance.new("RemoteEvent")
		swordHitEvent.Name = "SwordHitMonster"
		swordHitEvent.Parent = ReplicatedStorage
	end

	return swordHitEvent
end

local function getEquipWeaponEvent(): RemoteEvent
	if equipWeaponEvent then
		return equipWeaponEvent
	end

	equipWeaponEvent = ReplicatedStorage:FindFirstChild("EquipWeapon") :: RemoteEvent?
	if not equipWeaponEvent then
		equipWeaponEvent = Instance.new("RemoteEvent")
		equipWeaponEvent.Name = "EquipWeapon"
		equipWeaponEvent.Parent = ReplicatedStorage
	end

	return equipWeaponEvent
end

local function getLoadoutUpdatedEvent(): RemoteEvent
	if loadoutUpdatedEvent then
		return loadoutUpdatedEvent
	end

	loadoutUpdatedEvent = ReplicatedStorage:FindFirstChild("LoadoutUpdated") :: RemoteEvent?
	if not loadoutUpdatedEvent then
		loadoutUpdatedEvent = Instance.new("RemoteEvent")
		loadoutUpdatedEvent.Name = "LoadoutUpdated"
		loadoutUpdatedEvent.Parent = ReplicatedStorage
	end

	return loadoutUpdatedEvent
end

local function weld(part0: BasePart, part1: BasePart)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = part0
	constraint.Part1 = part1
	constraint.Parent = part0
end

local function createBroadswordTemplate(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Broadsword"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = "Heavy two-handed slashes"
	tool:SetAttribute(WeaponConfig.WEAPON_ATTRIBUTE, "Broadsword")

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

local function createRapierTemplate(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Rapier"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = "Fast one-handed thrusts"
	tool:SetAttribute(WeaponConfig.WEAPON_ATTRIBUTE, "Rapier")

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.18, 0.95, 0.18)
	handle.Color = Color3.fromRGB(74, 48, 32)
	handle.Material = Enum.Material.Fabric
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(0.55, 0.12, 0.55)
	guard.Color = Color3.fromRGB(148, 148, 156)
	guard.Material = Enum.Material.Metal
	guard.CanCollide = false
	guard.Massless = true
	guard.CFrame = handle.CFrame * CFrame.new(0, -0.48, 0)
	guard.Parent = tool

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(0.1, 3.6, 0.1)
	blade.Color = Color3.fromRGB(198, 202, 212)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.Massless = true
	blade.CFrame = handle.CFrame * CFrame.new(0, -2.35, 0)
	blade.Parent = tool

	local bladeTip = Instance.new("Part")
	bladeTip.Name = "BladeTip"
	bladeTip.Size = Vector3.new(0.08, 0.55, 0.08)
	bladeTip.Color = Color3.fromRGB(220, 224, 232)
	bladeTip.Material = Enum.Material.Metal
	bladeTip.CanCollide = false
	bladeTip.Massless = true
	bladeTip.CFrame = blade.CFrame * CFrame.new(0, -2.05, 0)
	bladeTip.Parent = tool

	weld(handle, guard)
	weld(handle, blade)
	weld(blade, bladeTip)

	tool.Grip = RapierConfig.SHOULDER_GRIP
	return tool
end

local function findWaveWeapon(container: Instance): Tool?
	for _, child in container:GetChildren() do
		if child:IsA("Tool") then
			local weaponId = child:GetAttribute(WeaponConfig.WEAPON_ATTRIBUTE) or child.Name
			if WeaponConfig.isValid(weaponId :: string) then
				return child
			end
		end
	end
	return nil
end

local function clearWaveWeapons(player: Player, character: Model?)
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, child in backpack:GetChildren() do
			if child:IsA("Tool") then
				local weaponId = child:GetAttribute(WeaponConfig.WEAPON_ATTRIBUTE) or child.Name
				if WeaponConfig.isValid(weaponId :: string) then
					child:Destroy()
				end
			end
		end
	end

	if character then
		local equipped = findWaveWeapon(character)
		if equipped then
			equipped:Destroy()
		end
	end
end

local function equipWeaponTool(character: Model, tool: Tool)
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

local function applyMonsterDamage(
	monster: Model,
	humanoid: Humanoid,
	alreadyHit: { [Model]: boolean },
	attacker: Player?,
	stats: WeaponConfig.WeaponStats
)
	if alreadyHit[monster] or humanoid.Health <= 0 then
		return
	end

	alreadyHit[monster] = true
	humanoid:TakeDamage(math.random(stats.damageMin, stats.damageMax))

	if attacker then
		getSwordHitEvent():FireClient(attacker)
	end
end

local function damageMonstersInSwing(tool: Tool, character: Model, alreadyHit: { [Model]: boolean })
	local monstersFolder = getMonstersFolder()
	if not monstersFolder then
		return
	end

	local attacker = Players:GetPlayerFromCharacter(character)
	local stats = WeaponConfig.getStatsForTool(tool)

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { monstersFolder }

	local reach = WaveConfig.SWORD_HITBOX_REACH
	local hitScale = Vector3.new(
		reach.X * stats.hitboxScale,
		reach.Y * stats.hitboxScale,
		reach.Z * stats.hitboxScale
	)

	for _, part in getBladeHitParts(tool) do
		local hitParts = workspace:GetPartBoundsInBox(part.CFrame, part.Size * hitScale, overlapParams)
		for _, hitPart in hitParts do
			local monster = hitPart:FindFirstAncestorOfClass("Model")
			if monster and monster.Name == "WaveMonster" then
				local humanoid = monster:FindFirstChildOfClass("Humanoid")
				if humanoid then
					applyMonsterDamage(monster, humanoid, alreadyHit, attacker, stats)
				end
			end
		end
	end
end

local function runSwingHitChecks(tool: Tool, character: Model)
	local combatConfig = WeaponCombatConfig.getConfigForTool(tool)
	local hitMonsters: { [Model]: boolean } = {}
	local swingDuration = combatConfig.getSwingDuration()
	local motors = BroadswordPose.getMotors(character)

	BroadswordPose.apply(motors, combatConfig.SHOULDER_POSE, tool)

	local startTime = os.clock()

	while os.clock() - startTime < swingDuration do
		if not tool.Parent or tool.Parent ~= character then
			break
		end

		local elapsed = os.clock() - startTime
		local pose = combatConfig.getPoseForSwing(elapsed)
		BroadswordPose.apply(motors, pose, tool)

		if combatConfig.isStrikePhase(elapsed) then
			damageMonstersInSwing(tool, character, hitMonsters)
		end

		task.wait(1 / 60)
	end

	BroadswordPose.apply(motors, combatConfig.SHOULDER_POSE, tool)
end

local function bindCombat(tool: Tool)
	local swinging = false
	local lastSwing = 0

	tool.Equipped:Connect(function()
		local character = tool.Parent
		if character and character:IsA("Model") then
			local combatConfig = WeaponCombatConfig.getConfigForTool(tool)
			local motors = BroadswordPose.getMotors(character)
			BroadswordPose.apply(motors, combatConfig.SHOULDER_POSE, tool)
		end
	end)

	tool.Activated:Connect(function()
		if swinging then
			return
		end

		local character = tool.Parent
		if not character or not character:IsA("Model") then
			return
		end

		local stats = WeaponConfig.getStatsForTool(tool)
		local now = os.clock()
		if now - lastSwing < stats.cooldown then
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
			local weaponId = playerWeapons[player]
			if weaponId and tool.Parent and character and character:FindFirstChildOfClass("Humanoid") then
				local expected = findWaveWeapon(character)
				if expected == tool or (not expected and tool:GetAttribute(WeaponConfig.WEAPON_ATTRIBUTE) == weaponId) then
					equipWeaponTool(character, tool)
				end
			end
		end)
	end)
end

local function notifyLoadout(player: Player)
	local weaponId = playerWeapons[player] or WeaponConfig.DEFAULT_WEAPON
	getLoadoutUpdatedEvent():FireClient(player, weaponId, WaveService.isLoadoutLocked())
end

local function giveWeapon(player: Player, character: Model?, weaponId: string)
	if not character then
		return
	end

	local template = weaponTemplates[weaponId]
	if not template then
		return
	end

	clearWaveWeapons(player, character)

	local tool = template:Clone()
	tool.Parent = player:WaitForChild("Backpack")
	bindPermanentEquip(player, tool)
	bindCombat(tool)

	local combatConfig = WeaponCombatConfig.getConfig(weaponId)
	tool.Grip = combatConfig.SHOULDER_GRIP
	equipWeaponTool(character, tool)
end

function WeaponService.equipPlayerWeapon(player: Player, weaponId: string): boolean
	if WaveService.isLoadoutLocked() then
		return false
	end

	if not WeaponConfig.isValid(weaponId) then
		return false
	end

	playerWeapons[player] = weaponId
	giveWeapon(player, player.Character, weaponId)
	notifyLoadout(player)
	return true
end

local function onCharacterAdded(player: Player, character: Model)
	task.defer(function()
		local weaponId = playerWeapons[player] or WeaponConfig.DEFAULT_WEAPON
		playerWeapons[player] = weaponId
		giveWeapon(player, character, weaponId)
		notifyLoadout(player)
	end)
end

function WeaponService.init()
	weaponTemplates.Broadsword = createBroadswordTemplate()
	weaponTemplates.Rapier = createRapierTemplate()

	for _, template in weaponTemplates do
		template.Parent = ServerStorage
	end

	getSwordHitEvent()
	getEquipWeaponEvent()
	getLoadoutUpdatedEvent()

	getEquipWeaponEvent().OnServerEvent:Connect(function(player, weaponId: string)
		if typeof(weaponId) ~= "string" then
			return
		end

		WeaponService.equipPlayerWeapon(player, weaponId)
	end)

	for _, player in Players:GetPlayers() do
		playerWeapons[player] = WeaponConfig.DEFAULT_WEAPON
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		playerWeapons[player] = WeaponConfig.DEFAULT_WEAPON
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerWeapons[player] = nil
	end)
end

return WeaponService
