local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StaminaConfig = require(ReplicatedStorage.Shared.StaminaConfig)

local StaminaService = {}

local staminaByPlayer: { [Player]: number } = {}

local function syncStamina(player: Player)
	local stamina = staminaByPlayer[player] or StaminaConfig.MAX
	player:SetAttribute("Stamina", math.floor(stamina * 10) / 10)
	player:SetAttribute("MaxStamina", StaminaConfig.MAX)
end

function StaminaService.getStamina(player: Player): number
	return staminaByPlayer[player] or StaminaConfig.MAX
end

function StaminaService.canAfford(player: Player, amount: number): boolean
	if amount <= 0 then
		return true
	end
	return StaminaService.getStamina(player) >= amount
end

function StaminaService.trySpend(player: Player, amount: number): boolean
	if amount <= 0 then
		return true
	end

	local current = StaminaService.getStamina(player)
	if current < amount then
		return false
	end

	staminaByPlayer[player] = current - amount
	syncStamina(player)
	return true
end

function StaminaService.refill(player: Player)
	staminaByPlayer[player] = StaminaConfig.MAX
	syncStamina(player)
end

local function bindPlayer(player: Player)
	syncStamina(player)
	player.CharacterAdded:Connect(function(character)
		task.defer(function()
			if player.Parent and player.Character == character then
				StaminaService.refill(player)
			end
		end)
	end)

	if player.Character then
		StaminaService.refill(player)
	end
end

function StaminaService.init()
	for _, player in Players:GetPlayers() do
		bindPlayer(player)
	end

	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(function(player)
		staminaByPlayer[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(StaminaConfig.REGEN_TICK_SECONDS)
			for _, player in Players:GetPlayers() do
				if not player.Parent then
					continue
				end

				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if not humanoid or humanoid.Health <= 0 then
					continue
				end

				local current = StaminaService.getStamina(player)
				if current >= StaminaConfig.MAX then
					continue
				end

				staminaByPlayer[player] = math.min(
					StaminaConfig.MAX,
					current + StaminaConfig.REGEN_PER_SECOND * StaminaConfig.REGEN_TICK_SECONDS
				)
				syncStamina(player)
			end
		end
	end)
end

return StaminaService
