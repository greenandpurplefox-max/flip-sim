local AnimationOverrideService = require(script.AnimationOverrideService)
local CardService = require(script.CardService)
local DashService = require(script.DashService)
local DungeonRunService = require(script.DungeonRunService)
local WaveService = require(script.WaveService)
local WeaponService = require(script.WeaponService)

local centerMarker = workspace:FindFirstChild("CenterMarker")
if centerMarker then
	centerMarker:Destroy()
end

AnimationOverrideService.init()
DashService.init()
WaveService.init()
CardService.init()
WeaponService.init()
DungeonRunService.init()
