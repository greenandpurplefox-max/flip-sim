local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TreasureConfig = require(ReplicatedStorage.Shared.TreasureConfig)

local TreasureChestClient = {}

function TreasureChestClient.init()
	-- Chest opening UI lives in WeaponMenuClient; dungeon pickup text lives in HealthBarUI.
end

return TreasureChestClient
