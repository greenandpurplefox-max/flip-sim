local BroadswordService = require(script.BroadswordService)
local WaveService = require(script.WaveService)

local centerMarker = workspace:FindFirstChild("CenterMarker")
if centerMarker then
	centerMarker:Destroy()
end

BroadswordService.init()
WaveService.init()
