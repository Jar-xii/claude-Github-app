-- Enemies/Imp.lua
-- Imp: fast melee enemy that blinks behind the player.

local Imp = {}

Imp.id          = "IMP"
Imp.displayName = "Imp"
Imp.directorCost = 8

Imp.baseStats = {
    maxHP      = 120,
    damage     = 16,
    speed      = 11,
    armor      = 0,
    xpReward   = 20,
    goldReward = 20,
}

Imp.sizeScale = Vector3.new(1, 1, 1)

Imp.ai = {
    sightRange     = 50,
    meleeRange     = 5,
    preferredRange = 3,   -- wants to be RIGHT on the player

    states = {
        IDLE    = "idle",
        BLINK   = "blink",   -- short-range teleport toward target
        ATTACK  = "attack",
        FLEE    = "flee",    -- repositions if stunned
    },

    transitions = {
        { from = "idle",   cond = "targetInSight",     to = "blink"  },
        { from = "blink",  cond = "blinkArrived",      to = "attack" },
        { from = "attack", cond = "attackCycleEnd",    to = "blink"  },
        { from = "attack", cond = "lowHP(0.25)",       to = "flee"   },
        { from = "flee",   cond = "targetFarEnough",   to = "blink"  },
    },
}

Imp.attacks = {
    SLASH = {
        id       = "SLASH",
        range    = 5,
        damage   = 2.0,
        cooldown = 0.8,
        comboLength = 4,
        procCoefficient = 1.0,
        attack = function(self, _target)
            return {
                type   = "melee_combo",
                hits   = 4,
                damage = 2.0,
                range  = 5,
                arc    = 90,
                owner  = self,
            }
        end,
    },
}

-- Blink ability (used by AI state machine, not an attack per se)
Imp.blink = {
    cooldown  = 3,
    distance  = 18,
    iFrames   = false,
}

Imp.onDeath = {
    dropChance = 0.06,
}

return Imp
