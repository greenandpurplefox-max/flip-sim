local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)
local WeaponConfig = require(ReplicatedStorage.Shared.WeaponConfig)
local WeaponUpgradeConfig = require(ReplicatedStorage.Shared.WeaponUpgradeConfig)

local PlayerDataService = {}

export type PlayerProfile = {
	gold: number,
	equippedWeapon: string,
	weaponLevels: { [string]: number },
	unlockedWeapons: { [string]: boolean },
}

local profileStore = nil
local profiles: { [Player]: PlayerProfile } = {}
local profileStateEvent: RemoteEvent

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
	}
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
	}
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
end

function PlayerDataService.trySpendGold(player: Player, amount: number): boolean
	local profile = profiles[player]
	if not profile or amount <= 0 or profile.gold < amount then
		return false
	end

	profile.gold -= math.floor(amount)
	PlayerDataService.sendProfile(player)
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
	return true, nil
end

function PlayerDataService.saveProfile(player: Player)
	local profile = profiles[player]
	if not profile or not profileStore then
		return
	end

	task.spawn(function()
		pcall(function()
			profileStore:SetAsync(`player_{player.UserId}`, buildSnapshot(profile))
		end)
	end)
end

local function loadProfile(player: Player): PlayerProfile
	if not profileStore then
		return getDefaultProfile()
	end

	local loaded: any = nil
	local ok = pcall(function()
		loaded = profileStore:GetAsync(`player_{player.UserId}`)
	end)

	if ok then
		return sanitizeProfile(loaded)
	end

	return getDefaultProfile()
end

function PlayerDataService.init()
	pcall(function()
		profileStore = DataStoreService:GetDataStore("FlipSimPlayerProfiles_v1")
	end)

	getProfileStateEvent()

	for _, player in Players:GetPlayers() do
		profiles[player] = loadProfile(player)
		PlayerDataService.sendProfile(player)
	end

	Players.PlayerAdded:Connect(function(player)
		profiles[player] = loadProfile(player)
		PlayerDataService.sendProfile(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		PlayerDataService.saveProfile(player)
		profiles[player] = nil
	end)

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			PlayerDataService.saveProfile(player)
		end
	end)
end

return PlayerDataService
