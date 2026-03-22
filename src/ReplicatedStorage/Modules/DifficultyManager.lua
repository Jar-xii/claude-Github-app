-- DifficultyManager.lua
-- Mirrors RoR2's difficulty scaling: a coefficient that grows with elapsed
-- time and adjusts HP, damage, and credit costs of all enemies.
--
-- Formula (from RoR2 wiki):
--   coeff = difficultyMult * (ambiguityFactor + scalingFactor * sqrt(t / 60))
-- where t is total run time in seconds.

local GameConstants = require(script.Parent.GameConstants)

local DifficultyManager = {}
DifficultyManager.__index = DifficultyManager

-- ── Constructor ───────────────────────────────────────────────────────────────

function DifficultyManager.new(difficulty)
    local self = setmetatable({}, DifficultyManager)
    self._difficulty   = difficulty or GameConstants.DIFFICULTY.RAINSTORM
    self._startTime    = 0  -- set when run begins (os.clock or tick)
    self._stageClearBonus = 0
    return self
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Call once when the run starts.
function DifficultyManager:StartRun()
    self._startTime = tick()
end

-- Add bonus seconds to the difficulty clock when a stage is cleared.
function DifficultyManager:OnStageClear()
    -- RoR2 adds ~2 minutes of effective time per stage clear.
    self._stageClearBonus = self._stageClearBonus + 120
end

-- Returns elapsed run time (including stage-clear bonuses) in seconds.
function DifficultyManager:GetRunTime()
    return (tick() - self._startTime) + self._stageClearBonus
end

-- Core scaling coefficient (≥ 1.0 for Rainstorm at t = 0).
function DifficultyManager:GetCoefficient()
    local t    = self:GetRunTime()
    local mult = GameConstants.DIFFICULTY_MULT[self._difficulty]
    local sc   = GameConstants.SCALING
    local base = sc.ambiguityFactor + sc.scalingFactor * math.sqrt(t / 60)
    return mult * base
end

-- Enemy HP multiplier for a given base health pool.
function DifficultyManager:ScaleHP(baseHP)
    local c = self:GetCoefficient()
    -- RoR2 formula: scaledHP = baseHP * c^1.0 (linear with coefficient)
    return baseHP * c
end

-- Enemy damage multiplier.
function DifficultyManager:ScaleDamage(baseDamage)
    local c = self:GetCoefficient()
    -- Damage scales a bit slower than HP (c^0.5 feels fair)
    return baseDamage * math.sqrt(c)
end

-- Director: credit cost of an enemy call is not scaled — but credit gain
-- rate is scaled so more enemies spawn as time passes.
function DifficultyManager:GetDirectorCreditGainRate()
    local c = self:GetCoefficient()
    return GameConstants.DIRECTOR.CREDIT_GAIN_PER_SEC * c
end

-- Human-readable summary for debugging / HUD display.
function DifficultyManager:GetSummary()
    return {
        difficulty   = self._difficulty,
        runTime      = self:GetRunTime(),
        coefficient  = self:GetCoefficient(),
        creditRate   = self:GetDirectorCreditGainRate(),
    }
end

-- ── Difficulty presets ────────────────────────────────────────────────────────

-- Returns the difficulty tier name from its string key.
function DifficultyManager.GetTierLabel(difficulty)
    local labels = {
        [GameConstants.DIFFICULTY.DRIZZLE]   = "Drizzle  (Easy)",
        [GameConstants.DIFFICULTY.RAINSTORM] = "Rainstorm (Normal)",
        [GameConstants.DIFFICULTY.MONSOON]   = "Monsoon  (Hard)",
    }
    return labels[difficulty] or "Unknown"
end

return DifficultyManager
