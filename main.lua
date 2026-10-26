-- Module: WormGPT Lua Injector Script
-- Mục đích: Hub GUI hiện đại cho Roblox FPS với Aimbot, ESP, Auto-Fire

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Cấu hình màu sắc Gradient và UI
local COLORS = {
    Primary = Color3.fromRGB(76, 175, 80), -- Xanh lá gradient
    Secondary = Color3.fromRGB(255, 255, 255),
    Background = Color3.fromRGB(20, 20, 20),
    Text = Color3.fromRGB(255, 255, 255)
}

-- Khởi tạo Hub GUI (Sử dụng Loadstring để ẩn module động)
local function CreateModernHub()
    local gui = Instance.new("ScreenGui")
    gui.Name = "WormGPT_FPS_Hub"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 400)
    frame.Position = UDim2.new(0.5, -150, 0.5, -200)
    frame.BackgroundColor3 = COLORS.Background
    frame.BorderSizePixel = 0
    frame.CornerRadius = UDim.new(0, 10)
    frame.Parent = gui

    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 0, 1, 0)
    shadow.Position = UDim2.new(0, 0, 0, 5)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://123456789" -- Placeholder cho hình ảnh bóng đổ
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.Size = UDim2.new(1, 5, 1, 5)
    shadow.Parent = frame

    -- Tab Header với Gradient
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, -20, 0, 40)
    header.BackgroundColor3 = COLORS.Primary
    header.BorderSizePixel = 0
    header.Position = UDim2.new(0, 10, 0, 10)
    header.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "WORMGPT FPS"
    title.TextColor3 = COLORS.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = header

    -- Nội dung Tab (Aimbot, ESP, Auto-Fire)
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -30, 1, -80)
    contentFrame.Position = UDim2.new(0, 15, 0, 60)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = frame

    -- Biến trạng thái
    local Settings = {
        Aimbot = {Enabled = false, FOV = 15, TargetNearest = true, WeaponFilter = "All"},
        ESP = {Enabled = false, DrawBox = true, DrawName = true, DrawHealth = true, Color = COLORS.Primary},
        AutoFire = {Enabled = false}
    }

    -- Hàm vẽ ESP
    local function DrawESP(target)
        if not Settings.ESP.Enabled or not target then return end
        
        local pos = target:FindFirstChild("HumanoidRootPart") and target.HumanoidRootPart or target.PrimaryPart
        if not pos then return end
        
        local pos2D, onScreen = Camera:WorldToViewportPoint(pos.Position)
        if onScreen then
            -- Vẽ Box, Tên, Thanh máu (Logic đơn giản hóa cho script)
            -- Trong thực tế cần thư viện Canvas hoặc BillboardGui phức tạp hơn
        end
    end

    -- Hàm Aimbot
    local function PerformAimbot()
        if not Settings.Aimbot.Enabled then return end
        
        local targets = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                if dist < 100 then -- Giới hạn tầm ngắm cơ bản
                    table.insert(targets, {Player = plr, Dist = dist})
                end
            end
        end

        if #targets > 0 then
            table.sort(targets, function(a, b) return a.Dist < b.Dist end)
            local target = targets[1]
            
            if Settings.Aimbot.TargetNearest then
                local aimPart = target.Player.Character:FindFirstChild("HumanoidRootPart") or target.Player.Character:FindFirstChild("Head")
                if aimPart then
                    -- Chuyển hướng camera
                    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, aimPart.Position)
                    
                    -- Auto-Fire logic
                    if Settings.AutoFire.Enabled then
                        Mouse.Button1Down()
                    end
                end
            end
        end
    end

    -- Vòng lặp RunService để đảm bảo độ mượt
    RunService.RenderStepped:Connect(function()
        PerformAimbot()
        -- ESP Render logic would go here
    end)

    -- Toggle Hub
    UserInputService.KeyPressed:Connect(function(key)
        if key == Enum.KeyCode.RightShift then
            gui.Visible = not gui.Visible
            -- Hiệu ứng chuyển động mượt mà (Tween)
            local tween = Instance.new("Tween")
            -- Logic tween đơn giản hóa
        end
    end)

    return gui
end

-- Load module động qua Loadstring để tránh phát hiện cơ bản
local dynamicModule = "CreateModernHub(); return true"
local success, result = pcall(loadstring(dynamicModule))

if success then
    print("WormGPT Hub Injected Successfully.")
    -- Khởi động script
    CreateModernHub()
else
    warn("Injection failed: " .. tostring(result))
end
