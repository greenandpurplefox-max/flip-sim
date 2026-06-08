local CardConfig = {}

export type CardEffects = {
	damageMult: number?,
	cooldownMult: number?,
	maxHealthBonus: number?,
	healOnRoomClear: number?,
	lifestealPercent: number?,
}

export type CardDefinition = {
	id: string,
	name: string,
	description: string,
	effects: CardEffects,
}

CardConfig.Cards = {
	BloodOath = {
		id = "BloodOath",
		name = "Blood Oath",
		description = "+18% damage, -12 max health.",
		effects = { damageMult = 1.18, maxHealthBonus = -12 },
	},
	IronHide = {
		id = "IronHide",
		name = "Iron Hide",
		description = "+25 max health.",
		effects = { maxHealthBonus = 25 },
	},
	BeastBane = {
		id = "BeastBane",
		name = "Beast Bane",
		description = "+22% damage against dungeon beasts.",
		effects = { damageMult = 1.22 },
	},
	QuickHands = {
		id = "QuickHands",
		name = "Quick Hands",
		description = "15% faster weapon swings.",
		effects = { cooldownMult = 0.85 },
	},
	VampiricEdge = {
		id = "VampiricEdge",
		name = "Vampiric Edge",
		description = "8% of damage dealt heals you.",
		effects = { lifestealPercent = 0.08 },
	},
	SecondWind = {
		id = "SecondWind",
		name = "Second Wind",
		description = "Restore 12 health after each cleared room.",
		effects = { healOnRoomClear = 12 },
	},
	Relentless = {
		id = "Relentless",
		name = "Relentless",
		description = "+10% damage and +10 max health.",
		effects = { damageMult = 1.1, maxHealthBonus = 10 },
	},
	StoneSkin = {
		id = "StoneSkin",
		name = "Stone Skin",
		description = "+35 max health, 8% slower swings.",
		effects = { maxHealthBonus = 35, cooldownMult = 1.08 },
	},
	HunterFocus = {
		id = "HunterFocus",
		name = "Hunter's Focus",
		description = "+14% damage.",
		effects = { damageMult = 1.14 },
	},
	GraveHarvest = {
		id = "GraveHarvest",
		name = "Grave Harvest",
		description = "Heal 6 HP on room clear and steal 5% life from hits.",
		effects = { healOnRoomClear = 6, lifestealPercent = 0.05 },
	},
}

function CardConfig.getCard(id: string): CardDefinition?
	return CardConfig.Cards[id]
end

function CardConfig.getAllIds(): { string }
	local ids: { string } = {}
	for id in CardConfig.Cards do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

return CardConfig
