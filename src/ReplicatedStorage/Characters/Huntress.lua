-- Characters/Huntress.lua
-- Huntress: high mobility, ranged, low health. Auto-aims at closest enemy.

local Huntress = {}
Huntress.name        = "Huntress"
Huntress.description = "The Huntress is a fragile but fast survivor who can fire while sprinting."
Huntress.unlockCondition = "Complete 5 stages in one run"

Huntress.passive = {
    name        = "Huntress's Focus",
    description = "Huntress can aim and fire while sprinting.",
    canFireWhileSprinting = true,
}

Huntress.skills = {}

-- M1 – Strafe (auto-aim arrow burst)
Huntress.skills.primary = {
    name        = "Strafe",
    description = "Fire an arrow for 150% damage. Auto-aims at the closest enemy.",
    cooldown    = 0,
    stockMax    = 0,
    isAutomatic = true,
    autoAim     = true,
    procCoefficient = 0.7,
    Activate = function(owner, targetEnemy)
        return {
            type       = "projectile",
            speed      = 200,
            damage     = 1.5,
            homing     = true,
            homingTarget = targetEnemy,
            owner      = owner,
        }
    end,
}

-- M2 – Laser Glaive (bouncing projectile)
Huntress.skills.secondary = {
    name        = "Laser Glaive",
    description = "Throw a glaive that bounces up to 6 times for 250% damage each.",
    cooldown    = 7,
    stockMax    = 1,
    bounces     = 6,
    procCoefficient = 1.0,
    Activate = function(owner, targetDirection)
        return {
            type       = "projectile",
            speed      = 60,
            damage     = 2.5,
            bounces    = 6,
            bounceRadius = 20,
            gravity    = false,
            direction  = targetDirection,
            owner      = owner,
        }
    end,
}

-- Utility – Blink (short teleport)
Huntress.skills.utility = {
    name        = "Blink",
    description = "Teleport forward a short distance, passing through enemies.",
    cooldown    = 7,
    stockMax    = 3,
    procCoefficient = 0,
    Activate = function(owner, inputDir)
        return {
            type      = "teleport",
            direction = inputDir,
            distance  = 25,
            owner     = owner,
        }
    end,
}

-- Special – Arrow Rain (AoE rain of arrows)
Huntress.skills.special = {
    name        = "Arrow Rain",
    description = "Teleport into the air and rain arrows on a large area for 12×100% damage.",
    cooldown    = 12,
    stockMax    = 1,
    procCoefficient = 0.5,
    Activate = function(owner, targetPosition)
        return {
            type     = "aoe_rain",
            center   = targetPosition,
            radius   = 15,
            arrows   = 12,
            damage   = 1.0,
            duration = 1.5,
            owner    = owner,
        }
    end,
}

return Huntress
