local BossConfig = {}

BossConfig.ID = "Gravewarden"
BossConfig.DISPLAY_NAME = "Gravewarden Alpha"

BossConfig.BASE_HEALTH = 180
BossConfig.HEALTH_PER_BOSS_DEPTH = 38
BossConfig.DAMAGE = 11
BossConfig.WALK_SPEED = 15
BossConfig.ATTACK_RANGE = 8
BossConfig.ATTACK_COOLDOWN = 2.75
BossConfig.SCALE = 2.65

BossConfig.ATTACKS = {
	GroundSlam = {
		id = "GroundSlam",
		displayName = "Ground Slam",
		minRange = 0,
		maxRange = 14,
		windup = 0.9,
		damage = 14,
		radius = 11,
		weight = 3,
	},
	SavageCharge = {
		id = "SavageCharge",
		displayName = "Savage Charge",
		minRange = 12,
		maxRange = 42,
		windup = 0.6,
		damage = 13,
		chargeSpeed = 62,
		chargeDistance = 26,
		weight = 3,
	},
	DarkHowl = {
		id = "DarkHowl",
		displayName = "Dark Howl",
		minRange = 0,
		maxRange = 26,
		windup = 1.15,
		damage = 8,
		radius = 19,
		weight = 2,
	},
}

function BossConfig.getHealthForDepth(bossDepthIndex: number): number
	return math.floor(BossConfig.BASE_HEALTH + bossDepthIndex * BossConfig.HEALTH_PER_BOSS_DEPTH)
end

function BossConfig.getBossDepthIndex(room: number, bossEveryN: number): number
	return math.max(1, math.floor(room / bossEveryN))
end

return BossConfig
