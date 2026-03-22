-- Enemies/Wisp.lua
-- Floating ranged enemy. Fires three-shot bursts; retreats when approached.

local Wisp = {}

Wisp.id          = "WISP"
Wisp.displayName = "Wisp"
Wisp.directorCost = 7

Wisp.baseStats = {
    maxHP      = 35,
    damage     = 14,
    speed      = 8,
    armor      = 0,
    xpReward   = 16,
    goldReward = 16,
    flying     = true,
}

Wisp.sizeScale = Vector3.new(0.8, 0.8, 0.8)

Wisp.ai = {
    sightRange     = 60,
    meleeRange     = 5,
    preferredRange = 25,
    floatHeight    = 4,   -- hovers this many studs above ground

    states = {
        IDLE    = "idle",
        ORBIT   = "orbit",    -- circles the target at preferred range
        ATTACK  = "attack",
        FLEE    = "flee",
    },

    transitions = {
        { from = "idle",   cond = "targetInSight",    to = "orbit"  },
        { from = "orbit",  cond = "atkCooldownReady", to = "attack" },
        { from = "attack", cond = "attackDone",       to = "orbit"  },
        { from = "orbit",  cond = "targetTooClose",   to = "flee"   },
        { from = "flee",   cond = "targetFarEnough",  to = "orbit"  },
    },
}

Wisp.attacks = {
    BURST = {
        id       = "BURST",
        minRange = 10,
        maxRange = 50,
        damage   = 1.4,
        cooldown = 3,
        shots    = 3,
        procCoefficient = 0.5,
        attack = function(self, target)
            local shots = {}
            for i = 1, 3 do
                shots[i] = {
                    type   = "projectile",
                    subtype = "wisp_orb",
                    speed  = 50,
                    damage = 1.4,
                    radius = 1,
                    target = target,
                    delay  = (i - 1) * 0.15,
                    owner  = self,
                }
            end
            return { type = "burst", shots = shots }
        end,
    },
}

Wisp.onDeath = {
    -- On death: explode into two Mini-Wisps (Director spawns them directly)
    spawnOnDeath = { id = "LESSER_WISP", count = 2 },
    dropChance   = 0.04,
}

return Wisp
