-- GameConfig.lua
-- All constants, upgrade definitions, milestone thresholds, and scaling parameters
-- for Carrot Clicker Phase 1.

local GameConfig = {}

-- ── Passive income tick rate ─────────────────────────────────────────────────
GameConfig.PASSIVE_TICK_RATE = 1          -- seconds between server passive-income ticks

-- ── DataStore key prefix ──────────────────────────────────────────────────────
GameConfig.DATA_KEY_PREFIX = "PlayerData_"
GameConfig.AUTOSAVE_INTERVAL = 120        -- seconds between autosaves
GameConfig.SAVE_RETRIES       = 3         -- max retry attempts on DataStore failure

-- ── Click mechanics ───────────────────────────────────────────────────────────
GameConfig.BASE_CLICK_VALUE     = 1       -- carrots per click before modifiers
GameConfig.GOLDEN_CLICK_EVERY   = 25      -- every Nth click is 10× (Golden Click)
GameConfig.GOLDEN_CLICK_MULTI   = 10

-- ── Streak mechanics ─────────────────────────────────────────────────────────
GameConfig.STREAK_MAX           = 50
GameConfig.STREAK_WINDOW        = 2       -- seconds; click within window to build streak
GameConfig.STREAK_DECAY_DELAY   = 0.6    -- seconds before streak starts draining
GameConfig.STREAK_DECAY_DURATION= 1.0    -- seconds to drain fully

-- ── Crit defaults (before upgrades) ─────────────────────────────────────────
GameConfig.BASE_CRIT_CHANCE     = 0      -- 0 = 0%; each Crit Chance level adds 0.02
GameConfig.BASE_CRIT_POWER      = 5      -- 5× click value; each Crit Power level adds 1

-- ── Upgrade definitions ───────────────────────────────────────────────────────
-- Fields:
--   key          unique string identifier
--   name         display name
--   description  short description
--   category     "Click" | "Idle" | "Boosts"
--   baseCost     cost at level 0
--   costMult     geometric scale per level
--   effectDesc   template for effect text ("%d" replaced by current level)
--   unlockAt     carrots total required to appear (0 = always visible)
--   maxLevel     optional cap (nil = unlimited)
GameConfig.Upgrades = {
	{
		key         = "ClickPower",
		name        = "Click Power",
		description = "Sharpen your harvest technique.",
		category    = "Click",
		baseCost    = 10,
		costMult    = 1.15,
		effectDesc  = "+%d carrot/click",
		unlockAt    = 0,
	},
	{
		key         = "AutoFarmer",
		name        = "Auto Farmer",
		description = "A tireless carrot-picking robot.",
		category    = "Idle",
		baseCost    = 50,
		costMult    = 1.18,
		effectDesc  = "+%d carrot/sec",
		unlockAt    = 0,
	},
	{
		key         = "Compost",
		name        = "Compost",
		description = "Enriches all production globally.",
		category    = "Boosts",
		baseCost    = 500,
		costMult    = 1.35,
		effectDesc  = "+%d×10%% global multiplier",
		unlockAt    = 10000,
	},
	{
		key         = "CritChance",
		name        = "Crit Chance",
		description = "Chance to land a critical harvest.",
		category    = "Click",
		baseCost    = 200,
		costMult    = 1.25,
		effectDesc  = "+%d×2%% crit chance",
		unlockAt    = 1000,
		maxLevel    = 25,   -- caps crit at 50%
	},
	{
		key         = "CritPower",
		name        = "Crit Power",
		description = "Multiplies critical hit value.",
		category    = "Click",
		baseCost    = 1000,
		costMult    = 1.30,
		effectDesc  = "+%d×1 crit multiplier",
		unlockAt    = 50000,
	},
}

-- Fast lookup by key
GameConfig.UpgradeMap = {}
for _, upg in ipairs(GameConfig.Upgrades) do
	GameConfig.UpgradeMap[upg.key] = upg
end

-- ── Milestone definitions ─────────────────────────────────────────────────────
GameConfig.Milestones = {
	{ id = "FirstHarvest",   threshold = 100,       name = "First Harvest",        reward = "badge" },
	{ id = "UnlockCrit",     threshold = 1000,      name = "Sharp Eye",            reward = "unlock:CritChance" },
	{ id = "UnlockCompost",  threshold = 10000,     name = "Rich Soil",            reward = "unlock:Compost" },
	{ id = "UnlockCritPow",  threshold = 50000,     name = "Critical Farming",     reward = "unlock:CritPower" },
	{ id = "Replant",        threshold = 250000,    name = "Replant Available",    reward = "tease:Phase2" },
	{ id = "Millionaire",    threshold = 1000000,   name = "Millionaire Farmer",   reward = "badge" },
}

-- ── Default player data ───────────────────────────────────────────────────────
GameConfig.DefaultData = {
	carrots              = 0,
	carrotsThisRun       = 0,
	totalCarrotsAllTime  = 0,
	upgrades             = {
		ClickPower  = 0,
		AutoFarmer  = 0,
		Compost     = 0,
		CritChance  = 0,
		CritPower   = 0,
	},
	milestones           = {},   -- { [milestoneId] = true }
	totalClicks          = 0,
	lastSave             = 0,
}

-- ── Helper: upgrade cost at a given level ─────────────────────────────────────
function GameConfig.getUpgradeCost(upgradeKey, level)
	local upg = GameConfig.UpgradeMap[upgradeKey]
	if not upg then return math.huge end
	return math.floor(upg.baseCost * (upg.costMult ^ level))
end

-- ── Helper: compute click value from player state ─────────────────────────────
function GameConfig.computeClickValue(data, streak)
	local clickPower  = data.upgrades.ClickPower  or 0
	local compost     = data.upgrades.Compost     or 0
	local critChance  = (data.upgrades.CritChance or 0) * 0.02
	local critPower   = GameConfig.BASE_CRIT_POWER + (data.upgrades.CritPower or 0)
	local globalMult  = 1 + compost * 0.10

	local base     = (GameConfig.BASE_CLICK_VALUE + clickPower) * globalMult
	local streakBn = 1 + (streak or 0) / 100
	local value    = math.floor(base * streakBn)
	local isCrit   = (math.random() < critChance)
	local isGolden = false  -- determined by caller based on click count

	if isCrit then
		value = math.floor(value * critPower)
	end

	return value, isCrit, isGolden
end

-- ── Helper: compute passive income from player state ─────────────────────────
function GameConfig.computePassiveIncome(data)
	local autoFarmer = data.upgrades.AutoFarmer or 0
	local compost    = data.upgrades.Compost    or 0
	local globalMult = 1 + compost * 0.10
	return math.floor(autoFarmer * globalMult)
end

return GameConfig
