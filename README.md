# Risk of Rain 2 — Roblox Edition

A faithful recreation of **Risk of Rain 2** built entirely in Roblox Lua (Luau).
Implements the core loop: land, loot, fight, activate the teleporter, repeat — with
difficulty that scales with real-world time.

---

## Feature Overview

| System | Status |
|---|---|
| Survivor characters (Commando, Huntress, Mercenary, Engineer, Artificer) | ✅ |
| 40+ items across Common / Uncommon / Legendary / Boss / Lunar tiers | ✅ |
| Enemy spawning with Director credit system | ✅ |
| Teleporter event (charge → boss → completion) | ✅ |
| Time-based difficulty scaling (Drizzle / Rainstorm / Monsoon) | ✅ |
| Run stats, kill tracker, item history | ✅ |
| Full HUD (health, shield, skills, item bar, difficulty timer) | ✅ |
| Multiplayer-ready (server-authoritative via RemoteEvents) | ✅ |

---

## Project Layout

```
src/
├── ReplicatedStorage/
│   ├── Modules/
│   │   ├── GameConstants.lua      -- shared constants & tuning knobs
│   │   ├── DifficultyManager.lua  -- time-scaled difficulty coefficients
│   │   ├── ItemRegistry.lua       -- all item definitions & stacking logic
│   │   ├── CharacterStats.lua     -- base + item-modified stat calculator
│   │   └── Util.lua               -- math helpers, random, lerp, etc.
│   ├── Characters/
│   │   ├── Commando.lua
│   │   ├── Huntress.lua
│   │   ├── Mercenary.lua
│   │   ├── Engineer.lua
│   │   └── Artificer.lua
│   └── Enemies/
│       ├── Lemurian.lua
│       ├── Wisp.lua
│       ├── GolemStone.lua
│       ├── Imp.lua
│       └── BeetleGuard.lua
├── ServerScriptService/
│   └── Services/
│       ├── GameManager.server.lua      -- orchestrates run state
│       ├── DirectorService.server.lua  -- enemy spawn director
│       ├── ItemService.server.lua      -- item drops & pickup grants
│       ├── TeleporterService.server.lua
│       └── CombatService.server.lua    -- damage, procs, death
├── StarterPlayerScripts/
│   ├── CharacterController.client.lua  -- input, skill activation
│   └── CameraController.client.lua     -- third-person over-shoulder
└── StarterGui/
    └── Hud/
        ├── HudController.client.lua
        └── ScreenGui.lua               -- layout definitions
```

---

## Running in Roblox Studio

1. Open **Roblox Studio** and create a new place.
2. Copy each `*.lua` file into the matching Roblox service using the path above.
3. Rename files: drop the `.server` / `.client` suffix — Roblox uses the Instance
   class (Script vs LocalScript vs ModuleScript) to determine context.
4. Place `ReplicatedStorage/Modules/*` as **ModuleScript** instances.
5. Place `Characters/*` and `Enemies/*` as **ModuleScript** instances.
6. Play-test in Studio — all systems initialise automatically.

---

## Design Philosophy

* **Server-authoritative**: all damage, stat changes, and item grants happen on the
  server; clients send intent via `RemoteFunction` / `RemoteEvent`.
* **Data-driven items**: every item is a plain Lua table; no subclassing required.
* **Difficulty as a function of time**: `DifficultyManager` exposes a single
  `GetCoefficient(t)` call used everywhere scaling is needed.
