local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardConfig = require(ReplicatedStorage.Shared.CardConfig)

local CardService = {}

export type CardModifiers = {
	damageMult: number,
	cooldownMult: number,
	maxHealthBonus: number,
	healOnRoomClear: number,
	lifestealPercent: number,
}

local activeCards: { [Player]: { string } } = {}
local baseMaxHealth: { [Player]: number } = {}

local function getDefaultModifiers(): CardModifiers
	return {
		damageMult = 1,
		cooldownMult = 1,
		maxHealthBonus = 0,
		healOnRoomClear = 0,
		lifestealPercent = 0,
	}
end

function CardService.getModifiers(player: Player): CardModifiers
	local modifiers = getDefaultModifiers()

	for _, cardId in activeCards[player] or {} do
		local card = CardConfig.getCard(cardId)
		if card then
			local effects = card.effects
			if effects.damageMult then
				modifiers.damageMult *= effects.damageMult
			end
			if effects.cooldownMult then
				modifiers.cooldownMult *= effects.cooldownMult
			end
			if effects.maxHealthBonus then
				modifiers.maxHealthBonus += effects.maxHealthBonus
			end
			if effects.healOnRoomClear then
				modifiers.healOnRoomClear += effects.healOnRoomClear
			end
			if effects.lifestealPercent then
				modifiers.lifestealPercent += effects.lifestealPercent
			end
		end
	end

	return modifiers
end

function CardService.getActiveCardIds(player: Player): { string }
	return table.clone(activeCards[player] or {})
end

function CardService.rollDraftOptions(_player: Player, count: number): { string }
	local pool = CardConfig.getAllIds()
	local options: { string } = {}

	while #options < count and #pool > 0 do
		local index = math.random(1, #pool)
		table.insert(options, pool[index])
		table.remove(pool, index)
	end

	return options
end

local function applyHealthBonus(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if not baseMaxHealth[player] then
		baseMaxHealth[player] = humanoid.MaxHealth
	end

	local modifiers = CardService.getModifiers(player)
	local targetMax = math.max(20, baseMaxHealth[player] + modifiers.maxHealthBonus)
	local healthRatio = if humanoid.MaxHealth > 0 then humanoid.Health / humanoid.MaxHealth else 1

	humanoid.MaxHealth = targetMax
	humanoid.Health = math.min(targetMax, targetMax * healthRatio)
end

function CardService.applyCard(player: Player, cardId: string): boolean
	local card = CardConfig.getCard(cardId)
	if not card then
		return false
	end

	if not activeCards[player] then
		activeCards[player] = {}
	end

	table.insert(activeCards[player], cardId)
	applyHealthBonus(player)
	return true
end

function CardService.healOnRoomClear(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local healAmount = CardService.getModifiers(player).healOnRoomClear
	if healAmount > 0 then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healAmount)
	end
end

function CardService.applyLifesteal(player: Player, damageDealt: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or damageDealt <= 0 then
		return
	end

	local percent = CardService.getModifiers(player).lifestealPercent
	if percent <= 0 then
		return
	end

	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + damageDealt * percent)
end

function CardService.resetRun(player: Player)
	activeCards[player] = nil
	baseMaxHealth[player] = nil
end

function CardService.bindCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	baseMaxHealth[player] = humanoid.MaxHealth
	applyHealthBonus(player)
end

function CardService.init()
	Players.PlayerRemoving:Connect(function(player)
		activeCards[player] = nil
		baseMaxHealth[player] = nil
	end)
end

return CardService
