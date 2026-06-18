local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)
local TrainingZoneConfig = require(ReplicatedStorage.Shared.TrainingZoneConfig)

local GamePhaseService = require(script.Parent.GamePhaseService)

local TrainingZoneService = {}

local trainingZoneStateEvent: RemoteEvent
local trainingDummyDamageEvent: RemoteEvent
local playerInTrainingZone: { [Player]: boolean } = {}

local function getTrainingZoneStateEvent(): RemoteEvent
	if trainingZoneStateEvent then
		return trainingZoneStateEvent
	end

	trainingZoneStateEvent = ReplicatedStorage:FindFirstChild("TrainingZoneState") :: RemoteEvent?
	if not trainingZoneStateEvent then
		trainingZoneStateEvent = Instance.new("RemoteEvent")
		trainingZoneStateEvent.Name = "TrainingZoneState"
		trainingZoneStateEvent.Parent = ReplicatedStorage
	end

	return trainingZoneStateEvent
end

local function getTrainingDummyDamageEvent(): RemoteEvent
	if trainingDummyDamageEvent then
		return trainingDummyDamageEvent
	end

	trainingDummyDamageEvent = ReplicatedStorage:FindFirstChild("TrainingDummyDamage") :: RemoteEvent?
	if not trainingDummyDamageEvent then
		trainingDummyDamageEvent = Instance.new("RemoteEvent")
		trainingDummyDamageEvent.Name = "TrainingDummyDamage"
		trainingDummyDamageEvent.Parent = ReplicatedStorage
	end

	return trainingDummyDamageEvent
end

function TrainingZoneService.getTrainingDummyDamageEvent(): RemoteEvent
	return getTrainingDummyDamageEvent()
end

function TrainingZoneService.isInTrainingZone(player: Player): boolean
	return playerInTrainingZone[player] == true
end

function TrainingZoneService.isTrainingDummy(monster: Model): boolean
	return monster:GetAttribute("TrainingDummy") == true
end

function TrainingZoneService.notifyDummyDamage(player: Player, damage: number, worldPosition: Vector3)
	if damage <= 0 or not player.Parent then
		return
	end

	getTrainingDummyDamageEvent():FireClient(player, damage, worldPosition)
end

function TrainingZoneService.getDummyDamagePosition(monster: Model): Vector3
	local root = monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		return root.Position + Vector3.new(0, 2.2, 0)
	end
	return monster:GetPivot().Position + Vector3.new(0, 2.2, 0)
end

local function isPositionInTrainingZone(position: Vector3): boolean
	local center = TrainingZoneConfig.ZONE_CENTER
	local half = TrainingZoneConfig.ZONE_HALF_SIZE
	local delta = position - center
	return math.abs(delta.X) <= half.X
		and math.abs(delta.Y) <= half.Y
		and math.abs(delta.Z) <= half.Z
end

local function setPlayerTrainingZone(player: Player, inZone: boolean)
	if playerInTrainingZone[player] == inZone then
		return
	end

	playerInTrainingZone[player] = inZone
	player:SetAttribute("InTrainingZone", inZone)
	getTrainingZoneStateEvent():FireClient(player, inZone)
end

local function createPart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	parent: Instance,
	options: {
		material: Enum.Material?,
		anchored: boolean?,
		canCollide: boolean?,
		canTouch: boolean?,
		canQuery: boolean?,
		shape: Enum.PartType?,
		transparency: number?,
	}?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = if options and options.material then options.material else Enum.Material.SmoothPlastic
	part.Anchored = if options and options.anchored ~= nil then options.anchored else true
	part.CanCollide = if options and options.canCollide ~= nil then options.canCollide else true
	part.CanTouch = if options and options.canTouch ~= nil then options.canTouch else true
	part.CanQuery = if options and options.canQuery ~= nil then options.canQuery else true
	part.Transparency = if options and options.transparency then options.transparency else 0
	if options and options.shape then
		part.Shape = options.shape
	end
	part.Parent = parent
	return part
end

local function weld(part0: BasePart, part1: BasePart, c0: CFrame?, c1: CFrame?)
	local weldInstance = Instance.new("Weld")
	weldInstance.Part0 = part0
	weldInstance.Part1 = part1
	weldInstance.C0 = c0 or CFrame.new()
	weldInstance.C1 = c1 or CFrame.new()
	weldInstance.Parent = part0
end

local function createTrainingDummy(position: Vector3, lookAt: Vector3, parent: Folder): Model
	local model = Instance.new("Model")
	model.Name = "WaveMonster"
	model:SetAttribute("TrainingDummy", true)

	local wood = Color3.fromRGB(92, 62, 38)
	local straw = Color3.fromRGB(196, 168, 88)
	local post = Color3.fromRGB(72, 52, 34)

	local rootCFrame = CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z))
	local root = createPart("HumanoidRootPart", Vector3.new(2, 2, 1), rootCFrame, wood, model, {
		anchored = true,
		canCollide = false,
	})
	model.PrimaryPart = root

	local base = createPart("Base", Vector3.new(3.2, 0.5, 3.2), rootCFrame * CFrame.new(0, -1.15, 0), post, model, {
		material = Enum.Material.Wood,
	})
	weld(root, base, CFrame.new(0, -1.15, 0), CFrame.new())

	local torso = createPart("Torso", Vector3.new(2.8, 3.6, 1.6), rootCFrame * CFrame.new(0, 0.4, 0), straw, model, {
		material = Enum.Material.Grass,
	})
	weld(root, torso, CFrame.new(0, 0.4, 0), CFrame.new())

	local head = createPart("Head", Vector3.new(1.8, 1.8, 1.8), rootCFrame * CFrame.new(0, 2.5, 0), straw, model, {
		shape = Enum.PartType.Ball,
		material = Enum.Material.Grass,
	})
	weld(root, head, CFrame.new(0, 2.5, 0), CFrame.new())

	local leftArm = createPart("LeftArm", Vector3.new(0.8, 2.4, 0.8), rootCFrame * CFrame.new(-1.7, 0.5, 0), straw, model, {
		material = Enum.Material.Grass,
	})
	weld(root, leftArm, CFrame.new(-1.7, 0.5, 0), CFrame.new())

	local rightArm = createPart("RightArm", Vector3.new(0.8, 2.4, 0.8), rootCFrame * CFrame.new(1.7, 0.5, 0), straw, model, {
		material = Enum.Material.Grass,
	})
	weld(root, rightArm, CFrame.new(1.7, 0.5, 0), CFrame.new())

	local postPart = createPart("Post", Vector3.new(0.7, 4.2, 0.7), rootCFrame * CFrame.new(0, -0.2, 0.9), post, model, {
		material = Enum.Material.Wood,
	})
	weld(root, postPart, CFrame.new(0, -0.2, 0.9), CFrame.new())

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = TrainingZoneConfig.DUMMY_HEALTH
	humanoid.Health = TrainingZoneConfig.DUMMY_HEALTH
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false
	humanoid.PlatformStand = true
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false
	humanoid.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DummyLabel"
	billboard.Size = UDim2.fromOffset(120, 28)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.Antique
	label.Text = "Training Dummy"
	label.TextColor3 = Color3.fromRGB(244, 228, 196)
	label.TextSize = 18
	label.TextStrokeTransparency = 0.35
	label.Parent = billboard

	humanoid.Died:Connect(function()
		task.delay(0.2, function()
			if humanoid.Parent then
				humanoid.Health = humanoid.MaxHealth
			end
		end)
	end)

	model.Parent = parent
	return model
end

local function buildTrainingArea(lobbyFolder: Folder)
	local center = TrainingZoneConfig.ZONE_CENTER

	local platform = createPart(
		"TrainingPlatform",
		TrainingZoneConfig.PLATFORM_SIZE,
		CFrame.new(center),
		TrainingZoneConfig.PLATFORM_COLOR,
		lobbyFolder,
		{ material = Enum.Material.WoodPlanks }
	)
	platform:SetAttribute("TrainingZone", true)

	createPart(
		"TrainingTrim",
		Vector3.new(TrainingZoneConfig.PLATFORM_SIZE.X + 3, 0.45, TrainingZoneConfig.PLATFORM_SIZE.Z + 3),
		CFrame.new(center.X, center.Y - 1.05, center.Z),
		Color3.fromRGB(58, 46, 34),
		lobbyFolder,
		{ material = Enum.Material.Slate }
	)

	local bridge = createPart(
		"TrainingBridge",
		Vector3.new(10, 1, 8),
		CFrame.new(44, center.Y, center.Z),
		TrainingZoneConfig.PLATFORM_COLOR,
		lobbyFolder,
		{ material = Enum.Material.Cobblestone }
	)
	bridge:SetAttribute("TrainingZone", true)

	local signAnchor = createPart(
		"TrainingSignAnchor",
		Vector3.new(0.2, 0.2, 0.2),
		CFrame.new(center + Vector3.new(0, 3, TrainingZoneConfig.PLATFORM_SIZE.Z * 0.5 - 1)),
		Color3.new(1, 1, 1),
		lobbyFolder,
		{ transparency = 1, canCollide = false, canTouch = false }
	)

	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(260, 48)
	sign.StudsOffset = Vector3.new(0, 2, 0)
	sign.AlwaysOnTop = false
	sign.Parent = signAnchor

	local signLabel = Instance.new("TextLabel")
	signLabel.BackgroundTransparency = 1
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.Font = Enum.Font.Antique
	signLabel.Text = "Training Grounds"
	signLabel.TextColor3 = Color3.fromRGB(255, 196, 96)
	signLabel.TextSize = 28
	signLabel.TextStrokeTransparency = 0.35
	signLabel.Parent = sign

	local monstersFolder = workspace:FindFirstChild("WaveMonsters") :: Folder?
	if not monstersFolder then
		monstersFolder = Instance.new("Folder")
		monstersFolder.Name = "WaveMonsters"
		monstersFolder.Parent = workspace
	end

	for _, position in TrainingZoneConfig.DUMMY_POSITIONS do
		createTrainingDummy(position, TrainingZoneConfig.DUMMY_LOOK_AT, monstersFolder)
	end
end

local function runTrainingZoneLoop()
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				if not player.Parent then
					continue
				end

				if not GamePhaseService.isInLobby(player) then
					setPlayerTrainingZone(player, false)
					continue
				end

				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if not root or not humanoid or humanoid.Health <= 0 then
					setPlayerTrainingZone(player, false)
					continue
				end

				setPlayerTrainingZone(player, isPositionInTrainingZone(root.Position))
			end
			task.wait(0.12)
		end
	end)
end

function TrainingZoneService.init()
	if not LobbyConfig.USE_LOBBY then
		return
	end

	getTrainingZoneStateEvent()
	getTrainingDummyDamageEvent()

	for _, player in Players:GetPlayers() do
		player:SetAttribute("InTrainingZone", false)
	end

	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("InTrainingZone", false)
	end)

	local lobbyFolder = workspace:FindFirstChild("Lobby")
	if lobbyFolder then
		buildTrainingArea(lobbyFolder)
	end

	runTrainingZoneLoop()

	Players.PlayerRemoving:Connect(function(player)
		playerInTrainingZone[player] = nil
	end)
end

return TrainingZoneService
