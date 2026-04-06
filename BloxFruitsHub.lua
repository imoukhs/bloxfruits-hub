--[[
    Blox Fruits Hub v1.1
    Built on Rayfield UI
    Features: Fruit ESP | Player ESP | Island Teleport
    Safe tier: All features are client-side only (zero ban risk)
    Toggle: RightShift
]]

------------------------------------------------------
-- STARTUP + DUPLICATE PREVENTION
------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

-- Prevent multiple UIs from opening
pcall(function()
    if getgenv and getgenv().BFHubLoaded then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Blox Fruits Hub",
            Text = "Already running!",
            Duration = 3,
        })
        return
    end
end)

-- Check flag (if getgenv worked and flag was set, the return above exits)
-- If we're still here, proceed with loading
local alreadyLoaded = false
pcall(function()
    if getgenv and getgenv().BFHubLoaded then
        alreadyLoaded = true
    end
end)
if alreadyLoaded then return end

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
        Title = "Blox Fruits Hub",
        Text = "Loading UI... please wait",
        Duration = 8,
    })
end)

------------------------------------------------------
-- LOAD RAYFIELD
------------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Mark as loaded so duplicate executions are blocked
pcall(function()
    if getgenv then getgenv().BFHubLoaded = true end
end)

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Blox Fruits Hub",
        Text = "Hub ready!",
        Duration = 3,
    })
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
-- ISLAND DATA (Real Blox Fruits coordinates)
------------------------------------------------------
local Islands = {
    -- SEA 1
    {sea = 1, name = "Starter Island",         pos = CFrame.new(1093, 16, 1310)},
    {sea = 1, name = "Jungle",                 pos = CFrame.new(-1613, 37, 152)},
    {sea = 1, name = "Pirate Village",         pos = CFrame.new(-1152, 5, 3826)},
    {sea = 1, name = "Desert",                 pos = CFrame.new(903, 20, 4393)},
    {sea = 1, name = "Frozen Village",         pos = CFrame.new(1510, 88, -5765)},
    {sea = 1, name = "Marine Fortress",        pos = CFrame.new(-4851, 25, 4332)},
    {sea = 1, name = "Skylands",               pos = CFrame.new(-4851, 800, -2561)},
    {sea = 1, name = "Prison",                 pos = CFrame.new(4875, 6, 735)},
    {sea = 1, name = "Colosseum",              pos = CFrame.new(-1428, 8, -2867)},
    {sea = 1, name = "Magma Village",          pos = CFrame.new(-5312, 12, 8531)},
    {sea = 1, name = "Underwater City",        pos = CFrame.new(3856, -2, 1174)},
    {sea = 1, name = "Fountain City",          pos = CFrame.new(5259, 40, 4711)},

    -- SEA 2
    {sea = 2, name = "Kingdom of Rose",        pos = CFrame.new(-2247, 73, -1671)},
    {sea = 2, name = "Green Zone",             pos = CFrame.new(-2448, 8, -3208)},
    {sea = 2, name = "Graveyard",              pos = CFrame.new(-5434, 12, -793)},
    {sea = 2, name = "Snow Mountain",          pos = CFrame.new(609, 400, -5258)},
    {sea = 2, name = "Hot and Cold",           pos = CFrame.new(-6224, 16, -4902)},
    {sea = 2, name = "Cursed Ship",            pos = CFrame.new(916, 40, -5574)},
    {sea = 2, name = "Ice Castle",             pos = CFrame.new(6170, 290, -6734)},
    {sea = 2, name = "Forgotten Island",       pos = CFrame.new(-3053, 240, -10112)},
    {sea = 2, name = "Usopp Island",           pos = CFrame.new(4804, 5, 714)},
    {sea = 2, name = "Mansion",                pos = CFrame.new(-4607, 86, 4187)},

    -- SEA 3
    {sea = 3, name = "Port Town",              pos = CFrame.new(-290, 14, 5321)},
    {sea = 3, name = "Hydra Island",           pos = CFrame.new(-4459, 200, -5726)},
    {sea = 3, name = "Great Tree",             pos = CFrame.new(2164, -15, -966)},
    {sea = 3, name = "Floating Turtle",        pos = CFrame.new(-12681, 380, -7504)},
    {sea = 3, name = "Castle on the Sea",      pos = CFrame.new(-5097, 295, -3177)},
    {sea = 3, name = "Haunted Castle",         pos = CFrame.new(-9499, 150, 5765)},
    {sea = 3, name = "Tiki Outpost",           pos = CFrame.new(-12149, 6, -8480)},
    {sea = 3, name = "Kitsune Shrine",         pos = CFrame.new(-7894, 687, -5765)},
}

------------------------------------------------------
-- FRUIT ESP
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
    bb.Name = "F"
    bb.Adornee = part
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.Parent = part

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 200, 50) -- gold for fruits
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 16
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Text = fruitModel.Name
    nameLabel.Parent = bb

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "D"
    distLabel.Size = UDim2.new(1, 0, 0.4, 0)
    distLabel.Position = UDim2.new(0, 0, 0.6, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 12
    distLabel.TextStrokeTransparency = 0.3
    distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distLabel.Parent = bb

    FruitESPObjects[fruitModel] = bb
end

local function isActualFruit(obj)
    -- CONFIRMED from DEX: Fruits spawn as DIRECT CHILDREN of Workspace
    -- Named like "Blade Fruit", "Spring Fruit", etc.
    -- They are Tool instances (not Models), no Humanoid
    -- Parent must be Workspace (not inside NPC, Enemies, Characters, etc.)

    -- Must be direct child of Workspace
    if obj.Parent ~= Workspace then return false end

    -- Must end with "Fruit" in the name
    local name = obj.Name
    if not name:match("Fruit$") then return false end

    -- REJECT: Has Humanoid (NPC)
    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then return false end

    -- REJECT: Is in player inventory
    for _, p in pairs(Players:GetPlayers()) do
        if obj:IsDescendantOf(p.Character) or obj:IsDescendantOf(p) then
            return false
        end
    end

    -- REJECT: NPC/dealer keywords
    local lower = name:lower()
    if lower:find("dealer") or lower:find("shop") or lower:find("npc") or lower:find("vendor") then
        return false
    end

    return true
end

local function scanForFruits()
    local found = {}

    -- Scan direct children of Workspace for fruits
    -- (confirmed via DEX: "Blade Fruit", "Spring Fruit" etc. are Workspace children)
    for _, obj in pairs(Workspace:GetChildren()) do
        if isActualFruit(obj) then
            table.insert(found, obj)
            createFruitBillboard(obj)
        end
    end

    return found
end

local function updateFruitESP()
    local myHRP = getHRP()
    if not myHRP then return end

    -- Update distances
    for obj, bb in pairs(FruitESPObjects) do
        if not obj.Parent then
            -- Fruit was picked up or despawned
            if bb and bb.Parent then bb:Destroy() end
            FruitESPObjects[obj] = nil
        else
            local part = obj:FindFirstChildWhichIsA("BasePart") or obj.PrimaryPart
            if part then
                local dist = math.floor((part.Position - myHRP.Position).Magnitude)
                local dl = bb:FindFirstChild("D")
                if dl then dl.Text = dist .. "m away" end
            end
        end
    end

    -- Scan for new fruits
    scanForFruits()
end

------------------------------------------------------
-- PLAYER ESP
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
    bb.Name = "P"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head

    local nl = Instance.new("TextLabel")
    nl.Name = "N"
    nl.Size = UDim2.new(1, 0, 0.5, 0)
    nl.BackgroundTransparency = 1
    nl.TextColor3 = Color3.fromRGB(255, 100, 100)
    nl.Font = Enum.Font.GothamBold
    nl.TextSize = 13
    nl.TextStrokeTransparency = 0.4
    nl.TextStrokeColor3 = Color3.new(0, 0, 0)
    nl.Text = player.Name
    nl.Parent = bb

    local il = Instance.new("TextLabel")
    il.Name = "I"
    il.Size = UDim2.new(1, 0, 0.5, 0)
    il.Position = UDim2.new(0, 0, 0.5, 0)
    il.BackgroundTransparency = 1
    il.Font = Enum.Font.Gotham
    il.TextSize = 10
    il.TextStrokeTransparency = 0.4
    il.TextStrokeColor3 = Color3.new(0, 0, 0)
    il.TextColor3 = Color3.fromRGB(255, 180, 180)
    il.Parent = bb

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
                    local lvl = ""
                    -- Try to get level from leaderstats
                    pcall(function()
                        local ls = player:FindFirstChild("leaderstats")
                        if ls then
                            local lvlVal = ls:FindFirstChild("Level") or ls:FindFirstChild("Lvl")
                            if lvlVal then lvl = " Lv." .. tostring(lvlVal.Value) end
                        end
                    end)
                    local n = bb:FindFirstChild("N")
                    local i = bb:FindFirstChild("I")
                    if n then n.Text = player.Name .. lvl end
                    if i then i.Text = string.format("%dm | HP: %d/%d", dist, hp, maxHp) end
                else
                    if bb.Parent then bb:Destroy() end
                    ESPObjects[player] = nil
                end
            end
        end
    end
    -- Clean departed players
    for player, bb in pairs(ESPObjects) do
        if not player.Parent then
            if bb and bb.Parent then bb:Destroy() end
            ESPObjects[player] = nil
        end
    end
end

------------------------------------------------------
-- TELEPORT
------------------------------------------------------
-- No-clip: temporarily disable collisions during teleport to avoid getting stuck in walls
local function setNoclip(state)
    pcall(function()
        local char = getCharacter()
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not state
            end
        end
    end)
end

local function teleportTo(cf)
    local hrp = getHRP()
    if not hrp then return end
    local startPos = hrp.Position
    local targetPos = cf.Position
    local dist = (targetPos - startPos).Magnitude

    if dist < 50 then
        hrp.CFrame = cf + Vector3.new(0, 3, 0)
        return
    end

    -- Enable no-clip during teleport to avoid wall collisions
    setNoclip(true)

    -- Noclip loop during TP (character collision re-enables each frame)
    local noclipConn
    noclipConn = RunService.Stepped:Connect(function()
        pcall(function()
            local char = getCharacter()
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end)

    -- Gradual TP — ~75 studs per step, fly above terrain
    local steps = math.clamp(math.floor(dist / 75), 8, 30)
    for i = 1, steps do
        if not getHRP() then break end
        local alpha = i / steps
        local mid = startPos:Lerp(targetPos, alpha) + Vector3.new(0, 20, 0)
        getHRP().CFrame = CFrame.new(mid)
        jitterWait(0.1)
    end
    task.wait(0.2)
    local finalHRP = getHRP()
    if finalHRP then
        finalHRP.CFrame = cf + Vector3.new(0, 5, 0)
    end

    -- Re-enable collisions
    task.wait(0.3)
    if noclipConn then noclipConn:Disconnect() end
    setNoclip(false)
end

------------------------------------------------------
-- AIMBOT (Client-side camera lock + face target)
------------------------------------------------------
local AimbotConfig = {
    Enabled = false,
    Target = nil,
    Range = 100,
    TargetPlayers = true,
    TargetNPCs = true,
}

local function findAimbotTarget()
    local hrp = getHRP()
    if not hrp then return nil end
    local nearest, bestDist = nil, AimbotConfig.Range

    -- Target players
    if AimbotConfig.TargetPlayers then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and isAlive(player) then
                local char = player.Character
                local targetHRP = char and char:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    local d = (targetHRP.Position - hrp.Position).Magnitude
                    if d < bestDist then
                        nearest = targetHRP
                        bestDist = d
                    end
                end
            end
        end
    end

    -- Target NPCs/enemies
    if AimbotConfig.TargetNPCs then
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then
            for _, mob in pairs(enemies:GetChildren()) do
                if mob:IsA("Model") then
                    local hum = mob:FindFirstChildOfClass("Humanoid")
                    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
                    if hum and hum.Health > 0 and root then
                        local d = (root.Position - hrp.Position).Magnitude
                        if d < bestDist then
                            nearest = root
                            bestDist = d
                        end
                    end
                end
            end
        end
    end

    return nearest
end

local function runAimbot()
    Connections["Aimbot"] = RunService.RenderStepped:Connect(function()
        if not AimbotConfig.Enabled then return end
        if not isAlive(LocalPlayer) then return end

        local target = findAimbotTarget()
        if not target then return end

        local hrp = getHRP()
        if not hrp then return end

        -- Face the target (client-side camera + character rotation)
        local targetPos = target.Position
        local myPos = hrp.Position

        -- Rotate character to face target
        hrp.CFrame = CFrame.new(myPos, Vector3.new(targetPos.X, myPos.Y, targetPos.Z))

        -- Lock camera towards target (subtle, doesn't force full snap)
        pcall(function()
            local cam = Workspace.CurrentCamera
            if cam then
                local dir = (targetPos - cam.CFrame.Position).Unit
                cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + dir)
            end
        end)
    end)
end

------------------------------------------------------
-- AUTO SKILLS (Smart Rotation)
------------------------------------------------------
local AutoSkillConfig = {
    Enabled = false,
    -- Skill keys: Z, X, C, V are standard Blox Fruits ability keys
    -- F is usually a special/ultimate
    Skills = {
        {key = Enum.KeyCode.Z, cooldown = 3,  lastUsed = 0, name = "Skill 1 (Z)"},
        {key = Enum.KeyCode.X, cooldown = 5,  lastUsed = 0, name = "Skill 2 (X)"},
        {key = Enum.KeyCode.C, cooldown = 8,  lastUsed = 0, name = "Skill 3 (C)"},
        {key = Enum.KeyCode.V, cooldown = 12, lastUsed = 0, name = "Skill 4 (V)"},
        {key = Enum.KeyCode.F, cooldown = 20, lastUsed = 0, name = "Skill 5 (F)"},
    },
}

local function runAutoSkills()
    Connections["AutoSkills"] = RunService.Heartbeat:Connect(function()
        if not AutoSkillConfig.Enabled then return end
        if not isAlive(LocalPlayer) then return end

        -- Only use skills when there's a nearby enemy
        local hrp = getHRP()
        if not hrp then return end

        local hasNearbyTarget = false
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then
            for _, mob in pairs(enemies:GetChildren()) do
                local hum = mob:FindFirstChildOfClass("Humanoid")
                local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
                if hum and hum.Health > 0 and root then
                    if (root.Position - hrp.Position).Magnitude < 30 then
                        hasNearbyTarget = true
                        break
                    end
                end
            end
        end

        -- Also check nearby players (for PvP)
        if not hasNearbyTarget then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and isAlive(player) then
                    local phrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if phrp and (phrp.Position - hrp.Position).Magnitude < 30 then
                        hasNearbyTarget = true
                        break
                    end
                end
            end
        end

        if not hasNearbyTarget then return end

        -- Smart rotation: use skills in order, respecting cooldowns
        local now = tick()
        for _, skill in ipairs(AutoSkillConfig.Skills) do
            if (now - skill.lastUsed) >= skill.cooldown then
                pcall(function()
                    local vim = game:GetService("VirtualInputManager")
                    vim:SendKeyEvent(true, skill.key, false, game)
                    task.wait(0.05)
                    vim:SendKeyEvent(false, skill.key, false, game)
                end)
                skill.lastUsed = now
                -- Small delay between skills for smart rotation (not spam)
                jitterWait(0.4)
                break -- only use one skill per frame cycle
            end
        end
    end)
end

------------------------------------------------------
-- RAYFIELD GUI
------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Blox Fruits Hub v1.3",
    Icon = "skull",  -- shown when minimized (Lucide icon)
    LoadingTitle = "Blox Fruits Hub",
    LoadingSubtitle = "by imoukhs",
    Theme = "Default",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BloxFruitsHub",
        FileName = "Config"
    },
    KeySystem = false,
})

------------------------------------------------------
-- TAB: FRUIT ESP
------------------------------------------------------
-- Rayfield icon names (Lucide icons): https://lucide.dev/icons
local FruitTab = Window:CreateTab("Fruit ESP", "cherry")

FruitTab:CreateSection("Devil Fruit Finder")

FruitTab:CreateToggle({
    Name = "Enable Fruit ESP",
    CurrentValue = false,
    Flag = "FruitESP",
    Callback = function(state)
        if state then
            scanForFruits()
            Connections["FruitESP"] = RunService.Heartbeat:Connect(function()
                updateFruitESP()
            end)

            -- Also watch for new fruits spawning
            -- Watch Workspace direct children for new fruit spawns
            Connections["FruitAdded"] = Workspace.ChildAdded:Connect(function(obj)
                if obj.Name:match("Fruit$") then
                    task.wait(0.5)
                    if isActualFruit(obj) then
                        createFruitBillboard(obj)
                        pcall(function()
                            game:GetService("StarterGui"):SetCore("SendNotification", {
                                Title = "FRUIT SPAWNED!",
                                Text = obj.Name .. " appeared!",
                                Duration = 10,
                            })
                        end)
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

FruitTab:CreateButton({
    Name = "Teleport to Nearest Fruit",
    Callback = function()
        local myHRP = getHRP()
        if not myHRP then return end
        local nearestFruit, nearestDist = nil, math.huge
        for obj, _ in pairs(FruitESPObjects) do
            if obj.Parent then
                local part = obj:FindFirstChildWhichIsA("BasePart") or obj.PrimaryPart
                if part then
                    local d = (part.Position - myHRP.Position).Magnitude
                    if d < nearestDist then
                        nearestFruit = part
                        nearestDist = d
                    end
                end
            end
        end
        if nearestFruit then
            teleportTo(CFrame.new(nearestFruit.Position))
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Teleported!",
                    Text = "Moved to fruit " .. math.floor(nearestDist) .. "m away",
                    Duration = 3,
                })
            end)
        else
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "No Fruit",
                    Text = "No fruits detected in this server",
                    Duration = 3,
                })
            end)
        end
    end,
})

FruitTab:CreateLabel("Gold markers show fruit name + distance through walls")
FruitTab:CreateLabel("Alerts you when a new fruit spawns!")

------------------------------------------------------
-- TAB: PLAYER ESP
------------------------------------------------------
local PlayerTab = Window:CreateTab("Player ESP", "users")

PlayerTab:CreateSection("Player Tracker")

PlayerTab:CreateToggle({
    Name = "Enable Player ESP",
    CurrentValue = false,
    Flag = "PlayerESP",
    Callback = function(state)
        if state then
            for _, player in pairs(Players:GetPlayers()) do createPlayerBillboard(player) end
            Connections["PlayerESP"] = RunService.Heartbeat:Connect(function()
                updatePlayerESP()
            end)
            Connections["PlayerJoin"] = Players.PlayerAdded:Connect(function(p)
                p.CharacterAdded:Connect(function()
                    task.wait(1)
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

PlayerTab:CreateLabel("Shows name, level, distance, and HP through walls")

------------------------------------------------------
-- TAB: TELEPORT
------------------------------------------------------
local TPTab = Window:CreateTab("Teleport", "map-pin")

-- Sea 1
TPTab:CreateSection("Sea 1")
for _, island in ipairs(Islands) do
    if island.sea == 1 then
        TPTab:CreateButton({
            Name = island.name,
            Callback = function()
                teleportTo(island.pos)
            end,
        })
    end
end

-- Sea 2
TPTab:CreateSection("Sea 2")
for _, island in ipairs(Islands) do
    if island.sea == 2 then
        TPTab:CreateButton({
            Name = island.name,
            Callback = function()
                teleportTo(island.pos)
            end,
        })
    end
end

-- Sea 3
TPTab:CreateSection("Sea 3")
for _, island in ipairs(Islands) do
    if island.sea == 3 then
        TPTab:CreateButton({
            Name = island.name,
            Callback = function()
                teleportTo(island.pos)
            end,
        })
    end
end

------------------------------------------------------
-- AUTO FARM DATA (Sea 1 focus, others included)
------------------------------------------------------

-- Quest NPCs and their mobs per island
-- TODO: These are common Sea 1 setups. Use DEX Explorer to verify exact NPC names.
local QuestData = {
    -- questId format confirmed via SimpleSpy: "StartQuest", questId, 1
    -- Quest IDs with TODO markers are estimated — capture with SimpleSpy to confirm
    -- Sea 1
    {level = {1, 10},     island = "Starter Island",    questId = "BanditQuest1",       mobName = "Bandit",            mobArea = CFrame.new(1093, 16, 1310)},
    {level = {11, 20},    island = "Jungle",             questId = "MonkeyQuest1",       mobName = "Monkey",            mobArea = CFrame.new(-1613, 37, 152)},
    {level = {21, 30},    island = "Jungle",             questId = "GorillaQuest1",      mobName = "Gorilla",           mobArea = CFrame.new(-1613, 37, 152)},  -- confirmed via DEX
    {level = {31, 60},    island = "Pirate Village",     questId = "PirateQuest1",       mobName = "Pirate",            mobArea = CFrame.new(-1152, 5, 3826)},  -- TODO: confirm questId
    {level = {61, 75},    island = "Desert",             questId = "DesertBanditQuest1", mobName = "Desert Bandit",     mobArea = CFrame.new(903, 20, 4393)},   -- TODO
    {level = {76, 90},    island = "Desert",             questId = "DesertOfficerQuest1",mobName = "Desert Officer",    mobArea = CFrame.new(903, 20, 4393)},   -- TODO
    {level = {91, 120},   island = "Frozen Village",     questId = "SnowBanditQuest1",   mobName = "Snow Bandit",       mobArea = CFrame.new(1510, 88, -5765)}, -- TODO
    {level = {121, 150},  island = "Marine Fortress",    questId = "MarineQuest1",       mobName = "Marine",            mobArea = CFrame.new(-4851, 25, 4332)}, -- TODO
    {level = {151, 175},  island = "Skylands",           questId = "SkyBanditQuest1",    mobName = "Sky Bandit",        mobArea = CFrame.new(-4851, 800, -2561)},-- TODO
    {level = {176, 200},  island = "Skylands",           questId = "DarkMasterQuest1",   mobName = "Dark Master",       mobArea = CFrame.new(-4851, 800, -2561)},-- TODO
    {level = {201, 250},  island = "Prison",             questId = "PrisonerQuest1",     mobName = "Prisoner",          mobArea = CFrame.new(4875, 6, 735)},    -- TODO
    {level = {251, 300},  island = "Colosseum",          questId = "GladiatorQuest1",    mobName = "Gladiator",         mobArea = CFrame.new(-1428, 8, -2867)}, -- TODO
    {level = {301, 350},  island = "Magma Village",      questId = "MilitaryQuest1",     mobName = "Military Soldier",  mobArea = CFrame.new(-5312, 12, 8531)}, -- TODO
    {level = {351, 375},  island = "Magma Village",      questId = "MagmaQuest1",        mobName = "Magma Ninja",       mobArea = CFrame.new(-5312, 12, 8531)}, -- TODO
    {level = {376, 450},  island = "Underwater City",    questId = "FishmanQuest1",      mobName = "Fishman",           mobArea = CFrame.new(3856, -2, 1174)},  -- TODO
    {level = {451, 525},  island = "Fountain City",      questId = "GalleyQuest1",       mobName = "Galley Pirate",     mobArea = CFrame.new(5259, 40, 4711)},  -- TODO
    {level = {526, 625},  island = "Fountain City",      questId = "GalleyCaptainQuest1",mobName = "Galley Captain",    mobArea = CFrame.new(5259, 40, 4711)},  -- TODO
    -- Sea 2
    {level = {700, 850},  island = "Kingdom of Rose",    questId = "SwanQuest1",         mobName = "Swan Pirate",       mobArea = CFrame.new(-2247, 73, -1671)},
    {level = {851, 975},  island = "Green Zone",         questId = "ZombieQuest1",       mobName = "Zombie",            mobArea = CFrame.new(-2448, 8, -3208)},
    {level = {976, 1100}, island = "Graveyard",          questId = "VampireQuest1",      mobName = "Vampire",           mobArea = CFrame.new(-5434, 12, -793)},
    {level = {1100,1250}, island = "Snow Mountain",      questId = "SnowTrooperQuest1",  mobName = "Snow Trooper",      mobArea = CFrame.new(609, 400, -5258)},
    {level = {1250,1425}, island = "Hot and Cold",       questId = "MagmaNinjaQuest1",   mobName = "Magma Ninja",       mobArea = CFrame.new(-6224, 16, -4902)},
    {level = {1425,1500}, island = "Ice Castle",         questId = "IceVikingQuest1",    mobName = "Ice Viking",        mobArea = CFrame.new(6170, 290, -6734)},
    -- Sea 3
    {level = {1500,1625}, island = "Port Town",          questId = "MillionaireQuest1",  mobName = "Pirate Millionaire", mobArea = CFrame.new(-290, 14, 5321)},
    {level = {1625,1800}, island = "Hydra Island",       questId = "DragonCrewQuest1",   mobName = "Dragon Crew",       mobArea = CFrame.new(-4459, 200, -5726)},
    {level = {1800,1975}, island = "Great Tree",         questId = "JunglePirateQuest1", mobName = "Jungle Pirate",     mobArea = CFrame.new(2164, -15, -966)},
    {level = {1975,2075}, island = "Floating Turtle",    questId = "CommodoreQuest1",    mobName = "Marine Commodore",  mobArea = CFrame.new(-12681, 380, -7504)},
    {level = {2075,2450}, island = "Haunted Castle",     questId = "CursedCaptainQuest1",mobName = "Cursed Captain",    mobArea = CFrame.new(-9499, 150, 5765)},
}

local FarmConfig = {
    Enabled = false,
    CurrentQuest = nil,
    KillCount = 0,
    Status = "Idle",
}

local function getPlayerLevel()
    local level = 1
    pcall(function()
        -- Search everywhere the level could be stored
        -- 1. leaderstats
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls then
            local lvl = ls:FindFirstChild("Level") or ls:FindFirstChild("Lvl")
            if lvl then level = lvl.Value; return end
        end
        -- 2. Data folder
        local data = LocalPlayer:FindFirstChild("Data")
        if data then
            local lvl = data:FindFirstChild("Level")
            if lvl then level = lvl.Value; return end
        end
        -- 3. PlayerGui (BF shows level in HUD)
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if gui then
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextLabel") then
                    -- Match patterns like "Lv. 15" or "Level 15" or "[15]"
                    local lvlMatch = obj.Text:match("Lv%.%s*(%d+)") or obj.Text:match("Level%s*(%d+)")
                    if lvlMatch then
                        level = tonumber(lvlMatch)
                        return
                    end
                end
            end
        end
        -- 4. Scan all ValueBase objects in player
        for _, obj in pairs(LocalPlayer:GetDescendants()) do
            if obj:IsA("IntValue") or obj:IsA("NumberValue") then
                if obj.Name == "Level" or obj.Name == "Lvl" or obj.Name == "PlayerLevel" then
                    level = obj.Value
                    return
                end
            end
        end
    end)
    return level
end

local function getBestQuest()
    local level = getPlayerLevel()
    local best = nil
    for _, quest in ipairs(QuestData) do
        if level >= quest.level[1] and level <= quest.level[2] then
            best = quest
        end
    end
    -- If overleveled, use highest available
    if not best then
        for i = #QuestData, 1, -1 do
            if getPlayerLevel() >= QuestData[i].level[1] then
                best = QuestData[i]
                break
            end
        end
    end
    return best
end

local function findQuestNPC(npcName)
    -- Search in Workspace.NPCs folder first (confirmed via DEX)
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if npcsFolder then
        for _, obj in pairs(npcsFolder:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == npcName then
                return obj
            end
        end
    end
    -- Fallback: search entire workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == npcName then
            return obj
        end
    end
    return nil
end

local function findMob(mobName, range)
    local hrp = getHRP()
    if not hrp then return nil end
    local nearest, bestDist = nil, range or 300
    -- Search in Workspace.Enemies folder (confirmed via DEX)
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil end
    for _, obj in pairs(enemiesFolder:GetChildren()) do
        if obj:IsA("Model") and obj.Name == mobName then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
            if hum and hum.Health > 0 and root then
                local d = (root.Position - hrp.Position).Magnitude
                if d < bestDist then
                    nearest = obj
                    bestDist = d
                end
            end
        end
    end
    return nearest, bestDist
end

local function hasActiveQuest()
    -- Check if player has an active quest by looking for quest HUD
    -- Confirmed from screenshot: HUD shows "QUEST\nDefeat X ..."
    local hasQuest = false
    pcall(function()
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if gui then
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextLabel") then
                    local text = obj.Text:lower()
                    if text:find("defeat") or text:find("quest") and (text:find("%d+/%d+") or text:find("reward")) then
                        hasQuest = true
                        return
                    end
                end
            end
        end
    end)
    return hasQuest
end

local function getQuestProgress()
    -- Try to read "Defeat X Gorillas (3/8)" type text
    local current, total = 0, 0
    pcall(function()
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if gui then
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextLabel") then
                    local c, t = obj.Text:match("%((%d+)/(%d+)%)")
                    if c and t then
                        current = tonumber(c)
                        total = tonumber(t)
                        return
                    end
                end
            end
        end
    end)
    return current, total
end

local function interactNPC(npcModel)
    if not npcModel then return end
    local root = npcModel:FindFirstChild("HumanoidRootPart") or npcModel:FindFirstChild("Head") or npcModel:FindFirstChild("Torso")
    if not root then return end

    -- Teleport close to NPC
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = CFrame.new(root.Position + Vector3.new(0, 0, 3), root.Position)
    end
    jitterWait(0.5)

    -- Try interacting via ProximityPrompt
    pcall(function()
        for _, prompt in pairs(npcModel:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                fireproximityprompt(prompt)
                return
            end
        end
    end)

    -- Try ClickDetector
    pcall(function()
        for _, cd in pairs(npcModel:GetDescendants()) do
            if cd:IsA("ClickDetector") then
                fireclickdetector(cd)
                return
            end
        end
    end)

    -- Try Dialog
    pcall(function()
        for _, dialog in pairs(npcModel:GetDescendants()) do
            if dialog:IsA("Dialog") then
                dialog:SignalDialogChoiceSelected(LocalPlayer, dialog.DialogChoices[1])
            end
        end
    end)

    jitterWait(0.5)
end

local function attackMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
    if not root then return end
    local hrp = getHRP()
    if not hrp then return end

    -- Medium aggression: TP close (within 5 studs) then attack
    local dist = (root.Position - hrp.Position).Magnitude
    if dist > 5 then
        hrp.CFrame = CFrame.new(root.Position + Vector3.new(0, 0, 3), root.Position)
    end
    jitterWait(0.05)

    -- Attack with equipped tool
    pcall(function()
        local tool = getCharacter():FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
    end)

    -- Also try mouse click simulation
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

local function acceptQuestFromNPC(quest)
    -- Method 1: Find and interact with quest NPC directly
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if not npcsFolder then return false end

    -- Look for NPCs near the quest mob area that have a quest dialog
    local hrp = getHRP()
    if not hrp then return false end

    -- Teleport to the quest area first
    teleportTo(quest.mobArea)
    jitterWait(1.5)

    -- Find closest NPC with interaction (ProximityPrompt, ClickDetector, or Dialog)
    local bestNPC, bestDist = nil, 200
    for _, obj in pairs(npcsFolder:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
            if root then
                local d = (root.Position - getHRP().Position).Magnitude
                -- Look for NPCs that have quest-giving capability
                local hasPrompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
                    or obj:FindFirstChildWhichIsA("ClickDetector", true)
                    or obj:FindFirstChildWhichIsA("Dialog", true)
                if d < bestDist and hasPrompt then
                    bestNPC = obj
                    bestDist = d
                end
            end
        end
    end

    -- Also search workspace root for NPCs
    if not bestNPC then
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
                if root then
                    local d = (root.Position - getHRP().Position).Magnitude
                    if d < bestDist then
                        bestNPC = obj
                        bestDist = d
                    end
                end
            end
        end
    end

    if bestNPC then
        interactNPC(bestNPC)
        jitterWait(1)

        -- Click any accept/ok buttons in the quest dialog GUI
        pcall(function()
            local gui = LocalPlayer:FindFirstChild("PlayerGui")
            if gui then
                for _ = 1, 3 do -- try a few times
                    for _, btn in pairs(gui:GetDescendants()) do
                        if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                            local text = btn:IsA("TextButton") and btn.Text:lower() or ""
                            if text:find("accept") or text:find("start") or text:find("ok") or text:find("yes") then
                                pcall(function() fireclick(btn) end)
                                pcall(function() btn.MouseButton1Click:Fire() end)
                                jitterWait(0.3)
                            end
                        end
                    end
                    jitterWait(0.5)
                end
            end
        end)
        return true
    end
    return false
end

local function runAutoFarm()
    while FarmConfig.Enabled and isAlive(LocalPlayer) do
        local quest = getBestQuest()
        if not quest then
            FarmConfig.Status = "No quest for your level"
            jitterWait(3)
            continue
        end

        FarmConfig.CurrentQuest = quest

        -- Step 1: Accept quest if none active
        if not hasActiveQuest() then
            FarmConfig.Status = "Getting quest at " .. quest.island
            acceptQuestFromNPC(quest)
            jitterWait(1)
            -- If still no quest after trying, skip this cycle
            if not hasActiveQuest() then
                FarmConfig.Status = "Couldn't accept quest, retrying..."
                jitterWait(2)
                continue
            end
        end

        -- Step 2: Check quest progress
        local current, total = getQuestProgress()
        FarmConfig.Status = string.format("Farming %s (%d/%d)", quest.mobName, current, total)

        -- Step 3: If quest complete (current >= total), go turn it in
        if total > 0 and current >= total then
            FarmConfig.Status = "Quest done! Turning in..."
            acceptQuestFromNPC(quest) -- interact with NPC again to turn in + get new quest
            jitterWait(2)
            continue
        end

        -- Step 4: Find and kill mobs
        local mob, dist = findMob(quest.mobName, 500)
        if mob then
            FarmConfig.Status = string.format("Attacking %s (%dm) [%d/%d]", quest.mobName, math.floor(dist), current, total)
            attackMob(mob)
            jitterWait(0.3)
        else
            -- No mobs nearby, teleport to mob area
            FarmConfig.Status = "Moving to " .. quest.island
            teleportTo(quest.mobArea)
            jitterWait(2)
        end

        jitterWait(0.2)
    end
    FarmConfig.Status = "Stopped"
end

------------------------------------------------------
-- FRUIT SNIPER (Auto Server Hop)
------------------------------------------------------
local SniperConfig = {
    Enabled = false,
    HopCount = 0,
    Status = "Idle",
    TargetFruits = {}, -- list of fruit names to hunt
}

local function serverHop()
    local success = false
    pcall(function()
        local servers = HttpService:JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        )
        if servers and servers.data then
            -- Shuffle to avoid always joining the same servers
            for i = #servers.data, 2, -1 do
                local j = math.random(1, i)
                servers.data[i], servers.data[j] = servers.data[j], servers.data[i]
            end
            for _, server in pairs(servers.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    success = true
                    break
                end
            end
        end
    end)
    return success
end

local function runFruitSniper()
    while SniperConfig.Enabled do
        SniperConfig.Status = "Scanning server..."
        jitterWait(3) -- wait for world to load

        -- Scan for fruits
        local found = scanForFruits()
        local targetFound = false

        if #found > 0 then
            for _, fruit in ipairs(found) do
                local name = fruit.Name:lower()
                -- Check if this is a target fruit
                if #SniperConfig.TargetFruits == 0 then
                    -- No specific target = any fruit is good
                    targetFound = true
                else
                    for _, target in ipairs(SniperConfig.TargetFruits) do
                        if name:find(target:lower()) then
                            targetFound = true
                            break
                        end
                    end
                end
                if targetFound then break end
            end
        end

        if targetFound then
            SniperConfig.Status = "FRUIT FOUND! Teleporting..."
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "FRUIT FOUND!",
                    Text = found[1].Name .. " detected! Go grab it!",
                    Duration = 15,
                })
            end)
            -- Teleport to the fruit
            local part = found[1]:FindFirstChildWhichIsA("BasePart") or found[1].PrimaryPart
            if part then
                teleportTo(CFrame.new(part.Position))
            end
            SniperConfig.Enabled = false -- stop sniping, fruit found
            break
        else
            SniperConfig.HopCount = SniperConfig.HopCount + 1
            SniperConfig.Status = "No fruit. Hopping... (#" .. SniperConfig.HopCount .. ")"
            jitterWait(2)
            serverHop()
            jitterWait(8) -- wait for server transition
        end
    end
    if not SniperConfig.Enabled then
        SniperConfig.Status = "Stopped"
    end
end

------------------------------------------------------
-- TAB: AUTO FARM
------------------------------------------------------
local FarmTab = Window:CreateTab("Auto Farm", "swords")

local detectedLevel = getPlayerLevel()
FarmTab:CreateSection("Auto Farm (Detected Level: " .. detectedLevel .. ")")

local bestQuest = getBestQuest()
if bestQuest then
    FarmTab:CreateLabel("Best quest: " .. bestQuest.island .. " (" .. bestQuest.mobName .. ")")
else
    FarmTab:CreateLabel("No quest found for level " .. detectedLevel .. " — use Refresh Quest")
end

FarmTab:CreateToggle({
    Name = "Enable Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(state)
        FarmConfig.Enabled = state
        if state then
            task.spawn(runAutoFarm)
        end
    end,
})

FarmTab:CreateLabel("Auto-accepts quest, TPs to mobs, kills, repeats")

FarmTab:CreateSection("Settings")

FarmTab:CreateButton({
    Name = "Equip Best Weapon",
    Callback = function()
        pcall(function()
            local backpack = LocalPlayer.Backpack
            local char = getCharacter()
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    tool.Parent = char
                    break
                end
            end
        end)
    end,
})

FarmTab:CreateButton({
    Name = "Refresh Quest (detect level change)",
    Callback = function()
        local lvl = getPlayerLevel()
        local q = getBestQuest()
        if q then
            FarmConfig.CurrentQuest = q
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Quest Updated",
                    Text = "Lv." .. lvl .. " → " .. q.island .. " (" .. q.mobName .. ")",
                    Duration = 4,
                })
            end)
        else
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Level Detection",
                    Text = "Detected level: " .. lvl .. ". Use manual override if wrong.",
                    Duration = 4,
                })
            end)
        end
    end,
})

FarmTab:CreateSection("Manual Level Override")

FarmTab:CreateInput({
    Name = "Enter your level",
    CurrentValue = tostring(detectedLevel),
    PlaceholderText = "Type your level (e.g. 15)",
    RemoveTextAfterFocusLost = false,
    Flag = "ManualLevel",
    Callback = function(text)
        local val = tonumber(text)
        if not val or val < 1 or val > 2550 then
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Invalid Level",
                    Text = "Enter a number between 1 and 2550",
                    Duration = 3,
                })
            end)
            return
        end
        getPlayerLevel = function() return val end
        local q = getBestQuest()
        if q then
            FarmConfig.CurrentQuest = q
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Level Set",
                    Text = "Lv." .. val .. " → " .. q.island .. " (" .. q.mobName .. ")",
                    Duration = 4,
                })
            end)
        end
    end,
})

FarmTab:CreateLabel("Use slider above if quest doesn't match your actual level")

------------------------------------------------------
-- TAB: FRUIT SNIPER
------------------------------------------------------
local SniperTab = Window:CreateTab("Fruit Sniper", "target")

SniperTab:CreateSection("Auto Server Hop Fruit Hunter")

SniperTab:CreateToggle({
    Name = "Enable Fruit Sniper",
    CurrentValue = false,
    Flag = "FruitSniper",
    Callback = function(state)
        SniperConfig.Enabled = state
        SniperConfig.HopCount = 0
        if state then
            task.spawn(runFruitSniper)
        end
    end,
})

SniperTab:CreateDropdown({
    Name = "Target Fruit (blank = any)",
    Options = {"Any Fruit", "Leopard", "Dragon", "Dough", "Venom", "Shadow", "Rumble", "Buddha", "Phoenix", "Magma", "Light", "Ice", "Flame"},
    CurrentOption = {"Any Fruit"},
    MultipleOptions = true,
    Flag = "TargetFruits",
    Callback = function(options)
        SniperConfig.TargetFruits = {}
        for _, opt in ipairs(options) do
            if opt ~= "Any Fruit" then
                table.insert(SniperConfig.TargetFruits, opt)
            end
        end
    end,
})

SniperTab:CreateLabel("Hops servers scanning for fruit spawns")
SniperTab:CreateLabel("Stops + alerts when target fruit found")
SniperTab:CreateLabel("Teleports you to the fruit automatically")

------------------------------------------------------
-- TAB: COMBAT (Aimbot + Auto Skills)
------------------------------------------------------
local CombatTab = Window:CreateTab("Combat", "crosshair")

CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "Aimbot",
    Callback = function(state)
        AimbotConfig.Enabled = state
        if state then
            runAimbot()
        else
            if Connections["Aimbot"] then Connections["Aimbot"]:Disconnect(); Connections["Aimbot"] = nil end
        end
    end,
})

CombatTab:CreateSlider({
    Name = "Aimbot Range",
    Range = {20, 200},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = 100,
    Flag = "AimbotRange",
    Callback = function(val)
        AimbotConfig.Range = val
    end,
})

CombatTab:CreateToggle({
    Name = "Target Players",
    CurrentValue = true,
    Flag = "AimbotPlayers",
    Callback = function(state)
        AimbotConfig.TargetPlayers = state
    end,
})

CombatTab:CreateToggle({
    Name = "Target NPCs/Enemies",
    CurrentValue = true,
    Flag = "AimbotNPCs",
    Callback = function(state)
        AimbotConfig.TargetNPCs = state
    end,
})

CombatTab:CreateLabel("Locks onto nearest target, rotates character + camera")
CombatTab:CreateLabel("Client-side only — undetectable by server")

CombatTab:CreateSection("Auto Skills (Smart Rotation)")

CombatTab:CreateToggle({
    Name = "Enable Auto Skills",
    CurrentValue = false,
    Flag = "AutoSkills",
    Callback = function(state)
        AutoSkillConfig.Enabled = state
        if state then
            runAutoSkills()
        else
            if Connections["AutoSkills"] then Connections["AutoSkills"]:Disconnect(); Connections["AutoSkills"] = nil end
        end
    end,
})

CombatTab:CreateLabel("Uses Z → X → C → V → F in order when enemy is near")
CombatTab:CreateLabel("Respects cooldowns, only fires one skill per cycle")
CombatTab:CreateLabel("Only activates when a target is within 30 studs")

------------------------------------------------------
-- TAB: EXTRAS
------------------------------------------------------
local ExtrasTab = Window:CreateTab("Extras", "settings")

ExtrasTab:CreateSection("Utilities")

ExtrasTab:CreateButton({
    Name = "Print My Position",
    Callback = function()
        local hrp = getHRP()
        if hrp then
            local pos = hrp.Position
            local str = string.format("CFrame.new(%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z)
            print("[BF Hub] " .. str)
            pcall(function()
                if setclipboard then setclipboard(str)
                elseif toclipboard then toclipboard(str) end
            end)
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Position Copied",
                    Text = str,
                    Duration = 3,
                })
            end)
        end
    end,
})

ExtrasTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
        end)
    end,
})

ExtrasTab:CreateButton({
    Name = "Server Hop (find new fruit)",
    Callback = function()
        pcall(function()
            local servers = HttpService:JSONDecode(
                game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
            )
            for _, server in pairs(servers.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    break
                end
            end
        end)
    end,
})

ExtrasTab:CreateSection("Anti-Detection")

ExtrasTab:CreateToggle({
    Name = "Anti-Idle",
    CurrentValue = true,
    Flag = "AntiIdle",
    Callback = function(state)
        if state then
            task.spawn(function()
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
            end)
        end
    end,
})

ExtrasTab:CreateSection("Coming Soon")
ExtrasTab:CreateLabel("v1.3: Auto Raid")
ExtrasTab:CreateLabel("v1.4: Stat Auto-Assign")

------------------------------------------------------
-- RENAME MINIMIZED BUTTON
------------------------------------------------------
-- Rayfield shows "Show Rayfield" when minimized — override it
task.spawn(function()
    task.wait(2) -- wait for Rayfield to fully render
    pcall(function()
        local coreGui = game:GetService("CoreGui")
        for _, gui in pairs(coreGui:GetDescendants()) do
            if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                if gui.Text == "Show Rayfield" then
                    gui.Text = "BF Hub"
                end
            end
        end
        -- Also check gethui
        if gethui then
            for _, gui in pairs(gethui():GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Text == "Show Rayfield" then
                    gui.Text = "BF Hub"
                end
            end
        end
    end)
end)

------------------------------------------------------
-- CLEANUP
------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
        ESPObjects[player] = nil
    end
end)

print("================================================")
print("  Blox Fruits Hub v1.3 Loaded")
print("  Tabs: Fruit ESP | Player ESP | Teleport |")
print("        Farm | Sniper | Combat | Extras")
print("================================================")
