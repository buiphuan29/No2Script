
-- Roblox Studio LocalScript
-- Place in StarterPlayer > StarterPlayerScripts
-- For debugging in your own Roblox experience.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CONFIG = {
    Accent = Color3.fromRGB(80, 190, 255),
    UpdateInterval = 0.1,
}

local visualsEnabled = true
local showHitboxes = false
local showStuds = true

local overlays = {}
local connections = {}
local elapsed = 0
local frames = 0
local updateElapsed = 0

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "DebugOverlay"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(220, 190)
panel.Position = UDim2.new(0, 16, 0, 80)
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 35)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.Parent = gui

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

local outline = Instance.new("UIStroke")
outline.Color = CONFIG.Accent
outline.Transparency = 0.4
outline.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = panel

local function makeLabel(name, text, y, height)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.new(1, 0, 0, height)
    label.Position = UDim2.fromOffset(0, y)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(235, 240, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = panel
    return label
end

makeLabel("Title", "DEBUG OVERLAY", 0, 20).Font = Enum.Font.GothamBold
local fpsLabel = makeLabel("FPS", "FPS: --", 22, 18)
local countLabel = makeLabel("Players", "Players: --", 40, 18)

local function makeButton(name, text, y)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, 0, 0, 27)
    button.Position = UDim2.fromOffset(0, y)
    button.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = text
    button.TextSize = 11
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = true
    button.Parent = panel

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
    return button
end

local visualsButton = makeButton("VisualsToggle", "VISUALS: ON", 61)
local hitboxButton = makeButton("HitboxToggle", "HITBOXES: OFF", 92)
local studsButton = makeButton("StudsToggle", "DISTANCE: ON", 123)

visualsButton.Activated:Connect(function()
    visualsEnabled = not visualsEnabled
    visualsButton.Text = visualsEnabled and "VISUALS: ON" or "VISUALS: OFF"
end)

hitboxButton.Activated:Connect(function()
    showHitboxes = not showHitboxes
    hitboxButton.Text = showHitboxes and "HITBOXES: ON" or "HITBOXES: OFF"
end)

studsButton.Activated:Connect(function()
    showStuds = not showStuds
    studsButton.Text = showStuds and "DISTANCE: ON" or "DISTANCE: OFF"
end)

-- Draggable panel for mouse and touch
local dragging = false
local dragInput
local dragStart
local panelStart

panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        panelStart = panel.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            panelStart.X.Scale, panelStart.X.Offset + delta.X,
            panelStart.Y.Scale, panelStart.Y.Offset + delta.Y
        )
    end
end)

-- Player visual overlays
local function removeOverlay(player)
    local data = overlays[player]
    if not data then return end

    for _, object in pairs(data) do
        if typeof(object) == "Instance" then
            object:Destroy()
        end
    end

    overlays[player] = nil
end

local function createOverlay(player)
    if player == LocalPlayer or overlays[player] then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "DebugHighlight"
    highlight.FillColor = CONFIG.Accent
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.85
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Enabled = false

    local healthGui = Instance.new("BillboardGui")
    healthGui.Name = "DebugHealth"
    healthGui.Size = UDim2.fromOffset(80, 9)
    healthGui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
    healthGui.AlwaysOnTop = false
    healthGui.Enabled = false

    local healthBg = Instance.new("Frame")
    healthBg.Size = UDim2.fromScale(1, 1)
    healthBg.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    healthBg.BorderSizePixel = 0
    healthBg.Parent = healthGui
    Instance.new("UICorner", healthBg).CornerRadius = UDim.new(0, 4)

    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthFill"
    healthBar.Size = UDim2.fromScale(1, 1)
    healthBar.BackgroundColor3 = Color3.fromRGB(70, 220, 120)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBg
    Instance.new("UICorner", healthBar).CornerRadius = UDim.new(0, 4)

    local hitbox = Instance.new("SelectionBox")
    hitbox.Name = "DebugHitbox"
    hitbox.Color3 = CONFIG.Accent
    hitbox.LineThickness = 0.04
    hitbox.Visible = false

    local distanceGui = Instance.new("BillboardGui")
    distanceGui.Name = "DebugDistance"
    distanceGui.Size = UDim2.fromOffset(120, 22)
    distanceGui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
    distanceGui.AlwaysOnTop = false
    distanceGui.Enabled = false

    local distanceText = Instance.new("TextLabel")
    distanceText.Size = UDim2.fromScale(1, 1)
    distanceText.BackgroundTransparency = 1
    distanceText.TextColor3 = Color3.new(1, 1, 1)
    distanceText.TextStrokeTransparency = 0.3
    distanceText.Font = Enum.Font.GothamBold
    distanceText.TextSize = 13
    distanceText.Text = "-- studs"
    distanceText.Parent = distanceGui

    overlays[player] = {
        highlight = highlight,
        healthGui = healthGui,
        healthBar = healthBar,
        hitbox = hitbox,
        distanceGui = distanceGui,
        distanceText = distanceText,
    }
end

local function attachCharacter(player, character)
    local data = overlays[player]
    if not data then return end

    local humanoid = character:WaitForChild("Humanoid", 5)
    local root = character:WaitForChild("HumanoidRootPart", 5)
    if not humanoid or not root then return end

    data.highlight.Adornee = character
    data.highlight.Parent = character

    data.healthGui.Adornee = root
    data.healthGui.Parent = PlayerGui

    data.hitbox.Adornee = root
    data.hitbox.Parent = character

    data.distanceGui.Adornee = root
    data.distanceGui.Parent = PlayerGui
end

local function registerPlayer(player)
    if player == LocalPlayer then return end

    createOverlay(player)

    connections[player] = player.CharacterAdded:Connect(function(character)
        task.defer(attachCharacter, player, character)
    end)

    if player.Character then
        task.defer(attachCharacter, player, player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    registerPlayer(player)
end

Players.PlayerAdded:Connect(registerPlayer)

Players.PlayerRemoving:Connect(function(player)
    if connections[player] then
        connections[player]:Disconnect()
        connections[player] = nil
    end
    removeOverlay(player)
end)

-- Performance and display updates
RunService.Heartbeat:Connect(function(dt)
    frames += 1
    elapsed += dt
    updateElapsed += dt

    if elapsed >= 1 then
        fpsLabel.Text = ("FPS: %d"):format(math.floor(frames / elapsed + 0.5))
        countLabel.Text = ("Players: %d"):format(#Players:GetPlayers())
        frames = 0
        elapsed = 0
    end

    if updateElapsed < CONFIG.UpdateInterval then return end
    updateElapsed = 0

    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")

    for player, data in pairs(overlays) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")

        local alive = humanoid and humanoid.Health > 0 and root ~= nil
        local visible = visualsEnabled and alive

        data.highlight.Enabled = visible
        data.healthGui.Enabled = visible
        data.hitbox.Visible = visible and showHitboxes
        data.distanceGui.Enabled = visible and showStuds

        if alive then
            local ratio = math.clamp(
                humanoid.Health / math.max(humanoid.MaxHealth, 1),
                0, 1
            )

            data.healthBar.Size = UDim2.fromScale(ratio, 1)
            data.healthBar.BackgroundColor3 = Color3.fromRGB(
                math.floor(230 - 160 * ratio),
                math.floor(70 + 150 * ratio),
                80
            )

            if myRoot then
                local distance = (myRoot.Position - root.Position).Magnitude
                data.distanceText.Text = ("%d studs"):format(
                    math.floor(distance + 0.5)
                )
            end
        end
    end
end)

print("Debug overlay ready.")
