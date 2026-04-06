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
    -- Actual spawned/dropped fruits in Blox Fruits:
    -- 1. Are Models without a Humanoid (NPCs/dealers HAVE humanoids)
    -- 2. Usually have a Handle or MeshPart inside
    -- 3. Do NOT have "Dealer" or "Shop" in name or parent name
    -- 4. Are relatively small (not full character-sized)

    if not obj:IsA("Model") then return false end

    -- REJECT: Has a Humanoid = it's an NPC, not a fruit
    if obj:FindFirstChildOfClass("Humanoid") then return false end

    -- REJECT: Is a player's item
    for _, p in pairs(Players:GetPlayers()) do
        if obj:IsDescendantOf(p.Character) or obj:IsDescendantOf(p) then
            return false
        end
    end

    -- REJECT: Name contains dealer/shop/npc keywords
    local name = obj.Name:lower()
    local parentName = obj.Parent and obj.Parent.Name:lower() or ""
    if name:find("dealer") or name:find("shop") or name:find("npc")
        or name:find("vendor") or name:find("merchant") or name:find("cousin")
        or parentName:find("npc") or parentName:find("shop") or parentName:find("dealer") then
        return false
    end

    -- REJECT: If parent is a character-like model (NPC container)
    if obj.Parent and obj.Parent:FindFirstChildOfClass("Humanoid") then
        return false
    end

    -- ACCEPT: Must have "Fruit" in name
    if not (name:find("fruit")) then return false end

    -- ACCEPT: Should have a physical part (mesh/handle) but no humanoid
    local hasPart = obj:FindFirstChildWhichIsA("BasePart") or obj:FindFirstChildWhichIsA("MeshPart")
    if not hasPart then return false end

    return true
end

local function scanForFruits()
    local found = {}

    -- Method 1: Scan entire workspace for fruit models
    for _, obj in pairs(Workspace:GetDescendants()) do
        if isActualFruit(obj) then
            table.insert(found, obj)
            createFruitBillboard(obj)
        end
    end

    -- Method 2: Check known fruit spawn containers
    pcall(function()
        local containers = {"Fruits", "DroppedItems", "Spawned", "GroundItems"}
        for _, containerName in ipairs(containers) do
            local folder = Workspace:FindFirstChild(containerName)
            if folder then
                for _, obj in pairs(folder:GetChildren()) do
                    if obj:IsA("Model") and not obj:FindFirstChildOfClass("Humanoid") then
                        table.insert(found, obj)
                        createFruitBillboard(obj)
                    end
                end
            end
        end
    end)

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

    -- Gradual TP — ~75 studs per step, 0.12s wait (faster but still safe)
    local steps = math.clamp(math.floor(dist / 75), 8, 30)
    for i = 1, steps do
        if not getHRP() then break end
        local alpha = i / steps
        local mid = startPos:Lerp(targetPos, alpha) + Vector3.new(0, 15, 0)
        getHRP().CFrame = CFrame.new(mid)
        jitterWait(0.1)
    end
    task.wait(0.2)
    local finalHRP = getHRP()
    if finalHRP then
        finalHRP.CFrame = cf + Vector3.new(0, 5, 0)
    end
end

------------------------------------------------------
-- RAYFIELD GUI
------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Blox Fruits Hub v1.1",
    Icon = 0,
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
            Connections["FruitAdded"] = Workspace.DescendantAdded:Connect(function(obj)
                if obj:IsA("Model") and obj.Name:lower():find("fruit") then
                    task.wait(0.5) -- wait for model to fully load
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
ExtrasTab:CreateLabel("v1.1: Auto Farm (mob kill + quest)")
ExtrasTab:CreateLabel("v1.2: Fruit Sniper (auto server hop)")
ExtrasTab:CreateLabel("v1.3: Auto Raid + Stats")

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
print("  Blox Fruits Hub v1.0 Loaded")
print("  Tabs: Fruit ESP | Player ESP | Teleport | Extras")
print("================================================")
