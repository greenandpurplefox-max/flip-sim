local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TreasureConfig = require(ReplicatedStorage.Shared.TreasureConfig)

local TreasureChestService = {}

export type ChestLoot = {
	tierId: string,
	tierName: string,
	gold: number,
}

local chestFolder: Folder
local activeChests: { [Player]: Model } = {}
local openCallbacks: { [Player]: (ChestLoot) -> () } = {}
local chestTokens: { [Player]: number } = {}

local function getChestFolder(): Folder
	if chestFolder and chestFolder.Parent then
		return chestFolder
	end

	local existing = workspace:FindFirstChild("TreasureChests")
	if existing and existing:IsA("Folder") then
		chestFolder = existing
		return chestFolder
	end

	chestFolder = Instance.new("Folder")
	chestFolder.Name = "TreasureChests"
	chestFolder.Parent = workspace
	return chestFolder
end

local function getChestSpawnCFrame(player: Player): CFrame
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return CFrame.new(0, 5, -8)
	end

	local flatLook = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if flatLook.Magnitude < 0.05 then
		flatLook = Vector3.new(0, 0, -1)
	else
		flatLook = flatLook.Unit
	end

	local target = root.Position + flatLook * 7
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }

	local rayResult = workspace:Raycast(target + Vector3.new(0, 24, 0), Vector3.new(0, -48, 0), rayParams)
	local groundY = if rayResult then rayResult.Position.Y else root.Position.Y
	return CFrame.new(target.X, groundY + 1.05, target.Z)
end

local function buildChestModel(tierId: string, ownerUserId: number, spawnCFrame: CFrame): Model
	local tier = TreasureConfig.getTier(tierId)
	local model = Instance.new("Model")
	model.Name = `{tierId}TreasureChest`

	local base = Instance.new("Part")
	base.Name = "ChestBase"
	base.Size = Vector3.new(3.2, 1.6, 2.4)
	base.Color = tier.bodyColor
	base.Material = Enum.Material.Wood
	base.Anchored = true
	base.CanCollide = true
	base.CFrame = spawnCFrame
	base.Parent = model

	local trim = Instance.new("Part")
	trim.Name = "ChestTrim"
	trim.Size = Vector3.new(3.35, 0.28, 2.55)
	trim.Color = tier.trimColor
	trim.Material = Enum.Material.Metal
	trim.Anchored = true
	trim.CanCollide = false
	trim.CFrame = spawnCFrame * CFrame.new(0, 0.72, 0)
	trim.Parent = model

	local lid = Instance.new("Part")
	lid.Name = "ChestLid"
	lid.Size = Vector3.new(3.2, 0.85, 2.4)
	lid.Color = tier.bodyColor
	lid.Material = Enum.Material.Wood
	lid.Anchored = true
	lid.CanCollide = false
	lid.CFrame = spawnCFrame * CFrame.new(0, 1.05, -0.35)
	lid.Parent = model

	local lockPart = Instance.new("Part")
	lockPart.Name = "ChestLock"
	lockPart.Size = Vector3.new(0.55, 0.55, 0.18)
	lockPart.Color = tier.trimColor
	lockPart.Material = Enum.Material.Metal
	lockPart.Anchored = true
	lockPart.CanCollide = false
	lockPart.CFrame = spawnCFrame * CFrame.new(0, 0.15, -1.15)
	lockPart.Parent = model

	local glow = Instance.new("Part")
	glow.Name = "ChestGlow"
	glow.Size = Vector3.new(2.4, 0.12, 1.8)
	glow.Color = tier.glowColor
	glow.Material = Enum.Material.Neon
	glow.Anchored = true
	glow.CanCollide = false
	glow.Transparency = 0.35
	glow.CFrame = spawnCFrame * CFrame.new(0, 1.55, 0)
	glow.Parent = model

	model.PrimaryPart = base
	model:SetAttribute("DungeonOwner", ownerUserId)
	model:SetAttribute("ChestTier", tierId)
	return model
end

local function destroyChest(player: Player)
	local chest = activeChests[player]
	if chest then
		chest:Destroy()
	end
	activeChests[player] = nil
	openCallbacks[player] = nil
end

local function openChest(player: Player)
	local chest = activeChests[player]
	local callback = openCallbacks[player]
	if not chest or not callback then
		return
	end

	local tierId = chest:GetAttribute("ChestTier")
	if typeof(tierId) ~= "string" then
		tierId = "Common"
	end

	local tier = TreasureConfig.getTier(tierId)
	local roomDepth = chest:GetAttribute("RoomDepth")
	if typeof(roomDepth) ~= "number" then
		roomDepth = 1
	end

	local loot: ChestLoot = {
		tierId = tierId,
		tierName = tier.displayName,
		gold = TreasureConfig.rollGold(tierId, roomDepth),
	}

	destroyChest(player)
	callback(loot)
end

function TreasureChestService.destroyChest(player: Player)
	chestTokens[player] = (chestTokens[player] or 0) + 1
	destroyChest(player)
end

function TreasureChestService.spawnChest(
	player: Player,
	tierId: string,
	roomDepth: number,
	onOpened: (ChestLoot) -> ()
)
	TreasureChestService.destroyChest(player)

	local token = (chestTokens[player] or 0) + 1
	chestTokens[player] = token

	local spawnCFrame = getChestSpawnCFrame(player)
	local chest = buildChestModel(tierId, player.UserId, spawnCFrame)
	chest:SetAttribute("RoomDepth", roomDepth)
	chest.Parent = getChestFolder()

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open"
	prompt.ObjectText = TreasureConfig.getTier(tierId).displayName
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0.35
	prompt.Parent = chest.PrimaryPart

	activeChests[player] = chest
	openCallbacks[player] = onOpened

	prompt.Triggered:Connect(function(triggerPlayer)
		if triggerPlayer ~= player then
			return
		end
		if chestTokens[player] ~= token then
			return
		end
		openChest(player)
	end)

	task.delay(TreasureConfig.CHEST_AUTO_OPEN_SECONDS, function()
		if chestTokens[player] ~= token then
			return
		end
		if activeChests[player] == chest then
			openChest(player)
		end
	end)
end

return TreasureChestService
