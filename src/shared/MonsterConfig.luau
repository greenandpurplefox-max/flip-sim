local MonsterConfig = {}

export type MonsterType = {
	id: string,
	displayName: string,
	minDepth: number,
	weight: number,
	health: number,
	damage: number,
	walkSpeed: number,
	attackRange: number,
	attackCooldown: number,
	scaleMult: number,
	paletteIndex: number?,
	isArmored: boolean?,
}

MonsterConfig.TYPES = {
	Wolf = {
		id = "Wolf",
		displayName = "Forest Wolf",
		minDepth = 1,
		weight = 10,
		health = 20,
		damage = 6,
		walkSpeed = 20,
		attackRange = 6.2,
		attackCooldown = 1.1,
		scaleMult = 1,
	},
	DireWolf = {
		id = "DireWolf",
		displayName = "Dire Wolf",
		minDepth = 4,
		weight = 6,
		health = 38,
		damage = 10,
		walkSpeed = 18,
		attackRange = 6.8,
		attackCooldown = 1.25,
		scaleMult = 1.35,
		paletteIndex = 2,
	},
	Stalker = {
		id = "Stalker",
		displayName = "Shadow Stalker",
		minDepth = 7,
		weight = 5,
		health = 16,
		damage = 8,
		walkSpeed = 28,
		attackRange = 5.8,
		attackCooldown = 0.85,
		scaleMult = 0.88,
		paletteIndex = 3,
	},
	Brute = {
		id = "Brute",
		displayName = "Thorn Brute",
		minDepth = 10,
		weight = 4,
		health = 55,
		damage = 12,
		walkSpeed = 14,
		attackRange = 7.2,
		attackCooldown = 1.45,
		scaleMult = 1.55,
		paletteIndex = 2,
		isArmored = true,
	},
}

MonsterConfig.DEPTH_HEALTH_GROWTH = 0.07
MonsterConfig.DEPTH_DAMAGE_GROWTH = 0.04

function MonsterConfig.getType(id: string): MonsterType
	return MonsterConfig.TYPES[id] or MonsterConfig.TYPES.Wolf
end

function MonsterConfig.getScaledStats(monsterType: MonsterType, depth: number): MonsterType
	local depthOffset = math.max(0, depth - 1)
	local healthMult = 1 + depthOffset * MonsterConfig.DEPTH_HEALTH_GROWTH
	local damageMult = 1 + depthOffset * MonsterConfig.DEPTH_DAMAGE_GROWTH

	return {
		id = monsterType.id,
		displayName = monsterType.displayName,
		minDepth = monsterType.minDepth,
		weight = monsterType.weight,
		health = math.floor(monsterType.health * healthMult),
		damage = math.floor(monsterType.damage * damageMult),
		walkSpeed = monsterType.walkSpeed,
		attackRange = monsterType.attackRange,
		attackCooldown = monsterType.attackCooldown,
		scaleMult = monsterType.scaleMult,
		paletteIndex = monsterType.paletteIndex,
		isArmored = monsterType.isArmored,
	}
end

function MonsterConfig.rollTypeForDepth(depth: number): string
	local pool: { { id: string, weight: number } } = {}

	for _, monsterType in MonsterConfig.TYPES do
		if depth >= monsterType.minDepth then
			local weight = monsterType.weight
			if depth >= monsterType.minDepth + 3 then
				weight += 2
			end
			table.insert(pool, { id = monsterType.id, weight = weight })
		end
	end

	if #pool == 0 then
		return "Wolf"
	end

	local totalWeight = 0
	for _, entry in pool do
		totalWeight += entry.weight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, entry in pool do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.id
		end
	end

	return pool[#pool].id
end

function MonsterConfig.getMinionCountForRoom(depth: number, isBossRoom: boolean): number
	local base = math.floor(4 + depth * 0.45)
	base = math.clamp(base, 4, 14)
	if isBossRoom then
		return math.clamp(math.floor(base * 0.45), 3, 6)
	end
	return base
end

return MonsterConfig
