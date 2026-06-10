local SpellConfig = {}

export type SpellStats = {
	id: string,
	displayName: string,
	ultimateDisplayName: string,
	description: string,
	ultimateDescription: string,
	damageMin: number,
	damageMax: number,
	projectileSpeed: number,
	projectileSize: Vector3,
	projectileColor: Color3,
	cooldown: number,
	staminaCost: number,
	aoeRadius: number?,
}

SpellConfig.DEFAULT_ACTIVE = "Firebolt"

SpellConfig.Spells = {
	Firebolt = {
		id = "Firebolt",
		displayName = "Firebolt",
		ultimateDisplayName = "Inferno Lance",
		description = "Press E to launch a flaming bolt forward.",
		ultimateDescription = "Press E to fire a blazing lance that pierces deeper.",
		damageMin = 8,
		damageMax = 14,
		projectileSpeed = 92,
		projectileSize = Vector3.new(0.85, 0.85, 3.2),
		projectileColor = Color3.fromRGB(255, 120, 48),
		cooldown = 2.4,
		staminaCost = 28,
		aoeRadius = 0,
	},
	FrostNova = {
		id = "FrostNova",
		displayName = "Frost Nova",
		ultimateDisplayName = "Blizzard Core",
		description = "Press E to burst ice in front of you.",
		ultimateDescription = "Press E to unleash a wider freezing blast.",
		damageMin = 10,
		damageMax = 18,
		projectileSpeed = 0,
		projectileSize = Vector3.new(1.8, 1.8, 1.8),
		projectileColor = Color3.fromRGB(120, 200, 255),
		cooldown = 4.2,
		staminaCost = 45,
		aoeRadius = 10,
	},
}

function SpellConfig.getSpell(id: string): SpellStats?
	return SpellConfig.Spells[id]
end

function SpellConfig.getSpellList(): { SpellStats }
	local list: { SpellStats } = {}
	for _, spell in SpellConfig.Spells do
		table.insert(list, spell)
	end
	table.sort(list, function(a, b)
		return a.displayName < b.displayName
	end)
	return list
end

function SpellConfig.isValid(id: string): boolean
	return SpellConfig.Spells[id] ~= nil
end

return SpellConfig
