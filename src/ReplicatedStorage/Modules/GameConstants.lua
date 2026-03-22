-- GameConstants.lua
-- Central tuning table shared between server and client.

local GameConstants = {}

-- ── Difficulty ───────────────────────────────────────────────────────────────
GameConstants.DIFFICULTY = {
    DRIZZLE  = "Drizzle",
    RAINSTORM = "Rainstorm",
    MONSOON  = "Monsoon",
}

-- Base scaling: RoR2 uses ambiguityFactor + scalingFactor * sqrt(t/60)
GameConstants.SCALING = {
    ambiguityFactor = 0.7,  -- floor so the game never trivialises
    scalingFactor   = 0.3,
}

-- Difficulty multipliers applied on top of the coefficient
GameConstants.DIFFICULTY_MULT = {
    [GameConstants.DIFFICULTY.DRIZZLE]   = 0.5,
    [GameConstants.DIFFICULTY.RAINSTORM] = 1.0,
    [GameConstants.DIFFICULTY.MONSOON]   = 1.5,
}

-- ── Teleporter ───────────────────────────────────────────────────────────────
GameConstants.TELEPORTER = {
    CHARGE_TIME           = 90,  -- seconds to fully charge (all players inside)
    BOSS_HEALTH_MULT      = 4.0, -- boss HP relative to a normal enemy of same type
    CHARGE_RADIUS         = 15,  -- studs — players must stay inside to charge
    COMPLETION_HEAL_FRAC  = 0.25,-- heal 25 % max HP on stage clear
}

-- ── Director (enemy spawn budget) ────────────────────────────────────────────
GameConstants.DIRECTOR = {
    BASE_CREDITS        = 40,
    CREDIT_GAIN_PER_SEC = 1.0,   -- credits earned each second
    MAX_CREDITS         = 800,
    MAX_ENEMIES         = 40,    -- hard cap alive at once
    SPAWN_INTERVAL      = 3,     -- seconds between spawn attempts
}

-- ── Combat ───────────────────────────────────────────────────────────────────
GameConstants.COMBAT = {
    PROC_COEFFICIENT_DEFAULT = 1.0,
    CRIT_MULT                = 2.0,
    FALL_DAMAGE_FRAC         = 0.1, -- fraction of max HP per fatal fall
    REGEN_TICK_RATE          = 0.5, -- seconds between HP regen ticks
}

-- ── Items ────────────────────────────────────────────────────────────────────
GameConstants.ITEM_TIER = {
    COMMON    = "Common",
    UNCOMMON  = "Uncommon",
    LEGENDARY = "Legendary",
    BOSS      = "Boss",
    LUNAR     = "Lunar",
    VOID      = "Void",
}

GameConstants.DROP_CHANCE = {
    [GameConstants.ITEM_TIER.COMMON]    = 0.79,
    [GameConstants.ITEM_TIER.UNCOMMON]  = 0.20,
    [GameConstants.ITEM_TIER.LEGENDARY] = 0.01,
}

-- ── Players / Survivors ──────────────────────────────────────────────────────
GameConstants.SURVIVOR = {
    RESPAWN_TIME     = 30,   -- seconds (Monsoon: no respawn in solo)
    BASE_JUMP_HEIGHT = 7.5,  -- studs
    BASE_MOVE_SPEED  = 16,   -- studs/s
    SPRINT_MULT      = 1.45,
    PICKUP_RADIUS    = 4,    -- studs — auto-pickup distance
}

-- ── Stages ───────────────────────────────────────────────────────────────────
GameConstants.STAGES = {
    "Distant Roost",
    "Titanic Plains",
    "Wetland Aspect",
    "Abandoned Aqueduct",
    "Rallypoint Delta",
    "Scorched Acres",
    "Abyssal Depths",
    "Siren's Call",
    "Sky Meadow",
    "Commencement",  -- final stage
}

return GameConstants
