local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)
local GamePhaseService = require(script.Parent.GamePhaseService)

local LobbyEnvironmentService = {}

local function createPart(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance, options: {
	material: Enum.Material?,
	anchored: boolean?,
	canCollide: boolean?,
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

function LobbyEnvironmentService.init()
	if not LobbyConfig.USE_LOBBY then
		return
	end

	local folder = workspace:FindFirstChild("Lobby")
	if not folder then
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

	createSign(folder, LobbyConfig.FORGE_POSITION + Vector3.new(0, 0, -8), "Blacksmith", Color3.fromRGB(255, 196, 96))
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
		{ material = Enum.Material.Neon, canCollide = false }
	)

	local portalBase = createPart(
		"DungeonPortal",
		Vector3.new(10, 0.4, 3),
		CFrame.new(LobbyConfig.PORTAL_POSITION),
		Color3.fromRGB(48, 48, 52),
		folder,
		{ material = Enum.Material.Slate }
	)

	local portalGlow = createPart(
		"PortalGlow",
		Vector3.new(8, 8, 0.6),
		CFrame.new(LobbyConfig.PORTAL_POSITION + Vector3.new(0, 4.2, 0)),
		Color3.fromRGB(72, 220, 128),
		folder,
		{ material = Enum.Material.Neon, canCollide = false, transparency = 0.25 }
	)

	local portalRing = createPart(
		"PortalRing",
		Vector3.new(9.5, 0.35, 9.5),
		CFrame.new(LobbyConfig.PORTAL_POSITION + Vector3.new(0, 0.35, 0)),
		Color3.fromRGB(48, 180, 96),
		folder,
		{ material = Enum.Material.Neon, canCollide = false, shape = Enum.PartType.Cylinder }
	)
	portalRing.Orientation = Vector3.new(0, 0, 90)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EnterDungeonPrompt"
	prompt.ActionText = "Enter Dungeon"
	prompt.ObjectText = "Dungeon Gate"
	prompt.HoldDuration = LobbyConfig.PORTAL_HOLD_SECONDS
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = portalGlow

	prompt.Triggered:Connect(function(player)
		GamePhaseService.enterDungeon(player)
	end)

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

	platform:SetAttribute("LobbyBuilt", true)
	forge:SetAttribute("LobbyProp", true)
	portalBase:SetAttribute("LobbyProp", true)
end

return LobbyEnvironmentService
