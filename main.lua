--!strict
-- TrainingTargetHUD_Combined.client.lua
-- Put this single LocalScript in StarterPlayer > StarterPlayerScripts.
-- Local-only practice aid for NPCs tagged with CollectionService tag "TrainingTarget".

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local TrainingTargetHUD = {}

local BIND_NAME = "TrainingTargetHUD_Render"
local DEFAULTS = {
    TargetTag = "TrainingTarget",
    MaxTargetDistance = 500,
    MaxFOVPixels = 280,
    ScanInterval = 0.12, -- expensive target scan / raycasts are throttled
    AimResponsiveness = 9, -- higher = stronger smoothing response
    RequireLineOfSight = true,
    AimEnabled = false,
    OverlayEnabled = true,
}

local config: {[string]: any} = table.clone(DEFAULTS)
local started = false
local aimEnabled = config.AimEnabled
local overlayEnabled = config.OverlayEnabled
local aimHeld = false
local uiVisible = true
local activeTab = "Overview"
local scanAccumulator = 0
local targetCache: {Instance} = {}
local currentTarget: Model? = nil
local visibilityCache: {[Model]: boolean} = {}
local targetVisuals: {[Model]: any} = {}
local connections: {RBXScriptConnection} = {}

local screenGui: ScreenGui? = nil
local mainPanel: Frame? = nil
local statusLabel: TextLabel? = nil
local overviewPage: Frame? = nil
local assistPage: Frame? = nil
local overlayPage: Frame? = nil
local aimButton: TextButton? = nil
local overlayButton: TextButton? = nil
local tabButtons: {[string]: TextButton} = {}

local COLORS = {
    Panel = Color3.fromRGB(18, 24, 36),
    PanelLight = Color3.fromRGB(28, 38, 54),
    Accent = Color3.fromRGB(88, 210, 235),
    Text = Color3.fromRGB(235, 243, 250),
    Muted = Color3.fromRGB(155, 174, 194),
    Green = Color3.fromRGB(75, 225, 145),
    Red = Color3.fromRGB(255, 105, 115),
}

local function addCorner(instance: Instance, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
end

local function addStroke(instance: Instance, color: Color3?, transparency: number?)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or COLORS.Accent
    stroke.Transparency = transparency or 0.45
    stroke.Thickness = 1
    stroke.Parent = instance
    return stroke
end

local function createText(parent: Instance, name: string, text: string, size: UDim2, position: UDim2, fontSize: number)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Size = size
    label.Position = position
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextSize = fontSize
    label.TextColor3 = COLORS.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

local function createButton(parent: Instance, name: string, text: string, size: UDim2, position: UDim2)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = COLORS.PanelLight
    button.BackgroundTransparency = 0.12
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamMedium
    button.Text = text
    button.TextSize = 12
    button.TextColor3 = COLORS.Text
    button.AutoButtonColor = true
    button.Parent = parent
    addCorner(button, 8)
    addStroke(button, COLORS.Accent, 0.78)
    return button
end

local function setPage(tabName: string)
    activeTab = tabName
    if overviewPage then overviewPage.Visible = tabName == "Overview" end
    if assistPage then assistPage.Visible = tabName == "Assist" end
    if overlayPage then overlayPage.Visible = tabName == "Overlay" end

    for name, button in pairs(tabButtons) do
        button.BackgroundTransparency = (name == tabName) and 0.02 or 0.35
        button.TextColor3 = (name == tabName) and COLORS.Accent or COLORS.Muted
    end
end

local function refreshButtonText()
    if aimButton then
        aimButton.Text = "Aim assist: " .. (aimEnabled and "ON" or "OFF")
        aimButton.TextColor3 = aimEnabled and COLORS.Green or COLORS.Text
    end
    if overlayButton then
        overlayButton.Text = "3D box + health: " .. (overlayEnabled and "ON" or "OFF")
        overlayButton.TextColor3 = overlayEnabled and COLORS.Green or COLORS.Text
    end
end

local function buildGui()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    local old = playerGui:FindFirstChild("TrainingTargetHUD")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "TrainingTargetHUD"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 40
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui
    screenGui = gui

    local panel = Instance.new("Frame")
    panel.Name = "MainPanel"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.53)
    panel.Size = UDim2.fromOffset(450, 310)
    panel.BackgroundColor3 = COLORS.Panel
    panel.BackgroundTransparency = 0.13 -- translucent glass-like base
    panel.BorderSizePixel = 0
    panel.Parent = gui
    mainPanel = panel
    addCorner(panel, 16)
    addStroke(panel, Color3.fromRGB(145, 225, 245), 0.48)

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 58, 78)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 19, 30)),
    })
    gradient.Rotation = 35
    gradient.Parent = panel

    createText(panel, "Title", "TRAINING  /  TARGET HUD", UDim2.new(1, -100, 0, 34), UDim2.fromOffset(18, 10), 15)
    local subtitle = createText(panel, "Subtitle", "PRACTICE MODE  •  TAGGED NPCs ONLY", UDim2.new(1, -34, 0, 18), UDim2.fromOffset(18, 38), 9)
    subtitle.TextColor3 = COLORS.Muted

    local closeButton = createButton(panel, "HideButton", "—", UDim2.fromOffset(32, 28), UDim2.new(1, -48, 0, 12))
    closeButton.TextSize = 16
    closeButton.Activated:Connect(function()
        uiVisible = false
        panel.Visible = false
    end)

    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.BackgroundTransparency = 1
    tabBar.Position = UDim2.fromOffset(18, 66)
    tabBar.Size = UDim2.new(1, -36, 0, 32)
    tabBar.Parent = panel

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabBar

    for index, tabName in ipairs({ "Overview", "Assist", "Overlay" }) do
        local tab = createButton(tabBar, tabName .. "Tab", tabName, UDim2.fromOffset(112, 30), UDim2.new())
        tab.LayoutOrder = index
        tabButtons[tabName] = tab
        tab.Activated:Connect(function() setPage(tabName) end)
    end

    local pages = Instance.new("Frame")
    pages.Name = "Pages"
    pages.Position = UDim2.fromOffset(18, 108)
    pages.Size = UDim2.new(1, -36, 1, -124)
    pages.BackgroundColor3 = COLORS.PanelLight
    pages.BackgroundTransparency = 0.42
    pages.BorderSizePixel = 0
    pages.Parent = panel
    addCorner(pages, 10)

    local overview = Instance.new("Frame")
    overview.Name = "OverviewPage"
    overview.Size = UDim2.fromScale(1, 1)
    overview.BackgroundTransparency = 1
    overview.Parent = pages
    overviewPage = overview

    createText(overview, "OverviewHeading", "Practice session", UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 12), 16)
    local overviewText = createText(
        overview,
        "OverviewText",
        "Track only NPC models tagged 'TrainingTarget'.\n\nHold RIGHT MOUSE to use soft aim assist.\nPress RIGHT SHIFT to show or hide this panel.\n\nNo player ESP; occluded targets are hidden when LOS is enabled.",
        UDim2.new(1, -28, 1, -56),
        UDim2.fromOffset(14, 43),
        12
    )
    overviewText.TextColor3 = COLORS.Muted
    overviewText.TextYAlignment = Enum.TextYAlignment.Top

    local assist = Instance.new("Frame")
    assist.Name = "AssistPage"
    assist.Size = UDim2.fromScale(1, 1)
    assist.BackgroundTransparency = 1
    assist.Visible = false
    assist.Parent = pages
    assistPage = assist

    createText(assist, "AssistHeading", "Aim assistance", UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 10), 16)
    local aimToggle = createButton(assist, "AimToggle", "Aim assist: OFF", UDim2.new(1, -28, 0, 36), UDim2.fromOffset(14, 48))
    aimButton = aimToggle
    aimToggle.Activated:Connect(function()
        aimEnabled = not aimEnabled
        refreshButtonText()
    end)
    local assistHint = createText(assist, "AssistHint", "Selects the closest visible tagged target within the screen FOV.\nThe camera is only eased toward it while RMB is held.", UDim2.new(1, -28, 0, 54), UDim2.fromOffset(14, 94), 11)
    assistHint.TextColor3 = COLORS.Muted
    assistHint.TextYAlignment = Enum.TextYAlignment.Top

    local overlay = Instance.new("Frame")
    overlay.Name = "OverlayPage"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundTransparency = 1
    overlay.Visible = false
    overlay.Parent = pages
    overlayPage = overlay

    createText(overlay, "OverlayHeading", "On-screen target cues", UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 10), 16)
    local overlayToggle = createButton(overlay, "OverlayToggle", "3D box + health: ON", UDim2.new(1, -28, 0, 36), UDim2.fromOffset(14, 48))
    overlayButton = overlayToggle
    overlayToggle.Activated:Connect(function()
        overlayEnabled = not overlayEnabled
        refreshButtonText()
    end)
    local overlayHint = createText(overlay, "OverlayHint", "A projected 3D cuboid, model name, and health bar are drawn only for visible tagged NPCs.", UDim2.new(1, -28, 0, 46), UDim2.fromOffset(14, 94), 11)
    overlayHint.TextColor3 = COLORS.Muted
    overlayHint.TextYAlignment = Enum.TextYAlignment.Top

    local status = createText(panel, "Status", "Targets: 0  •  Current: none", UDim2.new(1, -36, 0, 18), UDim2.new(0, 18, 1, -21), 10)
    status.TextColor3 = COLORS.Muted
    statusLabel = status

    setPage("Overview")
    refreshButtonText()
end

local BOX_EDGES = {
    {1, 2}, {2, 3}, {3, 4}, {4, 1},
    {5, 6}, {6, 7}, {7, 8}, {8, 5},
    {1, 5}, {2, 6}, {3, 7}, {4, 8},
}

local function createVisual(model: Model)
    if targetVisuals[model] then return targetVisuals[model] end

    local parentGui = screenGui
    if not parentGui then return nil end

    local visual: {[string]: any} = { lines = {} }
    for i = 1, #BOX_EDGES do
        local line = Instance.new("Frame")
        line.Name = "BoxEdge" .. i
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Size = UDim2.fromOffset(1, 2)
        line.BackgroundColor3 = COLORS.Accent
        line.BackgroundTransparency = 0.04
        line.BorderSizePixel = 0
        line.Visible = false
        line.ZIndex = 5
        line.Parent = parentGui
        visual.lines[i] = line
    end

    local label = Instance.new("TextLabel")
    label.Name = "TargetLabel"
    label.BackgroundColor3 = COLORS.Panel
    label.BackgroundTransparency = 0.18
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 11
    label.TextColor3 = COLORS.Text
    label.TextStrokeTransparency = 0.8
    label.Size = UDim2.fromOffset(150, 18)
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.Visible = false
    label.ZIndex = 6
    label.Parent = parentGui
    addCorner(label, 4)
    visual.label = label

    local healthTrack = Instance.new("Frame")
    healthTrack.Name = "HealthTrack"
    healthTrack.BackgroundColor3 = Color3.fromRGB(17, 22, 30)
    healthTrack.BackgroundTransparency = 0.12
    healthTrack.BorderSizePixel = 0
    healthTrack.Visible = false
    healthTrack.ZIndex = 6
    healthTrack.Parent = parentGui
    visual.healthTrack = healthTrack

    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.AnchorPoint = Vector2.new(0, 1)
    healthFill.Position = UDim2.new(0, 0, 1, 0)
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.BackgroundColor3 = COLORS.Green
    healthFill.BorderSizePixel = 0
    healthFill.ZIndex = 7
    healthFill.Parent = healthTrack
    visual.healthFill = healthFill

    targetVisuals[model] = visual
    return visual
end

local function hideVisual(visual)
    if not visual then return end
    for _, line in ipairs(visual.lines) do line.Visible = false end
    visual.label.Visible = false
    visual.healthTrack.Visible = false
end

local function destroyVisual(model: Model)
    local visual = targetVisuals[model]
    if not visual then return end
    for _, line in ipairs(visual.lines) do line:Destroy() end
    visual.label:Destroy()
    visual.healthTrack:Destroy()
    targetVisuals[model] = nil
end

local function getHumanoid(model: Model): Humanoid?
    return model:FindFirstChildOfClass("Humanoid")
end

local function getAimPart(model: Model): BasePart?
    local head = model:FindFirstChild("Head")
    if head and head:IsA("BasePart") then return head end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then return root end
    return model.PrimaryPart
end

local function hasLineOfSight(camera: Camera, model: Model, aimPart: BasePart, character: Model?): boolean
    if not config.RequireLineOfSight then return true end
    local origin = camera.CFrame.Position
    local direction = aimPart.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = character and { character } or {}
    params.IgnoreWater = true
    local result = Workspace:Raycast(origin, direction, params)
    return result == nil or result.Instance:IsDescendantOf(model)
end

local function isEligibleModel(instance: Instance): boolean
    if not instance:IsA("Model") or not instance:IsDescendantOf(Workspace) then return false end
    if not CollectionService:HasTag(instance, config.TargetTag) then return false end
    local humanoid = getHumanoid(instance)
    return humanoid ~= nil and humanoid.Health > 0 and getAimPart(instance) ~= nil
end

local function refreshTargets(camera: Camera)
    targetCache = CollectionService:GetTagged(config.TargetTag)
    local character = LocalPlayer.Character
    local rootCandidate = character and character:FindFirstChild("HumanoidRootPart")
    local localRoot: BasePart? = if rootCandidate and rootCandidate:IsA("BasePart") then rootCandidate else nil
    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    local bestModel: Model? = nil
    local bestWorldDistance = math.huge
    visibilityCache = {}

    for _, candidate in ipairs(targetCache) do
        if candidate:IsA("Model") and isEligibleModel(candidate) then
            local model = candidate :: Model
            local humanoid = getHumanoid(model)
            local aimPart = getAimPart(model)
            if humanoid and aimPart then
                local worldDistance = localRoot and (aimPart.Position - localRoot.Position).Magnitude or (aimPart.Position - camera.CFrame.Position).Magnitude
                local projected, onScreen = camera:WorldToViewportPoint(aimPart.Position)
                local screenDistance = (Vector2.new(projected.X, projected.Y) - center).Magnitude
                local inRange = worldDistance <= config.MaxTargetDistance
                local inFov = projected.Z > 0 and onScreen and screenDistance <= config.MaxFOVPixels
                local visible = hasLineOfSight(camera, model, aimPart, character)
                visibilityCache[model] = visible
                if inRange and inFov and visible and worldDistance < bestWorldDistance then
                    bestWorldDistance = worldDistance
                    bestModel = model
                end
            end
        end
    end

    currentTarget = bestModel

    -- Prune visual objects for removed or untagged targets.
    for model in pairs(targetVisuals) do
        if not model.Parent or not CollectionService:HasTag(model, config.TargetTag) then
            destroyVisual(model)
        end
    end
end

local function drawTarget(model: Model, camera: Camera): boolean
    local humanoid = getHumanoid(model)
    if not humanoid or humanoid.Health <= 0 then return false end
    if not visibilityCache[model] then return false end

    local partsCF, partsSize = model:GetBoundingBox()
    local half = partsSize * 0.5
    local localCorners = {
        Vector3.new(-half.X, -half.Y, -half.Z),
        Vector3.new( half.X, -half.Y, -half.Z),
        Vector3.new( half.X,  half.Y, -half.Z),
        Vector3.new(-half.X,  half.Y, -half.Z),
        Vector3.new(-half.X, -half.Y,  half.Z),
        Vector3.new( half.X, -half.Y,  half.Z),
        Vector3.new( half.X,  half.Y,  half.Z),
        Vector3.new(-half.X,  half.Y,  half.Z),
    }

    local points: {Vector2} = {}
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    for i, corner in ipairs(localCorners) do
        local screenPoint = camera:WorldToViewportPoint((partsCF * CFrame.new(corner)).Position)
        if screenPoint.Z <= 0 then return false end
        points[i] = Vector2.new(screenPoint.X, screenPoint.Y)
        minX = math.min(minX, screenPoint.X)
        minY = math.min(minY, screenPoint.Y)
        maxX = math.max(maxX, screenPoint.X)
        maxY = math.max(maxY, screenPoint.Y)
    end

    local viewport = camera.ViewportSize
    if maxX < 0 or maxY < 0 or minX > viewport.X or minY > viewport.Y then return false end

    local visual = createVisual(model)
    if not visual then return false end

    for index, edge in ipairs(BOX_EDGES) do
        local p1 = points[edge[1]]
        local p2 = points[edge[2]]
        local delta = p2 - p1
        local line = visual.lines[index]
        line.Position = UDim2.fromOffset((p1.X + p2.X) * 0.5, (p1.Y + p2.Y) * 0.5)
        line.Size = UDim2.fromOffset(delta.Magnitude, 2)
        line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
        line.Visible = true
    end

    local width = math.clamp(maxX - minX, 26, viewport.X)
    local boxHeight = math.clamp(maxY - minY, 12, viewport.Y)
    local healthRatio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
    visual.label.Text = string.format("%s  •  %d%%", model.Name, math.floor(healthRatio * 100 + 0.5))
    visual.label.Size = UDim2.fromOffset(math.clamp(width, 90, 190), 18)
    visual.label.Position = UDim2.fromOffset(math.clamp((minX + maxX) * 0.5, 50, viewport.X - 50), math.clamp(minY - 3, 20, viewport.Y - 3))
    visual.label.Visible = true

    visual.healthTrack.Position = UDim2.fromOffset(math.clamp(minX - 8, 1, viewport.X - 6), math.clamp(minY, 1, viewport.Y - 2))
    visual.healthTrack.Size = UDim2.fromOffset(4, boxHeight)
    visual.healthTrack.Visible = true
    visual.healthFill.Size = UDim2.new(1, 0, healthRatio, 0)
    visual.healthFill.BackgroundColor3 = Color3.new(1 - healthRatio, 0.25 + 0.65 * healthRatio, 0.18)
    return true
end

local function updateOverlay(camera: Camera, character: Model?)
    if not overlayEnabled then
        for _, visual in pairs(targetVisuals) do hideVisual(visual) end
        return
    end

    local seen: {[Model]: boolean} = {}
    for _, instance in ipairs(targetCache) do
        if instance:IsA("Model") and isEligibleModel(instance) then
            local model = instance :: Model
            seen[model] = true
            local ok, drawn = pcall(drawTarget, model, camera)
            if not ok or not drawn then hideVisual(targetVisuals[model]) end
        end
    end

    for model, visual in pairs(targetVisuals) do
        if not seen[model] then hideVisual(visual) end
    end
end

local function updateStatus()
    if not statusLabel then return end
    local activeCount = 0
    for _, instance in ipairs(targetCache) do
        if isEligibleModel(instance) then activeCount += 1 end
    end
    local targetName = currentTarget and currentTarget.Name or "none"
    statusLabel.Text = string.format("Targets: %d  •  Current: %s", activeCount, targetName)
end

local function onRenderStep(deltaTime: number)
    if not started then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end

    scanAccumulator += deltaTime
    if scanAccumulator >= config.ScanInterval then
        scanAccumulator %= config.ScanInterval
        refreshTargets(camera)
        updateStatus()
    end

    local character = LocalPlayer.Character
    updateOverlay(camera, character)

    if aimEnabled and aimHeld and currentTarget and isEligibleModel(currentTarget) then
        local aimPart = getAimPart(currentTarget)
        if aimPart then
            local desired = CFrame.lookAt(camera.CFrame.Position, aimPart.Position)
            local alpha = math.clamp(deltaTime * config.AimResponsiveness, 0, 1)
            camera.CFrame = camera.CFrame:Lerp(desired, alpha)
        end
    end
end

function TrainingTargetHUD.Start(userConfig)
    if started then return end
    started = true
    uiVisible = true

    config = table.clone(DEFAULTS)
    if type(userConfig) == "table" then
        for key, value in pairs(userConfig) do
            if config[key] ~= nil then config[key] = value end
        end
    end
    aimEnabled = config.AimEnabled
    overlayEnabled = config.OverlayEnabled
    scanAccumulator = config.ScanInterval

    buildGui()

    table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            uiVisible = not uiVisible
            if mainPanel then mainPanel.Visible = uiVisible end
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            aimHeld = true
        end
    end))

    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            aimHeld = false
        end
    end))

    table.insert(connections, LocalPlayer.CharacterRemoving:Connect(function()
        aimHeld = false
        currentTarget = nil
    end))

    RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 1, onRenderStep)
end

function TrainingTargetHUD.Stop()
    if not started then return end
    started = false
    aimHeld = false
    currentTarget = nil

    RunService:UnbindFromRenderStep(BIND_NAME)
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)

    for model in pairs(targetVisuals) do
        destroyVisual(model)
    end
    targetCache = {}
    visibilityCache = {}

    if screenGui then screenGui:Destroy() end
    screenGui = nil
    mainPanel = nil
    statusLabel = nil
    overviewPage = nil
    assistPage = nil
    overlayPage = nil
    aimButton = nil
    overlayButton = nil
    table.clear(tabButtons)
end


-- Automatic startup: no separate ModuleScript or require() is needed.
TrainingTargetHUD.Start({
    TargetTag = "TrainingTarget",
    MaxTargetDistance = 500,
    MaxFOVPixels = 280,
    ScanInterval = 0.12,
    AimResponsiveness = 9,
    RequireLineOfSight = true,
    AimEnabled = false, -- enable in the GUI; hold right mouse to apply
    OverlayEnabled = true,
})

-- Clean up connections, visuals, and the render binding if this script is removed.
script.Destroying:Connect(function()
    TrainingTargetHUD.Stop()
end)
