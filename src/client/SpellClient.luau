local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SpellConfig = require(ReplicatedStorage.Shared.SpellConfig)
local SpellUpgradeConfig = require(ReplicatedStorage.Shared.SpellUpgradeConfig)

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
	local castBound = false
	local equippedActiveSpell = SpellConfig.DEFAULT_ACTIVE
	local equippedPassiveSpell = SpellConfig.DEFAULT_PASSIVE
	local spellLevels: { [string]: number } = {}

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpellCombatUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local castHud = Instance.new("Frame")
	castHud.Name = "CastHud"
	castHud.AnchorPoint = Vector2.new(0, 1)
	castHud.Position = UDim2.new(0, 16, 1, -78)
	castHud.Size = UDim2.fromOffset(250, 58)
	castHud.BackgroundColor3 = Color3.fromRGB(24, 18, 34)
	castHud.BackgroundTransparency = 0.12
	castHud.BorderSizePixel = 0
	castHud.Visible = false
	castHud.Parent = screenGui

	local castHudCorner = Instance.new("UICorner")
	castHudCorner.CornerRadius = UDim.new(0, 10)
	castHudCorner.Parent = castHud

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
	castHintLabel.Text = "Press E to cast active spell"
	castHintLabel.TextColor3 = Color3.fromRGB(196, 180, 220)
	castHintLabel.TextSize = 14
	castHintLabel.TextXAlignment = Enum.TextXAlignment.Left
	castHintLabel.Parent = castHud

	local procBanner = Instance.new("TextLabel")
	procBanner.Name = "PassiveProcBanner"
	procBanner.AnchorPoint = Vector2.new(1, 1)
	procBanner.Position = UDim2.new(1, -16, 1, -78)
	procBanner.Size = UDim2.fromOffset(280, 42)
	procBanner.BackgroundColor3 = Color3.fromRGB(28, 22, 18)
	procBanner.BackgroundTransparency = 0.18
	procBanner.BorderSizePixel = 0
	procBanner.Font = Enum.Font.GothamBold
	procBanner.Text = ""
	procBanner.TextColor3 = Color3.fromRGB(255, 240, 180)
	procBanner.TextSize = 16
	procBanner.TextTransparency = 1
	procBanner.Visible = false
	procBanner.Parent = screenGui

	local procCorner = Instance.new("UICorner")
	procCorner.CornerRadius = UDim.new(0, 10)
	procCorner.Parent = procBanner

	local procStroke = Instance.new("UIStroke")
	procStroke.Color = Color3.fromRGB(214, 176, 72)
	procStroke.Thickness = 2
	procStroke.Transparency = 1
	procStroke.Parent = procBanner

	local function updateCastHud()
		local level = spellLevels[equippedActiveSpell] or 1
		local stats = SpellUpgradeConfig.getEffectiveStats(equippedActiveSpell, level)
		castNameLabel.Text = stats.resolvedName
		castHudStroke.Color = stats.projectileColor
		castHud.Visible = inDungeon
	end

	local function showCastFlash(color: Color3, kind: string?)
		local flash = Instance.new("Frame")
		flash.Name = "SpellCastFlash"
		flash.BackgroundColor3 = color
		flash.BackgroundTransparency = if kind == "passive" then 0.9 else 0.78
		flash.BorderSizePixel = 0
		flash.Size = UDim2.fromScale(1, 1)
		flash.ZIndex = 20
		flash.Parent = screenGui

		local ring = Instance.new("Frame")
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromScale(0.5, 0.55)
		ring.Size = UDim2.fromOffset(if kind == "passive" then 120 else 220, if kind == "passive" then 120 else 220)
		ring.BackgroundTransparency = 1
		ring.ZIndex = 21
		ring.Parent = flash

		local ringStroke = Instance.new("UIStroke")
		ringStroke.Color = color
		ringStroke.Thickness = if kind == "passive" then 4 else 8
		ringStroke.Transparency = 0.15
		ringStroke.Parent = ring

		local ringCorner = Instance.new("UICorner")
		ringCorner.CornerRadius = UDim.new(1, 0)
		ringCorner.Parent = ring

		TweenService:Create(ring, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(if kind == "passive" then 220 else 420, if kind == "passive" then 220 else 420),
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

	local function showCharacterCastBurst(color: Color3, kind: string?)
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
		core.Size = Vector3.new(if kind == "passive" then 2.2 else 3.6, if kind == "passive" then 2.2 else 3.6, if kind == "passive" then 2.2 else 3.6)
		core.Transparency = 0.2
		core.CFrame = anchor.CFrame
		core.Parent = anchor

		local light = Instance.new("PointLight")
		light.Color = color
		light.Brightness = if kind == "passive" then 4 else 7
		light.Range = if kind == "passive" then 14 else 22
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
		emitter:Emit(if kind == "passive" then 24 else 48)

		task.delay(0.45, function()
			anchor:Destroy()
		end)
	end

	local function showPassiveBanner(spellName: string, color: Color3)
		procBanner.Text = `{spellName} triggered!`
		procBanner.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.35)
		procBanner.Visible = true
		procBanner.TextTransparency = 0
		procStroke.Color = color
		procStroke.Transparency = 0.1

		task.delay(0.9, function()
			TweenService:Create(procBanner, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
			TweenService:Create(procStroke, TweenInfo.new(0.25), { Transparency = 1 }):Play()
			task.delay(0.25, function()
				procBanner.Visible = false
			end)
		end)
	end

	local function onCastAction(_actionName: string, inputState: Enum.UserInputState)
		if inputState ~= Enum.UserInputState.Begin or not inDungeon then
			return Enum.ContextActionResult.Pass
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

	spellLoadoutUpdatedEvent.OnClientEvent:Connect(function(activeSpellId: string, passiveSpellId: string)
		if typeof(activeSpellId) == "string" then
			equippedActiveSpell = activeSpellId
		end
		if typeof(passiveSpellId) == "string" then
			equippedPassiveSpell = passiveSpellId
		end
		updateCastHud()
	end)

	profileStateEvent.OnClientEvent:Connect(function(snapshot)
		if typeof(snapshot) ~= "table" or typeof(snapshot.spellLevels) ~= "table" then
			return
		end

		for spellId, level in snapshot.spellLevels do
			if typeof(level) == "number" then
				spellLevels[spellId] = level
			end
		end
		updateCastHud()
	end)

	phaseStateEvent.OnClientEvent:Connect(function(phase: string)
		inDungeon = phase == "Dungeon"
		setCastBinding(inDungeon)
		updateCastHud()
	end)

	spellCastEffectEvent.OnClientEvent:Connect(function(_spellId: string, spellName: string, color: Color3, kind: string?)
		if typeof(color) ~= "Color3" then
			return
		end

		local effectKind = if typeof(kind) == "string" then kind else "cast"
		showCastFlash(color, effectKind)
		showCharacterCastBurst(color, effectKind)
		if effectKind == "passive" and typeof(spellName) == "string" then
			showPassiveBanner(spellName, color)
		end
	end)

	player:GetAttributeChangedSignal("GamePhase"):Connect(function()
		local phase = player:GetAttribute("GamePhase")
		inDungeon = phase == "Dungeon"
		setCastBinding(inDungeon)
		updateCastHud()
	end)

	local initialPhase = player:GetAttribute("GamePhase")
	if initialPhase == "Dungeon" then
		inDungeon = true
		setCastBinding(true)
	end

	updateCastHud()
end

return SpellClient
