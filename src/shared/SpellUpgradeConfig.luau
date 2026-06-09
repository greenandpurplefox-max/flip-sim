local SpellConfig = require(script.Parent.SpellConfig)

local SpellUpgradeConfig = {}

SpellUpgradeConfig.MAX_LEVEL = 20
SpellUpgradeConfig.ULTIMATE_LEVEL = 10
SpellUpgradeConfig.DAMAGE_PER_LEVEL = 0.09
SpellUpgradeConfig.COOLDOWN_REDUCTION_PER_LEVEL = 0.018
SpellUpgradeConfig.INTERVAL_REDUCTION_PER_LEVEL = 0.025
SpellUpgradeConfig.MIN_COOLDOWN_MULT = 0.7
SpellUpgradeConfig.MIN_INTERVAL_MULT = 0.72

SpellUpgradeConfig.UNLOCK_COSTS = {
	Firebolt = 0,
	FrostNova = 140,
	ThornRetort = 110,
	ArcaneVolley = 0,
	StaticWard = 160,
}

SpellUpgradeConfig.BASE_UPGRADE_COST = 30
SpellUpgradeConfig.UPGRADE_COST_GROWTH = 1.34

export type EffectiveSpellStats = SpellConfig.SpellStats & {
	level: number,
	isUltimate: boolean,
	resolvedName: string,
	resolvedDescription: string,
}

function SpellUpgradeConfig.getUnlockCost(spellId: string): number
	return SpellUpgradeConfig.UNLOCK_COSTS[spellId] or 9999
end

function SpellUpgradeConfig.getUpgradeCost(spellId: string, currentLevel: number): number
	if currentLevel >= SpellUpgradeConfig.MAX_LEVEL then
		return 0
	end

	local base = SpellUpgradeConfig.BASE_UPGRADE_COST + (SpellUpgradeConfig.getUnlockCost(spellId) * 0.1)
	return math.floor(base * (SpellUpgradeConfig.UPGRADE_COST_GROWTH ^ (currentLevel - 1)))
end

function SpellUpgradeConfig.getEffectiveStats(spellId: string, level: number): EffectiveSpellStats
	local base = SpellConfig.getSpell(spellId) or SpellConfig.Spells.Firebolt
	local clampedLevel = math.clamp(level, 1, SpellUpgradeConfig.MAX_LEVEL)
	local isUltimate = clampedLevel >= SpellUpgradeConfig.ULTIMATE_LEVEL
	local damageMult = 1 + (clampedLevel - 1) * SpellUpgradeConfig.DAMAGE_PER_LEVEL
	local cooldownMult = math.max(
		SpellUpgradeConfig.MIN_COOLDOWN_MULT,
		1 - (clampedLevel - 1) * SpellUpgradeConfig.COOLDOWN_REDUCTION_PER_LEVEL
	)
	local intervalMult = math.max(
		SpellUpgradeConfig.MIN_INTERVAL_MULT,
		1 - (clampedLevel - 1) * SpellUpgradeConfig.INTERVAL_REDUCTION_PER_LEVEL
	)

	local projectileCount = base.projectileCount or 1
	if isUltimate and base.ultimateProjectileCount then
		projectileCount = base.ultimateProjectileCount
	end

	local aoeRadius = base.aoeRadius or 0
	if isUltimate and aoeRadius > 0 then
		aoeRadius *= 1.35
	end

	return {
		id = base.id,
		kind = base.kind,
		displayName = base.displayName,
		ultimateDisplayName = base.ultimateDisplayName,
		description = base.description,
		ultimateDescription = base.ultimateDescription,
		damageMin = math.max(1, math.floor(base.damageMin * damageMult)),
		damageMax = math.max(1, math.floor(base.damageMax * damageMult)),
		projectileSpeed = base.projectileSpeed,
		projectileSize = if isUltimate then base.projectileSize * 1.3 else base.projectileSize,
		projectileColor = if isUltimate then base.projectileColor:Lerp(Color3.new(1, 1, 1), 0.25) else base.projectileColor,
		cooldown = if base.cooldown then math.floor(base.cooldown * cooldownMult * 100) / 100 else nil,
		interval = if base.interval then math.floor(base.interval * intervalMult * 100) / 100 else nil,
		trigger = base.trigger,
		projectileCount = projectileCount,
		ultimateProjectileCount = base.ultimateProjectileCount,
		aoeRadius = aoeRadius,
		level = clampedLevel,
		isUltimate = isUltimate,
		resolvedName = if isUltimate then base.ultimateDisplayName else base.displayName,
		resolvedDescription = if isUltimate then base.ultimateDescription else base.description,
	}
end

return SpellUpgradeConfig
