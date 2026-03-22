-- Characters/Artificer.lua
-- Artificer: high-damage mage with crowd-control and a powerful charged shot.

local Artificer = {}
Artificer.name        = "Artificer"
Artificer.description = "The Artificer is a mage who dishes out tremendous damage but lacks utility escapes."
Artificer.unlockCondition = "Spend 10 Lunar Coins in a single run"

Artificer.passive = {
    name        = "Overclock",
    description = "Artificer can hover for a short time while holding the jump key.",
    hoverDuration = 1.5,  -- seconds
}

Artificer.skills = {}

-- M1 – Flame Bolt (chargeable fire projectile)
Artificer.skills.primary = {
    name        = "Flame Bolt",
    description = "Charge up to 4 bolts of fire. Each bolt deals 220% damage and ignites.",
    cooldown    = 0,
    stockMax    = 4,
    chargeTime  = 0.5,
    procCoefficient = 1.0,
    Activate = function(owner, targetDirection)
        return {
            type      = "projectile",
            subtype   = "flame_bolt",
            speed     = 80,
            damage    = 2.2,
            radius    = 3,
            ignite    = true,
            igniteDuration = 4,
            igniteDamage   = 0.5,
            direction = targetDirection,
            owner     = owner,
        }
    end,
}

-- M2 – Charged Nano-Bomb (big explosion)
Artificer.skills.secondary = {
    name        = "Charged Nano-Bomb",
    description = "Charge a massive nano-bomb for up to 2600% damage.",
    cooldown    = 12,
    stockMax    = 1,
    minCharge   = 0,
    maxCharge   = 2.0,   -- seconds to reach max damage
    procCoefficient = 1.0,
    Activate = function(owner, targetDirection, chargeRatio)
        local dmgMult = 8 + 18 * chargeRatio   -- 800% – 2600%
        return {
            type      = "projectile",
            subtype   = "nano_bomb",
            speed     = 60,
            damage    = dmgMult,
            radius    = 8 + 6 * chargeRatio,
            direction = targetDirection,
            owner     = owner,
        }
    end,
}

-- Utility – Snapfreeze (ice wall)
Artificer.skills.utility = {
    name        = "Snapfreeze",
    description = "Create a wall of ice at your crosshair, freezing and damaging enemies.",
    cooldown    = 12,
    stockMax    = 1,
    procCoefficient = 1.0,
    Activate = function(owner, targetPosition)
        return {
            type     = "aoe_wall",
            subtype  = "ice_wall",
            position = targetPosition,
            width    = 10,
            height   = 6,
            damage   = 2.0,
            freeze   = true,
            freezeDuration = 3,
            owner    = owner,
        }
    end,
}

-- Special – Flamethrower
Artificer.skills.special = {
    name        = "Flamethrower",
    description = "Ignite the area in front of you for 28×100% damage over 2 seconds.",
    cooldown    = 12,
    stockMax    = 1,
    isChannel   = true,
    channelDuration = 2.0,
    procCoefficient = 0.2,
    Activate = function(owner, targetDirection)
        return {
            type     = "beam",
            subtype  = "flamethrower",
            damage   = 1.0,
            tickRate = 0.1,
            duration = 2.0,
            range    = 20,
            arc      = 30,
            ignite   = true,
            direction = targetDirection,
            owner    = owner,
        }
    end,
}

return Artificer
