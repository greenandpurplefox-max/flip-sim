local Players = game:GetService("Players")

local AnimationOverrideService = {}

local DEFAULT_R15_ANIMATIONS = {
	IdleAnimation = 507766666,
	WalkAnimation = 913402848,
	RunAnimation = 913376220,
	JumpAnimation = 507765000,
	FallAnimation = 507767968,
	ClimbAnimation = 913143516,
	SwimAnimation = 913384386,
}

local DEFAULT_R6_ANIMATIONS = {
	IdleAnimation = 180435571,
	WalkAnimation = 180426354,
	RunAnimation = 180426354,
	JumpAnimation = 180436148,
	FallAnimation = 180436148,
	ClimbAnimation = 180436334,
	SwimAnimation = 180435792,
}

local function applyDefaultAnimations(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local description = humanoid:GetAppliedDescription()
	local defaults = if character:FindFirstChild("UpperTorso") then DEFAULT_R15_ANIMATIONS else DEFAULT_R6_ANIMATIONS

	description.IdleAnimation = defaults.IdleAnimation
	description.WalkAnimation = defaults.WalkAnimation
	description.RunAnimation = defaults.RunAnimation
	description.JumpAnimation = defaults.JumpAnimation
	description.FallAnimation = defaults.FallAnimation
	description.ClimbAnimation = defaults.ClimbAnimation
	description.SwimAnimation = defaults.SwimAnimation

	humanoid:ApplyDescription(description)
end

function AnimationOverrideService.init()
	for _, player in Players:GetPlayers() do
		player.CharacterAppearanceLoaded:Connect(applyDefaultAnimations)

		if player.Character then
			task.defer(applyDefaultAnimations, player.Character)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAppearanceLoaded:Connect(applyDefaultAnimations)
	end)
end

return AnimationOverrideService
