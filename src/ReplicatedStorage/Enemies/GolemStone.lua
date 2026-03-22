-- Enemies/GolemStone.lua
-- Stone Golem: heavy slow enemy with a high-damage laser.

local GolemStone = {}

GolemStone.id          = "GOLEM_STONE"
GolemStone.displayName = "Stone Golem"
GolemStone.directorCost = 35   -- expensive; rare appearance early game

GolemStone.baseStats = {
    maxHP      = 480,
    damage     = 30,
    speed      = 5,
    armor      = 20,
    xpReward   = 60,
    goldReward = 60,
}

GolemStone.sizeScale = Vector3.new(2.5, 2.5, 2.5)

GolemStone.ai = {
    sightRange     = 70,
    meleeRange     = 6,
    preferredRange = 30,

    states = {
        IDLE    = "idle",
        PATROL  = "patrol",
        AIM     = "aim",      -- stands still and tracks player before firing
        FIRE    = "fire",
        STOMP   = "stomp",    -- close-range AoE
    },

    transitions = {
        { from = "idle",    cond = "targetInSight",      to = "aim"    },
        { from = "patrol",  cond = "targetInSight",      to = "aim"    },
        { from = "aim",     cond = "aimTimeElapsed(2)",  to = "fire"   },
        { from = "fire",    cond = "attackDone",         to = "aim"    },
        { from = "aim",     cond = "targetInMelee",      to = "stomp"  },
        { from = "stomp",   cond = "attackDone",         to = "aim"    },
    },
}

GolemStone.attacks = {
    -- Charged laser (2 s wind-up, then fires)
    LASER = {
        id         = "LASER",
        minRange   = 0,
        maxRange   = 60,
        damage     = 4.5,
        cooldown   = 6,
        windupTime = 2.0,
        procCoefficient = 1.0,
        attack = function(self, target)
            return {
                type      = "beam",
                subtype   = "stone_laser",
                damage    = 4.5,
                range     = 60,
                width     = 1.5,
                duration  = 0.3,
                tracking  = false,   -- locks direction at fire time
                target    = target,
                owner     = self,
            }
        end,
    },

    -- Ground stomp AoE
    STOMP = {
        id       = "STOMP",
        range    = 10,
        damage   = 3.2,
        cooldown = 4,
        procCoefficient = 1.0,
        attack = function(self, _target)
            return {
                type   = "melee_aoe",
                radius = 10,
                damage = 3.2,
                knockback = 30,
                owner  = self,
            }
        end,
    },
}

GolemStone.onDeath = {
    dropChance = 0.15,
}

return GolemStone
