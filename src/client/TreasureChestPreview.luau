local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TreasureConfig = require(ReplicatedStorage.Shared.TreasureConfig)

local TreasureChestPreview = {}

local function buildChestModel(tierId: string): Model
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
	trim.Size = Vector3.new(3.35, 0.28, 2.55)
	trim.Color = tier.trimColor
	trim.Material = Enum.Material.Metal
	trim.Anchored = true
	trim.CanCollide = false
	trim.CFrame = base.CFrame * CFrame.new(0, 0.72, 0)
	trim.Parent = model

	local lid = Instance.new("Part")
	lid.Size = Vector3.new(3.2, 0.85, 2.4)
	lid.Color = tier.bodyColor
	lid.Material = Enum.Material.Wood
	lid.Anchored = true
	lid.CanCollide = false
	lid.CFrame = base.CFrame * CFrame.new(0, 1.05, -0.35)
	lid.Parent = model

	local glow = Instance.new("Part")
	glow.Size = Vector3.new(2.4, 0.12, 1.8)
	glow.Color = tier.glowColor
	glow.Material = Enum.Material.Neon
	glow.Anchored = true
	glow.CanCollide = false
	glow.Transparency = 0.35
	glow.CFrame = base.CFrame * CFrame.new(0, 1.55, 0)
	glow.Parent = model

	model.PrimaryPart = base
	return model
end

function TreasureChestPreview.mount(parent: Instance, tierId: string, size: number): ViewportFrame
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.fromOffset(size, size)
	viewport.BackgroundTransparency = 1
	viewport.Parent = parent

	local model = buildChestModel(tierId)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	model:PivotTo(CFrame.Angles(0, math.rad(28), math.rad(-12)))
	model.Parent = viewport

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(5, 3.5, 5), model:GetPivot().Position)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	return viewport
end

return TreasureChestPreview
