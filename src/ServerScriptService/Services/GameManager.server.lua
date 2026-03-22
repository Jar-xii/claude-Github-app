-- GameManager.server.lua (Script – ServerScriptService)
-- Orchestrates the entire run: stage transitions, player state, win/loss.

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")

local Modules     = ReplicatedStorage:WaitForChild("Modules")
local GameConstants   = require(Modules:WaitForChild("GameConstants"))
local DifficultyManager = require(Modules:WaitForChild("DifficultyManager"))
local CharacterStats  = require(Modules:WaitForChild("CharacterStats"))
local ItemRegistry    = require(Modules:WaitForChild("ItemRegistry"))

-- ── RemoteEvent setup ─────────────────────────────────────────────────────────
local Remotes = Instance.new("Folder")
Remotes.Name  = "Remotes"
Remotes.Parent = ReplicatedStorage

local function makeEvent(name)
    local e = Instance.new("RemoteEvent")
    e.Name   = name
    e.Parent = Remotes
    return e
end
local function makeFunction(name)
    local f = Instance.new("RemoteFunction")
    f.Name   = name
    f.Parent = Remotes
    return f
end

local RE_PlayerDied    = makeEvent("PlayerDied")
local RE_StageChanged  = makeEvent("StageChanged")
local RE_ItemGranted   = makeEvent("ItemGranted")
local RE_DamageNumber  = makeEvent("DamageNumber")
local RF_GetStats      = makeFunction("GetStats")
local RF_GetRunTime    = makeFunction("GetRunTime")
local RF_ChooseSurvivor = makeFunction("ChooseSurvivor")

-- ── Run State ─────────────────────────────────────────────────────────────────
local RunState = {
    active      = false,
    stage       = 0,
    difficulty  = GameConstants.DIFFICULTY.RAINSTORM,
    playerData  = {},   -- [Player] = { stats, survivor, currentHP, ... }
    diffMgr     = nil,
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function InitPlayer(player, survivorName)
    survivorName = survivorName or "Commando"
    local stats = CharacterStats.new(survivorName)
    local sheet = stats:GetSheet()
    RunState.playerData[player] = {
        stats        = stats,
        survivor     = survivorName,
        currentHP    = sheet.maxHP,
        currentShield = sheet.shield or 0,
        alive        = true,
        revivesLeft  = 0,
        kills        = 0,
        goldCollected = 0,
    }
end

local function GetPlayerData(player)
    return RunState.playerData[player]
end

-- ── RF Handlers ───────────────────────────────────────────────────────────────

RF_GetStats.OnServerInvoke = function(player)
    local pd = GetPlayerData(player)
    if not pd then return nil end
    return pd.stats:GetSheet()
end

RF_GetRunTime.OnServerInvoke = function(_player)
    if not RunState.diffMgr then return 0 end
    return RunState.diffMgr:GetRunTime()
end

RF_ChooseSurvivor.OnServerInvoke = function(player, survivorName)
    if RunState.active then
        return false, "Run already in progress"
    end
    local VALID = { Commando=true, Huntress=true, Mercenary=true, Engineer=true, Artificer=true }
    if not VALID[survivorName] then
        return false, "Unknown survivor"
    end
    InitPlayer(player, survivorName)
    return true
end

-- ── Stage logic ───────────────────────────────────────────────────────────────

local function AdvanceStage()
    RunState.stage = RunState.stage + 1
    RunState.diffMgr:OnStageClear()

    -- Partial heal on stage clear (25 % of max HP)
    for player, pd in pairs(RunState.playerData) do
        if pd.alive then
            local sheet = pd.stats:GetSheet()
            local healAmt = sheet.maxHP * GameConstants.TELEPORTER.COMPLETION_HEAL_FRAC
            pd.currentHP = math.min(pd.currentHP + healAmt, sheet.maxHP)
        end
    end

    RE_StageChanged:FireAllClients(RunState.stage, GameConstants.STAGES[RunState.stage])
    print("[GameManager] Stage " .. RunState.stage .. ": " .. (GameConstants.STAGES[RunState.stage] or "Loop"))
end

-- ── Death handling ────────────────────────────────────────────────────────────

local function KillPlayer(player)
    local pd = GetPlayerData(player)
    if not pd or not pd.alive then return end

    -- Check Dio's Best Friend
    if pd.stats:GetItemCount("DIOS_BEST_FRIEND") > 0 then
        pd.stats:RemoveItem("DIOS_BEST_FRIEND", 1)
        local sheet = pd.stats:GetSheet()
        pd.currentHP = sheet.maxHP
        RE_ItemGranted:FireClient(player, "DIOS_BEST_FRIEND", -1)  -- consumed
        return
    end

    pd.alive    = false
    pd.currentHP = 0
    RE_PlayerDied:FireAllClients(player)
    print("[GameManager] " .. player.Name .. " has died.")

    -- Monsoon solo: no respawn — end run
    if RunState.difficulty == GameConstants.DIFFICULTY.MONSOON then
        local anyAlive = false
        for _, data in pairs(RunState.playerData) do
            if data.alive then anyAlive = true; break end
        end
        if not anyAlive then
            print("[GameManager] All players dead — run ended.")
            RunState.active = false
        end
        return
    end

    -- Otherwise schedule respawn
    task.delay(GameConstants.SURVIVOR.RESPAWN_TIME, function()
        if not RunState.active then return end
        pd.alive = true
        local sheet = pd.stats:GetSheet()
        pd.currentHP = sheet.maxHP * 0.5
        print("[GameManager] " .. player.Name .. " respawned.")
    end)
end

-- ── Public: apply damage to a player ─────────────────────────────────────────
-- Called by CombatService when an enemy attack lands on a player.
function RunState.DamagePlayer(player, rawDamage, source)
    local pd = GetPlayerData(player)
    if not pd or not pd.alive then return end

    local sheet = pd.stats:GetSheet()

    -- Block check (Tougher Times)
    if sheet.blockChance and sheet.blockChance > 0 then
        if math.random() < sheet.blockChance then
            RE_DamageNumber:FireAllClients(player, 0, true)  -- "BLOCKED" popup
            return
        end
    end

    -- Armor reduction: RoR2 formula: finalDmg = rawDmg * (1 - armor / (armor + 100))
    local armor = sheet.armor or 0
    local reduction = armor / (armor + 100)
    local finalDamage = rawDamage * (1 - reduction)

    -- Absorb into shield first
    if pd.currentShield > 0 then
        local shieldAbsorb = math.min(pd.currentShield, finalDamage)
        pd.currentShield = pd.currentShield - shieldAbsorb
        finalDamage = finalDamage - shieldAbsorb
    end

    pd.currentHP = pd.currentHP - finalDamage
    RE_DamageNumber:FireAllClients(player, math.floor(finalDamage), false)

    if pd.currentHP <= 0 then
        KillPlayer(player)
    end
end

-- ── Player join/leave ─────────────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
    InitPlayer(player, "Commando")
end)

Players.PlayerRemoving:Connect(function(player)
    RunState.playerData[player] = nil
end)

-- Pre-populate existing players (Studio testing)
for _, p in ipairs(Players:GetPlayers()) do
    InitPlayer(p, "Commando")
end

-- ── Run start (called after all players have chosen a survivor) ───────────────

local function StartRun(difficulty)
    RunState.active     = true
    RunState.stage      = 0
    RunState.difficulty = difficulty or GameConstants.DIFFICULTY.RAINSTORM
    RunState.diffMgr    = DifficultyManager.new(RunState.difficulty)
    RunState.diffMgr:StartRun()

    AdvanceStage()
    print("[GameManager] Run started — " .. DifficultyManager.GetTierLabel(RunState.difficulty))
end

-- Auto-start when at least one player is in game (studio/testing convenience)
task.delay(3, function()
    if #Players:GetPlayers() > 0 then
        StartRun(GameConstants.DIFFICULTY.RAINSTORM)
    end
end)

-- ── Regen tick ───────────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(GameConstants.COMBAT.REGEN_TICK_RATE)
        if not RunState.active then continue end
        for player, pd in pairs(RunState.playerData) do
            if pd.alive then
                local sheet  = pd.stats:GetSheet()
                local regen  = (sheet.hpRegen or 0) * GameConstants.COMBAT.REGEN_TICK_RATE
                pd.currentHP = math.min(pd.currentHP + regen, sheet.maxHP)
            end
        end
    end
end)

-- Expose RunState for other server services via _G (simple service locator)
_G.RoR2_RunState = RunState
_G.RoR2_Remotes  = {
    RE_ItemGranted   = RE_ItemGranted,
    RE_DamageNumber  = RE_DamageNumber,
    RE_PlayerDied    = RE_PlayerDied,
    RE_StageChanged  = RE_StageChanged,
}

print("[GameManager] Loaded successfully.")
