local BroadswordPose = require(script.Parent.BroadswordPose)

local BroadswordConfig = {}

local IDENTITY = CFrame.new()

-- Hilt in the right hand; blade rests on top of the right shoulder.
BroadswordConfig.SHOULDER_POSE = {
	rightShoulder = CFrame.Angles(math.rad(-8), math.rad(18), math.rad(132)),
	rightElbow = CFrame.Angles(math.rad(-72), math.rad(12), math.rad(8)),
	rightWrist = CFrame.Angles(math.rad(18), math.rad(-42), math.rad(36)),
	leftShoulder = IDENTITY,
	leftElbow = IDENTITY,
	leftWrist = IDENTITY,
	grip = CFrame.new(0.06, -0.1, 0.04) * CFrame.Angles(math.rad(92), math.rad(178), math.rad(86)),
}

BroadswordConfig.SHOULDER_GRIP = BroadswordConfig.SHOULDER_POSE.grip

local TWO_HAND_HILT: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(18), math.rad(-8), math.rad(92)),
	rightElbow = CFrame.Angles(math.rad(-58), math.rad(6), math.rad(10)),
	rightWrist = CFrame.Angles(math.rad(8), math.rad(-18), math.rad(12)),
	leftShoulder = CFrame.Angles(math.rad(12), math.rad(18), math.rad(-72)),
	leftElbow = CFrame.Angles(math.rad(-48), math.rad(-8), math.rad(6)),
	leftWrist = CFrame.Angles(math.rad(10), math.rad(22), math.rad(-8)),
	grip = CFrame.new(0.08, -0.34, 0.38) * CFrame.Angles(math.rad(72), math.rad(176), math.rad(94)),
}

local BOTTOM_RIGHT: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(42), math.rad(-24), math.rad(118)),
	rightElbow = CFrame.Angles(math.rad(-28), math.rad(18), math.rad(14)),
	rightWrist = CFrame.Angles(math.rad(-12), math.rad(-8), math.rad(18)),
	leftShoulder = CFrame.Angles(math.rad(36), math.rad(8), math.rad(-96)),
	leftElbow = CFrame.Angles(math.rad(-22), math.rad(-12), math.rad(4)),
	leftWrist = CFrame.Angles(math.rad(-6), math.rad(16), math.rad(-6)),
	grip = CFrame.new(0.72, -0.92, 0.28) * CFrame.Angles(math.rad(-52), math.rad(138), math.rad(118)),
}

local TOP_RIGHT: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(-34), math.rad(-18), math.rad(108)),
	rightElbow = CFrame.Angles(math.rad(-18), math.rad(12), math.rad(8)),
	rightWrist = CFrame.Angles(math.rad(14), math.rad(-6), math.rad(10)),
	leftShoulder = CFrame.Angles(math.rad(-28), math.rad(12), math.rad(-88)),
	leftElbow = CFrame.Angles(math.rad(-12), math.rad(-8), math.rad(2)),
	leftWrist = CFrame.Angles(math.rad(8), math.rad(10), math.rad(-4)),
	grip = CFrame.new(0.66, 0.58, 0.22) * CFrame.Angles(math.rad(88), math.rad(164), math.rad(78)),
}

BroadswordConfig.SWING_COOLDOWN = 0.65
BroadswordConfig.SWING_DURATION = 0.52
BroadswordConfig.STRIKE_START_RATIO = 0.24
BroadswordConfig.STRIKE_END_RATIO = 0.56

BroadswordConfig.PoseKeyframes = {
	{ time = 0, pose = BroadswordConfig.SHOULDER_POSE },
	{ time = 0.08, pose = TWO_HAND_HILT },
	{ time = 0.2, pose = BOTTOM_RIGHT },
	{ time = 0.34, pose = TOP_RIGHT },
	{ time = 0.52, pose = BroadswordConfig.SHOULDER_POSE },
}

function BroadswordConfig.smoothstep(alpha: number): number
	alpha = math.clamp(alpha, 0, 1)
	return alpha * alpha * (3 - 2 * alpha)
end

function BroadswordConfig.getSwingDuration(): number
	return BroadswordConfig.SWING_DURATION
end

function BroadswordConfig.getPoseForSwing(elapsed: number): BroadswordPose.Pose
	local keyframes = BroadswordConfig.PoseKeyframes
	local time = math.clamp(elapsed, 0, BroadswordConfig.SWING_DURATION)

	for index = 1, #keyframes - 1 do
		local current = keyframes[index]
		local nextKeyframe = keyframes[index + 1]
		if time >= current.time and time <= nextKeyframe.time then
			local span = nextKeyframe.time - current.time
			local alpha = if span > 0 then (time - current.time) / span else 1
			return BroadswordPose.lerp(current.pose, nextKeyframe.pose, BroadswordConfig.smoothstep(alpha))
		end
	end

	return keyframes[#keyframes].pose
end

function BroadswordConfig.getGripForSwing(elapsed: number): CFrame
	return BroadswordConfig.getPoseForSwing(elapsed).grip
end

function BroadswordConfig.isStrikePhase(elapsed: number): boolean
	local progress = elapsed / BroadswordConfig.SWING_DURATION
	return progress >= BroadswordConfig.STRIKE_START_RATIO and progress <= BroadswordConfig.STRIKE_END_RATIO
end

return BroadswordConfig
