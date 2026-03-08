-- ============================================
-- SCRIPT 1: PROJECT STRUCTURE & FOLDERS
-- Paste into Roblox Studio Command Bar and press Enter
-- ============================================

-- ReplicatedStorage structure
local RS = game:GetService("ReplicatedStorage")

local function createFolder(parent, name)
    local existing = parent:FindFirstChild(name)
    if existing then existing:Destroy() end
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

-- Main folders in ReplicatedStorage
local Assets = createFolder(RS, "Assets")
local CarrotModels = createFolder(Assets, "CarrotModels")
local Modules = createFolder(RS, "Modules")
local Remotes = createFolder(RS, "Remotes")

-- Remote Events
local remoteNames = {
    "CollectCarrot", "BuyUpgrade", "BuyShredConvert",
    "BuyTreeNode", "DrawCard", "PickCard",
    "UpdatePlayerData", "SpawnCarrots"
}
for _, name in ipairs(remoteNames) do
    local re = Instance.new("RemoteEvent")
    re.Name = name
    re.Parent = Remotes
end

-- Remote Functions
local rf = Instance.new("RemoteFunction")
rf.Name = "GetPlayerData"
rf.Parent = Remotes

-- ServerScriptService structure
local SSS = game:GetService("ServerScriptService")
local ServerModules = createFolder(SSS, "ServerModules")

-- StarterGui structure
local SG = game:GetService("StarterGui")

-- StarterPlayerScripts
local SPS = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")

-- Workspace structure
local WS = game.Workspace
local GameWorld = createFolder(WS, "GameWorld")
local SpawnArea = createFolder(GameWorld, "SpawnArea")
local UpgradeWall1 = createFolder(GameWorld, "UpgradeWall1")
local UpgradeWall2 = createFolder(GameWorld, "UpgradeWall2")
local ShreddedConverter = createFolder(GameWorld, "ShreddedConverter")
local UpgradeTrees = createFolder(GameWorld, "UpgradeTrees")
local ActiveCarrots = createFolder(WS, "ActiveCarrots")

-- Create placeholder carrot models for you to replace
-- DELETE THESE and put your own models in ReplicatedStorage > Assets > CarrotModels
local rarities = {
    {name = "Common_Carrot", color = BrickColor.new("Deep orange"), value = 1, xp = 1, weight = 70},
    {name = "Uncommon_Carrot", color = BrickColor.new("Bright blue"), value = 3, xp = 2, weight = 20},
    {name = "Rare_Carrot", color = BrickColor.new("Bright violet"), value = 10, xp = 5, weight = 8},
    {name = "Epic_Carrot", color = BrickColor.new("Really red"), value = 25, xp = 10, weight = 1.8},
    {name = "Legendary_Carrot", color = BrickColor.new("New Yeller"), value = 100, xp = 50, weight = 0.2},
}

for _, data in ipairs(rarities) do
    local model = Instance.new("Model")
    model.Name = data.name

    local part = Instance.new("Part")
    part.Name = "MainPart"
    part.Size = Vector3.new(1, 3, 1)
    part.BrickColor = data.color
    part.Anchored = true
    part.CanCollide = false
    part.Parent = model
    model.PrimaryPart = part

    model:SetAttribute("Value", data.value)
    model:SetAttribute("XP", data.xp)
    model:SetAttribute("Weight", data.weight)
    model:SetAttribute("Rarity", data.name:gsub("_Carrot", ""))

    model.Parent = CarrotModels
end

print("Script 1 Complete: Project structure created!")
print("Add your own carrot models to: ReplicatedStorage > Assets > CarrotModels")
print("   Each model needs attributes: Value (number), XP (number), Weight (number), Rarity (string)")
print("   And a PrimaryPart set!")