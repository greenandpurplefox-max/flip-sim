local UiCorner = {}

function UiCorner.apply(parent: Instance, radius: number | UDim): UICorner
	local udim: UDim = if typeof(radius) == "number" then UDim.new(0, radius) else radius

	local corner = Instance.new("UICorner")
	corner.TopLeftRadius = udim
	corner.TopRightRadius = udim
	corner.BottomRightRadius = udim
	corner.BottomLeftRadius = udim
	corner.Parent = parent
	return corner
end

return UiCorner
