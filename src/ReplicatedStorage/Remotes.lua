-- Remotes.lua
-- Creates all RemoteEvents and RemoteFunctions needed for Carrot Clicker.
-- Run this module on the server (required from GameServer) to set up the
-- Remotes folder inside ReplicatedStorage.
--
-- Client scripts require this module to grab references to the same remotes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- Names of every RemoteEvent used in the game
local REMOTE_EVENT_NAMES = {
	"ClickCarrot",      -- Client → Server: player clicked the carrot
	"BuyUpgrade",       -- Client → Server: player wants to buy an upgrade
	"UpdateState",      -- Server → Client: broadcast full player state
	"CritNotify",       -- Server → Client: a crit occurred (critAmount)
	"GoldenClickNotify",-- Server → Client: golden click occurred
	"MilestoneReached", -- Server → Client: a milestone was completed
}

-- Initialise or retrieve the Remotes folder
function Remotes.setup()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name   = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	for _, name in ipairs(REMOTE_EVENT_NAMES) do
		if not folder:FindFirstChild(name) then
			local re    = Instance.new("RemoteEvent")
			re.Name     = name
			re.Parent   = folder
		end
	end

	return folder
end

-- Retrieve a RemoteEvent by name (works on both server and client after setup)
function Remotes.get(name)
	local folder = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not folder then
		error("[Remotes] Remotes folder not found in ReplicatedStorage")
	end
	local remote = folder:WaitForChild(name, 10)
	if not remote then
		error("[Remotes] Remote not found: " .. tostring(name))
	end
	return remote
end

return Remotes
