local BroadswordPose = require(script.Parent.BroadswordPose)

local HalberdConfig = {}

local SHOULDER_GRIP = CFrame.new(0.06, -0.5, 0.12) * CFrame.Angles(math.rad(86), math.rad(176), math.rad(96))
local READY_GRIP = CFrame.new(0.08, -0.44, 0.18) * CFrame.Angles(math.rad(84), math.rad(174), math.rad(98))
local WINDUP_GRIP = CFrame.new(0.42, -0.18, 0.34) * CFrame.Angles(math.rad(72), math.rad(160), math.rad(108))
local STRIKE_GRIP = CFrame.new(0.14, -0.06, 0.58) * CFrame.Angles(math.rad(64), math.rad(168), math.rad(92))
local FOLLOW_GRIP = CFrame.new(-0.18, 0.08, 0.42) * CFrame.Angles(math.rad(98), math.rad(152), math.rad(78))

HalberdConfig.SHOULDER_POSE = {
	rightShoulder = CFrame.Angles(math.rad(-16), math.rad(-8), math.rad(106)),
	rightElbow = CFrame.Angles(math.rad(-50), math.rad(12), math.rad(10)),
	rightWrist = CFrame.Angles(math.rad(10), math.rad(-18), math.rad(12)),
	leftShoulder = CFrame.Angles(math.rad(4), math.rad(18), math.rad(-84)),
	leftElbow = CFrame.Angles(math.rad(-46), math.rad(-8), math.rad(6)),
	leftWrist = CFrame.Angles(math.rad(8), math.rad(20), math.rad(-8)),
	grip = SHOULDER_GRIP,
}

HalberdConfig.SHOULDER_GRIP = SHOULDER_GRIP

local READY_POSE: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(-10), math.rad(-12), math.rad(112)),
	rightElbow = CFrame.Angles(math.rad(-46), math.rad(10), math.rad(8)),
	rightWrist = CFrame.Angles(math.rad(8), math.rad(-16), math.rad(10)),
	leftShoulder = CFrame.Angles(math.rad(10), math.rad(14), math.rad(-88)),
	leftElbow = CFrame.Angles(math.rad(-40), math.rad(-6), math.rad(4)),
	leftWrist = CFrame.Angles(math.rad(6), math.rad(18), math.rad(-6)),
	grip = READY_GRIP,
}

local WINDUP_POSE: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(6), math.rad(-34), math.rad(126)),
	rightElbow = CFrame.Angles(math.rad(-28), math.rad(16), math.rad(10)),
	rightWrist = CFrame.Angles(math.rad(-4), math.rad(-10), math.rad(14)),
	leftShoulder = CFrame.Angles(math.rad(22), math.rad(4), math.rad(-102)),
	leftElbow = CFrame.Angles(math.rad(-24), math.rad(-12), math.rad(2)),
	leftWrist = CFrame.Angles(math.rad(2), math.rad(14), math.rad(-4)),
	grip = WINDUP_GRIP,
}

local STRIKE_POSE: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(34), math.rad(-46), math.rad(138)),
	rightElbow = CFrame.Angles(math.rad(-14), math.rad(18), math.rad(8)),
	rightWrist = CFrame.Angles(math.rad(-8), math.rad(-6), math.rad(12)),
	leftShoulder = CFrame.Angles(math.rad(28), math.rad(-6), math.rad(-112)),
	leftElbow = CFrame.Angles(math.rad(-18), math.rad(-14), math.rad(2)),
	leftWrist = CFrame.Angles(math.rad(-2), math.rad(10), math.rad(-4)),
	grip = STRIKE_GRIP,
}

local FOLLOW_POSE: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(18), math.rad(-54), math.rad(122)),
	rightElbow = CFrame.Angles(math.rad(-20), math.rad(14), math.rad(6)),
	rightWrist = CFrame.Angles(math.rad(-4), math.rad(-4), math.rad(10)),
	leftShoulder = CFrame.Angles(math.rad(14), math.rad(-10), math.rad(-98)),
	leftElbow = CFrame.Angles(math.rad(-22), math.rad(-10), math.rad(2)),
	leftWrist = CFrame.Angles(math.rad(2), math.rad(8), math.rad(-4)),
	grip = FOLLOW_GRIP,
}

HalberdConfig.SWING_COOLDOWN = 0.72
HalberdConfig.SWING_DURATION = 0.68
HalberdConfig.STRIKE_START_RATIO = 0.3
HalberdConfig.STRIKE_END_RATIO = 0.52

HalberdConfig.PoseKeyframes = {
	{ time = 0, pose = HalberdConfig.SHOULDER_POSE },
	{ time = 0.1, pose = READY_POSE },
	{ time = 0.24, pose = WINDUP_POSE },
	{ time = 0.36, pose = STRIKE_POSE },
	{ time = 0.5, pose = FOLLOW_POSE },
	{ time = 0.68, pose = HalberdConfig.SHOULDER_POSE },
}

function HalberdConfig.smoothstep(alpha: number): number
	alpha = math.clamp(alpha, 0, 1)
	return alpha * alpha * (3 - 2 * alpha)
end

function HalberdConfig.easeSegment(alpha: number, sharp: boolean): number
	alpha = math.clamp(alpha, 0, 1)
	if sharp then
		return 1 - (1 - alpha) * (1 - alpha)
	end
	return HalberdConfig.smoothstep(alpha)
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
			local sharp = nextKeyframe.pose == STRIKE_POSE
			return BroadswordPose.lerp(current.pose, nextKeyframe.pose, HalberdConfig.easeSegment(alpha, sharp))
		end
	end

	return keyframes[#keyframes].pose
end

function HalberdConfig.isStrikePhase(elapsed: number): boolean
	local progress = elapsed / HalberdConfig.SWING_DURATION
	return progress >= HalberdConfig.STRIKE_START_RATIO and progress <= HalberdConfig.STRIKE_END_RATIO
end

return HalberdConfig
