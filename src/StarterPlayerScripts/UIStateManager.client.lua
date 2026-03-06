-- UIStateManager.client.lua
-- Manages panel visibility, tab switching, buy-mode selection, and tooltip display.
-- Works with the GUI tree built by BuildAll.lua.

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")

local player         = Players.LocalPlayer
local playerGui      = player:WaitForChild("PlayerGui")
local gui            = playerGui:WaitForChild("CarrotClickerGui")

-- ── References ─────────────────────────────────────────────────────────────────
local rightPanel     = gui:WaitForChild("RightPanel")
local categoryTabs   = rightPanel:WaitForChild("CategoryTabs")
local scrollFrame    = rightPanel:WaitForChild("UpgradeScrollFrame")

local bottomBar      = gui:WaitForChild("BottomBar")
local leftRail       = gui:WaitForChild("LeftRail")

-- ── State ──────────────────────────────────────────────────────────────────────
local UIStateManager = {}

UIStateManager.buyMode    = 1      -- 1 | 10 | 100 | -1 (Max)
UIStateManager.activeTab  = "Click"
UIStateManager.buyModeChanged = Instance.new("BindableEvent")

-- ── Color helpers ─────────────────────────────────────────────────────────────
local ACCENT     = Color3.fromRGB(255, 165, 0)
local PANEL_BG   = Color3.fromRGB(35, 35, 60)
local MUTED      = Color3.fromRGB(60, 60, 80)
local TEXT_PRI   = Color3.fromRGB(255, 255, 255)
local TEXT_MUT   = Color3.fromRGB(120, 120, 140)

local function tweenColor(obj, prop, target, dur)
	local info = TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(obj, info, { [prop] = target }):Play()
end

-- ── Buy Mode ──────────────────────────────────────────────────────────────────
local buyButtons = {
	{ name = "BuyModeX1",   value = 1   },
	{ name = "BuyModeX10",  value = 10  },
	{ name = "BuyModeX100", value = 100 },
	{ name = "BuyModeMax",  value = -1  },
}

local function refreshBuyMode()
	for _, entry in ipairs(buyButtons) do
		local btn = bottomBar:FindFirstChild(entry.name)
		if btn then
			if UIStateManager.buyMode == entry.value then
				btn.BackgroundColor3 = ACCENT
				btn.TextColor3       = Color3.fromRGB(26, 26, 46)
			else
				btn.BackgroundColor3 = PANEL_BG
				btn.TextColor3       = TEXT_PRI
			end
		end
	end
end

for _, entry in ipairs(buyButtons) do
	local btn = bottomBar:FindFirstChild(entry.name)
	if btn then
		btn.MouseButton1Click:Connect(function()
			UIStateManager.buyMode = entry.value
			refreshBuyMode()
			UIStateManager.buyModeChanged:Fire(entry.value)
		end)
	end
end

-- ── Category Tabs ─────────────────────────────────────────────────────────────
local tabNames = { "Click", "Idle", "Boosts", "Unlocks" }

local function refreshCategoryTabs()
	for _, tabName in ipairs(tabNames) do
		local btn = categoryTabs:FindFirstChild("Tab" .. tabName)
		if btn then
			if UIStateManager.activeTab == tabName then
				btn.BackgroundColor3 = ACCENT
				btn.TextColor3       = Color3.fromRGB(26, 26, 46)
			else
				btn.BackgroundColor3 = MUTED
				btn.TextColor3       = TEXT_PRI
			end
		end
	end

	-- Show/hide upgrade rows based on active category
	-- (Cards have a .Category attribute set by GameClient)
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			local catAttr = child:GetAttribute("Category")
			if catAttr then
				local shouldShow = (UIStateManager.activeTab == catAttr)
					or (UIStateManager.activeTab == "Unlocks")  -- Unlocks tab shows all
				child.Visible = shouldShow
			end
		end
	end
end

for _, tabName in ipairs(tabNames) do
	local btn = categoryTabs:FindFirstChild("Tab" .. tabName)
	if btn then
		btn.MouseButton1Click:Connect(function()
			UIStateManager.activeTab = tabName
			refreshCategoryTabs()
		end)
	end
end

-- ── Left Rail Tabs ────────────────────────────────────────────────────────────
-- Only Home and Upgrades are functional in Phase 1.
-- Locked tabs show a tooltip.

local function makeTooltip(parent, text)
	local tooltip = Instance.new("TextLabel")
	tooltip.Name              = "Tooltip"
	tooltip.Text              = text
	tooltip.Size              = UDim2.new(0, 120, 0, 30)
	tooltip.Position          = UDim2.new(1, 6, 0.5, -15)
	tooltip.BackgroundColor3  = Color3.fromRGB(20, 20, 35)
	tooltip.BackgroundTransparency = 0.1
	tooltip.TextColor3        = TEXT_PRI
	tooltip.TextSize          = 11
	tooltip.Font              = Enum.Font.GothamMedium
	tooltip.BorderSizePixel   = 0
	tooltip.ZIndex            = 20
	tooltip.Visible           = false

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = tooltip

	tooltip.Parent = parent
	return tooltip
end

local railTabDefs = {
	{ name = "HomeTab",     locked = false },
	{ name = "UpgradesTab", locked = false },
	{ name = "ReplantTab",  locked = true,  tip = "Coming Soon" },
	{ name = "PetsTab",     locked = true,  tip = "Coming Soon" },
	{ name = "QuestsTab",   locked = true,  tip = "Coming Soon" },
	{ name = "ShopTab",     locked = true,  tip = "Coming Soon" },
}

for _, def in ipairs(railTabDefs) do
	local btn = leftRail:FindFirstChild(def.name)
	if btn then
		if def.locked then
			local tip = makeTooltip(btn, def.tip or "Locked")
			btn.MouseEnter:Connect(function()  tip.Visible = true  end)
			btn.MouseLeave:Connect(function()  tip.Visible = false end)
		else
			btn.MouseButton1Click:Connect(function()
				-- Home and Upgrades toggle right panel visibility
				if def.name == "UpgradesTab" then
					rightPanel.Visible = not rightPanel.Visible
				end
			end)
		end
	end
end

-- ── Initial state ─────────────────────────────────────────────────────────────
refreshBuyMode()
refreshCategoryTabs()

-- Expose refresh functions for GameClient to call after state updates
UIStateManager.refreshCategoryTabs = refreshCategoryTabs

return UIStateManager
