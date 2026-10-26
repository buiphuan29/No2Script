
--[[
    Tactical HUD Module - Roblox Studio
    Single-file LocalScript
    Features:
      - Dark glassmorphism GUI
      - Tabs: HUD / Settings
      - 3D bounding boxes and health bars
      - Nearest-player direction calculation
      - UserInputService + RunService
      - Frame-based updates, no while true loops

    Place in StarterPlayer > StarterPlayerScripts.
    Intended for your own Roblox experience.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local Config = {
    Enabled = true,
    ShowBoxes = true,
    ShowHealth = true,
    ShowDistance = true,
    MaxDistance = 1000,
    UpdateInterval = 1 / 60,
    GUIKey = Enum.KeyCode.RightShift,
}

local Module = {}
local Connections = {}
local PlayerVisuals = {}
local CurrentTab = "HUD"
local GUIVisible = true
local Accumulator = 0

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TacticalGlassHUD"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(440, 310)
Main.Position = UDim2.new(0.5, -220, 0.5, -155)
Main.BackgroundColor3 = Color3.fromRGB(18, 21, 30)
Main.BackgroundTransparency = 0.12
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(105, 155, 255)
Stroke.Transparency = 0.45
Stroke.Thickness = 1.2
Stroke.Parent = Main

local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(29, 35, 51)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 16, 24)),
})
Gradient.Rotation = 35
Gradient.Parent = Main

local function makeLabel(parent, name, text, size, position, fontSize)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Text = text
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(230, 237, 255)
    label.TextSize = fontSize or 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local Title = makeLabel(
    Main, "Title", "TACTICAL  /  PLAYER HUD",
    UDim2.new(1, -70, 0, 35),
    UDim2.fromOffset(18, 8), 16
)
Title.Font = Enum.Font.GothamBold

local Subtitle = makeLabel(
    Main, "Subtitle", "VISUALIZATION SYSTEM",
    UDim2.new(1, -30, 0, 18),
    UDim2.fromOffset(18, 37), 10
)
Subtitle.TextColor3 = Color3.fromRGB(130, 157, 205)

local Close = Instance.new("TextButton")
Close.Name = "Close"
Close.Size = UDim2.fromOffset(30, 30)
Close.Position = UDim2.new(1, -42, 0, 12)
Close.Text = "×"
Close.TextSize = 22
Close.Font = Enum.Font.Gotham
Close.TextColor3 = Color3.fromRGB(255, 150, 160)
Close.BackgroundColor3 = Color3.fromRGB(55, 35, 45)
Close.BackgroundTransparency = 0.2
Close.Parent = Main
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

local Tabs = Instance.new("Frame")
Tabs.Name = "Tabs"
Tabs.Size = UDim2.new(1, -28, 0, 38)
Tabs.Position = UDim2.fromOffset(14, 65)
Tabs.BackgroundColor3 = Color3.fromRGB(10, 13, 21)
Tabs.BackgroundTransparency = 0.25
Tabs.BorderSizePixel = 0
Tabs.Parent = Main
Instance.new("UICorner", Tabs).CornerRadius = UDim.new(0, 9)

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -28, 1, -120)
Content.Position = UDim2.fromOffset(14, 110)
Content.BackgroundTransparency = 1
Content.Parent = Main

local function makeTabButton(text, xScale, width)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(width, 0, 1, -6)
    button.Position = UDim2.new(xScale, 3, 0, 3)
    button.BackgroundColor3 = Color3.fromRGB(55, 90, 155)
    button.BackgroundTransparency = 1
    button.Text = text
    button.TextColor3 = Color3.fromRGB(160, 174, 205)
    button.TextSize = 12
    button.Font = Enum.Font.GothamMedium
    button.Parent = Tabs
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
    return button
end

local HUDTab = makeTabButton("PLAYER HUD", 0, 0.5)
local SettingsTab = makeTabButton("SETTINGS", 0.5, 0.5)

local Pages = {}

for _, name in ipairs({"HUD", "Settings"}) do
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(90, 130, 220)
    page.CanvasSize = UDim2.fromOffset(0, 0)
    page.Visible = false
    page.Parent = Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 9)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    Pages[name] = page
end

local function showTab(name)
    CurrentTab = name

    for pageName, page in pairs(Pages) do
        page.Visible = pageName == name
    end

    HUDTab.BackgroundTransparency = name == "HUD" and 0.1 or 1
    SettingsTab.BackgroundTransparency = name == "Settings" and 0.1 or 1

    HUDTab.TextColor3 = name == "HUD"
        and Color3.new(1, 1, 1)
        or Color3.fromRGB(160, 174, 205)

    SettingsTab.TextColor3 = name == "Settings"
        and Color3.new(1, 1, 1)
        or Color3.fromRGB(160, 174, 205)
end

HUDTab.MouseButton1Click:Connect(function()
    showTab("HUD")
end)

SettingsTab.MouseButton1Click:Connect(function()
    showTab("Settings")
end)

local function addStatusRow(parent, text, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 37)
    row.BackgroundColor3 = Color3.fromRGB(35, 42, 59)
    row.BackgroundTransparency = 0.35
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local label = makeLabel(
        row, "Label", text,
        UDim2.new(1, -70, 1, 0),
        UDim2.fromOffset(11, 0), 12
    )

    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(55, 25)
    button.Position = UDim2.new(1, -62, 0.5, -12)
    button.BackgroundColor3 = Color3.fromRGB(49, 87, 140)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 11
    button.Font = Enum.Font.GothamBold
    button.Parent = row
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

    local function refresh()
        button.Text = Config[text] and "ON" or "OFF"
        button.BackgroundColor3 = Config[text]
            and Color3.fromRGB(46, 115, 100)
            or Color3.fromRGB(72, 76, 90)
    end

    refresh()

    button.MouseButton1Click:Connect(function()
        Config[text] = not Config[text]
        refresh()
    end)

    return row
end

addStatusRow(Pages.HUD, "ShowBoxes", 1)
addStatusRow(Pages.HUD, "ShowHealth", 2)
addStatusRow(Pages.HUD, "ShowDistance", 3)

local Info = makeLabel(
    Pages.HUD, "Info",
    "Bounding boxes are projected from character bounds.",
    UDim2.new(1, -8, 0, 38),
    UDim2.fromOffset(2, 0), 11
)
Info.LayoutOrder = 4
Info.TextWrapped = true
Info.TextColor3 = Color3.fromRGB(155, 171, 200)

local SettingsInfo = makeLabel(
    Pages.Settings, "SettingsInfo",
    "Update rate: 60 Hz\nToggle interface: Right Shift\nTarget vector: nearest visible character",
    UDim2.new(1, -8, 0, 65),
    UDim2.fromOffset(2, 0), 12
)
SettingsInfo.TextWrapped = true
SettingsInfo.LayoutOrder = 1

showTab("HUD")

--==================================================
-- Drag GUI
--==================================================

local dragging = false
local dragStart
local startPosition

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

Connections.DragEnd = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

Connections.DragMove = UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

Close.MouseButton1Click:Connect(function()
    GUIVisible = false
    Main.Visible = false
end)

Connections.ToggleGUI = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Config.GUIKey then
        GUIVisible = not GUIVisible
        Main.Visible = GUIVisible
    end
end)

--==================================================
-- Player visualization
--==================================================

local function createVisual(player)
    if player == LocalPlayer then
        return
    end

    local folder = Instance.new("Folder")
    folder.Name = "Visual_" .. player.UserId
    folder.Parent = ScreenGui

    local box = Instance.new("Frame")
    box.Name = "BoundingBox"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = folder

    local outline = Instance.new("UIStroke")
    outline.Color = Color3.fromRGB(90, 190, 255)
    outline.Thickness = 1.5
    outline.Transparency = 0.1
    outline.Parent = box

    local healthBG = Instance.new("Frame")
    healthBG.Name = "HealthBG"
    healthBG.Size = UDim2.fromOffset(4, 100)
    healthBG.BackgroundColor3 = Color3.fromRGB(35, 39, 48)
    healthBG.BorderSizePixel = 0
    healthBG.Visible = false
    healthBG.Parent = folder

    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.AnchorPoint = Vector2.new(0, 1)
    healthFill.Position = UDim2.new(0, 0, 1, 0)
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.BackgroundColor3 = Color3.fromRGB(70, 220, 130)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBG

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.fromOffset(180, 18)
    nameLabel.AnchorPoint = Vector2.new(0.5, 1)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(230, 240, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 11
    nameLabel.Visible = false
    nameLabel.Parent = folder

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "Distance"
    distanceLabel.Size = UDim2.fromOffset(150, 16)
    distanceLabel.AnchorPoint = Vector2.new(0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(150, 195, 255)
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.TextSize = 10
    distanceLabel.Visible = false
    distanceLabel.Parent = folder

    PlayerVisuals[player] = {
        Folder = folder,
        Box = box,
        HealthBG = healthBG,
        HealthFill = healthFill,
        Name = nameLabel,
        Distance = distanceLabel,
    }
end

local function removeVisual(player)
    local visual = PlayerVisuals[player]

    if visual then
        visual.Folder:Destroy()
        PlayerVisuals[player] = nil
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    createVisual(player)
end

Connections.PlayerAdded = Players.PlayerAdded:Connect(createVisual)
Connections.PlayerRemoving = Players.PlayerRemoving:Connect(removeVisual)

local function hideVisual(visual)
    visual.Box.Visible = false
    visual.HealthBG.Visible = false
    visual.Name.Visible = false
    visual.Distance.Visible = false
end

local function updateVisual(player, visual)
    local character = player.Character

    if not character then
        hideVisual(visual)
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or humanoid.Health <= 0 then
        hideVisual(visual)
        return
    end

    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")

    if not myRoot then
        hideVisual(visual)
        return
    end

    local distance = (root.Position - myRoot.Position).Magnitude

    if distance > Config.MaxDistance then
        hideVisual(visual)
        return
    end

    -- Project the 3D bounding box into screen-space.
    local boxCFrame, boxSize = character:GetBoundingBox()
    local half = boxSize * 0.5

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local anyOnScreen = false

    for xSign = -1, 1, 2 do
        for ySign = -1, 1, 2 do
            for zSign = -1, 1, 2 do
                local corner = boxCFrame:PointToWorldSpace(Vector3.new(
                    half.X * xSign,
                    half.Y * ySign,
                    half.Z * zSign
                ))

                local screenPoint, onScreen =
                    Camera:WorldToViewportPoint(corner)

                if onScreen and screenPoint.Z > 0 then
                    anyOnScreen = true
                    minX = math.min(minX, screenPoint.X)
                    minY = math.min(minY, screenPoint.Y)
                    maxX = math.max(maxX, screenPoint.X)
                    maxY = math.max(maxY, screenPoint.Y)
                end
            end
        end
    end

    if not anyOnScreen or maxX <= minX or maxY <= minY then
        hideVisual(visual)
        return
    end

    local width = maxX - minX
    local height = maxY - minY

    visual.Box.Position = UDim2.fromOffset(minX, minY)
    visual.Box.Size = UDim2.fromOffset(width, height)
    visual.Box.Visible = Config.Enabled and Config.ShowBoxes

    visual.HealthBG.Position = UDim2.fromOffset(minX - 7, minY)
    visual.HealthBG.Size = UDim2.fromOffset(4, height)
    visual.HealthBG.Visible = Config.Enabled and Config.ShowHealth

    local healthRatio = math.clamp(
        humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1
    )

    visual.HealthFill.Size = UDim2.new(1, 0, healthRatio, 0)

    visual.HealthFill.BackgroundColor3 =
        healthRatio > 0.6 and Color3.fromRGB(70, 220, 130)
        or healthRatio > 0.3 and Color3.fromRGB(255, 190, 70)
        or Color3.fromRGB(255, 80, 95)

    visual.Name.Text = player.DisplayName
    visual.Name.Position = UDim2.fromOffset(
        minX + width / 2, minY - 3
    )
    visual.Name.Visible = Config.Enabled and Config.ShowBoxes

    visual.Distance.Text = string.format("%d studs", distance)
    visual.Distance.Position = UDim2.fromOffset(
        minX + width / 2, maxY + 2
    )
    visual.Distance.Visible = Config.Enabled and Config.ShowDistance
end

--==================================================
-- Nearest-player direction calculation
--==================================================

local function getNearestTarget()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then
        return nil, nil, math.huge
    end

    local nearestPlayer = nil
    local nearestDirection = nil
    local nearestDistance = Config.MaxDistance

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local targetCharacter = player.Character
            local targetRoot = targetCharacter
                and targetCharacter:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = targetCharacter
                and targetCharacter:FindFirstChildOfClass("Humanoid")

            if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                local offset = targetRoot.Position - root.Position
                local distance = offset.Magnitude

                if distance > 0 and distance < nearestDistance then
                    nearestDistance = distance
                    nearestPlayer = player
                    nearestDirection = offset.Unit
                end
            end
        end
    end

    return nearestPlayer, nearestDirection, nearestDistance
end

-- Display the calculated direction in the HUD; does not move the aim.
local TargetInfo = makeLabel(
    Pages.HUD, "TargetInfo",
    "Nearest target: none",
    UDim2.new(1, -8, 0, 24),
    UDim2.fromOffset(2, 0), 11
)
TargetInfo.LayoutOrder = 5
TargetInfo.TextColor3 = Color3.fromRGB(120, 210, 255)

Module.GetNearestTarget = getNearestTarget

--==================================================
-- Frame update
--==================================================

Connections.Render = RunService.RenderStepped:Connect(function(deltaTime)
    if not Config.Enabled then
        return
    end

    Accumulator += deltaTime

    if Accumulator < Config.UpdateInterval then
        return
    end

    Accumulator %= Config.UpdateInterval

    Camera = workspace.CurrentCamera or Camera

    for player, visual in pairs(PlayerVisuals) do
        updateVisual(player, visual)
    end

    local target, direction, distance = getNearestTarget()

    if target and direction then
        TargetInfo.Text = string.format(
            "Nearest: %s  |  %.0f studs  |  Dir: %.2f, %.2f, %.2f",
            target.DisplayName,
            distance,
            direction.X,
            direction.Y,
            direction.Z
        )
    else
        TargetInfo.Text = "Nearest target: none"
    end
end)

--==================================================
-- Cleanup API
--==================================================

function Module.SetEnabled(enabled)
    Config.Enabled = enabled

    for _, visual in pairs(PlayerVisuals) do
        if not enabled then
            hideVisual(visual)
        end
    end
end

function Module.Destroy()
    for _, connection in pairs(Connections) do
        connection:Disconnect()
    end

    for player in pairs(PlayerVisuals) do
        removeVisual(player)
    end

    ScreenGui:Destroy()
end

Module.Config = Config

return Module
