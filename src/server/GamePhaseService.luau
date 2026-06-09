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
local portalPromptConnection: RBXScriptConnection? = nil
local lastPortalEnterAt: { [Player]: number } = {}

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

local function isPlayerActive(player: Player): boolean
	return player.Parent ~= nil
end

local function teleportCharacter(player: Player, position: Vector3)
	if not isPlayerActive(player) then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local lookVector = root.CFrame.LookVector
	local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
	if flatLook.Magnitude < 0.05 then
		flatLook = Vector3.new(0, 0, 1)
	else
		flatLook = flatLook.Unit
	end

	character:PivotTo(CFrame.new(position, position + flatLook))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

local function rescueFallenLobbyPlayer(player: Player)
	if not isPlayerActive(player) then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	if root.Position.Y < LobbyConfig.LOBBY_FALL_Y then
		GamePhaseService.teleportToLobby(player)
		humanoid.Health = humanoid.MaxHealth
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

	lastPortalEnterAt[player] = nil

	playerPhases[player] = "Lobby"
	player:SetAttribute("GamePhase", "Lobby")

	if runGold and runGold > 0 and PlayerDataServiceModule then
		PlayerDataServiceModule.addGold(player, runGold)
	end

	if DungeonRunServiceModule then
		DungeonRunServiceModule.bankRunChests(player)
		DungeonRunServiceModule.endRun(player)
	end

	GamePhaseService.teleportToLobby(player)
	sendPhase(player)

	if WeaponServiceModule then
		WeaponServiceModule.refreshPlayerLoadout(player)
	end
end

function GamePhaseService.enterDungeon(player: Player): boolean
	if not LobbyConfig.USE_LOBBY or not isPlayerActive(player) then
		return false
	end

	if DungeonRunServiceModule and DungeonRunServiceModule.hasActiveRun(player) then
		return false
	end

	local now = os.clock()
	if lastPortalEnterAt[player] and now - lastPortalEnterAt[player] < 1.5 then
		return false
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	lastPortalEnterAt[player] = now

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

function GamePhaseService.wireDungeonPortal()
	local folder = workspace:FindFirstChild("Lobby")
	if not folder then
		return
	end

	local trigger = folder:FindFirstChild("PortalTrigger", true) :: BasePart?
	if not trigger then
		return
	end

	for _, child in trigger:GetChildren() do
		if child:IsA("ProximityPrompt") then
			child:Destroy()
		end
	end

	if portalPromptConnection then
		portalPromptConnection:Disconnect()
		portalPromptConnection = nil
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EnterDungeonPrompt"
	prompt.ActionText = "Enter Dungeon"
	prompt.ObjectText = "Dungeon Gate"
	prompt.HoldDuration = LobbyConfig.PORTAL_HOLD_SECONDS
	prompt.MaxActivationDistance = LobbyConfig.PORTAL_PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.Parent = trigger

	portalPromptConnection = prompt.Triggered:Connect(function(player)
		GamePhaseService.enterDungeon(player)
	end)
end

function GamePhaseService.onPlayerReady(player: Player)
	if not isPlayerActive(player) then
		return
	end

	playerPhases[player] = "Lobby"
	player:SetAttribute("GamePhase", "Lobby")

	GamePhaseService.teleportToLobby(player)
	sendPhase(player)

	if WeaponServiceModule then
		WeaponServiceModule.refreshPlayerLoadout(player)
	end
end

local function runLobbySafetyLoop()
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				if not isPlayerActive(player) then
					continue
				end

				if GamePhaseService.isInLobby(player) then
					rescueFallenLobbyPlayer(player)
				end
			end
			task.wait(0.15)
		end
	end)
end

local function runPortalZoneLoop()
	local portalHoldTimes: { [Player]: number } = {}

	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				if not isPlayerActive(player) then
					continue
				end

				if DungeonRunServiceModule and DungeonRunServiceModule.hasActiveRun(player) then
					portalHoldTimes[player] = nil
				else
					local character = player.Character
					local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					if root and humanoid and humanoid.Health > 0 then
						local portalPos = LobbyConfig.PORTAL_POSITION
						local flatDistance = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(portalPos.X, 0, portalPos.Z)).Magnitude
						local inPortalZone = flatDistance <= LobbyConfig.PORTAL_ZONE_RADIUS
							and math.abs(root.Position.Y - portalPos.Y) <= 10

						if inPortalZone then
							local startedAt = portalHoldTimes[player]
							if not startedAt then
								portalHoldTimes[player] = os.clock()
							elseif os.clock() - startedAt >= LobbyConfig.PORTAL_HOLD_SECONDS then
								portalHoldTimes[player] = nil
								GamePhaseService.enterDungeon(player)
							end
						else
							portalHoldTimes[player] = nil
						end
					else
						portalHoldTimes[player] = nil
					end
				end
			end
			task.wait(0.1)
		end
	end)
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
				if not isPlayerActive(player) or player.Character ~= character or not character.Parent then
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
		lastPortalEnterAt[player] = nil
	end)

	runLobbySafetyLoop()
	runPortalZoneLoop()
end

return GamePhaseService
