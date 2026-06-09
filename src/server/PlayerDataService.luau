local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)
local TreasureConfig = require(ReplicatedStorage.Shared.TreasureConfig)
local WeaponConfig = require(ReplicatedStorage.Shared.WeaponConfig)
local WeaponUpgradeConfig = require(ReplicatedStorage.Shared.WeaponUpgradeConfig)

local PlayerDataService = {}

export type LobbyChest = {
	tierId: string,
	roomDepth: number,
}

export type PlayerProfile = {
	gold: number,
	equippedWeapon: string,
	weaponLevels: { [string]: number },
	unlockedWeapons: { [string]: boolean },
	lobbyChests: { LobbyChest },
}

local DATASTORE_NAME = "FlipSimPlayerProfiles_v1"
local AUTO_SAVE_INTERVAL_SECONDS = 45
local SAVE_DEBOUNCE_SECONDS = 6
local SAVE_RETRY_COUNT = 3

local profileStore: GlobalDataStore? = nil
local dataStoreEnabled = false
local profiles: { [Player]: PlayerProfile } = {}
local profileStateEvent: RemoteEvent
local pendingSaveTasks: { [Player]: thread } = {}

local function getDefaultProfile(): PlayerProfile
	local weaponLevels: { [string]: number } = {}
	local unlockedWeapons: { [string]: boolean } = {
		[LobbyConfig.STARTER_WEAPON] = true,
	}

	for _, weapon in WeaponConfig.getWeaponList() do
		weaponLevels[weapon.id] = 1
		if weapon.id ~= LobbyConfig.STARTER_WEAPON then
			unlockedWeapons[weapon.id] = false
		end
	end

	return {
		gold = LobbyConfig.STARTER_GOLD,
		equippedWeapon = LobbyConfig.STARTER_WEAPON,
		weaponLevels = weaponLevels,
		unlockedWeapons = unlockedWeapons,
		lobbyChests = {},
	}
end

local function sanitizeLobbyChests(data: any): { LobbyChest }
	local chests: { LobbyChest } = {}
	if typeof(data) ~= "table" then
		return chests
	end

	for _, chest in data do
		if typeof(chest) == "table" and typeof(chest.tierId) == "string" then
			local tier = TreasureConfig.getTier(chest.tierId)
			if tier then
				local roomDepth = if typeof(chest.roomDepth) == "number"
					then math.max(1, math.floor(chest.roomDepth))
					else 1
				table.insert(chests, {
					tierId = chest.tierId,
					roomDepth = roomDepth,
				})
			end
		end
	end

	return chests
end

local function sanitizeProfile(data: any): PlayerProfile
	local defaults = getDefaultProfile()
	if typeof(data) ~= "table" then
		return defaults
	end

	local profile = table.clone(defaults)
	profile.gold = if typeof(data.gold) == "number" then math.max(0, math.floor(data.gold)) else defaults.gold
	profile.equippedWeapon = if WeaponConfig.isValid(data.equippedWeapon)
		then data.equippedWeapon
		else defaults.equippedWeapon

	if typeof(data.weaponLevels) == "table" then
		for weaponId, level in data.weaponLevels do
			if WeaponConfig.isValid(weaponId) and typeof(level) == "number" then
				profile.weaponLevels[weaponId] = math.clamp(math.floor(level), 1, WeaponUpgradeConfig.MAX_LEVEL)
			end
		end
	end

	if typeof(data.unlockedWeapons) == "table" then
		for weaponId, unlocked in data.unlockedWeapons do
			if WeaponConfig.isValid(weaponId) and typeof(unlocked) == "boolean" then
				profile.unlockedWeapons[weaponId] = unlocked
			end
		end
	end

	profile.unlockedWeapons[LobbyConfig.STARTER_WEAPON] = true
	if not profile.unlockedWeapons[profile.equippedWeapon] then
		profile.equippedWeapon = LobbyConfig.STARTER_WEAPON
	end

	profile.lobbyChests = sanitizeLobbyChests(data.lobbyChests)

	return profile
end

local function getProfileStateEvent(): RemoteEvent
	if profileStateEvent then
		return profileStateEvent
	end

	profileStateEvent = ReplicatedStorage:FindFirstChild("PlayerProfileState") :: RemoteEvent?
	if not profileStateEvent then
		profileStateEvent = Instance.new("RemoteEvent")
		profileStateEvent.Name = "PlayerProfileState"
		profileStateEvent.Parent = ReplicatedStorage
	end

	return profileStateEvent
end

local function buildSnapshot(profile: PlayerProfile)
	local weaponLevels: { [string]: number } = {}
	local unlockedWeapons: { [string]: boolean } = {}
	for _, weapon in WeaponConfig.getWeaponList() do
		weaponLevels[weapon.id] = profile.weaponLevels[weapon.id] or 1
		unlockedWeapons[weapon.id] = profile.unlockedWeapons[weapon.id] == true
	end

	return {
		gold = profile.gold,
		equippedWeapon = profile.equippedWeapon,
		weaponLevels = weaponLevels,
		unlockedWeapons = unlockedWeapons,
		lobbyChests = profile.lobbyChests,
	}
end

local function getProfileKey(player: Player): string
	return `player_{player.UserId}`
end

local function scheduleSave(player: Player)
	if not dataStoreEnabled or not profiles[player] then
		return
	end

	local pending = pendingSaveTasks[player]
	if pending then
		task.cancel(pending)
	end

	pendingSaveTasks[player] = task.delay(SAVE_DEBOUNCE_SECONDS, function()
		pendingSaveTasks[player] = nil
		PlayerDataService.saveProfile(player)
	end)
end

function PlayerDataService.sendProfile(player: Player)
	local profile = profiles[player]
	if profile then
		getProfileStateEvent():FireClient(player, buildSnapshot(profile))
	end
end

function PlayerDataService.getProfile(player: Player): PlayerProfile?
	return profiles[player]
end

function PlayerDataService.getGold(player: Player): number
	local profile = profiles[player]
	return if profile then profile.gold else 0
end

function PlayerDataService.addGold(player: Player, amount: number)
	local profile = profiles[player]
	if not profile or amount <= 0 then
		return
	end

	profile.gold += math.floor(amount)
	PlayerDataService.sendProfile(player)
	scheduleSave(player)
end

function PlayerDataService.trySpendGold(player: Player, amount: number): boolean
	local profile = profiles[player]
	if not profile or amount <= 0 or profile.gold < amount then
		return false
	end

	profile.gold -= math.floor(amount)
	PlayerDataService.sendProfile(player)
	scheduleSave(player)
	return true
end

function PlayerDataService.getEquippedWeapon(player: Player): string
	local profile = profiles[player]
	return if profile then profile.equippedWeapon else LobbyConfig.STARTER_WEAPON
end

function PlayerDataService.setEquippedWeapon(player: Player, weaponId: string): boolean
	local profile = profiles[player]
	if not profile or not profile.unlockedWeapons[weaponId] then
		return false
	end

	profile.equippedWeapon = weaponId
	PlayerDataService.sendProfile(player)
	scheduleSave(player)
	return true
end

function PlayerDataService.isWeaponUnlocked(player: Player, weaponId: string): boolean
	local profile = profiles[player]
	return profile ~= nil and profile.unlockedWeapons[weaponId] == true
end

function PlayerDataService.getWeaponLevel(player: Player, weaponId: string): number
	local profile = profiles[player]
	if not profile then
		return 1
	end
	return profile.weaponLevels[weaponId] or 1
end

function PlayerDataService.tryUnlockWeapon(player: Player, weaponId: string): (boolean, string?)
	local profile = profiles[player]
	if not profile or not WeaponConfig.isValid(weaponId) then
		return false, "Invalid weapon."
	end

	if profile.unlockedWeapons[weaponId] then
		return false, "Already unlocked."
	end

	local cost = WeaponUpgradeConfig.getUnlockCost(weaponId)
	if profile.gold < cost then
		return false, "Not enough gold."
	end

	profile.gold -= cost
	profile.unlockedWeapons[weaponId] = true
	PlayerDataService.sendProfile(player)
	scheduleSave(player)
	return true, nil
end

function PlayerDataService.tryUpgradeWeapon(player: Player, weaponId: string): (boolean, string?)
	local profile = profiles[player]
	if not profile or not profile.unlockedWeapons[weaponId] then
		return false, "Weapon locked."
	end

	local currentLevel = profile.weaponLevels[weaponId] or 1
	if currentLevel >= WeaponUpgradeConfig.MAX_LEVEL then
		return false, "Max level reached."
	end

	local cost = WeaponUpgradeConfig.getUpgradeCost(weaponId, currentLevel)
	if profile.gold < cost then
		return false, "Not enough gold."
	end

	profile.gold -= cost
	profile.weaponLevels[weaponId] = currentLevel + 1
	PlayerDataService.sendProfile(player)
	scheduleSave(player)
	return true, nil
end

function PlayerDataService.getLobbyChests(player: Player): { LobbyChest }
	local profile = profiles[player]
	if not profile then
		return {}
	end
	return profile.lobbyChests
end

function PlayerDataService.setLobbyChests(player: Player, chests: { LobbyChest })
	local profile = profiles[player]
	if not profile then
		return
	end

	profile.lobbyChests = chests
	scheduleSave(player)
end

function PlayerDataService.saveProfile(player: Player)
	local profile = profiles[player]
	if not profile or not profileStore or not dataStoreEnabled then
		return
	end

	local key = getProfileKey(player)
	local snapshot = buildSnapshot(profile)

	task.spawn(function()
		for attempt = 1, SAVE_RETRY_COUNT do
			local ok = pcall(function()
				profileStore:UpdateAsync(key, function()
					return snapshot
				end)
			end)
			if ok then
				return
			end
			task.wait(attempt)
		end
	end)
end

local function loadProfile(player: Player): PlayerProfile
	if not profileStore or not dataStoreEnabled then
		return getDefaultProfile()
	end

	local loaded: any = nil
	local ok = pcall(function()
		loaded = profileStore:GetAsync(getProfileKey(player))
	end)

	if ok then
		return sanitizeProfile(loaded)
	end

	return getDefaultProfile()
end

local function initProfileStore(): boolean
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)
	if not ok or not store then
		return false
	end

	if RunService:IsStudio() then
		local apiOk = pcall(function()
			store:GetAsync("__studio_api_probe__")
		end)
		if not apiOk then
			return false
		end
	end

	profileStore = store
	return true
end

local function bindPlayer(player: Player)
	profiles[player] = loadProfile(player)
	PlayerDataService.sendProfile(player)
end

local function unbindPlayer(player: Player)
	local pending = pendingSaveTasks[player]
	if pending then
		task.cancel(pending)
		pendingSaveTasks[player] = nil
	end

	PlayerDataService.saveProfile(player)
	profiles[player] = nil
end

function PlayerDataService.init()
	dataStoreEnabled = initProfileStore()
	if not dataStoreEnabled then
		if RunService:IsStudio() then
			warn(
				"[PlayerDataService] DataStore disabled in Studio. Enable 'Studio Access to API Services' in Game Settings to save progress."
			)
		else
			warn("[PlayerDataService] DataStore unavailable. Progress will not persist this session.")
		end
	end

	getProfileStateEvent()

	for _, player in Players:GetPlayers() do
		bindPlayer(player)
	end

	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(unbindPlayer)

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			PlayerDataService.saveProfile(player)
		end
		task.wait(2)
	end)

	task.spawn(function()
		while true do
			task.wait(AUTO_SAVE_INTERVAL_SECONDS)
			if not dataStoreEnabled then
				continue
			end
			for _, player in Players:GetPlayers() do
				PlayerDataService.saveProfile(player)
			end
		end
	end)
end

return PlayerDataService
