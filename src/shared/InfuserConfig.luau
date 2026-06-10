local LobbyConfig = require(script.Parent.LobbyConfig)

local InfuserConfig = {}

InfuserConfig.DISPLAY_NAME = "Mira the Infuser"
InfuserConfig.PROMPT_OBJECT_TEXT = "Mira the Infuser"
InfuserConfig.PROMPT_ACTION_TEXT = "Infuse"
InfuserConfig.PROMPT_DISTANCE = 11

InfuserConfig.POSITION = LobbyConfig.FORGE_POSITION + Vector3.new(-14, 0, -4)
InfuserConfig.LOOK_AT = LobbyConfig.LOBBY_CENTER + Vector3.new(0, 5, 0)

return InfuserConfig
