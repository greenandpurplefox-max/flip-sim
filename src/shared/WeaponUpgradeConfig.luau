local WeaponConfig = require(script.Parent.WeaponConfig)

local WeaponUpgradeConfig = {}

WeaponUpgradeConfig.MAX_LEVEL = 20
WeaponUpgradeConfig.DAMAGE_PER_LEVEL = 0.08
WeaponUpgradeConfig.COOLDOWN_REDUCTION_PER_LEVEL = 0.015
WeaponUpgradeConfig.MIN_COOLDOWN_MULT = 0.72

WeaponUpgradeConfig.UNLOCK_COSTS = {
	Broadsword = 0,
	Rapier = 120,
	WarAxe = 180,
	Halberd = 240,
	WarHammer = 300,
}

WeaponUpgradeConfig.BASE_UPGRADE_COST = 35
WeaponUpgradeConfig.UPGRADE_COST_GROWTH = 1.38

function WeaponUpgradeConfig.getUnlockCost(weaponId: string): number
	return WeaponUpgradeConfig.UNLOCK_COSTS[weaponId] or 9999
end

function WeaponUpgradeConfig.getUpgradeCost(weaponId: string, currentLevel: number): number
	if currentLevel >= WeaponUpgradeConfig.MAX_LEVEL then
		return 0
	end

	local base = WeaponUpgradeConfig.BASE_UPGRADE_COST + (WeaponUpgradeConfig.getUnlockCost(weaponId) * 0.08)
	return math.floor(base * (WeaponUpgradeConfig.UPGRADE_COST_GROWTH ^ (currentLevel - 1)))
end

function WeaponUpgradeConfig.getEffectiveStats(weaponId: string, level: number): WeaponConfig.WeaponStats
	local base = WeaponConfig.getWeapon(weaponId) or WeaponConfig.Weapons.Broadsword
	local clampedLevel = math.clamp(level, 1, WeaponUpgradeConfig.MAX_LEVEL)
	local damageMult = 1 + (clampedLevel - 1) * WeaponUpgradeConfig.DAMAGE_PER_LEVEL
	local cooldownMult = math.max(
		WeaponUpgradeConfig.MIN_COOLDOWN_MULT,
		1 - (clampedLevel - 1) * WeaponUpgradeConfig.COOLDOWN_REDUCTION_PER_LEVEL
	)

	return {
		id = base.id,
		displayName = base.displayName,
		description = base.description,
		damageMin = math.max(1, math.floor(base.damageMin * damageMult)),
		damageMax = math.max(1, math.floor(base.damageMax * damageMult)),
		cooldown = math.floor(base.cooldown * cooldownMult * 100) / 100,
		hitboxScale = base.hitboxScale,
	}
end

return WeaponUpgradeConfig
