local DungeonConfig = require(script.Parent.DungeonConfig)
local LobbyConfig = require(script.Parent.LobbyConfig)

local BlacksmithConfig = {}

BlacksmithConfig.DISPLAY_NAME = "Harold"
BlacksmithConfig.PROMPT_OBJECT_TEXT = "Harold the Blacksmith"
BlacksmithConfig.PROMPT_ACTION_TEXT = "Talk"
BlacksmithConfig.PROMPT_DISTANCE = 11

BlacksmithConfig.POSITION = LobbyConfig.FORGE_POSITION + Vector3.new(3.2, 0, 1.4)
BlacksmithConfig.LOOK_AT = LobbyConfig.LOBBY_CENTER + Vector3.new(0, 5, 0)

function BlacksmithConfig.getDialogueLines(): { string }
	local bossInterval = DungeonConfig.BOSS_EVERY_N_ROOMS
	local cardInterval = DungeonConfig.CARD_OFFER_EVERY_N_ROOMS

	return {
		"Ah, another hunter. The depths below swallow the unprepared — steel yourself before you step through that gate.",
		"Each room you clear pushes you deeper. More beasts spill in every depth, and the old ones grow meaner as you descend.",
		`Every {bossInterval} depths, the Gravewarden Alpha rises to block the way. Break it, or it breaks you.`,
		`Clear rooms for run gold. Every {cardInterval} depths the dungeon offers relic choices — pick wisely, they last the whole run.`,
		"If you fall down there, the gold you earned on that run still lands in your purse. Upgrade your weapons at my forge before you march.",
	}
end

return BlacksmithConfig
