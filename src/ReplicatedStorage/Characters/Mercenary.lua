-- Characters/Mercenary.lua
-- Mercenary: melee brawler with invincibility frames and high combo damage.

local Mercenary = {}
Mercenary.name        = "Mercenary"
Mercenary.description = "The Mercenary is an agile swordsman who rewards aggressive play."
Mercenary.unlockCondition = "Complete the third teleporter event without dying"

Mercenary.passive = {
    name        = "Windborne",
    description = "Mercenary gains an extra jump in midair.",
    extraJumps  = 1,
}

Mercenary.skills = {}

-- M1 – Laser Sword (combo chain)
Mercenary.skills.primary = {
    name        = "Laser Sword",
    description = "3-hit melee combo for 3×130% damage.",
    cooldown    = 0,
    stockMax    = 0,
    isAutomatic = false,
    comboLength = 3,
    procCoefficient = 1.0,
    Activate = function(owner, inputDir)
        return {
            type     = "melee_combo",
            hits     = 3,
            damage   = 1.3,
            range    = 6,
            arc      = 120,  -- degrees
            direction = inputDir,
            owner    = owner,
        }
    end,
}

-- M2 – Whirlwind (aerial spinning slash)
Mercenary.skills.secondary = {
    name        = "Whirlwind",
    description = "Spin rapidly, hitting all nearby enemies for 2×200% damage. Works in the air.",
    cooldown    = 5,
    stockMax    = 1,
    resetOnKill = false,
    procCoefficient = 1.0,
    Activate = function(owner, _)
        return {
            type    = "melee_aoe",
            hits    = 2,
            damage  = 2.0,
            radius  = 8,
            owner   = owner,
        }
    end,
}

-- Utility – Focused Assault (dash + iframes)
Mercenary.skills.utility = {
    name        = "Focused Assault",
    description = "Dash forward with invincibility, slashing for 3×100% damage.",
    cooldown    = 6,
    stockMax    = 2,
    iFrameDuration = 0.4,
    procCoefficient = 1.0,
    Activate = function(owner, inputDir)
        return {
            type      = "dash_slash",
            direction = inputDir,
            speed     = 40,
            iFrames   = true,
            iFrameDuration = 0.4,
            hits      = 3,
            damage    = 1.0,
            range     = 3,
            owner     = owner,
        }
    end,
}

-- Special – Eviscerate (target-lock spinning slash)
Mercenary.skills.special = {
    name        = "Eviscerate",
    description = "Lock onto a target and spin around them for 550% damage. Grants invincibility.",
    cooldown    = 12,
    stockMax    = 1,
    iFrameDuration = 2.0,
    procCoefficient = 1.0,
    Activate = function(owner, targetEnemy)
        return {
            type         = "eviscerate",
            target       = targetEnemy,
            damage       = 5.5,
            iFrames      = true,
            iFrameDuration = 2.0,
            duration     = 2.0,
            owner        = owner,
        }
    end,
}

return Mercenary
