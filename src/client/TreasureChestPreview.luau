local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TreasureConfig = require(ReplicatedStorage.Shared.TreasureConfig)

local TreasureChestPreview = {}

export type ChestModelParts = {
	model: Model,
	base: BasePart,
	lid: BasePart,
	trim: BasePart,
	glow: BasePart,
	lidClosedCFrame: CFrame,
	lidOpenCFrame: CFrame,
}

function TreasureChestPreview.buildChestModel(tierId: string): ChestModelParts
	local tier = TreasureConfig.getTier(tierId)
	local model = Instance.new("Model")
	model.Name = "PreviewChest"

	local base = Instance.new("Part")
	base.Name = "ChestBase"
	base.Size = Vector3.new(3.2, 1.6, 2.4)
	base.Color = tier.bodyColor
	base.Material = Enum.Material.Wood
	base.Anchored = true
	base.CanCollide = false
	base.CFrame = CFrame.new(0, 0, 0)
	base.Parent = model

	local trim = Instance.new("Part")
	trim.Name = "ChestTrim"
	trim.Size = Vector3.new(3.35, 0.28, 2.55)
	trim.Color = tier.trimColor
	trim.Material = Enum.Material.Metal
	trim.Anchored = true
	trim.CanCollide = false
	trim.CFrame = base.CFrame * CFrame.new(0, 0.72, 0)
	trim.Parent = model

	local lid = Instance.new("Part")
	lid.Name = "ChestLid"
	lid.Size = Vector3.new(3.2, 0.85, 2.4)
	lid.Color = tier.bodyColor
	lid.Material = Enum.Material.Wood
	lid.Anchored = true
	lid.CanCollide = false
	local lidClosedCFrame = base.CFrame * CFrame.new(0, 1.05, -0.35)
	lid.CFrame = lidClosedCFrame
	lid.Parent = model

	local glow = Instance.new("Part")
	glow.Name = "ChestGlow"
	glow.Size = Vector3.new(2.4, 0.12, 1.8)
	glow.Color = tier.glowColor
	glow.Material = Enum.Material.Neon
	glow.Anchored = true
	glow.CanCollide = false
	glow.Transparency = 0.35
	glow.CFrame = base.CFrame * CFrame.new(0, 1.55, 0)
	glow.Parent = model

	local lidOpenCFrame = lidClosedCFrame * CFrame.new(0, 0.18, -0.62) * CFrame.Angles(math.rad(-118), 0, 0)

	model.PrimaryPart = base
	return {
		model = model,
		base = base,
		lid = lid,
		trim = trim,
		glow = glow,
		lidClosedCFrame = lidClosedCFrame,
		lidOpenCFrame = lidOpenCFrame,
	}
end

function TreasureChestPreview.mount(parent: Instance, tierId: string, size: number): ViewportFrame
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.fromOffset(size, size)
	viewport.BackgroundTransparency = 1
	viewport.Parent = parent

	local parts = TreasureChestPreview.buildChestModel(tierId)
	local model = parts.model
	model:PivotTo(CFrame.Angles(0, math.rad(28), math.rad(-12)))
	model.Parent = viewport

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(5, 3.5, 5), model:GetPivot().Position)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	return viewport
end

return TreasureChestPreview
