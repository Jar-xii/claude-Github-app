-- CameraController.client.lua (LocalScript – StarterPlayerScripts)
-- Third-person over-the-shoulder camera, matching RoR2's perspective.

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player    = Players.LocalPlayer
local Camera    = workspace.CurrentCamera

-- ── Settings ──────────────────────────────────────────────────────────────────

local CAM = {
    distance    = 18,     -- studs behind the character
    height      = 5,      -- studs above character root
    pitch       = 15,     -- default vertical angle (degrees)
    minPitch    = -30,
    maxPitch    = 60,
    sensitivity = 0.3,    -- mouse sensitivity
    smoothing   = 0.12,   -- lerp factor (lower = smoother)
    lockCenter  = false,  -- true when in "aim mode"
}

local currentYaw   = 0
local currentPitch = CAM.pitch
local targetYaw    = 0
local targetPitch  = CAM.pitch

-- ── Lock mouse ────────────────────────────────────────────────────────────────

UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
Camera.CameraType = Enum.CameraType.Scriptable

-- ── Input ─────────────────────────────────────────────────────────────────────

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        targetYaw   = targetYaw   - input.Delta.X * CAM.sensitivity
        targetPitch = math.clamp(
            targetPitch - input.Delta.Y * CAM.sensitivity,
            CAM.minPitch, CAM.maxPitch
        )
    end
end)

-- ── Update loop ───────────────────────────────────────────────────────────────

RunService.RenderStepped:Connect(function()
    local character = Player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Smooth rotation
    currentYaw   = currentYaw   + (targetYaw   - currentYaw)   * CAM.smoothing
    currentPitch = currentPitch + (targetPitch - currentPitch) * CAM.smoothing

    -- Camera position calculation
    local yawRad   = math.rad(currentYaw)
    local pitchRad = math.rad(currentPitch)

    local offset = Vector3.new(
        -math.sin(yawRad) * math.cos(pitchRad),
        math.sin(pitchRad),
        -math.cos(yawRad) * math.cos(pitchRad)
    ) * CAM.distance

    local lookTarget = root.Position + Vector3.new(0, CAM.height * 0.3, 0)
    local camPos     = lookTarget + Vector3.new(0, CAM.height, 0) + offset

    -- Collision nudge (keep camera from clipping through walls)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { character }
    params.FilterType = Enum.RaycastFilterType.Exclude

    local rayDir = camPos - lookTarget
    local result = workspace:Raycast(lookTarget, rayDir, params)
    if result then
        camPos = result.Position - rayDir.Unit * 0.5
    end

    Camera.CFrame = CFrame.lookAt(camPos, lookTarget)

    -- Rotate character to face camera yaw
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
        -- Face movement direction
        local movDir = humanoid.MoveDirection
        root.CFrame  = CFrame.new(root.Position) * CFrame.Angles(0, math.atan2(-movDir.X, -movDir.Z), 0)
    else
        -- Face camera direction when idle
        root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(currentYaw), 0)
    end
end)

print("[CameraController] Loaded.")
