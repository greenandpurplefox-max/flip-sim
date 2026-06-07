local BroadswordPose = {}

export type Pose = {
	rightShoulder: CFrame,
	rightElbow: CFrame,
	rightWrist: CFrame,
	leftShoulder: CFrame,
	leftElbow: CFrame,
	leftWrist: CFrame,
	grip: CFrame,
}

export type ArmMotors = {
	rightShoulder: Motor6D?,
	rightElbow: Motor6D?,
	rightWrist: Motor6D?,
	leftShoulder: Motor6D?,
	leftElbow: Motor6D?,
	leftWrist: Motor6D?,
}

local IDENTITY = CFrame.new()

function BroadswordPose.identity(): Pose
	return {
		rightShoulder = IDENTITY,
		rightElbow = IDENTITY,
		rightWrist = IDENTITY,
		leftShoulder = IDENTITY,
		leftElbow = IDENTITY,
		leftWrist = IDENTITY,
		grip = IDENTITY,
	}
end

function BroadswordPose.lerp(fromPose: Pose, toPose: Pose, alpha: number): Pose
	alpha = math.clamp(alpha, 0, 1)
	return {
		rightShoulder = fromPose.rightShoulder:Lerp(toPose.rightShoulder, alpha),
		rightElbow = fromPose.rightElbow:Lerp(toPose.rightElbow, alpha),
		rightWrist = fromPose.rightWrist:Lerp(toPose.rightWrist, alpha),
		leftShoulder = fromPose.leftShoulder:Lerp(toPose.leftShoulder, alpha),
		leftElbow = fromPose.leftElbow:Lerp(toPose.leftElbow, alpha),
		leftWrist = fromPose.leftWrist:Lerp(toPose.leftWrist, alpha),
		grip = fromPose.grip:Lerp(toPose.grip, alpha),
	}
end

function BroadswordPose.getMotors(character: Model): ArmMotors
	local upperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not upperTorso then
		return {}
	end

	if character:FindFirstChild("UpperTorso") then
		local rightUpperArm = character:FindFirstChild("RightUpperArm")
		local rightLowerArm = character:FindFirstChild("RightLowerArm")
		local leftUpperArm = character:FindFirstChild("LeftUpperArm")
		local leftLowerArm = character:FindFirstChild("LeftLowerArm")

		return {
			rightShoulder = upperTorso:FindFirstChild("RightShoulder") :: Motor6D?,
			rightElbow = if rightUpperArm then rightUpperArm:FindFirstChild("RightElbow") :: Motor6D? else nil,
			rightWrist = if rightLowerArm then rightLowerArm:FindFirstChild("RightWrist") :: Motor6D? else nil,
			leftShoulder = upperTorso:FindFirstChild("LeftShoulder") :: Motor6D?,
			leftElbow = if leftUpperArm then leftUpperArm:FindFirstChild("LeftElbow") :: Motor6D? else nil,
			leftWrist = if leftLowerArm then leftLowerArm:FindFirstChild("LeftWrist") :: Motor6D? else nil,
		}
	end

	return {
		rightShoulder = upperTorso:FindFirstChild("Right Shoulder") :: Motor6D?,
		rightElbow = nil,
		rightWrist = nil,
		leftShoulder = upperTorso:FindFirstChild("Left Shoulder") :: Motor6D?,
		leftElbow = nil,
		leftWrist = nil,
	}
end

function BroadswordPose.apply(motors: ArmMotors, pose: Pose, tool: Tool?)
	if motors.rightShoulder then
		motors.rightShoulder.Transform = pose.rightShoulder
	end
	if motors.rightElbow then
		motors.rightElbow.Transform = pose.rightElbow
	end
	if motors.rightWrist then
		motors.rightWrist.Transform = pose.rightWrist
	end
	if motors.leftShoulder then
		motors.leftShoulder.Transform = pose.leftShoulder
	end
	if motors.leftElbow then
		motors.leftElbow.Transform = pose.leftElbow
	end
	if motors.leftWrist then
		motors.leftWrist.Transform = pose.leftWrist
	end
	if tool then
		tool.Grip = pose.grip
	end
end

function BroadswordPose.reset(motors: ArmMotors, tool: Tool?, idleGrip: CFrame?)
	BroadswordPose.apply(motors, BroadswordPose.identity(), tool)
	if tool and idleGrip then
		tool.Grip = idleGrip
	end
end

return BroadswordPose
