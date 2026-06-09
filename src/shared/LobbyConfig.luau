local LobbyConfig = {}

LobbyConfig.USE_LOBBY = true

LobbyConfig.LOBBY_CENTER = Vector3.new(0, 4, -650)
LobbyConfig.LOBBY_SPAWN = Vector3.new(0, 6, -650)
LobbyConfig.DUNGEON_SPAWN = Vector3.new(0, 5, 0)

LobbyConfig.LOBBY_PLATFORM_SIZE = Vector3.new(96, 2, 96)
LobbyConfig.PORTAL_HOLD_SECONDS = 1.2
LobbyConfig.PORTAL_POSITION = Vector3.new(0, 6, -610)
LobbyConfig.PORTAL_ZONE_RADIUS = 8
LobbyConfig.PORTAL_PROMPT_DISTANCE = 16
LobbyConfig.FORGE_POSITION = Vector3.new(-18, 6, -650)
LobbyConfig.LOBBY_FALL_Y = 2.5

LobbyConfig.STARTER_WEAPON = "Broadsword"
LobbyConfig.STARTER_ACTIVE_SPELL = "Firebolt"
LobbyConfig.STARTER_PASSIVE_SPELL = "ArcaneVolley"
LobbyConfig.STARTER_GOLD = 25

return LobbyConfig
