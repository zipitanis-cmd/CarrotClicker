-- GuiStructure.lua
-- Documents the complete ScreenGui hierarchy for Carrot Clicker (Phase 1 v2).
-- Uses IgnoreGuiInset=true and fixed-pixel sizing for consistency across screen sizes.
--
-- Layout dimensions:
--   TOP_H    = 52px  (TopBar)
--   BOTTOM_H = 48px  (BottomBar)
--   RAIL_W   = 60px  (LeftRail)
--   PANEL_W  = 290px (RightPanel / Upgrades)
--   MainArea = fills remaining space between rails
--
-- Tree notation:
--   ScreenGui (CarrotClickerGui) -- IgnoreGuiInset=true
--   Background (full-screen, dark #12121e)
--     FineGrid, CoarseGrid, CenterGlow
--   TopBar (52px fixed, full-width)
--     BottomLine, Title, CurrencyDisplay (CarrotsAmount, StatsRow > PerSec/PerClick)
--     RightGroup (SeedsAmount, SettingsButton)
--   LeftRail (60px wide, full height between bars)
--     HomeTab, UpgradesTab, ReplantTab(*), PetsTab(*), QuestsTab(*), ShopTab(*)
--     (*) locked tabs have a LockBadge child label
--   RightPanel (290px wide, full height between bars)
--     LeftLine, PanelHeaderRow (PanelHeader, HeaderDivider)
--     CategoryTabs (TabClick, TabIdle, TabBoosts, TabUnlocks)
--     UpgradeScrollFrame (UIListLayout + runtime upgrade cards)
--   MainArea (fills space between rails, below TopBar, above BottomBar)
--     CarrotButtonPlate (230x230, centred at 0.5,0.42)
--       GlowRing (1.08 scale, pulses to 1.14)
--       CarrotButton (0.90 scale, emoji "🥕")
--     FloatingTextLayer (clipsDescendants=false)
--     StreakMeter (280px wide, centred at 0.5,0.70)
--       StreakLabel, StreakBarBg > StreakBarFill, StreakLostLabel
--     MilestoneTracker (280px wide, centred at 0.5,0.82)
--       MilestoneLabel, MilestoneBarBg > MilestoneBarFill, RewardChip
--   BottomBar (48px fixed, full-width, pinned to bottom)
--     TopLine, BuyModeX1, BuyModeX10, BuyModeX100, BuyModeMax, AutoToggle
--   PopupsLayer (ZIndex=50, full-screen)

local GuiStructure = {
description = "CarrotClickerGui full ScreenGui hierarchy — see file comments for tree.",
version     = "Phase1-v2",
}

return GuiStructure
