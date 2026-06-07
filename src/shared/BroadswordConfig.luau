local BroadswordConfig = {}

-- Resting: broadsword on the shoulder.
BroadswordConfig.SHOULDER_GRIP = CFrame.new(0, -0.55, 0.35)
	* CFrame.Angles(math.rad(108), math.rad(180), math.rad(92))

-- Both hands grab the hilt in front of the body.
BroadswordConfig.TWO_HAND_HILT = CFrame.new(0.04, -0.34, 0.46)
	* CFrame.Angles(math.rad(72), math.rad(178), math.rad(94))

-- Windup: bottom-right of the body.
BroadswordConfig.BOTTOM_RIGHT = CFrame.new(0.62, -0.94, 0.24)
	* CFrame.Angles(math.rad(-38), math.rad(164), math.rad(106))

-- Strike: top-left of the body.
BroadswordConfig.TOP_LEFT = CFrame.new(-0.68, 0.4, 0.1)
	* CFrame.Angles(math.rad(114), math.rad(-20), math.rad(34))

BroadswordConfig.SWING_COOLDOWN = 0.65
BroadswordConfig.SWING_DURATION = 0.5
BroadswordConfig.STRIKE_START_RATIO = 0.22
BroadswordConfig.STRIKE_END_RATIO = 0.58
BroadswordConfig.TWO_HAND_START = 0.05
BroadswordConfig.TWO_HAND_END = 0.42

-- Shoulder -> grab hilt -> bottom-right -> top-left -> shoulder.
BroadswordConfig.Keyframes = {
	{ time = 0, grip = BroadswordConfig.SHOULDER_GRIP },
	{ time = 0.08, grip = BroadswordConfig.TWO_HAND_HILT },
	{ time = 0.18, grip = BroadswordConfig.BOTTOM_RIGHT },
	{ time = 0.32, grip = BroadswordConfig.TOP_LEFT },
	{ time = 0.5, grip = BroadswordConfig.SHOULDER_GRIP },
}

BroadswordConfig.BodyKeyframes = {
	{ time = 0, offset = CFrame.new() },
	{ time = 0.08, offset = CFrame.Angles(math.rad(-4), math.rad(-8), math.rad(-4)) },
	{ time = 0.18, offset = CFrame.Angles(math.rad(-10), math.rad(-36), math.rad(-14)) },
	{ time = 0.32, offset = CFrame.Angles(math.rad(12), math.rad(44), math.rad(18)) },
	{ time = 0.5, offset = CFrame.new() },
}

BroadswordConfig.LEFT_HAND_GRIP_OFFSET = CFrame.new(-0.22, -0.28, 0.06)
	* CFrame.Angles(math.rad(8), math.rad(90), math.rad(-12))

function BroadswordConfig.smoothstep(alpha: number): number
	alpha = math.clamp(alpha, 0, 1)
	return alpha * alpha * (3 - 2 * alpha)
end

function BroadswordConfig.getSwingDuration(): number
	return BroadswordConfig.SWING_DURATION
end

local function sampleKeyframes(keyframes: { { time: number, grip: CFrame? , offset: CFrame? } }, elapsed: number, duration: number): CFrame
	local time = math.clamp(elapsed, 0, duration)

	for index = 1, #keyframes - 1 do
		local current = keyframes[index]
		local nextKeyframe = keyframes[index + 1]
		if time >= current.time and time <= nextKeyframe.time then
			local span = nextKeyframe.time - current.time
			local alpha = if span > 0 then (time - current.time) / span else 1
			local currentValue = current.grip or current.offset :: CFrame
			local nextValue = nextKeyframe.grip or nextKeyframe.offset :: CFrame
			return currentValue:Lerp(nextValue, BroadswordConfig.smoothstep(alpha))
		end
	end

	local last = keyframes[#keyframes]
	return last.grip or last.offset :: CFrame
end

function BroadswordConfig.getGripForSwing(elapsed: number): CFrame
	return sampleKeyframes(BroadswordConfig.Keyframes, elapsed, BroadswordConfig.SWING_DURATION)
end

function BroadswordConfig.getBodyOffset(elapsed: number): CFrame
	return sampleKeyframes(BroadswordConfig.BodyKeyframes, elapsed, BroadswordConfig.SWING_DURATION)
end

function BroadswordConfig.isStrikePhase(elapsed: number): boolean
	local progress = elapsed / BroadswordConfig.SWING_DURATION
	return progress >= BroadswordConfig.STRIKE_START_RATIO and progress <= BroadswordConfig.STRIKE_END_RATIO
end

function BroadswordConfig.isTwoHandPhase(elapsed: number): boolean
	return elapsed >= BroadswordConfig.TWO_HAND_START and elapsed <= BroadswordConfig.TWO_HAND_END
end

return BroadswordConfig
