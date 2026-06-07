local AnimationOverrideService = require(script.AnimationOverrideService)
local BroadswordService = require(script.BroadswordService)
local WaveService = require(script.WaveService)

local centerMarker = workspace:FindFirstChild("CenterMarker")
if centerMarker then
	centerMarker:Destroy()
end

AnimationOverrideService.init()
BroadswordService.init()
WaveService.init()
