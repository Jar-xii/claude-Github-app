-- DirectorService.server.lua (Script – ServerScriptService)
-- Controls enemy spawning using a credit-budget system identical to RoR2's
-- "Combat Director". Enemies are represented as Roblox Models tagged with
-- CollectionService; their AI runs in this same script via a coroutine pool.

local CollectionService = game:GetService("CollectionService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConstants  = require(Modules:WaitForChild("GameConstants"))
local Util           = require(Modules:WaitForChild("Util"))

-- Enemy definitions (ModuleScripts in ReplicatedStorage/Enemies)
local EnemyFolder = ReplicatedStorage:WaitForChild("Enemies")
local EnemyDefs = {
    LEMURIAN    = require(EnemyFolder:WaitForChild("Lemurian")),
    WISP        = require(EnemyFolder:WaitForChild("Wisp")),
    GOLEM_STONE = require(EnemyFolder:WaitForChild("GolemStone")),
    IMP         = require(EnemyFolder:WaitForChild("Imp")),
    BEETLE_GUARD = require(EnemyFolder:WaitForChild("BeetleGuard")),
}

-- Wait for GameManager to initialise
repeat task.wait(0.1) until _G.RoR2_RunState

local RunState = _G.RoR2_RunState

-- ── Director State ────────────────────────────────────────────────────────────

local Director = {
    credits      = GameConstants.DIRECTOR.BASE_CREDITS,
    aliveEnemies = {},   -- [model] = { def, hp, state, target, ... }
    spawnPoints  = {},   -- populated from map SpawnPads tagged "EnemySpawn"
    enabled      = true,
}

-- ── Spawn-point detection ─────────────────────────────────────────────────────

local function RefreshSpawnPoints()
    Director.spawnPoints = CollectionService:GetTagged("EnemySpawn")
end
RefreshSpawnPoints()

-- ── Pick a random spawn point off-screen from all players ────────────────────

local function ChooseSpawnPoint()
    local points = Director.spawnPoints
    if #points == 0 then return nil end
    -- Simple: just pick a random tagged part
    return points[math.random(#points)]
end

-- ── Build a candidate pool based on current credits ──────────────────────────

local function GetAffordableEnemies()
    local pool = {}
    for id, def in pairs(EnemyDefs) do
        if def.directorCost <= Director.credits then
            pool[id] = def.directorCost  -- use cost as weight (cheaper = more common)
        end
    end
    return pool
end

-- ── Spawn a single enemy ──────────────────────────────────────────────────────

local function SpawnEnemy(defId, spawnCFrame)
    local def = EnemyDefs[defId]
    if not def then return nil end

    -- Create a simple Model placeholder (replace with actual mesh in Studio)
    local model = Instance.new("Model")
    model.Name  = def.displayName

    local part  = Instance.new("Part")
    part.Name   = "HumanoidRootPart"
    part.Size   = def.sizeScale * Vector3.new(4, 4, 4)
    part.CFrame = spawnCFrame
    part.Anchored = false
    part.Parent = model

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = def.baseStats.maxHP
    humanoid.Health    = def.baseStats.maxHP
    humanoid.Parent    = model
    humanoid.WalkSpeed = def.baseStats.speed

    model.PrimaryPart = part
    model.Parent = workspace

    CollectionService:AddTag(model, "Enemy")
    CollectionService:AddTag(model, defId)

    -- Internal tracking entry
    local entry = {
        def       = def,
        model     = model,
        humanoid  = humanoid,
        hp        = def.baseStats.maxHP,
        state     = def.ai.states.IDLE or "idle",
        target    = nil,
        atkTimers = {},
    }

    -- Scale HP and damage per difficulty coefficient
    if RunState.diffMgr then
        entry.maxHP  = RunState.diffMgr:ScaleHP(def.baseStats.maxHP)
        entry.dmgMult = RunState.diffMgr:ScaleDamage(1)
        humanoid.MaxHealth = entry.maxHP
        humanoid.Health    = entry.maxHP
        entry.hp = entry.maxHP
    else
        entry.maxHP  = def.baseStats.maxHP
        entry.dmgMult = 1
    end

    Director.aliveEnemies[model] = entry

    -- Listen for death
    humanoid.Died:Connect(function()
        Director.aliveEnemies[model] = nil
        -- Notify RunState for XP / gold
        -- (RunState would fire events here; kept simple for brevity)
        model:Destroy()
    end)

    return entry
end

-- ── AI tick (runs every frame for each alive enemy) ──────────────────────────

local AI_TICK = 0.2   -- run AI at 5 Hz to stay within performance budget

local function FindNearestPlayer(rootPart)
    local nearest, nearestDist = nil, math.huge
    for _, player in ipairs(game.Players:GetPlayers()) do
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local d = (root.Position - rootPart.Position).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearest     = char
                end
            end
        end
    end
    return nearest, nearestDist
end

local function TickEnemyAI(entry, dt)
    local model = entry.model
    if not model or not model.Parent then return end

    local root = model.PrimaryPart
    if not root then return end

    local target, dist = FindNearestPlayer(root)
    entry.target = target

    local def = entry.def
    local ai  = def.ai

    if not target then
        entry.state = ai.states.IDLE or "idle"
        return
    end

    -- Very simplified 3-state AI: idle -> chase -> attack
    local sightRange  = ai.sightRange or 50
    local meleeRange  = ai.meleeRange or 5
    local prefRange   = ai.preferredRange or 15

    if dist > sightRange then
        entry.state = "idle"
        return
    end

    if dist > prefRange then
        entry.state = "chase"
        -- Move toward target
        local direction = (target.PrimaryPart.Position - root.Position).Unit
        local moveVec   = direction * def.baseStats.speed * dt
        local cf = root.CFrame
        root.CFrame = CFrame.new(cf.Position + moveVec, cf.Position + direction)
    else
        entry.state = "attack"
        -- Simple: call the first attack that is in range and off cooldown
        for atkId, atk in pairs(def.attacks) do
            local timer = entry.atkTimers[atkId] or 0
            if (tick() - timer) >= (atk.cooldown or 2) then
                local inRange = dist <= (atk.maxRange or meleeRange)
                if inRange then
                    entry.atkTimers[atkId] = tick()
                    local action = atk.attack(entry, target)
                    -- CombatService resolves the action; fire event to it
                    -- (simplified: directly damage the target's humanoid)
                    if action.type == "melee" or action.type == "melee_combo" then
                        local hum = target:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum:TakeDamage(def.baseStats.damage * (action.damage or 1) * entry.dmgMult)
                        end
                    end
                end
            end
        end
    end
end

-- ── Main Director loop ────────────────────────────────────────────────────────

local lastSpawnTick = 0
local lastAITick    = 0

RunService.Heartbeat:Connect(function(dt)
    if not RunState.active or not Director.enabled then return end

    local now = tick()

    -- Accrue credits
    local gainRate = RunState.diffMgr and RunState.diffMgr:GetDirectorCreditGainRate()
                     or GameConstants.DIRECTOR.CREDIT_GAIN_PER_SEC
    Director.credits = math.min(
        Director.credits + gainRate * dt,
        GameConstants.DIRECTOR.MAX_CREDITS
    )

    -- Spawn attempt
    if (now - lastSpawnTick) >= GameConstants.DIRECTOR.SPAWN_INTERVAL then
        lastSpawnTick = now
        local aliveCount = 0
        for _ in pairs(Director.aliveEnemies) do aliveCount = aliveCount + 1 end

        if aliveCount < GameConstants.DIRECTOR.MAX_ENEMIES then
            local pool = GetAffordableEnemies()
            if next(pool) then
                local chosenId = Util.WeightedRandom(pool)
                local sp = ChooseSpawnPoint()
                if sp and chosenId then
                    SpawnEnemy(chosenId, sp.CFrame)
                    Director.credits = Director.credits - EnemyDefs[chosenId].directorCost
                end
            end
        end
    end

    -- AI tick (throttled)
    if (now - lastAITick) >= AI_TICK then
        lastAITick = now
        for _, entry in pairs(Director.aliveEnemies) do
            local ok, err = pcall(TickEnemyAI, entry, AI_TICK)
            if not ok then
                warn("[DirectorService] AI error: " .. tostring(err))
            end
        end
    end
end)

-- ── Teleporter Boss spawn ─────────────────────────────────────────────────────
-- Called by TeleporterService when the charge begins.
function Director.SpawnTeleporterBoss()
    local bossPool = { "GOLEM_STONE", "BEETLE_GUARD" }
    local bossId   = bossPool[math.random(#bossPool)]
    local sp       = ChooseSpawnPoint()
    if not sp then
        warn("[DirectorService] No spawn point for teleporter boss!")
        return
    end
    local entry = SpawnEnemy(bossId, sp.CFrame)
    if entry then
        -- Boss HP multiplier
        local bossHP = entry.maxHP * GameConstants.TELEPORTER.BOSS_HEALTH_MULT
        entry.humanoid.MaxHealth = bossHP
        entry.humanoid.Health    = bossHP
        entry.hp                 = bossHP
        CollectionService:AddTag(entry.model, "TeleporterBoss")
        print("[DirectorService] Teleporter boss spawned: " .. bossId)
    end
    return entry
end

-- Expose to TeleporterService
_G.RoR2_Director = Director

print("[DirectorService] Loaded successfully.")
