local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local BroadswordConfig = require(ReplicatedStorage.Shared.BroadswordConfig)
local BroadswordPose = require(ReplicatedStorage.Shared.BroadswordPose)
local HalberdConfig = require(ReplicatedStorage.Shared.HalberdConfig)
local RapierConfig = require(ReplicatedStorage.Shared.RapierConfig)
local WarAxeConfig = require(ReplicatedStorage.Shared.WarAxeConfig)
local WarHammerConfig = require(ReplicatedStorage.Shared.WarHammerConfig)
local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)
local WeaponCombatConfig = require(ReplicatedStorage.Shared.WeaponCombatConfig)
local WeaponConfig = require(ReplicatedStorage.Shared.WeaponConfig)
local WeaponUpgradeConfig = require(ReplicatedStorage.Shared.WeaponUpgradeConfig)

local CardService = require(script.Parent.CardService)
local GamePhaseService = require(script.Parent.GamePhaseService)
local PlayerDataService = require(script.Parent.PlayerDataService)

local WeaponService = {}

local weaponTemplates: { [string]: Tool } = {}
local playerWeapons: { [Player]: string } = {}
local swordHitEvent: RemoteEvent
local equipWeaponEvent: RemoteEvent
local loadoutUpdatedEvent: RemoteEvent
local upgradeWeaponEvent: RemoteEvent
local unlockWeaponEvent: RemoteEvent

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

local function getUpgradeWeaponEvent(): RemoteEvent
	if upgradeWeaponEvent then
		return upgradeWeaponEvent
	end

	upgradeWeaponEvent = ReplicatedStorage:FindFirstChild("UpgradeWeapon") :: RemoteEvent?
	if not upgradeWeaponEvent then
		upgradeWeaponEvent = Instance.new("RemoteEvent")
		upgradeWeaponEvent.Name = "UpgradeWeapon"
		upgradeWeaponEvent.Parent = ReplicatedStorage
	end

	return upgradeWeaponEvent
end

local function getUnlockWeaponEvent(): RemoteEvent
	if unlockWeaponEvent then
		return unlockWeaponEvent
	end

	unlockWeaponEvent = ReplicatedStorage:FindFirstChild("UnlockWeapon") :: RemoteEvent?
	if not unlockWeaponEvent then
		unlockWeaponEvent = Instance.new("RemoteEvent")
		unlockWeaponEvent.Name = "UnlockWeapon"
		unlockWeaponEvent.Parent = ReplicatedStorage
	end

	return unlockWeaponEvent
end

local function getEffectiveStats(player: Player?, weaponId: string): WeaponConfig.WeaponStats
	if player then
		local level = PlayerDataService.getWeaponLevel(player, weaponId)
		return WeaponUpgradeConfig.getEffectiveStats(weaponId, level)
	end

	return WeaponConfig.getWeapon(weaponId) or WeaponConfig.Weapons.Broadsword
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

local function createWarAxeTemplate(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "WarAxe"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = "Quick overhead chops with a wide edge"
	tool:SetAttribute(WeaponConfig.WEAPON_ATTRIBUTE, "WarAxe")

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.32, 1.05, 0.32)
	handle.Color = Color3.fromRGB(88, 54, 32)
	handle.Material = Enum.Material.Fabric
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(0.75, 0.18, 0.75)
	guard.Color = Color3.fromRGB(108, 88, 48)
	guard.Material = Enum.Material.Metal
	guard.CanCollide = false
	guard.Massless = true
	guard.CFrame = handle.CFrame * CFrame.new(0, -0.52, 0)
	guard.Parent = tool

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(1.35, 0.42, 1.85)
	blade.Color = Color3.fromRGB(176, 182, 192)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.Massless = true
	blade.CFrame = handle.CFrame * CFrame.new(0, -0.72, -0.42) * CFrame.Angles(math.rad(18), 0, 0)
	blade.Parent = tool

	local bladeTip = Instance.new("Part")
	bladeTip.Name = "BladeTip"
	bladeTip.Size = Vector3.new(1.15, 0.28, 0.55)
	bladeTip.Color = Color3.fromRGB(198, 204, 214)
	bladeTip.Material = Enum.Material.Metal
	bladeTip.CanCollide = false
	bladeTip.Massless = true
	bladeTip.CFrame = blade.CFrame * CFrame.new(0, 0, -1.05)
	bladeTip.Parent = tool

	weld(handle, guard)
	weld(handle, blade)
	weld(blade, bladeTip)

	tool.Grip = WarAxeConfig.SHOULDER_GRIP
	return tool
end

local function createHalberdTemplate(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Halberd"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = "Long reach polearm sweeps"
	tool:SetAttribute(WeaponConfig.WEAPON_ATTRIBUTE, "Halberd")

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.22, 5.2, 0.22)
	handle.Color = Color3.fromRGB(96, 68, 38)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(0.55, 0.12, 0.55)
	guard.Color = Color3.fromRGB(128, 108, 58)
	guard.Material = Enum.Material.Metal
	guard.CanCollide = false
	guard.Massless = true
	guard.CFrame = handle.CFrame * CFrame.new(0, -2.35, 0)
	guard.Parent = tool

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(0.18, 2.4, 1.45)
	blade.Color = Color3.fromRGB(184, 190, 200)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.Massless = true
	blade.CFrame = handle.CFrame * CFrame.new(0, -3.55, -0.35) * CFrame.Angles(math.rad(12), 0, 0)
	blade.Parent = tool

	local bladeTip = Instance.new("Part")
	bladeTip.Name = "BladeTip"
	bladeTip.Size = Vector3.new(0.14, 0.65, 0.95)
	bladeTip.Color = Color3.fromRGB(204, 210, 220)
	bladeTip.Material = Enum.Material.Metal
	bladeTip.CanCollide = false
	bladeTip.Massless = true
	bladeTip.CFrame = blade.CFrame * CFrame.new(0, -1.35, -0.18)
	bladeTip.Parent = tool

	weld(handle, guard)
	weld(handle, blade)
	weld(blade, bladeTip)

	tool.Grip = HalberdConfig.SHOULDER_GRIP
	return tool
end

local function createWarHammerTemplate(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "WarHammer"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = "Slow crushing blows that hit hard"
	tool:SetAttribute(WeaponConfig.WEAPON_ATTRIBUTE, "WarHammer")

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.28, 1.15, 0.28)
	handle.Color = Color3.fromRGB(82, 52, 30)
	handle.Material = Enum.Material.Fabric
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(0.95, 0.16, 0.95)
	guard.Color = Color3.fromRGB(118, 98, 52)
	guard.Material = Enum.Material.Metal
	guard.CanCollide = false
	guard.Massless = true
	guard.CFrame = handle.CFrame * CFrame.new(0, -0.58, 0)
	guard.Parent = tool

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(1.05, 1.05, 1.05)
	blade.Color = Color3.fromRGB(148, 152, 162)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.Massless = true
	blade.Shape = Enum.PartType.Ball
	blade.CFrame = handle.CFrame * CFrame.new(0, -1.25, 0)
	blade.Parent = tool

	local bladeTip = Instance.new("Part")
	bladeTip.Name = "BladeTip"
	bladeTip.Size = Vector3.new(0.85, 0.85, 0.85)
	bladeTip.Color = Color3.fromRGB(168, 172, 182)
	bladeTip.Material = Enum.Material.Metal
	bladeTip.CanCollide = false
	bladeTip.Massless = true
	bladeTip.Shape = Enum.PartType.Ball
	bladeTip.CFrame = blade.CFrame
	bladeTip.Parent = tool

	weld(handle, guard)
	weld(handle, blade)
	weld(blade, bladeTip)

	tool.Grip = WarHammerConfig.SHOULDER_GRIP
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
	local damage = math.random(stats.damageMin, stats.damageMax)
	if attacker then
		local modifiers = CardService.getModifiers(attacker)
		damage = math.max(1, math.floor(damage * modifiers.damageMult))
		CardService.applyLifesteal(attacker, damage)
	end
	humanoid:TakeDamage(damage)

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
	local weaponId = tool:GetAttribute(WeaponConfig.WEAPON_ATTRIBUTE) or tool.Name
	local stats = getEffectiveStats(attacker, weaponId :: string)

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
	local weaponId = tool:GetAttribute(WeaponConfig.WEAPON_ATTRIBUTE) or tool.Name
	local hitMonsters: { [Model]: boolean } = {}
	local swingDuration = combatConfig.getSwingDuration()
	local motors = BroadswordPose.getMotors(character)
	local usesAnimation = WeaponCombatConfig.usesAnimationSwing(weaponId :: string)

	if usesAnimation then
		BroadswordPose.reset(motors, tool, BroadswordConfig.SHOULDER_GRIP)
	else
		BroadswordPose.apply(motors, combatConfig.SHOULDER_POSE, tool)
	end

	local startTime = os.clock()

	while os.clock() - startTime < swingDuration do
		if not tool.Parent or tool.Parent ~= character then
			break
		end

		local elapsed = os.clock() - startTime
		local progress = (elapsed / swingDuration) * BroadswordConfig.ANIMATION_END_RATIO

		if usesAnimation then
			tool.Grip = BroadswordConfig.getGripForAnimationSwing(progress)
		else
			local pose = combatConfig.getPoseForSwing(elapsed)
			BroadswordPose.apply(motors, pose, tool)
		end

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

		local attacker = Players:GetPlayerFromCharacter(character)
		local weaponId = tool:GetAttribute(WeaponConfig.WEAPON_ATTRIBUTE) or tool.Name
		local stats = getEffectiveStats(attacker, weaponId :: string)
		local now = os.clock()
		local swingCooldown = stats.cooldown
		if attacker then
			swingCooldown *= CardService.getModifiers(attacker).cooldownMult
		end
		if now - lastSwing < swingCooldown then
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
	local weaponId = PlayerDataService.getEquippedWeapon(player)
	playerWeapons[player] = weaponId
	getLoadoutUpdatedEvent():FireClient(player, weaponId, GamePhaseService.isLoadoutLocked(player))
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

function WeaponService.refreshPlayerLoadout(player: Player)
	local weaponId = PlayerDataService.getEquippedWeapon(player)
	playerWeapons[player] = weaponId
	giveWeapon(player, player.Character, weaponId)
	notifyLoadout(player)
end

function WeaponService.equipPlayerWeapon(player: Player, weaponId: string): boolean
	if GamePhaseService.isLoadoutLocked(player) then
		return false
	end

	if not WeaponConfig.isValid(weaponId) then
		return false
	end

	if not PlayerDataService.isWeaponUnlocked(player, weaponId) then
		return false
	end

	if not PlayerDataService.setEquippedWeapon(player, weaponId) then
		return false
	end

	playerWeapons[player] = weaponId
	giveWeapon(player, player.Character, weaponId)
	notifyLoadout(player)
	return true
end

function WeaponService.upgradePlayerWeapon(player: Player, weaponId: string): boolean
	if not GamePhaseService.isInLobby(player) then
		return false
	end

	local ok = PlayerDataService.tryUpgradeWeapon(player, weaponId)
	return ok
end

function WeaponService.unlockPlayerWeapon(player: Player, weaponId: string): boolean
	if not GamePhaseService.isInLobby(player) then
		return false
	end

	local ok = PlayerDataService.tryUnlockWeapon(player, weaponId)
	return ok
end

local function onCharacterAdded(player: Player, character: Model)
	task.defer(function()
		local weaponId = PlayerDataService.getEquippedWeapon(player)
		playerWeapons[player] = weaponId
		giveWeapon(player, character, weaponId)
		notifyLoadout(player)
	end)
end

function WeaponService.init()
	weaponTemplates.Broadsword = createBroadswordTemplate()
	weaponTemplates.Rapier = createRapierTemplate()
	weaponTemplates.WarAxe = createWarAxeTemplate()
	weaponTemplates.Halberd = createHalberdTemplate()
	weaponTemplates.WarHammer = createWarHammerTemplate()

	for _, template in weaponTemplates do
		template.Parent = ServerStorage
	end

	getSwordHitEvent()
	getEquipWeaponEvent()
	getLoadoutUpdatedEvent()
	getUpgradeWeaponEvent()
	getUnlockWeaponEvent()

	getEquipWeaponEvent().OnServerEvent:Connect(function(player, weaponId: string)
		if typeof(weaponId) ~= "string" then
			return
		end

		WeaponService.equipPlayerWeapon(player, weaponId)
	end)

	getUpgradeWeaponEvent().OnServerEvent:Connect(function(player, weaponId: string)
		if typeof(weaponId) ~= "string" then
			return
		end

		WeaponService.upgradePlayerWeapon(player, weaponId)
	end)

	getUnlockWeaponEvent().OnServerEvent:Connect(function(player, weaponId: string)
		if typeof(weaponId) ~= "string" then
			return
		end

		WeaponService.unlockPlayerWeapon(player, weaponId)
	end)

	for _, player in Players:GetPlayers() do
		playerWeapons[player] = PlayerDataService.getEquippedWeapon(player)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		playerWeapons[player] = PlayerDataService.getEquippedWeapon(player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerWeapons[player] = nil
	end)
end

return WeaponService
