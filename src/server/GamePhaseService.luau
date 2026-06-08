local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)

local GamePhaseService = {}

export type Phase = "Lobby" | "Dungeon"

local playerPhases: { [Player]: Phase } = {}
local phaseStateEvent: RemoteEvent
local enterDungeonEvent: RemoteEvent

local DungeonRunServiceModule = nil
local PlayerDataServiceModule = nil
local WeaponServiceModule = nil

local function getPhaseStateEvent(): RemoteEvent
	if phaseStateEvent then
		return phaseStateEvent
	end

	phaseStateEvent = ReplicatedStorage:FindFirstChild("PlayerPhaseState") :: RemoteEvent?
	if not phaseStateEvent then
		phaseStateEvent = Instance.new("RemoteEvent")
		phaseStateEvent.Name = "PlayerPhaseState"
		phaseStateEvent.Parent = ReplicatedStorage
	end

	return phaseStateEvent
end

local function getEnterDungeonEvent(): RemoteEvent
	if enterDungeonEvent then
		return enterDungeonEvent
	end

	enterDungeonEvent = ReplicatedStorage:FindFirstChild("EnterDungeon") :: RemoteEvent?
	if not enterDungeonEvent then
		enterDungeonEvent = Instance.new("RemoteEvent")
		enterDungeonEvent.Name = "EnterDungeon"
		enterDungeonEvent.Parent = ReplicatedStorage
	end

	return enterDungeonEvent
end

function GamePhaseService.getPhase(player: Player): Phase
	if not LobbyConfig.USE_LOBBY then
		return "Dungeon"
	end
	return playerPhases[player] or "Lobby"
end

function GamePhaseService.isInLobby(player: Player): boolean
	return GamePhaseService.getPhase(player) == "Lobby"
end

function GamePhaseService.isInDungeon(player: Player): boolean
	return GamePhaseService.getPhase(player) == "Dungeon"
end

function GamePhaseService.isLoadoutLocked(player: Player): boolean
	return GamePhaseService.isInDungeon(player)
end

local function sendPhase(player: Player)
	getPhaseStateEvent():FireClient(player, GamePhaseService.getPhase(player))
end

local function teleportCharacter(player: Player, position: Vector3)
	local character = player.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.CFrame = CFrame.new(position)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
end

function GamePhaseService.teleportToLobby(player: Player)
	teleportCharacter(player, LobbyConfig.LOBBY_SPAWN)
end

function GamePhaseService.teleportToDungeon(player: Player)
	teleportCharacter(player, LobbyConfig.DUNGEON_SPAWN)
end

function GamePhaseService.returnToLobby(player: Player, runGold: number?)
	if not player.Parent then
		return
	end

	playerPhases[player] = "Lobby"
	player:SetAttribute("GamePhase", "Lobby")

	if runGold and runGold > 0 and PlayerDataServiceModule then
		PlayerDataServiceModule.addGold(player, runGold)
	end

	if DungeonRunServiceModule then
		DungeonRunServiceModule.endRun(player)
	end

	GamePhaseService.teleportToLobby(player)
	sendPhase(player)

	if WeaponServiceModule then
		WeaponServiceModule.refreshPlayerLoadout(player)
	end
end

function GamePhaseService.enterDungeon(player: Player): boolean
	if not LobbyConfig.USE_LOBBY then
		return false
	end

	if GamePhaseService.isInDungeon(player) then
		return false
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	playerPhases[player] = "Dungeon"
	player:SetAttribute("GamePhase", "Dungeon")
	GamePhaseService.teleportToDungeon(player)
	sendPhase(player)

	if WeaponServiceModule then
		WeaponServiceModule.refreshPlayerLoadout(player)
	end

	if DungeonRunServiceModule then
		DungeonRunServiceModule.startRun(player)
	end

	return true
end

function GamePhaseService.onPlayerReady(player: Player)
	playerPhases[player] = "Lobby"
	player:SetAttribute("GamePhase", "Lobby")
	GamePhaseService.teleportToLobby(player)
	sendPhase(player)

	if WeaponServiceModule and PlayerDataServiceModule then
		WeaponServiceModule.refreshPlayerLoadout(player)
	end
end

function GamePhaseService.init(deps: {
	dungeonRunService: any,
	playerDataService: any,
	weaponService: any,
})
	if not LobbyConfig.USE_LOBBY then
		return
	end

	DungeonRunServiceModule = deps.dungeonRunService
	PlayerDataServiceModule = deps.playerDataService
	WeaponServiceModule = deps.weaponService

	getPhaseStateEvent()
	getEnterDungeonEvent()

	getEnterDungeonEvent().OnServerEvent:Connect(function(player)
		GamePhaseService.enterDungeon(player)
	end)

	local function bindPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			task.defer(function()
				if player.Character ~= character then
					return
				end

				if GamePhaseService.isInLobby(player) then
					GamePhaseService.teleportToLobby(player)
				elseif GamePhaseService.isInDungeon(player) then
					GamePhaseService.teleportToDungeon(player)
				end

				if WeaponServiceModule then
					WeaponServiceModule.refreshPlayerLoadout(player)
				end
			end)
		end)

		if player.Character then
			GamePhaseService.onPlayerReady(player)
		else
			player.CharacterAdded:Once(function()
				GamePhaseService.onPlayerReady(player)
			end)
		end
	end

	for _, player in Players:GetPlayers() do
		bindPlayer(player)
	end

	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(function(player)
		playerPhases[player] = nil
	end)
end

return GamePhaseService
