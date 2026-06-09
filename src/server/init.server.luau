local AnimationOverrideService = require(script.AnimationOverrideService)
local CardService = require(script.CardService)
local DashService = require(script.DashService)
local DungeonRunService = require(script.DungeonRunService)
local GamePhaseService = require(script.GamePhaseService)
local LobbyEnvironmentService = require(script.LobbyEnvironmentService)
local PlayerDataService = require(script.PlayerDataService)
local WaveService = require(script.WaveService)
local BossService = require(script.BossService)
local WeaponService = require(script.WeaponService)
local SpellService = require(script.SpellService)
local TreasureChestService = require(script.TreasureChestService)

local centerMarker = workspace:FindFirstChild("CenterMarker")
if centerMarker then
	centerMarker:Destroy()
end

PlayerDataService.init()
AnimationOverrideService.init()
DashService.init()
WaveService.init()
CardService.init()
WeaponService.init()
SpellService.init()
WaveService.setOnPlayerDamagedCallback(SpellService.onPlayerDamaged)
BossService.setOnPlayerDamagedCallback(SpellService.onPlayerDamaged)
TreasureChestService.init()
DungeonRunService.init()

GamePhaseService.init({
	dungeonRunService = DungeonRunService,
	playerDataService = PlayerDataService,
	weaponService = WeaponService,
	spellService = SpellService,
})

DungeonRunService.setRunEndedHandler(function(player, runGold)
	GamePhaseService.returnToLobby(player, runGold)
end)

LobbyEnvironmentService.init()
GamePhaseService.wireDungeonPortal()
