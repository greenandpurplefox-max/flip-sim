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
SpellConfig.NO_PASSIVE = ""

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
	ArcaneVolley = {
		id = "ArcaneVolley",
		kind = "Passive",
		trigger = "Interval",
		displayName = "Arcane Volley",
		ultimateDisplayName = "Twin Volley",
		description = "Every few seconds, shoot a bolt straight ahead.",
		ultimateDescription = "Every few seconds, shoot twin bolts straight ahead.",
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

function SpellConfig.hasEquippedPassive(id: string): boolean
	return id ~= "" and SpellConfig.isValid(id) and SpellConfig.getKind(id) == "Passive"
end

return SpellConfig
