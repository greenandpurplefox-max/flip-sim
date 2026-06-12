local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local SpellConfig = require(ReplicatedStorage.Shared.SpellConfig)

local GrimoireOpenClient = {}

local GRIMOIRE = Color3.fromRGB(180, 120, 255)
local GRIMOIRE_BRIGHT = Color3.fromRGB(220, 180, 255)
local PAGE = Color3.fromRGB(236, 224, 196)
local SHADOW = Color3.fromRGB(8, 4, 10)
local REQUIRED_TAPS = 3

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local useGrimoireEvent: RemoteEvent
local grimoireUsedEvent: RemoteEvent

local screenGui: ScreenGui
local backdrop: Frame
local container: Frame
local spellRevealLabel: TextLabel
local tapHintLabel: TextLabel
local viewportHost: Frame
local activeToken = 0
local pendingRevealHandler: ((any) -> ())? = nil

local function smoothstep(alpha: number): number
	alpha = math.clamp(alpha, 0, 1)
	return alpha * alpha * (3 - 2 * alpha)
end

local function weld(part0: BasePart, part1: BasePart)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = part0
	weldConstraint.Part1 = part1
	weldConstraint.Parent = part0
end

local function buildBookModel(): (Model, { BasePart }, BasePart, BasePart)
	local book = Instance.new("Model")
	book.Name = "GrimoireBook"

	local cover = Instance.new("Part")
	cover.Name = "Cover"
	cover.Size = Vector3.new(0.62, 0.82, 0.1)
	cover.Color = GRIMOIRE
	cover.Material = Enum.Material.SmoothPlastic
	cover.Anchored = true
	cover.CanCollide = false
	cover.Parent = book

	local spine = Instance.new("Part")
	spine.Name = "Spine"
	spine.Size = Vector3.new(0.12, 0.82, 0.14)
	spine.Color = Color3.fromRGB(92, 58, 128)
	spine.Material = Enum.Material.SmoothPlastic
	spine.Anchored = true
	spine.CanCollide = false
	spine.Parent = book

	local back = Instance.new("Part")
	back.Name = "BackCover"
	back.Size = Vector3.new(0.58, 0.78, 0.08)
	back.Color = Color3.fromRGB(120, 82, 168)
	back.Material = Enum.Material.SmoothPlastic
	back.Anchored = true
	back.CanCollide = false
	back.Parent = book

	local revealPage = Instance.new("Part")
	revealPage.Name = "RevealPage"
	revealPage.Size = Vector3.new(0.54, 0.74, 0.05)
	revealPage.Color = PAGE
	revealPage.Material = Enum.Material.SmoothPlastic
	revealPage.Anchored = true
	revealPage.CanCollide = false
	revealPage.Parent = book

	local rune = Instance.new("Part")
	rune.Name = "Rune"
	rune.Size = Vector3.new(0.22, 0.22, 0.04)
	rune.Color = GRIMOIRE_BRIGHT
	rune.Material = Enum.Material.Neon
	rune.Anchored = true
	rune.CanCollide = false
	rune.Parent = revealPage

	cover.CFrame = CFrame.new(0.16, 0, 0.04)
	spine.CFrame = CFrame.new(-0.18, 0, 0)
	back.CFrame = CFrame.new(-0.16, 0, -0.02)
	revealPage.CFrame = CFrame.new(0.12, 0, 0.01)
	rune.CFrame = revealPage.CFrame * CFrame.new(0, 0.08, 0.03)

	weld(cover, spine)
	weld(cover, back)

	local pages: { BasePart } = {}
	for index = 1, REQUIRED_TAPS do
		local page = Instance.new("Part")
		page.Name = `FlipPage_{index}`
		page.Size = Vector3.new(0.52, 0.72, 0.03)
		page.Color = if index == REQUIRED_TAPS then PAGE else Color3.fromRGB(220, 208, 180)
		page.Material = Enum.Material.SmoothPlastic
		page.Anchored = true
		page.CanCollide = false
		page.Parent = book
		page.CFrame = CFrame.new(-0.18, 0, 0.02 + index * 0.015)
			* CFrame.new(0.26, 0, 0)
		table.insert(pages, page)
	end

	local light = Instance.new("PointLight")
	light.Color = GRIMOIRE_BRIGHT
	light.Brightness = 2
	light.Range = 7
	light.Parent = cover

	book.PrimaryPart = spine
	return book, pages, revealPage, rune
end

local function pageCFrame(spinePosition: Vector3, angleRadians: number, pageHalfWidth: number, lift: number): CFrame
	return CFrame.new(spinePosition)
		* CFrame.Angles(0, angleRadians, 0)
		* CFrame.new(pageHalfWidth, lift, 0.02)
end

local function flipPage(page: BasePart, spine: BasePart, onComplete: () -> ())
	local duration = 0.34
	local startTime = os.clock()
	local endAngle = -math.rad(168)
	local pageHalfWidth = 0.26
	local lift = (tonumber(string.match(page.Name, "%d+")) or 1) * 0.012

	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		if not page.Parent or not spine.Parent then
			connection:Disconnect()
			return
		end

		local spinePosition = spine.Position
		local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
		local angle = endAngle * smoothstep(alpha)
		page.CFrame = pageCFrame(spinePosition, angle, pageHalfWidth, lift)

		if alpha >= 1 then
			connection:Disconnect()
			page.Transparency = 1
			onComplete()
		end
	end)
end

local function ensureUI()
	if screenGui then
		return
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GrimoireOpenUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 22
	screenGui.Enabled = true
	screenGui.Parent = playerGui

	backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.42
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.Visible = false
	backdrop.ZIndex = 1
	backdrop.Parent = screenGui

	container = Instance.new("Frame")
	container.Name = "GrimoireOpenContainer"
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.Size = UDim2.fromOffset(620, 540)
	container.Visible = false
	container.ZIndex = 2
	container.Parent = screenGui

	spellRevealLabel = Instance.new("TextLabel")
	spellRevealLabel.Name = "SpellReveal"
	spellRevealLabel.AnchorPoint = Vector2.new(0.5, 0)
	spellRevealLabel.BackgroundTransparency = 1
	spellRevealLabel.Position = UDim2.new(0.5, 0, 0, 0)
	spellRevealLabel.Size = UDim2.fromOffset(520, 56)
	spellRevealLabel.Font = Enum.Font.Antique
	spellRevealLabel.Text = ""
	spellRevealLabel.TextColor3 = GRIMOIRE_BRIGHT
	spellRevealLabel.TextSize = 34
	spellRevealLabel.TextStrokeColor3 = SHADOW
	spellRevealLabel.TextStrokeTransparency = 0.1
	spellRevealLabel.TextTransparency = 1
	spellRevealLabel.ZIndex = 4
	spellRevealLabel.Parent = container

	tapHintLabel = Instance.new("TextLabel")
	tapHintLabel.Name = "TapHint"
	tapHintLabel.AnchorPoint = Vector2.new(0.5, 1)
	tapHintLabel.BackgroundTransparency = 1
	tapHintLabel.Position = UDim2.new(0.5, 0, 1, -4)
	tapHintLabel.Size = UDim2.fromOffset(420, 36)
	tapHintLabel.Font = Enum.Font.Antique
	tapHintLabel.Text = "Tap the grimoire to read it!"
	tapHintLabel.TextColor3 = GRIMOIRE
	tapHintLabel.TextSize = 24
	tapHintLabel.TextStrokeColor3 = SHADOW
	tapHintLabel.TextStrokeTransparency = 0.15
	tapHintLabel.ZIndex = 4
	tapHintLabel.Parent = container

	viewportHost = Instance.new("Frame")
	viewportHost.Name = "ViewportHost"
	viewportHost.BackgroundTransparency = 1
	viewportHost.Position = UDim2.fromOffset(0, 58)
	viewportHost.Size = UDim2.new(1, 0, 1, -108)
	viewportHost.ClipsDescendants = false
	viewportHost.Parent = container
end

local function closeSession(token: number)
	if token ~= activeToken then
		return
	end

	pendingRevealHandler = nil
	backdrop.Visible = false
	container.Visible = false
	for _, child in viewportHost:GetChildren() do
		child:Destroy()
	end
end

local function playReveal(
	token: number,
	camera: Camera,
	revealPage: BasePart,
	rune: BasePart,
	spellName: string,
	subtitle: string
)
	if token ~= activeToken then
		return
	end

	spellRevealLabel.Text = spellName
	spellRevealLabel.TextTransparency = 1
	spellRevealLabel.TextStrokeTransparency = 1
	tapHintLabel.Visible = true
	tapHintLabel.Text = subtitle

	local baseCamera = camera.CFrame
	local focus = revealPage.Position + Vector3.new(0.08, 0.04, 0)
	local zoomCamera = CFrame.new(focus + Vector3.new(0.55, 0.35, 1.35), focus + Vector3.new(0, 0.05, 0))

	local zoomStart = os.clock()
	local zoomDuration = 0.65
	local zoomConnection: RBXScriptConnection
	zoomConnection = RunService.RenderStepped:Connect(function()
		if token ~= activeToken or not camera.Parent then
			zoomConnection:Disconnect()
			return
		end

		local alpha = smoothstep(math.clamp((os.clock() - zoomStart) / zoomDuration, 0, 1))
		camera.CFrame = baseCamera:Lerp(zoomCamera, alpha)

		if alpha >= 1 then
			zoomConnection:Disconnect()
		end
	end)

	TweenService:Create(spellRevealLabel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		TextStrokeTransparency = 0.1,
	}):Play()

	TweenService:Create(rune, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.32, 0.32, 0.05),
	}):Play()

	task.wait(2.8)
	if token ~= activeToken then
		return
	end

	local fade = TweenService:Create(spellRevealLabel, TweenInfo.new(0.35), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	fade:Play()
	fade.Completed:Wait()
	closeSession(token)
end

function GrimoireOpenClient.mountPreview(parent: Instance, size: number)
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.fromOffset(size, size)
	viewport.BackgroundTransparency = 1
	viewport.Parent = parent

	local book, _, _, _ = buildBookModel()
	book:PivotTo(CFrame.Angles(0, math.rad(24), math.rad(-12)))
	book.Parent = viewport

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(1.8, 1.1, 2.2), Vector3.new(0.1, 0, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	return viewport
end

function GrimoireOpenClient.open(onFinished: ((boolean) -> ())?)
	if pendingRevealHandler then
		return
	end

	ensureUI()
	activeToken += 1
	local token = activeToken

	for _, child in viewportHost:GetChildren() do
		child:Destroy()
	end

	backdrop.Visible = true
	container.Visible = true
	spellRevealLabel.Text = ""
	spellRevealLabel.TextTransparency = 1
	spellRevealLabel.TextStrokeTransparency = 1
	tapHintLabel.Visible = true
	tapHintLabel.Text = `Tap the grimoire to read it! (0/{REQUIRED_TAPS})`

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "GrimoireViewport"
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundTransparency = 1
	viewport.ZIndex = 2
	viewport.Parent = viewportHost

	local book, pages, revealPage, rune = buildBookModel()
	book:PivotTo(CFrame.Angles(0, math.rad(18), math.rad(-8)))
	book.Parent = viewport

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(1.9, 1.15, 2.35), Vector3.new(0.05, 0, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local spine = book.PrimaryPart :: BasePart

	local tapButton = Instance.new("TextButton")
	tapButton.Name = "TapTarget"
	tapButton.Size = UDim2.fromScale(1, 1)
	tapButton.BackgroundTransparency = 1
	tapButton.Text = ""
	tapButton.AutoButtonColor = false
	tapButton.ZIndex = 10
	tapButton.Parent = viewportHost

	local tapCount = 0
	local finished = false
	local tapConnection: RBXScriptConnection

	pendingRevealHandler = function(payload)
		if finished or token ~= activeToken then
			return
		end

		finished = true
		pendingRevealHandler = nil
		tapConnection:Disconnect()
		tapButton:Destroy()
		tapHintLabel.Visible = false

		local spellId = if typeof(payload.spellId) == "string" then payload.spellId else ""
		local spell = SpellConfig.getSpell(spellId)
		local spellName = if spell then spell.displayName else "Unknown Spell"
		local subtitle = if typeof(payload.message) == "string" then payload.message else "Spell learned!"

		task.spawn(function()
			playReveal(token, camera, revealPage, rune, spellName, subtitle)
			if onFinished then
				onFinished(true)
			end
		end)
	end

	tapConnection = tapButton.MouseButton1Click:Connect(function()
		if finished or token ~= activeToken then
			return
		end

		tapCount += 1
		local page = pages[tapCount]
		if not page then
			return
		end

		tapHintLabel.Text = if tapCount < REQUIRED_TAPS
			then `Tap the grimoire to read it! ({tapCount}/{REQUIRED_TAPS})`
			else "The final page turns..."

		flipPage(page, spine, function()
			if tapCount < REQUIRED_TAPS or finished or token ~= activeToken then
				return
			end

			useGrimoireEvent:FireServer()

			task.delay(2.5, function()
				if pendingRevealHandler and token == activeToken and not finished then
					pendingRevealHandler = nil
					closeSession(token)
					if onFinished then
						onFinished(false)
					end
				end
			end)
		end)
	end)
end

function GrimoireOpenClient.init()
	useGrimoireEvent = ReplicatedStorage:WaitForChild("UseGrimoire") :: RemoteEvent
	grimoireUsedEvent = ReplicatedStorage:WaitForChild("GrimoireUsed") :: RemoteEvent

	grimoireUsedEvent.OnClientEvent:Connect(function(payload)
		if pendingRevealHandler then
			pendingRevealHandler(payload)
		end
	end)
end

return GrimoireOpenClient
