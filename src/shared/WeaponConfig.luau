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
}

WeaponConfig.DEFAULT_WEAPON = "Broadsword"
WeaponConfig.WEAPON_ATTRIBUTE = "WeaponId"

function WeaponConfig.getWeapon(id: string): WeaponStats?
	return WeaponConfig.Weapons[id]
end

function WeaponConfig.getWeaponList(): { WeaponStats }
	local list: { WeaponStats } = {}
	table.insert(list, WeaponConfig.Weapons.Broadsword)
	table.insert(list, WeaponConfig.Weapons.Rapier)
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
