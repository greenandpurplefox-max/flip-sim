local WeaponConfig = {}

export type WeaponStats = {
	id: string,
	displayName: string,
	description: string,
	damageMin: number,
	damageMax: number,
	cooldown: number,
	hitboxScale: number,
}

WeaponConfig.Weapons = {
	Broadsword = {
		id = "Broadsword",
		displayName = "Broadsword",
		description = "Heavy two-handed slashes.",
		damageMin = 5,
		damageMax = 10,
		cooldown = 0.65,
		hitboxScale = 2.35,
	},
	Rapier = {
		id = "Rapier",
		displayName = "Rapier",
		description = "Fast one-handed thrusts.",
		damageMin = 4,
		damageMax = 7,
		cooldown = 0.2,
		hitboxScale = 1.85,
	},
	WarAxe = {
		id = "WarAxe",
		displayName = "War Axe",
		description = "Quick overhead chops with a wide edge.",
		damageMin = 6,
		damageMax = 11,
		cooldown = 0.48,
		hitboxScale = 2.1,
	},
	Halberd = {
		id = "Halberd",
		displayName = "Halberd",
		description = "Long reach polearm sweeps.",
		damageMin = 7,
		damageMax = 12,
		cooldown = 0.72,
		hitboxScale = 2.55,
	},
	WarHammer = {
		id = "WarHammer",
		displayName = "War Hammer",
		description = "Slow crushing blows that hit hard.",
		damageMin = 9,
		damageMax = 16,
		cooldown = 0.95,
		hitboxScale = 1.95,
	},
}

WeaponConfig.DEFAULT_WEAPON = "Broadsword"
WeaponConfig.WEAPON_ATTRIBUTE = "WeaponId"

function WeaponConfig.getWeapon(id: string): WeaponStats?
	return WeaponConfig.Weapons[id]
end

function WeaponConfig.getWeaponList(): { WeaponStats }
	local list: { WeaponStats } = {}
	for _, weapon in WeaponConfig.Weapons do
		table.insert(list, weapon)
	end
	return list
end

function WeaponConfig.isValid(id: string): boolean
	return WeaponConfig.Weapons[id] ~= nil
end

function WeaponConfig.getStatsForTool(tool: Tool): WeaponStats
	local weaponId = tool:GetAttribute(WeaponConfig.WEAPON_ATTRIBUTE) or tool.Name
	return WeaponConfig.getWeapon(weaponId :: string) or WeaponConfig.Weapons.Broadsword
end

return WeaponConfig
