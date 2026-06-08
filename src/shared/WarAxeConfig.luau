local BroadswordPose = require(script.Parent.BroadswordPose)

local WarAxeConfig = {}

local IDENTITY = CFrame.new()

WarAxeConfig.SHOULDER_POSE = {
	rightShoulder = CFrame.Angles(math.rad(-8), math.rad(-14), math.rad(88)),
	rightElbow = CFrame.Angles(math.rad(-38), math.rad(10), math.rad(8)),
	rightWrist = CFrame.Angles(math.rad(14), math.rad(-18), math.rad(10)),
	leftShoulder = IDENTITY,
	leftElbow = IDENTITY,
	leftWrist = IDENTITY,
	grip = CFrame.new(0.02, -0.08, 0.04) * CFrame.Angles(math.rad(96), math.rad(178), math.rad(88)),
}

WarAxeConfig.SHOULDER_GRIP = WarAxeConfig.SHOULDER_POSE.grip

local CHOP_POSE: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(52), math.rad(-18), math.rad(108)),
	rightElbow = CFrame.Angles(math.rad(-12), math.rad(16), math.rad(6)),
	rightWrist = CFrame.Angles(math.rad(-8), math.rad(-10), math.rad(12)),
	leftShoulder = IDENTITY,
	leftElbow = IDENTITY,
	leftWrist = IDENTITY,
	grip = CFrame.new(0.18, -0.22, 0.38) * CFrame.Angles(math.rad(118), math.rad(168), math.rad(82)),
}

WarAxeConfig.SWING_COOLDOWN = 0.48
WarAxeConfig.SWING_DURATION = 0.38
WarAxeConfig.STRIKE_START_RATIO = 0.22
WarAxeConfig.STRIKE_END_RATIO = 0.58

WarAxeConfig.PoseKeyframes = {
	{ time = 0, pose = WarAxeConfig.SHOULDER_POSE },
	{ time = 0.14, pose = CHOP_POSE },
	{ time = 0.38, pose = WarAxeConfig.SHOULDER_POSE },
}

function WarAxeConfig.smoothstep(alpha: number): number
	alpha = math.clamp(alpha, 0, 1)
	return alpha * alpha * (3 - 2 * alpha)
end

function WarAxeConfig.getSwingDuration(): number
	return WarAxeConfig.SWING_DURATION
end

function WarAxeConfig.getPoseForSwing(elapsed: number): BroadswordPose.Pose
	local keyframes = WarAxeConfig.PoseKeyframes
	local time = math.clamp(elapsed, 0, WarAxeConfig.SWING_DURATION)

	for index = 1, #keyframes - 1 do
		local current = keyframes[index]
		local nextKeyframe = keyframes[index + 1]
		if time >= current.time and time <= nextKeyframe.time then
			local span = nextKeyframe.time - current.time
			local alpha = if span > 0 then (time - current.time) / span else 1
			return BroadswordPose.lerp(current.pose, nextKeyframe.pose, WarAxeConfig.smoothstep(alpha))
		end
	end

	return keyframes[#keyframes].pose
end

function WarAxeConfig.isStrikePhase(elapsed: number): boolean
	local progress = elapsed / WarAxeConfig.SWING_DURATION
	return progress >= WarAxeConfig.STRIKE_START_RATIO and progress <= WarAxeConfig.STRIKE_END_RATIO
end

return WarAxeConfig
