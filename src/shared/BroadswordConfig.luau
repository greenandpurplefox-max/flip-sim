local BroadswordConfig = {}

-- Idle: broadsword resting on the shoulder, still gripped in hand.
BroadswordConfig.SHOULDER_GRIP = CFrame.new(0, -0.55, 0.35)
	* CFrame.Angles(math.rad(108), math.rad(180), math.rad(92))

-- Forward combat grip used while a full-body slash animation plays.
BroadswordConfig.COMBAT_GRIP = CFrame.new(0, -0.42, 0.48)
	* CFrame.Angles(math.rad(82), math.rad(175), math.rad(96))

BroadswordConfig.SWING_COOLDOWN = 0.65
BroadswordConfig.DEFAULT_SWING_DURATION = 0.72
BroadswordConfig.STRIKE_START_RATIO = 0.14
BroadswordConfig.STRIKE_END_RATIO = 0.58

-- Full-body slash animations, tried in order until one loads.
-- R15: community sword swings first, then official Roblox tool slash.
BroadswordConfig.R15_SLASH_ANIMATIONS = {
	"rbxassetid://846754447",
	"rbxassetid://1029253339",
	"rbxassetid://522635514",
}

-- R6: classic two-handed swing, then Roblox tool slash fallback.
BroadswordConfig.R6_SLASH_ANIMATIONS = {
	"rbxassetid://32659706",
	"rbxassetid://129967390",
}

-- Fallback grip-only swing when no animation asset loads.
BroadswordConfig.Keyframes = {
	{ time = 0, grip = BroadswordConfig.SHOULDER_GRIP },
	{
		time = 0.1,
		grip = CFrame.new(0, -0.35, 0.55) * CFrame.Angles(math.rad(25), math.rad(178), math.rad(98)),
	},
	{
		time = 0.2,
		grip = CFrame.new(0.3, -0.1, 0.42) * CFrame.Angles(math.rad(150), math.rad(-15), math.rad(168)),
	},
	{
		time = 0.32,
		grip = CFrame.new(-0.05, -0.72, -0.42) * CFrame.Angles(math.rad(-28), math.rad(92), math.rad(-8)),
	},
	{
		time = 0.42,
		grip = CFrame.new(-0.42, -0.92, 0.08) * CFrame.Angles(math.rad(22), math.rad(138), math.rad(32)),
	},
	{ time = 0.58, grip = BroadswordConfig.SHOULDER_GRIP },
}

function BroadswordConfig.getKeyframeDuration(): number
	return BroadswordConfig.Keyframes[#BroadswordConfig.Keyframes].time
end

function BroadswordConfig.getSwingDuration(useAnimation: boolean, animationLength: number?): number
	if useAnimation and animationLength and animationLength > 0 then
		return animationLength
	end
	return BroadswordConfig.DEFAULT_SWING_DURATION
end

function BroadswordConfig.sample(elapsed: number): CFrame
	local keyframes = BroadswordConfig.Keyframes
	local time = math.clamp(elapsed, 0, BroadswordConfig.getKeyframeDuration())

	for index = 1, #keyframes - 1 do
		local current = keyframes[index]
		local nextKeyframe = keyframes[index + 1]
		if time >= current.time and time <= nextKeyframe.time then
			local span = nextKeyframe.time - current.time
			local alpha = if span > 0 then (time - current.time) / span else 1
			return current.grip:Lerp(nextKeyframe.grip, alpha)
		end
	end

	return keyframes[#keyframes].grip
end

function BroadswordConfig.isStrikePhase(elapsed: number, swingDuration: number): boolean
	local duration = if swingDuration > 0 then swingDuration else BroadswordConfig.DEFAULT_SWING_DURATION
	local progress = elapsed / duration
	return progress >= BroadswordConfig.STRIKE_START_RATIO and progress <= BroadswordConfig.STRIKE_END_RATIO
end

return BroadswordConfig
