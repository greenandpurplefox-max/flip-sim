local BossConfig = {}

BossConfig.ID = "Gravewarden"
BossConfig.DISPLAY_NAME = "Gravewarden Alpha"

BossConfig.BASE_HEALTH = 220
BossConfig.HEALTH_PER_BOSS_DEPTH = 45
BossConfig.DAMAGE = 14
BossConfig.WALK_SPEED = 16
BossConfig.ATTACK_RANGE = 8
BossConfig.ATTACK_COOLDOWN = 2.4
BossConfig.SCALE = 2.65

BossConfig.ATTACKS = {
	GroundSlam = {
		id = "GroundSlam",
		displayName = "Ground Slam",
		minRange = 0,
		maxRange = 14,
		windup = 0.85,
		damage = 18,
		radius = 13,
		weight = 3,
	},
	SavageCharge = {
		id = "SavageCharge",
		displayName = "Savage Charge",
		minRange = 12,
		maxRange = 42,
		windup = 0.55,
		damage = 16,
		chargeSpeed = 72,
		chargeDistance = 28,
		weight = 3,
	},
	DarkHowl = {
		id = "DarkHowl",
		displayName = "Dark Howl",
		minRange = 0,
		maxRange = 26,
		windup = 1.1,
		damage = 10,
		radius = 22,
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
