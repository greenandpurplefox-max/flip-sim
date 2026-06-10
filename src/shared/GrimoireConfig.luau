local GrimoireConfig = {}

GrimoireConfig.TIER_DROP_CHANCE = {
	Common = 0.04,
	Rare = 0.12,
	Epic = 0.28,
}

GrimoireConfig.DUPLICATE_GOLD = 30

function GrimoireConfig.getChestDropChance(tierId: string): number
	return GrimoireConfig.TIER_DROP_CHANCE[tierId] or GrimoireConfig.TIER_DROP_CHANCE.Common
end

return GrimoireConfig
