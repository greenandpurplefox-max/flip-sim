local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlacksmithConfig = require(ReplicatedStorage.Shared.BlacksmithConfig)
local BobConfig = require(ReplicatedStorage.Shared.BobConfig)
local InfuserConfig = require(ReplicatedStorage.Shared.InfuserConfig)
local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)

local LobbyEnvironmentService = {}

local function createPart(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance, options: {
	material: Enum.Material?,
	anchored: boolean?,
	canCollide: boolean?,
	canTouch: boolean?,
	canQuery: boolean?,
	shape: Enum.PartType?,
	transparency: number?,
}?): Part
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

local function createSign(parent: Instance, position: Vector3, text: string, color: Color3?)
	local anchor = createPart("SignAnchor", Vector3.new(0.2, 0.2, 0.2), CFrame.new(position), Color3.new(1, 1, 1), parent, {
		transparency = 1,
		canCollide = false,
		canTouch = false,
	})

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(220, 48)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.Antique
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(244, 228, 196)
	label.TextSize = 24
	label.TextStrokeTransparency = 0.4
	label.Parent = billboard
end

local function weld(part0: BasePart, part1: BasePart, c0: CFrame?, c1: CFrame?)
	local weldInstance = Instance.new("Weld")
	weldInstance.Part0 = part0
	weldInstance.Part1 = part1
	weldInstance.C0 = c0 or CFrame.new()
	weldInstance.C1 = c1 or CFrame.new()
	weldInstance.Parent = part0
end

local function createBlacksmith(parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Blacksmith"

	local skin = Color3.fromRGB(204, 168, 132)
	local shirt = Color3.fromRGB(92, 88, 96)
	local pants = Color3.fromRGB(58, 46, 38)
	local apron = Color3.fromRGB(118, 72, 38)
	local leather = Color3.fromRGB(74, 48, 28)
	local metal = Color3.fromRGB(88, 88, 94)
	local metalBright = Color3.fromRGB(148, 148, 156)

	local rootPosition = BlacksmithConfig.POSITION + Vector3.new(0, 3.1, 0)
	local rootCFrame = CFrame.lookAt(
		rootPosition,
		Vector3.new(BlacksmithConfig.LOOK_AT.X, rootPosition.Y, BlacksmithConfig.LOOK_AT.Z)
	)

	local root = createPart("HumanoidRootPart", Vector3.new(2, 2.2, 1), rootCFrame, shirt, model, {
		material = Enum.Material.Fabric,
	})
	model.PrimaryPart = root

	local head = createPart("Head", Vector3.new(1.35, 1.35, 1.35), rootCFrame * CFrame.new(0, 1.75, 0), skin, model, {
		shape = Enum.PartType.Ball,
		canCollide = false,
	})
	weld(root, head, CFrame.new(0, 1.75, 0), CFrame.new())

	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head

	local beard = createPart("Beard", Vector3.new(0.9, 0.55, 0.45), rootCFrame * CFrame.new(0, 1.35, -0.45), leather, model, {
		canCollide = false,
	})
	weld(head, beard, CFrame.new(0, -0.25, -0.45), CFrame.new())

	local leftArm = createPart("LeftArm", Vector3.new(1, 2.2, 1), rootCFrame * CFrame.new(-1.55, 0.1, 0), shirt, model, {
		material = Enum.Material.Fabric,
		canCollide = false,
	})
	weld(root, leftArm, CFrame.new(-1.55, 0.1, 0), CFrame.new())

	local rightArm = createPart("RightArm", Vector3.new(1, 2.2, 1), rootCFrame * CFrame.new(1.55, 0.35, -0.15), shirt, model, {
		material = Enum.Material.Fabric,
		canCollide = false,
	})
	weld(root, rightArm, CFrame.new(1.55, 0.35, -0.15), CFrame.new())

	local leftLeg = createPart("LeftLeg", Vector3.new(1, 2, 1), rootCFrame * CFrame.new(-0.55, -2.1, 0), pants, model, {
		canCollide = false,
	})
	weld(root, leftLeg, CFrame.new(-0.55, -2.1, 0), CFrame.new())

	local rightLeg = createPart("RightLeg", Vector3.new(1, 2, 1), rootCFrame * CFrame.new(0.55, -2.1, 0), pants, model, {
		canCollide = false,
	})
	weld(root, rightLeg, CFrame.new(0.55, -2.1, 0), CFrame.new())

	local apronPart = createPart("Apron", Vector3.new(1.7, 2.2, 0.18), rootCFrame * CFrame.new(0, -0.1, -0.55), apron, model, {
		material = Enum.Material.Fabric,
		canCollide = false,
	})
	weld(root, apronPart, CFrame.new(0, -0.1, -0.55), CFrame.new())

	local hammerHandle = createPart("HammerHandle", Vector3.new(0.28, 1.2, 0.28), rootCFrame * CFrame.new(1.95, 0.55, -0.55), leather, model, {
		canCollide = false,
	})
	weld(rightArm, hammerHandle, CFrame.new(0.45, 0.15, -0.35) * CFrame.Angles(math.rad(28), 0, math.rad(18)), CFrame.new())

	local hammerHead = createPart("HammerHead", Vector3.new(0.85, 0.55, 0.55), rootCFrame * CFrame.new(2.15, 1.05, -0.75), metal, model, {
		material = Enum.Material.Metal,
		canCollide = false,
	})
	weld(hammerHandle, hammerHead, CFrame.new(0, 0.65, 0), CFrame.new())

	local beltBuckle = createPart("BeltBuckle", Vector3.new(0.45, 0.45, 0.12), rootCFrame * CFrame.new(0, -0.55, -0.52), metalBright, model, {
		material = Enum.Material.Metal,
		canCollide = false,
	})
	weld(root, beltBuckle, CFrame.new(0, -0.55, -0.52), CFrame.new())

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Upgrade"
	prompt.ObjectText = BlacksmithConfig.PROMPT_OBJECT_TEXT
	prompt.MaxActivationDistance = BlacksmithConfig.PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = root

	model:SetAttribute("BlacksmithNpc", true)
	model.Parent = parent
end

local function createBob(parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Bob"

	local skin = Color3.fromRGB(204, 168, 132)
	local shirt = Color3.fromRGB(72, 108, 148)
	local pants = Color3.fromRGB(52, 58, 68)
	local shoes = Color3.fromRGB(42, 38, 36)

	local rootPosition = BobConfig.POSITION + Vector3.new(0, 3.1, 0)
	local rootCFrame = CFrame.lookAt(
		rootPosition,
		Vector3.new(BobConfig.LOOK_AT.X, rootPosition.Y, BobConfig.LOOK_AT.Z)
	)

	local root = createPart("HumanoidRootPart", Vector3.new(2, 2.2, 1), rootCFrame, shirt, model, {
		material = Enum.Material.Fabric,
	})
	model.PrimaryPart = root

	local head = createPart("Head", Vector3.new(1.35, 1.35, 1.35), rootCFrame * CFrame.new(0, 1.75, 0), skin, model, {
		shape = Enum.PartType.Ball,
		canCollide = false,
	})
	weld(root, head, CFrame.new(0, 1.75, 0), CFrame.new())

	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head

	local hair = createPart("Hair", Vector3.new(1.45, 0.55, 1.45), rootCFrame * CFrame.new(0, 2.15, 0), Color3.fromRGB(92, 64, 42), model, {
		canCollide = false,
	})
	weld(head, hair, CFrame.new(0, 0.45, 0), CFrame.new())

	local leftArm = createPart("LeftArm", Vector3.new(1, 2.2, 1), rootCFrame * CFrame.new(-1.55, 0.1, 0), shirt, model, {
		material = Enum.Material.Fabric,
		canCollide = false,
	})
	weld(root, leftArm, CFrame.new(-1.55, 0.1, 0), CFrame.new())

	local rightArm = createPart("RightArm", Vector3.new(1, 2.2, 1), rootCFrame * CFrame.new(1.55, 0.1, 0), shirt, model, {
		material = Enum.Material.Fabric,
		canCollide = false,
	})
	weld(root, rightArm, CFrame.new(1.55, 0.1, 0), CFrame.new())

	local leftLeg = createPart("LeftLeg", Vector3.new(1, 2, 1), rootCFrame * CFrame.new(-0.55, -2.1, 0), pants, model, {
		canCollide = false,
	})
	weld(root, leftLeg, CFrame.new(-0.55, -2.1, 0), CFrame.new())

	local rightLeg = createPart("RightLeg", Vector3.new(1, 2, 1), rootCFrame * CFrame.new(0.55, -2.1, 0), pants, model, {
		canCollide = false,
	})
	weld(root, rightLeg, CFrame.new(0.55, -2.1, 0), CFrame.new())

	local leftShoe = createPart("LeftShoe", Vector3.new(1.05, 0.35, 1.2), rootCFrame * CFrame.new(-0.55, -3.05, 0.08), shoes, model, {
		canCollide = false,
	})
	weld(leftLeg, leftShoe, CFrame.new(0, -1.05, 0.08), CFrame.new())

	local rightShoe = createPart("RightShoe", Vector3.new(1.05, 0.35, 1.2), rootCFrame * CFrame.new(0.55, -3.05, 0.08), shoes, model, {
		canCollide = false,
	})
	weld(rightLeg, rightShoe, CFrame.new(0, -1.05, 0.08), CFrame.new())

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = BobConfig.PROMPT_ACTION_TEXT
	prompt.ObjectText = BobConfig.PROMPT_OBJECT_TEXT
	prompt.MaxActivationDistance = BobConfig.PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = root

	model:SetAttribute("GuideNpc", true)
	model.Parent = parent
end

local function createInfuser(parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Infuser"

	local skin = Color3.fromRGB(204, 168, 132)
	local robe = Color3.fromRGB(88, 52, 132)
	local trim = Color3.fromRGB(120, 72, 180)
	local book = Color3.fromRGB(72, 48, 108)

	local rootPosition = InfuserConfig.POSITION + Vector3.new(0, 3.1, 0)
	local rootCFrame = CFrame.lookAt(
		rootPosition,
		Vector3.new(InfuserConfig.LOOK_AT.X, rootPosition.Y, InfuserConfig.LOOK_AT.Z)
	)

	local root = createPart("HumanoidRootPart", Vector3.new(2, 2.2, 1), rootCFrame, robe, model, {
		material = Enum.Material.Fabric,
	})
	model.PrimaryPart = root

	local head = createPart("Head", Vector3.new(1.35, 1.35, 1.35), rootCFrame * CFrame.new(0, 1.75, 0), skin, model, {
		shape = Enum.PartType.Ball,
		canCollide = false,
	})
	weld(root, head, CFrame.new(0, 1.75, 0), CFrame.new())

	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head

	local hood = createPart("Hood", Vector3.new(1.55, 0.75, 1.55), rootCFrame * CFrame.new(0, 2.05, 0), trim, model, {
		canCollide = false,
	})
	weld(head, hood, CFrame.new(0, 0.35, 0), CFrame.new())

	local leftArm = createPart("LeftArm", Vector3.new(1, 2.2, 1), rootCFrame * CFrame.new(-1.55, 0.1, 0), robe, model, {
		material = Enum.Material.Fabric,
		canCollide = false,
	})
	weld(root, leftArm, CFrame.new(-1.55, 0.1, 0), CFrame.new())

	local rightArm = createPart("RightArm", Vector3.new(1, 2.2, 1), rootCFrame * CFrame.new(1.55, 0.1, 0), robe, model, {
		material = Enum.Material.Fabric,
		canCollide = false,
	})
	weld(root, rightArm, CFrame.new(1.55, 0.1, 0), CFrame.new())

	local grimoire = createPart("Grimoire", Vector3.new(0.9, 1.2, 0.18), rootCFrame * CFrame.new(1.1, 0.2, -0.55), book, model, {
		material = Enum.Material.SmoothPlastic,
		canCollide = false,
	})
	weld(rightArm, grimoire, CFrame.new(0, -0.35, -0.55), CFrame.new())

	local leftLeg = createPart("LeftLeg", Vector3.new(1, 2, 1), rootCFrame * CFrame.new(-0.55, -2.1, 0), trim, model, {
		canCollide = false,
	})
	weld(root, leftLeg, CFrame.new(-0.55, -2.1, 0), CFrame.new())

	local rightLeg = createPart("RightLeg", Vector3.new(1, 2, 1), rootCFrame * CFrame.new(0.55, -2.1, 0), trim, model, {
		canCollide = false,
	})
	weld(root, rightLeg, CFrame.new(0.55, -2.1, 0), CFrame.new())

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = InfuserConfig.PROMPT_ACTION_TEXT
	prompt.ObjectText = InfuserConfig.PROMPT_OBJECT_TEXT
	prompt.MaxActivationDistance = InfuserConfig.PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = root

	model:SetAttribute("InfuserNpc", true)
	model.Parent = parent
end

function LobbyEnvironmentService.init()
	if not LobbyConfig.USE_LOBBY then
		return
	end

	local folder = workspace:FindFirstChild("Lobby")
	if folder then
		folder:ClearAllChildren()
	else
		folder = Instance.new("Folder")
		folder.Name = "Lobby"
		folder.Parent = workspace
	end

	local center = LobbyConfig.LOBBY_CENTER
	local platform = createPart(
		"LobbyPlatform",
		LobbyConfig.LOBBY_PLATFORM_SIZE,
		CFrame.new(center),
		Color3.fromRGB(88, 84, 78),
		folder,
		{ material = Enum.Material.Cobblestone }
	)

	createPart(
		"LobbyTrim",
		Vector3.new(LobbyConfig.LOBBY_PLATFORM_SIZE.X + 4, 0.5, LobbyConfig.LOBBY_PLATFORM_SIZE.Z + 4),
		CFrame.new(center.X, center.Y - 1.1, center.Z),
		Color3.fromRGB(58, 54, 50),
		folder,
		{ material = Enum.Material.Slate }
	)

	createSign(folder, BlacksmithConfig.POSITION + Vector3.new(0, 6.5, 0), "Blacksmith", Color3.fromRGB(255, 196, 96))
	createSign(folder, BobConfig.POSITION + Vector3.new(0, 6.5, 0), "Bob", Color3.fromRGB(144, 196, 255))
	createSign(folder, InfuserConfig.POSITION + Vector3.new(0, 6.5, 0), "Infuser", Color3.fromRGB(180, 120, 255))
	createSign(folder, LobbyConfig.PORTAL_POSITION + Vector3.new(0, 0, 8), "Dungeon Gate", Color3.fromRGB(120, 255, 160))

	local forge = createPart(
		"ForgeAnvil",
		Vector3.new(4, 1.2, 2.4),
		CFrame.new(LobbyConfig.FORGE_POSITION),
		Color3.fromRGB(72, 72, 78),
		folder,
		{ material = Enum.Material.Metal }
	)
	createPart(
		"ForgeFire",
		Vector3.new(2.4, 1.4, 2.4),
		CFrame.new(LobbyConfig.FORGE_POSITION + Vector3.new(0, 1.1, -2.2)),
		Color3.fromRGB(255, 118, 48),
		folder,
		{ material = Enum.Material.Neon, canCollide = false, canTouch = false }
	)

	createBlacksmith(folder)
	createBob(folder)
	createInfuser(folder)

	local portalBase = createPart(
		"DungeonPortal",
		Vector3.new(12, 0.4, 12),
		CFrame.new(LobbyConfig.PORTAL_POSITION),
		Color3.fromRGB(48, 48, 52),
		folder,
		{ material = Enum.Material.Slate, canCollide = false, canTouch = false }
	)

	local portalTrigger = createPart(
		"PortalTrigger",
		Vector3.new(14, 8, 14),
		CFrame.new(LobbyConfig.PORTAL_POSITION + Vector3.new(0, 1, 0)),
		Color3.fromRGB(72, 220, 128),
		folder,
		{
			material = Enum.Material.Neon,
			canCollide = false,
			canTouch = true,
			canQuery = true,
			transparency = 0.88,
		}
	)

	local portalRing = createPart(
		"PortalRing",
		Vector3.new(0.35, 11, 11),
		CFrame.new(LobbyConfig.PORTAL_POSITION + Vector3.new(0, 0.35, 0)),
		Color3.fromRGB(48, 180, 96),
		folder,
		{ material = Enum.Material.Neon, canCollide = false, canTouch = false, shape = Enum.PartType.Cylinder }
	)
	portalRing.Orientation = Vector3.new(0, 0, 90)

	local portalGlow = createPart(
		"PortalGlow",
		Vector3.new(8, 8, 1),
		CFrame.new(LobbyConfig.PORTAL_POSITION + Vector3.new(0, 4.5, 0)),
		Color3.fromRGB(72, 220, 128),
		folder,
		{ material = Enum.Material.Neon, canCollide = false, canTouch = false, transparency = 0.35 }
	)

	portalTrigger:SetAttribute("PortalTrigger", true)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.new(LobbyConfig.LOBBY_SPAWN)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Neutral = true
	spawn.Parent = folder

	for _, offset in { Vector3.new(-36, 1.5, -36), Vector3.new(36, 1.5, -36), Vector3.new(-36, 1.5, 36), Vector3.new(36, 1.5, 36) } do
		createPart(
			"LobbyPillar",
			Vector3.new(2.4, 8, 2.4),
			CFrame.new(center + offset),
			Color3.fromRGB(72, 68, 64),
			folder,
			{ material = Enum.Material.Brick }
		)
	end

	folder:SetAttribute("LobbyBuilt", true)
	platform:SetAttribute("LobbyBuilt", true)
	forge:SetAttribute("LobbyProp", true)
	portalBase:SetAttribute("LobbyProp", true)
end

return LobbyEnvironmentService
