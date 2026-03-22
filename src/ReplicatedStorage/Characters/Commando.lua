-- Characters/Commando.lua
-- Skill definitions for the Commando survivor.
-- Each skill returns an action table consumed by CombatService.

local Commando = {}
Commando.name        = "Commando"
Commando.description = "The Commando is a well-rounded survivor with reliable damage output."
Commando.unlockCondition = nil  -- starter character, always unlocked

-- ── Passive ───────────────────────────────────────────────────────────────────
Commando.passive = {
    name        = "Commando's Tactics",
    description = "Commando rolls have reduced cooldown on kill.",
}

-- ── Skills ────────────────────────────────────────────────────────────────────

-- M1 – Double Tap
Commando.skills = {}

Commando.skills.primary = {
    name        = "Double Tap",
    description = "Fire twice for 2×100% damage.",
    cooldown    = 0,       -- no cooldown, fires on click
    stockMax    = 0,
    isAutomatic = false,
    procCoefficient = 1.0,
    -- Returns a list of hit-scan or projectile definitions the server will resolve
    Activate = function(owner, targetDirection)
        return {
            type    = "hitscan",
            hits    = 2,
            damage  = 1.0,   -- multiplier of owner base damage
            range   = 200,
            spread  = 0.02,
            direction = targetDirection,
            owner   = owner,
        }
    end,
}

-- M2 – Phase Round (piercing)
Commando.skills.secondary = {
    name        = "Phase Round",
    description = "Fire a piercing bullet for 300% damage.",
    cooldown    = 3,
    stockMax    = 1,
    procCoefficient = 1.0,
    Activate = function(owner, targetDirection)
        return {
            type      = "hitscan",
            hits      = 1,
            damage    = 3.0,
            range     = 300,
            piercing  = true,
            direction = targetDirection,
            owner     = owner,
        }
    end,
}

-- Utility – Roll (i-frames dodge)
Commando.skills.utility = {
    name        = "Roll",
    description = "Roll in the input direction, granting brief invincibility.",
    cooldown    = 4,
    stockMax    = 2,
    iFrameDuration = 0.35,  -- seconds of invincibility
    procCoefficient = 0,
    Activate = function(owner, inputDir)
        return {
            type      = "dash",
            direction = inputDir,
            speed     = 35,
            duration  = 0.35,
            iFrames   = true,
            owner     = owner,
        }
    end,
}

-- Special – Suppressive Fire (barrage)
Commando.skills.special = {
    name        = "Suppressive Fire",
    description = "Unload a barrage of 12 bullets for 12×100% damage.",
    cooldown    = 7,
    stockMax    = 1,
    isChannel   = false,
    procCoefficient = 1.0,
    Activate = function(owner, targetDirection)
        local hits = {}
        for i = 1, 12 do
            hits[i] = {
                type      = "hitscan",
                hits      = 1,
                damage    = 1.0,
                range     = 200,
                spread    = 0.05,
                direction = targetDirection,
                owner     = owner,
                delay     = (i - 1) * 0.05,  -- stagger per bullet
            }
        end
        return { type = "barrage", shots = hits }
    end,
}

return Commando
