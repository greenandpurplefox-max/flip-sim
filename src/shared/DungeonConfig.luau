local DungeonConfig = {}

DungeonConfig.USE_DUNGEON_MODE = true

DungeonConfig.BASE_MONSTERS_PER_ROOM = 4
DungeonConfig.MONSTERS_PER_ROOM_GROWTH = 0.45
DungeonConfig.MAX_MONSTERS_PER_ROOM = 14
DungeonConfig.BOSS_EVERY_N_ROOMS = 5
DungeonConfig.BOSS_MONSTER_BONUS = 5

DungeonConfig.CARD_OFFER_EVERY_N_ROOMS = 3
DungeonConfig.FIRST_CARD_ROOM = 2

DungeonConfig.ROOM_CLEAR_DELAY = 2.2
DungeonConfig.CARD_DRAFT_TIMEOUT = 18
DungeonConfig.RUN_START_DELAY = 1.5

DungeonConfig.GOLD_PER_ROOM = 8
DungeonConfig.GOLD_PER_BOSS = 35

DungeonConfig.SPAWN_RADIUS_MIN = 70
DungeonConfig.SPAWN_RADIUS_MAX = 130

return DungeonConfig
