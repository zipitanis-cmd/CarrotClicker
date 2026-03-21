-- DataStoreManager.server.lua
-- Handles saving and loading player data using DataStoreService.
-- Features: autosave every 120s, save on PlayerRemoving, save on BindToClose,
-- pcall error handling with up to 3 retries.

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")

-- Load shared config (wait for it in case module hasn't replicated yet)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local DataStoreManager = {}

-- ── DataStore reference ──────────────────────────────────────────────────────
local playerDataStore = DataStoreService:GetDataStore("CarrotClickerData_v1")

-- In-memory cache: [userId] = data table
local cache = {}

-- ── Helpers ───────────────────────────────────────────────────────────────────

-- Deep-copy a table so the default template is not modified
local function deepCopy(tbl)
	local copy = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

-- Merge saved data onto the default template so new fields are always present
local function mergeDefaults(saved, default)
	local result = deepCopy(default)
	for k, v in pairs(saved) do
		if type(v) == "table" and type(result[k]) == "table" then
			result[k] = mergeDefaults(v, result[k])
		else
			result[k] = v
		end
	end
	return result
end

-- Retry a function up to maxRetries times with exponential back-off
local function withRetry(fn, maxRetries)
	local lastErr
	for attempt = 1, maxRetries do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		else
			lastErr = result
			warn(string.format("[DataStore] Attempt %d/%d failed: %s", attempt, maxRetries, tostring(lastErr)))
			if attempt < maxRetries then
				task.wait(2 ^ attempt)  -- 2s, 4s back-off
			end
		end
	end
	return false, lastErr
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Load data for a player; populate cache; returns the data table
function DataStoreManager.loadData(player)
	local userId = tostring(player.UserId)
	local key    = GameConfig.DATA_KEY_PREFIX .. userId

	local ok, result = withRetry(function()
		return playerDataStore:GetAsync(key)
	end, GameConfig.SAVE_RETRIES)

	local data
	if ok and result then
		data = mergeDefaults(result, GameConfig.DefaultData)
	else
		if not ok then
			warn("[DataStore] Failed to load data for " .. player.Name .. ": " .. tostring(result))
		end
		data = deepCopy(GameConfig.DefaultData)
	end

	data.lastSave = os.time()
	cache[userId] = data
	return data
end

-- Save data for a player; reads from cache
function DataStoreManager.saveData(player)
	local userId = tostring(player.UserId)
	local data   = cache[userId]
	if not data then return end

	local key = GameConfig.DATA_KEY_PREFIX .. userId
	data.lastSave = os.time()

	local ok, err = withRetry(function()
		playerDataStore:SetAsync(key, data)
	end, GameConfig.SAVE_RETRIES)

	if ok then
		print(string.format("[DataStore] Saved data for %s (%d carrots)", player.Name, data.carrots))
	else
		warn(string.format("[DataStore] FAILED to save data for %s: %s", player.Name, tostring(err)))
	end
end

-- Retrieve cached data for a player (returns nil if not loaded yet)
function DataStoreManager.getData(player)
	return cache[tostring(player.UserId)]
end

-- Update cached data (pass a function that mutates the data table)
function DataStoreManager.updateData(player, fn)
	local data = cache[tostring(player.UserId)]
	if data then fn(data) end
end

-- Track players whose data is currently being loaded to prevent duplicate loads
local loading = {}

-- ── Player lifecycle ──────────────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
	local userId = tostring(player.UserId)
	if loading[userId] or cache[userId] then return end
	loading[userId] = true
	DataStoreManager.loadData(player)
	loading[userId] = nil
	print("[DataStore] Loaded data for " .. player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
	DataStoreManager.saveData(player)
	local userId = tostring(player.UserId)
	cache[userId]   = nil
	loading[userId] = nil
end)

game:BindToClose(function()
	-- Save all remaining players (e.g., on server shutdown)
	for _, player in ipairs(Players:GetPlayers()) do
		DataStoreManager.saveData(player)
	end
end)

-- ── Autosave loop ─────────────────────────────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(GameConfig.AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			DataStoreManager.saveData(player)
		end
		print("[DataStore] Autosave complete.")
	end
end)

-- Pre-load data for any players already connected (e.g., Studio test).
-- Guard with the same loading flag to prevent duplicate loads if PlayerAdded
-- fires for the same player concurrently.
for _, player in ipairs(Players:GetPlayers()) do
	local userId = tostring(player.UserId)
	if not loading[userId] and not cache[userId] then
		loading[userId] = true
		DataStoreManager.loadData(player)
		loading[userId] = nil
	end
end

-- ── Cross-script exposure ──────────────────────────────────────────────────────
-- GameServer.server.lua is a sibling Script (not a ModuleScript) and cannot use
-- require() to depend on this Script directly.  We use _G as a simple in-process
-- shared reference — both scripts run in the same server VM.  This is a well-
-- established Roblox pattern for Script → Script communication.
_G.DataStoreManager = DataStoreManager

return DataStoreManager
