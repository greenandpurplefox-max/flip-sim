local BroadswordPose = require(script.Parent.BroadswordPose)

local BroadswordConfig = {}

local IDENTITY = CFrame.new()

-- Blade flat on the right shoulder, hilt still in the right hand.
local SHOULDER_GRIP = CFrame.new(0, -0.55, 0.35) * CFrame.Angles(math.rad(108), math.rad(180), math.rad(92))
local TWO_HAND_GRIP = CFrame.new(0.04, -0.34, 0.46) * CFrame.Angles(math.rad(72), math.rad(178), math.rad(94))
local WINDUP_GRIP = CFrame.new(0.62, -0.94, 0.24) * CFrame.Angles(math.rad(-38), math.rad(164), math.rad(106))
local STRIKE_GRIP = CFrame.new(0.08, -0.18, 0.52) * CFrame.Angles(math.rad(12), math.rad(172), math.rad(88))
local FOLLOW_GRIP = CFrame.new(-0.68, 0.4, 0.1) * CFrame.Angles(math.rad(114), math.rad(-20), math.rad(34))

BroadswordConfig.SHOULDER_POSE = {
	rightShoulder = CFrame.Angles(math.rad(-20), math.rad(30), math.rad(148)),
	rightElbow = CFrame.Angles(math.rad(-58), math.rad(6), math.rad(16)),
	rightWrist = CFrame.Angles(math.rad(32), math.rad(-28), math.rad(48)),
	leftShoulder = IDENTITY,
	leftElbow = IDENTITY,
	leftWrist = IDENTITY,
	grip = SHOULDER_GRIP,
}

BroadswordConfig.SHOULDER_GRIP = SHOULDER_GRIP

BroadswordConfig.SWING_ANIMATION_ID = "rbxassetid://131022963827845"
BroadswordConfig.USES_ANIMATION = true
BroadswordConfig.ANIMATION_SWING_DURATION = 0.92
BroadswordConfig.ANIMATION_END_RATIO = 0.88

-- GIF-style horizontal two-handed slash: shoulder -> wind-up -> edge-led arc -> follow-through -> shoulder.
BroadswordConfig.ANIMATION_GRIP_KEYFRAMES = {
	{ time = 0, grip = SHOULDER_GRIP },
	{ time = 0.07, grip = TWO_HAND_GRIP },
	{ time = 0.16, grip = WINDUP_GRIP },
	{ time = 0.3, grip = STRIKE_GRIP },
	{ time = 0.46, grip = FOLLOW_GRIP },
	{ time = 0.62, grip = TWO_HAND_GRIP },
	{ time = 0.78, grip = SHOULDER_GRIP },
}

local TWO_HAND_HILT: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(18), math.rad(-8), math.rad(92)),
	rightElbow = CFrame.Angles(math.rad(-58), math.rad(6), math.rad(10)),
	rightWrist = CFrame.Angles(math.rad(8), math.rad(-18), math.rad(12)),
	leftShoulder = CFrame.Angles(math.rad(12), math.rad(18), math.rad(-72)),
	leftElbow = CFrame.Angles(math.rad(-48), math.rad(-8), math.rad(6)),
	leftWrist = CFrame.Angles(math.rad(10), math.rad(22), math.rad(-8)),
	grip = TWO_HAND_GRIP,
}

local BOTTOM_RIGHT: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(42), math.rad(-24), math.rad(118)),
	rightElbow = CFrame.Angles(math.rad(-28), math.rad(18), math.rad(14)),
	rightWrist = CFrame.Angles(math.rad(-12), math.rad(-8), math.rad(18)),
	leftShoulder = CFrame.Angles(math.rad(36), math.rad(8), math.rad(-96)),
	leftElbow = CFrame.Angles(math.rad(-22), math.rad(-12), math.rad(4)),
	leftWrist = CFrame.Angles(math.rad(-6), math.rad(16), math.rad(-6)),
	grip = WINDUP_GRIP,
}

local TOP_RIGHT: BroadswordPose.Pose = {
	rightShoulder = CFrame.Angles(math.rad(-34), math.rad(-18), math.rad(108)),
	rightElbow = CFrame.Angles(math.rad(-18), math.rad(12), math.rad(8)),
	rightWrist = CFrame.Angles(math.rad(14), math.rad(-6), math.rad(10)),
	leftShoulder = CFrame.Angles(math.rad(-28), math.rad(12), math.rad(-88)),
	leftElbow = CFrame.Angles(math.rad(-12), math.rad(-8), math.rad(2)),
	leftWrist = CFrame.Angles(math.rad(8), math.rad(10), math.rad(-4)),
	grip = FOLLOW_GRIP,
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
	if BroadswordConfig.USES_ANIMATION then
		return BroadswordConfig.ANIMATION_SWING_DURATION * BroadswordConfig.ANIMATION_END_RATIO
	end
	return BroadswordConfig.SWING_DURATION
end

function BroadswordConfig.getGripForAnimationSwing(progress: number): CFrame
	local keyframes = BroadswordConfig.ANIMATION_GRIP_KEYFRAMES
	local time = math.clamp(progress, 0, BroadswordConfig.ANIMATION_END_RATIO)

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
	local duration = BroadswordConfig.getSwingDuration()
	local progress = elapsed / duration
	return progress >= BroadswordConfig.STRIKE_START_RATIO and progress <= BroadswordConfig.STRIKE_END_RATIO
end

return BroadswordConfig
