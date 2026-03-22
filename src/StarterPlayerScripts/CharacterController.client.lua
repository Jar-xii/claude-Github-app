-- CharacterController.client.lua (LocalScript – StarterPlayerScripts)
-- Handles player input, skill activation, sprint, and sends actions to the server.

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player     = Players.LocalPlayer
local Mouse      = Player:GetMouse()
local Camera     = workspace.CurrentCamera

-- Wait for remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if not Remotes then error("[CharacterController] Remotes not found") end

local RE_SkillFired    = Remotes:WaitForChild("SkillFired")
local RF_GetStats      = Remotes:WaitForChild("GetStats")
local RF_ChooseSurvivor = Remotes:WaitForChild("ChooseSurvivor")
local RE_TeleActivate  = Remotes:WaitForChild("ActivateTeleporter")
local RE_ItemGranted   = Remotes:WaitForChild("ItemGranted")
local RE_AmmoPackDropped = Instance.new("RemoteEvent")
RE_AmmoPackDropped.Name   = "AmmoPackDropped"
RE_AmmoPackDropped.Parent = Remotes

-- ── Survivor selection ────────────────────────────────────────────────────────
-- In production, this would show a lobby UI. Here we default to Commando.

local CHOSEN_SURVIVOR = "Commando"

task.spawn(function()
    task.wait(1)
    RF_ChooseSurvivor:InvokeServer(CHOSEN_SURVIVOR)
end)

-- ── State ─────────────────────────────────────────────────────────────────────

local State = {
    isSprinting    = false,
    isGrounded     = true,
    extraJumps     = 0,
    currentJumps   = 0,

    -- Skill cooldowns (client-side prediction only; server authoritative)
    cooldowns = {
        primary   = 0,
        secondary = 0,
        utility   = 0,
        special   = 0,
    },
    stocks = {
        primary   = 0,
        secondary = 1,
        utility   = 2,
        special   = 1,
    },
}

-- Survivor skill definitions (loaded client-side for preview / cooldown UI)
local CharacterDefs = {
    Commando  = require(ReplicatedStorage:WaitForChild("Characters"):WaitForChild("Commando")),
    Huntress  = require(ReplicatedStorage:WaitForChild("Characters"):WaitForChild("Huntress")),
    Mercenary = require(ReplicatedStorage:WaitForChild("Characters"):WaitForChild("Mercenary")),
    Engineer  = require(ReplicatedStorage:WaitForChild("Characters"):WaitForChild("Engineer")),
    Artificer = require(ReplicatedStorage:WaitForChild("Characters"):WaitForChild("Artificer")),
}

local SurvivorDef = CharacterDefs[CHOSEN_SURVIVOR]

-- ── Cooldown helpers ──────────────────────────────────────────────────────────

local function IsSkillReady(skillKey)
    return (tick() - State.cooldowns[skillKey]) >= (SurvivorDef.skills[skillKey].cooldown or 0)
end

local function UseSkill(skillKey)
    State.cooldowns[skillKey] = tick()
end

-- ── Sprint ────────────────────────────────────────────────────────────────────

local Humanoid
local Character

Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid  = char:WaitForChild("Humanoid")
    State.currentJumps = 0

    Humanoid.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Landed then
            State.isGrounded   = true
            State.currentJumps = 0
        elseif new == Enum.HumanoidStateType.Freefall or new == Enum.HumanoidStateType.Jumping then
            State.isGrounded = false
        end
    end)
end)

if Player.Character then
    Character = Player.Character
    Humanoid  = Character:FindFirstChildOfClass("Humanoid")
end

RunService.RenderStepped:Connect(function()
    if not Humanoid then return end

    -- Sprinting
    local isMoving = Humanoid.MoveDirection.Magnitude > 0.1
    local shiftHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)

    State.isSprinting = isMoving and shiftHeld

    -- Apply sprint speed via BodyVelocity if sprinting
    -- (Roblox Humanoid.WalkSpeed is set directly)
    local stats = RF_GetStats:InvokeServer()
    if stats then
        local base  = stats.moveSpeed or 16
        local speed = State.isSprinting and (base * 1.45) or base
        Humanoid.WalkSpeed = speed
    end
end)

-- ── Target detection (simple: raycast from camera toward mouse) ──────────────

local function GetMouseTarget()
    local unitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local params  = RaycastParams.new()
    params.FilterDescendantsInstances = { Character }
    params.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, params)
    if result then
        return result.Instance, result.Position
    end
    return nil, unitRay.Origin + unitRay.Direction * 200
end

local function GetNearestEnemy(maxRange)
    local root = Character and Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local nearest, nearestDist = nil, maxRange or 60
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("Humanoid") and part.Parent ~= Character then
            local partRoot = part.Parent:FindFirstChild("HumanoidRootPart")
            if partRoot then
                local d = (partRoot.Position - root.Position).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearest     = part.Parent
                end
            end
        end
    end
    return nearest
end

-- ── Skill activation ──────────────────────────────────────────────────────────

local function FireSkill(skillKey)
    if not Character or not Humanoid then return end
    if Humanoid.Health <= 0 then return end
    if not IsSkillReady(skillKey) then return end

    local skill = SurvivorDef.skills[skillKey]
    if not skill then return end

    UseSkill(skillKey)

    local hitPart, hitPos  = GetMouseTarget()
    local targetModel      = hitPart and hitPart:FindFirstAncestorOfClass("Model")
    local direction        = (hitPos - Character.PrimaryPart.Position).Unit

    local action = skill.Activate(Character, direction)
    if type(action) == "table" then
        action.target    = targetModel
        action.targetPos = hitPos
        RE_SkillFired:FireServer(action)
    end
end

-- ── Inputs ────────────────────────────────────────────────────────────────────

-- M1 – Primary
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        FireSkill("primary")
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        FireSkill("secondary")
    elseif input.KeyCode == Enum.KeyCode.E then
        -- Utility skill OR teleporter interaction
        local root = Character and Character:FindFirstChild("HumanoidRootPart")
        if root then
            -- Check if near teleporter
            for _, obj in ipairs(game:GetService("CollectionService"):GetTagged("Teleporter")) do
                if obj.PrimaryPart then
                    local d = (obj.PrimaryPart.Position - root.Position).Magnitude
                    if d <= 8 then
                        RE_TeleActivate:FireServer()
                        return
                    end
                elseif obj:IsA("BasePart") then
                    local d = (obj.Position - root.Position).Magnitude
                    if d <= 8 then
                        RE_TeleActivate:FireServer()
                        return
                    end
                end
            end
        end
        FireSkill("utility")

    elseif input.KeyCode == Enum.KeyCode.R then
        FireSkill("special")

    elseif input.KeyCode == Enum.KeyCode.Space then
        -- Extra jumps (Hopoo Feather)
        if Humanoid and not State.isGrounded then
            local stats = RF_GetStats:InvokeServer()
            local extra = (stats and stats.extraJumps) or 0
            if State.currentJumps < extra then
                State.currentJumps = State.currentJumps + 1
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- ── Ammo pack resets skill stocks (Bandolier) ─────────────────────────────────

RE_AmmoPackDropped.OnClientEvent:Connect(function()
    -- Reset all skill stocks
    if SurvivorDef then
        for key, skill in pairs(SurvivorDef.skills) do
            State.cooldowns[key] = 0
            State.stocks[key]    = skill.stockMax or 1
        end
    end
end)

-- ── Expose state for HUD ──────────────────────────────────────────────────────

_G.RoR2_ControllerState = State
_G.RoR2_SurvivorDef     = SurvivorDef

print("[CharacterController] Loaded for " .. CHOSEN_SURVIVOR)
