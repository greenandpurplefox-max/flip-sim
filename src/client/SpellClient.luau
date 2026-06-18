local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SpellConfig = require(ReplicatedStorage.Shared.SpellConfig)
local SpellUpgradeConfig = require(ReplicatedStorage.Shared.SpellUpgradeConfig)
local StaminaConfig = require(ReplicatedStorage.Shared.StaminaConfig)
local UiCorner = require(script.Parent.UiCorner)

local SpellClient = {}

local CAST_ACTION = "CastEquippedSpell"

function SpellClient.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local castSpellEvent = ReplicatedStorage:WaitForChild("CastSpell") :: RemoteEvent
	local spellCastEffectEvent = ReplicatedStorage:WaitForChild("SpellCastEffect") :: RemoteEvent
	local spellLoadoutUpdatedEvent = ReplicatedStorage:WaitForChild("SpellLoadoutUpdated") :: RemoteEvent
	local profileStateEvent = ReplicatedStorage:WaitForChild("PlayerProfileState") :: RemoteEvent
	local phaseStateEvent = ReplicatedStorage:WaitForChild("PlayerPhaseState") :: RemoteEvent

	local inDungeon = false
	local inTrainingZone = false
	local castBound = false
	local infusedSpellId = ""
	local spellLevels: { [string]: number } = {}

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpellCombatUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local castHud = Instance.new("Frame")
	castHud.Name = "CastHud"
	castHud.AnchorPoint = Vector2.new(1, 1)
	castHud.Position = UDim2.new(1, -16, 1, -78)
	castHud.Size = UDim2.fromOffset(250, 58)
	castHud.BackgroundColor3 = Color3.fromRGB(24, 18, 34)
	castHud.BackgroundTransparency = 0.12
	castHud.BorderSizePixel = 0
	castHud.Visible = false
	castHud.Parent = screenGui

	UiCorner.apply(castHud, 10)

	local castHudStroke = Instance.new("UIStroke")
	castHudStroke.Color = Color3.fromRGB(160, 96, 255)
	castHudStroke.Thickness = 2
	castHudStroke.Parent = castHud

	local castNameLabel = Instance.new("TextLabel")
	castNameLabel.BackgroundTransparency = 1
	castNameLabel.Position = UDim2.fromOffset(12, 8)
	castNameLabel.Size = UDim2.new(1, -24, 0, 22)
	castNameLabel.Font = Enum.Font.GothamBold
	castNameLabel.Text = "Firebolt"
	castNameLabel.TextColor3 = Color3.fromRGB(255, 220, 160)
	castNameLabel.TextSize = 18
	castNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	castNameLabel.Parent = castHud

	local castHintLabel = Instance.new("TextLabel")
	castHintLabel.BackgroundTransparency = 1
	castHintLabel.Position = UDim2.fromOffset(12, 30)
	castHintLabel.Size = UDim2.new(1, -24, 0, 18)
	castHintLabel.Font = Enum.Font.Gotham
	castHintLabel.Text = "Press E to cast"
	castHintLabel.TextColor3 = Color3.fromRGB(196, 180, 220)
	castHintLabel.TextSize = 14
	castHintLabel.TextXAlignment = Enum.TextXAlignment.Left
	castHintLabel.Parent = castHud

	local function getCurrentStamina(): number
		return player:GetAttribute("Stamina") or StaminaConfig.MAX
	end

	local function getInfusedStats()
		if infusedSpellId == "" then
			return nil
		end
		local level = spellLevels[infusedSpellId] or 1
		return SpellUpgradeConfig.getEffectiveStats(infusedSpellId, level)
	end

	local function canCastInfusedSpell(): boolean
		local stats = getInfusedStats()
		if not stats then
			return false
		end
		return getCurrentStamina() >= stats.staminaCost
	end

	local function canUseCombatSpells(): boolean
		return inDungeon or inTrainingZone
	end

	local function updateCastHud()
		local stats = getInfusedStats()
		if not stats or not canUseCombatSpells() then
			castHud.Visible = false
			return
		end

		local stamina = getCurrentStamina()
		local canCast = stamina >= stats.staminaCost

		castNameLabel.Text = stats.resolvedName
		castHudStroke.Color = stats.projectileColor
		castHintLabel.Text = if canCast
			then `Press E  |  {stats.staminaCost} stamina`
			else `Need {stats.staminaCost} stamina ({math.floor(stamina)} left)`
		castHintLabel.TextColor3 = if canCast
			then Color3.fromRGB(196, 180, 220)
			else Color3.fromRGB(255, 140, 120)
		castHud.Visible = true
	end

	local function showCastFlash(color: Color3)
		local flash = Instance.new("Frame")
		flash.Name = "SpellCastFlash"
		flash.BackgroundColor3 = color
		flash.BackgroundTransparency = 0.78
		flash.BorderSizePixel = 0
		flash.Size = UDim2.fromScale(1, 1)
		flash.ZIndex = 20
		flash.Parent = screenGui

		local ring = Instance.new("Frame")
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromScale(0.5, 0.55)
		ring.Size = UDim2.fromOffset(220, 220)
		ring.BackgroundTransparency = 1
		ring.ZIndex = 21
		ring.Parent = flash

		local ringStroke = Instance.new("UIStroke")
		ringStroke.Color = color
		ringStroke.Thickness = 8
		ringStroke.Transparency = 0.15
		ringStroke.Parent = ring

		UiCorner.apply(ring, UDim.new(1, 0))

		TweenService:Create(ring, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(420, 420),
		}):Play()
		TweenService:Create(ringStroke, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 1,
		}):Play()
		TweenService:Create(flash, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		}):Play()

		task.delay(0.3, function()
			flash:Destroy()
		end)
	end

	local function showCharacterCastBurst(color: Color3)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			return
		end

		local anchor = Instance.new("Part")
		anchor.Name = "SpellCastAnchor"
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(1, 1, 1)
		anchor.CFrame = root.CFrame * CFrame.new(0, 1.2, -1.5)
		anchor.Parent = workspace

		local core = Instance.new("Part")
		core.Name = "SpellCastCore"
		core.Anchored = true
		core.CanCollide = false
		core.CanQuery = false
		core.CanTouch = false
		core.Material = Enum.Material.Neon
		core.Color = color
		core.Size = Vector3.new(3.6, 3.6, 3.6)
		core.Transparency = 0.2
		core.CFrame = anchor.CFrame
		core.Parent = anchor

		local light = Instance.new("PointLight")
		light.Color = color
		light.Brightness = 7
		light.Range = 22
		light.Parent = core

		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
		emitter.LightEmission = 1
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(1, 0),
		})
		emitter.Lifetime = NumberRange.new(0.25, 0.55)
		emitter.Speed = NumberRange.new(8, 18)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Parent = core
		emitter:Emit(48)

		task.delay(0.45, function()
			anchor:Destroy()
		end)
	end

	local function onCastAction(_actionName: string, inputState: Enum.UserInputState)
		if inputState ~= Enum.UserInputState.Begin or not canUseCombatSpells() then
			return Enum.ContextActionResult.Pass
		end

		if not canCastInfusedSpell() then
			updateCastHud()
			return Enum.ContextActionResult.Sink
		end

		castSpellEvent:FireServer()
		return Enum.ContextActionResult.Sink
	end

	local function setCastBinding(enabled: boolean)
		if enabled and not castBound then
			ContextActionService:BindAction(CAST_ACTION, onCastAction, false, Enum.KeyCode.E)
			castBound = true
		elseif not enabled and castBound then
			ContextActionService:UnbindAction(CAST_ACTION)
			castBound = false
		end
	end

	spellLoadoutUpdatedEvent.OnClientEvent:Connect(function(activeInfusion: string, _locked: boolean)
		if typeof(activeInfusion) == "string" then
			infusedSpellId = activeInfusion
		end
		updateCastHud()
	end)

	profileStateEvent.OnClientEvent:Connect(function(snapshot)
		if typeof(snapshot) ~= "table" then
			return
		end

		if typeof(snapshot.infusedSpellId) == "string" then
			infusedSpellId = snapshot.infusedSpellId
		end
		if typeof(snapshot.spellLevels) == "table" then
			for spellId, level in snapshot.spellLevels do
				if typeof(level) == "number" then
					spellLevels[spellId] = level
				end
			end
		end
		updateCastHud()
	end)

	player:GetAttributeChangedSignal("Stamina"):Connect(updateCastHud)

	phaseStateEvent.OnClientEvent:Connect(function(phase: string)
		inDungeon = phase == "Dungeon"
		setCastBinding(canUseCombatSpells())
		updateCastHud()
	end)

	player:GetAttributeChangedSignal("InTrainingZone"):Connect(function()
		inTrainingZone = player:GetAttribute("InTrainingZone") == true
		setCastBinding(canUseCombatSpells())
		updateCastHud()
	end)

	inTrainingZone = player:GetAttribute("InTrainingZone") == true

	spellCastEffectEvent.OnClientEvent:Connect(function(_spellId: string, _spellName: string, color: Color3)
		if typeof(color) ~= "Color3" then
			return
		end

		showCastFlash(color)
		showCharacterCastBurst(color)
	end)

	player:GetAttributeChangedSignal("GamePhase"):Connect(function()
		local phase = player:GetAttribute("GamePhase")
		inDungeon = phase == "Dungeon"
		setCastBinding(canUseCombatSpells())
		updateCastHud()
	end)

	local initialPhase = player:GetAttribute("GamePhase")
	if initialPhase == "Dungeon" then
		inDungeon = true
	end
	setCastBinding(canUseCombatSpells())

	updateCastHud()
end

return SpellClient
