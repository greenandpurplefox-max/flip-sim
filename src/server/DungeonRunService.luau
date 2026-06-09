local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardService = require(script.Parent.CardService)
local DungeonConfig = require(ReplicatedStorage.Shared.DungeonConfig)
local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)
local TreasureChestService = require(script.Parent.TreasureChestService)
local TreasureConfig = require(ReplicatedStorage.Shared.TreasureConfig)
local WaveService = require(script.Parent.WaveService)

local DungeonRunService = {}

export type RunStatus = "starting" | "fighting" | "card_draft" | "intermission" | "ended"

export type RunState = {
	room: number,
	gold: number,
	status: RunStatus,
	monstersRemaining: number,
	isBossRoom: boolean,
	activeCards: { string },
	runChestCount: number,
}

local CardServiceModule = CardService
local cardDraftPickEvent: RemoteEvent
local dungeonRunStateEvent: RemoteEvent

local playerRuns: { [Player]: RunState } = {}
local pendingDraftOptions: { [Player]: { string } } = {}
local runTokens: { [Player]: number } = {}
local runEndedHandler: ((Player, number) -> ())? = nil

local function getCardDraftPickEvent(): RemoteEvent
	if cardDraftPickEvent then
		return cardDraftPickEvent
	end

	cardDraftPickEvent = ReplicatedStorage:FindFirstChild("CardDraftPick") :: RemoteEvent?
	if not cardDraftPickEvent then
		cardDraftPickEvent = Instance.new("RemoteEvent")
		cardDraftPickEvent.Name = "CardDraftPick"
		cardDraftPickEvent.Parent = ReplicatedStorage
	end

	return cardDraftPickEvent
end

local function getDungeonRunStateEvent(): RemoteEvent
	if dungeonRunStateEvent then
		return dungeonRunStateEvent
	end

	dungeonRunStateEvent = ReplicatedStorage:FindFirstChild("DungeonRunState") :: RemoteEvent?
	if not dungeonRunStateEvent then
		dungeonRunStateEvent = Instance.new("RemoteEvent")
		dungeonRunStateEvent.Name = "DungeonRunState"
		dungeonRunStateEvent.Parent = ReplicatedStorage
	end

	return dungeonRunStateEvent
end

local function getRun(player: Player): RunState?
	return playerRuns[player]
end

local function buildSnapshot(player: Player): RunState?
	local run = getRun(player)
	if not run then
		return nil
	end

	return {
		room = run.room,
		gold = run.gold,
		status = run.status,
		monstersRemaining = run.monstersRemaining,
		isBossRoom = run.isBossRoom,
		activeCards = CardServiceModule.getActiveCardIds(player),
		runChestCount = TreasureChestService.getRunChestCount(player),
	}
end

local function sendRunState(player: Player, draftOptions: { string }?)
	local snapshot = buildSnapshot(player)
	if snapshot then
		getDungeonRunStateEvent():FireClient(player, snapshot, draftOptions)
	end
end

local function bumpToken(player: Player): number
	runTokens[player] = (runTokens[player] or 0) + 1
	return runTokens[player]
end

local function isTokenValid(player: Player, token: number): boolean
	return runTokens[player] == token
end

local function shouldOfferCards(room: number): boolean
	if room < DungeonConfig.FIRST_CARD_ROOM then
		return false
	end
	return room % DungeonConfig.CARD_OFFER_EVERY_N_ROOMS == 0
end

local function beginRoom(player: Player)
	local run = getRun(player)
	if not run or run.status == "ended" then
		return
	end

	run.status = "fighting"
	run.isBossRoom = run.room > 0 and run.room % DungeonConfig.BOSS_EVERY_N_ROOMS == 0

	run.monstersRemaining = WaveService.spawnDungeonMonsters(
		run.room,
		player.UserId,
		run.isBossRoom,
		DungeonConfig.SPAWN_RADIUS_MIN,
		DungeonConfig.SPAWN_RADIUS_MAX
	)

	sendRunState(player)
end

local function proceedAfterRoomClear(player: Player, clearedRoom: number)
	local token = bumpToken(player)
	task.delay(DungeonConfig.ROOM_CLEAR_DELAY, function()
		if not isTokenValid(player, token) then
			return
		end

		local activeRun = getRun(player)
		if not activeRun or activeRun.status ~= "intermission" then
			return
		end

		if shouldOfferCards(clearedRoom) then
			activeRun.status = "card_draft"
			local options = CardServiceModule.rollDraftOptions(player, 3)
			pendingDraftOptions[player] = options
			sendRunState(player, options)

			local draftToken = bumpToken(player)
			task.delay(DungeonConfig.CARD_DRAFT_TIMEOUT, function()
				if not isTokenValid(player, draftToken) then
					return
				end

				local draftRun = getRun(player)
				if draftRun and draftRun.status == "card_draft" and pendingDraftOptions[player] then
					local fallback = pendingDraftOptions[player][1]
					if fallback then
						CardServiceModule.applyCard(player, fallback)
					end
					pendingDraftOptions[player] = nil
					draftRun.room += 1
					beginRoom(player)
				end
			end)
			return
		end

		activeRun.room += 1
		beginRoom(player)
	end)
end

local function continueAfterRoomClear(player: Player)
	local run = getRun(player)
	if not run then
		return
	end

	CardServiceModule.healOnRoomClear(player)

	run.gold += if run.isBossRoom then DungeonConfig.GOLD_PER_BOSS else DungeonConfig.GOLD_PER_ROOM
	local clearedRoom = run.room

	if TreasureConfig.shouldSpawnChest(run.isBossRoom) then
		local tierId = TreasureConfig.rollTier(run.isBossRoom, clearedRoom)
		TreasureChestService.awardRunChest(player, tierId, clearedRoom)
	end

	run.status = "intermission"
	sendRunState(player)
	proceedAfterRoomClear(player, clearedRoom)
end

local function onRoomCleared(player: Player)
	local run = getRun(player)
	if not run or run.status ~= "fighting" then
		return
	end

	run.monstersRemaining = 0
	continueAfterRoomClear(player)
end

local function healPlayerToFull(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = humanoid.MaxHealth
	end
end

local function onMonsterDeath(monster: Model)
	local ownerUserId = monster:GetAttribute("DungeonOwner")
	if typeof(ownerUserId) ~= "number" then
		return
	end

	local player = Players:GetPlayerByUserId(ownerUserId)
	if not player then
		return
	end

	local run = getRun(player)
	if not run or run.status ~= "fighting" then
		return
	end

	if monster:GetAttribute("IsBoss") == true then
		healPlayerToFull(player)
	end

	run.monstersRemaining = math.max(0, run.monstersRemaining - 1)
	sendRunState(player)

	if run.monstersRemaining <= 0 then
		onRoomCleared(player)
	end
end

function DungeonRunService.hasActiveRun(player: Player): boolean
	return playerRuns[player] ~= nil
end

function DungeonRunService.startRun(player: Player)
	WaveService.clearMonstersForOwner(player.UserId)
	bumpToken(player)
	CardServiceModule.resetRun(player)
	pendingDraftOptions[player] = nil
	TreasureChestService.clearRunChests(player)

	playerRuns[player] = {
		room = 1,
		gold = 0,
		status = "starting",
		monstersRemaining = 0,
		isBossRoom = false,
		activeCards = {},
		runChestCount = 0,
	}

	sendRunState(player)

	local token = bumpToken(player)
	task.delay(DungeonConfig.RUN_START_DELAY, function()
		if not isTokenValid(player, token) then
			return
		end

		if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
			CardServiceModule.bindCharacter(player, player.Character)
		end

		beginRoom(player)
	end)
end

function DungeonRunService.endRun(player: Player)
	WaveService.clearMonstersForOwner(player.UserId)
	TreasureChestService.clearRunChests(player)
	playerRuns[player] = nil
	pendingDraftOptions[player] = nil
	bumpToken(player)
	getDungeonRunStateEvent():FireClient(player, nil, nil)
end

function DungeonRunService.setRunEndedHandler(handler: (Player, number) -> ())
	runEndedHandler = handler
end

function DungeonRunService.bankRunChests(player: Player)
	TreasureChestService.transferRunChestsToLobby(player)
end

function DungeonRunService.handlePlayerDeath(player: Player)
	local run = getRun(player)
	local runGold = if run then run.gold else 0

	if LobbyConfig.USE_LOBBY and runEndedHandler then
		runEndedHandler(player, runGold)
		return
	end

	DungeonRunService.endRun(player)
end

function DungeonRunService.init()
	WaveService.setDungeonMode(true)
	WaveService.onMonsterDied(onMonsterDeath)

	getDungeonRunStateEvent()
	getCardDraftPickEvent()

	getCardDraftPickEvent().OnServerEvent:Connect(function(player, cardId: string)
		if typeof(cardId) ~= "string" then
			return
		end

		local run = getRun(player)
		local options = pendingDraftOptions[player]
		if not run or run.status ~= "card_draft" or not options then
			return
		end

		local valid = false
		for _, optionId in options do
			if optionId == cardId then
				valid = true
				break
			end
		end

		if not valid then
			return
		end

		CardServiceModule.applyCard(player, cardId)
		pendingDraftOptions[player] = nil
		bumpToken(player)
		run.room += 1
		beginRoom(player)
	end)

	local function bindPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			if not DungeonConfig.USE_DUNGEON_MODE then
				return
			end

			local humanoid = character:WaitForChild("Humanoid") :: Humanoid
			humanoid.Died:Connect(function()
				DungeonRunService.handlePlayerDeath(player)
			end)
		end)

		if not LobbyConfig.USE_LOBBY and player.Character then
			DungeonRunService.startRun(player)
		end
	end

	for _, player in Players:GetPlayers() do
		bindPlayer(player)
	end

	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(function(player)
		playerRuns[player] = nil
		pendingDraftOptions[player] = nil
		runTokens[player] = nil
	end)
end

return DungeonRunService
