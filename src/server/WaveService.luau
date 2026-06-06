local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)

local WaveService = {}

local activeMonsters: { Model } = {}
local lastAttackTimes: { [Model]: number } = {}
local monstersFolder: Folder
local aiRunning = false

local MONSTER_COLORS = {
	Color3.fromRGB(85, 170, 85),
	Color3.fromRGB(120, 60, 180),
	Color3.fromRGB(200, 80, 60),
}

local function weld(part0: BasePart, part1: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part0
end

local function createPart(name: string, size: Vector3, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.Anchored = false
	part.Parent = parent
	return part
end

function WaveService.createMonster(spawnPosition: Vector3): Model
	local color = MONSTER_COLORS[math.random(1, #MONSTER_COLORS)]
	local model = Instance.new("Model")
	model.Name = "WaveMonster"

	local humanoidRootPart = createPart("HumanoidRootPart", Vector3.new(2, 2, 1), color, model)
	humanoidRootPart.Transparency = 1
	humanoidRootPart.CanCollide = true

	local torso = createPart("Torso", Vector3.new(2.5, 2.5, 1.5), color, model)
	local head = createPart("Head", Vector3.new(1.8, 1.8, 1.8), color:lerp(Color3.new(1, 1, 1), 0.2), model)
	local leftArm = createPart("LeftArm", Vector3.new(1, 2.5, 1), color, model)
	local rightArm = createPart("RightArm", Vector3.new(1, 2.5, 1), color, model)
	local leftLeg = createPart("LeftLeg", Vector3.new(1, 2.5, 1), color, model)
	local rightLeg = createPart("RightLeg", Vector3.new(1, 2.5, 1), color, model)

	head.Shape = Enum.PartType.Ball

	torso.CFrame = humanoidRootPart.CFrame
	head.CFrame = humanoidRootPart.CFrame * CFrame.new(0, 2.2, 0)
	leftArm.CFrame = humanoidRootPart.CFrame * CFrame.new(-2, 0.2, 0)
	rightArm.CFrame = humanoidRootPart.CFrame * CFrame.new(2, 0.2, 0)
	leftLeg.CFrame = humanoidRootPart.CFrame * CFrame.new(-0.6, -2.5, 0)
	rightLeg.CFrame = humanoidRootPart.CFrame * CFrame.new(0.6, -2.5, 0)

	weld(humanoidRootPart, torso)
	weld(humanoidRootPart, head)
	weld(humanoidRootPart, leftArm)
	weld(humanoidRootPart, rightArm)
	weld(humanoidRootPart, leftLeg)
	weld(humanoidRootPart, rightLeg)

	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = WaveConfig.MONSTER_WALK_SPEED
	humanoid.MaxHealth = WaveConfig.MONSTER_HEALTH
	humanoid.Health = WaveConfig.MONSTER_HEALTH
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model

	model.PrimaryPart = humanoidRootPart
	model:PivotTo(CFrame.new(spawnPosition))
	model.Parent = monstersFolder

	table.insert(activeMonsters, model)
	lastAttackTimes[model] = 0

	humanoid.Died:Connect(function()
		lastAttackTimes[model] = nil
		local index = table.find(activeMonsters, model)
		if index then
			table.remove(activeMonsters, index)
		end
		task.delay(2, function()
			if model.Parent then
				model:Destroy()
			end
		end)
	end)

	return model
end

local function getSpawnPosition(): Vector3
	local angle = math.random() * math.pi * 2
	local radius = math.random(WaveConfig.SPAWN_RADIUS_MIN, WaveConfig.SPAWN_RADIUS_MAX)
	local x = math.cos(angle) * radius
	local z = math.sin(angle) * radius
	return Vector3.new(x, WaveConfig.SPAWN_HEIGHT, z)
end

local function getNearestPlayerCharacter(monster: Model): Model?
	local root = monster.PrimaryPart
	if not root then
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

local function tryAttack(monster: Model, target: Model)
	local now = os.clock()
	local lastAttack = lastAttackTimes[monster] or 0
	if now - lastAttack < WaveConfig.ATTACK_COOLDOWN then
		return
	end

	local monsterRoot = monster.PrimaryPart
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetHumanoid = target:FindFirstChildOfClass("Humanoid")

	if not monsterRoot or not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
		return
	end

	if (monsterRoot.Position - targetRoot.Position).Magnitude > WaveConfig.ATTACK_RANGE then
		return
	end

	lastAttackTimes[monster] = now
	targetHumanoid:TakeDamage(WaveConfig.MONSTER_DAMAGE)
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

	tryAttack(monster, target)

	local monsterRoot = monster.PrimaryPart
	if monsterRoot and (monsterRoot.Position - targetRoot.Position).Magnitude > WaveConfig.ATTACK_RANGE then
		humanoid:MoveTo(targetRoot.Position)
	end
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
					table.remove(activeMonsters, index)
				end
			end
			task.wait(WaveConfig.AI_TICK)
		end
	end)
end

function WaveService.startWave()
	for _ = 1, WaveConfig.MONSTER_COUNT do
		WaveService.createMonster(getSpawnPosition())
	end
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

	startWaveEvent.OnServerEvent:Connect(function(player)
		print(`{player.Name} started a wave!`)
		WaveService.startWave()
	end)

	runAI()
end

return WaveService
