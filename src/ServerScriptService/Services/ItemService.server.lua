-- ItemService.server.lua (Script – ServerScriptService)
-- Handles item orb drops, chest interaction, and pickup grants.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Modules       = ReplicatedStorage:WaitForChild("Modules")
local GameConstants = require(Modules:WaitForChild("GameConstants"))
local ItemRegistry  = require(Modules:WaitForChild("ItemRegistry"))
local Util          = require(Modules:WaitForChild("Util"))

repeat task.wait(0.1) until _G.RoR2_RunState and _G.RoR2_Remotes
local RunState = _G.RoR2_RunState
local Remotes  = _G.RoR2_Remotes

local Remotes2  = ReplicatedStorage:WaitForChild("Remotes")

-- ── RemoteEvent for player requesting pickup ──────────────────────────────────
local RE_PickupItem = Instance.new("RemoteEvent")
RE_PickupItem.Name   = "PickupItem"
RE_PickupItem.Parent = Remotes2

-- ── Grant an item to a player ─────────────────────────────────────────────────

local function GrantItem(player, itemId)
    local pd = RunState.playerData[player]
    if not pd then return false end

    pd.stats:AddItem(itemId)

    local item = ItemRegistry.Get(itemId)
    local stackCount = pd.stats:GetItemCount(itemId)

    -- Notify all clients (for scoreboard / item log)
    Remotes.RE_ItemGranted:FireAllClients(player, itemId, stackCount, item.name, item.tier)

    -- Also fire to the owning client with full stat sheet update
    local RF_GetStats = Remotes2:FindFirstChild("GetStats")
    -- Stats will be fetched on next poll — no extra fire needed

    print(string.format("[ItemService] %s received %s (×%d)", player.Name, item.name, stackCount))
    return true
end

-- ── Spawn an item orb in the world ───────────────────────────────────────────

local function SpawnItemOrb(position, itemId)
    local item = ItemRegistry.Get(itemId)
    if not item then return nil end

    local orb  = Instance.new("Part")
    orb.Name   = "ItemOrb_" .. itemId
    orb.Size   = Vector3.new(1.5, 1.5, 1.5)
    orb.Shape  = Enum.PartType.Ball
    orb.CFrame = CFrame.new(position)
    orb.Anchored = true

    -- Colour by tier
    local tierColors = {
        [GameConstants.ITEM_TIER.COMMON]    = Color3.fromRGB(255, 255, 255),
        [GameConstants.ITEM_TIER.UNCOMMON]  = Color3.fromRGB(0, 255, 0),
        [GameConstants.ITEM_TIER.LEGENDARY] = Color3.fromRGB(255, 215, 0),
        [GameConstants.ITEM_TIER.BOSS]      = Color3.fromRGB(255, 165, 0),
        [GameConstants.ITEM_TIER.LUNAR]     = Color3.fromRGB(0, 200, 255),
        [GameConstants.ITEM_TIER.VOID]      = Color3.fromRGB(100, 0, 150),
    }
    orb.Color = tierColors[item.tier] or Color3.new(1, 1, 1)

    orb.Material = Enum.Material.Neon
    orb.Parent   = workspace

    CollectionService:AddTag(orb, "ItemOrb")
    orb:SetAttribute("ItemId", itemId)

    -- Bobbing animation
    task.spawn(function()
        local t = 0
        local baseY = position.Y
        while orb.Parent do
            t = t + task.wait(0.05)
            orb.CFrame = CFrame.new(position.X, baseY + math.sin(t * 2) * 0.3, position.Z)
        end
    end)

    return orb
end

-- ── Spawn a random item orb (called by DirectorService on kill) ──────────────

function ItemService_DropRandom(position)
    local item = ItemRegistry.RandomDrop()
    if item then
        SpawnItemOrb(position, item.id)
    end
end

-- ── Proximity check: award item when player walks over orb ──────────────────

local PICKUP_RADIUS = GameConstants.SURVIVOR.PICKUP_RADIUS

local function CheckPickups()
    local orbs = CollectionService:GetTagged("ItemOrb")
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        for _, orb in ipairs(orbs) do
            if not orb.Parent then continue end
            local dist = (orb.Position - root.Position).Magnitude
            if dist <= PICKUP_RADIUS then
                local itemId = orb:GetAttribute("ItemId")
                if itemId then
                    orb:Destroy()
                    GrantItem(player, itemId)
                end
            end
        end
    end
end

-- Run proximity check at 10 Hz
task.spawn(function()
    while true do
        task.wait(0.1)
        if RunState.active then
            CheckPickups()
        end
    end
end)

-- ── Chest interaction ─────────────────────────────────────────────────────────
-- Chests are Parts tagged "Chest" in the map with an attribute "Cost".
-- Players pay gold, receive a random item of the appropriate tier.

local function OpenChest(player, chest)
    local pd = RunState.playerData[player]
    if not pd then return end

    local cost = chest:GetAttribute("Cost") or 25
    if pd.goldCollected < cost then return end

    pd.goldCollected = pd.goldCollected - cost
    chest:SetAttribute("Opened", true)
    CollectionService:RemoveTag(chest, "Chest")

    -- Determine tier from chest type attribute
    local chestTier = chest:GetAttribute("Tier") or GameConstants.ITEM_TIER.COMMON
    local tierPool  = ItemRegistry.GetByTier(chestTier)
    if #tierPool == 0 then return end
    local item = tierPool[math.random(#tierPool)]

    SpawnItemOrb(chest.Position + Vector3.new(0, 2, 0), item.id)

    -- Visual: darken the chest
    if chest:IsA("BasePart") then
        chest.Color = Color3.fromRGB(50, 50, 50)
    end
end

-- Listen for chest interaction events from CharacterController
RE_PickupItem.OnServerEvent:Connect(function(player, chestOrOrb)
    if not chestOrOrb then return end
    if CollectionService:HasTag(chestOrOrb, "Chest") then
        OpenChest(player, chestOrOrb)
    end
end)

-- Expose publicly
_G.RoR2_ItemService = {
    GrantItem   = GrantItem,
    SpawnItemOrb = SpawnItemOrb,
    DropRandom  = ItemService_DropRandom,
}

print("[ItemService] Loaded successfully.")
