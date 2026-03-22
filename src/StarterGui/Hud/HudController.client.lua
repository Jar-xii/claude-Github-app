-- HudController.client.lua (LocalScript – StarterGui/Hud)
-- Drives the RoR2-style HUD: health bar, shield bar, skill icons + cooldowns,
-- item list, difficulty timer, teleporter charge, damage numbers.

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Gui    = script.Parent  -- ScreenGui (set Parent in Studio)

-- Wait for remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if not Remotes then error("[HudController] Remotes not found") end

local RF_GetStats      = Remotes:WaitForChild("GetStats")
local RF_GetRunTime    = Remotes:WaitForChild("GetRunTime")
local RE_ItemGranted   = Remotes:WaitForChild("ItemGranted")
local RE_DamageNumber  = Remotes:WaitForChild("DamageNumber")
local RE_TeleCharge    = Remotes:WaitForChild("TeleporterCharge")
local RE_TeleActivated = Remotes:WaitForChild("TeleporterActivated")
local RE_TeleComplete  = Remotes:WaitForChild("TeleporterComplete")
local RE_StageChanged  = Remotes:WaitForChild("StageChanged")

-- ── UI references (created programmatically so no Studio layout required) ────

local function makeFrame(parent, name, size, pos, color, transparency)
    local f = Instance.new("Frame")
    f.Name              = name
    f.Size              = size
    f.Position          = pos
    f.BackgroundColor3  = color or Color3.new(0, 0, 0)
    f.BackgroundTransparency = transparency or 0
    f.BorderSizePixel   = 0
    f.Parent            = parent
    return f
end

local function makeLabel(parent, name, text, size, pos, color)
    local l = Instance.new("TextLabel")
    l.Name              = name
    l.Text              = text
    l.Size              = size
    l.Position          = pos
    l.BackgroundTransparency = 1
    l.TextColor3        = color or Color3.new(1, 1, 1)
    l.Font              = Enum.Font.GothamBold
    l.TextScaled        = true
    l.Parent            = parent
    return l
end

-- ── Build layout ──────────────────────────────────────────────────────────────

-- Bottom-left: health + shield
local HealthPanel = makeFrame(Gui, "HealthPanel",
    UDim2.new(0, 300, 0, 60),
    UDim2.new(0, 20, 1, -90),
    Color3.fromRGB(10, 10, 10), 0.3
)

local HPBarBG = makeFrame(HealthPanel, "HPBarBG",
    UDim2.new(1, -10, 0, 20),
    UDim2.new(0, 5, 0, 5),
    Color3.fromRGB(20, 20, 20)
)
local HPBar = makeFrame(HPBarBG, "HPBar",
    UDim2.new(1, 0, 1, 0),
    UDim2.new(0, 0, 0, 0),
    Color3.fromRGB(0, 200, 80)
)
local ShieldBar = makeFrame(HPBarBG, "ShieldBar",
    UDim2.new(0, 0, 1, 0),
    UDim2.new(0, 0, 0, 0),
    Color3.fromRGB(100, 200, 255)
)
ShieldBar.ZIndex = 3

local HPLabel = makeLabel(HealthPanel, "HPLabel", "110 / 110",
    UDim2.new(1, -10, 0, 18),
    UDim2.new(0, 5, 0, 28),
    Color3.fromRGB(220, 220, 220)
)

-- Bottom-center: skill icons
local SkillPanel = makeFrame(Gui, "SkillPanel",
    UDim2.new(0, 260, 0, 70),
    UDim2.new(0.5, -130, 1, -80),
    Color3.fromRGB(10, 10, 10), 0.3
)

local SKILL_KEYS  = {"primary", "secondary", "utility", "special"}
local SKILL_BINDS = {"M1", "M2", "E", "R"}
local SkillIcons  = {}
for i, key in ipairs(SKILL_KEYS) do
    local icon = makeFrame(SkillPanel, key,
        UDim2.new(0, 55, 0, 55),
        UDim2.new(0, 5 + (i-1)*62, 0, 5),
        Color3.fromRGB(30, 30, 30)
    )
    local bindLabel = makeLabel(icon, "Bind", SKILL_BINDS[i],
        UDim2.new(1, 0, 0, 12),
        UDim2.new(0, 0, 1, -14),
        Color3.fromRGB(180, 180, 180)
    )
    local cdOverlay = makeFrame(icon, "CDOverlay",
        UDim2.new(1, 0, 0, 0),
        UDim2.new(0, 0, 1, 0),
        Color3.fromRGB(0, 0, 0), 0.6
    )
    cdOverlay.ZIndex = 5
    local cdLabel = makeLabel(cdOverlay, "CDLabel", "",
        UDim2.new(1, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        Color3.fromRGB(255, 255, 255)
    )
    cdLabel.ZIndex = 6
    SkillIcons[key] = { frame = icon, overlay = cdOverlay, label = cdLabel }
end

-- Top-right: run timer + difficulty
local TimerPanel = makeFrame(Gui, "TimerPanel",
    UDim2.new(0, 180, 0, 50),
    UDim2.new(1, -190, 0, 10),
    Color3.fromRGB(10, 10, 10), 0.4
)
local TimerLabel = makeLabel(TimerPanel, "Timer", "00:00",
    UDim2.new(1, 0, 0.6, 0),
    UDim2.new(0, 0, 0, 0),
    Color3.fromRGB(255, 240, 180)
)
local DiffLabel = makeLabel(TimerPanel, "Diff", "Rainstorm",
    UDim2.new(1, 0, 0.4, 0),
    UDim2.new(0, 0, 0.6, 0),
    Color3.fromRGB(200, 200, 200)
)

-- Bottom-right: item list
local ItemPanel = makeFrame(Gui, "ItemPanel",
    UDim2.new(0, 260, 0, 80),
    UDim2.new(1, -270, 1, -100),
    Color3.fromRGB(10, 10, 10), 0.4
)
local ItemListLabel = makeLabel(ItemPanel, "ItemList", "No items",
    UDim2.new(1, -8, 1, -8),
    UDim2.new(0, 4, 0, 4),
    Color3.fromRGB(220, 220, 220)
)
ItemListLabel.TextXAlignment = Enum.TextXAlignment.Left
ItemListLabel.TextYAlignment = Enum.TextYAlignment.Top
ItemListLabel.TextWrapped    = true

-- Center: teleporter charge bar (hidden until activated)
local TelePanel = makeFrame(Gui, "TelePanel",
    UDim2.new(0, 300, 0, 30),
    UDim2.new(0.5, -150, 0, 10),
    Color3.fromRGB(10, 10, 10), 0.5
)
TelePanel.Visible = false

local TeleBarBG = makeFrame(TelePanel, "TeleBG",
    UDim2.new(1, -10, 0, 16),
    UDim2.new(0, 5, 0, 5),
    Color3.fromRGB(20, 20, 20)
)
local TeleBar = makeFrame(TeleBarBG, "TeleBar",
    UDim2.new(0, 0, 1, 0),
    UDim2.new(0, 0, 0, 0),
    Color3.fromRGB(0, 220, 200)
)
local TeleLabel = makeLabel(TelePanel, "TeleLabel", "TELEPORTER: 0%",
    UDim2.new(1, 0, 0.4, 0),
    UDim2.new(0, 0, 0, 18),
    Color3.fromRGB(255, 255, 255)
)

-- Stage notification
local StageLabel = makeLabel(Gui, "StageLabel", "",
    UDim2.new(0, 400, 0, 50),
    UDim2.new(0.5, -200, 0, 80),
    Color3.fromRGB(255, 230, 100)
)
StageLabel.BackgroundTransparency = 1
StageLabel.TextStrokeTransparency = 0.5
StageLabel.ZIndex = 10

-- ── Item inventory tracking (client-side mirror) ──────────────────────────────

local OwnedItems = {}   -- { [itemId] = { name=, count=, tier= } }

RE_ItemGranted.OnClientEvent:Connect(function(grantedPlayer, itemId, count, itemName, tier)
    if grantedPlayer ~= Player then return end
    OwnedItems[itemId] = { name = itemName, count = count, tier = tier }

    -- Rebuild label
    local lines = {}
    for _, data in pairs(OwnedItems) do
        if data.count > 0 then
            lines[#lines + 1] = string.format("×%d %s", data.count, data.name)
        end
    end
    table.sort(lines)
    ItemListLabel.Text = #lines > 0 and table.concat(lines, "\n") or "No items"
end)

-- ── Damage number popups ─────────────────────────────────────────────────────

RE_DamageNumber.OnClientEvent:Connect(function(target, amount, isCrit)
    -- Find world position of the target
    local part = nil
    if typeof(target) == "Instance" then
        part = target:IsA("BasePart") and target
            or target:FindFirstChild("HumanoidRootPart")
    end
    if not part then return end

    local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position + Vector3.new(0, 2, 0))
    if not onScreen then return end

    local label = Instance.new("TextLabel")
    label.Size              = UDim2.new(0, 80, 0, 30)
    label.Position          = UDim2.new(0, screenPos.X - 40, 0, screenPos.Y - 15)
    label.BackgroundTransparency = 1
    label.Text              = tostring(math.floor(amount))
    label.TextColor3        = isCrit and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 255, 255)
    label.Font              = isCrit and Enum.Font.GothamBlack or Enum.Font.GothamBold
    label.TextSize          = isCrit and 22 or 16
    label.TextStrokeTransparency = 0.4
    label.ZIndex            = 20
    label.Parent            = Gui

    -- Float upward and fade out
    TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, screenPos.X - 40, 0, screenPos.Y - 60),
        TextTransparency = 1,
        TextStrokeTransparency = 1,
    }):Play()
    game:GetService("Debris"):AddItem(label, 1.1)
end)

-- ── Teleporter events ─────────────────────────────────────────────────────────

RE_TeleActivated.OnClientEvent:Connect(function()
    TelePanel.Visible = true
end)

RE_TeleCharge.OnClientEvent:Connect(function(progress)
    TeleBar.Size    = UDim2.new(progress, 0, 1, 0)
    TeleLabel.Text  = string.format("TELEPORTER: %d%%", math.floor(progress * 100))
end)

RE_TeleComplete.OnClientEvent:Connect(function()
    TeleLabel.Text  = "STAGE CLEAR!"
    TeleBar.Color   = Color3.fromRGB(255, 220, 0)
    task.delay(3, function() TelePanel.Visible = false end)
end)

-- ── Stage name popup ──────────────────────────────────────────────────────────

RE_StageChanged.OnClientEvent:Connect(function(stageNum, stageName)
    StageLabel.Text = string.format("Stage %d — %s", stageNum, tostring(stageName))
    StageLabel.TextTransparency = 0
    TweenService:Create(StageLabel, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 2), {
        TextTransparency = 1,
    }):Play()
end)

-- ── Main update loop ──────────────────────────────────────────────────────────

local STATS_POLL_RATE   = 0.25  -- seconds between stat fetches
local lastStatsFetch    = 0

RunService.RenderStepped:Connect(function()
    local now = tick()

    -- Fetch stats periodically
    if (now - lastStatsFetch) >= STATS_POLL_RATE then
        lastStatsFetch = now

        local stats = RF_GetStats:InvokeServer()
        if stats then
            -- Health bar
            local hpFrac = math.clamp((stats.currentHP or stats.maxHP) / stats.maxHP, 0, 1)
            HPBar.Size   = UDim2.new(hpFrac, 0, 1, 0)

            local shieldFrac = 0
            if stats.shield and stats.shield > 0 then
                shieldFrac = math.clamp((stats.currentShield or 0) / stats.shield, 0, 1)
            end
            ShieldBar.Size = UDim2.new(shieldFrac * hpFrac, 0, 1, 0)

            HPLabel.Text = string.format("%d / %d HP", stats.currentHP or stats.maxHP, stats.maxHP)
        end
    end

    -- Timer
    local runTime = RF_GetRunTime:InvokeServer()
    if runTime then
        local m = math.floor(runTime / 60)
        local s = math.floor(runTime % 60)
        TimerLabel.Text = string.format("%02d:%02d", m, s)
    end

    -- Skill cooldowns (read from CharacterController shared state)
    local ctrlState = _G.RoR2_ControllerState
    local survivorDef = _G.RoR2_SurvivorDef
    if ctrlState and survivorDef then
        for _, key in ipairs(SKILL_KEYS) do
            local icon   = SkillIcons[key]
            local skill  = survivorDef.skills[key]
            if not icon or not skill then continue end

            local cd      = skill.cooldown or 0
            local elapsed = tick() - (ctrlState.cooldowns[key] or 0)
            local remaining = math.max(cd - elapsed, 0)

            if remaining > 0 then
                local frac = 1 - (remaining / cd)
                icon.overlay.Size     = UDim2.new(1, 0, 1 - frac, 0)
                icon.overlay.Position = UDim2.new(0, 0, frac, 0)
                icon.label.Text       = string.format("%.1f", remaining)
            else
                icon.overlay.Size = UDim2.new(0, 0, 0, 0)
                icon.label.Text   = ""
            end
        end
    end
end)

print("[HudController] Loaded.")
