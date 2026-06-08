local BroadswordConfig = require(script.Parent.BroadswordConfig)
local HalberdConfig = require(script.Parent.HalberdConfig)
local RapierConfig = require(script.Parent.RapierConfig)
local WarAxeConfig = require(script.Parent.WarAxeConfig)
local WarHammerConfig = require(script.Parent.WarHammerConfig)
local WeaponConfig = require(script.Parent.WeaponConfig)

local WeaponCombatConfig = {}

local CONFIG_BY_WEAPON = {
	Broadsword = BroadswordConfig,
	Rapier = RapierConfig,
	WarAxe = WarAxeConfig,
	Halberd = HalberdConfig,
	WarHammer = WarHammerConfig,
}

function WeaponCombatConfig.getConfig(weaponId: string)
	return CONFIG_BY_WEAPON[weaponId] or BroadswordConfig
end

function WeaponCombatConfig.getConfigForTool(tool: Tool)
	local weaponId = tool:GetAttribute(WeaponConfig.WEAPON_ATTRIBUTE) or tool.Name
	return WeaponCombatConfig.getConfig(weaponId :: string)
end

function WeaponCombatConfig.usesAnimationSwing(weaponId: string): boolean
	return weaponId == "Broadsword" and BroadswordConfig.USES_ANIMATION
end

function WeaponCombatConfig.usesAnimationSwingForTool(tool: Tool): boolean
	local weaponId = tool:GetAttribute(WeaponConfig.WEAPON_ATTRIBUTE) or tool.Name
	return WeaponCombatConfig.usesAnimationSwing(weaponId :: string)
end

return WeaponCombatConfig
