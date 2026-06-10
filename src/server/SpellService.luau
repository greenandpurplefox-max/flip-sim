local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpellConfig = require(ReplicatedStorage.Shared.SpellConfig)
local SpellUpgradeConfig = require(ReplicatedStorage.Shared.SpellUpgradeConfig)

local CardService = require(script.Parent.CardService)
local GamePhaseService = require(script.Parent.GamePhaseService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StaminaService = require(script.Parent.StaminaService)

local SpellService = {}

local PROJECTILE_LIFETIME = 2.5

local lastActiveCastAt: { [Player]: number } = {}
local lastInfusionProcAt: { [Player]: number } = {}
local INFUSION_PROC_COOLDOWN = 0.85

local infuseSpellEvent: RemoteEvent
local upgradeSpellEvent: RemoteEvent
local unlockSpellEvent: RemoteEvent
local castSpellEvent: RemoteEvent
local spellLoadoutUpdatedEvent: RemoteEvent
local spellCastEffectEvent: RemoteEvent

local function isPlayerActive(player: Player): boolean
	return player.Parent ~= nil
end

local function getInfuseSpellEvent(): RemoteEvent
	if infuseSpellEvent then
		return infuseSpellEvent
	end

	infuseSpellEvent = ReplicatedStorage:FindFirstChild("InfuseSpell") :: RemoteEvent?
	if not infuseSpellEvent then
		infuseSpellEvent = Instance.new("RemoteEvent")
		infuseSpellEvent.Name = "InfuseSpell"
		infuseSpellEvent.Parent = ReplicatedStorage
	end

	return infuseSpellEvent
end

local function getUpgradeSpellEvent(): RemoteEvent
	if upgradeSpellEvent then
		return upgradeSpellEvent
	end

	upgradeSpellEvent = ReplicatedStorage:FindFirstChild("UpgradeSpell") :: RemoteEvent?
	if not upgradeSpellEvent then
		upgradeSpellEvent = Instance.new("RemoteEvent")
		upgradeSpellEvent.Name = "UpgradeSpell"
		upgradeSpellEvent.Parent = ReplicatedStorage
	end

	return upgradeSpellEvent
end

local function getUnlockSpellEvent(): RemoteEvent
	if unlockSpellEvent then
		return unlockSpellEvent
	end

	unlockSpellEvent = ReplicatedStorage:FindFirstChild("UnlockSpell") :: RemoteEvent?
	if not unlockSpellEvent then
		unlockSpellEvent = Instance.new("RemoteEvent")
		unlockSpellEvent.Name = "UnlockSpell"
		unlockSpellEvent.Parent = ReplicatedStorage
	end

	return unlockSpellEvent
end

local function getCastSpellEvent(): RemoteEvent
	if castSpellEvent then
		return castSpellEvent
	end

	castSpellEvent = ReplicatedStorage:FindFirstChild("CastSpell") :: RemoteEvent?
	if not castSpellEvent then
		castSpellEvent = Instance.new("RemoteEvent")
		castSpellEvent.Name = "CastSpell"
		castSpellEvent.Parent = ReplicatedStorage
	end

	return castSpellEvent
end

local function getSpellLoadoutUpdatedEvent(): RemoteEvent
	if spellLoadoutUpdatedEvent then
		return spellLoadoutUpdatedEvent
	end

	spellLoadoutUpdatedEvent = ReplicatedStorage:FindFirstChild("SpellLoadoutUpdated") :: RemoteEvent?
	if not spellLoadoutUpdatedEvent then
		spellLoadoutUpdatedEvent = Instance.new("RemoteEvent")
		spellLoadoutUpdatedEvent.Name = "SpellLoadoutUpdated"
		spellLoadoutUpdatedEvent.Parent = ReplicatedStorage
	end

	return spellLoadoutUpdatedEvent
end

local function getSpellCastEffectEvent(): RemoteEvent
	if spellCastEffectEvent then
		return spellCastEffectEvent
	end

	spellCastEffectEvent = ReplicatedStorage:FindFirstChild("SpellCastEffect") :: RemoteEvent?
	if not spellCastEffectEvent then
		spellCastEffectEvent = Instance.new("RemoteEvent")
		spellCastEffectEvent.Name = "SpellCastEffect"
		spellCastEffectEvent.Parent = ReplicatedStorage
	end

	return spellCastEffectEvent
end

local function getEffectiveStats(player: Player, spellId: string): SpellUpgradeConfig.EffectiveSpellStats
	local level = PlayerDataService.getSpellLevel(player, spellId)
	return SpellUpgradeConfig.getEffectiveStats(spellId, level)
end

local function getMonstersFolder(): Folder?
	return workspace:FindFirstChild("WaveMonsters") :: Folder?
end

local function getProjectileFolder(): Folder
	local folder = workspace:FindFirstChild("SpellProjectiles") :: Folder?
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "SpellProjectiles"
		folder.Parent = workspace
	end
	return folder
end

local function createSparkEmitter(parent: Instance, color: Color3, rate: number, lifetime: NumberRange)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SpellSparkles"
	emitter.Color = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.65))
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(0.5, 0.9),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = lifetime
	emitter.Rate = rate
	emitter.Speed = NumberRange.new(4, 12)
	emitter.SpreadAngle = Vector2.new(35, 35)
	emitter.Drag = 2
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Parent = parent
	return emitter
end

local function decorateProjectile(part: BasePart, stats: SpellUpgradeConfig.EffectiveSpellStats)
	local glow = Instance.new("Part")
	glow.Name = "SpellGlow"
	glow.Size = part.Size * 1.55
	glow.Material = Enum.Material.Neon
	glow.Color = stats.projectileColor
	glow.Transparency = 0.55
	glow.CanCollide = false
	glow.Massless = true
	glow.Anchored = false
	glow.CFrame = part.CFrame
	glow.Parent = part

	local glowWeld = Instance.new("WeldConstraint")
	glowWeld.Part0 = part
	glowWeld.Part1 = glow
	glowWeld.Parent = part

	local light = Instance.new("PointLight")
	light.Color = stats.projectileColor
	light.Brightness = if stats.isUltimate then 4 else 2.8
	light.Range = if stats.isUltimate then 20 else 14
	light.Parent = part

	local frontAttachment = Instance.new("Attachment")
	frontAttachment.Name = "Front"
	frontAttachment.Position = Vector3.new(0, 0, -part.Size.Z * 0.45)
	frontAttachment.Parent = part

	local backAttachment = Instance.new("Attachment")
	backAttachment.Name = "Back"
	backAttachment.Position = Vector3.new(0, 0, part.Size.Z * 0.45)
	backAttachment.Parent = part

	local trail = Instance.new("Trail")
	trail.Attachment0 = backAttachment
	trail.Attachment1 = frontAttachment
	trail.Color = ColorSequence.new(stats.projectileColor, stats.projectileColor:Lerp(Color3.new(1, 1, 1), 0.5))
	trail.LightEmission = 1
	trail.Lifetime = if stats.isUltimate then 0.35 else 0.22
	trail.MinLength = 0.05
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Parent = part

	createSparkEmitter(part, stats.projectileColor, if stats.isUltimate then 70 else 45, NumberRange.new(0.12, 0.28))
end

local function spawnImpactBurst(position: Vector3, color: Color3)
	local burst = Instance.new("Part")
	burst.Name = "SpellImpactBurst"
	burst.Anchored = true
	burst.CanCollide = false
	burst.CanQuery = false
	burst.CanTouch = false
	burst.Material = Enum.Material.Neon
	burst.Color = color
	burst.Size = Vector3.new(2.4, 2.4, 2.4)
	burst.Transparency = 0.35
	burst.CFrame = CFrame.new(position)
	burst.Parent = getProjectileFolder()

	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 5
	light.Range = 16
	light.Parent = burst

	local emitter = createSparkEmitter(burst, color, 120, NumberRange.new(0.2, 0.45))
	emitter.Speed = NumberRange.new(8, 18)
	emitter:Emit(24)

	task.delay(0.35, function()
		emitter.Enabled = false
		task.delay(0.4, function()
			burst:Destroy()
		end)
	end)
end

local function spawnNovaBurst(center: Vector3, radius: number, color: Color3, isUltimate: boolean)
	local ring = Instance.new("Part")
	ring.Name = "SpellNovaRing"
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Size = Vector3.new(radius * 0.35, 0.35, radius * 0.35)
	ring.Transparency = 0.25
	ring.CFrame = CFrame.new(center)
	ring.Parent = getProjectileFolder()

	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = if isUltimate then 6 else 4
	light.Range = radius * 1.2
	light.Parent = ring

	local emitter = createSparkEmitter(ring, color, 0, NumberRange.new(0.35, 0.7))
	emitter.Speed = NumberRange.new(radius * 0.35, radius * 0.8)
	emitter:Emit(if isUltimate then 80 else 48)

	task.spawn(function()
		local startSize = ring.Size
		local endSize = Vector3.new(radius * 2.1, 0.2, radius * 2.1)
		for step = 1, 10 do
			local alpha = step / 10
			ring.Size = startSize:Lerp(endSize, alpha)
			ring.Transparency = 0.25 + alpha * 0.55
			task.wait(0.03)
		end
		ring:Destroy()
	end)
end

local function canDamageMonster(monster: Model, player: Player): boolean
	if monster.Name ~= "WaveMonster" then
		return false
	end

	local ownerId = monster:GetAttribute("DungeonOwner")
	if typeof(ownerId) == "number" and ownerId ~= player.UserId then
		return false
	end

	return true
end

local function applySpellDamage(player: Player, monster: Model, stats: SpellUpgradeConfig.EffectiveSpellStats)
	local humanoid = monster:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or not canDamageMonster(monster, player) then
		return
	end

	local damage = math.random(stats.damageMin, stats.damageMax)
	local modifiers = CardService.getModifiers(player)
	damage = math.max(1, math.floor(damage * modifiers.damageMult))
	CardService.applyLifesteal(player, damage)
	humanoid:TakeDamage(damage)
end

local function flattenLookVector(root: BasePart): Vector3
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if look.Magnitude < 0.01 then
		return Vector3.new(0, 0, -1)
	end
	return look.Unit
end

local function getMonsterRoot(monster: Model): BasePart?
	return monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function spawnProjectile(
	player: Player,
	origin: Vector3,
	direction: Vector3,
	stats: SpellUpgradeConfig.EffectiveSpellStats
)
	if direction.Magnitude < 0.01 or stats.projectileSpeed <= 0 then
		return
	end

	local folder = getProjectileFolder()
	local part = Instance.new("Part")
	part.Name = "SpellProjectile"
	part.Size = stats.projectileSize
	part.Material = Enum.Material.Neon
	part.Color = stats.projectileColor
	part.CanCollide = false
	part.Anchored = false
	part.Massless = true
	part.CFrame = CFrame.lookAt(origin, origin + direction)
	part.Parent = folder

	decorateProjectile(part, stats)
	part.AssemblyLinearVelocity = direction.Unit * stats.projectileSpeed

	local hitMonsters: { [Model]: boolean } = {}
	local connection = part.Touched:Connect(function(hit)
		local monster = hit:FindFirstAncestorOfClass("Model")
		if not monster or hitMonsters[monster] or not canDamageMonster(monster, player) then
			return
		end

		hitMonsters[monster] = true
		spawnImpactBurst(part.Position, stats.projectileColor)
		applySpellDamage(player, monster, stats)
	end)

	task.delay(PROJECTILE_LIFETIME, function()
		connection:Disconnect()
		part:Destroy()
	end)
end

local function fireForwardProjectiles(player: Player, stats: SpellUpgradeConfig.EffectiveSpellStats)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local direction = flattenLookVector(root)
	local count = if stats.isUltimate then 2 else 1
	for index = 0, count - 1 do
		local origin = root.Position + Vector3.new(0, 1.2, 0) + direction * (1.5 + index * 1.2)
		spawnProjectile(player, origin, direction, stats)
	end
end

local function castFrostNova(player: Player, stats: SpellUpgradeConfig.EffectiveSpellStats)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local look = flattenLookVector(root)
	local center = root.Position + look * 5
	local radius = stats.aoeRadius or 10
	spawnNovaBurst(center, radius, stats.projectileColor, stats.isUltimate)
	local folder = getMonstersFolder()
	if not folder then
		return
	end

	for _, monster in folder:GetChildren() do
		if monster:IsA("Model") then
			local monsterRoot = getMonsterRoot(monster)
			if monsterRoot and (monsterRoot.Position - center).Magnitude <= radius then
				applySpellDamage(player, monster, stats)
			end
		end
	end
end

local function notifyCastEffect(player: Player, spellId: string, stats: SpellUpgradeConfig.EffectiveSpellStats)
	getSpellCastEffectEvent():FireClient(player, spellId, stats.resolvedName, stats.projectileColor)
end

local function notifyLoadout(player: Player)
	getSpellLoadoutUpdatedEvent():FireClient(
		player,
		PlayerDataService.getInfusedSpell(player),
		GamePhaseService.isLoadoutLocked(player)
	)
end

function SpellService.refreshPlayerLoadout(player: Player)
	if not isPlayerActive(player) then
		return
	end

	lastActiveCastAt[player] = nil
	lastInfusionProcAt[player] = nil
	notifyLoadout(player)
end

local function castInfusedSpell(player: Player, spellId: string): boolean
	local stats = getEffectiveStats(player, spellId)
	if spellId == "FrostNova" then
		castFrostNova(player, stats)
	else
		fireForwardProjectiles(player, stats)
	end
	notifyCastEffect(player, spellId, stats)
	return true
end

function SpellService.tryProcInfusionOnHit(player: Player)
	if not isPlayerActive(player) or not GamePhaseService.isInDungeon(player) then
		return
	end

	local spellId = PlayerDataService.getInfusedSpell(player)
	if spellId == "" or not PlayerDataService.ownsSpell(player, spellId) then
		return
	end

	local now = os.clock()
	if lastInfusionProcAt[player] and now - lastInfusionProcAt[player] < INFUSION_PROC_COOLDOWN then
		return
	end

	local stats = getEffectiveStats(player, spellId)
	if not StaminaService.trySpend(player, stats.staminaCost) then
		return
	end

	lastInfusionProcAt[player] = now
	castInfusedSpell(player, spellId)
end

local function tryCastActiveSpell(player: Player): boolean
	if not isPlayerActive(player) or not GamePhaseService.isInDungeon(player) then
		return false
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false
	end

	local spellId = PlayerDataService.getInfusedSpell(player)
	if spellId == "" or not PlayerDataService.ownsSpell(player, spellId) then
		return false
	end

	local stats = getEffectiveStats(player, spellId)
	local cooldown = stats.cooldown or 2
	local now = os.clock()
	local lastCast = lastActiveCastAt[player] or 0
	if now - lastCast < cooldown then
		return false
	end

	if not StaminaService.trySpend(player, stats.staminaCost) then
		return false
	end

	lastActiveCastAt[player] = now
	return castInfusedSpell(player, spellId)
end

function SpellService.infusePlayerSpell(player: Player, spellId: string): boolean
	if GamePhaseService.isLoadoutLocked(player) or not SpellConfig.isValid(spellId) then
		return false
	end

	if not PlayerDataService.setInfusedSpell(player, spellId) then
		return false
	end

	notifyLoadout(player)
	return true
end

function SpellService.upgradePlayerSpell(player: Player, spellId: string): boolean
	if not GamePhaseService.isInLobby(player) then
		return false
	end

	local ok = PlayerDataService.tryUpgradeSpell(player, spellId)
	return ok
end

function SpellService.unlockPlayerSpell(player: Player, spellId: string): boolean
	if not GamePhaseService.isInLobby(player) then
		return false
	end

	local ok = PlayerDataService.tryUnlockSpell(player, spellId)
	return ok
end

function SpellService.init()
	getInfuseSpellEvent()
	getUpgradeSpellEvent()
	getUnlockSpellEvent()
	getCastSpellEvent()
	getSpellLoadoutUpdatedEvent()
	getSpellCastEffectEvent()

	getInfuseSpellEvent().OnServerEvent:Connect(function(player, spellId: string)
		if typeof(spellId) ~= "string" then
			return
		end
		SpellService.infusePlayerSpell(player, spellId)
	end)

	getUpgradeSpellEvent().OnServerEvent:Connect(function(player, spellId: string)
		if typeof(spellId) ~= "string" then
			return
		end
		SpellService.upgradePlayerSpell(player, spellId)
	end)

	getUnlockSpellEvent().OnServerEvent:Connect(function(player, spellId: string)
		if typeof(spellId) ~= "string" then
			return
		end
		SpellService.unlockPlayerSpell(player, spellId)
	end)

	getCastSpellEvent().OnServerEvent:Connect(function(player)
		tryCastActiveSpell(player)
	end)

	for _, player in Players:GetPlayers() do
		notifyLoadout(player)
	end

	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			if isPlayerActive(player) then
				notifyLoadout(player)
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastActiveCastAt[player] = nil
		lastInfusionProcAt[player] = nil
	end)
end

return SpellService
