local BroadswordPose = require(script.Parent.BroadswordPose)

local WarAxeConfig = {}

local IDENTITY = CFrame.new()

local SHOULDER_GRIP = CFrame.new(0.04, -0.12, 0.06) * CFrame.Angles(math.rad(94), math.rad(176), math.rad(90))
local READY_GRIP = CFrame.new(0.06, -0.1, 0.1) * CFrame.Angles(math.rad(92), math.rad(174), math.rad(92))
local WINDUP_GRIP = CFrame.new(0.34, -0.28, 0.18) * CFrame.Angles(math.rad(118), math.rad(162), math.rad(104))
local STRIKE_GRIP = CFrame.new(0.16, -0.04, 0.42) * CFrame.Angles(math.rad(126), math.rad(168), math.rad(78))
local FOLLOW_GRIP = CFrame.new(0.08, 0.08, 0.34) * CFrame.Angles(math.rad(108), math.rad(154), math.rad(72))

WarAxeConfig.SHOULDER_POSE = {
	rightShoulder = CFrame.Angles(math.rad(-10), math.rad(-16), math.rad(92)),
	rightElbow = CFrame.Angles(math.rad(-42), math.rad(12), math.rad(8)),
	rightWrist = CFrame.Angles(math.rad(16), math.rad(-20), math.rad(12)),
	leftShoulder = IDENTITY,
	leftElbow = IDENTITY,
	leftWrist = IDENTITY,
	grip = SHOULDER_GRIP,
}

WarAxeConfig.SHOULDER_GRIP = SHOULDER_GRIP

local READY_POSE: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(-4), math.rad(-18), math.rad(98)),
	rightElbow = CFrame.Angles(math.rad(-38), math.rad(10), math.rad(6)),
	rightWrist = CFrame.Angles(math.rad(12), math.rad(-16), math.rad(10)),
	leftShoulder = IDENTITY,
	leftElbow = IDENTITY,
	leftWrist = IDENTITY,
	grip = READY_GRIP,
}

local WINDUP_POSE: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(18), math.rad(-28), math.rad(118)),
	rightElbow = CFrame.Angles(math.rad(-24), math.rad(14), math.rad(8)),
	rightWrist = CFrame.Angles(math.rad(-6), math.rad(-12), math.rad(14)),
	leftShoulder = IDENTITY,
	leftElbow = IDENTITY,
	leftWrist = IDENTITY,
	grip = WINDUP_GRIP,
}

local STRIKE_POSE: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(58), math.rad(-22), math.rad(112)),
	rightElbow = CFrame.Angles(math.rad(-8), math.rad(18), math.rad(6)),
	rightWrist = CFrame.Angles(math.rad(-10), math.rad(-8), math.rad(14)),
	leftShoulder = IDENTITY,
	leftElbow = IDENTITY,
	leftWrist = IDENTITY,
	grip = STRIKE_GRIP,
}

local FOLLOW_POSE: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(44), math.rad(-26), math.rad(106)),
	rightElbow = CFrame.Angles(math.rad(-14), math.rad(14), math.rad(4)),
	rightWrist = CFrame.Angles(math.rad(-6), math.rad(-6), math.rad(10)),
	leftShoulder = IDENTITY,
	leftElbow = IDENTITY,
	leftWrist = IDENTITY,
	grip = FOLLOW_GRIP,
}

WarAxeConfig.SWING_COOLDOWN = 0.48
WarAxeConfig.SWING_DURATION = 0.44
WarAxeConfig.STRIKE_START_RATIO = 0.24
WarAxeConfig.STRIKE_END_RATIO = 0.42

WarAxeConfig.PoseKeyframes = {
	{ time = 0, pose = WarAxeConfig.SHOULDER_POSE },
	{ time = 0.07, pose = READY_POSE },
	{ time = 0.16, pose = WINDUP_POSE },
	{ time = 0.26, pose = STRIKE_POSE },
	{ time = 0.34, pose = FOLLOW_POSE },
	{ time = 0.44, pose = WarAxeConfig.SHOULDER_POSE },
}

function WarAxeConfig.smoothstep(alpha: number): number
	alpha = math.clamp(alpha, 0, 1)
	return alpha * alpha * (3 - 2 * alpha)
end

function WarAxeConfig.easeSegment(alpha: number, sharp: boolean): number
	alpha = math.clamp(alpha, 0, 1)
	if sharp then
		return 1 - (1 - alpha) * (1 - alpha)
	end
	return WarAxeConfig.smoothstep(alpha)
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
			local sharp = nextKeyframe.pose == STRIKE_POSE
			return BroadswordPose.lerp(current.pose, nextKeyframe.pose, WarAxeConfig.easeSegment(alpha, sharp))
		end
	end

	return keyframes[#keyframes].pose
end

function WarAxeConfig.isStrikePhase(elapsed: number): boolean
	local progress = elapsed / WarAxeConfig.SWING_DURATION
	return progress >= WarAxeConfig.STRIKE_START_RATIO and progress <= WarAxeConfig.STRIKE_END_RATIO
end

return WarAxeConfig
