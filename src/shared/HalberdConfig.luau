local BroadswordPose = require(script.Parent.BroadswordPose)

local HalberdConfig = {}

local IDENTITY = CFrame.new()

HalberdConfig.SHOULDER_POSE = {
	rightShoulder = CFrame.Angles(math.rad(-12), math.rad(-10), math.rad(94)),
	rightElbow = CFrame.Angles(math.rad(-42), math.rad(8), math.rad(6)),
	rightWrist = CFrame.Angles(math.rad(8), math.rad(-20), math.rad(8)),
	leftShoulder = CFrame.Angles(math.rad(8), math.rad(14), math.rad(-68)),
	leftElbow = CFrame.Angles(math.rad(-36), math.rad(-6), math.rad(4)),
	leftWrist = CFrame.Angles(math.rad(6), math.rad(18), math.rad(-6)),
	grip = CFrame.new(0.04, -0.42, 0.08) * CFrame.Angles(math.rad(92), math.rad(178), math.rad(90)),
}

HalberdConfig.SHOULDER_GRIP = HalberdConfig.SHOULDER_POSE.grip

local SWEEP_POSE: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(24), math.rad(-28), math.rad(118)),
	rightElbow = CFrame.Angles(math.rad(-18), math.rad(14), math.rad(8)),
	rightWrist = CFrame.Angles(math.rad(-6), math.rad(-8), math.rad(10)),
	leftShoulder = CFrame.Angles(math.rad(18), math.rad(6), math.rad(-92)),
	leftElbow = CFrame.Angles(math.rad(-22), math.rad(-10), math.rad(2)),
	leftWrist = CFrame.Angles(math.rad(4), math.rad(12), math.rad(-4)),
	grip = CFrame.new(0.12, -0.08, 0.52) * CFrame.Angles(math.rad(78), math.rad(168), math.rad(96)),
}

HalberdConfig.SWING_COOLDOWN = 0.72
HalberdConfig.SWING_DURATION = 0.56
HalberdConfig.STRIKE_START_RATIO = 0.28
HalberdConfig.STRIKE_END_RATIO = 0.62

HalberdConfig.PoseKeyframes = {
	{ time = 0, pose = HalberdConfig.SHOULDER_POSE },
	{ time = 0.18, pose = SWEEP_POSE },
	{ time = 0.56, pose = HalberdConfig.SHOULDER_POSE },
}

function HalberdConfig.smoothstep(alpha: number): number
	alpha = math.clamp(alpha, 0, 1)
	return alpha * alpha * (3 - 2 * alpha)
end

function HalberdConfig.getSwingDuration(): number
	return HalberdConfig.SWING_DURATION
end

function HalberdConfig.getPoseForSwing(elapsed: number): BroadswordPose.Pose
	local keyframes = HalberdConfig.PoseKeyframes
	local time = math.clamp(elapsed, 0, HalberdConfig.SWING_DURATION)

	for index = 1, #keyframes - 1 do
		local current = keyframes[index]
		local nextKeyframe = keyframes[index + 1]
		if time >= current.time and time <= nextKeyframe.time then
			local span = nextKeyframe.time - current.time
			local alpha = if span > 0 then (time - current.time) / span else 1
			return BroadswordPose.lerp(current.pose, nextKeyframe.pose, HalberdConfig.smoothstep(alpha))
		end
	end

	return keyframes[#keyframes].pose
end

function HalberdConfig.isStrikePhase(elapsed: number): boolean
	local progress = elapsed / HalberdConfig.SWING_DURATION
	return progress >= HalberdConfig.STRIKE_START_RATIO and progress <= HalberdConfig.STRIKE_END_RATIO
end

return HalberdConfig
