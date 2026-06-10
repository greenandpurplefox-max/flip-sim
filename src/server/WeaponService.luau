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
local SpellService = require(script.Parent.SpellService)
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

	local wood = Color3.fromRGB(72, 46, 28)
	local leather = Color3.fromRGB(54, 34, 22)
	local bronze = Color3.fromRGB(118, 92, 48)
	local steel = Color3.fromRGB(168, 174, 184)
	local edge = Color3.fromRGB(214, 220, 230)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.26, 1.28, 0.26)
	handle.Color = wood
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local gripWrap = Instance.new("Part")
	gripWrap.Name = "GripWrap"
	gripWrap.Size = Vector3.new(0.32, 0.52, 0.32)
	gripWrap.Color = leather
	gripWrap.Material = Enum.Material.Fabric
	gripWrap.CanCollide = false
	gripWrap.Massless = true
	gripWrap.CFrame = handle.CFrame * CFrame.new(0, 0.28, 0)
	gripWrap.Parent = tool

	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(0.58, 0.22, 0.58)
	guard.Color = bronze
	guard.Material = Enum.Material.Metal
	guard.CanCollide = false
	guard.Massless = true
	guard.CFrame = handle.CFrame * CFrame.new(0, -0.58, 0)
	guard.Parent = tool

	local socket = Instance.new("Part")
	socket.Name = "Socket"
	socket.Size = Vector3.new(0.34, 0.28, 0.34)
	socket.Color = steel
	socket.Material = Enum.Material.Metal
	socket.CanCollide = false
	socket.Massless = true
	socket.CFrame = guard.CFrame * CFrame.new(0, -0.12, 0)
	socket.Parent = tool

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(1.18, 0.24, 1.42)
	blade.Color = steel
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.Massless = true
	blade.CFrame = socket.CFrame * CFrame.new(0, 0.02, -0.62) * CFrame.Angles(math.rad(8), 0, 0)
	blade.Parent = tool

	local axeEdge = Instance.new("Part")
	axeEdge.Name = "AxeEdge"
	axeEdge.Size = Vector3.new(1.02, 0.1, 0.16)
	axeEdge.Color = edge
	axeEdge.Material = Enum.Material.Metal
	axeEdge.CanCollide = false
	axeEdge.Massless = true
	axeEdge.CFrame = blade.CFrame * CFrame.new(0, 0, -0.72)
	axeEdge.Parent = tool

	local bladeTip = Instance.new("Part")
	bladeTip.Name = "BladeTip"
	bladeTip.Size = Vector3.new(0.42, 0.18, 0.72)
	bladeTip.Color = edge
	bladeTip.Material = Enum.Material.Metal
	bladeTip.CanCollide = false
	bladeTip.Massless = true
	bladeTip.CFrame = blade.CFrame * CFrame.new(0, 0.08, -0.92)
	bladeTip.Parent = tool

	local beard = Instance.new("Part")
	beard.Name = "Beard"
	beard.Size = Vector3.new(0.72, 0.16, 0.48)
	beard.Color = steel
	beard.Material = Enum.Material.Metal
	beard.CanCollide = false
	beard.Massless = true
	beard.CFrame = blade.CFrame * CFrame.new(0, -0.12, -0.28) * CFrame.Angles(math.rad(-24), 0, 0)
	beard.Parent = tool

	local poll = Instance.new("Part")
	poll.Name = "Poll"
	poll.Size = Vector3.new(0.18, 0.18, 0.42)
	poll.Color = bronze
	poll.Material = Enum.Material.Metal
	poll.CanCollide = false
	poll.Massless = true
	poll.CFrame = socket.CFrame * CFrame.new(0, 0.02, 0.34)
	poll.Parent = tool

	weld(handle, gripWrap)
	weld(handle, guard)
	weld(guard, socket)
	weld(socket, blade)
	weld(blade, axeEdge)
	weld(blade, bladeTip)
	weld(blade, beard)
	weld(socket, poll)

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

	local wood = Color3.fromRGB(68, 44, 26)
	local leather = Color3.fromRGB(54, 34, 22)
	local bronze = Color3.fromRGB(132, 104, 56)
	local steel = Color3.fromRGB(168, 174, 184)
	local edge = Color3.fromRGB(214, 220, 230)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.16, 5.75, 0.16)
	handle.Color = wood
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local gripWrap = Instance.new("Part")
	gripWrap.Name = "GripWrap"
	gripWrap.Size = Vector3.new(0.24, 0.95, 0.24)
	gripWrap.Color = leather
	gripWrap.Material = Enum.Material.Fabric
	gripWrap.CanCollide = false
	gripWrap.Massless = true
	gripWrap.CFrame = handle.CFrame * CFrame.new(0, 1.15, 0)
	gripWrap.Parent = tool

	local shaftBand = Instance.new("Part")
	shaftBand.Name = "ShaftBand"
	shaftBand.Size = Vector3.new(0.22, 0.12, 0.22)
	shaftBand.Color = bronze
	shaftBand.Material = Enum.Material.Metal
	shaftBand.CanCollide = false
	shaftBand.Massless = true
	shaftBand.CFrame = handle.CFrame * CFrame.new(0, 0.35, 0)
	shaftBand.Parent = tool

	local bottomCap = Instance.new("Part")
	bottomCap.Name = "BottomCap"
	bottomCap.Size = Vector3.new(0.2, 0.16, 0.2)
	bottomCap.Color = bronze
	bottomCap.Material = Enum.Material.Metal
	bottomCap.CanCollide = false
	bottomCap.Massless = true
	bottomCap.CFrame = handle.CFrame * CFrame.new(0, -2.82, 0)
	bottomCap.Parent = tool

	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(0.46, 0.34, 0.46)
	guard.Color = bronze
	guard.Material = Enum.Material.Metal
	guard.CanCollide = false
	guard.Massless = true
	guard.CFrame = handle.CFrame * CFrame.new(0, -2.58, 0)
	guard.Parent = tool

	local langetLeft = Instance.new("Part")
	langetLeft.Name = "LangetLeft"
	langetLeft.Size = Vector3.new(0.06, 0.72, 0.14)
	langetLeft.Color = steel
	langetLeft.Material = Enum.Material.Metal
	langetLeft.CanCollide = false
	langetLeft.Massless = true
	langetLeft.CFrame = guard.CFrame * CFrame.new(-0.16, -0.28, 0)
	langetLeft.Parent = tool

	local langetRight = Instance.new("Part")
	langetRight.Name = "LangetRight"
	langetRight.Size = Vector3.new(0.06, 0.72, 0.14)
	langetRight.Color = steel
	langetRight.Material = Enum.Material.Metal
	langetRight.CanCollide = false
	langetRight.Massless = true
	langetRight.CFrame = guard.CFrame * CFrame.new(0.16, -0.28, 0)
	langetRight.Parent = tool

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(0.12, 1.05, 1.65)
	blade.Color = steel
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.Massless = true
	blade.CFrame = guard.CFrame * CFrame.new(0, -0.08, -0.72) * CFrame.Angles(math.rad(14), 0, 0)
	blade.Parent = tool

	local axeEdge = Instance.new("Part")
	axeEdge.Name = "AxeEdge"
	axeEdge.Size = Vector3.new(0.05, 0.92, 0.18)
	axeEdge.Color = edge
	axeEdge.Material = Enum.Material.Metal
	axeEdge.CanCollide = false
	axeEdge.Massless = true
	axeEdge.CFrame = blade.CFrame * CFrame.new(0, 0, -0.78)
	axeEdge.Parent = tool

	local bladeTip = Instance.new("Part")
	bladeTip.Name = "BladeTip"
	bladeTip.Size = Vector3.new(0.1, 1.55, 0.1)
	bladeTip.Color = edge
	bladeTip.Material = Enum.Material.Metal
	bladeTip.CanCollide = false
	bladeTip.Massless = true
	bladeTip.CFrame = guard.CFrame * CFrame.new(0, -0.92, 0)
	bladeTip.Parent = tool

	local hookBeak = Instance.new("Part")
	hookBeak.Name = "HookBeak"
	hookBeak.Size = Vector3.new(0.1, 0.48, 0.82)
	hookBeak.Color = steel
	hookBeak.Material = Enum.Material.Metal
	hookBeak.CanCollide = false
	hookBeak.Massless = true
	hookBeak.CFrame = guard.CFrame * CFrame.new(0, -0.12, 0.58) * CFrame.Angles(math.rad(-18), 0, 0)
	hookBeak.Parent = tool

	weld(handle, gripWrap)
	weld(handle, shaftBand)
	weld(handle, bottomCap)
	weld(handle, guard)
	weld(guard, langetLeft)
	weld(guard, langetRight)
	weld(guard, blade)
	weld(blade, axeEdge)
	weld(guard, bladeTip)
	weld(guard, hookBeak)

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

local function isPlayerActive(player: Player): boolean
	return player.Parent ~= nil
end

local function equipWeaponTool(character: Model, tool: Tool)
	if not character.Parent then
		return
	end

	local owner = Players:GetPlayerFromCharacter(character)
	if owner and not isPlayerActive(owner) then
		return
	end

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
		SpellService.tryProcInfusionOnHit(attacker)
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
			if not isPlayerActive(player) then
				return
			end

			local character = player.Character
			if not character or not character.Parent then
				return
			end

			local weaponId = playerWeapons[player]
			if weaponId and tool.Parent and character:FindFirstChildOfClass("Humanoid") then
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
	if not isPlayerActive(player) or not character or not character.Parent then
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
	if not isPlayerActive(player) then
		return
	end

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
		if not isPlayerActive(player) or player.Character ~= character or not character.Parent then
			return
		end

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
