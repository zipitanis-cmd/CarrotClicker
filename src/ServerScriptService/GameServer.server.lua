-- GameServer.server.lua
-- Main server script for Carrot Clicker.
-- Handles:
--   • Setting up RemoteEvents (via Remotes module)
--   • Click processing (value calculation, crit, golden clicks)
--   • Upgrade purchase validation
--   • Passive income ticks (once per second)
--   • Milestone checking
--   • Broadcasting UpdateState to clients

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ── Wait for shared modules ───────────────────────────────────────────────────
local Modules      = ReplicatedStorage:WaitForChild("Modules")
local GameConfig   = require(Modules:WaitForChild("GameConfig"))
local Remotes      = require(Modules:WaitForChild("Remotes"))

-- ── Set up RemoteEvents ───────────────────────────────────────────────────────
Remotes.setup()

-- ── Wait for DataStoreManager (loaded by its own Script in SSS) ──────────────
-- We use a BindableEvent pattern: DataStoreManager sets _G.DSM when ready.
-- Alternatively we require it directly since it's a Script (not ModuleScript).
-- For simplicity, poll until available.
local DSM
local function getDSM()
	if DSM then return DSM end
	-- DataStoreManager.server.lua exposes itself via _G
	local tries = 0
	while not _G.DataStoreManager and tries < 60 do
		task.wait(0.5)
		tries = tries + 1
	end
	DSM = _G.DataStoreManager
	if not DSM then
		warn("[GameServer] DataStoreManager not found — using in-memory fallback")
		-- Fallback: simple in-memory store (no persistence, safe for Studio tests)
		local mem = {}
		DSM = {
			loadData  = function(p)
				local d = mem[p.UserId]
				if not d then
					d = {}
					for k, v in pairs(GameConfig.DefaultData) do
						if type(v) == "table" then
							local cp = {}
							for kk, vv in pairs(v) do cp[kk] = vv end
							d[k] = cp
						else
							d[k] = v
						end
					end
					mem[p.UserId] = d
				end
				return d
			end,
			saveData   = function() end,
			getData    = function(p) return mem[p.UserId] end,
			updateData = function(p, fn) if mem[p.UserId] then fn(mem[p.UserId]) end end,
		}
	end
	return DSM
end

-- ── Helpers ───────────────────────────────────────────────────────────────────

-- Send full state to a specific player
local function sendState(player)
	local dsm  = getDSM()
	local data = dsm.getData(player)
	if not data then return end
	Remotes.get("UpdateState"):FireClient(player, data)
end

-- Check milestones against totalCarrotsAllTime and fire events for newly completed ones
local function checkMilestones(player)
	local dsm  = getDSM()
	local data = dsm.getData(player)
	if not data then return end

	for _, ms in ipairs(GameConfig.Milestones) do
		if not data.milestones[ms.id] and data.totalCarrotsAllTime >= ms.threshold then
			data.milestones[ms.id] = true
			Remotes.get("MilestoneReached"):FireClient(player, ms)
			print(string.format("[GameServer] %s reached milestone: %s", player.Name, ms.name))
		end
	end
end

-- Add carrots to a player's data (all three counters)
local function addCarrots(player, amount)
	local dsm = getDSM()
	dsm.updateData(player, function(data)
		data.carrots             = data.carrots             + amount
		data.carrotsThisRun      = data.carrotsThisRun      + amount
		data.totalCarrotsAllTime = data.totalCarrotsAllTime + amount
	end)
end

-- ── Click Handler ─────────────────────────────────────────────────────────────
Remotes.get("ClickCarrot").OnServerEvent:Connect(function(player, streak)
	local dsm  = getDSM()
	local data = dsm.getData(player)
	if not data then return end

	-- Increment total click count
	data.totalClicks = (data.totalClicks or 0) + 1

	-- Determine click value
	local value, isCrit, _ = GameConfig.computeClickValue(data, streak or 0)

	-- Golden Click override (every GOLDEN_CLICK_EVERY clicks)
	local isGolden = (data.totalClicks % GameConfig.GOLDEN_CLICK_EVERY == 0)
	if isGolden then
		value = math.floor(value * GameConfig.GOLDEN_CLICK_MULTI)
	end

	-- Apply carrots
	addCarrots(player, value)

	-- Notify client of special clicks
	if isCrit then
		Remotes.get("CritNotify"):FireClient(player, value)
	end
	if isGolden then
		Remotes.get("GoldenClickNotify"):FireClient(player, value)
	end

	-- Check milestones
	checkMilestones(player)

	-- Broadcast updated state
	sendState(player)
end)

-- ── Upgrade Purchase Handler ──────────────────────────────────────────────────
Remotes.get("BuyUpgrade").OnServerEvent:Connect(function(player, upgradeKey, quantity)
	local dsm  = getDSM()
	local data = dsm.getData(player)
	if not data then return end

	local upg = GameConfig.UpgradeMap[upgradeKey]
	if not upg then
		warn(string.format("[GameServer] Unknown upgrade key '%s' from %s", tostring(upgradeKey), player.Name))
		return
	end

	-- Unlock check: totalCarrotsAllTime must have reached threshold
	if data.totalCarrotsAllTime < upg.unlockAt then
		return  -- silently deny; client should already hide locked upgrades
	end

	-- Resolve quantity
	local qty = tonumber(quantity) or 1
	if qty <= 0 then return end

	-- "Max" mode: figure out how many we can afford
	if qty == -1 then
		qty = 0
		local testLevel = data.upgrades[upgradeKey] or 0
		local testCarrots = data.carrots
		while true do
			if upg.maxLevel and testLevel >= upg.maxLevel then break end
			local cost = GameConfig.getUpgradeCost(upgradeKey, testLevel)
			if testCarrots < cost then break end
			testCarrots = testCarrots - cost
			testLevel   = testLevel + 1
			qty         = qty + 1
			if qty > 10000 then break end  -- safety cap
		end
		if qty == 0 then return end
	end

	-- Purchase loop
	local currentLevel = data.upgrades[upgradeKey] or 0
	for i = 1, qty do
		if upg.maxLevel and currentLevel >= upg.maxLevel then break end
		local cost = GameConfig.getUpgradeCost(upgradeKey, currentLevel)
		if data.carrots < cost then break end
		data.carrots                = data.carrots - cost
		currentLevel                = currentLevel + 1
		data.upgrades[upgradeKey]   = currentLevel
	end

	-- Check milestones
	checkMilestones(player)

	-- Broadcast updated state
	sendState(player)
end)

-- ── Passive Income Tick ───────────────────────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(GameConfig.PASSIVE_TICK_RATE)
		for _, player in ipairs(Players:GetPlayers()) do
			local dsm  = getDSM()
			local data = dsm.getData(player)
			if data then
				local income = GameConfig.computePassiveIncome(data)
				if income > 0 then
					addCarrots(player, income)
					checkMilestones(player)
					sendState(player)
				end
			end
		end
	end
end)

-- ── Player Joined: send initial state ────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	-- Give DataStoreManager time to load
	task.delay(1, function()
		sendState(player)
	end)
end)

-- For players already in-game (Studio test)
for _, player in ipairs(Players:GetPlayers()) do
	task.delay(1, function()
		sendState(player)
	end)
end

print("[GameServer] Carrot Clicker server started.")
