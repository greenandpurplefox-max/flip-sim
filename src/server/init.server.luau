local AnimationOverrideService = require(script.AnimationOverrideService)
local DashService = require(script.DashService)
local WaveService = require(script.WaveService)
local WeaponService = require(script.WeaponService)

local centerMarker = workspace:FindFirstChild("CenterMarker")
if centerMarker then
	centerMarker:Destroy()
end

AnimationOverrideService.init()
DashService.init()
WaveService.init()
WeaponService.init()
