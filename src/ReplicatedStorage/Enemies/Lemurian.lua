-- Enemies/Lemurian.lua
-- Basic melee/ranged enemy. Leaps at the player or fires a fireball.

local Lemurian = {}

Lemurian.id          = "LEMURIAN"
Lemurian.displayName = "Lemurian"
Lemurian.directorCost = 6   -- budget cost for Director to spawn one

Lemurian.baseStats = {
    maxHP       = 80,
    damage      = 12,
    speed       = 7,
    armor       = 0,
    xpReward    = 14,
    goldReward  = 14,
}

Lemurian.sizeScale = Vector3.new(1, 1, 1)  -- referenced by server when creating the Roblox model

-- ── AI Behaviour ──────────────────────────────────────────────────────────────
-- The server's CombatService / DirectorService reads these tables to drive
-- a simple state-machine AI without any Pathfinding overhead on the client.

Lemurian.ai = {
    sightRange     = 50,
    meleeRange     = 4,
    preferredRange = 20,   -- tries to keep this distance from the target

    states = {
        IDLE    = "idle",
        CHASE   = "chase",
        ATTACK  = "attack",
        RETREAT = "retreat",
    },

    -- Transition rules (evaluated in order each AI tick)
    transitions = {
        { from = "idle",    cond = "targetInSight",     to = "chase"   },
        { from = "chase",   cond = "inPreferredRange",  to = "attack"  },
        { from = "attack",  cond = "outOfRange",        to = "chase"   },
    },
}

-- ── Skills ────────────────────────────────────────────────────────────────────

Lemurian.attacks = {
    -- Melee swipe
    BITE = {
        id       = "BITE",
        range    = 4,
        damage   = 1.2,   -- multiplier of base damage
        cooldown = 1.5,
        procCoefficient = 1.0,
        attack = function(self, target)
            return { type = "melee", range = 4, damage = 1.2, owner = self }
        end,
    },

    -- Ranged fireball (used when target is far)
    FIREBALL = {
        id       = "FIREBALL",
        minRange = 8,
        maxRange = 30,
        damage   = 1.5,
        cooldown = 4,
        procCoefficient = 1.0,
        attack = function(self, target)
            return {
                type      = "projectile",
                subtype   = "fireball",
                speed     = 35,
                damage    = 1.5,
                radius    = 2,
                target    = target,
                owner     = self,
            }
        end,
    },
}

-- ── Death ─────────────────────────────────────────────────────────────────────

Lemurian.onDeath = {
    dropChance = 0.05,   -- 5 % chance to drop an item orb on death
}

return Lemurian
