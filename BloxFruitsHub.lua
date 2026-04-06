--[[
    Blox Fruits Hub v2.0
    Built on Fluent UI (sidebar navigation)
    Features: Farm | ESP | Teleport | Combat | Settings
    Toggle: LeftAlt (Fluent default)
]]

------------------------------------------------------
-- STARTUP + DUPLICATE PREVENTION
------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

-- If already loaded, re-show the window instead of blocking
local alreadyLoaded = false
pcall(function()
    if getgenv and getgenv().BFHubLoaded and getgenv().BFHubFluent then
        -- Re-open the existing window
        pcall(function()
            getgenv().BFHubFluent:Destroy()
            getgenv().BFHubFluent = nil
            getgenv().BFHubLoaded = false
        end)
    end
end)

task.wait(2 + math.random() * 2)

------------------------------------------------------
-- SERVICES
------------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

------------------------------------------------------
-- LOADING NOTIFICATION
------------------------------------------------------
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "BF Hub", Text = "Loading sidebar UI...", Duration = 8,
    })
end)

------------------------------------------------------
-- LOAD FLUENT UI
------------------------------------------------------
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

pcall(function()
    if getgenv then getgenv().BFHubLoaded = true end
end)

------------------------------------------------------
-- HELPERS
------------------------------------------------------
local function jitterWait(base)
    task.wait(base * (0.8 + math.random() * 0.7))
end

local Connections = {}
local ESPObjects = {}
local FruitESPObjects = {}

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function isAlive(player)
    local char = player and player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

------------------------------------------------------
-- ISLAND DATA
------------------------------------------------------
local Islands = {
    {sea = 1, name = "Starter Island",    pos = CFrame.new(1093, 16, 1310)},
    {sea = 1, name = "Jungle",            pos = CFrame.new(-1613, 37, 152)},
    {sea = 1, name = "Pirate Village",    pos = CFrame.new(-1152, 5, 3826)},
    {sea = 1, name = "Desert",            pos = CFrame.new(903, 20, 4393)},
    {sea = 1, name = "Frozen Village",    pos = CFrame.new(1510, 88, -5765)},
    {sea = 1, name = "Marine Fortress",   pos = CFrame.new(-4851, 25, 4332)},
    {sea = 1, name = "Skylands",          pos = CFrame.new(-4851, 800, -2561)},
    {sea = 1, name = "Prison",            pos = CFrame.new(4875, 6, 735)},
    {sea = 1, name = "Colosseum",         pos = CFrame.new(-1428, 8, -2867)},
    {sea = 1, name = "Magma Village",     pos = CFrame.new(-5312, 12, 8531)},
    {sea = 1, name = "Underwater City",   pos = CFrame.new(3856, -2, 1174)},
    {sea = 1, name = "Fountain City",     pos = CFrame.new(5259, 40, 4711)},
    {sea = 2, name = "Kingdom of Rose",   pos = CFrame.new(-2247, 73, -1671)},
    {sea = 2, name = "Green Zone",        pos = CFrame.new(-2448, 8, -3208)},
    {sea = 2, name = "Graveyard",         pos = CFrame.new(-5434, 12, -793)},
    {sea = 2, name = "Snow Mountain",     pos = CFrame.new(609, 400, -5258)},
    {sea = 2, name = "Hot and Cold",      pos = CFrame.new(-6224, 16, -4902)},
    {sea = 2, name = "Cursed Ship",       pos = CFrame.new(916, 40, -5574)},
    {sea = 2, name = "Ice Castle",        pos = CFrame.new(6170, 290, -6734)},
    {sea = 2, name = "Forgotten Island",  pos = CFrame.new(-3053, 240, -10112)},
    {sea = 2, name = "Mansion",           pos = CFrame.new(-4607, 86, 4187)},
    {sea = 3, name = "Port Town",         pos = CFrame.new(-290, 14, 5321)},
    {sea = 3, name = "Hydra Island",      pos = CFrame.new(-4459, 200, -5726)},
    {sea = 3, name = "Great Tree",        pos = CFrame.new(2164, -15, -966)},
    {sea = 3, name = "Floating Turtle",   pos = CFrame.new(-12681, 380, -7504)},
    {sea = 3, name = "Castle on the Sea", pos = CFrame.new(-5097, 295, -3177)},
    {sea = 3, name = "Haunted Castle",    pos = CFrame.new(-9499, 150, 5765)},
    {sea = 3, name = "Tiki Outpost",      pos = CFrame.new(-12149, 6, -8480)},
    {sea = 3, name = "Kitsune Shrine",    pos = CFrame.new(-7894, 687, -5765)},
}

------------------------------------------------------
-- FRUIT ESP SYSTEM
------------------------------------------------------
local function cleanupFruitESP()
    for obj, bb in pairs(FruitESPObjects) do
        if bb and bb.Parent then bb:Destroy() end
    end
    FruitESPObjects = {}
end

local function createFruitBillboard(fruitModel)
    if FruitESPObjects[fruitModel] then return end
    local part = fruitModel:FindFirstChildWhichIsA("BasePart") or fruitModel.PrimaryPart
    if not part then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "F"; bb.Adornee = part; bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 4, 0); bb.AlwaysOnTop = true; bb.Parent = part
    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(1, 0, 0.6, 0); nl.BackgroundTransparency = 1
    nl.TextColor3 = Color3.fromRGB(255, 200, 50); nl.Font = Enum.Font.GothamBold
    nl.TextSize = 16; nl.TextStrokeTransparency = 0.3; nl.TextStrokeColor3 = Color3.new(0,0,0)
    nl.Text = fruitModel.Name; nl.Parent = bb
    local dl = Instance.new("TextLabel")
    dl.Name = "D"; dl.Size = UDim2.new(1, 0, 0.4, 0); dl.Position = UDim2.new(0, 0, 0.6, 0)
    dl.BackgroundTransparency = 1; dl.TextColor3 = Color3.fromRGB(255, 255, 200)
    dl.Font = Enum.Font.Gotham; dl.TextSize = 12; dl.TextStrokeTransparency = 0.3
    dl.TextStrokeColor3 = Color3.new(0,0,0); dl.Parent = bb
    FruitESPObjects[fruitModel] = bb
end

local function isActualFruit(obj)
    if obj.Parent ~= Workspace then return false end
    if not obj.Name:match("Fruit$") then return false end
    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then return false end
    for _, p in pairs(Players:GetPlayers()) do
        if obj:IsDescendantOf(p.Character) or obj:IsDescendantOf(p) then return false end
    end
    local lower = obj.Name:lower()
    if lower:find("dealer") or lower:find("shop") or lower:find("npc") or lower:find("vendor") then return false end
    return true
end

local function scanForFruits()
    local found = {}
    for _, obj in pairs(Workspace:GetChildren()) do
        if isActualFruit(obj) then table.insert(found, obj); createFruitBillboard(obj) end
    end
    return found
end

local function updateFruitESP()
    local myHRP = getHRP()
    if not myHRP then return end
    for obj, bb in pairs(FruitESPObjects) do
        if not obj.Parent then
            if bb and bb.Parent then bb:Destroy() end
            FruitESPObjects[obj] = nil
        else
            local part = obj:FindFirstChildWhichIsA("BasePart") or obj.PrimaryPart
            if part then
                local dl = bb:FindFirstChild("D")
                if dl then dl.Text = math.floor((part.Position - myHRP.Position).Magnitude) .. "m away" end
            end
        end
    end
    scanForFruits()
end

------------------------------------------------------
-- PLAYER ESP SYSTEM
------------------------------------------------------
local function cleanupPlayerESP()
    for player, bb in pairs(ESPObjects) do
        if bb and bb.Parent then bb:Destroy() end
    end
    ESPObjects = {}
end

local function createPlayerBillboard(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    if ESPObjects[player] then ESPObjects[player]:Destroy() end
    local bb = Instance.new("BillboardGui")
    bb.Name = "P"; bb.Adornee = head; bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = true; bb.Parent = head
    local nl = Instance.new("TextLabel")
    nl.Name = "N"; nl.Size = UDim2.new(1, 0, 0.5, 0); nl.BackgroundTransparency = 1
    nl.TextColor3 = Color3.fromRGB(255, 100, 100); nl.Font = Enum.Font.GothamBold
    nl.TextSize = 13; nl.TextStrokeTransparency = 0.4; nl.TextStrokeColor3 = Color3.new(0,0,0)
    nl.Text = player.Name; nl.Parent = bb
    local il = Instance.new("TextLabel")
    il.Name = "I"; il.Size = UDim2.new(1, 0, 0.5, 0); il.Position = UDim2.new(0, 0, 0.5, 0)
    il.BackgroundTransparency = 1; il.Font = Enum.Font.Gotham; il.TextSize = 10
    il.TextStrokeTransparency = 0.4; il.TextStrokeColor3 = Color3.new(0,0,0)
    il.TextColor3 = Color3.fromRGB(255, 180, 180); il.Parent = bb
    ESPObjects[player] = bb
end

local function updatePlayerESP()
    local myHRP = getHRP()
    if not myHRP then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local bb = ESPObjects[player]
            if not bb or not bb.Parent then createPlayerBillboard(player); bb = ESPObjects[player] end
            if bb then
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = math.floor((hrp.Position - myHRP.Position).Magnitude)
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local hp = hum and math.floor(hum.Health) or 0
                    local maxHp = hum and math.floor(hum.MaxHealth) or 0
                    local n = bb:FindFirstChild("N"); local i = bb:FindFirstChild("I")
                    if n then n.Text = player.Name end
                    if i then i.Text = string.format("%dm | HP: %d/%d", dist, hp, maxHp) end
                else
                    if bb.Parent then bb:Destroy() end; ESPObjects[player] = nil
                end
            end
        end
    end
    for player, bb in pairs(ESPObjects) do
        if not player.Parent then
            if bb and bb.Parent then bb:Destroy() end; ESPObjects[player] = nil
        end
    end
end

------------------------------------------------------
-- TELEPORT (No-clip)
------------------------------------------------------
local function setNoclip(state)
    pcall(function()
        local char = getCharacter()
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = not state end
        end
    end)
end

local function teleportTo(cf)
    local hrp = getHRP()
    if not hrp then return end
    local startPos = hrp.Position
    local targetPos = cf.Position
    local dist = (targetPos - startPos).Magnitude
    if dist < 50 then hrp.CFrame = cf + Vector3.new(0, 3, 0); return end
    setNoclip(true)
    local noclipConn = RunService.Stepped:Connect(function()
        pcall(function()
            local char = getCharacter()
            if char then for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end end
        end)
    end)
    local steps = math.clamp(math.floor(dist / 75), 8, 30)
    for i = 1, steps do
        if not getHRP() then break end
        getHRP().CFrame = CFrame.new(startPos:Lerp(targetPos, i / steps) + Vector3.new(0, 20, 0))
        jitterWait(0.1)
    end
    task.wait(0.2)
    local finalHRP = getHRP()
    if finalHRP then finalHRP.CFrame = cf + Vector3.new(0, 5, 0) end
    task.wait(0.3)
    if noclipConn then noclipConn:Disconnect() end
    setNoclip(false)
end

------------------------------------------------------
-- AIMBOT
------------------------------------------------------
local AimbotConfig = { Enabled = false, Range = 100, TargetPlayers = true, TargetNPCs = true }

local function findAimbotTarget()
    local hrp = getHRP()
    if not hrp then return nil end
    local nearest, bestDist = nil, AimbotConfig.Range
    if AimbotConfig.TargetPlayers then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and isAlive(player) then
                local t = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if t then local d = (t.Position - hrp.Position).Magnitude
                    if d < bestDist then nearest = t; bestDist = d end
                end
            end
        end
    end
    if AimbotConfig.TargetNPCs then
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then for _, mob in pairs(enemies:GetChildren()) do
            if mob:IsA("Model") then
                local hum = mob:FindFirstChildOfClass("Humanoid")
                local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
                if hum and hum.Health > 0 and root then
                    local d = (root.Position - hrp.Position).Magnitude
                    if d < bestDist then nearest = root; bestDist = d end
                end
            end
        end end
    end
    return nearest
end

local function runAimbot()
    Connections["Aimbot"] = RunService.RenderStepped:Connect(function()
        if not AimbotConfig.Enabled or not isAlive(LocalPlayer) then return end
        local target = findAimbotTarget()
        if not target then return end
        local hrp = getHRP()
        if not hrp then return end
        hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(target.Position.X, hrp.Position.Y, target.Position.Z))
        pcall(function()
            local cam = Workspace.CurrentCamera
            if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + (target.Position - cam.CFrame.Position).Unit) end
        end)
    end)
end

------------------------------------------------------
-- AUTO SKILLS
------------------------------------------------------
local AutoSkillConfig = {
    Enabled = false,
    Skills = {
        {key = Enum.KeyCode.Z, cooldown = 3,  lastUsed = 0},
        {key = Enum.KeyCode.X, cooldown = 5,  lastUsed = 0},
        {key = Enum.KeyCode.C, cooldown = 8,  lastUsed = 0},
        {key = Enum.KeyCode.V, cooldown = 12, lastUsed = 0},
        {key = Enum.KeyCode.F, cooldown = 20, lastUsed = 0},
    },
}

local function runAutoSkills()
    Connections["AutoSkills"] = RunService.Heartbeat:Connect(function()
        if not AutoSkillConfig.Enabled or not isAlive(LocalPlayer) then return end
        local hrp = getHRP()
        if not hrp then return end
        local hasTarget = false
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then for _, mob in pairs(enemies:GetChildren()) do
            local hum = mob:FindFirstChildOfClass("Humanoid")
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
            if hum and hum.Health > 0 and root and (root.Position - hrp.Position).Magnitude < 30 then
                hasTarget = true; break
            end
        end end
        if not hasTarget then for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and isAlive(player) then
                local p = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if p and (p.Position - hrp.Position).Magnitude < 30 then hasTarget = true; break end
            end
        end end
        if not hasTarget then return end
        local now = tick()
        for _, skill in ipairs(AutoSkillConfig.Skills) do
            if (now - skill.lastUsed) >= skill.cooldown then
                pcall(function()
                    local vim = game:GetService("VirtualInputManager")
                    vim:SendKeyEvent(true, skill.key, false, game)
                    task.wait(0.05)
                    vim:SendKeyEvent(false, skill.key, false, game)
                end)
                skill.lastUsed = now; jitterWait(0.4); break
            end
        end
    end)
end

------------------------------------------------------
-- AUTO FARM DATA
------------------------------------------------------
local QuestData = {
    {level = {1, 10},     island = "Starter Island",  mobName = "Bandit",           mobArea = CFrame.new(1093, 16, 1310)},
    {level = {11, 20},    island = "Jungle",           mobName = "Monkey",           mobArea = CFrame.new(-1613, 37, 152)},
    {level = {21, 30},    island = "Jungle",           mobName = "Gorilla",          mobArea = CFrame.new(-1613, 37, 152)},
    {level = {31, 60},    island = "Pirate Village",   mobName = "Pirate",           mobArea = CFrame.new(-1152, 5, 3826)},
    {level = {61, 75},    island = "Desert",           mobName = "Desert Bandit",    mobArea = CFrame.new(903, 20, 4393)},
    {level = {76, 90},    island = "Desert",           mobName = "Desert Officer",   mobArea = CFrame.new(903, 20, 4393)},
    {level = {91, 120},   island = "Frozen Village",   mobName = "Snow Bandit",      mobArea = CFrame.new(1510, 88, -5765)},
    {level = {121, 150},  island = "Marine Fortress",  mobName = "Marine",           mobArea = CFrame.new(-4851, 25, 4332)},
    {level = {151, 175},  island = "Skylands",         mobName = "Sky Bandit",       mobArea = CFrame.new(-4851, 800, -2561)},
    {level = {176, 200},  island = "Skylands",         mobName = "Dark Master",      mobArea = CFrame.new(-4851, 800, -2561)},
    {level = {201, 250},  island = "Prison",           mobName = "Prisoner",         mobArea = CFrame.new(4875, 6, 735)},
    {level = {251, 300},  island = "Colosseum",        mobName = "Gladiator",        mobArea = CFrame.new(-1428, 8, -2867)},
    {level = {301, 350},  island = "Magma Village",    mobName = "Military Soldier", mobArea = CFrame.new(-5312, 12, 8531)},
    {level = {351, 375},  island = "Magma Village",    mobName = "Magma Ninja",      mobArea = CFrame.new(-5312, 12, 8531)},
    {level = {376, 450},  island = "Underwater City",  mobName = "Fishman",          mobArea = CFrame.new(3856, -2, 1174)},
    {level = {451, 525},  island = "Fountain City",    mobName = "Galley Pirate",    mobArea = CFrame.new(5259, 40, 4711)},
    {level = {526, 625},  island = "Fountain City",    mobName = "Galley Captain",   mobArea = CFrame.new(5259, 40, 4711)},
    {level = {700, 850},  island = "Kingdom of Rose",  mobName = "Swan Pirate",      mobArea = CFrame.new(-2247, 73, -1671)},
    {level = {851, 975},  island = "Green Zone",       mobName = "Zombie",           mobArea = CFrame.new(-2448, 8, -3208)},
    {level = {976, 1100}, island = "Graveyard",        mobName = "Vampire",          mobArea = CFrame.new(-5434, 12, -793)},
    {level = {1100,1250}, island = "Snow Mountain",    mobName = "Snow Trooper",     mobArea = CFrame.new(609, 400, -5258)},
    {level = {1250,1425}, island = "Hot and Cold",     mobName = "Magma Ninja",      mobArea = CFrame.new(-6224, 16, -4902)},
    {level = {1425,1500}, island = "Ice Castle",       mobName = "Ice Viking",       mobArea = CFrame.new(6170, 290, -6734)},
    {level = {1500,1625}, island = "Port Town",        mobName = "Pirate Millionaire",mobArea = CFrame.new(-290, 14, 5321)},
    {level = {1625,1800}, island = "Hydra Island",     mobName = "Dragon Crew",      mobArea = CFrame.new(-4459, 200, -5726)},
    {level = {1800,1975}, island = "Great Tree",       mobName = "Jungle Pirate",    mobArea = CFrame.new(2164, -15, -966)},
    {level = {1975,2075}, island = "Floating Turtle",  mobName = "Marine Commodore", mobArea = CFrame.new(-12681, 380, -7504)},
    {level = {2075,2450}, island = "Haunted Castle",   mobName = "Cursed Captain",   mobArea = CFrame.new(-9499, 150, 5765)},
}

local FarmConfig = { Enabled = false, CurrentQuest = nil, Status = "Idle" }
local SniperConfig = { Enabled = false, HopCount = 0, TargetFruits = {} }

local function getPlayerLevel()
    local level = 1
    pcall(function()
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls then local l = ls:FindFirstChild("Level") or ls:FindFirstChild("Lvl")
            if l then level = l.Value; return end
        end
        local data = LocalPlayer:FindFirstChild("Data")
        if data then local l = data:FindFirstChild("Level")
            if l then level = l.Value; return end
        end
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if gui then for _, obj in pairs(gui:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local m = obj.Text:match("Lv%.%s*(%d+)") or obj.Text:match("Level%s*(%d+)")
                if m then level = tonumber(m); return end
            end
        end end
        for _, obj in pairs(LocalPlayer:GetDescendants()) do
            if (obj:IsA("IntValue") or obj:IsA("NumberValue")) and (obj.Name == "Level" or obj.Name == "Lvl") then
                level = obj.Value; return
            end
        end
    end)
    return level
end

local function getBestQuest()
    local level = getPlayerLevel()
    local best = nil
    for _, q in ipairs(QuestData) do
        if level >= q.level[1] and level <= q.level[2] then best = q end
    end
    if not best then
        for i = #QuestData, 1, -1 do
            if getPlayerLevel() >= QuestData[i].level[1] then best = QuestData[i]; break end
        end
    end
    return best
end

local function findMob(mobName, range)
    local hrp = getHRP()
    if not hrp then return nil end
    local nearest, bestDist = nil, range or 300
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    for _, obj in pairs(enemies:GetChildren()) do
        if obj:IsA("Model") and obj.Name == mobName then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
            if hum and hum.Health > 0 and root then
                local d = (root.Position - hrp.Position).Magnitude
                if d < bestDist then nearest = obj; bestDist = d end
            end
        end
    end
    return nearest, bestDist
end

local function hasActiveQuest()
    local has = false
    pcall(function()
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if gui then for _, obj in pairs(gui:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local t = obj.Text:lower()
                if t:find("defeat") or (t:find("quest") and (t:find("%d+/%d+") or t:find("reward"))) then
                    has = true; return
                end
            end
        end end
    end)
    return has
end

local function getQuestProgress()
    local c, t = 0, 0
    pcall(function()
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if gui then for _, obj in pairs(gui:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local a, b = obj.Text:match("%((%d+)/(%d+)%)")
                if a and b then c = tonumber(a); t = tonumber(b); return end
            end
        end end
    end)
    return c, t
end

local function interactNPC(npcModel)
    if not npcModel then return end
    local root = npcModel:FindFirstChild("HumanoidRootPart") or npcModel:FindFirstChild("Head") or npcModel:FindFirstChild("Torso")
    if not root then return end
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(root.Position + Vector3.new(0, 0, 3), root.Position) end
    jitterWait(0.5)
    pcall(function() for _, p in pairs(npcModel:GetDescendants()) do
        if p:IsA("ProximityPrompt") then fireproximityprompt(p); return end
    end end)
    pcall(function() for _, cd in pairs(npcModel:GetDescendants()) do
        if cd:IsA("ClickDetector") then fireclickdetector(cd); return end
    end end)
    pcall(function() for _, d in pairs(npcModel:GetDescendants()) do
        if d:IsA("Dialog") then d:SignalDialogChoiceSelected(LocalPlayer, d.DialogChoices[1]) end
    end end)
    jitterWait(0.5)
end

local function attackMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
    if not root then return end
    local hrp = getHRP()
    if not hrp then return end
    if (root.Position - hrp.Position).Magnitude > 5 then
        hrp.CFrame = CFrame.new(root.Position + Vector3.new(0, 0, 3), root.Position)
    end
    jitterWait(0.05)
    pcall(function() local tool = getCharacter():FindFirstChildOfClass("Tool"); if tool then tool:Activate() end end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true, game, 0); task.wait(0.05)
        vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

local function acceptQuestFromNPC(quest)
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if not npcsFolder then return false end
    teleportTo(quest.mobArea); jitterWait(1.5)
    local bestNPC, bestDist = nil, 200
    for _, obj in pairs(npcsFolder:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
            if root then
                local d = (root.Position - getHRP().Position).Magnitude
                if d < bestDist then bestNPC = obj; bestDist = d end
            end
        end
    end
    if bestNPC then
        interactNPC(bestNPC); jitterWait(1)
        pcall(function()
            local gui = LocalPlayer:FindFirstChild("PlayerGui")
            if gui then for _ = 1, 3 do for _, btn in pairs(gui:GetDescendants()) do
                if btn:IsA("TextButton") then
                    local t = btn.Text:lower()
                    if t:find("accept") or t:find("start") or t:find("ok") or t:find("yes") then
                        pcall(function() fireclick(btn) end)
                        pcall(function() btn.MouseButton1Click:Fire() end)
                        jitterWait(0.3)
                    end
                end
            end; jitterWait(0.5) end end
        end)
        return true
    end
    return false
end

local function runAutoFarm()
    while FarmConfig.Enabled and isAlive(LocalPlayer) do
        local quest = getBestQuest()
        if not quest then FarmConfig.Status = "No quest for level"; jitterWait(3); continue end
        FarmConfig.CurrentQuest = quest
        if not hasActiveQuest() then
            FarmConfig.Status = "Getting quest at " .. quest.island
            acceptQuestFromNPC(quest); jitterWait(1)
            if not hasActiveQuest() then FarmConfig.Status = "Retrying..."; jitterWait(2); continue end
        end
        local cur, tot = getQuestProgress()
        if tot > 0 and cur >= tot then
            FarmConfig.Status = "Turning in quest..."
            acceptQuestFromNPC(quest); jitterWait(2); continue
        end
        local mob, dist = findMob(quest.mobName, 500)
        if mob then
            FarmConfig.Status = string.format("Attacking %s (%dm) [%d/%d]", quest.mobName, math.floor(dist), cur, tot)
            attackMob(mob); jitterWait(0.3)
        else
            FarmConfig.Status = "Moving to " .. quest.island
            teleportTo(quest.mobArea); jitterWait(2)
        end
        jitterWait(0.2)
    end
    FarmConfig.Status = "Stopped"
end

local function serverHop()
    pcall(function()
        local servers = HttpService:JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        if servers and servers.data then
            for i = #servers.data, 2, -1 do
                local j = math.random(1, i)
                servers.data[i], servers.data[j] = servers.data[j], servers.data[i]
            end
            for _, s in pairs(servers.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer); break
                end
            end
        end
    end)
end

local function runFruitSniper()
    while SniperConfig.Enabled do
        jitterWait(3)
        local found = scanForFruits()
        local targetFound = false
        if #found > 0 then
            for _, fruit in ipairs(found) do
                if #SniperConfig.TargetFruits == 0 then targetFound = true; break end
                for _, target in ipairs(SniperConfig.TargetFruits) do
                    if fruit.Name:lower():find(target:lower()) then targetFound = true; break end
                end
                if targetFound then break end
            end
        end
        if targetFound then
            pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "FRUIT FOUND!", Text = found[1].Name, Duration = 15,
            }) end)
            local part = found[1]:FindFirstChildWhichIsA("BasePart") or found[1].PrimaryPart
            if part then teleportTo(CFrame.new(part.Position)) end
            SniperConfig.Enabled = false; break
        else
            SniperConfig.HopCount = SniperConfig.HopCount + 1
            jitterWait(2); serverHop(); jitterWait(8)
        end
    end
end

------------------------------------------------------
-- FLUENT WINDOW
------------------------------------------------------
local Window = Fluent:CreateWindow({
    Title = "BF Hub v2.0",
    SubTitle = "by imoukhs",
    TabWidth = 160,
    Size = UDim2.fromOffset(480, 360),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift,
})

-- Store reference so re-execution can clean up properly
pcall(function()
    if getgenv then getgenv().BFHubFluent = Fluent end
end)

------------------------------------------------------
-- TAB: FARM
------------------------------------------------------
local FarmTab = Window:AddTab({ Title = "Farm", Icon = "swords" })
local detectedLevel = getPlayerLevel()

FarmTab:AddParagraph({ Title = "Auto Farm", Content = "Detected Level: " .. detectedLevel })

local bestQ = getBestQuest()
if bestQ then
    FarmTab:AddParagraph({ Title = "Best Quest", Content = bestQ.island .. " (" .. bestQ.mobName .. ")" })
end

FarmTab:AddToggle("AutoFarm", {
    Title = "Enable Auto Farm",
    Default = false,
    Callback = function(state)
        FarmConfig.Enabled = state
        if state then task.spawn(runAutoFarm) end
    end,
})

FarmTab:AddButton({
    Title = "Equip Best Weapon",
    Callback = function()
        pcall(function()
            local char = getCharacter()
            for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                if tool:IsA("Tool") then tool.Parent = char; break end
            end
        end)
    end,
})

FarmTab:AddButton({
    Title = "Refresh Quest",
    Callback = function()
        local q = getBestQuest()
        if q then
            FarmConfig.CurrentQuest = q
            pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Quest", Text = "Lv." .. getPlayerLevel() .. " → " .. q.island .. " (" .. q.mobName .. ")", Duration = 4,
            }) end)
        end
    end,
})

FarmTab:AddInput("LevelOverride", {
    Title = "Manual Level Override",
    Default = tostring(detectedLevel),
    Placeholder = "Type your level (e.g. 15)",
    Numeric = true,
    Callback = function(text)
        local val = tonumber(text)
        if val and val >= 1 and val <= 2550 then
            getPlayerLevel = function() return val end
            local q = getBestQuest()
            if q then
                FarmConfig.CurrentQuest = q
                pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Level Set", Text = "Lv." .. val .. " → " .. q.island .. " (" .. q.mobName .. ")", Duration = 4,
                }) end)
            end
        end
    end,
})

------------------------------------------------------
-- TAB: ESP
------------------------------------------------------
local ESPTab = Window:AddTab({ Title = "ESP", Icon = "eye" })

ESPTab:AddParagraph({ Title = "Fruit ESP", Content = "Gold markers on spawned fruits through walls" })

ESPTab:AddToggle("FruitESP", {
    Title = "Enable Fruit ESP",
    Default = false,
    Callback = function(state)
        if state then
            scanForFruits()
            Connections["FruitESP"] = RunService.Heartbeat:Connect(function() updateFruitESP() end)
            Connections["FruitAdded"] = Workspace.ChildAdded:Connect(function(obj)
                if obj.Name:match("Fruit$") then task.wait(0.5)
                    if isActualFruit(obj) then
                        createFruitBillboard(obj)
                        pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title = "FRUIT SPAWNED!", Text = obj.Name, Duration = 10,
                        }) end)
                    end
                end
            end)
        else
            if Connections["FruitESP"] then Connections["FruitESP"]:Disconnect(); Connections["FruitESP"] = nil end
            if Connections["FruitAdded"] then Connections["FruitAdded"]:Disconnect(); Connections["FruitAdded"] = nil end
            cleanupFruitESP()
        end
    end,
})

ESPTab:AddButton({
    Title = "Teleport to Nearest Fruit",
    Callback = function()
        local myHRP = getHRP()
        if not myHRP then return end
        local best, bestDist = nil, math.huge
        for obj, _ in pairs(FruitESPObjects) do
            if obj.Parent then
                local part = obj:FindFirstChildWhichIsA("BasePart") or obj.PrimaryPart
                if part then local d = (part.Position - myHRP.Position).Magnitude
                    if d < bestDist then best = part; bestDist = d end
                end
            end
        end
        if best then teleportTo(CFrame.new(best.Position)) else
            pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "No Fruit", Text = "None detected in this server", Duration = 3,
            }) end)
        end
    end,
})

ESPTab:AddParagraph({ Title = "Player ESP", Content = "Name, HP, distance through walls" })

ESPTab:AddToggle("PlayerESP", {
    Title = "Enable Player ESP",
    Default = false,
    Callback = function(state)
        if state then
            for _, p in pairs(Players:GetPlayers()) do createPlayerBillboard(p) end
            Connections["PlayerESP"] = RunService.Heartbeat:Connect(function() updatePlayerESP() end)
            Connections["PlayerJoin"] = Players.PlayerAdded:Connect(function(p)
                p.CharacterAdded:Connect(function() task.wait(1)
                    if Connections["PlayerESP"] then createPlayerBillboard(p) end
                end)
            end)
        else
            if Connections["PlayerESP"] then Connections["PlayerESP"]:Disconnect(); Connections["PlayerESP"] = nil end
            if Connections["PlayerJoin"] then Connections["PlayerJoin"]:Disconnect(); Connections["PlayerJoin"] = nil end
            cleanupPlayerESP()
        end
    end,
})

------------------------------------------------------
-- TAB: TELEPORT
------------------------------------------------------
local TPTab = Window:AddTab({ Title = "Teleport", Icon = "map-pin" })

-- Build dropdown lists per sea
local sea1Names, sea2Names, sea3Names = {}, {}, {}
for _, island in ipairs(Islands) do
    if island.sea == 1 then table.insert(sea1Names, island.name) end
    if island.sea == 2 then table.insert(sea2Names, island.name) end
    if island.sea == 3 then table.insert(sea3Names, island.name) end
end

TPTab:AddDropdown("Sea1TP", {
    Title = "Sea 1",
    Values = sea1Names,
    Multi = false,
    Callback = function(val)
        for _, island in ipairs(Islands) do
            if island.name == val then teleportTo(island.pos); break end
        end
    end,
})

TPTab:AddDropdown("Sea2TP", {
    Title = "Sea 2",
    Values = sea2Names,
    Multi = false,
    Callback = function(val)
        for _, island in ipairs(Islands) do
            if island.name == val then teleportTo(island.pos); break end
        end
    end,
})

TPTab:AddDropdown("Sea3TP", {
    Title = "Sea 3",
    Values = sea3Names,
    Multi = false,
    Callback = function(val)
        for _, island in ipairs(Islands) do
            if island.name == val then teleportTo(island.pos); break end
        end
    end,
})

TPTab:AddParagraph({ Title = "Fruit Sniper", Content = "Auto hops servers hunting for fruits" })

TPTab:AddToggle("FruitSniper", {
    Title = "Enable Fruit Sniper",
    Default = false,
    Callback = function(state)
        SniperConfig.Enabled = state; SniperConfig.HopCount = 0
        if state then task.spawn(runFruitSniper) end
    end,
})

TPTab:AddDropdown("TargetFruits", {
    Title = "Target Fruit",
    Values = {"Any", "Leopard", "Dragon", "Dough", "Venom", "Shadow", "Rumble", "Buddha", "Phoenix", "Magma", "Light", "Ice", "Flame"},
    Multi = true,
    Default = {"Any"},
    Callback = function(options)
        SniperConfig.TargetFruits = {}
        for _, opt in ipairs(options) do
            if opt ~= "Any" then table.insert(SniperConfig.TargetFruits, opt) end
        end
    end,
})

------------------------------------------------------
-- TAB: COMBAT
------------------------------------------------------
local CombatTab = Window:AddTab({ Title = "Combat", Icon = "crosshair" })

CombatTab:AddParagraph({ Title = "Aimbot", Content = "Client-side lock-on. Undetectable." })

CombatTab:AddToggle("Aimbot", {
    Title = "Enable Aimbot",
    Default = false,
    Callback = function(state)
        AimbotConfig.Enabled = state
        if state then runAimbot() else
            if Connections["Aimbot"] then Connections["Aimbot"]:Disconnect(); Connections["Aimbot"] = nil end
        end
    end,
})

CombatTab:AddSlider("AimbotRange", {
    Title = "Aimbot Range",
    Min = 20, Max = 200, Default = 100, Rounding = 0, Suffix = " studs",
    Callback = function(val) AimbotConfig.Range = val end,
})

CombatTab:AddToggle("AimbotPlayers", {
    Title = "Target Players", Default = true,
    Callback = function(state) AimbotConfig.TargetPlayers = state end,
})

CombatTab:AddToggle("AimbotNPCs", {
    Title = "Target NPCs/Enemies", Default = true,
    Callback = function(state) AimbotConfig.TargetNPCs = state end,
})

CombatTab:AddParagraph({ Title = "Auto Skills", Content = "Smart rotation: Z → X → C → V → F\nOnly fires when enemy within 30 studs" })

CombatTab:AddToggle("AutoSkills", {
    Title = "Enable Auto Skills",
    Default = false,
    Callback = function(state)
        AutoSkillConfig.Enabled = state
        if state then runAutoSkills() else
            if Connections["AutoSkills"] then Connections["AutoSkills"]:Disconnect(); Connections["AutoSkills"] = nil end
        end
    end,
})

------------------------------------------------------
-- TAB: SETTINGS
------------------------------------------------------
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

SettingsTab:AddParagraph({ Title = "Utilities" })

SettingsTab:AddButton({
    Title = "Print My Position",
    Callback = function()
        local hrp = getHRP()
        if hrp then
            local str = string.format("CFrame.new(%.0f, %.0f, %.0f)", hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
            print("[BF Hub] " .. str)
            pcall(function() if setclipboard then setclipboard(str) end end)
            pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Copied", Text = str, Duration = 3,
            }) end)
        end
    end,
})

SettingsTab:AddButton({
    Title = "Rejoin Server",
    Callback = function()
        pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)
    end,
})

SettingsTab:AddButton({
    Title = "Server Hop",
    Callback = serverHop,
})

SettingsTab:AddToggle("AntiIdle", {
    Title = "Anti-Idle",
    Default = true,
    Callback = function(state)
        if state then task.spawn(function()
            while state do
                pcall(function()
                    local cam = Workspace.CurrentCamera
                    if cam then
                        cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(0.01), 0)
                        task.wait(0.1)
                        cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(-0.01), 0)
                    end
                end)
                task.wait(55 + math.random() * 10)
            end
        end) end
    end,
})

SettingsTab:AddParagraph({ Title = "Coming Soon", Content = "Auto Raid | Stat Auto-Assign | Chest ESP | Sea Beast Alert" })

-- Fluent config saving
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:SetFolder("BFHub")
InterfaceManager:SetFolder("BFHub")
InterfaceManager:BuildInterfaceSection(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

------------------------------------------------------
-- CLEANUP + SELECT DEFAULT TAB
------------------------------------------------------
Window:SelectTab(1)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then ESPObjects[player]:Destroy(); ESPObjects[player] = nil end
end)

pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "BF Hub", Text = "Ready! Toggle: RightShift", Duration = 3,
}) end)

print("================================================")
print("  BF Hub v2.0 (Fluent) Loaded")
print("  Sidebar: Farm | ESP | Teleport | Combat | Settings")
print("  Toggle: RightShift")
print("================================================")
