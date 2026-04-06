# Blox Fruits Hub - Roblox Script Project

## Project Overview
Roblox Lua executor script (hub GUI) for **Blox Fruits** (One Piece-inspired anime game). Built on **Rayfield UI library**. Incremental build — start with safe MVP, add features one by one.

**Repo:** https://github.com/imoukhs/bloxfruits-hub
**Owner:** imoukhs
**Current Version:** v1.0 (MVP)

## Why Blox Fruits is Safe
- Weak anticheat compared to Peroxide
- Thousands of existing scripts (Hoho Hub, Mukuro Hub, etc.) — executors blend in
- ESP and auto farm have worked for years without bans
- Server-side checks are minimal — most validation is client-trusted

## Build Phases (Incremental)
1. **MVP (v1.0):** Fruit ESP + Player ESP + Teleport to islands — GUI only, no automation
2. **v1.1:** Auto farm (mob kill + quest auto-accept)
3. **v1.2:** Fruit finder with server hop
4. **v1.3:** Auto raid, auto bounty, stat allocation
5. **v1.4:** PvP assists (auto block, skill spam)

## Files
- `BloxFruitsHub.lua` — Main hub script (Rayfield-based)
- `loader.lua` — One-liner loadstring
- `CLAUDE.md` — This file

## Blox Fruits Game Knowledge
- **Sea 1:** Levels 1-700 (Starter islands → Skylands)
- **Sea 2:** Levels 700-1500 (Kingdom of Rose → Ice Castle)
- **Sea 3:** Levels 1500-2550 (Port Town → Tiki Outpost)
- **Fruits** spawn every 60-120 min on random spots, or under trees. Stored in `Workspace` as models.
- **NPCs** are in folders under `Workspace` organized by island
- **Quests** use RemoteEvents — talk to NPC, accept, kill X mobs, return
- **Stats:** Melee, Defense, Sword, Gun, Blox Fruit — allocated via remote
- **Islands** have fixed positions — these are well-documented and stable

## Anti-Detection Notes (Blox Fruits Specific)
- Blox Fruits trusts the client heavily — teleporting is generally safe
- Auto farm is safe if you don't kill mobs faster than humanly possible (use jitterWait)
- ESP is completely client-side — zero ban risk
- Fruit ESP is safe — just reading workspace children
- Server hopping is safe — it's a built-in Roblox feature
- The main risk is speed hacks / fly hacks (we won't use these)

## Coding Rules
- Rayfield UI only
- All anti-detection rules from parent CLAUDE.md apply
- Startup delay + staggered init
- jitterWait on all automation loops
- pcall wrap all executor APIs and remote fires
