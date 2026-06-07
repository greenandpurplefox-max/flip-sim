local BroadswordConfig = {}

-- Idle: broadsword resting on the shoulder.
BroadswordConfig.SHOULDER_GRIP = CFrame.new(0, -0.55, 0.35)
	* CFrame.Angles(math.rad(108), math.rad(180), math.rad(92))

-- Diagonal slash grips: bottom-right (screen space) to top-left.
BroadswordConfig.WINDUP_BOTTOM_RIGHT = CFrame.new(0.58, -0.88, 0.28)
	* CFrame.Angles(math.rad(-42), math.rad(168), math.rad(108))

BroadswordConfig.MID_DIAGONAL = CFrame.new(0.12, -0.22, 0.46)
	* CFrame.Angles(math.rad(38), math.rad(178), math.rad(86))

BroadswordConfig.STRIKE_TOP_LEFT = CFrame.new(-0.64, 0.38, 0.1)
	* CFrame.Angles(math.rad(118), math.rad(-18), math.rad(36))

BroadswordConfig.FOLLOW_THROUGH = CFrame.new(-0.38, 0.08, -0.18)
	* CFrame.Angles(math.rad(92), math.rad(8), math.rad(24))

BroadswordConfig.SWING_COOLDOWN = 0.65
BroadswordConfig.DEFAULT_SWING_DURATION = 0.62
BroadswordConfig.ANIMATION_END_RATIO = 0.58
BroadswordConfig.ANIMATION_FADE_IN = 0.16
BroadswordConfig.ANIMATION_FADE_OUT = 0.22
BroadswordConfig.RECOVERY_DURATION = 0.2
BroadswordConfig.STRIKE_START_RATIO = 0.16
BroadswordConfig.STRIKE_END_RATIO = 0.52

-- Body animation only; the sword arc comes from grip keyframes below.
BroadswordConfig.R15_SLASH_ANIMATIONS = {
	"rbxassetid://846754447",
	"rbxassetid://1029253339",
	"rbxassetid://522635514",
}

BroadswordConfig.R6_SLASH_ANIMATIONS = {
	"rbxassetid://32659706",
	"rbxassetid://129967390",
}

-- Bottom-right to top-left diagonal slash path.
BroadswordConfig.Keyframes = {
	{ time = 0, grip = BroadswordConfig.SHOULDER_GRIP },
	{ time = 0.08, grip = BroadswordConfig.WINDUP_BOTTOM_RIGHT },
	{ time = 0.18, grip = BroadswordConfig.MID_DIAGONAL },
	{ time = 0.3, grip = BroadswordConfig.STRIKE_TOP_LEFT },
	{ time = 0.4, grip = BroadswordConfig.FOLLOW_THROUGH },
	{ time = 0.55, grip = BroadswordConfig.SHOULDER_GRIP },
}

function BroadswordConfig.smoothstep(alpha: number): number
	alpha = math.clamp(alpha, 0, 1)
	return alpha * alpha * (3 - 2 * alpha)
end

function BroadswordConfig.getKeyframeDuration(): number
	return BroadswordConfig.Keyframes[#BroadswordConfig.Keyframes].time
end

function BroadswordConfig.getSwingDuration(useAnimation: boolean, animationLength: number?): number
	if useAnimation and animationLength and animationLength > 0 then
		return animationLength * BroadswordConfig.ANIMATION_END_RATIO
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
			return current.grip:Lerp(nextKeyframe.grip, BroadswordConfig.smoothstep(alpha))
		end
	end

	return keyframes[#keyframes].grip
end

function BroadswordConfig.getGripForSwing(elapsed: number, swingDuration: number, _usesAnimation: boolean): CFrame
	local duration = if swingDuration > 0 then swingDuration else BroadswordConfig.DEFAULT_SWING_DURATION
	local progress = math.clamp(elapsed / duration, 0, 1)
	local sampleTime = progress * BroadswordConfig.getKeyframeDuration()
	return BroadswordConfig.sample(sampleTime)
end

function BroadswordConfig.getRecoveryGrip(recoveryElapsed: number): CFrame
	local alpha = BroadswordConfig.smoothstep(recoveryElapsed / BroadswordConfig.RECOVERY_DURATION)
	local endGrip = BroadswordConfig.FOLLOW_THROUGH
	return endGrip:Lerp(BroadswordConfig.SHOULDER_GRIP, alpha)
end

function BroadswordConfig.isStrikePhase(elapsed: number, swingDuration: number): boolean
	local duration = if swingDuration > 0 then swingDuration else BroadswordConfig.DEFAULT_SWING_DURATION
	local progress = elapsed / duration
	return progress >= BroadswordConfig.STRIKE_START_RATIO and progress <= BroadswordConfig.STRIKE_END_RATIO
end

return BroadswordConfig
