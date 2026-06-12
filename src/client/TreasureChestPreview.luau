local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TreasureConfig = require(ReplicatedStorage.Shared.TreasureConfig)

local TreasureChestPreview = {}

local COMMON_BODY = Color3.fromRGB(98, 62, 34)
local COMMON_BODY_DARK = Color3.fromRGB(72, 44, 24)
local COMMON_TRIM = Color3.fromRGB(156, 118, 58)

export type ChestModelParts = {
	model: Model,
	base: BasePart,
	lid: BasePart,
	trim: BasePart,
	glow: BasePart,
	innerGold: BasePart?,
	interiorCFrame: CFrame?,
	lidClosedCFrame: CFrame,
	lidOpenCFrame: CFrame,
}

local function addPart(
	model: Model,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	options: {
		material: Enum.Material?,
		shape: Enum.PartType?,
		transparency: number?,
	}?
): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = if options and options.material then options.material else Enum.Material.SmoothPlastic
	part.Shape = if options and options.shape then options.shape else Enum.PartType.Block
	part.Transparency = if options and options.transparency then options.transparency else 0
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = cframe
	part.Parent = model
	return part
end

local function weld(part0: BasePart, part1: BasePart)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = part0
	weldConstraint.Part1 = part1
	weldConstraint.Parent = part0
end

local function buildClassicChestModel(tier: typeof(TreasureConfig.TIERS.Common), model: Model): ChestModelParts
	local base = addPart(model, "ChestBase", Vector3.new(3.2, 1.6, 2.4), CFrame.new(), tier.bodyColor, {
		material = Enum.Material.Wood,
	})

	local trim = addPart(
		model,
		"ChestTrim",
		Vector3.new(3.35, 0.28, 2.55),
		base.CFrame * CFrame.new(0, 0.72, 0),
		tier.trimColor,
		{ material = Enum.Material.Metal }
	)

	local lid = addPart(
		model,
		"ChestLid",
		Vector3.new(3.2, 0.85, 2.4),
		base.CFrame * CFrame.new(0, 1.05, -0.35),
		tier.bodyColor,
		{ material = Enum.Material.Wood }
	)
	local lidClosedCFrame = lid.CFrame
	local lidOpenCFrame = lidClosedCFrame * CFrame.new(0, 0.18, -0.62) * CFrame.Angles(math.rad(-118), 0, 0)

	local glow = addPart(
		model,
		"ChestGlow",
		Vector3.new(2.4, 0.12, 1.8),
		base.CFrame * CFrame.new(0, 1.55, 0),
		tier.glowColor,
		{ material = Enum.Material.Neon, transparency = 0.35 }
	)

	model.PrimaryPart = base
	return {
		model = model,
		base = base,
		lid = lid,
		trim = trim,
		glow = glow,
		innerGold = nil,
		interiorCFrame = nil,
		lidClosedCFrame = lidClosedCFrame,
		lidOpenCFrame = lidOpenCFrame,
	}
end

local function buildCommonChestModel(tier: typeof(TreasureConfig.TIERS.Common), model: Model): ChestModelParts
	local base = addPart(model, "ChestBase", Vector3.new(3.1, 1.45, 2.35), CFrame.new(), COMMON_BODY, {
		material = Enum.Material.Wood,
	})

	addPart(
		model,
		"ChestInnerWall",
		Vector3.new(2.7, 1.05, 2.0),
		base.CFrame * CFrame.new(0, 0.12, 0),
		COMMON_BODY_DARK,
		{ material = Enum.Material.Wood, transparency = 0.08 }
	)

	local trim = addPart(
		model,
		"ChestTrim",
		Vector3.new(3.22, 0.22, 2.48),
		base.CFrame * CFrame.new(0, 0.66, 0),
		COMMON_TRIM,
		{ material = Enum.Material.Metal }
	)

	addPart(
		model,
		"ChestBandFront",
		Vector3.new(3.12, 0.14, 0.12),
		base.CFrame * CFrame.new(0, 0.18, 1.18),
		COMMON_TRIM,
		{ material = Enum.Material.Metal }
	)

	addPart(
		model,
		"ChestBandBack",
		Vector3.new(3.12, 0.14, 0.12),
		base.CFrame * CFrame.new(0, 0.18, -1.18),
		COMMON_TRIM,
		{ material = Enum.Material.Metal }
	)

	local hinge = addPart(
		model,
		"ChestHinge",
		Vector3.new(3.05, 0.16, 0.28),
		base.CFrame * CFrame.new(0, 0.78, -1.02),
		COMMON_TRIM,
		{ material = Enum.Material.Metal }
	)

	local lidClosedCFrame = hinge.CFrame * CFrame.new(0, 0.72, 0.42) * CFrame.Angles(0, 0, 0)
	local lid = addPart(
		model,
		"ChestLid",
		Vector3.new(3.15, 1.35, 2.45),
		lidClosedCFrame,
		COMMON_BODY,
		{ material = Enum.Material.Wood, shape = Enum.PartType.Ball }
	)

	local lidTrim = addPart(
		model,
		"LidTrim",
		Vector3.new(3.18, 0.12, 2.5),
		lidClosedCFrame * CFrame.new(0, -0.42, 0.02),
		COMMON_TRIM,
		{ material = Enum.Material.Metal }
	)
	weld(lid, lidTrim)

	local lidOpenCFrame = lidClosedCFrame * CFrame.new(0, 0.12, -0.58) * CFrame.Angles(math.rad(-125), 0, 0)

	local interiorCFrame = base.CFrame * CFrame.new(0, 0.52, 0.08)

	local innerGold = addPart(
		model,
		"InnerGold",
		Vector3.new(2.55, 0.14, 1.85),
		base.CFrame * CFrame.new(0, 0.28, 0.04),
		tier.glowColor,
		{ material = Enum.Material.Neon, transparency = 1 }
	)

	addPart(
		model,
		"InnerGoldRim",
		Vector3.new(2.62, 0.06, 1.92),
		innerGold.CFrame * CFrame.new(0, 0.08, 0),
		Color3.fromRGB(255, 220, 120),
		{ material = Enum.Material.Neon, transparency = 1 }
	)

	local innerLight = Instance.new("PointLight")
	innerLight.Name = "InnerGoldLight"
	innerLight.Color = tier.glowColor
	innerLight.Brightness = 0
	innerLight.Range = 5
	innerLight.Parent = innerGold

	model.PrimaryPart = base
	return {
		model = model,
		base = base,
		lid = lid,
		trim = trim,
		glow = innerGold,
		innerGold = innerGold,
		interiorCFrame = interiorCFrame,
		lidClosedCFrame = lidClosedCFrame,
		lidOpenCFrame = lidOpenCFrame,
	}
end

function TreasureChestPreview.buildChestModel(tierId: string): ChestModelParts
	local tier = TreasureConfig.getTier(tierId)
	local model = Instance.new("Model")
	model.Name = "PreviewChest"

	if tierId == "Common" then
		return buildCommonChestModel(tier, model)
	end

	return buildClassicChestModel(tier, model)
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
