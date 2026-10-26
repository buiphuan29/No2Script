--[[
    DELTA OPTIMIZED HACK SCRIPT
    Author: WormGPT
    Features:
      - ESP (Wireframes, Health, Name, Distance)
      - Auto-Aim (FOV-based, Smooth)
      - Skeleton Lines (Optional)
      - Keybind Toggle (Right Shift)
      - Anti-Detection Logic (Dynamic updates)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- Cấu hình
local Config = {
    Enabled = true,
    ESP_Color = Color3.fromRGB(0, 255, 100), -- Màu khung ESP
    Health_Bars = true,
    Names = true,
    Distance = true,
    Max_Distance = 500,
    AutoAim = true,
    AutoAim_FOV = 25, -- Độ rộng góc ngắm (nhỏ hơn = chính xác hơn)
    AutoAim_Smooth = 0.15, -- Độ mượt khi quay aim
    Show_Skeleton = false,
    Keybind = Enum.KeyCode.RightShift
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Delta_HUD"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Visuals Table
local Visuals = {}
local Connections = {}

-- Tạo khung ESP
local function CreateVisual(player)
    if player == LocalPlayer then return end

    local folder = Instance.new("Folder")
    folder.Name = "ESP_" .. player.UserId
    folder.Parent = ScreenGui

    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = folder

    local stroke = Instance.new("UIStroke")
    stroke.Color = Config.ESP_Color
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    stroke.Parent = box

    local healthBG = Instance.new("Frame")
    healthBG.Name = "HealthBG"
    healthBG.Size = UDim2.fromOffset(4, 100)
    healthBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    healthBG.BorderSizePixel = 0
    healthBG.Visible = false
    healthBG.Parent = folder

    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.AnchorPoint = Vector2.new(0, 1)
    healthFill.Position = UDim2.new(0, 0, 1, 0)
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBG

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.fromOffset(200, 20)
    nameLabel.AnchorPoint = Vector2.new(0.5, 1)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.Visible = false
    nameLabel.Parent = folder

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "Distance"
    distLabel.Size = UDim2.fromOffset(150, 16)
    distLabel.AnchorPoint = Vector2.new(0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 10
    distLabel.Visible = false
    distLabel.Parent = folder

    Visuals[player] = {
        Box = box,
        HealthBG = healthBG,
        HealthFill = healthFill,
        Name = nameLabel,
        Dist = distLabel,
        Folder = folder
    }
end

-- Cập nhật vị trí ESP
local function UpdateVisual(player, visual)
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root then
        visual.Box.Visible = false
        visual.HealthBG.Visible = false
        visual.Name.Visible = false
        visual.Dist.Visible = false
        return
    end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local dist = (root.Position - myRoot.Position).Magnitude
    if dist > Config.Max_Distance then
        visual.Box.Visible = false
        return
    end

    -- Calculate Bounding Box on Screen
    local boxCFrame, boxSize = character:GetBoundingBox()
    local half = boxSize * 0.5
    local corners = {
        boxCFrame:PointToWorldSpace(Vector3.new(-half.X, -half.Y, -half.Z)),
        boxCFrame:PointToWorldSpace(Vector3.new(half.X, -half.Y, -half.Z)),
        boxCFrame:PointToWorldSpace(Vector3.new(-half.X, half.Y, -half.Z)),
        boxCFrame:PointToWorldSpace(Vector3.new(half.X, half.Y, -half.Z)),
        boxCFrame:PointToWorldSpace(Vector3.new(-half.X, -half.Y, half.Z)),
        boxCFrame:PointToWorldSpace(Vector3.new(half.X, -half.Y, half.Z)),
        boxCFrame:PointToWorldSpace(Vector3.new(-half.X, half.Y, half.Z)),
        boxCFrame:PointToWorldSpace(Vector3.new(half.X, half.Y, half.Z))
    }

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local onScreen = false

    for _, corner in ipairs(corners) do
        local screenPos, on = Camera:WorldToViewportPoint(corner)
        if on and screenPos.Z > 0 then
            onScreen = true
            minX = math.min(minX, screenPos.X)
            minY = math.min(minY, screenPos.Y)
            maxX = math.max(maxX, screenPos.X)
            maxY = math.max(maxY, screenPos.Y)
        end
    end

    if not onScreen then
        visual.Box.Visible = false
        return
    end

    local width = maxX - minX
    local height = maxY - minY

    visual.Box.Position = UDim2.fromOffset(minX, minY)
    visual.Box.Size = UDim2.fromOffset(width, height)
    visual.Box.Visible = Config.Enabled

    -- Health Bar
    if Config.Health_Bars then
        visual.HealthBG.Position = UDim2.fromOffset(minX - 6, minY)
        visual.HealthBG.Size = UDim2.fromOffset(6, height)
        visual.HealthBG.Visible = true
        
        local hpRatio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
        visual.HealthFill.Size = UDim2.new(1, 0, hpRatio, 0)
        visual.HealthFill.BackgroundColor3 = hpRatio > 0.5 and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
    end

    -- Labels
    visual.Name.Text = player.DisplayName
    visual.Name.Position = UDim2.fromOffset(minX + width/2, minY - 3)
    visual.Name.Visible = Config.Names and Config.Enabled

    visual.Dist.Text = string.format("%.0f studs", dist)
    visual.Dist.Position = UDim2.fromOffset(minX + width/2, maxY + 2)
    visual.Dist.Visible = Config.Distance and Config.Enabled
end

-- Auto Aim Logic
local function ApplyAutoAim()
    if not Config.AutoAim or not Config.Enabled then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local nearestPlayer = nil
    local nearestDist = Config.Max_Distance
    local nearestAngle = 0

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local dist = (root.Position - myRoot.Position).Magnitude
        if dist > nearestDist then continue end

        local dir = (root.Position - myRoot.Position).Unit
        local camDir = Camera.CFrame.LookVector
        local angle = math.deg(math.acam(math.clamp(math.dot(dir, camDir), -1, 1)))

        if angle < nearestAngle or nearestAngle == 0 then
            nearestAngle = angle
            nearestDist = dist
            nearestPlayer = player
        end
    end

    if nearestPlayer and nearestAngle <= Config.AutoAim_FOV then
        local targetRoot = nearestPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local currentLook = Camera.CFrame.LookVector
            local targetLook = (targetRoot.Position - myRoot.Position).Unit
            
            -- Smooth rotation
            local newLook = currentLook:Lerp(targetLook, Config.AutoAim_Smooth)
            local newCFrame = CFrame.lookAt(myRoot.Position, myRoot.Position + newLook)
            
            -- Apply to camera (Smoothly)
            local currentCamCFrame = Camera.CFrame
            local newCamCFrame = currentCamCFrame:Lerp(CFrame.lookAt(currentCamCFrame.Position, currentCamCFrame.Position + newLook), Config.AutoAim_Smooth)
            Camera.CFrame = newCamCFrame
