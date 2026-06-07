local BroadswordPose = require(script.Parent.BroadswordPose)

local RapierConfig = {}

local IDENTITY = CFrame.new()

RapierConfig.SHOULDER_POSE = {
	rightShoulder = CFrame.Angles(math.rad(-4), math.rad(-18), math.rad(82)),
	rightElbow = CFrame.Angles(math.rad(-32), math.rad(8), math.rad(6)),
	rightWrist = CFrame.Angles(math.rad(10), math.rad(-24), math.rad(12)),
	leftShoulder = IDENTITY,
	leftElbow = IDENTITY,
	leftWrist = IDENTITY,
	grip = CFrame.new(0.04, -0.06, 0.06) * CFrame.Angles(math.rad(94), math.rad(178), math.rad(90)),
}

RapierConfig.SHOULDER_GRIP = RapierConfig.SHOULDER_POSE.grip

local THRUST_POSE: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(18), math.rad(-8), math.rad(96)),
	rightElbow = CFrame.Angles(math.rad(-8), math.rad(12), math.rad(4)),
	rightWrist = CFrame.Angles(math.rad(-4), math.rad(-6), math.rad(8)),
	leftShoulder = IDENTITY,
	leftElbow = IDENTITY,
	leftWrist = IDENTITY,
	grip = CFrame.new(0.08, -0.12, -0.42) * CFrame.Angles(math.rad(88), math.rad(178), math.rad(92)),
}

RapierConfig.SWING_COOLDOWN = 0.2
RapierConfig.SWING_DURATION = 0.28
RapierConfig.STRIKE_START_RATIO = 0.18
RapierConfig.STRIKE_END_RATIO = 0.62

RapierConfig.PoseKeyframes = {
	{ time = 0, pose = RapierConfig.SHOULDER_POSE },
	{ time = 0.12, pose = THRUST_POSE },
	{ time = 0.28, pose = RapierConfig.SHOULDER_POSE },
}

function RapierConfig.smoothstep(alpha: number): number
	alpha = math.clamp(alpha, 0, 1)
	return alpha * alpha * (3 - 2 * alpha)
end

function RapierConfig.getSwingDuration(): number
	return RapierConfig.SWING_DURATION
end

function RapierConfig.getPoseForSwing(elapsed: number): BroadswordPose.Pose
	local keyframes = RapierConfig.PoseKeyframes
	local time = math.clamp(elapsed, 0, RapierConfig.SWING_DURATION)

	for index = 1, #keyframes - 1 do
		local current = keyframes[index]
		local nextKeyframe = keyframes[index + 1]
		if time >= current.time and time <= nextKeyframe.time then
			local span = nextKeyframe.time - current.time
			local alpha = if span > 0 then (time - current.time) / span else 1
			return BroadswordPose.lerp(current.pose, nextKeyframe.pose, RapierConfig.smoothstep(alpha))
		end
	end

	return keyframes[#keyframes].pose
end

function RapierConfig.isStrikePhase(elapsed: number): boolean
	local progress = elapsed / RapierConfig.SWING_DURATION
	return progress >= RapierConfig.STRIKE_START_RATIO and progress <= RapierConfig.STRIKE_END_RATIO
end

return RapierConfig
