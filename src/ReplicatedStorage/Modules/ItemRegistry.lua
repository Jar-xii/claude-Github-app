-- ItemRegistry.lua
-- Defines every item, its tier, stack behaviour, and the stat-modifier
-- function that CharacterStats applies when recalculating a player's sheet.
--
-- Each item table has:
--   id          (string)  unique identifier
--   name        (string)  display name
--   tier        (string)  GameConstants.ITEM_TIER value
--   maxStack    (number)  max stacks (math.huge = unlimited)
--   description (string)  tooltip shown in the HUD
--   onStack     (fn)      function(stats, stacks) -> mutates stats table

local GameConstants = require(script.Parent.GameConstants)
local Util          = require(script.Parent.Util)

local TIER = GameConstants.ITEM_TIER

-- ── Helper ────────────────────────────────────────────────────────────────────

local function addHP(stats, flat)      stats.maxHP     = stats.maxHP + flat  end
local function addRegen(stats, flat)   stats.hpRegen   = stats.hpRegen + flat end
local function addDamage(stats, pct)   stats.damage    = stats.damage * (1 + pct) end
local function addAttackSpeed(stats, pct) stats.attackSpeed = stats.attackSpeed * (1 + pct) end
local function addArmor(stats, flat)   stats.armor     = stats.armor + flat  end
local function addMoveSpeed(stats, pct) stats.moveSpeed = stats.moveSpeed * (1 + pct) end
local function addCritChance(stats, flat) stats.critChance = math.min(stats.critChance + flat, 1) end

-- ── Item Definitions ──────────────────────────────────────────────────────────

local Items = {}

-- ════════════════ COMMON ═════════════════════════════════════════════════════

Items.TOUGHER_TIMES = {
    id = "TOUGHER_TIMES", tier = TIER.COMMON, maxStack = math.huge,
    name = "Tougher Times",
    description = "Chance to block incoming damage. +15% per stack.",
    onStack = function(stats, n)
        -- Hyperbolic stacking: blockChance = 1 - (1-0.15)^n
        stats.blockChance = 1 - (0.85 ^ n)
    end,
}

Items.LENS_MAKERS_GLASSES = {
    id = "LENS_MAKERS_GLASSES", tier = TIER.COMMON, maxStack = math.huge,
    name = "Lens-Maker's Glasses",
    description = "Your attacks have a chance to critically strike for 2x damage. +10% per stack.",
    onStack = function(stats, n)
        addCritChance(stats, 0.10 * n)
    end,
}

Items.SOLDIERS_SYRINGE = {
    id = "SOLDIERS_SYRINGE", tier = TIER.COMMON, maxStack = math.huge,
    name = "Soldier's Syringe",
    description = "Increases attack speed by 15% (+15% per stack).",
    onStack = function(stats, n)
        -- Linear stacking
        stats.attackSpeed = stats.attackSpeed * (1 + 0.15 * n)
    end,
}

Items.PAUL_GOAT_HOOF = {
    id = "PAUL_GOAT_HOOF", tier = TIER.COMMON, maxStack = math.huge,
    name = "Paul's Goat Hoof",
    description = "Increases movement speed by 14% (+14% per stack).",
    onStack = function(stats, n)
        addMoveSpeed(stats, 0.14 * n)
    end,
}

Items.PERSONAL_SHIELD = {
    id = "PERSONAL_SHIELD", tier = TIER.COMMON, maxStack = math.huge,
    name = "Personal Shield Generator",
    description = "Gain a recharging shield worth 8 HP (+8 per stack).",
    onStack = function(stats, n)
        stats.shield = (stats.shield or 0) + 8 * n
    end,
}

Items.CROWBAR = {
    id = "CROWBAR", tier = TIER.COMMON, maxStack = math.huge,
    name = "Crowbar",
    description = "Deal 75% more damage to enemies above 90% HP (+75% per stack).",
    onStack = function(stats, n)
        stats.crowbarMult = 1 + 0.75 * n
    end,
}

Items.TRI_TIP_DAGGER = {
    id = "TRI_TIP_DAGGER", tier = TIER.COMMON, maxStack = math.huge,
    name = "Tri-Tip Dagger",
    description = "15% chance to bleed on hit for 240% damage. +15% per stack.",
    onStack = function(stats, n)
        stats.bleedChance = 1 - (0.85 ^ n)
    end,
}

Items.TOPAZ_BROOCH = {
    id = "TOPAZ_BROOCH", tier = TIER.COMMON, maxStack = math.huge,
    name = "Topaz Brooch",
    description = "Gain a temporary barrier on kill for 15 HP (+15 per stack).",
    onStack = function(stats, n)
        stats.barrierOnKill = (stats.barrierOnKill or 0) + 15 * n
    end,
}

Items.BISON_STEAK = {
    id = "BISON_STEAK", tier = TIER.COMMON, maxStack = math.huge,
    name = "Bison Steak",
    description = "Increases maximum health by 25 HP (+25 per stack).",
    onStack = function(stats, n)
        addHP(stats, 25 * n)
    end,
}

Items.BUNDLE_OF_FIREWORKS = {
    id = "BUNDLE_OF_FIREWORKS", tier = TIER.COMMON, maxStack = math.huge,
    name = "Bundle of Fireworks",
    description = "Activating an interactable launches 8 fireworks (+4 per stack).",
    onStack = function(stats, n)
        stats.fireworkCount = (stats.fireworkCount or 0) + 4 * n + 4
    end,
}

-- ════════════════ UNCOMMON ═══════════════════════════════════════════════════

Items.UKULELE = {
    id = "UKULELE", tier = TIER.UNCOMMON, maxStack = math.huge,
    name = "Ukulele",
    description = "25% chance to chain lightning on hit for 80% damage to 3 targets (+2 per stack).",
    onStack = function(stats, n)
        stats.ukuleleChance  = 0.25
        stats.ukuleleTargets = 3 + 2 * (n - 1)
        stats.ukuleleDamage  = 0.80
    end,
}

Items.WILL_O_WISP = {
    id = "WILL_O_WISP", tier = TIER.UNCOMMON, maxStack = math.huge,
    name = "Will-o'-the-wisp",
    description = "On kill, detonate the enemy for 350% damage to nearby foes. +280% per stack.",
    onStack = function(stats, n)
        stats.wispDamage = 3.50 + 2.80 * (n - 1)
    end,
}

Items.HOPOO_FEATHER = {
    id = "HOPOO_FEATHER", tier = TIER.UNCOMMON, maxStack = 10,
    name = "Hopoo Feather",
    description = "Gain an extra jump. +1 per stack (max 10).",
    onStack = function(stats, n)
        stats.extraJumps = (stats.extraJumps or 0) + n
    end,
}

Items.BANDOLIER = {
    id = "BANDOLIER", tier = TIER.UNCOMMON, maxStack = math.huge,
    name = "Bandolier",
    description = "18% chance on kill to drop an ammo pack. +18% per stack.",
    onStack = function(stats, n)
        stats.bandolierChance = 1 - (0.82 ^ n)
    end,
}

Items.HARVESTER_SCYTHE = {
    id = "HARVESTER_SCYTHE", tier = TIER.UNCOMMON, maxStack = math.huge,
    name = "Harvester's Scythe",
    description = "Gain 5% crit chance. Critical strikes heal for 8 HP (+4 per stack).",
    onStack = function(stats, n)
        addCritChance(stats, 0.05)
        stats.critHeal = (stats.critHeal or 0) + 4 * n + 4
    end,
}

Items.PREDATORY_INSTINCTS = {
    id = "PREDATORY_INSTINCTS", tier = TIER.UNCOMMON, maxStack = math.huge,
    name = "Predatory Instincts",
    description = "Critical strikes increase attack speed by 12%. Limit: 30% (+30% per stack).",
    onStack = function(stats, n)
        addCritChance(stats, 0.05)
        stats.critAttackSpeedMax = 0.30 * n
    end,
}

Items.ROSE_BUCKLER = {
    id = "ROSE_BUCKLER", tier = TIER.UNCOMMON, maxStack = math.huge,
    name = "Rose Buckler",
    description = "Increase armor by 30 while sprinting (+30 per stack).",
    onStack = function(stats, n)
        stats.sprintArmor = (stats.sprintArmor or 0) + 30 * n
    end,
}

Items.OLD_WAR_STEALTHKIT = {
    id = "OLD_WAR_STEALTHKIT", tier = TIER.UNCOMMON, maxStack = math.huge,
    name = "Old War Stealthkit",
    description = "40% chance to turn invisible when hurt, lasting 3s (+1.5s per stack).",
    onStack = function(stats, n)
        stats.stealthkitChance    = 0.40
        stats.stealthkitDuration  = 3 + 1.5 * (n - 1)
    end,
}

-- ════════════════ LEGENDARY ══════════════════════════════════════════════════

Items.ALIEN_HEAD = {
    id = "ALIEN_HEAD", tier = TIER.LEGENDARY, maxStack = math.huge,
    name = "Alien Head",
    description = "Reduce all skill cooldowns by 25% (+25% per stack, hyperbolic).",
    onStack = function(stats, n)
        stats.cooldownReduction = 1 - (0.75 ^ n)
    end,
}

Items.BRILLIANT_BEHEMOTH = {
    id = "BRILLIANT_BEHEMOTH", tier = TIER.LEGENDARY, maxStack = math.huge,
    name = "Brilliant Behemoth",
    description = "All attacks explode for 60% damage (+60% per stack) to nearby enemies.",
    onStack = function(stats, n)
        stats.behemothDamage = 0.60 * n
    end,
}

Items.CEREMONIAL_DAGGER = {
    id = "CEREMONIAL_DAGGER", tier = TIER.LEGENDARY, maxStack = math.huge,
    name = "Ceremonial Dagger",
    description = "On kill, release 3 daggers chasing nearby enemies for 150% damage (+150% per stack).",
    onStack = function(stats, n)
        stats.daggerDamage = 1.50 * n
        stats.daggerCount  = 3
    end,
}

Items.DIOS_BEST_FRIEND = {
    id = "DIOS_BEST_FRIEND", tier = TIER.LEGENDARY, maxStack = math.huge,
    name = "Dio's Best Friend",
    description = "Revive once upon death. Extra stacks charge independently.",
    onStack = function(stats, n)
        stats.reviveCharges = (stats.reviveCharges or 0) + n
    end,
}

Items.REJUVENATION_RACK = {
    id = "REJUVENATION_RACK", tier = TIER.LEGENDARY, maxStack = math.huge,
    name = "Rejuvenation Rack",
    description = "Double all healing (×2 per stack).",
    onStack = function(stats, n)
        stats.healingMult = (stats.healingMult or 1) * (2 ^ n)
    end,
}

-- ════════════════ BOSS ═══════════════════════════════════════════════════════

Items.KNURL = {
    id = "KNURL", tier = TIER.BOSS, maxStack = math.huge,
    name = "Titanic Knurl",
    description = "Increase maximum health by 40 HP and regen by 1.6 HP/s (+40 HP, +1.6 HP/s per stack).",
    onStack = function(stats, n)
        addHP(stats, 40 * n)
        addRegen(stats, 1.6 * n)
    end,
}

Items.QUEENS_GLAND = {
    id = "QUEENS_GLAND", tier = TIER.BOSS, maxStack = 1,
    name = "Queen's Gland",
    description = "Recruit a Beetle Guard ally that inherits your items.",
    onStack = function(stats, _n)
        stats.hasBeetleGuard = true
    end,
}

Items.HALCYON_SEED = {
    id = "HALCYON_SEED", tier = TIER.BOSS, maxStack = 1,
    name = "Halcyon Seed",
    description = "Summon Aurelionite during the teleporter event.",
    onStack = function(stats, _n)
        stats.summonAurelionite = true
    end,
}

-- ════════════════ LUNAR ══════════════════════════════════════════════════════

Items.SHAPED_GLASS = {
    id = "SHAPED_GLASS", tier = TIER.LUNAR, maxStack = math.huge,
    name = "Shaped Glass",
    description = "Double damage, halve maximum health (×2 damage, ÷2 HP per stack).",
    onStack = function(stats, n)
        stats.damage  = stats.damage * (2 ^ n)
        stats.maxHP   = stats.maxHP  / (2 ^ n)
    end,
}

Items.BEADS_OF_FEALTY = {
    id = "BEADS_OF_FEALTY", tier = TIER.LUNAR, maxStack = 1,
    name = "Beads of Fealty",
    description = "Seems to do nothing... or does it?",
    onStack = function(_stats, _n)
        -- Narrative: changes Mithrix encounter; no stat effect in base loop
    end,
}

Items.STRIDES_OF_HERESY = {
    id = "STRIDES_OF_HERESY", tier = TIER.LUNAR, maxStack = 1,
    name = "Strides of Heresy",
    description = "Replace Utility skill with Shadowfade: briefly turn invisible and heal.",
    onStack = function(stats, _n)
        stats.utilityReplaced = "SHADOWFADE"
    end,
}

-- ── Registry Index ────────────────────────────────────────────────────────────

local ItemRegistry = {}
ItemRegistry._byId = {}
ItemRegistry._byTier = {}

for _, item in pairs(Items) do
    ItemRegistry._byId[item.id] = item
    local tier = item.tier
    if not ItemRegistry._byTier[tier] then
        ItemRegistry._byTier[tier] = {}
    end
    table.insert(ItemRegistry._byTier[tier], item)
end

function ItemRegistry.Get(id)
    return ItemRegistry._byId[id]
end

function ItemRegistry.GetByTier(tier)
    return Util.ShallowCopy(ItemRegistry._byTier[tier] or {})
end

function ItemRegistry.GetAll()
    local all = {}
    for _, item in pairs(ItemRegistry._byId) do
        table.insert(all, item)
    end
    return all
end

-- Returns a random item from a weighted tier distribution.
function ItemRegistry.RandomDrop()
    local GC   = GameConstants
    local tier = Util.WeightedRandom({
        [TIER.COMMON]    = GC.DROP_CHANCE[TIER.COMMON],
        [TIER.UNCOMMON]  = GC.DROP_CHANCE[TIER.UNCOMMON],
        [TIER.LEGENDARY] = GC.DROP_CHANCE[TIER.LEGENDARY],
    })
    local pool = ItemRegistry.GetByTier(tier)
    if not pool or #pool == 0 then return nil end
    return pool[math.random(#pool)]
end

return ItemRegistry
