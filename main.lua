-- Roblox Studio: Mobile Performance & Visual Overlay
-- LocalScript — place in StarterPlayerScripts
-- Includes FPS monitoring, glass-style GUI, and player ESP
-- Intended for your own Roblox experience or authorized testing.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CONFIG = {
    ShowBoxes = true,
    ShowHealth = true,
    UpdateInterval = 1 / 30,
    BackgroundTransparency = 0.2,
    Accent = Color3.fromRGB(80, 190, 255),
}

local gui = Instance.new("ScreenGui")
gui.Name = "PerformanceOverlay"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = PlayerGui

local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.Size = UDim2.fromOffset(220, 112)
panel.Position = UDim2.new(0, 16, 0, 80)
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 35)
panel.BackgroundTransparency = CONFIG.BackgroundTransparency
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = CONFIG.Accent
stroke.Transparency = 0.45
stroke.Thickness = 1
stroke.Parent = panel

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
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(235, 240, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = panel
    return label
end

makeLabel("Title", "PERFORMANCE", 0, 22).Font =
    Enum.Font.GothamBold

local fpsLabel = makeLabel("FPS", "FPS: --", 27, 20)
local playersLabel = makeLabel("Players", "Players: --", 49, 20)

local toggle = Instance.new("TextButton")
toggle.Name = "VisualToggle"
toggle.Size = UDim2.new(1, 0, 0, 27)
toggle.Position = UDim2.fromOffset(0, 73)
toggle.BackgroundColor3 = CONFIG.Accent
toggle.BorderSizePixel = 0
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 12
toggle.TextColor3 = Color3.fromRGB(15, 22, 35)
toggle.Text = "VISUALS: ON"
toggle.Parent = panel

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 7)
toggleCorner.Parent = toggle

local visualsEnabled = true
local overlays = {}
local elapsed = 0
local frames = 0

local function removeOverlay(player)
    local data = overlays[player]
    if data then
        if data.box then data.box:Destroy() end
        if data.health then data.health:Destroy() end
        overlays[player] = nil
    end
end

local function createOverlay(player)
    if player == LocalPlayer or overlays[player] then
        return
    end

    local box = Instance.new("Highlight")
    box.Name = "DebugHighlight"
    box.FillColor = CONFIG.Accent
    box.OutlineColor = Color3.fromRGB(255, 255, 255)
    box.FillTransparency = 0.82
    box.OutlineTransparency = 0.15
    box.Enabled = visualsEnabled
    box.DepthMode = Enum.HighlightDepthMode.Occluded

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "HealthDisplay"
    billboard.Size = UDim2.fromOffset(80, 10)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
    billboard.AlwaysOnTop = false
    billboard.Enabled = visualsEnabled

    local background = Instance.new("Frame")
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    background.BorderSizePixel = 0
    background.Parent = billboard

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 4)
    bgCorner.Parent = background

    local bar = Instance.new("Frame")
    bar.Name = "HealthFill"
    bar.Size = UDim2.fromScale(1, 1)
    bar.BackgroundColor3 = Color3.fromRGB(80, 220, 130)
    bar.BorderSizePixel = 0
    bar.Parent = background

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = bar

    overlays[player] = {
        box = box,
        health = billboard,
        bar = bar,
    }
end

local function attachCharacter(player, character)
    local data = overlays[player]
    if not data then
        createOverlay(player)
        data = overlays[player]
    end
    if not data then return end

    data.box.Adornee = character
    data.box.Parent = character

    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        data.health.Adornee = root
        data.health.Parent = PlayerGui
    end
end

local function registerPlayer(player)
    if player == LocalPlayer then return end
    createOverlay(player)

    player.CharacterAdded:Connect(function(character)
        task.defer(attachCharacter, player, character)
    end)

    if player.Character then
        attachCharacter(player, player.Character)
    end
end

for _, player in Players:GetPlayers() do
    registerPlayer(player)
end

Players.PlayerAdded:Connect(registerPlayer)
Players.PlayerRemoving:Connect(removeOverlay)

toggle.Activated:Connect(function()
    visualsEnabled = not visualsEnabled
    toggle.Text = visualsEnabled and "VISUALS: ON" or "VISUALS: OFF"

    for _, data in pairs(overlays) do
        data.box.Enabled = visualsEnabled
        data.health.Enabled = visualsEnabled
    end
end)

-- Drag the panel using touch or mouse.
local dragging = false
local dragStart
local panelStart

panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        panelStart = panel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            panelStart.X.Scale,
            panelStart.X.Offset + delta.X,
            panelStart.Y.Scale,
            panelStart.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Throttled display updates; render events remain independent.
RunService.Heartbeat:Connect(function(dt)
    frames += 1
    elapsed += dt

    if elapsed >= 1 then
        fpsLabel.Text = ("FPS: %d"):format(
            math.floor(frames / elapsed + 0.5)
        )
        playersLabel.Text = ("Players: %d"):format(
            #Players:GetPlayers()
        )
        frames = 0
        elapsed = 0
    end

    if not visualsEnabled then return end

    for player, data in pairs(overlays) do
        local character = player.Character
        local humanoid = character
            and character:FindFirstChildOfClass("Humanoid")

        if humanoid and humanoid.Health > 0 then
            local ratio = math.clamp(
                humanoid.Health / math.max(humanoid.MaxHealth, 1),
                0, 1
            )
            data.bar.Size = UDim2.fromScale(ratio, 1)
            data.bar.BackgroundColor3 = Color3.fromRGB(
                math.floor(230 * (1 - ratio) + 50 * ratio),
                math.floor(70 * (1 - ratio) + 220 * ratio),
                90
            )
        end
    end
end)

print("Performance overlay initialized.")
