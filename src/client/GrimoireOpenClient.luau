local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local SpellConfig = require(ReplicatedStorage.Shared.SpellConfig)

local GrimoireOpenClient = {}

local GRIMOIRE = Color3.fromRGB(118, 72, 168)
local GRIMOIRE_DARK = Color3.fromRGB(62, 38, 92)
local GRIMOIRE_BRIGHT = Color3.fromRGB(220, 180, 255)
local GOLD_TRIM = Color3.fromRGB(214, 176, 72)
local PAGE = Color3.fromRGB(244, 232, 208)
local PAGE_EDGE = Color3.fromRGB(210, 190, 160)
local INK = Color3.fromRGB(48, 32, 58)
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
local activeDemoToken = 0

export type PageContent = {
	surfaceGui: SurfaceGui,
	nameLabel: TextLabel,
	statsLabel: TextLabel,
	descLabel: TextLabel,
}

export type BookBuild = {
	model: Model,
	pages: { BasePart },
	revealPage: BasePart,
	cover: BasePart,
	spine: BasePart,
	rune: BasePart,
	pageContent: PageContent,
}

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

local function formatSpellStats(spell: SpellConfig.SpellStats): string
	local lines = {
		`Damage  {spell.damageMin} - {spell.damageMax}`,
		`Cooldown  {spell.cooldown}s`,
		`Stamina  {spell.staminaCost}`,
	}
	if (spell.aoeRadius or 0) > 0 then
		table.insert(lines, `Area blast  {spell.aoeRadius} studs`)
	else
		table.insert(lines, "Type  Projectile")
	end
	return table.concat(lines, "\n")
end

local function createPageContent(revealPage: BasePart): PageContent
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "PageText"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.AlwaysOnTop = true
	surfaceGui.LightInfluence = 0
	surfaceGui.Brightness = 1.35
	surfaceGui.CanvasSize = Vector2.new(540, 740)
	surfaceGui.PixelsPerStud = 80
	surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	surfaceGui.Parent = revealPage

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "SpellName"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(24, 28)
	nameLabel.Size = UDim2.new(1, -48, 0, 92)
	nameLabel.Font = Enum.Font.Antique
	nameLabel.Text = ""
	nameLabel.TextColor3 = INK
	nameLabel.TextSize = 52
	nameLabel.TextTransparency = 1
	nameLabel.TextWrapped = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = surfaceGui

	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.BackgroundColor3 = GOLD_TRIM
	divider.BorderSizePixel = 0
	divider.Position = UDim2.fromOffset(48, 126)
	divider.Size = UDim2.new(1, -96, 0, 3)
	divider.BackgroundTransparency = 1
	divider.Parent = surfaceGui

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "SpellStats"
	statsLabel.BackgroundTransparency = 1
	statsLabel.Position = UDim2.fromOffset(36, 142)
	statsLabel.Size = UDim2.new(1, -72, 0, 150)
	statsLabel.Font = Enum.Font.GothamBold
	statsLabel.Text = ""
	statsLabel.TextColor3 = Color3.fromRGB(72, 52, 88)
	statsLabel.TextSize = 28
	statsLabel.TextTransparency = 1
	statsLabel.TextWrapped = true
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.TextYAlignment = Enum.TextYAlignment.Top
	statsLabel.Parent = surfaceGui

	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "SpellDesc"
	descLabel.BackgroundTransparency = 1
	descLabel.Position = UDim2.fromOffset(36, 300)
	descLabel.Size = UDim2.new(1, -72, 0, 120)
	descLabel.Font = Enum.Font.Gotham
	descLabel.Text = ""
	descLabel.TextColor3 = Color3.fromRGB(96, 72, 108)
	descLabel.TextSize = 22
	descLabel.TextTransparency = 1
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = surfaceGui

	local demoLabel = Instance.new("TextLabel")
	demoLabel.Name = "DemoCaption"
	demoLabel.BackgroundTransparency = 1
	demoLabel.Position = UDim2.fromOffset(36, 430)
	demoLabel.Size = UDim2.new(1, -72, 0, 28)
	demoLabel.Font = Enum.Font.GothamBold
	demoLabel.Text = "Preview"
	demoLabel.TextColor3 = Color3.fromRGB(120, 96, 72)
	demoLabel.TextSize = 18
	demoLabel.TextTransparency = 1
	demoLabel.TextXAlignment = Enum.TextXAlignment.Center
	demoLabel.Parent = surfaceGui

	return {
		surfaceGui = surfaceGui,
		nameLabel = nameLabel,
		statsLabel = statsLabel,
		descLabel = descLabel,
	}
end

local function buildBookModel(): BookBuild
	local book = Instance.new("Model")
	book.Name = "GrimoireBook"

	local spine = Instance.new("Part")
	spine.Name = "Spine"
	spine.Size = Vector3.new(0.16, 0.88, 0.18)
	spine.Color = GRIMOIRE_DARK
	spine.Material = Enum.Material.SmoothPlastic
	spine.Anchored = true
	spine.CanCollide = false
	spine.Parent = book

	local back = Instance.new("Part")
	back.Name = "BackCover"
	back.Size = Vector3.new(0.64, 0.84, 0.1)
	back.Color = GRIMOIRE_DARK
	back.Material = Enum.Material.SmoothPlastic
	back.Anchored = true
	back.CanCollide = false
	back.Parent = book

	local cover = Instance.new("Part")
	cover.Name = "Cover"
	cover.Size = Vector3.new(0.64, 0.84, 0.12)
	cover.Color = GRIMOIRE
	cover.Material = Enum.Material.SmoothPlastic
	cover.Anchored = true
	cover.CanCollide = false
	cover.Parent = book

	local coverTrim = Instance.new("Part")
	coverTrim.Name = "CoverTrim"
	coverTrim.Size = Vector3.new(0.58, 0.78, 0.04)
	coverTrim.Color = GRIMOIRE_DARK
	coverTrim.Material = Enum.Material.SmoothPlastic
	coverTrim.Anchored = true
	coverTrim.CanCollide = false
	coverTrim.Parent = book

	local bandTop = Instance.new("Part")
	bandTop.Name = "BandTop"
	bandTop.Size = Vector3.new(0.66, 0.08, 0.13)
	bandTop.Color = GOLD_TRIM
	bandTop.Material = Enum.Material.Metal
	bandTop.Anchored = true
	bandTop.CanCollide = false
	bandTop.Parent = book

	local bandBottom = Instance.new("Part")
	bandBottom.Name = "BandBottom"
	bandBottom.Size = Vector3.new(0.66, 0.08, 0.13)
	bandBottom.Color = GOLD_TRIM
	bandBottom.Material = Enum.Material.Metal
	bandBottom.Anchored = true
	bandBottom.CanCollide = false
	bandBottom.Parent = book

	local clasp = Instance.new("Part")
	clasp.Name = "CoverClasp"
	clasp.Size = Vector3.new(0.16, 0.16, 0.16)
	clasp.Shape = Enum.PartType.Ball
	clasp.Color = GRIMOIRE_BRIGHT
	clasp.Material = Enum.Material.Neon
	clasp.Anchored = true
	clasp.CanCollide = false
	clasp.Parent = book

	local cornerOffsets = {
		Vector3.new(0.24, 0.34, 0.06),
		Vector3.new(0.24, -0.34, 0.06),
		Vector3.new(-0.24, 0.34, 0.06),
		Vector3.new(-0.24, -0.34, 0.06),
	}
	for index, offset in cornerOffsets do
		local corner = Instance.new("Part")
		corner.Name = `Corner_{index}`
		corner.Size = Vector3.new(0.1, 0.1, 0.04)
		corner.Color = GOLD_TRIM
		corner.Material = Enum.Material.Metal
		corner.Anchored = true
		corner.CanCollide = false
		corner.Parent = book
		corner.CFrame = cover.CFrame * CFrame.new(offset)
		weld(cover, corner)
	end

	spine.CFrame = CFrame.new(-0.2, 0, 0)
	back.CFrame = CFrame.new(-0.18, 0, -0.02)
	cover.CFrame = CFrame.new(0.18, 0, 0.05)
	coverTrim.CFrame = cover.CFrame * CFrame.new(0, 0, 0.05)
	bandTop.CFrame = cover.CFrame * CFrame.new(0, 0.36, 0.02)
	bandBottom.CFrame = cover.CFrame * CFrame.new(0, -0.36, 0.02)
	clasp.CFrame = cover.CFrame * CFrame.new(0.18, -0.28, 0.08)

	weld(spine, back)
	weld(spine, cover)
	weld(cover, coverTrim)
	weld(cover, bandTop)
	weld(cover, bandBottom)
	weld(cover, clasp)

	local revealPage = Instance.new("Part")
	revealPage.Name = "RevealPage"
	revealPage.Size = Vector3.new(0.56, 0.78, 0.045)
	revealPage.Color = PAGE
	revealPage.Material = Enum.Material.SmoothPlastic
	revealPage.Anchored = true
	revealPage.CanCollide = false
	revealPage.CFrame = CFrame.new(0.1, 0, 0.02)
	revealPage.Parent = book

	local pageEdge = Instance.new("Part")
	pageEdge.Name = "PageEdge"
	pageEdge.Size = Vector3.new(0.04, 0.74, 0.05)
	pageEdge.Color = PAGE_EDGE
	pageEdge.Material = Enum.Material.SmoothPlastic
	pageEdge.Anchored = true
	pageEdge.CanCollide = false
	pageEdge.CFrame = revealPage.CFrame * CFrame.new(-0.28, 0, 0)
	pageEdge.Parent = book
	weld(revealPage, pageEdge)

	local rune = Instance.new("Part")
	rune.Name = "Rune"
	rune.Size = Vector3.new(0.18, 0.18, 0.03)
	rune.Color = GRIMOIRE_BRIGHT
	rune.Material = Enum.Material.Neon
	rune.Anchored = true
	rune.CanCollide = false
	rune.CFrame = revealPage.CFrame * CFrame.new(0, 0.24, 0.03)
	rune.Parent = book

	local pageContent = createPageContent(revealPage)

	local pages: { BasePart } = {}
	for index = 1, REQUIRED_TAPS do
		local page = Instance.new("Part")
		page.Name = `FlipPage_{index}`
		page.Size = Vector3.new(0.54, 0.74, 0.028)
		page.Color = if index == REQUIRED_TAPS then PAGE else Color3.fromRGB(228, 214, 188)
		page.Material = Enum.Material.SmoothPlastic
		page.Anchored = true
		page.CanCollide = false
		page.Parent = book
		page.CFrame = CFrame.new(-0.2, 0, 0.018 + index * 0.012) * CFrame.new(0.27, 0, 0)
		table.insert(pages, page)
	end

	local light = Instance.new("PointLight")
	light.Color = GRIMOIRE_BRIGHT
	light.Brightness = 2.4
	light.Range = 8
	light.Parent = cover

	book.PrimaryPart = spine
	return {
		model = book,
		pages = pages,
		revealPage = revealPage,
		cover = cover,
		spine = spine,
		rune = rune,
		pageContent = pageContent,
	}
end

local function pageCFrame(spinePosition: Vector3, angleRadians: number, pageHalfWidth: number, lift: number): CFrame
	return CFrame.new(spinePosition)
		* CFrame.Angles(0, angleRadians, 0)
		* CFrame.new(pageHalfWidth, lift, 0.02)
end

local function flipPage(page: BasePart, spine: BasePart, onComplete: () -> ())
	local duration = 0.36
	local startTime = os.clock()
	local endAngle = -math.rad(168)
	local pageHalfWidth = 0.27
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

local function populateRevealPage(pageContent: PageContent, spell: SpellConfig.SpellStats)
	pageContent.nameLabel.Text = spell.displayName
	pageContent.statsLabel.Text = formatSpellStats(spell)
	pageContent.descLabel.Text = spell.description
end

local function fadeInPageText(pageContent: PageContent)
	local labels = { pageContent.nameLabel, pageContent.statsLabel, pageContent.descLabel }
	for index, label in labels do
		task.delay((index - 1) * 0.06, function()
			TweenService:Create(label, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()
		end)
	end
	local demoCaption = pageContent.surfaceGui:FindFirstChild("DemoCaption") :: TextLabel?
	if demoCaption then
		TweenService:Create(demoCaption, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()
	end
end

local function createMiniMage(spellColor: Color3): Model
	local mage = Instance.new("Model")
	mage.Name = "SpellDemoMage"

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.14, 0.34, 0.1)
	root.Color = Color3.fromRGB(58, 92, 148)
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = true
	root.CanCollide = false
	root.Parent = mage

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(0.16, 0.16, 0.16)
	head.Shape = Enum.PartType.Ball
	head.Color = Color3.fromRGB(234, 184, 146)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Parent = mage

	local arm = Instance.new("Part")
	arm.Name = "CastArm"
	arm.Size = Vector3.new(0.08, 0.22, 0.08)
	arm.Color = Color3.fromRGB(234, 184, 146)
	arm.Material = Enum.Material.SmoothPlastic
	arm.Anchored = true
	arm.CanCollide = false
	arm.Parent = mage

	local wand = Instance.new("Part")
	wand.Name = "Wand"
	wand.Size = Vector3.new(0.05, 0.28, 0.05)
	wand.Color = GRIMOIRE_DARK
	wand.Material = Enum.Material.Wood
	wand.Anchored = true
	wand.CanCollide = false
	wand.Parent = mage

	local tip = Instance.new("Part")
	tip.Name = "WandTip"
	tip.Size = Vector3.new(0.08, 0.08, 0.08)
	tip.Shape = Enum.PartType.Ball
	tip.Color = spellColor
	tip.Material = Enum.Material.Neon
	tip.Anchored = true
	tip.CanCollide = false
	tip.Parent = mage

	root.CFrame = CFrame.new()
	head.CFrame = root.CFrame * CFrame.new(0, 0.24, 0)
	arm.CFrame = root.CFrame * CFrame.new(0.12, 0.08, -0.04) * CFrame.Angles(0, 0, math.rad(-28))
	wand.CFrame = arm.CFrame * CFrame.new(0.08, -0.1, -0.08) * CFrame.Angles(math.rad(58), 0, 0)
	tip.CFrame = wand.CFrame * CFrame.new(0, -0.16, 0)

	weld(root, head)
	weld(root, arm)
	weld(arm, wand)
	weld(wand, tip)

	mage.PrimaryPart = root
	return mage
end

local function playSpellDemo(token: number, revealPage: BasePart, spell: SpellConfig.SpellStats)
	activeDemoToken += 1
	local demoToken = activeDemoToken

	local stage = Instance.new("Part")
	stage.Name = "DemoStage"
	stage.Size = Vector3.new(0.42, 0.02, 0.28)
	stage.Color = Color3.fromRGB(210, 198, 176)
	stage.Material = Enum.Material.SmoothPlastic
	stage.Anchored = true
	stage.CanCollide = false
	stage.CFrame = revealPage.CFrame * CFrame.new(0, -0.2, 0.05)
	stage.Parent = revealPage

	local frame = Instance.new("Part")
	frame.Name = "DemoFrame"
	frame.Size = Vector3.new(0.44, 0.24, 0.02)
	frame.Color = GOLD_TRIM
	frame.Material = Enum.Material.Metal
	frame.Anchored = true
	frame.CanCollide = false
	frame.Transparency = 0.15
	frame.CFrame = stage.CFrame * CFrame.new(0, 0.13, 0.01)
	frame.Parent = revealPage

	local mage = createMiniMage(spell.projectileColor)
	local mageRoot = mage.PrimaryPart :: BasePart
	local basePivot = revealPage.CFrame * CFrame.new(0, -0.2, 0.08)
	mage.Parent = revealPage
	mage:PivotTo(basePivot)

	local isAoe = (spell.aoeRadius or 0) > 0
	local effectPart: BasePart? = nil
	if isAoe then
		local ring = Instance.new("Part")
		ring.Name = "NovaRing"
		ring.Size = Vector3.new(0.08, 0.08, 0.08)
		ring.Shape = Enum.PartType.Cylinder
		ring.Color = spell.projectileColor
		ring.Material = Enum.Material.Neon
		ring.Anchored = true
		ring.CanCollide = false
		ring.Transparency = 0.2
		ring.CFrame = basePivot * CFrame.new(0, -0.08, 0.12) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = revealPage
		effectPart = ring
	else
		local bolt = Instance.new("Part")
		bolt.Name = "SpellBolt"
		bolt.Size = spell.projectileSize * 0.08
		bolt.Color = spell.projectileColor
		bolt.Material = Enum.Material.Neon
		bolt.Anchored = true
		bolt.CanCollide = false
		bolt.CFrame = basePivot * CFrame.new(0.12, 0.04, -0.08)
		bolt.Parent = revealPage
		effectPart = bolt
	end

	local startTime = os.clock()
	local cycleDuration = 2.2
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		if token ~= activeToken or demoToken ~= activeDemoToken or not revealPage.Parent then
			connection:Disconnect()
			if stage.Parent then
				stage:Destroy()
			end
			if frame.Parent then
				frame:Destroy()
			end
			if mage.Parent then
				mage:Destroy()
			end
			if effectPart and effectPart.Parent then
				effectPart:Destroy()
			end
			return
		end

		local loop = (os.clock() - startTime) % cycleDuration
		local cycle = loop / cycleDuration

		local castLift = math.sin(cycle * math.pi * 2) * 0.015
		mage:PivotTo(basePivot * CFrame.new(0, castLift, 0))

		local arm = mage:FindFirstChild("CastArm") :: BasePart?
		local wand = mage:FindFirstChild("Wand") :: BasePart?
		local tip = mage:FindFirstChild("WandTip") :: BasePart?
		if arm then
			local castAngle = -28 + math.sin(cycle * math.pi * 2) * 18
			arm.CFrame = mageRoot.CFrame * CFrame.new(0.12, 0.08, -0.04) * CFrame.Angles(0, 0, math.rad(castAngle))
			if wand then
				wand.CFrame = arm.CFrame * CFrame.new(0.08, -0.1, -0.08) * CFrame.Angles(math.rad(58), 0, 0)
			end
			if tip and wand then
				tip.CFrame = wand.CFrame * CFrame.new(0, -0.16, 0)
			end
		end

		if effectPart then
			if isAoe then
				local pulse = 0.12 + math.abs(math.sin(cycle * math.pi * 2)) * 0.22
				effectPart.Size = Vector3.new(0.06, pulse, pulse)
				effectPart.Transparency = 0.15 + math.sin(cycle * math.pi * 2) * 0.1
			else
				local travel = (cycle % 0.55) / 0.55
				if cycle > 0.55 then
					effectPart.Transparency = 1
				else
					effectPart.Transparency = 0
					effectPart.CFrame = basePivot
						* CFrame.new(0.12 + travel * 0.42, 0.04 + travel * 0.04, -0.08 - travel * 0.18)
				end
			end
		end

	end)
end

local function animateCoverOpen(token: number, bookBuild: BookBuild)
	local cover = bookBuild.cover
	local spine = bookBuild.spine
	local clasp = bookBuild.model:FindFirstChild("CoverClasp") :: BasePart?
	local bandTop = bookBuild.model:FindFirstChild("BandTop") :: BasePart?
	local bandBottom = bookBuild.model:FindFirstChild("BandBottom") :: BasePart?
	local coverTrim = bookBuild.model:FindFirstChild("CoverTrim") :: BasePart?
	local cornerOffsets = {
		Vector3.new(0.24, 0.34, 0.06),
		Vector3.new(0.24, -0.34, 0.06),
		Vector3.new(-0.24, 0.34, 0.06),
		Vector3.new(-0.24, -0.34, 0.06),
	}

	local spinePivot = spine.CFrame
	local duration = 0.55
	local startTime = os.clock()

	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		if token ~= activeToken or not cover.Parent then
			connection:Disconnect()
			return
		end

		local alpha = smoothstep(math.clamp((os.clock() - startTime) / duration, 0, 1))
		local angle = -math.rad(118) * alpha
		local openPivot = spinePivot * CFrame.Angles(0, angle, 0) * CFrame.new(0.36, 0, 0.05)
		cover.CFrame = openPivot

		if clasp then
			clasp.CFrame = openPivot * CFrame.new(0.18, -0.28, 0.08)
		end
		if bandTop then
			bandTop.CFrame = openPivot * CFrame.new(0, 0.36, 0.02)
		end
		if bandBottom then
			bandBottom.CFrame = openPivot * CFrame.new(0, -0.36, 0.02)
		end
		if coverTrim then
			coverTrim.CFrame = openPivot * CFrame.new(0, 0, 0.05)
		end

		for index, offset in cornerOffsets do
			local corner = bookBuild.model:FindFirstChild(`Corner_{index}`) :: BasePart?
			if corner then
				corner.CFrame = openPivot * CFrame.new(offset)
			end
		end

		if alpha >= 1 then
			connection:Disconnect()
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
	spellRevealLabel.TextSize = 30
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
	tapHintLabel.TextColor3 = GRIMOIRE_BRIGHT
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

	activeDemoToken += 1
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
	bookBuild: BookBuild,
	spell: SpellConfig.SpellStats,
	subtitle: string
)
	if token ~= activeToken then
		return
	end

	populateRevealPage(bookBuild.pageContent, spell)
	for _, label in { bookBuild.pageContent.nameLabel, bookBuild.pageContent.statsLabel, bookBuild.pageContent.descLabel } do
		label.TextTransparency = 1
	end
	local demoCaption = bookBuild.pageContent.surfaceGui:FindFirstChild("DemoCaption") :: TextLabel?
	if demoCaption then
		demoCaption.TextTransparency = 1
	end

	spellRevealLabel.Text = subtitle
	spellRevealLabel.TextTransparency = 1
	spellRevealLabel.TextStrokeTransparency = 1
	tapHintLabel.Visible = true
	tapHintLabel.Text = subtitle

	animateCoverOpen(token, bookBuild)
	TweenService:Create(bookBuild.rune, TweenInfo.new(0.35), { Transparency = 1 }):Play()

	local revealPage = bookBuild.revealPage
	local baseCamera = camera.CFrame
	local focus = revealPage.Position + Vector3.new(0.04, 0.02, 0.04)
	local zoomCamera = CFrame.new(focus + Vector3.new(0.42, 0.18, 0.95), focus + Vector3.new(0, -0.02, 0))

	local zoomStart = os.clock()
	local zoomDuration = 0.72
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

	task.delay(0.25, function()
		if token ~= activeToken then
			return
		end
		fadeInPageText(bookBuild.pageContent)
		playSpellDemo(token, revealPage, spell)
	end)

	TweenService:Create(spellRevealLabel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		TextStrokeTransparency = 0.1,
	}):Play()

	task.wait(3.6)
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

	local bookBuild = buildBookModel()
	bookBuild.model:PivotTo(CFrame.Angles(0, math.rad(24), math.rad(-12)))
	bookBuild.model.Parent = viewport

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(1.85, 1.05, 2.15), Vector3.new(0.08, 0, 0))
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

	local bookBuild = buildBookModel()
	bookBuild.model:PivotTo(CFrame.Angles(0, math.rad(18), math.rad(-8)))
	bookBuild.model.Parent = viewport

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(1.95, 1.1, 2.25), Vector3.new(0.06, 0, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local spine = bookBuild.model.PrimaryPart :: BasePart

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
		if not spell then
			closeSession(token)
			if onFinished then
				onFinished(false)
			end
			return
		end

		local subtitle = if typeof(payload.message) == "string" then payload.message else "Spell learned!"

		task.spawn(function()
			playReveal(token, camera, bookBuild, spell, subtitle)
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
		local page = bookBuild.pages[tapCount]
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
