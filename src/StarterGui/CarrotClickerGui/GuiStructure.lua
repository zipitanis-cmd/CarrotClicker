-- GuiStructure.lua
-- Documents the complete ScreenGui hierarchy for Carrot Clicker.
-- This file serves as both documentation AND as the reference used by
-- BuildScripts/BuildAll.lua when constructing the GUI tree in Roblox Studio.
--
-- Tree notation:
--   ScreenGui (CarrotClickerGui)
--   ├── Background                     Frame, full-screen dark base
--   │   ├── FineGrid                   ImageLabel, tile grid overlay (fine)
--   │   ├── CoarseGrid                 ImageLabel, tile grid overlay (coarse)
--   │   ├── CenterGlow                 ImageLabel, radial gradient behind carrot
--   │   └── Vignette                   ImageLabel, dark edges vignette
--   ├── TopBar                         Frame, ~9% screen height
--   │   ├── Title                      TextLabel  "🥕 Carrot Clicker"
--   │   ├── CurrencyDisplay            Frame
--   │   │   ├── CarrotsAmount          TextLabel  (large, orange, bold)
--   │   │   ├── PerSec                 TextLabel  "/s"
--   │   │   └── PerClick               TextLabel  "/click"
--   │   └── RightGroup                 Frame
--   │       ├── SeedsAmount            TextLabel  (Seeds: 0)
--   │       └── SettingsButton         TextButton  "⚙"
--   ├── LeftRail                        Frame, ~75px wide, full height below TopBar
--   │   ├── HomeTab                    TextButton  "🏠"
--   │   ├── UpgradesTab                TextButton  "⬆"
--   │   ├── ReplantTab                 TextButton  "🌱" (locked)
--   │   ├── PetsTab                    TextButton  "🐇" (locked)
--   │   ├── QuestsTab                  TextButton  "📋" (locked)
--   │   └── ShopTab                    TextButton  "🛒" (locked)
--   ├── MainArea                        Frame, center play zone
--   │   ├── CarrotButtonPlate          Frame  circular plate
--   │   │   ├── GlowRing               Frame  pulsing outer ring
--   │   │   └── CarrotButton           ImageButton  "🥕" (large)
--   │   ├── FloatingTextLayer          Frame, clipsDescendants=false (floating +N numbers spawn here)
--   │   ├── StreakMeter                Frame
--   │   │   ├── StreakLabel            TextLabel  "Harvest Streak: 0x"
--   │   │   ├── StreakBarBg            Frame  bar background
--   │   │   │   └── StreakBarFill      Frame  bar fill
--   │   │   └── StreakLostLabel        TextLabel  "Streak Lost!" (hidden)
--   │   └── MilestoneTracker           Frame
--   │       ├── MilestoneLabel         TextLabel  "Next Unlock: First Harvest"
--   │       ├── MilestoneBarBg         Frame
--   │       │   └── MilestoneBarFill   Frame
--   │       └── RewardChip             TextLabel  (shows reward name, hidden by default)
--   ├── RightPanel                      Frame, ~30% screen width
--   │   ├── PanelHeader                TextLabel  "Upgrades"
--   │   ├── CategoryTabs               Frame  (horizontal tab strip)
--   │   │   ├── TabClick               TextButton  "Click"
--   │   │   ├── TabIdle                TextButton  "Idle"
--   │   │   ├── TabBoosts              TextButton  "Boosts"
--   │   │   └── TabUnlocks             TextButton  "Unlocks"
--   │   └── UpgradeScrollFrame         ScrollingFrame
--   │       └── UpgradeListLayout      UIListLayout
--   │           (Upgrade cards are cloned here at runtime by GameClient)
--   └── BottomBar                       Frame, ~7% screen height
--       ├── BuyModeX1                  TextButton  "x1"
--       ├── BuyModeX10                 TextButton  "x10"
--       ├── BuyModeX100                TextButton  "x100"
--       ├── BuyModeMax                 TextButton  "Max"
--       └── AutoToggle                 TextButton  "Auto 🔒" (locked)

-- This module simply returns the structure description as a table for reference.
local GuiStructure = {
	description = "CarrotClickerGui full ScreenGui hierarchy — see file comments for tree.",
	version     = "Phase1",
}

return GuiStructure
