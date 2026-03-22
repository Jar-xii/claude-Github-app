-- CharacterStats.lua
-- Holds a player's live stat sheet and recomputes it whenever items change.
-- All game systems (combat, movement, skills) read from this sheet.

local ItemRegistry = require(script.Parent.ItemRegistry)

local CharacterStats = {}
CharacterStats.__index = CharacterStats

-- ── Base stat tables per survivor ────────────────────────────────────────────

local BASE_STATS = {
    Commando = {
        maxHP = 110, hpRegen = 2.5, damage = 12, attackSpeed = 1,
        armor = 0, moveSpeed = 7, critChance = 0.01,
    },
    Huntress = {
        maxHP = 90,  hpRegen = 2.5, damage = 12, attackSpeed = 1,
        armor = 0, moveSpeed = 7, critChance = 0.01,
    },
    Mercenary = {
        maxHP = 110, hpRegen = 2.5, damage = 12, attackSpeed = 1,
        armor = 20, moveSpeed = 7, critChance = 0.01,
    },
    Engineer = {
        maxHP = 130, hpRegen = 2.5, damage = 14, attackSpeed = 1,
        armor = 0, moveSpeed = 7, critChance = 0.01,
    },
    Artificer = {
        maxHP = 110, hpRegen = 2.5, damage = 12, attackSpeed = 1,
        armor = 0, moveSpeed = 7, critChance = 0.01,
    },
}

-- ── Constructor ───────────────────────────────────────────────────────────────

function CharacterStats.new(survivorName)
    local base = BASE_STATS[survivorName]
    assert(base, "Unknown survivor: " .. tostring(survivorName))

    local self = setmetatable({}, CharacterStats)
    self._survivorName = survivorName
    self._base         = base
    self._items        = {}   -- { [itemId] = stackCount }
    self._sheet        = {}   -- computed live stats
    self:_Recalculate()
    return self
end

-- ── Item management ───────────────────────────────────────────────────────────

function CharacterStats:AddItem(itemId, count)
    count = count or 1
    local item = ItemRegistry.Get(itemId)
    if not item then
        warn("CharacterStats: unknown item " .. tostring(itemId))
        return
    end
    local current = self._items[itemId] or 0
    local maxStack = item.maxStack or math.huge
    self._items[itemId] = math.min(current + count, maxStack)
    self:_Recalculate()
end

function CharacterStats:RemoveItem(itemId, count)
    count = count or 1
    local current = self._items[itemId] or 0
    self._items[itemId] = math.max(current - count, 0)
    if self._items[itemId] == 0 then
        self._items[itemId] = nil
    end
    self:_Recalculate()
end

function CharacterStats:GetItemCount(itemId)
    return self._items[itemId] or 0
end

function CharacterStats:GetAllItems()
    local out = {}
    for id, n in pairs(self._items) do
        out[id] = n
    end
    return out
end

-- ── Stat access ───────────────────────────────────────────────────────────────

-- Returns the live stat sheet (do NOT cache — re-call after item changes).
function CharacterStats:GetSheet()
    return self._sheet
end

function CharacterStats:Get(statName)
    return self._sheet[statName]
end

-- Level-up: RoR2 survivors gain flat stats per level.
function CharacterStats:SetLevel(level)
    self._level = level
    self:_Recalculate()
end

-- ── Internal ──────────────────────────────────────────────────────────────────

local LEVEL_GROWTH = {
    maxHP       = 33,
    damage      = 2.4,
    hpRegen     = 0.2,
}

function CharacterStats:_Recalculate()
    local base  = self._base
    local level = self._level or 1

    -- Start from base values (copy so items don't pollute the source)
    local s = {
        maxHP        = base.maxHP + LEVEL_GROWTH.maxHP * (level - 1),
        hpRegen      = base.hpRegen + LEVEL_GROWTH.hpRegen * (level - 1),
        damage       = base.damage + LEVEL_GROWTH.damage * (level - 1),
        attackSpeed  = base.attackSpeed,
        armor        = base.armor,
        moveSpeed    = base.moveSpeed,
        critChance   = base.critChance,
        -- These start at zero; items fill them in
        shield            = 0,
        blockChance       = 0,
        bleedChance       = 0,
        extraJumps        = 0,
        barrierOnKill     = 0,
        critHeal          = 0,
        cooldownReduction = 0,
        healingMult       = 1,
        reviveCharges     = 0,
    }

    -- Apply items in a deterministic order (sorted by id for reproducibility)
    local sortedIds = {}
    for id in pairs(self._items) do sortedIds[#sortedIds + 1] = id end
    table.sort(sortedIds)

    for _, id in ipairs(sortedIds) do
        local n    = self._items[id]
        local item = ItemRegistry.Get(id)
        if item and item.onStack and n > 0 then
            item.onStack(s, n)
        end
    end

    -- Clamp sanity checks
    s.critChance   = math.clamp(s.critChance, 0, 1)
    s.blockChance  = math.clamp(s.blockChance or 0, 0, 1)
    s.bleedChance  = math.clamp(s.bleedChance or 0, 0, 1)
    s.attackSpeed  = math.max(s.attackSpeed, 0.1)
    s.moveSpeed    = math.max(s.moveSpeed, 1)
    s.maxHP        = math.max(s.maxHP, 1)

    self._sheet = s
end

return CharacterStats
