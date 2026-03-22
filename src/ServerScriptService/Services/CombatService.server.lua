-- CombatService.server.lua (Script – ServerScriptService)
-- Resolves all damage calculations, proc effects, critical strikes, and
-- on-hit item procs.  Server-authoritative — clients never touch HP directly.

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConstants  = require(Modules:WaitForChild("GameConstants"))
local ItemRegistry   = require(Modules:WaitForChild("ItemRegistry"))
local Util           = require(Modules:WaitForChild("Util"))

-- Wait for upstream services
repeat task.wait(0.1) until _G.RoR2_RunState and _G.RoR2_Remotes

local RunState = _G.RoR2_RunState
local Remotes  = _G.RoR2_Remotes

-- ── Incoming action queue ─────────────────────────────────────────────────────
-- CharacterController fires a RemoteEvent with the skill action; we queue and
-- resolve server-side.

local Remotes2 = ReplicatedStorage:WaitForChild("Remotes")
local RE_SkillFired = Instance.new("RemoteEvent")
RE_SkillFired.Name   = "SkillFired"
RE_SkillFired.Parent = Remotes2

-- ── Core: calculate damage dealt by a player ─────────────────────────────────

-- Returns a DamageResult table from a raw multiplier action.
local function CalcPlayerDamage(player, action)
    local pd = RunState.playerData[player]
    if not pd then return nil end

    local sheet  = pd.stats:GetSheet()
    local base   = sheet.damage
    local mult   = action.damage or 1.0
    local raw    = base * mult

    local isCrit = Util.ProcRoll(sheet.critChance or 0, 1)
    if isCrit then
        raw = raw * GameConstants.COMBAT.CRIT_MULT
    end

    -- Crowbar: extra damage above 90 % HP target
    local crowbarBonus = 1
    if sheet.crowbarMult and action.targetHP and action.targetMaxHP then
        if action.targetHP / action.targetMaxHP > 0.9 then
            crowbarBonus = sheet.crowbarMult
        end
    end
    raw = raw * crowbarBonus

    return {
        damage    = raw,
        isCrit    = isCrit,
        procCoeff = action.procCoefficient or GameConstants.COMBAT.PROC_COEFFICIENT_DEFAULT,
    }
end

-- ── Proc effects ──────────────────────────────────────────────────────────────

local function FireProcs(player, result, targetModel)
    local pd    = RunState.playerData[player]
    if not pd then return end
    local sheet = pd.stats:GetSheet()
    local pc    = result.procCoeff

    -- Bleed (Tri-Tip Dagger)
    if sheet.bleedChance and Util.ProcRoll(sheet.bleedChance, pc) then
        -- Apply a bleed DoT: 240% of base damage over 3 seconds
        task.spawn(function()
            local bleedTick = pd.stats:GetSheet().damage * 2.4 / 6  -- 6 ticks
            for _ = 1, 6 do
                task.wait(0.5)
                if targetModel and targetModel.Parent then
                    local hum = targetModel:FindFirstChildOfClass("Humanoid")
                    if hum then hum:TakeDamage(bleedTick) end
                end
            end
        end)
    end

    -- Ukulele (chain lightning)
    if sheet.ukuleleChance and Util.ProcRoll(sheet.ukuleleChance, pc) then
        local targets = CollectionService:GetTagged("Enemy")
        local hit = 0
        for _, enemy in ipairs(targets) do
            if enemy ~= targetModel and hit < (sheet.ukuleleTargets or 3) then
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:TakeDamage(result.damage * (sheet.ukuleleDamage or 0.8))
                    hit = hit + 1
                    Remotes.RE_DamageNumber:FireAllClients(enemy, math.floor(result.damage * 0.8), false)
                end
            end
        end
    end

    -- Will-o'-the-wisp (on kill explosion — handled in Kill event instead)

    -- Crit heal (Harvester's Scythe)
    if result.isCrit and sheet.critHeal and sheet.critHeal > 0 then
        local healAmt = sheet.critHeal * (sheet.healingMult or 1)
        local currentPD = RunState.playerData[player]
        if currentPD then
            local maxHP = currentPD.stats:GetSheet().maxHP
            currentPD.currentHP = math.min(currentPD.currentHP + healAmt, maxHP)
        end
    end
end

-- ── Apply damage to an enemy model ───────────────────────────────────────────

local function DamageEnemy(player, targetModel, action)
    local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local result = CalcPlayerDamage(player, action)
    if not result then return end

    humanoid:TakeDamage(result.damage)

    -- Fire visual feedback to all clients
    Remotes.RE_DamageNumber:FireAllClients(targetModel, math.floor(result.damage), result.isCrit)

    -- Fire on-hit procs
    FireProcs(player, result, targetModel)

    -- Kill handling
    if humanoid.Health <= 0 then
        local pd   = RunState.playerData[player]
        local def  = nil
        -- Identify enemy type to award XP/gold
        for tag, d in pairs({
            LEMURIAN    = true,
            WISP        = true,
            GOLEM_STONE = true,
            IMP         = true,
            BEETLE_GUARD = true,
        }) do
            if CollectionService:HasTag(targetModel, tag) then
                local EnemyFolder = ReplicatedStorage:WaitForChild("Enemies", 1)
                if EnemyFolder then
                    local mod = EnemyFolder:FindFirstChild(tag:sub(1,1) .. tag:sub(2):lower():gsub("_(%l)", string.upper))
                    -- Just award a flat amount for simplicity
                end
            end
        end

        if pd then
            pd.kills = pd.kills + 1

            -- Topaz Brooch barrier on kill
            local sheet = pd.stats:GetSheet()
            if sheet.barrierOnKill and sheet.barrierOnKill > 0 then
                pd.currentShield = math.min(
                    (pd.currentShield or 0) + sheet.barrierOnKill,
                    sheet.maxHP
                )
            end

            -- Bandolier ammo pack on kill
            if sheet.bandolierChance and Util.ProcRoll(sheet.bandolierChance, 1) then
                -- Notify CharacterController to reset skill stocks
                local ammoRE = Remotes2:FindFirstChild("AmmoPackDropped")
                if ammoRE then ammoRE:FireClient(player) end
            end

            -- Will-o'-the-wisp explosion on kill
            if sheet.wispDamage and sheet.wispDamage > 0 then
                local pos  = targetModel.PrimaryPart and targetModel.PrimaryPart.Position
                if pos then
                    for _, enemy in ipairs(CollectionService:GetTagged("Enemy")) do
                        if enemy ~= targetModel and enemy.PrimaryPart then
                            local dist = (enemy.PrimaryPart.Position - pos).Magnitude
                            if dist <= 12 then
                                local hum = enemy:FindFirstChildOfClass("Humanoid")
                                if hum then
                                    hum:TakeDamage(pd.stats:GetSheet().damage * sheet.wispDamage)
                                end
                            end
                        end
                    end
                end
            end

            -- Ceremonial Daggers on kill
            if sheet.daggerDamage and sheet.daggerDamage > 0 then
                local targets = CollectionService:GetTagged("Enemy")
                local sent = 0
                for _, enemy in ipairs(targets) do
                    if sent < (sheet.daggerCount or 3) and enemy.Parent then
                        local hum = enemy:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum:TakeDamage(pd.stats:GetSheet().damage * sheet.daggerDamage)
                            sent = sent + 1
                        end
                    end
                end
            end
        end
    end
end

-- ── RemoteEvent handler: skill fired by client ────────────────────────────────

RE_SkillFired.OnServerEvent:Connect(function(player, actionTable)
    if not RunState.active then return end
    local pd = RunState.playerData[player]
    if not pd or not pd.alive then return end

    -- Validate action type
    if type(actionTable) ~= "table" then return end

    local actionType = actionTable.type
    if not actionType then return end

    -- For hitscan and projectile attacks, find the first enemy in the path
    -- (In a real impl, the client would send the target model; we trust it for now)
    local targetModel = actionTable.target   -- RemoteEvent should pass the enemy model ref

    if targetModel and (actionType == "hitscan" or actionType == "projectile"
        or actionType == "melee" or actionType == "melee_combo"
        or actionType == "melee_aoe") then
        DamageEnemy(player, targetModel, actionTable)
    end
end)

-- Expose DamageEnemy for internal server use
_G.RoR2_CombatService = {
    DamageEnemy  = DamageEnemy,
    DamagePlayer = RunState.DamagePlayer,
}

print("[CombatService] Loaded successfully.")
