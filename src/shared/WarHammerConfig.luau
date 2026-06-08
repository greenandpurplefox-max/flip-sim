local BroadswordPose = require(script.Parent.BroadswordPose)

local WarHammerConfig = {}

local IDENTITY = CFrame.new()

WarHammerConfig.SHOULDER_POSE = {
	rightShoulder = CFrame.Angles(math.rad(-16), math.rad(12), math.rad(102)),
	rightElbow = CFrame.Angles(math.rad(-48), math.rad(6), math.rad(12)),
	rightWrist = CFrame.Angles(math.rad(18), math.rad(-22), math.rad(14)),
	leftShoulder = CFrame.Angles(math.rad(10), math.rad(18), math.rad(-78)),
	leftElbow = CFrame.Angles(math.rad(-42), math.rad(-8), math.rad(6)),
	leftWrist = CFrame.Angles(math.rad(8), math.rad(20), math.rad(-8)),
	grip = CFrame.new(0.06, -0.28, 0.12) * CFrame.Angles(math.rad(98), math.rad(178), math.rad(92)),
}

WarHammerConfig.SHOULDER_GRIP = WarHammerConfig.SHOULDER_POSE.grip

local SMASH_POSE: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(58), math.rad(-8), math.rad(124)),
	rightElbow = CFrame.Angles(math.rad(-8), math.rad(18), math.rad(8)),
	rightWrist = CFrame.Angles(math.rad(-12), math.rad(-6), math.rad(16)),
	leftShoulder = CFrame.Angles(math.rad(42), math.rad(10), math.rad(-98)),
	leftElbow = CFrame.Angles(math.rad(-18), math.rad(-12), math.rad(4)),
	leftWrist = CFrame.Angles(math.rad(-4), math.rad(14), math.rad(-6)),
	grip = CFrame.new(0.22, -0.04, 0.46) * CFrame.Angles(math.rad(132), math.rad(168), math.rad(78)),
}

WarHammerConfig.SWING_COOLDOWN = 0.95
WarHammerConfig.SWING_DURATION = 0.72
WarHammerConfig.STRIKE_START_RATIO = 0.34
WarHammerConfig.STRIKE_END_RATIO = 0.58

WarHammerConfig.PoseKeyframes = {
	{ time = 0, pose = WarHammerConfig.SHOULDER_POSE },
	{ time = 0.24, pose = SMASH_POSE },
	{ time = 0.72, pose = WarHammerConfig.SHOULDER_POSE },
}

function WarHammerConfig.smoothstep(alpha: number): number
	alpha = math.clamp(alpha, 0, 1)
	return alpha * alpha * (3 - 2 * alpha)
end

function WarHammerConfig.getSwingDuration(): number
	return WarHammerConfig.SWING_DURATION
end

function WarHammerConfig.getPoseForSwing(elapsed: number): BroadswordPose.Pose
	local keyframes = WarHammerConfig.PoseKeyframes
	local time = math.clamp(elapsed, 0, WarHammerConfig.SWING_DURATION)

	for index = 1, #keyframes - 1 do
		local current = keyframes[index]
		local nextKeyframe = keyframes[index + 1]
		if time >= current.time and time <= nextKeyframe.time then
			local span = nextKeyframe.time - current.time
			local alpha = if span > 0 then (time - current.time) / span else 1
			return BroadswordPose.lerp(current.pose, nextKeyframe.pose, WarHammerConfig.smoothstep(alpha))
		end
	end

	return keyframes[#keyframes].pose
end

function WarHammerConfig.isStrikePhase(elapsed: number): boolean
	local progress = elapsed / WarHammerConfig.SWING_DURATION
	return progress >= WarHammerConfig.STRIKE_START_RATIO and progress <= WarHammerConfig.STRIKE_END_RATIO
end

return WarHammerConfig
