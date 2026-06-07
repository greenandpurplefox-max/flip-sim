local BroadswordConfig = require(script.Parent.BroadswordConfig)
local RapierConfig = require(script.Parent.RapierConfig)
local WeaponConfig = require(script.Parent.WeaponConfig)

local WeaponCombatConfig = {}

function WeaponCombatConfig.getConfig(weaponId: string)
	if weaponId == "Rapier" then
		return RapierConfig
	end
	return BroadswordConfig
end

function WeaponCombatConfig.getConfigForTool(tool: Tool)
	local weaponId = tool:GetAttribute(WeaponConfig.WEAPON_ATTRIBUTE) or tool.Name
	return WeaponCombatConfig.getConfig(weaponId :: string)
end

return WeaponCombatConfig
