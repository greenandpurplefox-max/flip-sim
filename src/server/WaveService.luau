local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BossService = require(script.Parent.BossService)
local MonsterConfig = require(ReplicatedStorage.Shared.MonsterConfig)
local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)

local WaveService = {}

local activeMonsters: { Model } = {}
local lastAttackTimes: { [Model]: number } = {}
local attackingMonsters: { [Model]: boolean } = {}
local walkPhases: { [Model]: number } = {}
local monstersFolder: Folder
local waveStateEvent: RemoteEvent
local waveInProgress = false
local waveStatus = "idle"
local currentWave = 0
local waveSpawnTotal = 0
local interWaveScheduled = false
local waveTimeoutToken = 0
local aiRunning = false
local walkAnimRunning = false
local dungeonMode = false
local monsterDiedCallbacks: { (Model) -> () } = {}
WaveService.onPlayerDamagedCallback = nil

local WOLF_SCALE = WaveConfig.WOLF_SCALE

local function scaleVector(vector: Vector3): Vector3
	return vector * WOLF_SCALE
end

local function scaleOffset(offset: CFrame): CFrame
	return CFrame.new(scaleVector(offset.Position)) * (offset - offset.Position)
end

local FRONT_LEFT_LEG_REST = scaleOffset(CFrame.new(-0.38, -0.42, -0.68))
local FRONT_RIGHT_LEG_REST = scaleOffset(CFrame.new(0.38, -0.42, -0.68))
local BACK_LEFT_LEG_REST = scaleOffset(CFrame.new(-0.34, -0.42, 0.72))
local BACK_RIGHT_LEG_REST = scaleOffset(CFrame.new(0.34, -0.42, 0.72))
local NECK_REST = scaleOffset(CFrame.new(0, 0.28, -0.92) * CFrame.Angles(math.rad(-12), 0, 0))
local TAIL_REST = scaleOffset(CFrame.new(0, 0.08, 1.02) * CFrame.Angles(math.rad(28), 0, 0))

type WolfPalette = {
	fur: Color3,
	darkFur: Color3,
	belly: Color3,
	nose: Color3,
	eye: Color3,
}

local WOLF_PALETTES: { WolfPalette } = {
	{
		fur = Color3.fromRGB(118, 118, 128),
		darkFur = Color3.fromRGB(62, 62, 70),
		belly = Color3.fromRGB(176, 176, 184),
		nose = Color3.fromRGB(28, 28, 32),
		eye = Color3.fromRGB(255, 214, 96),
	},
	{
		fur = Color3.fromRGB(132, 92, 58),
		darkFur = Color3.fromRGB(78, 52, 34),
		belly = Color3.fromRGB(188, 156, 118),
		nose = Color3.fromRGB(32, 24, 20),
		eye = Color3.fromRGB(255, 208, 88),
	},
	{
		fur = Color3.fromRGB(48, 48, 56),
		darkFur = Color3.fromRGB(24, 24, 28),
		belly = Color3.fromRGB(92, 92, 100),
		nose = Color3.fromRGB(16, 16, 18),
		eye = Color3.fromRGB(255, 220, 110),
	},
}

local function weld(part0: BasePart, part1: BasePart)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = part0
	constraint.Part1 = part1
	constraint.Parent = part0
end

local function attachMotor(part0: BasePart, part1: BasePart, name: string, restOffset: CFrame): Motor6D
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = restOffset
	motor.C1 = CFrame.new()
	motor.Parent = part0
	return motor
end

local function getNearestPlayerDistance(position: Vector3): number
	local nearestDistance = math.huge

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoidRootPart then
			nearestDistance = math.min(nearestDistance, (humanoidRootPart.Position - position).Magnitude)
		end
	end

	return nearestDistance
end

local function createPart(
	name: string,
	size: Vector3,
	color: Color3,
	parent: Instance,
	options: {
		material: Enum.Material?,
		canCollide: boolean?,
		massless: boolean?,
		shape: Enum.PartType?,
	}?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = if options and options.material then options.material else Enum.Material.SmoothPlastic
	part.CanCollide = if options and options.canCollide ~= nil then options.canCollide else false
	part.Massless = if options and options.massless ~= nil then options.massless else false
	if options and options.shape then
		part.Shape = options.shape
	end
	part.Anchored = false
	part.Parent = parent
	return part
end

local function scaledSize(size: Vector3): Vector3
	return scaleVector(size)
end

local function offset(position: Vector3): CFrame
	return CFrame.new(scaleVector(position))
end

local function broadcastWaveState()
	if waveStateEvent then
		local loadoutLocked = waveStatus == "fighting"
		waveStateEvent:FireAllClients(waveInProgress, #activeMonsters, waveSpawnTotal, currentWave, waveStatus, loadoutLocked)
	end
end

function WaveService.isLoadoutLocked(): boolean
	return waveStatus == "fighting"
end

local function cancelWaveTimeout()
	waveTimeoutToken += 1
end

local function startWaveTimeout()
	cancelWaveTimeout()
	local token = waveTimeoutToken

	task.delay(WaveConfig.WAVE_TIMEOUT, function()
		if token ~= waveTimeoutToken or not waveInProgress or waveStatus ~= "fighting" then
			return
		end

		for index = #activeMonsters, 1, -1 do
			local monster = activeMonsters[index]
			if monster.Parent then
				monster:Destroy()
			end
			table.remove(activeMonsters, index)
		end

		for _, child in monstersFolder:GetChildren() do
			if child:IsA("Model") and child.Name == "WaveMonster" and child:GetAttribute("TrainingDummy") ~= true then
				child:Destroy()
			end
		end

		onWaveCleared()
	end)
end

local function onWaveCleared()
	if dungeonMode then
		return
	end

	if interWaveScheduled then
		return
	end

	cancelWaveTimeout()
	waveInProgress = false
	waveStatus = "intermission"
	interWaveScheduled = true
	broadcastWaveState()

	task.delay(WaveConfig.INTER_WAVE_DELAY, function()
		interWaveScheduled = false
		WaveService.startWave()
	end)
end

local function checkWaveComplete()
	if not waveInProgress or waveStatus ~= "fighting" then
		broadcastWaveState()
		return
	end

	if waveSpawnTotal > 0 and #activeMonsters <= 0 then
		onWaveCleared()
	else
		broadcastWaveState()
	end
end

local function onMonsterDiedInternal(model: Model)
	lastAttackTimes[model] = nil
	attackingMonsters[model] = nil
	walkPhases[model] = nil
	BossService.cleanup(model)

	local index = table.find(activeMonsters, model)
	if index then
		table.remove(activeMonsters, index)
	end

	for _, callback in monsterDiedCallbacks do
		callback(model)
	end

	checkWaveComplete()

	local headPart = model:FindFirstChild("Head")
	local healthBar = headPart and headPart:FindFirstChild("HealthBar")
	if healthBar then
		healthBar:Destroy()
	end

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end

	task.delay(1.2, function()
		if model.Parent then
			model:Destroy()
		end
	end)
end

local function registerMonster(model: Model)
	table.insert(activeMonsters, model)
	lastAttackTimes[model] = 0
	walkPhases[model] = 0

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			onMonsterDiedInternal(model)
		end)
	end
end

local function keepMonsterUpright(root: BasePart)
	local lookVector = root.CFrame.LookVector
	local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
	if flatLook.Magnitude < 0.05 then
		flatLook = Vector3.new(0, 0, -1)
	else
		flatLook = flatLook.Unit
	end

	root.CFrame = CFrame.new(root.Position, root.Position + flatLook)
	root.AssemblyAngularVelocity = Vector3.zero
end

local function configureStableHumanoid(humanoid: Humanoid)
	humanoid.AutoRotate = true
	humanoid.BreakJointsOnDeath = false

	for _, state in {
		Enum.HumanoidStateType.FallingDown,
		Enum.HumanoidStateType.Ragdoll,
		Enum.HumanoidStateType.Physics,
	} do
		pcall(function()
			humanoid:SetStateEnabled(state, false)
		end)
	end
end

function WaveService.createMonster(spawnPosition: Vector3, monsterTypeId: string?, roomDepth: number?): Model
	local depth = roomDepth or 1
	local typeId = monsterTypeId or "Wolf"
	local baseType = MonsterConfig.getType(typeId)
	local stats = MonsterConfig.getScaledStats(baseType, depth)
	local monsterScale = WaveConfig.WOLF_SCALE * stats.scaleMult

	local function scaleVector(vector: Vector3): Vector3
		return vector * monsterScale
	end

	local function scaleOffset(offset: CFrame): CFrame
		return CFrame.new(scaleVector(offset.Position)) * (offset - offset.Position)
	end

	local function scaledSize(size: Vector3): Vector3
		return scaleVector(size)
	end

	local function offset(position: Vector3): CFrame
		return CFrame.new(scaleVector(position))
	end

	local FRONT_LEFT_LEG_REST = scaleOffset(CFrame.new(-0.38, -0.42, -0.68))
	local FRONT_RIGHT_LEG_REST = scaleOffset(CFrame.new(0.38, -0.42, -0.68))
	local BACK_LEFT_LEG_REST = scaleOffset(CFrame.new(-0.34, -0.42, 0.72))
	local BACK_RIGHT_LEG_REST = scaleOffset(CFrame.new(0.34, -0.42, 0.72))
	local NECK_REST = scaleOffset(CFrame.new(0, 0.28, -0.92) * CFrame.Angles(math.rad(-12), 0, 0))
	local TAIL_REST = scaleOffset(CFrame.new(0, 0.08, 1.02) * CFrame.Angles(math.rad(28), 0, 0))

	local palette = if stats.paletteIndex
		then WOLF_PALETTES[stats.paletteIndex]
		else WOLF_PALETTES[math.random(1, #WOLF_PALETTES)]
	local model = Instance.new("Model")
	model.Name = "WaveMonster"

	local humanoidRootPart = createPart("HumanoidRootPart", scaledSize(Vector3.new(1.1, 0.65, 1.45)), palette.fur, model, {
		canCollide = false,
		massless = true,
	})
	humanoidRootPart.Transparency = 1

	local body = createPart("Body", scaledSize(Vector3.new(1.12, 0.78, 2.05)), palette.fur, model)
	local chest = createPart("Chest", scaledSize(Vector3.new(0.95, 0.72, 0.82)), palette.fur, model)
	local belly = createPart("Belly", scaledSize(Vector3.new(0.88, 0.18, 1.45)), palette.belly, model, { massless = true })
	local haunch = createPart("Haunch", scaledSize(Vector3.new(1.02, 0.68, 0.72)), palette.darkFur, model)
	local leftPlate: Part? = nil
	local rightPlate: Part? = nil
	if stats.isArmored then
		leftPlate = createPart("LeftPlate", scaledSize(Vector3.new(0.22, 0.42, 0.62)), Color3.fromRGB(88, 92, 98), model, {
			material = Enum.Material.Metal,
			massless = true,
		})
		rightPlate = createPart("RightPlate", scaledSize(Vector3.new(0.22, 0.42, 0.62)), Color3.fromRGB(88, 92, 98), model, {
			material = Enum.Material.Metal,
			massless = true,
		})
	end

	local head = createPart("Head", scaledSize(Vector3.new(0.68, 0.62, 0.78)), palette.fur, model)
	local snout = createPart("Snout", scaledSize(Vector3.new(0.42, 0.36, 0.72)), palette.fur, model, { massless = true })
	local nose = createPart("Nose", scaledSize(Vector3.new(0.18, 0.12, 0.12)), palette.nose, model, { massless = true })
	local leftEar = createPart("LeftEar", scaledSize(Vector3.new(0.16, 0.34, 0.18)), palette.darkFur, model, { massless = true })
	local rightEar = createPart("RightEar", scaledSize(Vector3.new(0.16, 0.34, 0.18)), palette.darkFur, model, { massless = true })
	local leftEye = createPart("LeftEye", scaledSize(Vector3.new(0.12, 0.12, 0.08)), palette.eye, model, {
		massless = true,
		material = Enum.Material.Neon,
	})
	local rightEye = createPart("RightEye", scaledSize(Vector3.new(0.12, 0.12, 0.08)), palette.eye, model, {
		massless = true,
		material = Enum.Material.Neon,
	})

	local frontLeftLeg = createPart("FrontLeftLeg", scaledSize(Vector3.new(0.28, 0.88, 0.28)), palette.darkFur, model, {
		canCollide = true,
	})
	local frontRightLeg = createPart("FrontRightLeg", scaledSize(Vector3.new(0.28, 0.88, 0.28)), palette.darkFur, model, {
		canCollide = true,
	})
	local backLeftLeg = createPart("BackLeftLeg", scaledSize(Vector3.new(0.28, 0.92, 0.3)), palette.darkFur, model, {
		canCollide = true,
	})
	local backRightLeg = createPart("BackRightLeg", scaledSize(Vector3.new(0.28, 0.92, 0.3)), palette.darkFur, model, {
		canCollide = true,
	})

	local frontLeftPaw = createPart("FrontLeftPaw", scaledSize(Vector3.new(0.32, 0.12, 0.36)), palette.nose, model, {
		massless = true,
	})
	local frontRightPaw = createPart("FrontRightPaw", scaledSize(Vector3.new(0.32, 0.12, 0.36)), palette.nose, model, {
		massless = true,
	})
	local backLeftPaw = createPart("BackLeftPaw", scaledSize(Vector3.new(0.34, 0.12, 0.38)), palette.nose, model, {
		massless = true,
	})
	local backRightPaw = createPart("BackRightPaw", scaledSize(Vector3.new(0.34, 0.12, 0.38)), palette.nose, model, {
		massless = true,
	})

	local tail = createPart("Tail", scaledSize(Vector3.new(0.22, 0.22, 0.82)), palette.fur, model, { massless = true })
	local tailTip = createPart("TailTip", scaledSize(Vector3.new(0.18, 0.18, 0.42)), palette.darkFur, model, { massless = true })
	local biteHitbox = createPart("BiteHitbox", scaledSize(Vector3.new(0.55, 0.42, 0.65)), palette.fur, model, {
		massless = true,
	})
	biteHitbox.Transparency = 1

	local rootCFrame = CFrame.new(spawnPosition)
	humanoidRootPart.CFrame = rootCFrame

	body.CFrame = rootCFrame
	if leftPlate and rightPlate then
		leftPlate.CFrame = body.CFrame * offset(Vector3.new(-0.58, 0.12, -0.08))
		rightPlate.CFrame = body.CFrame * offset(Vector3.new(0.58, 0.12, -0.08))
		weld(body, leftPlate)
		weld(body, rightPlate)
	end
	chest.CFrame = rootCFrame * offset(Vector3.new(0, 0.08, -0.72))
	belly.CFrame = rootCFrame * offset(Vector3.new(0, -0.28, 0.02))
	haunch.CFrame = rootCFrame * offset(Vector3.new(0, 0.04, 0.78))
	head.CFrame = rootCFrame * offset(Vector3.new(0, 0.34, -1.02))
	snout.CFrame = rootCFrame * offset(Vector3.new(0, 0.18, -1.42))
	nose.CFrame = rootCFrame * offset(Vector3.new(0, 0.12, -1.78))
	leftEar.CFrame = rootCFrame * offset(Vector3.new(-0.24, 0.58, -1.08)) * CFrame.Angles(0, 0, math.rad(18))
	rightEar.CFrame = rootCFrame * offset(Vector3.new(0.24, 0.58, -1.08)) * CFrame.Angles(0, 0, math.rad(-18))
	leftEye.CFrame = rootCFrame * offset(Vector3.new(-0.18, 0.36, -1.28))
	rightEye.CFrame = rootCFrame * offset(Vector3.new(0.18, 0.36, -1.28))
	frontLeftLeg.CFrame = rootCFrame * FRONT_LEFT_LEG_REST
	frontRightLeg.CFrame = rootCFrame * FRONT_RIGHT_LEG_REST
	backLeftLeg.CFrame = rootCFrame * BACK_LEFT_LEG_REST
	backRightLeg.CFrame = rootCFrame * BACK_RIGHT_LEG_REST
	frontLeftPaw.CFrame = frontLeftLeg.CFrame * offset(Vector3.new(0, -0.48, -0.04))
	frontRightPaw.CFrame = frontRightLeg.CFrame * offset(Vector3.new(0, -0.48, -0.04))
	backLeftPaw.CFrame = backLeftLeg.CFrame * offset(Vector3.new(0, -0.5, 0.02))
	backRightPaw.CFrame = backRightLeg.CFrame * offset(Vector3.new(0, -0.5, 0.02))
	tail.CFrame = rootCFrame * TAIL_REST
	tailTip.CFrame = tail.CFrame * offset(Vector3.new(0, 0.04, 0.58))
	biteHitbox.CFrame = snout.CFrame * offset(Vector3.new(0, -0.02, -0.18))

	weld(humanoidRootPart, body)
	weld(body, chest)
	weld(body, belly)
	weld(body, haunch)
	weld(head, snout)
	weld(snout, nose)
	weld(snout, biteHitbox)
	weld(head, leftEar)
	weld(head, rightEar)
	weld(head, leftEye)
	weld(head, rightEye)
	weld(frontLeftLeg, frontLeftPaw)
	weld(frontRightLeg, frontRightPaw)
	weld(backLeftLeg, backLeftPaw)
	weld(backRightLeg, backRightPaw)
	weld(tail, tailTip)

	local neckMotor = attachMotor(body, head, "NeckMotor", NECK_REST)
	local tailMotor = attachMotor(body, tail, "TailMotor", TAIL_REST)
	local frontLeftLegMotor = attachMotor(humanoidRootPart, frontLeftLeg, "FrontLeftLegMotor", FRONT_LEFT_LEG_REST)
	local frontRightLegMotor = attachMotor(humanoidRootPart, frontRightLeg, "FrontRightLegMotor", FRONT_RIGHT_LEG_REST)
	local backLeftLegMotor = attachMotor(humanoidRootPart, backLeftLeg, "BackLeftLegMotor", BACK_LEFT_LEG_REST)
	local backRightLegMotor = attachMotor(humanoidRootPart, backRightLeg, "BackRightLegMotor", BACK_RIGHT_LEG_REST)

	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = stats.walkSpeed
	humanoid.HipHeight = WaveConfig.MONSTER_HIP_HEIGHT * stats.scaleMult
	humanoid.MaxHealth = stats.health
	humanoid.Health = stats.health
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model
	configureStableHumanoid(humanoid)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.fromOffset(72, 10)
	billboard.StudsOffset = Vector3.new(0, 1.35 * monsterScale, 0)
	billboard.AlwaysOnTop = true
	billboard.Enabled = false
	billboard.Parent = head

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	background.BorderSizePixel = 0
	background.Size = UDim2.fromScale(1, 1)
	background.Parent = billboard

	local backgroundStroke = Instance.new("UIStroke")
	backgroundStroke.Color = Color3.fromRGB(0, 0, 0)
	backgroundStroke.Thickness = 1
	backgroundStroke.Parent = background

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = background

	local function updateHealthBar()
		local ratio = if humanoid.MaxHealth > 0 then math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) else 0
		fill.Size = UDim2.new(ratio, 0, 1, 0)

		local distance = getNearestPlayerDistance(humanoidRootPart.Position)
		local hasTakenDamage = humanoid.Health < humanoid.MaxHealth
		billboard.Enabled = hasTakenDamage and distance <= WaveConfig.MONSTER_HEALTHBAR_DISTANCE
	end

	humanoid.HealthChanged:Connect(updateHealthBar)
	updateHealthBar()

	model:SetAttribute("MonsterType", stats.id)
	model:SetAttribute("MonsterDamage", stats.damage)
	model:SetAttribute("AttackRange", stats.attackRange)
	model:SetAttribute("AttackCooldown", stats.attackCooldown)
	model:SetAttribute("MonsterScale", monsterScale)
	model:SetAttribute("NeckRest", NECK_REST)
	model:SetAttribute("TailRest", TAIL_REST)
	model:SetAttribute("FrontLeftLegRest", FRONT_LEFT_LEG_REST)
	model:SetAttribute("FrontRightLegRest", FRONT_RIGHT_LEG_REST)
	model:SetAttribute("BackLeftLegRest", BACK_LEFT_LEG_REST)
	model:SetAttribute("BackRightLegRest", BACK_RIGHT_LEG_REST)
	model:SetAttribute("NeckMotorName", neckMotor.Name)
	model:SetAttribute("TailMotorName", tailMotor.Name)
	model:SetAttribute("FrontLeftLegMotorName", frontLeftLegMotor.Name)
	model:SetAttribute("FrontRightLegMotorName", frontRightLegMotor.Name)
	model:SetAttribute("BackLeftLegMotorName", backLeftLegMotor.Name)
	model:SetAttribute("BackRightLegMotorName", backRightLegMotor.Name)

	model.PrimaryPart = humanoidRootPart
	model:PivotTo(rootCFrame)
	model.Parent = monstersFolder
	registerMonster(model)

	return model
end

local function getSpawnPosition(radiusMin: number?, radiusMax: number?): Vector3
	local angle = math.random() * math.pi * 2
	local minRadius = radiusMin or WaveConfig.SPAWN_RADIUS_MIN
	local maxRadius = radiusMax or WaveConfig.SPAWN_RADIUS_MAX
	local radius = math.random(minRadius, maxRadius)
	local x = math.cos(angle) * radius
	local z = math.sin(angle) * radius
	return Vector3.new(x, WaveConfig.SPAWN_HEIGHT, z)
end

local function getNearestPlayerCharacter(monster: Model): Model?
	local root = monster.PrimaryPart
	if not root then
		return nil
	end

	local ownerUserId = monster:GetAttribute("DungeonOwner")
	if typeof(ownerUserId) == "number" then
		local owner = Players:GetPlayerByUserId(ownerUserId)
		local character = owner and owner.Character
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoidRootPart and humanoid and humanoid.Health > 0 then
			return character
		end
		return nil
	end

	local nearestCharacter: Model? = nil
	local nearestDistance = math.huge

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if humanoidRootPart and humanoid and humanoid.Health > 0 then
			local distance = (humanoidRootPart.Position - root.Position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestCharacter = character
			end
		end
	end

	return nearestCharacter
end

local function getMotor(root: BasePart, monster: Model, attributeName: string): Motor6D?
	return root:FindFirstChild(monster:GetAttribute(attributeName) :: string) :: Motor6D?
end

local function getMonsterAttackParts(monster: Model): { BasePart }
	local parts: { BasePart } = {}
	for _, name in { "BiteHitbox", "Snout", "Head" } do
		local part = monster:FindFirstChild(name, true) :: BasePart?
		if part then
			table.insert(parts, part)
		end
	end
	return parts
end

local function tryDamagePlayerFromAttack(monster: Model, target: Model): boolean
	local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return false
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { target }

	local hitScale = WaveConfig.MONSTER_ATTACK_HITBOX_SCALE
	local damage = monster:GetAttribute("MonsterDamage") or WaveConfig.MONSTER_DAMAGE
	for _, hitPart in getMonsterAttackParts(monster) do
		local hits = workspace:GetPartBoundsInBox(hitPart.CFrame, hitPart.Size * hitScale, overlapParams)
		if #hits > 0 then
			targetHumanoid:TakeDamage(damage)
			local targetPlayer = Players:GetPlayerFromCharacter(target)
			if targetPlayer and WaveService.onPlayerDamagedCallback then
				WaveService.onPlayerDamagedCallback(targetPlayer)
			end
			return true
		end
	end

	return false
end

local function getMonsterRestCFrames(monster: Model): {
	neck: CFrame,
	tail: CFrame,
	frontLeftLeg: CFrame,
	frontRightLeg: CFrame,
	backLeftLeg: CFrame,
	backRightLeg: CFrame,
	scale: number,
}
	local scale = monster:GetAttribute("MonsterScale") or WOLF_SCALE
	return {
		neck = monster:GetAttribute("NeckRest") or NECK_REST,
		tail = monster:GetAttribute("TailRest") or TAIL_REST,
		frontLeftLeg = monster:GetAttribute("FrontLeftLegRest") or FRONT_LEFT_LEG_REST,
		frontRightLeg = monster:GetAttribute("FrontRightLegRest") or FRONT_RIGHT_LEG_REST,
		backLeftLeg = monster:GetAttribute("BackLeftLegRest") or BACK_LEFT_LEG_REST,
		backRightLeg = monster:GetAttribute("BackRightLegRest") or BACK_RIGHT_LEG_REST,
		scale = scale,
	}
end

local function playAttackAnimation(monster: Model, target: Model): boolean
	if attackingMonsters[monster] then
		return false
	end

	local root = monster.PrimaryPart
	local body = monster:FindFirstChild("Body") :: BasePart?
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or not body or not targetRoot then
		return false
	end

	local neckMotor = getMotor(body, monster, "NeckMotorName")
	local tailMotor = getMotor(body, monster, "TailMotorName")
	local frontLeftLegMotor = getMotor(root, monster, "FrontLeftLegMotorName")
	local frontRightLegMotor = getMotor(root, monster, "FrontRightLegMotorName")
	local backLeftLegMotor = getMotor(root, monster, "BackLeftLegMotorName")
	local backRightLegMotor = getMotor(root, monster, "BackRightLegMotorName")

	if not neckMotor or not tailMotor or not frontLeftLegMotor or not frontRightLegMotor or not backLeftLegMotor or not backRightLegMotor then
		return false
	end

	attackingMonsters[monster] = true

	local rests = getMonsterRestCFrames(monster)
	local startCFrame = root.CFrame
	local direction = (targetRoot.Position - root.Position).Unit
	local lungeTarget = CFrame.lookAt(
		startCFrame.Position + direction * (1.35 * rests.scale) + Vector3.new(0, 0.08, 0),
		Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z)
	)

	local neckCrouch = rests.neck * CFrame.Angles(math.rad(18), 0, 0)
	local neckBite = rests.neck * CFrame.new(0, -0.08 * rests.scale, -0.22 * rests.scale) * CFrame.Angles(math.rad(42), 0, 0)
	local tailRaise = rests.tail * CFrame.Angles(math.rad(-24), 0, 0)
	local haunchCompress = CFrame.new(0, 0.08 * rests.scale, 0.06 * rests.scale) * CFrame.Angles(math.rad(28), 0, 0)
	local frontExtend = CFrame.new(0, -0.06 * rests.scale, -0.12 * rests.scale) * CFrame.Angles(math.rad(-24), 0, 0)
	local didDamage = false

	task.spawn(function()
		for step = 1, 3 do
			if not monster.Parent then
				break
			end
			local alpha = step / 3
			root.CFrame = startCFrame:Lerp(lungeTarget, alpha * 0.35)
			neckMotor.C0 = rests.neck:Lerp(neckCrouch, alpha)
			tailMotor.C0 = rests.tail:Lerp(tailRaise, alpha)
			backLeftLegMotor.C0 = rests.backLeftLeg:Lerp(rests.backLeftLeg * haunchCompress, alpha)
			backRightLegMotor.C0 = rests.backRightLeg:Lerp(rests.backRightLeg * haunchCompress, alpha)
			task.wait(0.035)
		end

		for step = 1, 4 do
			if not monster.Parent then
				break
			end
			local alpha = step / 4
			root.CFrame = startCFrame:Lerp(lungeTarget, 0.35 + alpha * 0.65)
			neckMotor.C0 = neckCrouch:Lerp(neckBite, alpha)
			frontLeftLegMotor.C0 = rests.frontLeftLeg:Lerp(rests.frontLeftLeg * frontExtend, alpha)
			frontRightLegMotor.C0 = rests.frontRightLeg:Lerp(rests.frontRightLeg * frontExtend, alpha)
			backLeftLegMotor.C0 = rests.backLeftLeg * haunchCompress:Lerp(rests.backLeftLeg, alpha)
			backRightLegMotor.C0 = rests.backRightLeg * haunchCompress:Lerp(rests.backRightLeg, alpha)

			if step >= 3 and not didDamage then
				didDamage = tryDamagePlayerFromAttack(monster, target)
			end

			task.wait(0.03)
		end

		if not didDamage then
			didDamage = tryDamagePlayerFromAttack(monster, target)
		end

		task.wait(0.04)

		for step = 1, 5 do
			if not monster.Parent then
				break
			end
			local alpha = step / 5
			root.CFrame = lungeTarget:Lerp(startCFrame, alpha)
			neckMotor.C0 = neckBite:Lerp(rests.neck, alpha)
			tailMotor.C0 = tailRaise:Lerp(rests.tail, alpha)
			frontLeftLegMotor.C0 = (rests.frontLeftLeg * frontExtend):Lerp(rests.frontLeftLeg, alpha)
			frontRightLegMotor.C0 = (rests.frontRightLeg * frontExtend):Lerp(rests.frontRightLeg, alpha)
			backLeftLegMotor.C0 = rests.backLeftLeg
			backRightLegMotor.C0 = rests.backRightLeg
			task.wait(0.03)
		end

		neckMotor.C0 = rests.neck
		tailMotor.C0 = rests.tail
		frontLeftLegMotor.C0 = rests.frontLeftLeg
		frontRightLegMotor.C0 = rests.frontRightLeg
		backLeftLegMotor.C0 = rests.backLeftLeg
		backRightLegMotor.C0 = rests.backRightLeg
		attackingMonsters[monster] = nil
	end)

	return true
end

local function tryAttack(monster: Model, target: Model)
	if BossService.isBoss(monster) then
		return
	end

	local now = os.clock()
	local lastAttack = lastAttackTimes[monster] or 0
	local attackCooldown = monster:GetAttribute("AttackCooldown") or WaveConfig.ATTACK_COOLDOWN
	if now - lastAttack < attackCooldown then
		return
	end

	local monsterRoot = monster.PrimaryPart
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetHumanoid = target:FindFirstChildOfClass("Humanoid")

	if not monsterRoot or not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
		return
	end

	local attackRange = monster:GetAttribute("AttackRange") or WaveConfig.ATTACK_RANGE
	if (monsterRoot.Position - targetRoot.Position).Magnitude > attackRange then
		return
	end

	lastAttackTimes[monster] = now
	playAttackAnimation(monster, target)
end

local function updateMonster(monster: Model)
	if not monster.Parent then
		return
	end

	local humanoid = monster:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local target = getNearestPlayerCharacter(monster)
	if not target then
		return
	end

	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then
		return
	end

	local monsterRoot = monster.PrimaryPart
	if not monsterRoot then
		return
	end

	tryAttack(monster, target)

	local head = monster:FindFirstChild("Head")
	local billboard = head and head:FindFirstChild("HealthBar") :: BillboardGui?
	if billboard then
		local distance = getNearestPlayerDistance(monsterRoot.Position)
		local hasTakenDamage = humanoid.Health < humanoid.MaxHealth
		billboard.Enabled = hasTakenDamage and distance <= WaveConfig.MONSTER_HEALTHBAR_DISTANCE
	end

	if BossService.isBoss(monster) then
		BossService.updateBoss(monster, target)
		if not BossService.isBusy(monster) then
			local attackRange = monster:GetAttribute("AttackRange") or WaveConfig.ATTACK_RANGE
			if (monsterRoot.Position - targetRoot.Position).Magnitude > attackRange then
				humanoid:MoveTo(targetRoot.Position)
			end
		end
		return
	end

	if (monsterRoot.Position - targetRoot.Position).Magnitude > (monster:GetAttribute("AttackRange") or WaveConfig.ATTACK_RANGE)
		and not attackingMonsters[monster]
	then
		humanoid:MoveTo(targetRoot.Position)
	end
end

local function updateMonsterWalkAnimation(monster: Model, deltaTime: number)
	local humanoid = monster:FindFirstChildOfClass("Humanoid")
	local root = monster.PrimaryPart
	local body = monster:FindFirstChild("Body") :: BasePart?
	if not humanoid or not root or not body or humanoid.Health <= 0 then
		return
	end

	local neckMotor = getMotor(body, monster, "NeckMotorName")
	local tailMotor = getMotor(body, monster, "TailMotorName")
	local frontLeftLegMotor = getMotor(root, monster, "FrontLeftLegMotorName")
	local frontRightLegMotor = getMotor(root, monster, "FrontRightLegMotorName")
	local backLeftLegMotor = getMotor(root, monster, "BackLeftLegMotorName")
	local backRightLegMotor = getMotor(root, monster, "BackRightLegMotorName")

	if not neckMotor or not tailMotor or not frontLeftLegMotor or not frontRightLegMotor or not backLeftLegMotor or not backRightLegMotor then
		return
	end

	if attackingMonsters[monster] or BossService.isBusy(monster) then
		return
	end

	local rests = getMonsterRestCFrames(monster)
	local velocity = root.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local moving = horizontalSpeed > 1 or humanoid.MoveDirection.Magnitude > 0.05
	local phase = walkPhases[monster] or 0

	if moving then
		phase += deltaTime * WaveConfig.MONSTER_WALK_ANIM_SPEED
		walkPhases[monster] = phase

		local stride = math.sin(phase) * WaveConfig.MONSTER_LEG_SWING
		local oppositeStride = math.sin(phase + math.pi) * WaveConfig.MONSTER_LEG_SWING
		local bodyBob = math.abs(math.sin(phase)) * WaveConfig.MONSTER_BODY_BOB
		local headBob = math.sin(phase * 2) * WaveConfig.MONSTER_HEAD_BOB
		local tailSway = math.sin(phase) * WaveConfig.MONSTER_TAIL_SWING

		frontLeftLegMotor.C0 = rests.frontLeftLeg
			* CFrame.new(0, bodyBob * 0.12, stride * 0.14)
			* CFrame.Angles(stride, 0, stride * 0.18)
		backRightLegMotor.C0 = rests.backRightLeg
			* CFrame.new(0, bodyBob * 0.12, stride * 0.12)
			* CFrame.Angles(stride, 0, -stride * 0.12)
		frontRightLegMotor.C0 = rests.frontRightLeg
			* CFrame.new(0, bodyBob * 0.12, oppositeStride * 0.14)
			* CFrame.Angles(oppositeStride, 0, -oppositeStride * 0.18)
		backLeftLegMotor.C0 = rests.backLeftLeg
			* CFrame.new(0, bodyBob * 0.12, oppositeStride * 0.12)
			* CFrame.Angles(oppositeStride, 0, oppositeStride * 0.12)

		neckMotor.C0 = rests.neck * CFrame.Angles(headBob, 0, 0)
		tailMotor.C0 = rests.tail * CFrame.Angles(math.rad(-tailSway * 28), math.rad(tailSway * 18), 0)
	else
		walkPhases[monster] = phase
		frontLeftLegMotor.C0 = rests.frontLeftLeg
		frontRightLegMotor.C0 = rests.frontRightLeg
		backLeftLegMotor.C0 = rests.backLeftLeg
		backRightLegMotor.C0 = rests.backRightLeg
		neckMotor.C0 = rests.neck
		tailMotor.C0 = rests.tail * CFrame.Angles(0, 0, math.rad(math.sin(phase) * 4))
	end
end

local function runWalkAnimation()
	if walkAnimRunning then
		return
	end

	walkAnimRunning = true

	RunService.Heartbeat:Connect(function(deltaTime)
		for _, monster in activeMonsters do
			if monster.Parent then
				local humanoid = monster:FindFirstChildOfClass("Humanoid")
				local root = monster.PrimaryPart
				if humanoid and humanoid.Health > 0 and root then
					keepMonsterUpright(root)
				end
				updateMonsterWalkAnimation(monster, deltaTime)
			end
		end
	end)
end

local function runAI()
	if aiRunning then
		return
	end

	aiRunning = true

	task.spawn(function()
		while true do
			for index = #activeMonsters, 1, -1 do
				local monster = activeMonsters[index]
				if monster.Parent then
					updateMonster(monster)
				else
					lastAttackTimes[monster] = nil
					walkPhases[monster] = nil
					table.remove(activeMonsters, index)
					checkWaveComplete()
				end
			end
			task.wait(WaveConfig.AI_TICK)
		end
	end)
end

function WaveService.clearMonstersForOwner(ownerUserId: number)
	for index = #activeMonsters, 1, -1 do
		local monster = activeMonsters[index]
		if monster:GetAttribute("DungeonOwner") == ownerUserId then
			if monster.Parent then
				monster:Destroy()
			end
			table.remove(activeMonsters, index)
		end
	end
end

function WaveService.setDungeonMode(enabled: boolean)
	dungeonMode = enabled
end

function WaveService.onMonsterDied(callback: (Model) -> ())
	table.insert(monsterDiedCallbacks, callback)
end

function WaveService.setOnPlayerDamagedCallback(callback: ((Player) -> ())?)
	WaveService.onPlayerDamagedCallback = callback
end

function WaveService.spawnDungeonMonsters(
	roomDepth: number,
	ownerUserId: number,
	isBossRoom: boolean,
	radiusMin: number,
	radiusMax: number
): number
	local spawnCount = 0

	if isBossRoom then
		local boss = BossService.createBoss(
			getSpawnPosition(radiusMin, radiusMax),
			roomDepth,
			ownerUserId,
			monstersFolder,
			configureStableHumanoid
		)
		registerMonster(boss)
		spawnCount += 1
	end

	local minionCount = MonsterConfig.getMinionCountForRoom(roomDepth, isBossRoom)
	for _ = 1, minionCount do
		local monsterTypeId = MonsterConfig.rollTypeForDepth(roomDepth)
		local monster = WaveService.createMonster(getSpawnPosition(radiusMin, radiusMax), monsterTypeId, roomDepth)
		monster:SetAttribute("DungeonOwner", ownerUserId)
		spawnCount += 1
	end

	return spawnCount
end

function WaveService.startWave(): boolean
	if waveInProgress or interWaveScheduled then
		return false
	end

	cancelWaveTimeout()
	currentWave += 1
	waveSpawnTotal = WaveConfig.MONSTER_COUNT
	waveInProgress = true
	waveStatus = "fighting"

	for _ = 1, waveSpawnTotal do
		WaveService.createMonster(getSpawnPosition())
	end

	startWaveTimeout()
	broadcastWaveState()
	return true
end

function WaveService.init()
	monstersFolder = workspace:FindFirstChild("WaveMonsters") :: Folder?
	if not monstersFolder then
		monstersFolder = Instance.new("Folder")
		monstersFolder.Name = "WaveMonsters"
		monstersFolder.Parent = workspace
	end

	local startWaveEvent = ReplicatedStorage:FindFirstChild("StartWave") :: RemoteEvent?
	if not startWaveEvent then
		startWaveEvent = Instance.new("RemoteEvent")
		startWaveEvent.Name = "StartWave"
		startWaveEvent.Parent = ReplicatedStorage
	end

	waveStateEvent = ReplicatedStorage:FindFirstChild("WaveState") :: RemoteEvent?
	if not waveStateEvent then
		waveStateEvent = Instance.new("RemoteEvent")
		waveStateEvent.Name = "WaveState"
		waveStateEvent.Parent = ReplicatedStorage
	end

	for _, child in monstersFolder:GetChildren() do
		if child:IsA("Model") and child.Name == "WaveMonster" and child:GetAttribute("TrainingDummy") ~= true then
			table.insert(activeMonsters, child)
			waveInProgress = true
			waveStatus = "fighting"
			waveSpawnTotal = math.max(waveSpawnTotal, #activeMonsters)
			currentWave = math.max(currentWave, 1)
		end
	end
	if waveInProgress and #activeMonsters > 0 then
		startWaveTimeout()
	end
	broadcastWaveState()

	startWaveEvent.OnServerEvent:Connect(function(player)
		if dungeonMode then
			return
		end

		if waveInProgress or interWaveScheduled then
			return
		end

		print(`{player.Name} started a wave!`)
		WaveService.startWave()
	end)

	runAI()
	runWalkAnimation()
end

return WaveService
