local SpellConfig = {}

export type SpellKind = "Active" | "Passive"
export type PassiveTrigger = "OnHit" | "Interval"

export type SpellStats = {
	id: string,
	kind: SpellKind,
	displayName: string,
	ultimateDisplayName: string,
	description: string,
	ultimateDescription: string,
	damageMin: number,
	damageMax: number,
	projectileSpeed: number,
	projectileSize: Vector3,
	projectileColor: Color3,
	cooldown: number?,
	interval: number?,
	trigger: PassiveTrigger?,
	projectileCount: number?,
	ultimateProjectileCount: number?,
	aoeRadius: number?,
}

SpellConfig.DEFAULT_ACTIVE = "Firebolt"
SpellConfig.DEFAULT_PASSIVE = "ArcaneVolley"

SpellConfig.Spells = {
	Firebolt = {
		id = "Firebolt",
		kind = "Active",
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
		aoeRadius = 0,
	},
	FrostNova = {
		id = "FrostNova",
		kind = "Active",
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
		aoeRadius = 10,
	},
	ThornRetort = {
		id = "ThornRetort",
		kind = "Passive",
		trigger = "OnHit",
		displayName = "Thorn Retort",
		ultimateDisplayName = "Thorn Nova",
		description = "When hit, fire a thorn in a random direction.",
		ultimateDescription = "When hit, fire a burst of thorns in random directions.",
		damageMin = 5,
		damageMax = 9,
		projectileSpeed = 70,
		projectileSize = Vector3.new(0.7, 0.7, 2.2),
		projectileColor = Color3.fromRGB(96, 200, 96),
		projectileCount = 1,
		ultimateProjectileCount = 4,
		aoeRadius = 0,
	},
	ArcaneVolley = {
		id = "ArcaneVolley",
		kind = "Passive",
		trigger = "Interval",
		displayName = "Arcane Volley",
		ultimateDisplayName = "Twin Volley",
		description = "Every few seconds, shoot a bolt in front of you.",
		ultimateDescription = "Every few seconds, shoot twin bolts forward.",
		damageMin = 6,
		damageMax = 11,
		projectileSpeed = 84,
		projectileSize = Vector3.new(0.75, 0.75, 2.6),
		projectileColor = Color3.fromRGB(160, 96, 255),
		interval = 5,
		projectileCount = 1,
		ultimateProjectileCount = 2,
		aoeRadius = 0,
	},
	StaticWard = {
		id = "StaticWard",
		kind = "Passive",
		trigger = "OnHit",
		displayName = "Static Ward",
		ultimateDisplayName = "Storm Ward",
		description = "When hit, lash the nearest foe with lightning.",
		ultimateDescription = "When hit, chain lightning through nearby foes.",
		damageMin = 7,
		damageMax = 12,
		projectileSpeed = 110,
		projectileSize = Vector3.new(0.65, 0.65, 2.4),
		projectileColor = Color3.fromRGB(255, 230, 96),
		projectileCount = 1,
		ultimateProjectileCount = 3,
		aoeRadius = 0,
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
		if a.kind == b.kind then
			return a.displayName < b.displayName
		end
		return a.kind < b.kind
	end)
	return list
end

function SpellConfig.isValid(id: string): boolean
	return SpellConfig.Spells[id] ~= nil
end

function SpellConfig.getKind(id: string): SpellKind?
	local spell = SpellConfig.getSpell(id)
	return if spell then spell.kind else nil
end

return SpellConfig
