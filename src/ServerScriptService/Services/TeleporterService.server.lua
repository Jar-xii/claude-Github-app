-- TeleporterService.server.lua (Script – ServerScriptService)
-- Manages the teleporter charge event:
--   1. Player activates the teleporter (touches it / presses E near it).
--   2. A boss spawns.
--   3. Players must stay inside the radius to charge (0 → 100 %).
--   4. Once at 100 %, boss must be dead for the stage to complete.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConstants = require(Modules:WaitForChild("GameConstants"))
local Util          = require(Modules:WaitForChild("Util"))

repeat task.wait(0.1) until _G.RoR2_RunState and _G.RoR2_Remotes and _G.RoR2_Director
local RunState = _G.RoR2_RunState
local Remotes  = _G.RoR2_Remotes
local Director = _G.RoR2_Director

local Remotes2 = ReplicatedStorage:WaitForChild("Remotes")

-- ── RemoteEvents ──────────────────────────────────────────────────────────────

local RE_TeleporterActivated = Instance.new("RemoteEvent")
RE_TeleporterActivated.Name   = "TeleporterActivated"
RE_TeleporterActivated.Parent = Remotes2

local RE_TeleporterCharge = Instance.new("RemoteEvent")
RE_TeleporterCharge.Name   = "TeleporterCharge"   -- fires each second with 0-1 progress
RE_TeleporterCharge.Parent = Remotes2

local RE_TeleporterComplete = Instance.new("RemoteEvent")
RE_TeleporterComplete.Name   = "TeleporterComplete"
RE_TeleporterComplete.Parent = Remotes2

local RE_ActivateTeleporter = Instance.new("RemoteEvent")
RE_ActivateTeleporter.Name   = "ActivateTeleporter"  -- fired by client
RE_ActivateTeleporter.Parent = Remotes2

-- ── State ─────────────────────────────────────────────────────────────────────

local TeleState = {
    activated   = false,
    charge      = 0,      -- 0..1
    bossAlive   = false,
    boss        = nil,    -- the enemy entry from Director
    teleporter  = nil,    -- the Part in workspace tagged "Teleporter"
}

-- ── Find teleporter Part ──────────────────────────────────────────────────────

local function FindTeleporter()
    local parts = CollectionService:GetTagged("Teleporter")
    return parts[1]
end

-- ── Count players inside the teleporter radius ───────────────────────────────

local RADIUS = GameConstants.TELEPORTER.CHARGE_RADIUS

local function CountPlayersInsideRadius(telePos)
    local count = 0
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = Util.DistanceXZ(root.Position, telePos)
                if dist <= RADIUS then
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- ── Activation ────────────────────────────────────────────────────────────────

local function ActivateTeleporter(player)
    if TeleState.activated then return end

    local tele = FindTeleporter()
    if not tele then
        warn("[TeleporterService] No Part tagged 'Teleporter' in workspace!")
        return
    end

    TeleState.activated = true
    TeleState.teleporter = tele
    TeleState.charge     = 0
    TeleState.bossAlive  = true

    -- Visual feedback: glow the teleporter
    if tele:IsA("BasePart") then
        tele.Material = Enum.Material.Neon
        tele.Color    = Color3.fromRGB(0, 255, 200)
    end

    -- Spawn boss
    TeleState.boss = Director.SpawnTeleporterBoss()
    if TeleState.boss then
        TeleState.boss.humanoid.Died:Connect(function()
            TeleState.bossAlive = false
            print("[TeleporterService] Teleporter boss defeated.")
        end)
    else
        TeleState.bossAlive = false
    end

    RE_TeleporterActivated:FireAllClients(player, tele.Position)
    print("[TeleporterService] Teleporter activated by " .. player.Name)

    -- Charge loop
    task.spawn(function()
        local CHARGE_TIME = GameConstants.TELEPORTER.CHARGE_TIME  -- seconds (all players inside)

        while TeleState.charge < 1 do
            task.wait(1)
            if not RunState.active then return end

            local telePos     = tele.Position
            local insideCount = CountPlayersInsideRadius(telePos)
            local totalCount  = #Players:GetPlayers()

            if insideCount > 0 then
                -- Charge rate scales with fraction of players inside
                local rate = (insideCount / math.max(totalCount, 1)) / CHARGE_TIME
                TeleState.charge = math.min(TeleState.charge + rate, 1)
            end

            RE_TeleporterCharge:FireAllClients(TeleState.charge)
        end

        -- Charge complete — wait for boss death before advancing
        print("[TeleporterService] Charge complete, waiting for boss...")
        while TeleState.bossAlive do
            task.wait(0.5)
        end

        -- Stage complete!
        RE_TeleporterComplete:FireAllClients()
        print("[TeleporterService] Stage complete!")

        -- Heal all alive players
        for _, pd in pairs(RunState.playerData) do
            if pd.alive then
                local sheet = pd.stats:GetSheet()
                local healFrac = GameConstants.TELEPORTER.COMPLETION_HEAL_FRAC
                pd.currentHP = math.min(pd.currentHP + sheet.maxHP * healFrac, sheet.maxHP)
            end
        end

        task.wait(3)  -- brief celebration delay

        -- Advance stage via GameManager
        if RunState.diffMgr then
            RunState.diffMgr:OnStageClear()
        end

        -- Reset teleporter state for next stage
        TeleState.activated = false
        TeleState.charge    = 0
        TeleState.bossAlive = false
        TeleState.boss      = nil

        -- Director: let GameManager know
        -- (In a real impl, GameManager would trigger map loading here)
        RunState.stage = RunState.stage + 1
        if RunState.stage > #GameConstants.STAGES then
            print("[TeleporterService] Final stage cleared — you WIN!")
        end
    end)
end

-- Client fires this when pressing E near the teleporter
RE_ActivateTeleporter.OnServerEvent:Connect(function(player)
    if not RunState.active then return end
    local pd = RunState.playerData[player]
    if not pd or not pd.alive then return end
    ActivateTeleporter(player)
end)

print("[TeleporterService] Loaded successfully.")
