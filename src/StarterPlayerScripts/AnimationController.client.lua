-- AnimationController.client.lua
-- All micro-animations for Carrot Clicker:
--   • Carrot button press/bounce
--   • Click ripple
--   • Floating "+N" number labels
--   • Glow ring pulse
--   • Streak bar smooth fill
--   • Milestone bar smooth fill + confetti burst
--   • Currency counter smooth count-up with scale pop
--   • Crit sparkle / golden flash
--   • Grid parallax drift

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local player       = Players.LocalPlayer
local playerGui    = player:WaitForChild("PlayerGui")
local gui          = playerGui:WaitForChild("CarrotClickerGui")

local AnimationController = {}

-- ── GUI references (wait up to 10s each) ─────────────────────────────────────
local mainArea       = gui:WaitForChild("MainArea")
local carrotPlate    = mainArea:WaitForChild("CarrotButtonPlate")
local carrotButton   = carrotPlate:WaitForChild("CarrotButton")
local glowRing       = carrotPlate:WaitForChild("GlowRing")
local floatLayer     = mainArea:WaitForChild("FloatingTextLayer")
local streakMeter    = mainArea:WaitForChild("StreakMeter")
local streakBarFill  = streakMeter:WaitForChild("StreakBarBg"):WaitForChild("StreakBarFill")
local streakLostLbl  = streakMeter:WaitForChild("StreakLostLabel")
local milestone      = mainArea:WaitForChild("MilestoneTracker")
local msBarFill      = milestone:WaitForChild("MilestoneBarBg"):WaitForChild("MilestoneBarFill")
local msRewardChip   = milestone:WaitForChild("RewardChip")
local topBar         = gui:WaitForChild("TopBar")
local currDisp       = topBar:WaitForChild("CurrencyDisplay")
local carrotsLbl     = currDisp:WaitForChild("CarrotsAmount")
local perSecLbl      = currDisp:WaitForChild("PerSec")
local perClickLbl    = currDisp:WaitForChild("PerClick")

-- Background for parallax
local background     = gui:WaitForChild("Background")
local fineGrid       = background:FindFirstChild("FineGrid")
local coarseGrid     = background:FindFirstChild("CoarseGrid")

-- ── Utility ───────────────────────────────────────────────────────────────────
local function tween(obj, props, dur, style, dir)
	style = style or Enum.EasingStyle.Quad
	dir   = dir   or Enum.EasingDirection.Out
	local info = TweenInfo.new(dur, style, dir)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

-- ── Glow Ring Pulse (continuous) ─────────────────────────────────────────────
local function startGlowPulse()
	local function doPulse()
		tween(glowRing, { BackgroundTransparency = 0.65, Size = UDim2.new(1.14, 0, 1.14, 0) }, 1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.delay(1.0, function()
			tween(glowRing, { BackgroundTransparency = 0.82, Size = UDim2.new(1.08, 0, 1.08, 0) }, 1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		end)
	end

	task.spawn(function()
		while true do
			doPulse()
			task.wait(2.0)
		end
	end)
end

-- ── Carrot Button Press Animation ────────────────────────────────────────────
function AnimationController.playClickAnim(isGolden, isCrit)
	-- Press down
	tween(carrotButton, { Size = UDim2.new(0.965, 0, 0.965, 0) }, 0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	-- Bounce back with slight overshoot
	task.delay(0.07, function()
		tween(carrotButton, { Size = UDim2.new(1.0, 0, 1.0, 0) }, 0.13, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)

	-- Golden flash
	if isGolden then
		local origColor = carrotButton.ImageColor3 or carrotButton.BackgroundColor3
		tween(carrotButton, { ImageColor3 = Color3.fromRGB(255, 215, 0) }, 0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(0.25, function()
			tween(carrotButton, { ImageColor3 = origColor }, 0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end)
	end

	-- Crit scale pop
	if isCrit then
		tween(carrotButton, { Size = UDim2.new(1.15, 0, 1.15, 0) }, 0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		task.delay(0.08, function()
			tween(carrotButton, { Size = UDim2.new(1.0, 0, 1.0, 0) }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)
	end
end

-- ── Click Ripple ──────────────────────────────────────────────────────────────
function AnimationController.spawnRipple()
	local ripple = Instance.new("Frame")
	ripple.Name                   = "Ripple"
	ripple.Size                   = UDim2.new(0.9, 0, 0.9, 0)
	ripple.AnchorPoint            = Vector2.new(0.5, 0.5)
	ripple.Position               = UDim2.new(0.5, 0, 0.5, 0)
	ripple.BackgroundColor3       = Color3.fromRGB(255, 165, 0)
	ripple.BackgroundTransparency = 0.65
	ripple.BorderSizePixel        = 0
	ripple.ZIndex                 = carrotButton.ZIndex + 1
	ripple.Parent                 = carrotPlate

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ripple

	-- Expand and fade
	tween(ripple, {
		Size                   = UDim2.new(1.25, 0, 1.25, 0),
		BackgroundTransparency = 1.0,
	}, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	task.delay(0.25, function()
		ripple:Destroy()
	end)
end

-- ── Floating "+N" Numbers ─────────────────────────────────────────────────────
function AnimationController.spawnFloatingNumber(amount, isCrit, isGolden)
	local label = Instance.new("TextLabel")
	label.Name                   = "FloatNum"
	label.Text                   = "+" .. tostring(amount)
	label.Font                   = Enum.Font.GothamBold
	label.TextSize               = isCrit and 22 or (isGolden and 20 or 16)
	label.BackgroundTransparency = 1
	label.BorderSizePixel        = 0
	label.ZIndex                 = 15

	if isGolden then
		label.TextColor3 = Color3.fromRGB(255, 215, 0)
	elseif isCrit then
		label.TextColor3 = Color3.fromRGB(255, 100, 50)
	else
		label.TextColor3 = Color3.fromRGB(255, 200, 80)
	end

	-- Randomise horizontal start position slightly
	local xOffset = math.random(-30, 30)
	label.Size     = UDim2.new(0, 80, 0, 28)
	label.Position = UDim2.new(0.5, xOffset - 40, 0.5, 0)
	label.AnchorPoint = Vector2.new(0, 0)

	label.Parent = floatLayer

	-- Float upward and fade
	local driftY = math.random(40, 70)
	tween(label, {
		Position              = UDim2.new(0.5, xOffset - 40, 0.5, -driftY),
		TextTransparency      = 1.0,
		TextStrokeTransparency = 1.0,
	}, math.random(35, 55) / 100, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	task.delay(0.6, function()
		label:Destroy()
	end)
end

-- ── Click Particles ───────────────────────────────────────────────────────────
function AnimationController.spawnClickParticles(isCrit)
	local count = isCrit and math.random(6, 10) or math.random(2, 4)
	for _ = 1, count do
		local p = Instance.new("Frame")
		p.Name                   = "Particle"
		p.Size                   = UDim2.new(0, math.random(4, 8), 0, math.random(4, 8))
		p.AnchorPoint            = Vector2.new(0.5, 0.5)
		p.Position               = UDim2.new(0.5, 0, 0.5, 0)
		p.BackgroundColor3       = isCrit
			and Color3.fromRGB(255, math.random(100, 200), 0)
			or  Color3.fromRGB(255, 165, 0)
		p.BackgroundTransparency = 0
		p.BorderSizePixel        = 0
		p.ZIndex                 = 16
		p.Parent                 = floatLayer

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 2)
		corner.Parent = p

		local angle   = math.rad(math.random(0, 360))
		local dist    = math.random(30, 80)
		local targetX = math.cos(angle) * dist
		local targetY = math.sin(angle) * dist
		local dur     = math.random(20, 60) / 100

		tween(p, {
			Position               = UDim2.new(0.5, targetX, 0.5, targetY),
			BackgroundTransparency = 1,
		}, dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		task.delay(dur + 0.05, function()
			p:Destroy()
		end)
	end
end

-- ── Streak Bar ────────────────────────────────────────────────────────────────
function AnimationController.updateStreakBar(streak, max)
	local fillX = math.clamp(streak / max, 0, 1)
	tween(streakBarFill, { Size = UDim2.new(fillX, 0, 1, 0) }, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function AnimationController.flashStreakLost()
	streakLostLbl.Visible = true
	streakLostLbl.TextTransparency = 0
	task.delay(0.4, function()
		tween(streakLostLbl, { TextTransparency = 1 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(0.25, function()
			streakLostLbl.Visible = false
		end)
	end)
end

-- ── Milestone Bar ─────────────────────────────────────────────────────────────
function AnimationController.updateMilestoneBar(progress)
	-- progress = 0..1
	local fillX = math.clamp(progress, 0, 1)
	tween(msBarFill, { Size = UDim2.new(fillX, 0, 1, 0) }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Pulse when near completion
	if fillX >= 0.85 then
		local function pulse()
			tween(msBarFill, { BackgroundTransparency = 0.3 }, 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.delay(0.4, function()
				tween(msBarFill, { BackgroundTransparency = 0 }, 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			end)
		end
		task.spawn(pulse)
	end
end

-- ── Milestone Complete: confetti burst ───────────────────────────────────────
function AnimationController.milestoneComplete(milestoneName)
	-- Fill bar
	tween(msBarFill, { Size = UDim2.new(1, 0, 1, 0) }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Flash the bar white briefly
	local origColor = msBarFill.BackgroundColor3
	tween(msBarFill, { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	task.delay(0.2, function()
		tween(msBarFill, { BackgroundColor3 = origColor }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end)

	-- Show reward chip
	msRewardChip.Text = "🎉 " .. milestoneName
	msRewardChip.TextTransparency = 0
	msRewardChip.Visible = true
	task.delay(0.9, function()
		tween(msRewardChip, { TextTransparency = 1 }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(0.35, function()
			msRewardChip.Visible = false
		end)
	end)

	-- Confetti (12-20 square particles)
	local confettiCount = math.random(12, 20)
	for _ = 1, confettiCount do
		local p = Instance.new("Frame")
		p.Name                   = "Confetti"
		p.Size                   = UDim2.new(0, math.random(5, 10), 0, math.random(5, 10))
		p.AnchorPoint            = Vector2.new(0.5, 0.5)
		p.Position               = UDim2.new(math.random(20, 80) / 100, 0, 0.5, 0)
		p.BackgroundColor3       = Color3.fromRGB(math.random(150,255), math.random(150,255), math.random(50,255))
		p.BackgroundTransparency = 0
		p.BorderSizePixel        = 0
		p.ZIndex                 = 18
		p.Parent                 = milestone

		local dur = math.random(40, 90) / 100
		tween(p, {
			Position               = UDim2.new(p.Position.X.Scale, 0, p.Position.Y.Scale - 0.4, 0),
			BackgroundTransparency = 1,
		}, dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		task.delay(dur + 0.05, function()
			p:Destroy()
		end)
	end
end

-- ── Currency Label Pop ────────────────────────────────────────────────────────
function AnimationController.popCurrencyLabel()
	-- Brief scale pop: 1.0 → 1.04 → 1.0
	tween(carrotsLbl, { TextSize = math.floor(carrotsLbl.TextSize * 1.04) }, 0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	task.delay(0.1, function()
		tween(carrotsLbl, { TextSize = carrotsLbl.TextSize }, 0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end)
end

-- ── Upgrade Purchase Flash ────────────────────────────────────────────────────
function AnimationController.flashUpgradeRow(row)
	if not row then return end
	local orig = row.BackgroundColor3
	tween(row, { BackgroundColor3 = Color3.fromRGB(76, 175, 80) }, 0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	task.delay(0.14, function()
		tween(row, { BackgroundColor3 = orig }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end)
end

-- ── Upgrade Can't Afford Shake ────────────────────────────────────────────────
function AnimationController.shakeButton(btn)
	if not btn then return end
	local orig = btn.Position
	local ox   = orig.X.Offset
	local shakeSeq = { 5, -5, 4, -4, 2, 0 }
	local delay = 0
	for _, v in ipairs(shakeSeq) do
		local step = delay
		task.delay(step, function()
			tween(btn, { Position = UDim2.new(orig.X.Scale, ox + v, orig.Y.Scale, orig.Y.Offset) }, 0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end)
		delay = delay + 0.04
	end
	-- Red tint flash
	tween(btn, { BackgroundColor3 = Color3.fromRGB(220, 50, 50) }, 0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	task.delay(0.3, function()
		tween(btn, { BackgroundColor3 = Color3.fromRGB(60, 60, 80) }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end)
end

-- ── Grid Parallax Drift ───────────────────────────────────────────────────────
local function startGridDrift()
	if not fineGrid and not coarseGrid then return end

	-- drift amplitude and period randomised per layer
	local function driftLayer(img, amp, period)
		if not img then return end
		task.spawn(function()
			local t = 0
			local baseOff = img.ImageRectOffset
			local startX  = baseOff.X
			local startY  = baseOff.Y
			while true do
				RunService.Heartbeat:Wait()
				local dt = 1/60  -- approximate
				t = t + dt
				local newX = startX + math.sin(t * math.pi * 2 / period) * amp
				local newY = startY + math.cos(t * math.pi * 2 / period) * amp
				img.ImageRectOffset = Vector2.new(newX, newY)
			end
		end)
	end

	driftLayer(fineGrid,   12, 30)
	driftLayer(coarseGrid, 8,  40)
end

-- ── Start persistent animations ───────────────────────────────────────────────
startGlowPulse()
startGridDrift()

return AnimationController
