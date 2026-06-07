local AnimationOverrideService = require(script.AnimationOverrideService)
local BroadswordService = require(script.BroadswordService)
local DashService = require(script.DashService)
local WaveService = require(script.WaveService)

local centerMarker = workspace:FindFirstChild("CenterMarker")
if centerMarker then
	centerMarker:Destroy()
end

AnimationOverrideService.init()
DashService.init()
BroadswordService.init()
WaveService.init()
