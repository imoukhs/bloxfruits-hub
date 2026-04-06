--[[
    Dev Tools Loader
    Loads SimpleSpy + Infinite Yield + DEX Explorer
    Paste into Delta before scripting any game
]]

-- SimpleSpy (Remote Spy)
-- Shows all RemoteEvent/RemoteFunction calls in a GUI
-- Use this to find exact remote names for auto-farm, stats, quests
task.spawn(function()
    loadstring(game:HttpGet("https://github.com/infyiff/backup/blob/main/SimpleSpyV3/main.lua?raw=true"))()
    print("[Dev Tools] SimpleSpy loaded - check the GUI at bottom of screen")
end)

task.wait(2)

-- Infinite Yield (Admin Commands)
-- Type commands like: ;esp, ;tp me [player], ;speed 50, ;fly, ;noclip
-- Type ;cmds to see all commands
task.spawn(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    print("[Dev Tools] Infinite Yield loaded - press ; to open command bar")
end)

task.wait(2)

-- DEX Explorer (Game Explorer)
-- Browse Workspace, ReplicatedStorage, etc. like Roblox Studio
-- Find object names, properties, hierarchy
task.spawn(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
    print("[Dev Tools] DEX Explorer loaded - check the explorer GUI")
end)

print("================================================")
print("  All Dev Tools Loaded!")
print("  SimpleSpy: Watch remotes at bottom panel")
print("  Infinite Yield: Press ; for commands")
print("  DEX: Browse game objects in explorer")
print("================================================")
