
-- FPS TRAINING DEBUG CLIENT
-- Roblox Studio LocalScript
-- Location: StarterPlayer > StarterPlayerScripts
-- Targets NPC models tagged "TrainingBot" only.
-- No executor, obfuscation, or anti-cheat bypass.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CONFIG = {
    BotTag = "TrainingBot",
    UpdateRate = 0.05,
    AimSmoothness = 8,
    AimRange = 250,
    ShowHitboxes = true,
    ShowHealth = true,
    ShowDistance = true,
}

local running = true
local showVisuals = true
local aimEnabled = false
local elapsed = 0
local frameCount = 0
local fps = 0
local botData = {}

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "FPSBotDebug"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(230, 220)
panel.Position = UDim2.fromOffset(16, 100)
panel.BackgroundColor3 = Color3.fromRGB(22, 27, 40)
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Parent = gui

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 180, 255)
stroke.Transparency = 0.35
stroke.Parent = panel

local function makeLabel(text, y)
    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(12, y)
    label.Size = UDim2.new(1, -24, 0, 22)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(235, 240, 255)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = panel
    return label
end

makeLabel("NPC FPS TRAINING", 8).Font = Enum.Font.GothamBold
local fpsLabel = makeLabel("FPS: --", 32)
local targetLabel = makeLabel("Target: none", 54)

local function makeButton(name, text, y)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Position = UDim2.fromOffset(10, y)
    button.Size = UDim2.new(1, -20, 0, 29)
    button.BackgroundColor3 = Color3.fromRGB(43, 57, 78)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.Parent = panel

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
    return button
end

local visualButton = makeButton("Visuals", "VISUALS: ON", 82)
local hitboxButton = makeButton("Hitboxes", "HITBOXES: ON", 115)
local aimButton = makeButton("AimAssist", "NPC AIM ASSIST: OFF", 148)
local distanceButton = makeButton("Distance", "DISTANCE: ON", 181)

visualButton.Activated:Connect(function()
    showVisuals = not showVisuals
    visualButton.Text = showVisuals and "VISUALS: ON" or "VISUALS: OFF"
end)

hitboxButton.Activated:Connect(function()
    CONFIG.ShowHitboxes = not CONFIG.ShowHitboxes
    hitboxButton.Text = CONFIG.ShowHitboxes and
        "HITBOXES: ON" or "HITBOXES: OFF"
end)

aimButton.Activated:Connect(function()
    aimEnabled = not aimEnabled
    aimButton.Text = aimEnabled and
        "NPC AIM ASSIST: ON" or "NPC AIM ASSIST: OFF"
end)

distanceButton.Activated:Connect(function()
    CONFIG.ShowDistance = not CONFIG.ShowDistance
    distanceButton.Text = CONFIG.ShowDistance and
        "DISTANCE: ON" or "DISTANCE: OFF"
end)

-- Drag panel on touch or mouse
local dragging = false
local dragStart
local startPosition

panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = panel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement
    ) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Bot visuals
local function removeBot(model)
    local data = botData[model]
    if not data then return end

    for _, object in pairs(data) do
        if typeof(object) == "Instance" then
            object:Destroy()
        end
    end

    botData[model] = nil
end

local function addBot(model)
    if not model:IsA("Model") or botData[model] then
        return
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or not root:IsA("BasePart") then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "TrainingBotHighlight"
    highlight.Adornee = model
    highlight.FillColor = Color3.fromRGB(50, 160, 255)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.88
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Enabled = false
    highlight.Parent = gui

    local hitbox = Instance.new("SelectionBox")
    hitbox.Name = "TrainingBotHitbox"
    hitbox.Adornee = root
    hitbox.Color3 = Color3.fromRGB(255, 190, 50)
    hitbox.LineThickness = 0.05
    hitbox.Visible = false
    hitbox.Parent = gui

    local healthGui = Instance.new("BillboardGui")
    healthGui.Name = "TrainingBotHealth"
    healthGui.Adornee = root
    healthGui.Size = UDim2.fromOffset(100, 14)
    healthGui.StudsOffset = Vector3.new(0, 3.1, 0)
    healthGui.AlwaysOnTop = true
    healthGui.Enabled = false
    healthGui.Parent = gui

    local healthBack = Instance.new("Frame")
    healthBack.Size = UDim2.fromScale(1, 1)
    healthBack.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    healthBack.BorderSizePixel = 0
    healthBack.Parent = healthGui
    Instance.new("UICorner", healthBack).CornerRadius = UDim.new(0, 4)

    local healthFill = Instance.new("Frame")
    healthFill.Name = "Fill"
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.BackgroundColor3 = Color3.fromRGB(50, 225, 115)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBack
    Instance.new("UICorner", healthFill).CornerRadius = UDim.new(0, 4)

    local distanceGui = Instance.new("BillboardGui")
    distanceGui.Name = "TrainingBotDistance"
    distanceGui.Adornee = root
    distanceGui.Size = UDim2.fromOffset(120, 22)
    distanceGui.StudsOffset = Vector3.new(0, 4, 0)
    distanceGui.AlwaysOnTop = true
    distanceGui.Enabled = false
    distanceGui.Parent = gui

    local distanceText = Instance.new("TextLabel")
    distanceText.Size = UDim2.fromScale(1, 1)
    distanceText.BackgroundTransparency = 1
    distanceText.TextColor3 = Color3.new(1, 1, 1)
    distanceText.TextStrokeTransparency = 0.25
    distanceText.Font = Enum.Font.GothamBold
    distanceText.TextSize = 13
    distanceText.Text = "-- studs"
    distanceText.Parent = distanceGui

    botData[model] = {
        humanoid = humanoid,
        root = root,
        highlight = highlight,
        hitbox = hitbox,
        healthGui = healthGui,
        healthFill = healthFill,
        distanceGui = distanceGui,
        distanceText = distanceText,
    }
end

-- Initial NPC discovery and tag monitoring
for _, instance in ipairs(CollectionService:GetTagged(CONFIG.BotTag)) do
    addBot(instance)
end

CollectionService:GetInstanceAddedSignal(CONFIG.BotTag):Connect(addBot)
CollectionService:GetInstanceRemovedSignal(CONFIG.BotTag):Connect(removeBot)

-- Aim target selection: tagged NPCs only
local function findNearestBot()
    local character = player.Character
    local myRoot = character and character:FindFirstChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera

    if not myRoot or not camera then
        return nil
    end

    local bestModel = nil
    local bestScore = math.huge

    for model, data in pairs(botData) do
        if model.Parent and data.root.Parent
            and data.humanoid.Health > 0 then

            local offset = data.root.Position - myRoot.Position
            local distance = offset.Magnitude

            if distance <= CONFIG.AimRange then
                local part = model:FindFirstChild("Head") or data.root
                local screenPoint, onScreen =
                    camera:WorldToViewportPoint(part.Position)

                if onScreen and screenPoint.Z > 0 then
                    local center = camera.ViewportSize / 2
                    local screenDistance = (
                        Vector2.new(screenPoint.X, screenPoint.Y) - center
                    ).Magnitude

                    if screenDistance < bestScore then
                        bestScore = screenDistance
                        bestModel = model
                    end
                end
            end
        end
    end

    return bestModel
end

-- Main update
local updateAccumulator = 0

local connection = RunService.Heartbeat:Connect(function(dt)
    if not running then return end

    frameCount += 1
    elapsed += dt
    updateAccumulator += dt

    if elapsed >= 1 then
        fps = math.floor(frameCount / elapsed + 0.5)
        fpsLabel.Text = ("FPS: %d"):format(fps)
        frameCount = 0
        elapsed = 0
    end

    if updateAccumulator < CONFIG.UpdateRate then
        return
    end
    updateAccumulator = 0

    local character = player.Character
    local myRoot = character and character:FindFirstChild("HumanoidRootPart")

    for model, data in pairs(botData) do
        if not model.Parent or not data.root.Parent
            or not data.humanoid.Parent then
            removeBot(model)
            continue
        end

        local alive = data.humanoid.Health > 0
        local enabled = showVisuals and alive

        data.highlight.Enabled = enabled
        data.hitbox.Visible = enabled and CONFIG.ShowHitboxes
        data.healthGui.Enabled = enabled and CONFIG.ShowHealth
        data.distanceGui.Enabled = enabled and CONFIG.ShowDistance

        local ratio = math.clamp(
            data.humanoid.Health /
                math.max(data.humanoid.MaxHealth, 1),
            0, 1
        )

        data.healthFill.Size = UDim2.fromScale(ratio, 1)
        data.healthFill.BackgroundColor3 = Color3.fromRGB(
            math.floor(230 * (1 - ratio) + 45 * ratio),
            math.floor(65 * (1 - ratio) + 220 * ratio),
            80
        )

        if myRoot then
            local distance = (myRoot.Position - data.root.Position).Magnitude
            data.distanceText.Text =
                ("%d studs"):format(math.floor(distance + 0.5))
        end
    end

    -- NPC-only camera aim assist for training.
    if aimEnabled then
        local target = findNearestBot()
        local camera = workspace.CurrentCamera

        if target and camera then
            local data = botData[target]
            local part = target:FindFirstChild("Head")
                or (data and data.root)

            if part then
                local desired = CFrame.lookAt(
                    camera.CFrame.Position,
                    part.Position
                )

                local alpha = 1 - math.exp(
                    -CONFIG.AimSmoothness * CONFIG.UpdateRate
                )

                camera.CFrame = camera.CFrame:Lerp(desired, alpha)
                targetLabel.Text = "Target: " .. target.Name
            end
        else
            targetLabel.Text = "Target: none"
        end
    else
        targetLabel.Text = "Target: none"
    end
end)

-- Cleanup if this LocalScript is destroyed
script.Destroying:Connect(function()
    running = false
    connection:Disconnect()

    for model in pairs(botData) do
        removeBot(model)
    end

    gui:Destroy()
end)

print("FPS training debug client loaded.")
