--[[
  BuildAll.lua — Carrot Clicker Phase 1
  ════════════════════════════════════════════════════════════════════════════════
  Paste this entire script into the Roblox Studio Command Bar and press Enter.
  It will create the COMPLETE Carrot Clicker game hierarchy inside the current
  place — all scripts, all GUI elements, all RemoteEvents — ready to Play (F5).

  Progress is printed to the Output window.
  Ends with: ✅ Carrot Clicker build complete!
  ════════════════════════════════════════════════════════════════════════════════
--]]

-- ── Services ─────────────────────────────────────────────────────────────────
local SS   = game:GetService("ServerScriptService")
local SPS  = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts") or game:GetService("StarterPlayerScripts")
local SG   = game:GetService("StarterGui")
local RS   = game:GetService("ReplicatedStorage")

-- ── Helper: remove existing instance by name/class ───────────────────────────
local function wipe(parent, name)
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
end

-- ── Helper: create a ModuleScript with source ────────────────────────────────
local function makeModule(parent, name, source)
	wipe(parent, name)
	local m = Instance.new("ModuleScript")
	m.Name   = name
	m.Source = source
	m.Parent = parent
	return m
end

-- ── Helper: create a Script (server) ─────────────────────────────────────────
local function makeScript(parent, name, source)
	wipe(parent, name)
	local s = Instance.new("Script")
	s.Name    = name
	s.Source  = source
	s.Parent  = parent
	return s
end

-- ── Helper: create a LocalScript (client) ────────────────────────────────────
local function makeLocalScript(parent, name, source)
	wipe(parent, name)
	local s = Instance.new("LocalScript")
	s.Name    = name
	s.Source  = source
	s.Parent  = parent
	return s
end

-- ── Helper: UICorner ─────────────────────────────────────────────────────────
local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

-- ── Helper: UIPadding ────────────────────────────────────────────────────────
local function addPadding(parent, top, right, bottom, left)
	local p = Instance.new("UIPadding")
	p.PaddingTop    = UDim.new(0, top    or 8)
	p.PaddingRight  = UDim.new(0, right  or 8)
	p.PaddingBottom = UDim.new(0, bottom or 8)
	p.PaddingLeft   = UDim.new(0, left   or 8)
	p.Parent = parent
	return p
end

-- ╔══════════════════════════════════════════════════════════════════════════════
-- ║  STEP 1: ReplicatedStorage — Modules folder + module scripts
-- ╚══════════════════════════════════════════════════════════════════════════════
print("[BuildAll] Creating ReplicatedStorage modules...")

wipe(RS, "Modules")
local modulesFolder = Instance.new("Folder")
modulesFolder.Name   = "Modules"
modulesFolder.Parent = RS

wipe(RS, "Remotes")
local remotesFolder = Instance.new("Folder")
remotesFolder.Name   = "Remotes"
remotesFolder.Parent = RS

-- ── GameConfig ────────────────────────────────────────────────────────────────
makeModule(modulesFolder, "GameConfig", [[
local GameConfig = {}
GameConfig.PASSIVE_TICK_RATE    = 1
GameConfig.DATA_KEY_PREFIX      = "PlayerData_"
GameConfig.AUTOSAVE_INTERVAL    = 120
GameConfig.SAVE_RETRIES         = 3
GameConfig.BASE_CLICK_VALUE     = 1
GameConfig.GOLDEN_CLICK_EVERY   = 25
GameConfig.GOLDEN_CLICK_MULTI   = 10
GameConfig.STREAK_MAX           = 50
GameConfig.STREAK_WINDOW        = 2
GameConfig.STREAK_DECAY_DELAY   = 0.6
GameConfig.STREAK_DECAY_DURATION= 1.0
GameConfig.BASE_CRIT_CHANCE     = 0
GameConfig.BASE_CRIT_POWER      = 5
GameConfig.Upgrades = {
	{key="ClickPower", name="Click Power",  description="Sharpen your harvest.",   category="Click",  baseCost=10,   costMult=1.15, effectDesc="+%d carrot/click",           unlockAt=0},
	{key="AutoFarmer", name="Auto Farmer",  description="A carrot-picking robot.", category="Idle",   baseCost=50,   costMult=1.18, effectDesc="+%d carrot/sec",             unlockAt=0},
	{key="Compost",    name="Compost",      description="Enriches all production.",category="Boosts", baseCost=500,  costMult=1.35, effectDesc="+%dx10%% global multiplier", unlockAt=10000},
	{key="CritChance", name="Crit Chance",  description="Critical harvest chance.",category="Click",  baseCost=200,  costMult=1.25, effectDesc="+%dx2%% crit chance",        unlockAt=1000,  maxLevel=25},
	{key="CritPower",  name="Crit Power",   description="Multiplies crit value.",  category="Click",  baseCost=1000, costMult=1.30, effectDesc="+%dx1 crit multiplier",      unlockAt=50000},
}
GameConfig.UpgradeMap = {}
for _,u in ipairs(GameConfig.Upgrades) do GameConfig.UpgradeMap[u.key]=u end
GameConfig.Milestones = {
	{id="FirstHarvest",  threshold=100,    name="First Harvest",     reward="badge"},
	{id="UnlockCrit",    threshold=1000,   name="Sharp Eye",         reward="unlock:CritChance"},
	{id="UnlockCompost", threshold=10000,  name="Rich Soil",         reward="unlock:Compost"},
	{id="UnlockCritPow", threshold=50000,  name="Critical Farming",  reward="unlock:CritPower"},
	{id="Replant",       threshold=250000, name="Replant Available", reward="tease:Phase2"},
	{id="Millionaire",   threshold=1000000,name="Millionaire Farmer",reward="badge"},
}
GameConfig.DefaultData = {
	carrots=0, carrotsThisRun=0, totalCarrotsAllTime=0,
	upgrades={ClickPower=0,AutoFarmer=0,Compost=0,CritChance=0,CritPower=0},
	milestones={}, totalClicks=0, lastSave=0,
}
function GameConfig.getUpgradeCost(key,level)
	local u=GameConfig.UpgradeMap[key]; if not u then return math.huge end
	return math.floor(u.baseCost*(u.costMult^level))
end
function GameConfig.computeClickValue(data,streak)
	local cp=data.upgrades.ClickPower or 0
	local co=data.upgrades.Compost or 0
	local cc=(data.upgrades.CritChance or 0)*0.02
	local cpow=GameConfig.BASE_CRIT_POWER+(data.upgrades.CritPower or 0)
	local gm=1+co*0.10
	local base=(GameConfig.BASE_CLICK_VALUE+cp)*gm
	local sb=1+(streak or 0)/100
	local val=math.floor(base*sb)
	local isCrit=(math.random()<cc)
	if isCrit then val=math.floor(val*cpow) end
	return val,isCrit
end
function GameConfig.computePassiveIncome(data)
	local af=data.upgrades.AutoFarmer or 0
	local co=data.upgrades.Compost or 0
	return math.floor(af*(1+co*0.10))
end
return GameConfig
]])

-- ── NumberFormatter ───────────────────────────────────────────────────────────
makeModule(modulesFolder, "NumberFormatter", [[
local NF={}
local S={{1e33,"Dc"},{1e30,"No"},{1e27,"Oc"},{1e24,"Sp"},{1e21,"Sx"},{1e18,"Qi"},{1e15,"Qa"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}}
function NF.format(n)
	n=tonumber(n) or 0
	if n<0 then return "-"..NF.format(-n) end
	if n>=1e36 then return "999.9Dc+" end
	for _,e in ipairs(S) do
		if n>=e[1] then return string.format("%.1f%s",n/e[1],e[2]) end
	end
	return tostring(math.floor(n))
end
function NF.formatRate(n) return NF.format(n).."/s" end
return NF
]])

-- ── Remotes ───────────────────────────────────────────────────────────────────
makeModule(modulesFolder, "Remotes", [[
local RS=game:GetService("ReplicatedStorage")
local NAMES={"ClickCarrot","BuyUpgrade","UpdateState","CritNotify","GoldenClickNotify","MilestoneReached"}
local Remotes={}
function Remotes.setup()
	local f=RS:FindFirstChild("Remotes")
	if not f then f=Instance.new("Folder"); f.Name="Remotes"; f.Parent=RS end
	for _,n in ipairs(NAMES) do
		if not f:FindFirstChild(n) then
			local r=Instance.new("RemoteEvent"); r.Name=n; r.Parent=f
		end
	end
	return f
end
function Remotes.get(name)
	local f=RS:WaitForChild("Remotes",10)
	return f:WaitForChild(name,10)
end
return Remotes
]])

-- ── Create RemoteEvents now so they exist immediately ─────────────────────────
local remoteNames = {"ClickCarrot","BuyUpgrade","UpdateState","CritNotify","GoldenClickNotify","MilestoneReached"}
for _, rname in ipairs(remoteNames) do
	if not remotesFolder:FindFirstChild(rname) then
		local re = Instance.new("RemoteEvent")
		re.Name   = rname
		re.Parent = remotesFolder
	end
end

print("[BuildAll] Modules and RemoteEvents created.")

-- ╔══════════════════════════════════════════════════════════════════════════════
-- ║  STEP 2: ServerScriptService — DataStoreManager + GameServer
-- ╚══════════════════════════════════════════════════════════════════════════════
print("[BuildAll] Creating server scripts...")

-- ── DataStoreManager ─────────────────────────────────────────────────────────
makeScript(SS, "DataStoreManager", [[
local DSS=game:GetService("DataStoreService")
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local GC=require(RS:WaitForChild("Modules"):WaitForChild("GameConfig"))
local store=DSS:GetDataStore("CarrotClickerData_v1")
local cache={}
local function deepCopy(t)
	local c={}; for k,v in pairs(t) do c[k]=(type(v)=="table")and deepCopy(v) or v end; return c
end
local function merge(saved,def)
	local r=deepCopy(def)
	for k,v in pairs(saved) do
		r[k]=(type(v)=="table"and type(r[k])=="table")and merge(v,r[k]) or v
	end
	return r
end
local function retry(fn,n)
	local err
	for i=1,n do
		local ok,res=pcall(fn)
		if ok then return true,res end
		err=res; warn("[DS] Attempt "..i.."/"..n.." failed: "..tostring(err))
		if i<n then task.wait(2^i) end
	end
	return false,err
end
local DSM={}
function DSM.loadData(p)
	local key=GC.DATA_KEY_PREFIX..p.UserId
	local ok,res=retry(function() return store:GetAsync(key) end,GC.SAVE_RETRIES)
	local d=(ok and res) and merge(res,GC.DefaultData) or deepCopy(GC.DefaultData)
	d.lastSave=os.time(); cache[p.UserId]=d; return d
end
function DSM.saveData(p)
	local d=cache[p.UserId]; if not d then return end
	local key=GC.DATA_KEY_PREFIX..p.UserId; d.lastSave=os.time()
	local ok,err=retry(function() store:SetAsync(key,d) end,GC.SAVE_RETRIES)
	if ok then print("[DS] Saved "..p.Name) else warn("[DS] FAIL "..p.Name..": "..tostring(err)) end
end
function DSM.getData(p) return cache[p.UserId] end
function DSM.updateData(p,fn) local d=cache[p.UserId]; if d then fn(d) end end
local loading={}
Players.PlayerAdded:Connect(function(p)
	local uid=p.UserId
	if loading[uid] or cache[uid] then return end
	loading[uid]=true; DSM.loadData(p); loading[uid]=nil
end)
Players.PlayerRemoving:Connect(function(p) DSM.saveData(p); cache[p.UserId]=nil; loading[p.UserId]=nil end)
game:BindToClose(function() for _,p in ipairs(Players:GetPlayers()) do DSM.saveData(p) end end)
task.spawn(function()
	while true do task.wait(GC.AUTOSAVE_INTERVAL)
		for _,p in ipairs(Players:GetPlayers()) do DSM.saveData(p) end
		print("[DS] Autosave complete.")
	end
end)
for _,p in ipairs(Players:GetPlayers()) do
	local uid=p.UserId
	if not loading[uid] and not cache[uid] then loading[uid]=true; DSM.loadData(p); loading[uid]=nil end
end
_G.DataStoreManager=DSM
print("[DS] DataStoreManager ready.")
]])

-- ── GameServer ────────────────────────────────────────────────────────────────
makeScript(SS, "GameServer", [[
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Modules=RS:WaitForChild("Modules")
local GC=require(Modules:WaitForChild("GameConfig"))
local Rem=require(Modules:WaitForChild("Remotes"))
Rem.setup()
-- Wait for DataStoreManager
local DSM
local tries=0
while not _G.DataStoreManager and tries<60 do task.wait(0.5); tries=tries+1 end
if _G.DataStoreManager then
	DSM=_G.DataStoreManager
else
	warn("[GS] DSM not found — using in-memory fallback")
	local mem={}
	local function deepCopy(t) local c={} for k,v in pairs(t) do c[k]=(type(v)=="table")and deepCopy(v) or v end return c end
	DSM={
		loadData=function(p)
			local d=mem[p.UserId]
			if not d then d=deepCopy(GC.DefaultData); mem[p.UserId]=d end
			return d
		end,
		saveData=function() end,
		getData=function(p) return mem[p.UserId] end,
		updateData=function(p,fn) if mem[p.UserId] then fn(mem[p.UserId]) end end,
	}
end
local function sendState(p)
	local d=DSM.getData(p); if not d then return end
	Rem.get("UpdateState"):FireClient(p,d)
end
local function checkMS(p)
	local d=DSM.getData(p); if not d then return end
	for _,ms in ipairs(GC.Milestones) do
		if not d.milestones[ms.id] and d.totalCarrotsAllTime>=ms.threshold then
			d.milestones[ms.id]=true
			Rem.get("MilestoneReached"):FireClient(p,ms)
		end
	end
end
local function addCarrots(p,amt)
	DSM.updateData(p,function(d)
		d.carrots=d.carrots+amt
		d.carrotsThisRun=d.carrotsThisRun+amt
		d.totalCarrotsAllTime=d.totalCarrotsAllTime+amt
	end)
end
Rem.get("ClickCarrot").OnServerEvent:Connect(function(p,streak)
	local d=DSM.getData(p); if not d then return end
	d.totalClicks=(d.totalClicks or 0)+1
	local val,isCrit=GC.computeClickValue(d,streak or 0)
	local isGolden=(d.totalClicks%GC.GOLDEN_CLICK_EVERY==0)
	if isGolden then val=math.floor(val*GC.GOLDEN_CLICK_MULTI) end
	addCarrots(p,val)
	if isCrit   then Rem.get("CritNotify"):FireClient(p,val) end
	if isGolden then Rem.get("GoldenClickNotify"):FireClient(p,val) end
	checkMS(p); sendState(p)
end)
Rem.get("BuyUpgrade").OnServerEvent:Connect(function(p,key,qty)
	local d=DSM.getData(p); if not d then return end
	local upg=GC.UpgradeMap[key]; if not upg then return end
	if d.totalCarrotsAllTime<upg.unlockAt then return end
	qty=tonumber(qty) or 1
	if qty==-1 then
		local n=0; local tl=d.upgrades[key] or 0; local tc=d.carrots
		while true do
			if upg.maxLevel and tl>=upg.maxLevel then break end
			local c=GC.getUpgradeCost(key,tl)
			if tc<c then break end
			tc=tc-c; tl=tl+1; n=n+1; if n>10000 then break end
		end
		if n==0 then return end; qty=n
	end
	local lv=d.upgrades[key] or 0
	for _=1,qty do
		if upg.maxLevel and lv>=upg.maxLevel then break end
		local c=GC.getUpgradeCost(key,lv)
		if d.carrots<c then break end
		d.carrots=d.carrots-c; lv=lv+1; d.upgrades[key]=lv
	end
	checkMS(p); sendState(p)
end)
task.spawn(function()
	while true do task.wait(GC.PASSIVE_TICK_RATE)
		for _,p in ipairs(Players:GetPlayers()) do
			local d=DSM.getData(p)
			if d then
				local inc=GC.computePassiveIncome(d)
				if inc>0 then addCarrots(p,inc); checkMS(p); sendState(p) end
			end
		end
	end
end)
Players.PlayerAdded:Connect(function(p) task.delay(1,function() sendState(p) end) end)
for _,p in ipairs(Players:GetPlayers()) do task.delay(1,function() sendState(p) end) end
print("[GS] GameServer ready.")
]])

print("[BuildAll] Server scripts created.")

-- ╔══════════════════════════════════════════════════════════════════════════════
-- ║  STEP 3: StarterGui — CarrotClickerGui ScreenGui + full GUI tree
-- ╚══════════════════════════════════════════════════════════════════════════════
print("[BuildAll] Building GUI hierarchy...")

-- Fixed-pixel dimensions for consistent cross-resolution layout
local TOP_H    = 52   -- TopBar height in pixels
local BOTTOM_H = 48   -- BottomBar height in pixels
local RAIL_W   = 60   -- Left rail width in pixels
local PANEL_W  = 290  -- Right upgrades panel width in pixels

wipe(SG, "CarrotClickerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "CarrotClickerGui"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
-- Extend under the Roblox CoreGui top bar so nothing bleeds through
screenGui.IgnoreGuiInset  = true
screenGui.Parent          = SG

-- ── Color constants ───────────────────────────────────────────────────────────
local C_BASE     = Color3.fromRGB(18, 18, 32)
local C_PANEL    = Color3.fromRGB(28, 28, 50)
local C_PANEL2   = Color3.fromRGB(38, 38, 64)
local C_ACCENT   = Color3.fromRGB(255, 165, 0)
local C_GREEN    = Color3.fromRGB(76, 175, 80)
local C_TEXT     = Color3.fromRGB(255, 255, 255)
local C_TEXT2    = Color3.fromRGB(170, 170, 195)
local C_MUTED    = Color3.fromRGB(110, 110, 135)
local C_LOCKED   = Color3.fromRGB(48, 48, 72)
local C_BORDER   = Color3.fromRGB(55, 55, 85)
local C_RED      = Color3.fromRGB(220, 60, 60)
local C_GOLD     = Color3.fromRGB(255, 215, 0)

-- ── Helper: plain TextLabel ───────────────────────────────────────────────────
local function makeLabel(parent, name, text, size, pos, textSize, font, color, xAlign)
	local l = Instance.new("TextLabel")
	l.Name                   = name
	l.Text                   = text
	l.Size                   = size
	l.Position               = pos
	l.BackgroundTransparency = 1
	l.BorderSizePixel        = 0
	l.TextSize               = textSize or 14
	l.Font                   = font  or Enum.Font.Gotham
	l.TextColor3             = color or C_TEXT
	l.TextXAlignment         = xAlign or Enum.TextXAlignment.Center
	l.Parent                 = parent
	return l
end

-- ── BACKGROUND ────────────────────────────────────────────────────────────────
local bg = Instance.new("Frame")
bg.Name                   = "Background"
bg.Size                   = UDim2.new(1,0,1,0)
bg.Position               = UDim2.new(0,0,0,0)
bg.BackgroundColor3       = C_BASE
bg.BorderSizePixel        = 0
bg.ZIndex                 = 1
bg.Parent                 = screenGui

-- Subtle dot-grid overlay (very transparent)
local fineGrid = Instance.new("Frame")
fineGrid.Name                   = "FineGrid"
fineGrid.Size                   = UDim2.new(1,0,1,0)
fineGrid.BackgroundColor3       = Color3.fromRGB(80, 80, 120)
fineGrid.BackgroundTransparency = 0.96
fineGrid.BorderSizePixel        = 0
fineGrid.ZIndex                 = 2
fineGrid.Parent                 = bg

local coarseGrid = Instance.new("Frame")
coarseGrid.Name                   = "CoarseGrid"
coarseGrid.Size                   = UDim2.new(1,0,1,0)
coarseGrid.BackgroundColor3       = Color3.fromRGB(100,100,160)
coarseGrid.BackgroundTransparency = 0.97
coarseGrid.BorderSizePixel        = 0
coarseGrid.ZIndex                 = 3
coarseGrid.Parent                 = bg

-- Subtle warm radial glow centred behind the carrot area (much smaller than before)
local bgGlow = Instance.new("Frame")
bgGlow.Name                   = "CenterGlow"
bgGlow.Size                   = UDim2.new(0,320,0,320)
bgGlow.AnchorPoint            = Vector2.new(0.5,0.5)
bgGlow.Position               = UDim2.new(0.5,-(PANEL_W/2),0.5,0)
bgGlow.BackgroundColor3       = Color3.fromRGB(255,130,0)
bgGlow.BackgroundTransparency = 0.97
bgGlow.BorderSizePixel        = 0
bgGlow.ZIndex                 = 4
bgGlow.Parent                 = bg
local bgGlowCorner = Instance.new("UICorner")
bgGlowCorner.CornerRadius = UDim.new(1,0)
bgGlowCorner.Parent = bgGlow

-- ── TOP BAR ───────────────────────────────────────────────────────────────────
-- Fixed pixel height so it looks identical on all screen sizes.
local topBar = Instance.new("Frame")
topBar.Name                   = "TopBar"
topBar.Size                   = UDim2.new(1,0,0,TOP_H)
topBar.Position               = UDim2.new(0,0,0,0)
topBar.BackgroundColor3       = C_PANEL
topBar.BackgroundTransparency = 0
topBar.BorderSizePixel        = 0
topBar.ZIndex                 = 10
topBar.Parent                 = screenGui

-- Thin accent line at the bottom of the top bar for visual separation
local topBarLine = Instance.new("Frame")
topBarLine.Name              = "BottomLine"
topBarLine.Size              = UDim2.new(1,0,0,1)
topBarLine.AnchorPoint       = Vector2.new(0,1)
topBarLine.Position          = UDim2.new(0,0,1,0)
topBarLine.BackgroundColor3  = C_ACCENT
topBarLine.BackgroundTransparency = 0.6
topBarLine.BorderSizePixel   = 0
topBarLine.ZIndex            = 11
topBarLine.Parent            = topBar

-- Title (left side)
local titleLbl = makeLabel(topBar,"Title","🥕 Carrot Clicker",
	UDim2.new(0,180,1,0), UDim2.new(0,12,0,0),
	17, Enum.Font.GothamBold, C_ACCENT, Enum.TextXAlignment.Left)
titleLbl.ZIndex = 11

-- Currency display (centred in top bar)
local currDisp = Instance.new("Frame")
currDisp.Name                   = "CurrencyDisplay"
currDisp.Size                   = UDim2.new(0,300,1,0)
currDisp.AnchorPoint            = Vector2.new(0.5,0)
currDisp.Position               = UDim2.new(0.5,0,0,0)
currDisp.BackgroundTransparency = 1
currDisp.BorderSizePixel        = 0
currDisp.ZIndex                 = 11
currDisp.Parent                 = topBar

-- Big carrot count
local carrotsAmtLbl = makeLabel(currDisp,"CarrotsAmount","0",
	UDim2.new(1,0,0,30), UDim2.new(0,0,0,4),
	24, Enum.Font.GothamBold, C_ACCENT)
carrotsAmtLbl.ZIndex = 12

-- /s and /click on the same row below (direct children of currDisp for easy WaitForChild access)
local perSecLbl = makeLabel(currDisp,"PerSec","0/s",
	UDim2.new(0,80,0,14), UDim2.new(0.5,-50,0,34),
	12, Enum.Font.Gotham, C_TEXT2)
perSecLbl.ZIndex = 12

local statsDot = makeLabel(currDisp,"StatsDot","·",
	UDim2.new(0,8,0,14), UDim2.new(0.5,-4,0,34),
	12, Enum.Font.Gotham, C_MUTED)
statsDot.ZIndex = 12

local perClickLbl = makeLabel(currDisp,"PerClick","1/click",
	UDim2.new(0,80,0,14), UDim2.new(0.5,-26,0,34),
	12, Enum.Font.Gotham, C_TEXT2)
perClickLbl.ZIndex = 12

-- Right group: seeds + gear button
local rightGroup = Instance.new("Frame")
rightGroup.Name                   = "RightGroup"
rightGroup.Size                   = UDim2.new(0,160,1,0)
rightGroup.AnchorPoint            = Vector2.new(1,0)
rightGroup.Position               = UDim2.new(1,-8,0,0)
rightGroup.BackgroundTransparency = 1
rightGroup.BorderSizePixel        = 0
rightGroup.ZIndex                 = 11
rightGroup.Parent                 = topBar

local seedsLbl = makeLabel(rightGroup,"SeedsAmount","🌱 Seeds: 0",
	UDim2.new(1,-46,1,0), UDim2.new(0,0,0,0),
	12, Enum.Font.Gotham, C_TEXT2, Enum.TextXAlignment.Right)
seedsLbl.ZIndex = 12

local settingsBtn = Instance.new("TextButton")
settingsBtn.Name                = "SettingsButton"
settingsBtn.Text                = "⚙"
settingsBtn.Size                = UDim2.new(0,34,0,34)
settingsBtn.AnchorPoint         = Vector2.new(1,0.5)
settingsBtn.Position            = UDim2.new(1,0,0.5,0)
settingsBtn.BackgroundColor3    = C_PANEL2
settingsBtn.TextColor3          = C_TEXT2
settingsBtn.TextSize            = 16
settingsBtn.Font                = Enum.Font.GothamBold
settingsBtn.BorderSizePixel     = 0
settingsBtn.ZIndex              = 12
settingsBtn.Parent              = rightGroup
addCorner(settingsBtn, 8)

-- ── LEFT RAIL ─────────────────────────────────────────────────────────────────
-- Spans from below TopBar to above BottomBar.
local leftRail = Instance.new("Frame")
leftRail.Name                   = "LeftRail"
leftRail.Size                   = UDim2.new(0,RAIL_W,1,-(TOP_H+BOTTOM_H))
leftRail.Position               = UDim2.new(0,0,0,TOP_H)
leftRail.BackgroundColor3       = C_PANEL
leftRail.BackgroundTransparency = 0
leftRail.BorderSizePixel        = 0
leftRail.ZIndex                 = 10
leftRail.Parent                 = screenGui

-- Right border line on the rail
local railLine = Instance.new("Frame")
railLine.Name              = "RightLine"
railLine.Size              = UDim2.new(0,1,1,0)
railLine.AnchorPoint       = Vector2.new(1,0)
railLine.Position          = UDim2.new(1,0,0,0)
railLine.BackgroundColor3  = C_BORDER
railLine.BorderSizePixel   = 0
railLine.ZIndex            = 11
railLine.Parent            = leftRail

local railLayout = Instance.new("UIListLayout")
railLayout.Padding                  = UDim.new(0, 4)
railLayout.SortOrder                = Enum.SortOrder.LayoutOrder
railLayout.HorizontalAlignment      = Enum.HorizontalAlignment.Center
railLayout.Parent                   = leftRail
addPadding(leftRail, 8, 5, 8, 5)

local railTabs = {
	{name="HomeTab",     icon="🏠", locked=false, order=1},
	{name="UpgradesTab", icon="⬆", locked=false, order=2},
	{name="ReplantTab",  icon="🌱", locked=true,  order=3},
	{name="PetsTab",     icon="🐇", locked=true,  order=4},
	{name="QuestsTab",   icon="📋", locked=true,  order=5},
	{name="ShopTab",     icon="🛒", locked=true,  order=6},
}
for _, td in ipairs(railTabs) do
	local btn = Instance.new("TextButton")
	btn.Name             = td.name
	-- Icon only — no stacked emoji+lock text; lock state shown via colour
	btn.Text             = td.icon
	btn.Size             = UDim2.new(1,-4,0,44)
	btn.BackgroundColor3 = td.locked and C_LOCKED or C_PANEL2
	btn.BackgroundTransparency = td.locked and 0.2 or 0.0
	btn.TextColor3       = td.locked and C_MUTED or C_TEXT
	btn.TextSize         = 22
	btn.Font             = Enum.Font.GothamMedium
	btn.BorderSizePixel  = 0
	btn.LayoutOrder      = td.order
	btn.ZIndex           = 11
	btn.Parent           = leftRail
	addCorner(btn, 8)

	-- Small lock badge in bottom-right corner of locked tabs
	if td.locked then
		local badge = Instance.new("TextLabel")
		badge.Name                   = "LockBadge"
		badge.Text                   = "🔒"
		badge.Size                   = UDim2.new(0,16,0,16)
		badge.AnchorPoint            = Vector2.new(1,1)
		badge.Position               = UDim2.new(1,0,1,0)
		badge.BackgroundTransparency = 1
		badge.BorderSizePixel        = 0
		badge.TextSize               = 10
		badge.Font                   = Enum.Font.Gotham
		badge.ZIndex                 = 12
		badge.Parent                 = btn
	end
end

-- ── RIGHT PANEL (Upgrades) ────────────────────────────────────────────────────
-- Fixed pixel width, spans from below TopBar to above BottomBar.
local rightPanel = Instance.new("Frame")
rightPanel.Name                   = "RightPanel"
rightPanel.Size                   = UDim2.new(0,PANEL_W,1,-(TOP_H+BOTTOM_H))
rightPanel.AnchorPoint            = Vector2.new(1,0)
rightPanel.Position               = UDim2.new(1,0,0,TOP_H)
rightPanel.BackgroundColor3       = C_PANEL
rightPanel.BackgroundTransparency = 0
rightPanel.BorderSizePixel        = 0
rightPanel.ZIndex                 = 12
rightPanel.Parent                 = screenGui

-- Left border line on the right panel
local panelLine = Instance.new("Frame")
panelLine.Name              = "LeftLine"
panelLine.Size              = UDim2.new(0,1,1,0)
panelLine.BackgroundColor3  = C_BORDER
panelLine.BorderSizePixel   = 0
panelLine.ZIndex            = 13
panelLine.Parent            = rightPanel

-- Panel header row
local panelHeaderRow = Instance.new("Frame")
panelHeaderRow.Name                   = "PanelHeaderRow"
panelHeaderRow.Size                   = UDim2.new(1,0,0,44)
panelHeaderRow.BackgroundTransparency = 1
panelHeaderRow.BorderSizePixel        = 0
panelHeaderRow.ZIndex                 = 13
panelHeaderRow.Parent                 = rightPanel

local panelHeader = makeLabel(panelHeaderRow,"PanelHeader","Upgrades",
	UDim2.new(1,-12,1,0), UDim2.new(0,12,0,0),
	16, Enum.Font.GothamBold, C_ACCENT, Enum.TextXAlignment.Left)
panelHeader.ZIndex = 14

local headerDiv = Instance.new("Frame")
headerDiv.Name                   = "HeaderDivider"
headerDiv.Size                   = UDim2.new(1,0,0,1)
headerDiv.AnchorPoint            = Vector2.new(0,1)
headerDiv.Position               = UDim2.new(0,0,1,0)
headerDiv.BackgroundColor3       = C_BORDER
headerDiv.BorderSizePixel        = 0
headerDiv.ZIndex                 = 13
headerDiv.Parent                 = panelHeaderRow

-- Category tabs
local catTabs = Instance.new("Frame")
catTabs.Name                   = "CategoryTabs"
catTabs.Size                   = UDim2.new(1,-8,0,32)
catTabs.Position               = UDim2.new(0,4,0,48)
catTabs.BackgroundTransparency = 1
catTabs.BorderSizePixel        = 0
catTabs.ZIndex                 = 13
catTabs.Parent                 = rightPanel

local catLayout = Instance.new("UIListLayout")
catLayout.FillDirection = Enum.FillDirection.Horizontal
catLayout.Padding       = UDim.new(0,3)
catLayout.SortOrder     = Enum.SortOrder.LayoutOrder
catLayout.Parent        = catTabs

local catNames = {{"Click",1},{"Idle",2},{"Boosts",3},{"Unlocks",4}}
for _, ct in ipairs(catNames) do
	local tb = Instance.new("TextButton")
	tb.Name             = "Tab"..ct[1]
	tb.Text             = ct[1]
	tb.Size             = UDim2.new(0.25,-3,1,0)
	tb.BackgroundColor3 = ct[2]==1 and C_ACCENT or C_LOCKED
	tb.TextColor3       = ct[2]==1 and Color3.fromRGB(18,18,32) or C_TEXT2
	tb.TextSize         = 12
	tb.Font             = Enum.Font.GothamBold
	tb.BorderSizePixel  = 0
	tb.LayoutOrder      = ct[2]
	tb.ZIndex           = 14
	tb.Parent           = catTabs
	addCorner(tb, 6)
end

-- Scroll frame for upgrade cards
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name                     = "UpgradeScrollFrame"
scrollFrame.Size                     = UDim2.new(1,0,1,-88)
scrollFrame.Position                 = UDim2.new(0,0,0,88)
scrollFrame.BackgroundTransparency   = 1
scrollFrame.BorderSizePixel          = 0
scrollFrame.ScrollBarThickness       = 4
scrollFrame.ScrollBarImageColor3     = C_ACCENT
scrollFrame.CanvasSize               = UDim2.new(0,0,0,400)
scrollFrame.ZIndex                   = 13
scrollFrame.Parent                   = rightPanel
addPadding(scrollFrame, 4, 8, 4, 8)

local upgradeListLayout = Instance.new("UIListLayout")
upgradeListLayout.Padding   = UDim.new(0,6)
upgradeListLayout.SortOrder = Enum.SortOrder.LayoutOrder
upgradeListLayout.Parent    = scrollFrame

-- ── MAIN AREA ────────────────────────────────────────────────────────────────
-- Fills the space between LeftRail, RightPanel, TopBar, and BottomBar.
local mainArea = Instance.new("Frame")
mainArea.Name                   = "MainArea"
mainArea.Size                   = UDim2.new(1,-(RAIL_W+PANEL_W),1,-(TOP_H+BOTTOM_H))
mainArea.Position               = UDim2.new(0,RAIL_W,0,TOP_H)
mainArea.BackgroundTransparency = 1
mainArea.BorderSizePixel        = 0
mainArea.ZIndex                 = 10
mainArea.Parent                 = screenGui

-- Carrot button plate — perfectly centred in MainArea
local carrotPlate = Instance.new("Frame")
carrotPlate.Name                   = "CarrotButtonPlate"
carrotPlate.Size                   = UDim2.new(0,230,0,230)
carrotPlate.AnchorPoint            = Vector2.new(0.5,0.5)
carrotPlate.Position               = UDim2.new(0.5,0,0.42,0)
carrotPlate.BackgroundColor3       = Color3.fromRGB(38,38,68)
carrotPlate.BackgroundTransparency = 0.0
carrotPlate.BorderSizePixel        = 0
carrotPlate.ZIndex                 = 11
carrotPlate.Parent                 = mainArea
addCorner(carrotPlate, 115)

-- Outer glow ring (pulsed by AnimationController)
local glowRing = Instance.new("Frame")
glowRing.Name                   = "GlowRing"
glowRing.Size                   = UDim2.new(1.08,0,1.08,0)
glowRing.AnchorPoint            = Vector2.new(0.5,0.5)
glowRing.Position               = UDim2.new(0.5,0,0.5,0)
glowRing.BackgroundColor3       = C_ACCENT
glowRing.BackgroundTransparency = 0.82
glowRing.BorderSizePixel        = 0
glowRing.ZIndex                 = 10
glowRing.Parent                 = carrotPlate
addCorner(glowRing, 122)

-- Carrot button
local carrotBtn = Instance.new("TextButton")
carrotBtn.Name                   = "CarrotButton"
carrotBtn.Text                   = "🥕"
carrotBtn.Size                   = UDim2.new(0.90,0,0.90,0)
carrotBtn.AnchorPoint            = Vector2.new(0.5,0.5)
carrotBtn.Position               = UDim2.new(0.5,0,0.5,0)
carrotBtn.BackgroundColor3       = Color3.fromRGB(255,145,0)
carrotBtn.BackgroundTransparency = 0.0
carrotBtn.TextSize               = 90
carrotBtn.Font                   = Enum.Font.GothamBold
carrotBtn.TextColor3             = C_TEXT
carrotBtn.BorderSizePixel        = 0
carrotBtn.AutoButtonColor        = false
carrotBtn.ZIndex                 = 13
carrotBtn.Parent                 = carrotPlate
addCorner(carrotBtn, 115)

-- Floating text layer (parent for +N labels and particles, clipsDescendants=false)
local floatLayer = Instance.new("Frame")
floatLayer.Name                   = "FloatingTextLayer"
floatLayer.Size                   = UDim2.new(1,0,1,0)
floatLayer.BackgroundTransparency = 1
floatLayer.BorderSizePixel        = 0
floatLayer.ZIndex                 = 20
floatLayer.ClipsDescendants       = false
floatLayer.Parent                 = mainArea

-- ── Streak Meter (centred under carrot) ───────────────────────────────────────
local streakMeter = Instance.new("Frame")
streakMeter.Name                   = "StreakMeter"
streakMeter.Size                   = UDim2.new(0,280,0,54)
streakMeter.AnchorPoint            = Vector2.new(0.5,0)
streakMeter.Position               = UDim2.new(0.5,0,0.70,0)
streakMeter.BackgroundTransparency = 1
streakMeter.BorderSizePixel        = 0
streakMeter.ZIndex                 = 12
streakMeter.Parent                 = mainArea

local streakLabelObj = makeLabel(streakMeter,"StreakLabel","Harvest Streak: 0x",
	UDim2.new(1,0,0,20), UDim2.new(0,0,0,0),
	12, Enum.Font.GothamMedium, C_TEXT2)
streakLabelObj.ZIndex = 13

local streakBarBg = Instance.new("Frame")
streakBarBg.Name                   = "StreakBarBg"
streakBarBg.Size                   = UDim2.new(1,0,0,10)
streakBarBg.Position               = UDim2.new(0,0,0,22)
streakBarBg.BackgroundColor3       = Color3.fromRGB(35,35,60)
streakBarBg.BackgroundTransparency = 0
streakBarBg.BorderSizePixel        = 0
streakBarBg.ZIndex                 = 13
streakBarBg.ClipsDescendants       = true
streakBarBg.Parent                 = streakMeter
addCorner(streakBarBg, 5)

local streakBarFill = Instance.new("Frame")
streakBarFill.Name                   = "StreakBarFill"
streakBarFill.Size                   = UDim2.new(0,0,1,0)
streakBarFill.BackgroundColor3       = Color3.fromRGB(255,165,0)
streakBarFill.BackgroundTransparency = 0
streakBarFill.BorderSizePixel        = 0
streakBarFill.ZIndex                 = 14
streakBarFill.Parent                 = streakBarBg
addCorner(streakBarFill, 5)

local streakLostLbl = makeLabel(streakMeter,"StreakLostLabel","Streak Lost!",
	UDim2.new(1,0,0,16), UDim2.new(0,0,0,36),
	12, Enum.Font.GothamBold, C_RED)
streakLostLbl.ZIndex  = 15
streakLostLbl.Visible = false

-- ── Milestone Tracker (centred, below streak) ─────────────────────────────────
local milestoneTrack = Instance.new("Frame")
milestoneTrack.Name                   = "MilestoneTracker"
milestoneTrack.Size                   = UDim2.new(0,280,0,54)
milestoneTrack.AnchorPoint            = Vector2.new(0.5,0)
milestoneTrack.Position               = UDim2.new(0.5,0,0.82,0)
milestoneTrack.BackgroundTransparency = 1
milestoneTrack.BorderSizePixel        = 0
milestoneTrack.ZIndex                 = 12
milestoneTrack.Parent                 = mainArea

local msFillLbl = makeLabel(milestoneTrack,"MilestoneLabel","Next: First Harvest (0/100)",
	UDim2.new(1,0,0,20), UDim2.new(0,0,0,0),
	11, Enum.Font.Gotham, C_TEXT2)
msFillLbl.ZIndex = 13

local msBarBg = Instance.new("Frame")
msBarBg.Name                   = "MilestoneBarBg"
msBarBg.Size                   = UDim2.new(1,0,0,10)
msBarBg.Position               = UDim2.new(0,0,0,22)
msBarBg.BackgroundColor3       = Color3.fromRGB(35,35,60)
msBarBg.BorderSizePixel        = 0
msBarBg.ZIndex                 = 13
msBarBg.ClipsDescendants       = true
msBarBg.Parent                 = milestoneTrack
addCorner(msBarBg, 5)

local msBarFill = Instance.new("Frame")
msBarFill.Name                   = "MilestoneBarFill"
msBarFill.Size                   = UDim2.new(0,0,1,0)
msBarFill.BackgroundColor3       = Color3.fromRGB(76,175,80)
msBarFill.BorderSizePixel        = 0
msBarFill.ZIndex                 = 14
msBarFill.Parent                 = msBarBg
addCorner(msBarFill, 5)

local msRewardChip = makeLabel(milestoneTrack,"RewardChip","",
	UDim2.new(1,0,0,16), UDim2.new(0,0,0,38),
	12, Enum.Font.GothamBold, C_GOLD)
msRewardChip.ZIndex   = 15
msRewardChip.Visible  = false

-- ── BOTTOM BAR ────────────────────────────────────────────────────────────────
-- Fixed pixel height, full width, pinned to the bottom.
local bottomBar = Instance.new("Frame")
bottomBar.Name                   = "BottomBar"
bottomBar.Size                   = UDim2.new(1,0,0,BOTTOM_H)
bottomBar.AnchorPoint            = Vector2.new(0,1)
bottomBar.Position               = UDim2.new(0,0,1,0)
bottomBar.BackgroundColor3       = C_PANEL
bottomBar.BackgroundTransparency = 0
bottomBar.BorderSizePixel        = 0
bottomBar.ZIndex                 = 10
bottomBar.Parent                 = screenGui

-- Thin accent line at the top of the bottom bar
local bottomBarLine = Instance.new("Frame")
bottomBarLine.Name              = "TopLine"
bottomBarLine.Size              = UDim2.new(1,0,0,1)
bottomBarLine.BackgroundColor3  = C_BORDER
bottomBarLine.BorderSizePixel   = 0
bottomBarLine.ZIndex            = 11
bottomBarLine.Parent            = bottomBar

local bbLayout = Instance.new("UIListLayout")
bbLayout.FillDirection          = Enum.FillDirection.Horizontal
bbLayout.Padding                = UDim.new(0,6)
bbLayout.VerticalAlignment      = Enum.VerticalAlignment.Center
bbLayout.HorizontalAlignment    = Enum.HorizontalAlignment.Left
bbLayout.SortOrder              = Enum.SortOrder.LayoutOrder
bbLayout.Parent                 = bottomBar
addPadding(bottomBar, 6, 8, 6, 8)

local buyModes = {
	{"BuyModeX1","x1",1,true},
	{"BuyModeX10","x10",2,false},
	{"BuyModeX100","x100",3,false},
	{"BuyModeMax","Max",4,false},
}
for _, bm in ipairs(buyModes) do
	local bb = Instance.new("TextButton")
	bb.Name             = bm[1]
	bb.Text             = bm[2]
	bb.Size             = UDim2.new(0,58,0,34)
	bb.BackgroundColor3 = bm[4] and C_ACCENT or C_PANEL2
	bb.TextColor3       = bm[4] and Color3.fromRGB(18,18,32) or C_TEXT
	bb.TextSize         = 14
	bb.Font             = Enum.Font.GothamBold
	bb.BorderSizePixel  = 0
	bb.LayoutOrder      = bm[3]
	bb.ZIndex           = 11
	bb.Parent           = bottomBar
	addCorner(bb, 7)
end

-- Auto toggle (locked, greyed out)
local autoBtn = Instance.new("TextButton")
autoBtn.Name             = "AutoToggle"
autoBtn.Text             = "Auto 🔒"
autoBtn.Size             = UDim2.new(0,78,0,34)
autoBtn.BackgroundColor3 = C_LOCKED
autoBtn.TextColor3       = C_MUTED
autoBtn.TextSize         = 12
autoBtn.Font             = Enum.Font.GothamMedium
autoBtn.BorderSizePixel  = 0
autoBtn.LayoutOrder      = 5
autoBtn.ZIndex           = 11
autoBtn.Parent           = bottomBar
addCorner(autoBtn, 7)

-- ── POPUPS LAYER ──────────────────────────────────────────────────────────────
local popupsLayer = Instance.new("Frame")
popupsLayer.Name                   = "PopupsLayer"
popupsLayer.Size                   = UDim2.new(1,0,1,0)
popupsLayer.BackgroundTransparency = 1
popupsLayer.BorderSizePixel        = 0
popupsLayer.ZIndex                 = 50
popupsLayer.Parent                 = screenGui

print("[BuildAll] GUI hierarchy built.")

-- ╔══════════════════════════════════════════════════════════════════════════════
-- ║  STEP 4: StarterPlayerScripts — GameClient, AnimationController, UIStateManager
-- ╚══════════════════════════════════════════════════════════════════════════════
print("[BuildAll] Creating client scripts...")

-- ── GameClient ────────────────────────────────────────────────────────────────
makeLocalScript(SPS, "GameClient", [[
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local gui=playerGui:WaitForChild("CarrotClickerGui")
local RS=game:GetService("ReplicatedStorage")
local Modules=RS:WaitForChild("Modules")
local GC=require(Modules:WaitForChild("GameConfig"))
local NF=require(Modules:WaitForChild("NumberFormatter"))
local Rem=require(Modules:WaitForChild("Remotes"))
-- GUI refs
local topBar=gui:WaitForChild("TopBar")
local currDisp=topBar:WaitForChild("CurrencyDisplay")
local carrotsLbl=currDisp:WaitForChild("CarrotsAmount")
local perSecLbl=currDisp:WaitForChild("PerSec")
local perClickLbl=currDisp:WaitForChild("PerClick")
local mainArea=gui:WaitForChild("MainArea")
local carrotPlate=mainArea:WaitForChild("CarrotButtonPlate")
local carrotBtn=carrotPlate:WaitForChild("CarrotButton")
local floatLayer=mainArea:WaitForChild("FloatingTextLayer")
local streakMeter=mainArea:WaitForChild("StreakMeter")
local streakLbl=streakMeter:WaitForChild("StreakLabel")
local streakBarFill=streakMeter:WaitForChild("StreakBarBg"):WaitForChild("StreakBarFill")
local streakLostLbl=streakMeter:WaitForChild("StreakLostLabel")
local msTrack=mainArea:WaitForChild("MilestoneTracker")
local msLbl=msTrack:WaitForChild("MilestoneLabel")
local msBarFill=msTrack:WaitForChild("MilestoneBarBg"):WaitForChild("MilestoneBarFill")
local msChip=msTrack:WaitForChild("RewardChip")
local rightPanel=gui:WaitForChild("RightPanel")
local scrollFrame=rightPanel:WaitForChild("UpgradeScrollFrame")
local bottomBar=gui:WaitForChild("BottomBar")
local catTabs=rightPanel:WaitForChild("CategoryTabs")
-- State
local lastState=nil
local streak=0
local lastClickTime=0
local buyMode=1
local activeTab="Click"
local cards={}
-- Tween helper
local function tw(o,p,d,s,dr)
	TweenService:Create(o,TweenInfo.new(d,s or Enum.EasingStyle.Quad,dr or Enum.EasingDirection.Out),p):Play()
end
-- Floating number
local function spawnFloat(n,isCrit,isGolden)
	local l=Instance.new("TextLabel")
	l.Text="+"..NF.format(n)
	l.Font=Enum.Font.GothamBold
	l.TextSize=isCrit and 22 or (isGolden and 20 or 16)
	l.BackgroundTransparency=1
	l.BorderSizePixel=0
	l.ZIndex=15
	l.Size=UDim2.new(0,90,0,30)
	l.TextColor3=isGolden and Color3.fromRGB(255,215,0) or isCrit and Color3.fromRGB(255,100,50) or Color3.fromRGB(255,200,80)
	local x=math.random(-35,35)
	l.Position=UDim2.new(0.5,x-45,0.5,0)
	l.Parent=floatLayer
	tw(l,{Position=UDim2.new(0.5,x-45,0.5,-math.random(40,70)),TextTransparency=1},math.random(35,55)/100)
	task.delay(0.65,function() l:Destroy() end)
end
-- Ripple
local function spawnRipple()
	local r=Instance.new("Frame")
	r.Size=UDim2.new(0.9,0,0.9,0); r.AnchorPoint=Vector2.new(0.5,0.5)
	r.Position=UDim2.new(0.5,0,0.5,0)
	r.BackgroundColor3=Color3.fromRGB(255,165,0); r.BackgroundTransparency=0.65
	r.BorderSizePixel=0; r.ZIndex=carrotBtn.ZIndex+1; r.Parent=carrotPlate
	local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=r
	tw(r,{Size=UDim2.new(1.25,0,1.25,0),BackgroundTransparency=1},0.22)
	task.delay(0.27,function() r:Destroy() end)
end
-- Particles
local function spawnParticles(isCrit)
	local cnt=isCrit and math.random(6,10) or math.random(2,4)
	for _=1,cnt do
		local p=Instance.new("Frame")
		p.Size=UDim2.new(0,math.random(4,8),0,math.random(4,8)); p.AnchorPoint=Vector2.new(0.5,0.5)
		p.Position=UDim2.new(0.5,0,0.5,0)
		p.BackgroundColor3=isCrit and Color3.fromRGB(255,math.random(100,200),0) or Color3.fromRGB(255,165,0)
		p.BackgroundTransparency=0; p.BorderSizePixel=0; p.ZIndex=16; p.Parent=floatLayer
		local c2=Instance.new("UICorner"); c2.CornerRadius=UDim.new(0,2); c2.Parent=p
		local a=math.rad(math.random(0,360)); local d2=math.random(30,80); local dur=math.random(20,60)/100
		tw(p,{Position=UDim2.new(0.5,math.cos(a)*d2,0.5,math.sin(a)*d2),BackgroundTransparency=1},dur)
		task.delay(dur+0.05,function() p:Destroy() end)
	end
end
-- Button press
local function playPress(isCrit,isGolden)
	tw(carrotBtn,{Size=UDim2.new(0.965,0,0.965,0)},0.07,Enum.EasingStyle.Quad)
	task.delay(0.07,function()
		if isCrit then
			tw(carrotBtn,{Size=UDim2.new(1.15,0,1.15,0)},0.08,Enum.EasingStyle.Back)
			task.delay(0.08,function() tw(carrotBtn,{Size=UDim2.new(1,0,1,0)},0.18,Enum.EasingStyle.Back) end)
		else
			tw(carrotBtn,{Size=UDim2.new(1.02,0,1.02,0)},0.07,Enum.EasingStyle.Back)
			task.delay(0.07,function() tw(carrotBtn,{Size=UDim2.new(1,0,1,0)},0.10,Enum.EasingStyle.Quad) end)
		end
	end)
	if isGolden then
		tw(carrotBtn,{BackgroundColor3=Color3.fromRGB(255,215,0)},0.05)
		task.delay(0.3,function() tw(carrotBtn,{BackgroundColor3=Color3.fromRGB(255,140,0)},0.2) end)
	end
end
-- Streak
local decayThread=nil
local function startDecay()
	if decayThread then task.cancel(decayThread) end
	decayThread=task.delay(GC.STREAK_DECAY_DELAY,function()
		tw(streakBarFill,{Size=UDim2.new(0,0,1,0)},GC.STREAK_DECAY_DURATION)
		task.delay(GC.STREAK_DECAY_DURATION,function() streak=0; streakLbl.Text="Harvest Streak: 0x" end)
	end)
end
local function incrStreak()
	local now=tick()
	if now-lastClickTime<=GC.STREAK_WINDOW then
		streak=math.min(streak+1,GC.STREAK_MAX)
	else
		if streak>0 then
			streakLostLbl.Visible=true; streakLostLbl.TextTransparency=0
			tw(streakLostLbl,{TextTransparency=1},0.2)
			task.delay(0.45,function() streakLostLbl.Visible=false end)
		end
		streak=1
	end
	lastClickTime=now
	streakLbl.Text="Harvest Streak: "..streak.."x"
	tw(streakBarFill,{Size=UDim2.new(streak/GC.STREAK_MAX,0,1,0)},0.08)
	if decayThread then task.cancel(decayThread) end
	startDecay()
end
-- Milestone display
local function updateMS(state)
	local next=nil
	for _,ms in ipairs(GC.Milestones) do
		if not (state.milestones and state.milestones[ms.id]) then next=ms; break end
	end
	if not next then
		msLbl.Text="All Milestones Complete! 🎉"; tw(msBarFill,{Size=UDim2.new(1,0,1,0)},0.25); return
	end
	local prog=math.min(state.totalCarrotsAllTime/next.threshold,1)
	msLbl.Text=string.format("Next: %s (%s/%s)",next.name,NF.format(state.totalCarrotsAllTime),NF.format(next.threshold))
	tw(msBarFill,{Size=UDim2.new(prog,0,1,0)},0.25)
	if prog>=0.85 then
		tw(msBarFill,{BackgroundTransparency=0.3},0.4,Enum.EasingStyle.Sine)
		task.delay(0.4,function() tw(msBarFill,{BackgroundTransparency=0},0.4,Enum.EasingStyle.Sine) end)
	end
end
-- Upgrade cards
local CA=Color3.fromRGB(76,175,80); local CL=Color3.fromRGB(60,60,80)
local CE=Color3.fromRGB(80,60,60); local CP=Color3.fromRGB(35,35,60)
local CT=Color3.fromRGB(255,255,255); local CM=Color3.fromRGB(120,120,140)
local CAC=Color3.fromRGB(255,165,0)
local function createCard(u)
	local card=Instance.new("Frame")
	card.Name="Card_"..u.key; card.Size=UDim2.new(1,-8,0,64)
	card.BackgroundColor3=CP; card.BackgroundTransparency=0.15; card.BorderSizePixel=0
	card:SetAttribute("Category",u.category)
	local cc=Instance.new("UICorner"); cc.CornerRadius=UDim.new(0,8); cc.Parent=card
	local ico=Instance.new("TextLabel"); ico.Text=u.category=="Click"and"🖱️"or u.category=="Idle"and"⏱️"or u.category=="Boosts"and"💚"or"🔓"
	ico.Size=UDim2.new(0,44,1,0); ico.Position=UDim2.new(0,4,0,0); ico.BackgroundTransparency=1
	ico.TextSize=22; ico.Font=Enum.Font.GothamMedium; ico.TextColor3=CT; ico.BorderSizePixel=0; ico.Parent=card
	local nl=Instance.new("TextLabel"); nl.Name="NameLbl"; nl.Text=u.name.." Lv 0"
	nl.Size=UDim2.new(1,-108,0,22); nl.Position=UDim2.new(0,52,0,6); nl.BackgroundTransparency=1
	nl.TextSize=14; nl.Font=Enum.Font.GothamBold; nl.TextColor3=CT; nl.TextXAlignment=Enum.TextXAlignment.Left; nl.BorderSizePixel=0; nl.Parent=card
	local el=Instance.new("TextLabel"); el.Name="EffectLbl"; el.Text=u.description
	el.Size=UDim2.new(1,-108,0,18); el.Position=UDim2.new(0,52,0,28); el.BackgroundTransparency=1
	el.TextSize=11; el.Font=Enum.Font.Gotham; el.TextColor3=CM; el.TextXAlignment=Enum.TextXAlignment.Left; el.BorderSizePixel=0; el.Parent=card
	local bb=Instance.new("TextButton"); bb.Name="BuyBtn"; bb.Text="Buy\n--"
	bb.Size=UDim2.new(0,72,0,48); bb.AnchorPoint=Vector2.new(1,0.5); bb.Position=UDim2.new(1,-8,0.5,0)
	bb.BackgroundColor3=CL; bb.TextColor3=CT; bb.TextSize=11; bb.Font=Enum.Font.GothamBold
	bb.BorderSizePixel=0; bb.AutoButtonColor=false; bb.Parent=card
	local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,8); bc.Parent=bb
	card.Parent=scrollFrame
	cards[u.key]={frame=card,nameLbl=nl,effectLbl=el,buyBtn=bb}
	bb.MouseButton1Click:Connect(function()
		if not lastState then return end
		local lv=lastState.upgrades[u.key] or 0
		local cost=GC.getUpgradeCost(u.key,lv)
		if lastState.carrots<cost then
			tw(bb,{BackgroundColor3=Color3.fromRGB(220,50,50)},0.06)
			task.delay(0.3,function() tw(bb,{BackgroundColor3=CE},0.15) end)
			local op=bb.Position; local ox=op.X.Offset
			for i,v in ipairs({5,-5,4,-4,2,0}) do
				task.delay((i-1)*0.04,function() bb.Position=UDim2.new(op.X.Scale,ox+v,op.Y.Scale,op.Y.Offset) end)
			end
			return
		end
		Rem.get("BuyUpgrade"):FireServer(u.key,buyMode)
	end)
end
for _,u in ipairs(GC.Upgrades) do createCard(u) end
-- Category tab switching
local function refreshTabs()
	for _,ct in ipairs({"Click","Idle","Boosts","Unlocks"}) do
		local btn=catTabs:FindFirstChild("Tab"..ct)
		if btn then
			if activeTab==ct then btn.BackgroundColor3=CAC; btn.TextColor3=Color3.fromRGB(26,26,46)
			else btn.BackgroundColor3=CL; btn.TextColor3=CT end
		end
	end
	for _,ch in ipairs(scrollFrame:GetChildren()) do
		if ch:IsA("Frame") then
			local cat=ch:GetAttribute("Category")
			if cat then ch.Visible=(activeTab==cat or activeTab=="Unlocks") end
		end
	end
end
for _,ct in ipairs({"Click","Idle","Boosts","Unlocks"}) do
	local btn=catTabs:FindFirstChild("Tab"..ct)
	if btn then btn.MouseButton1Click:Connect(function() activeTab=ct; refreshTabs() end) end
end
-- Buy mode
local function refreshBM()
	local map={BuyModeX1=1,BuyModeX10=10,BuyModeX100=100,BuyModeMax=-1}
	for n,v in pairs(map) do
		local b=bottomBar:FindFirstChild(n)
		if b then
			if buyMode==v then b.BackgroundColor3=CAC; b.TextColor3=Color3.fromRGB(26,26,46)
			else b.BackgroundColor3=CP; b.TextColor3=CT end
		end
	end
end
local bmMap={BuyModeX1=1,BuyModeX10=10,BuyModeX100=100,BuyModeMax=-1}
for n,v in pairs(bmMap) do
	local b=bottomBar:FindFirstChild(n)
	if b then b.MouseButton1Click:Connect(function() buyMode=v; refreshBM() end) end
end
refreshBM()
-- Update cards from state
local function refreshCards(state)
	for _,u in ipairs(GC.Upgrades) do
		local c=cards[u.key]; if not c then continue end
		local ok=(state.totalCarrotsAllTime>=u.unlockAt)
		local lv=state.upgrades[u.key] or 0
		local cost=GC.getUpgradeCost(u.key,lv)
		local afford=ok and(state.carrots>=cost)
		local atMax=u.maxLevel and(lv>=u.maxLevel)
		c.nameLbl.Text=u.name.." Lv "..lv
		c.effectLbl.Text=string.format(u.effectDesc,lv)..(u.maxLevel and(" (max:"..u.maxLevel..")") or "")
		c.frame.Visible=ok
		if atMax then c.buyBtn.Text="MAX"; c.buyBtn.BackgroundColor3=Color3.fromRGB(50,100,50); c.buyBtn.TextColor3=CM
		elseif not ok then c.buyBtn.Text="🔒\n"..NF.format(u.unlockAt); c.buyBtn.BackgroundColor3=CL; c.buyBtn.TextColor3=CM
		elseif afford then c.buyBtn.Text="Buy\n"..NF.format(cost); c.buyBtn.BackgroundColor3=CA; c.buyBtn.TextColor3=CT
		else c.buyBtn.Text=NF.format(cost); c.buyBtn.BackgroundColor3=CE; c.buyBtn.TextColor3=CM end
	end
	local ll=scrollFrame:FindFirstChildOfClass("UIListLayout")
	if ll then scrollFrame.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+12) end
end
-- HUD update
local function onState(state)
	lastState=state
	local cs=NF.format(state.carrots)
	if carrotsLbl.Text~=cs then
		carrotsLbl.Text=cs
		local os2=carrotsLbl.TextSize; carrotsLbl.TextSize=math.floor(os2*1.04)
		tw(carrotsLbl,{TextSize=os2},0.12)
	end
	perSecLbl.Text=NF.format(GC.computePassiveIncome(state)).."/s"
	local perClick=GC.computeClickValue(state,0)
	perClickLbl.Text=NF.format(perClick).."/click"
	refreshCards(state); updateMS(state); refreshTabs()
end
Rem.get("UpdateState").OnClientEvent:Connect(onState)
Rem.get("CritNotify").OnClientEvent:Connect(function(n) spawnFloat(n,true,false); spawnParticles(true); playPress(true,false) end)
Rem.get("GoldenClickNotify").OnClientEvent:Connect(function(n) spawnFloat(n,false,true); playPress(false,true) end)
Rem.get("MilestoneReached").OnClientEvent:Connect(function(ms)
	msChip.Text="🎉 "..ms.name; msChip.Visible=true; msChip.TextTransparency=0
	for _=1,math.random(12,20) do
		local p=Instance.new("Frame"); p.Size=UDim2.new(0,math.random(5,10),0,math.random(5,10))
		p.AnchorPoint=Vector2.new(0.5,0.5); p.Position=UDim2.new(math.random(20,80)/100,0,0.5,0)
		p.BackgroundColor3=Color3.fromRGB(math.random(150,255),math.random(150,255),math.random(50,255))
		p.BackgroundTransparency=0; p.BorderSizePixel=0; p.ZIndex=18; p.Parent=msTrack
		local dur2=math.random(40,90)/100
		tw(p,{Position=UDim2.new(p.Position.X.Scale,0,p.Position.Y.Scale-0.4,0),BackgroundTransparency=1},dur2)
		task.delay(dur2+0.05,function() p:Destroy() end)
	end
	task.delay(0.9,function() tw(msChip,{TextTransparency=1},0.3); task.delay(0.35,function() msChip.Visible=false end) end)
end)
-- Click handler
carrotBtn.MouseButton1Click:Connect(function()
	incrStreak(); spawnRipple(); spawnParticles(false); playPress(false,false); spawnFloat(1,false,false)
	Rem.get("ClickCarrot"):FireServer(streak)
end)
-- Left rail
local leftRail=gui:WaitForChild("LeftRail")
local upBtn=leftRail:FindFirstChild("UpgradesTab")
if upBtn then upBtn.MouseButton1Click:Connect(function() rightPanel.Visible=not rightPanel.Visible end) end
print("[GameClient] Ready.")
]])

-- ── AnimationController ───────────────────────────────────────────────────────
makeLocalScript(SPS, "AnimationController", [[
-- AnimationController: handles persistent background animations.
-- Button/ripple/particle animations are handled directly by GameClient for
-- tight synchronisation with click events. This script manages:
--   • Glow ring continuous pulse
--   • Grid parallax drift (animated via Frame position offset)
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local gui=player:WaitForChild("PlayerGui"):WaitForChild("CarrotClickerGui")
local mainArea=gui:WaitForChild("MainArea")
local plate=mainArea:WaitForChild("CarrotButtonPlate")
local ring=plate:WaitForChild("GlowRing")
-- Glow ring pulse (matches initial size of 1.08 scale)
local function pulse()
	TweenService:Create(ring,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0.65,Size=UDim2.new(1.14,0,1.14,0)}):Play()
	task.delay(1,function()
		TweenService:Create(ring,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0.82,Size=UDim2.new(1.08,0,1.08,0)}):Play()
	end)
end
task.spawn(function() while true do pulse(); task.wait(2) end end)
print("[AnimCtrl] Ready.")
]])

-- ── UIStateManager ────────────────────────────────────────────────────────────
makeLocalScript(SPS, "UIStateManager", [[
-- UIStateManager: locked tab tooltips.
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local gui=player:WaitForChild("PlayerGui"):WaitForChild("CarrotClickerGui")
local leftRail=gui:WaitForChild("LeftRail")
local lockedTabs={"ReplantTab","PetsTab","QuestsTab","ShopTab"}
for _,name in ipairs(lockedTabs) do
	local btn=leftRail:FindFirstChild(name)
	if btn then
		local tip=Instance.new("TextLabel"); tip.Name="Tooltip"
		tip.Text="Coming Soon"; tip.Size=UDim2.new(0,110,0,28)
		tip.Position=UDim2.new(1,6,0.5,-14)
		tip.BackgroundColor3=Color3.fromRGB(20,20,35); tip.BackgroundTransparency=0.1
		tip.TextColor3=Color3.fromRGB(255,255,255); tip.TextSize=11
		tip.Font=Enum.Font.GothamMedium; tip.BorderSizePixel=0; tip.ZIndex=20; tip.Visible=false
		local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,4); c.Parent=tip
		tip.Parent=btn
		btn.MouseEnter:Connect(function() tip.Visible=true end)
		btn.MouseLeave:Connect(function() tip.Visible=false end)
	end
end
print("[UIState] Ready.")
]])

print("[BuildAll] Client scripts created.")

-- ╔══════════════════════════════════════════════════════════════════════════════
-- ║  DONE
-- ╚══════════════════════════════════════════════════════════════════════════════
print("")
print("╔══════════════════════════════════════════════╗")
print("║  ✅ Carrot Clicker build complete!           ║")
print("║                                              ║")
print("║  Press F5 (Play) to test the game.           ║")
print("║  Click the 🥕 to earn Carrots!               ║")
print("╚══════════════════════════════════════════════╝")
