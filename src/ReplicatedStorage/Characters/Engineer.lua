-- Characters/Engineer.lua
-- Engineer: turret-deploying survivor with grenades and mines.

local Engineer = {}
Engineer.name        = "Engineer"
Engineer.description = "The Engineer places turrets that fight alongside him, rewarding careful positioning."
Engineer.unlockCondition = "Unlock 40 items"

Engineer.passive = {
    name        = "Blueprint",
    description = "Engineer can place two turrets that inherit his items and stats.",
    maxTurrets  = 2,
}

Engineer.skills = {}

-- M1 – Pressure Mines (burst-fire bouncing grenades)
Engineer.skills.primary = {
    name        = "Grenade",
    description = "Lob a grenade that explodes for 300% damage.",
    cooldown    = 0,
    stockMax    = 0,
    isAutomatic = false,
    procCoefficient = 1.0,
    Activate = function(owner, targetDirection)
        return {
            type      = "projectile",
            subtype   = "grenade",
            speed     = 40,
            arc       = true,
            gravity   = true,
            damage    = 3.0,
            radius    = 6,
            direction = targetDirection,
            owner     = owner,
        }
    end,
}

-- M2 – Pressure Mines
Engineer.skills.secondary = {
    name        = "Pressure Mine",
    description = "Place a mine for 300% damage (+2 stocks, 10s cd per stock).",
    cooldown    = 10,
    stockMax    = 4,
    procCoefficient = 1.0,
    Activate = function(owner, placementPosition)
        return {
            type         = "placeable",
            subtype      = "mine",
            position     = placementPosition,
            damage       = 3.0,
            triggerRadius = 3,
            armDelay     = 1.0,
            owner        = owner,
        }
    end,
}

-- Utility – Bubble Shield
Engineer.skills.utility = {
    name        = "Bubble Shield",
    description = "Deploy a temporary bubble that blocks all projectiles.",
    cooldown    = 15,
    stockMax    = 1,
    duration    = 8,
    procCoefficient = 0,
    Activate = function(owner, _)
        return {
            type     = "shield_bubble",
            radius   = 8,
            duration = 8,
            owner    = owner,
        }
    end,
}

-- Special – TR12 Gauss Auto-Turret
Engineer.skills.special = {
    name        = "TR12 Gauss Auto-Turret",
    description = "Deploy a turret that fires at enemies for 100% damage. Max 2 turrets.",
    cooldown    = 30,
    stockMax    = 2,
    procCoefficient = 1.0,
    Activate = function(owner, placementPosition)
        return {
            type         = "placeable",
            subtype      = "turret",
            position     = placementPosition,
            inheritStats = true,
            damage       = 1.0,
            attackSpeed  = 1.5,
            maxHP        = 400,
            range        = 40,
            owner        = owner,
        }
    end,
}

return Engineer
