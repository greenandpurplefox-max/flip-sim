local DungeonConfig = require(script.Parent.DungeonConfig)
local LobbyConfig = require(script.Parent.LobbyConfig)

local BobConfig = {}

BobConfig.DISPLAY_NAME = "Bob"
BobConfig.PROMPT_OBJECT_TEXT = "Bob the Guide"
BobConfig.PROMPT_ACTION_TEXT = "Talk"
BobConfig.PROMPT_DISTANCE = 11

BobConfig.POSITION = LobbyConfig.LOBBY_SPAWN + Vector3.new(14, 0, -8)
BobConfig.LOOK_AT = LobbyConfig.LOBBY_CENTER + Vector3.new(0, 5, 0)

function BobConfig.getDialogueLines(): { string }
	local bossInterval = DungeonConfig.BOSS_EVERY_N_ROOMS
	local cardInterval = DungeonConfig.CARD_OFFER_EVERY_N_ROOMS

	return {
		"Ah, another hunter. The depths below swallow the unprepared — steel yourself before you step through that gate.",
		"Each room you clear pushes you deeper. More beasts spill in every depth, and the old ones grow meaner as you descend.",
		`Every {bossInterval} depths, the Gravewarden Alpha rises to block the way. Break it, or it breaks you.`,
		`Clear rooms for run gold. Every {cardInterval} depths the dungeon offers relic choices — pick wisely, they last the whole run.`,
		"If you fall down there, the gold you earned on that run still lands in your purse. Talk to Harold at the forge to upgrade your weapons before you march.",
	}
end

return BobConfig
