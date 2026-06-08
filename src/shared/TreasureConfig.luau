local TreasureConfig = {}

TreasureConfig.CHEST_SPAWN_CHANCE = 0.38
TreasureConfig.BOSS_CHEST_GUARANTEED = true
TreasureConfig.CHEST_AUTO_OPEN_SECONDS = 14

TreasureConfig.TIERS = {
	Common = {
		id = "Common",
		displayName = "Common Chest",
		weight = 68,
		goldMin = 6,
		goldMax = 16,
		depthGoldBonus = 1,
		bodyColor = Color3.fromRGB(118, 82, 48),
		trimColor = Color3.fromRGB(168, 128, 72),
		glowColor = Color3.fromRGB(255, 196, 96),
	},
	Rare = {
		id = "Rare",
		displayName = "Rare Chest",
		weight = 26,
		goldMin = 18,
		goldMax = 38,
		depthGoldBonus = 2,
		bodyColor = Color3.fromRGB(58, 88, 148),
		trimColor = Color3.fromRGB(120, 168, 255),
		glowColor = Color3.fromRGB(96, 168, 255),
	},
	Epic = {
		id = "Epic",
		displayName = "Epic Chest",
		weight = 6,
		goldMin = 40,
		goldMax = 72,
		depthGoldBonus = 3,
		bodyColor = Color3.fromRGB(92, 58, 128),
		trimColor = Color3.fromRGB(214, 176, 72),
		glowColor = Color3.fromRGB(255, 128, 220),
	},
}

function TreasureConfig.getTier(tierId: string)
	return TreasureConfig.TIERS[tierId] or TreasureConfig.TIERS.Common
end

function TreasureConfig.rollTier(isBossRoom: boolean, roomDepth: number): string
	if isBossRoom then
		local roll = math.random(1, 100)
		if roll <= 55 then
			return "Epic"
		elseif roll <= 90 then
			return "Rare"
		end
		return "Common"
	end

	local depthBonus = math.clamp(math.floor(roomDepth / 4), 0, 8)
	local weights = {
		Common = TreasureConfig.TIERS.Common.weight,
		Rare = TreasureConfig.TIERS.Rare.weight + depthBonus,
		Epic = TreasureConfig.TIERS.Epic.weight + math.floor(depthBonus / 2),
	}

	local total = weights.Common + weights.Rare + weights.Epic
	local roll = math.random(1, total)
	if roll <= weights.Epic then
		return "Epic"
	elseif roll <= weights.Epic + weights.Rare then
		return "Rare"
	end
	return "Common"
end

function TreasureConfig.rollGold(tierId: string, roomDepth: number): number
	local tier = TreasureConfig.getTier(tierId)
	local depthBonus = math.floor(roomDepth * tier.depthGoldBonus)
	local minGold = tier.goldMin + depthBonus
	local maxGold = tier.goldMax + depthBonus
	return math.random(minGold, maxGold)
end

function TreasureConfig.shouldSpawnChest(isBossRoom: boolean): boolean
	if isBossRoom and TreasureConfig.BOSS_CHEST_GUARANTEED then
		return true
	end
	return math.random() < TreasureConfig.CHEST_SPAWN_CHANCE
end

return TreasureConfig
