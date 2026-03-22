-- Enemies/BeetleGuard.lua
-- Beetle Guard: large beetle that charges and body-slams.

local BeetleGuard = {}

BeetleGuard.id          = "BEETLE_GUARD"
BeetleGuard.displayName = "Beetle Guard"
BeetleGuard.directorCost = 25

BeetleGuard.baseStats = {
    maxHP      = 360,
    damage     = 26,
    speed      = 8,
    armor      = 20,
    xpReward   = 45,
    goldReward = 45,
}

BeetleGuard.sizeScale = Vector3.new(2, 2, 2)

BeetleGuard.ai = {
    sightRange     = 60,
    meleeRange     = 7,
    preferredRange = 0,   -- always tries to close distance

    states = {
        IDLE    = "idle",
        CHARGE  = "charge",
        SLAM    = "slam",
        SWIPE   = "swipe",
    },

    transitions = {
        { from = "idle",   cond = "targetInSight",      to = "charge" },
        { from = "charge", cond = "targetInMelee",      to = "slam"   },
        { from = "slam",   cond = "attackDone",         to = "swipe"  },
        { from = "swipe",  cond = "attackDone",         to = "charge" },
    },
}

BeetleGuard.attacks = {
    -- Headbutt slam
    SLAM = {
        id       = "SLAM",
        range    = 7,
        damage   = 3.0,
        cooldown = 2.5,
        knockback = 40,
        procCoefficient = 1.0,
        attack = function(self, _target)
            return {
                type      = "melee",
                range     = 7,
                arc       = 60,
                damage    = 3.0,
                knockback = 40,
                owner     = self,
            }
        end,
    },

    -- Swipe (wide arc)
    SWIPE = {
        id       = "SWIPE",
        range    = 8,
        damage   = 2.2,
        cooldown = 1.5,
        procCoefficient = 1.0,
        attack = function(self, _target)
            return {
                type   = "melee",
                range  = 8,
                arc    = 150,
                damage = 2.2,
                owner  = self,
            }
        end,
    },
}

BeetleGuard.onDeath = {
    dropChance = 0.12,
}

return BeetleGuard
