local TrainingZoneConfig = {}

TrainingZoneConfig.ZONE_CENTER = Vector3.new(58, 4, -650)
TrainingZoneConfig.ZONE_HALF_SIZE = Vector3.new(18, 8, 18)

TrainingZoneConfig.PLATFORM_SIZE = Vector3.new(36, 2, 36)
TrainingZoneConfig.PLATFORM_COLOR = Color3.fromRGB(96, 82, 62)

TrainingZoneConfig.DUMMY_HEALTH = 100000
TrainingZoneConfig.DUMMY_POSITIONS = {
	Vector3.new(52, 6, -642),
	Vector3.new(58, 6, -642),
	Vector3.new(64, 6, -642),
	Vector3.new(58, 6, -656),
}

TrainingZoneConfig.DUMMY_LOOK_AT = Vector3.new(58, 6, -668)

return TrainingZoneConfig
