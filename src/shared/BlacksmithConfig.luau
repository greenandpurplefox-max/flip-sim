local LobbyConfig = require(script.Parent.LobbyConfig)
local BlacksmithConfig = {}

BlacksmithConfig.DISPLAY_NAME = "Harold"
BlacksmithConfig.PROMPT_OBJECT_TEXT = "Harold the Blacksmith"
BlacksmithConfig.PROMPT_ACTION_TEXT = "Talk"
BlacksmithConfig.PROMPT_DISTANCE = 11

BlacksmithConfig.POSITION = LobbyConfig.FORGE_POSITION + Vector3.new(3.2, 0, 1.4)
BlacksmithConfig.LOOK_AT = LobbyConfig.LOBBY_CENTER + Vector3.new(0, 5, 0)

return BlacksmithConfig
