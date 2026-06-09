local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local TreasureConfig = require(ReplicatedStorage.Shared.TreasureConfig)

local GamePhaseService = require(script.Parent.GamePhaseService)
local PlayerDataService = require(script.Parent.PlayerDataService)

local TreasureChestService = {}

export type PendingChest = {
	tierId: string,
	roomDepth: number,
}

export type ChestLoot = {
	tierId: string,
	tierName: string,
	gold: number,
	remainingChests: number,
}

local runChests: { [Player]: { PendingChest } } = {}

local treasureChestAwardedEvent: RemoteEvent
local treasureChestStateEvent: RemoteEvent
local treasureChestOpenedEvent: RemoteEvent
local openTreasureChestEvent: RemoteEvent

local function getTreasureChestAwardedEvent(): RemoteEvent
	if treasureChestAwardedEvent then
		return treasureChestAwardedEvent
	end

	treasureChestAwardedEvent = ReplicatedStorage:FindFirstChild("TreasureChestAwarded") :: RemoteEvent?
	if not treasureChestAwardedEvent then
		treasureChestAwardedEvent = Instance.new("RemoteEvent")
		treasureChestAwardedEvent.Name = "TreasureChestAwarded"
		treasureChestAwardedEvent.Parent = ReplicatedStorage
	end

	return treasureChestAwardedEvent
end

local function getTreasureChestStateEvent(): RemoteEvent
	if treasureChestStateEvent then
		return treasureChestStateEvent
	end

	treasureChestStateEvent = ReplicatedStorage:FindFirstChild("TreasureChestState") :: RemoteEvent?
	if not treasureChestStateEvent then
		treasureChestStateEvent = Instance.new("RemoteEvent")
		treasureChestStateEvent.Name = "TreasureChestState"
		treasureChestStateEvent.Parent = ReplicatedStorage
	end

	return treasureChestStateEvent
end

local function getTreasureChestOpenedEvent(): RemoteEvent
	if treasureChestOpenedEvent then
		return treasureChestOpenedEvent
	end

	treasureChestOpenedEvent = ReplicatedStorage:FindFirstChild("TreasureChestOpened") :: RemoteEvent?
	if not treasureChestOpenedEvent then
		treasureChestOpenedEvent = Instance.new("RemoteEvent")
		treasureChestOpenedEvent.Name = "TreasureChestOpened"
		treasureChestOpenedEvent.Parent = ReplicatedStorage
	end

	return treasureChestOpenedEvent
end

local function getOpenTreasureChestEvent(): RemoteEvent
	if openTreasureChestEvent then
		return openTreasureChestEvent
	end

	openTreasureChestEvent = ReplicatedStorage:FindFirstChild("OpenTreasureChest") :: RemoteEvent?
	if not openTreasureChestEvent then
		openTreasureChestEvent = Instance.new("RemoteEvent")
		openTreasureChestEvent.Name = "OpenTreasureChest"
		openTreasureChestEvent.Parent = ReplicatedStorage
	end

	return openTreasureChestEvent
end

local function serializeChests(chests: { PendingChest }?)
	local payload: { { tierId: string, roomDepth: number, tierName: string } } = {}
	if not chests then
		return payload
	end

	for _, chest in chests do
		table.insert(payload, {
			tierId = chest.tierId,
			roomDepth = chest.roomDepth,
			tierName = TreasureConfig.getTier(chest.tierId).displayName,
		})
	end

	return payload
end

local function syncLobbyChests(player: Player)
	getTreasureChestStateEvent():FireClient(player, serializeChests(PlayerDataService.getLobbyChests(player)))
end

function TreasureChestService.getRunChestCount(player: Player): number
	local chests = runChests[player]
	return if chests then #chests else 0
end

function TreasureChestService.clearRunChests(player: Player)
	runChests[player] = nil
end

function TreasureChestService.awardRunChest(player: Player, tierId: string, roomDepth: number)
	if not runChests[player] then
		runChests[player] = {}
	end

	table.insert(runChests[player], {
		tierId = tierId,
		roomDepth = roomDepth,
	})

	local tier = TreasureConfig.getTier(tierId)
	getTreasureChestAwardedEvent():FireClient(player, {
		tierId = tierId,
		tierName = tier.displayName,
		roomDepth = roomDepth,
		runChestCount = #runChests[player],
	})
end

function TreasureChestService.transferRunChestsToLobby(player: Player)
	local earned = runChests[player]
	runChests[player] = nil

	if not earned or #earned == 0 then
		return
	end

	local chests = PlayerDataService.getLobbyChests(player)
	for _, chest in earned do
		table.insert(chests, chest)
	end
	PlayerDataService.setLobbyChests(player, chests)
	syncLobbyChests(player)
end

function TreasureChestService.openLobbyChest(player: Player, chestIndex: number): boolean
	if not GamePhaseService.isInLobby(player) then
		return false
	end

	local chests = PlayerDataService.getLobbyChests(player)
	if chestIndex < 1 or chestIndex > #chests then
		return false
	end

	local chest = table.remove(chests, chestIndex)
	if not chest then
		return false
	end

	PlayerDataService.setLobbyChests(player, chests)

	local tier = TreasureConfig.getTier(chest.tierId)
	local gold = TreasureConfig.rollGold(chest.tierId, chest.roomDepth)
	PlayerDataService.addGold(player, gold)

	local loot: ChestLoot = {
		tierId = chest.tierId,
		tierName = tier.displayName,
		gold = gold,
		remainingChests = if chests then #chests else 0,
	}

	syncLobbyChests(player)
	getTreasureChestOpenedEvent():FireClient(player, loot)
	return true
end

function TreasureChestService.init()
	getTreasureChestAwardedEvent()
	getTreasureChestStateEvent()
	getTreasureChestOpenedEvent()
	getOpenTreasureChestEvent()

	getOpenTreasureChestEvent().OnServerEvent:Connect(function(player, chestIndex: number)
		if typeof(chestIndex) ~= "number" then
			return
		end

		TreasureChestService.openLobbyChest(player, math.floor(chestIndex))
	end)

	local function bindPlayer(player: Player)
		task.defer(function()
			syncLobbyChests(player)
		end)
	end

	for _, player in Players:GetPlayers() do
		bindPlayer(player)
	end

	Players.PlayerAdded:Connect(bindPlayer)

	Players.PlayerRemoving:Connect(function(player)
		runChests[player] = nil
	end)
end

return TreasureChestService
