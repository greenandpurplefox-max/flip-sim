local Players = game:GetService("Players")

local AnimationOverrideService = {}

local function clearAnimationPacks(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local description = humanoid:GetAppliedDescription()
	description.IdleAnimation = 0
	description.WalkAnimation = 0
	description.RunAnimation = 0
	description.JumpAnimation = 0
	description.FallAnimation = 0
	description.ClimbAnimation = 0
	description.SwimAnimation = 0

	local ok, err = pcall(function()
		humanoid:ApplyDescription(description)
	end)

	if not ok then
		warn(`Failed to clear animation packs: {err}`)
	end
end

function AnimationOverrideService.init()
	local function onCharacter(character: Model)
		task.defer(clearAnimationPacks, character)
	end

	for _, player in Players:GetPlayers() do
		player.CharacterAppearanceLoaded:Connect(onCharacter)
		if player.Character then
			onCharacter(player.Character)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAppearanceLoaded:Connect(onCharacter)
	end)
end

return AnimationOverrideService
