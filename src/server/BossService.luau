local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BossConfig = require(ReplicatedStorage.Shared.BossConfig)
local DungeonConfig = require(ReplicatedStorage.Shared.DungeonConfig)
local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)

local BossService = {}

type BossAttackState = {
	attackId: string,
	phase: "windup" | "active" | "recover",
	startTime: number,
	startCFrame: CFrame?,
	targetPosition: Vector3?,
}

type BossRuntime = {
	lastAttackTime: number,
	busy: boolean,
	state: BossAttackState?,
}

local bossRuntimes: { [Model]: BossRuntime } = {}
local attackingBosses: { [Model]: boolean } = {}

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
		transparency: number?,
	}?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = if options and options.material then options.material else Enum.Material.SmoothPlastic
	part.CanCollide = if options and options.canCollide ~= nil then options.canCollide else false
	part.Massless = if options and options.massless ~= nil then options.massless else false
	part.Transparency = if options and options.transparency then options.transparency else 0
	if options and options.shape then
		part.Shape = options.shape
	end
	part.Anchored = false
	part.Parent = parent
	return part
end

local function getMotor(root: BasePart, monster: Model, attributeName: string): Motor6D?
	return root:FindFirstChild(monster:GetAttribute(attributeName) :: string) :: Motor6D?
end

local function spawnTelegraph(position: Vector3, radius: number, color: Color3, duration: number)
	local ring = Instance.new("Part")
	ring.Name = "BossTelegraph"
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.45
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.35, radius * 2, radius * 2)
	ring.CFrame = CFrame.new(position.X, position.Y + 0.12, position.Z) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace

	task.delay(duration, function()
		if ring.Parent then
			ring:Destroy()
		end
	end)
end

local function damagePlayersInRadius(origin: Vector3, radius: number, damage: number, ownerUserId: number?)
	local Players = game:GetService("Players")
	for _, player in Players:GetPlayers() do
		if ownerUserId and player.UserId ~= ownerUserId then
			continue
		end

		local character = player.Character
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoidRootPart and humanoid and humanoid.Health > 0 then
			local distance = (humanoidRootPart.Position - origin).Magnitude
			if distance <= radius then
				humanoid:TakeDamage(damage)
			end
		end
	end
end

local function pickAttack(monster: Model, target: Model): string?
	local root = monster.PrimaryPart
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or not targetRoot then
		return nil
	end

	local distance = (root.Position - targetRoot.Position).Magnitude
	local candidates: { { id: string, weight: number } } = {}

	for _, attack in BossConfig.ATTACKS do
		if distance >= attack.minRange and distance <= attack.maxRange then
			table.insert(candidates, { id = attack.id, weight = attack.weight })
		end
	end

	if #candidates == 0 then
		return "GroundSlam"
	end

	local totalWeight = 0
	for _, entry in candidates do
		totalWeight += entry.weight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, entry in candidates do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.id
		end
	end

	return candidates[1].id
end

local function finishAttack(monster: Model)
	attackingBosses[monster] = nil
	local runtime = bossRuntimes[monster]
	if runtime then
		runtime.busy = false
		runtime.state = nil
	end
end

local function executeGroundSlam(monster: Model, target: Model, attackConfig: typeof(BossConfig.ATTACKS.GroundSlam))
	local root = monster.PrimaryPart
	if not root then
		finishAttack(monster)
		return
	end

	local ownerUserId = monster:GetAttribute("DungeonOwner")
	spawnTelegraph(root.Position, attackConfig.radius, Color3.fromRGB(255, 72, 48), attackConfig.windup)

	task.delay(attackConfig.windup, function()
		if not monster.Parent or not root.Parent then
			finishAttack(monster)
			return
		end

		spawnTelegraph(root.Position, attackConfig.radius, Color3.fromRGB(255, 120, 48), 0.25)
		damagePlayersInRadius(
			root.Position,
			attackConfig.radius,
			attackConfig.damage,
			if typeof(ownerUserId) == "number" then ownerUserId else nil
		)
		task.delay(0.35, function()
			finishAttack(monster)
		end)
	end)
end

local function executeSavageCharge(monster: Model, target: Model, attackConfig: typeof(BossConfig.ATTACKS.SavageCharge))
	local root = monster.PrimaryPart
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or not targetRoot then
		finishAttack(monster)
		return
	end

	local ownerUserId = monster:GetAttribute("DungeonOwner")
	local startCFrame = root.CFrame
	local direction = (targetRoot.Position - root.Position).Unit
	local chargeTarget = startCFrame.Position + direction * attackConfig.chargeDistance
	local lookTarget = Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z)

	spawnTelegraph(root.Position, 4, Color3.fromRGB(255, 180, 48), attackConfig.windup)

	task.delay(attackConfig.windup, function()
		if not monster.Parent or not root.Parent then
			finishAttack(monster)
			return
		end

		local steps = 10
		for step = 1, steps do
			if not monster.Parent then
				break
			end
			local alpha = step / steps
			local nextPos = startCFrame.Position:Lerp(chargeTarget, alpha)
			root.CFrame = CFrame.lookAt(nextPos, lookTarget)
			damagePlayersInRadius(
				root.Position,
				5.5,
				attackConfig.damage,
				if typeof(ownerUserId) == "number" then ownerUserId else nil
			)
			task.wait(0.04)
		end

		task.delay(0.25, function()
			finishAttack(monster)
		end)
	end)
end

local function executeDarkHowl(monster: Model, attackConfig: typeof(BossConfig.ATTACKS.DarkHowl))
	local root = monster.PrimaryPart
	local body = monster:FindFirstChild("Body") :: BasePart?
	if not root or not body then
		finishAttack(monster)
		return
	end

	local ownerUserId = monster:GetAttribute("DungeonOwner")
	local neckMotor = getMotor(body, monster, "NeckMotorName")
	local tailMotor = getMotor(root, monster, "TailMotorName")
	local neckRest = monster:GetAttribute("NeckRest") :: CFrame?
	local tailRest = monster:GetAttribute("TailRest") :: CFrame?

	spawnTelegraph(root.Position, attackConfig.radius, Color3.fromRGB(140, 48, 255), attackConfig.windup * 0.7)

	task.spawn(function()
		for step = 1, 6 do
			if not monster.Parent or not neckMotor or not tailMotor or not neckRest or not tailRest then
				break
			end
			local alpha = step / 6
			neckMotor.C0 = neckRest * CFrame.Angles(math.rad(-28 * alpha), 0, 0)
			tailMotor.C0 = tailRest * CFrame.Angles(math.rad(18 * alpha), math.rad(12 * alpha), 0)
			task.wait(attackConfig.windup / 6)
		end

		if monster.Parent and root.Parent then
			spawnTelegraph(root.Position, attackConfig.radius, Color3.fromRGB(180, 72, 255), 0.35)
			damagePlayersInRadius(
				root.Position,
				attackConfig.radius,
				attackConfig.damage,
				if typeof(ownerUserId) == "number" then ownerUserId else nil
			)
		end

		if neckMotor and tailMotor and neckRest and tailRest then
			for step = 1, 4 do
				if not monster.Parent then
					break
				end
				local alpha = step / 4
				neckMotor.C0 = (neckRest * CFrame.Angles(math.rad(-28), 0, 0)):Lerp(neckRest, alpha)
				tailMotor.C0 = (tailRest * CFrame.Angles(math.rad(18), math.rad(12), 0)):Lerp(tailRest, alpha)
				task.wait(0.05)
			end
		end

		finishAttack(monster)
	end)
end

local function startBossAttack(monster: Model, target: Model, attackId: string)
	local attackConfig = BossConfig.ATTACKS[attackId]
	if not attackConfig then
		return false
	end

	attackingBosses[monster] = true
	local runtime = bossRuntimes[monster]
	if runtime then
		runtime.busy = true
		runtime.lastAttackTime = os.clock()
	end

	if attackId == "GroundSlam" then
		executeGroundSlam(monster, target, attackConfig)
	elseif attackId == "SavageCharge" then
		executeSavageCharge(monster, target, attackConfig)
	elseif attackId == "DarkHowl" then
		executeDarkHowl(monster, attackConfig)
	else
		finishAttack(monster)
		return false
	end

	return true
end

function BossService.isBoss(monster: Model): boolean
	return monster:GetAttribute("IsBoss") == true
end

function BossService.isBusy(monster: Model): boolean
	return attackingBosses[monster] == true
end

function BossService.cleanup(monster: Model)
	bossRuntimes[monster] = nil
	attackingBosses[monster] = nil
end

function BossService.updateBoss(monster: Model, target: Model)
	if BossService.isBusy(monster) then
		return
	end

	local runtime = bossRuntimes[monster]
	if not runtime then
		return
	end

	local now = os.clock()
	if now - runtime.lastAttackTime < BossConfig.ATTACK_COOLDOWN then
		return
	end

	local root = monster.PrimaryPart
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or not targetRoot then
		return
	end

	local distance = (root.Position - targetRoot.Position).Magnitude
	if distance > BossConfig.ATTACK_RANGE + 8 then
		return
	end

	local attackId = pickAttack(monster, target)
	if attackId then
		startBossAttack(monster, target, attackId)
	end
end

function BossService.createBoss(
	spawnPosition: Vector3,
	roomDepth: number,
	ownerUserId: number,
	monstersFolder: Folder,
	configureStableHumanoid: (Humanoid) -> ()
): Model
	local scale = BossConfig.SCALE
	local bossDepthIndex = BossConfig.getBossDepthIndex(roomDepth, DungeonConfig.BOSS_EVERY_N_ROOMS)
	local maxHealth = BossConfig.getHealthForDepth(bossDepthIndex)

	local function s(vector: Vector3): Vector3
		return vector * scale
	end

	local function sOffset(offset: CFrame): CFrame
		return CFrame.new(s(offset.Position)) * (offset - offset.Position)
	end

	local fur = Color3.fromRGB(42, 38, 48)
	local darkFur = Color3.fromRGB(22, 18, 28)
	local glow = Color3.fromRGB(255, 64, 72)

	local model = Instance.new("Model")
	model.Name = "WaveMonster"

	local humanoidRootPart = createPart("HumanoidRootPart", s(Vector3.new(1.1, 0.65, 1.45)), fur, model, {
		canCollide = false,
		massless = true,
	})
	humanoidRootPart.Transparency = 1

	local body = createPart("Body", s(Vector3.new(1.12, 0.78, 2.05)), fur, model)
	local chest = createPart("Chest", s(Vector3.new(0.95, 0.72, 0.82)), darkFur, model)
	local head = createPart("Head", s(Vector3.new(0.68, 0.62, 0.78)), fur, model)
	local snout = createPart("Snout", s(Vector3.new(0.42, 0.36, 0.72)), darkFur, model, { massless = true })
	local leftHorn = createPart("LeftHorn", s(Vector3.new(0.16, 0.52, 0.16)), Color3.fromRGB(92, 88, 96), model, { massless = true })
	local rightHorn = createPart("RightHorn", s(Vector3.new(0.16, 0.52, 0.16)), Color3.fromRGB(92, 88, 96), model, { massless = true })
	local leftEye = createPart("LeftEye", s(Vector3.new(0.14, 0.14, 0.08)), glow, model, {
		massless = true,
		material = Enum.Material.Neon,
	})
	local rightEye = createPart("RightEye", s(Vector3.new(0.14, 0.14, 0.08)), glow, model, {
		massless = true,
		material = Enum.Material.Neon,
	})
	local biteHitbox = createPart("BiteHitbox", s(Vector3.new(0.55, 0.42, 0.65)), fur, model, {
		massless = true,
		transparency = 1,
	})
	local tail = createPart("Tail", s(Vector3.new(0.22, 0.22, 0.82)), darkFur, model, { massless = true })

	local frontLeftLeg = createPart("FrontLeftLeg", s(Vector3.new(0.28, 0.88, 0.28)), darkFur, model, { canCollide = true })
	local frontRightLeg = createPart("FrontRightLeg", s(Vector3.new(0.28, 0.88, 0.28)), darkFur, model, { canCollide = true })
	local backLeftLeg = createPart("BackLeftLeg", s(Vector3.new(0.28, 0.92, 0.3)), darkFur, model, { canCollide = true })
	local backRightLeg = createPart("BackRightLeg", s(Vector3.new(0.28, 0.92, 0.3)), darkFur, model, { canCollide = true })

	local rootCFrame = CFrame.new(spawnPosition)
	humanoidRootPart.CFrame = rootCFrame
	body.CFrame = rootCFrame
	chest.CFrame = rootCFrame * sOffset(CFrame.new(0, 0.08, -0.72))
	head.CFrame = rootCFrame * sOffset(CFrame.new(0, 0.34, -1.02))
	snout.CFrame = rootCFrame * sOffset(CFrame.new(0, 0.18, -1.42))
	leftHorn.CFrame = head.CFrame * sOffset(CFrame.new(-0.18, 0.42, -0.12)) * CFrame.Angles(0, 0, math.rad(24))
	rightHorn.CFrame = head.CFrame * sOffset(CFrame.new(0.18, 0.42, -0.12)) * CFrame.Angles(0, 0, math.rad(-24))
	leftEye.CFrame = rootCFrame * sOffset(CFrame.new(-0.18, 0.36, -1.28))
	rightEye.CFrame = rootCFrame * sOffset(CFrame.new(0.18, 0.36, -1.28))
	biteHitbox.CFrame = snout.CFrame * sOffset(CFrame.new(0, -0.02, -0.18))
	tail.CFrame = rootCFrame * sOffset(CFrame.new(0, 0.08, 1.02) * CFrame.Angles(math.rad(28), 0, 0))
	frontLeftLeg.CFrame = rootCFrame * sOffset(CFrame.new(-0.38, -0.42, -0.68))
	frontRightLeg.CFrame = rootCFrame * sOffset(CFrame.new(0.38, -0.42, -0.68))
	backLeftLeg.CFrame = rootCFrame * sOffset(CFrame.new(-0.34, -0.42, 0.72))
	backRightLeg.CFrame = rootCFrame * sOffset(CFrame.new(0.34, -0.42, 0.72))

	weld(humanoidRootPart, body)
	weld(body, chest)
	weld(head, snout)
	weld(snout, biteHitbox)
	weld(head, leftHorn)
	weld(head, rightHorn)
	weld(head, leftEye)
	weld(head, rightEye)
	weld(body, tail)

	local neckRest = sOffset(CFrame.new(0, 0.28, -0.92) * CFrame.Angles(math.rad(-12), 0, 0))
	local tailRest = sOffset(CFrame.new(0, 0.08, 1.02) * CFrame.Angles(math.rad(28), 0, 0))
	local frontLeftLegRest = sOffset(CFrame.new(-0.38, -0.42, -0.68))
	local frontRightLegRest = sOffset(CFrame.new(0.38, -0.42, -0.68))
	local backLeftLegRest = sOffset(CFrame.new(-0.34, -0.42, 0.72))
	local backRightLegRest = sOffset(CFrame.new(0.34, -0.42, 0.72))

	local neckMotor = attachMotor(body, head, "NeckMotor", neckRest)
	local tailMotor = attachMotor(body, tail, "TailMotor", tailRest)
	local frontLeftLegMotor = attachMotor(humanoidRootPart, frontLeftLeg, "FrontLeftLegMotor", frontLeftLegRest)
	local frontRightLegMotor = attachMotor(humanoidRootPart, frontRightLeg, "FrontRightLegMotor", frontRightLegRest)
	local backLeftLegMotor = attachMotor(humanoidRootPart, backLeftLeg, "BackLeftLegMotor", backLeftLegRest)
	local backRightLegMotor = attachMotor(humanoidRootPart, backRightLeg, "BackRightLegMotor", backRightLegRest)

	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = BossConfig.WALK_SPEED
	humanoid.HipHeight = WaveConfig.MONSTER_HIP_HEIGHT * scale
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model
	configureStableHumanoid(humanoid)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.fromOffset(110, 16)
	billboard.StudsOffset = Vector3.new(0, 2.1 * scale, 0)
	billboard.AlwaysOnTop = true
	billboard.Enabled = true
	billboard.Parent = head

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 10)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 10
	title.TextColor3 = Color3.fromRGB(255, 92, 92)
	title.Text = BossConfig.DISPLAY_NAME
	title.Parent = billboard

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	background.BorderSizePixel = 0
	background.Position = UDim2.fromOffset(0, 12)
	background.Size = UDim2.new(1, 0, 0, 8)
	background.Parent = billboard

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = background

	local function updateHealthBar()
		local ratio = if humanoid.MaxHealth > 0 then math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) else 0
		fill.Size = UDim2.new(ratio, 0, 1, 0)
	end

	humanoid.HealthChanged:Connect(updateHealthBar)
	updateHealthBar()

	model:SetAttribute("IsBoss", true)
	model:SetAttribute("MonsterType", BossConfig.ID)
	model:SetAttribute("MonsterDamage", BossConfig.DAMAGE)
	model:SetAttribute("AttackRange", BossConfig.ATTACK_RANGE)
	model:SetAttribute("AttackCooldown", BossConfig.ATTACK_COOLDOWN)
	model:SetAttribute("DungeonOwner", ownerUserId)
	model:SetAttribute("NeckMotorName", neckMotor.Name)
	model:SetAttribute("TailMotorName", tailMotor.Name)
	model:SetAttribute("FrontLeftLegMotorName", frontLeftLegMotor.Name)
	model:SetAttribute("FrontRightLegMotorName", frontRightLegMotor.Name)
	model:SetAttribute("BackLeftLegMotorName", backLeftLegMotor.Name)
	model:SetAttribute("BackRightLegMotorName", backRightLegMotor.Name)
	model:SetAttribute("NeckRest", neckRest)
	model:SetAttribute("TailRest", tailRest)
	model:SetAttribute("FrontLeftLegRest", frontLeftLegRest)
	model:SetAttribute("FrontRightLegRest", frontRightLegRest)
	model:SetAttribute("BackLeftLegRest", backLeftLegRest)
	model:SetAttribute("BackRightLegRest", backRightLegRest)
	model:SetAttribute("BossScale", scale)
	model:SetAttribute("MonsterScale", scale)

	model.PrimaryPart = humanoidRootPart
	model:PivotTo(rootCFrame)
	model.Parent = monstersFolder

	bossRuntimes[model] = {
		lastAttackTime = 0,
		busy = false,
		state = nil,
	}

	return model
end

return BossService
