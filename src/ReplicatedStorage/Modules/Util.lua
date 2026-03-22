-- Util.lua
-- Shared math / table helpers used across all modules.

local Util = {}

-- ── Math ─────────────────────────────────────────────────────────────────────

function Util.Lerp(a, b, t)
    return a + (b - a) * math.clamp(t, 0, 1)
end

function Util.InverseLerp(a, b, v)
    if a == b then return 0 end
    return math.clamp((v - a) / (b - a), 0, 1)
end

function Util.Round(n, decimals)
    local factor = 10 ^ (decimals or 0)
    return math.floor(n * factor + 0.5) / factor
end

-- Smooth step (ease-in-out)
function Util.SmoothStep(a, b, t)
    local x = math.clamp((t - a) / (b - a), 0, 1)
    return x * x * (3 - 2 * x)
end

-- ── Random ───────────────────────────────────────────────────────────────────

-- Roll a proc: returns true with probability (chance * coefficient)
function Util.ProcRoll(chance, coefficient)
    coefficient = coefficient or 1
    return math.random() < math.clamp(chance * coefficient, 0, 1)
end

-- Weighted random pick: weights = {item = weight, ...}
function Util.WeightedRandom(pool)
    local total = 0
    for _, w in pairs(pool) do total = total + w end
    local r = math.random() * total
    local cumulative = 0
    for item, w in pairs(pool) do
        cumulative = cumulative + w
        if r <= cumulative then return item end
    end
end

-- Pick N unique items from a list
function Util.PickN(list, n)
    local copy = {table.unpack(list)}
    local result = {}
    for i = 1, math.min(n, #copy) do
        local idx = math.random(i, #copy)
        copy[i], copy[idx] = copy[idx], copy[i]
        result[i] = copy[i]
    end
    return result
end

-- ── Table ────────────────────────────────────────────────────────────────────

function Util.ShallowCopy(t)
    local copy = {}
    for k, v in pairs(t) do copy[k] = v end
    return copy
end

function Util.DeepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[Util.DeepCopy(k)] = Util.DeepCopy(v)
    end
    return setmetatable(copy, getmetatable(t))
end

function Util.Contains(t, value)
    for _, v in ipairs(t) do
        if v == value then return true end
    end
    return false
end

function Util.Map(t, fn)
    local out = {}
    for i, v in ipairs(t) do out[i] = fn(v) end
    return out
end

function Util.Filter(t, fn)
    local out = {}
    for _, v in ipairs(t) do
        if fn(v) then out[#out + 1] = v end
    end
    return out
end

-- ── String ───────────────────────────────────────────────────────────────────

function Util.FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d", m, s)
end

function Util.FormatNumber(n)
    -- Insert commas: 1234567 -> "1,234,567"
    local s = tostring(math.floor(n))
    local result = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return result:gsub("^,", "")
end

-- ── 3-D helpers ──────────────────────────────────────────────────────────────

function Util.RandomPointInRing(center, minR, maxR)
    local angle = math.random() * math.pi * 2
    local r = math.sqrt(math.random() * (maxR^2 - minR^2) + minR^2)
    return Vector3.new(
        center.X + math.cos(angle) * r,
        center.Y,
        center.Z + math.sin(angle) * r
    )
end

function Util.DistanceXZ(a, b)
    local dx = a.X - b.X
    local dz = a.Z - b.Z
    return math.sqrt(dx*dx + dz*dz)
end

return Util
