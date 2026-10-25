--[[
    AIM + ESP + HP + STUDS + CUSTOM UI (PC + MOBILE) — v3
    LocalScript -> StarterPlayer > StarterPlayerScripts
    PC     : Nhấn M = menu | Giữ E = aim | Kéo tiêu đề = di chuyển menu
    Mobile : Tap ☰ = menu | Tap AIM = bật/tắt aim | Kéo tiêu đề = di chuyển menu
    Mới: Slider FOV / Smoothing / ESP Distance + Chọn AimPart (Head/Torso/Root)
--]]

--// =========================================================
--// CẤU HÌNH (thay đổi tuỳ ý)
--// =========================================================
local Config = {
    -- Aim
    AimEnabled       = true,
    AimKey           = Enum.KeyCode.E,     -- (PC) giữ để aim
    AimFOV           = 150,
    AimSmoothing     = 0.35,               -- 0 = cứng, 1 = rất mềm
    AimPart          = "Head",
    TeamCheck        = true,
    ShowFOVCircle    = true,

    -- ESP
    ESPEnabled       = true,
    ShowBoxes        = true,
    ShowName         = true,
    ShowHP           = true,
    ShowDistance     = true,
    ShowTeamColor    = true,
    ESPMaxDistance   = 2000,

    -- Mobile
    MobileButtons    = true,

    -- UI
    UITheme          = {
        Background   = Color3.fromRGB(18, 18, 24),
        Panel        = Color3.fromRGB(28, 28, 38),
        Accent       = Color3.fromRGB(120, 80, 255),
        Text         = Color3.fromRGB(235, 235, 245),
        SubText      = Color3.fromRGB(150, 150, 165),
        Element      = Color3.fromRGB(40, 40, 55),
        On           = Color3.fromRGB(70, 200, 120),
        Off          = Color3.fromRGB(200, 70, 80),
    },
    Font             = Enum.Font.GothamMedium,
}
--// =========================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer   = Players.LocalPlayer
local Camera        = Workspace.CurrentCamera

local IS_TOUCH      = UserInputService.TouchEnabled
local INSET_Y       = GuiService:GetGuiInset().Y

-- =========================================================
-- UI
-- =========================================================
local function getGuiParent()
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
end

local oldGui = getGuiParent():FindFirstChild("AimEspHub")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimEspHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = getGuiParent()

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(310, 400)
Main.Position = UDim2.fromOffset(40, 120)
Main.BackgroundColor3 = Config.UITheme.Background
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Tự thu nhỏ UI trên màn hình nhỏ (điện thoại dọc/ngang)
local uiScale = Instance.new("UIScale")
uiScale.Parent = Main
local function fitUI()
    local vp = Camera.ViewportSize
    uiScale.Scale = (vp.X < 900 or vp.Y < 450) and 0.8 or 1
    if vp.X < 500 then
        Main.Position = UDim2.fromOffset(10, 70)
    end
end
fitUI()
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitUI)

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 42)
Title.BackgroundColor3 = Config.UITheme.Panel
Title.BorderSizePixel = 0
Title.Text = "  AIM / ESP HUB"
Title.TextColor3 = Config.UITheme.Accent
Title.Font = Config.Font
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Active = true
Title.Parent = Main
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local lpName = Instance.new("TextLabel")
lpName.Size = UDim2.new(1, -120, 1, -10)
lpName.Position = UDim2.fromOffset(12, 10)
lpName.BackgroundTransparency = 1
lpName.Text = "Xin chào, " .. LocalPlayer.DisplayName
lpName.TextColor3 = Config.UITheme.SubText
lpName.Font = Config.Font
lpName.TextSize = 14
lpName.TextXAlignment = Enum.TextXAlignment.Left
lpName.Parent = Title

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.fromOffset(28, 28)
MinBtn.Position = UDim2.new(1, -62, 0, 7)
MinBtn.BackgroundColor3 = Config.UITheme.Element
MinBtn.Text = "–"
MinBtn.TextColor3 = Config.UITheme.Text
MinBtn.Font = Config.Font
MinBtn.TextSize = 18
MinBtn.BorderSizePixel = 0
MinBtn.Parent = Main
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(28, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 7)
CloseBtn.BackgroundColor3 = Config.UITheme.Off
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Config.Font
CloseBtn.TextSize = 14
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Main
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local Body = Instance.new("ScrollingFrame")
Body.Size = UDim2.new(1, -16, 1, -56)
Body.Position = UDim2.fromOffset(8, 50)
Body.BackgroundTransparency = 1
Body.BorderSizePixel = 0
Body.ScrollBarThickness = 4
Body.CanvasSize = UDim2.new(0, 0, 0, 0)
Body.AutomaticCanvasSize = Enum.AutomaticSize.Y
Body.Parent = Main

local BodyLayout = Instance.new("UIListLayout")
BodyLayout.Padding = UDim.new(0, 8)
BodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
BodyLayout.Parent = Body

-- Kéo thả menu (hỗ trợ cả chuột lẫn tay cảm ứng)
local dragging, dragStart, startPos = false, nil, nil
Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- =========================================================
-- WIDGETS: Toggle / Slider / Choice
-- =========================================================
local function makeToggle(text, default, order, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 40)
    holder.BackgroundColor3 = Config.UITheme.Element
    holder.BorderSizePixel = 0
    holder.LayoutOrder = order
    holder.Parent = Body
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Config.UITheme.Text
    label.Font = Config.Font
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(56, 24)
    btn.Position = UDim2.new(1, -68, 0.5, -12)
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BackgroundColor3 = default and Config.UITheme.On or Config.UITheme.Off
    btn.Font = Config.Font
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = holder
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

    btn.MouseButton1Click:Connect(function()
        default = not default
        btn.Text = default and "ON" or "OFF"
        btn.BackgroundColor3 = default and Config.UITheme.On or Config.UITheme.Off
        callback(default)
    end)
    callback(default)
    return btn
end

local function makeSlider(text, default, minValue, maxValue, order, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 46)
    holder.BackgroundColor3 = Config.UITheme.Element
    holder.BorderSizePixel = 0
    holder.LayoutOrder = order
    holder.Parent = Body
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -80, 0, 18)
    label.Position = UDim2.fromOffset(12, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Config.UITheme.Text
    label.Font = Config.Font
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.fromOffset(62, 18)
    valueLabel.Position = UDim2.new(1, -74, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Config.UITheme.Accent
    valueLabel.Font = Config.Font
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = holder

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.fromOffset(12, 32)
    track.BackgroundColor3 = Config.UITheme.Background
    track.BorderSizePixel = 0
    track.Parent = holder
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Config.UITheme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(14, 14)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local value = default
    local fine = (maxValue - minValue) <= 1   -- slider 0..1 làm tròn 2 chữ số thập phân
    local function fmt(v)
        if fine then
            return string.format("%.2f", v)
        end
        return tostring(math.floor(v + 0.5))
    end
    local function refresh()
        local pct = (value - minValue) / (maxValue - minValue)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valueLabel.Text = fmt(value)
        callback(value)
    end
    local function setFromInput(input)
        local x = input.Position.X - track.AbsolutePosition.X
        local pct = math.clamp(x / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local raw = minValue + (maxValue - minValue) * pct
        value = fine and (math.floor(raw * 100 + 0.5) / 100) or math.floor(raw + 0.5)
        refresh()
    end

    local sliding = false
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            setFromInput(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            setFromInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    refresh()
end

local function makeChoice(text, options, order)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 50)
    holder.BackgroundColor3 = Config.UITheme.Element
    holder.BorderSizePixel = 0
    holder.LayoutOrder = order
    holder.Parent = Body
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -24, 0, 18)
    label.Position = UDim2.fromOffset(12, 4)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Config.UITheme.Text
    label.Font = Config.Font
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local shortNames = {
        Head = "Head",
        UpperTorso = "Torso",
        HumanoidRootPart = "Root",
    }
    local buttons = {}
    for i, opt in ipairs(options) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1/3, -8, 0, 22)
        btn.Position = UDim2.new((i - 1) / 3, (i == 1 and 4) or (i == 2 and 2) or 0, 0, 26)
        btn.BackgroundColor3 = (Config.AimPart == opt) and Config.UITheme.Accent or Config.UITheme.Background
        btn.Text = shortNames[opt] or opt
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Config.Font
        btn.TextSize = 12
        btn.BorderSizePixel = 0
        btn.Parent = holder
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local function paint()
            btn.BackgroundColor3 = (Config.AimPart == opt) and Config.UITheme.Accent or Config.UITheme.Background
        end

        local entry = { paint = paint, opt = opt }
        buttons[i] = entry
        btn.MouseButton1Click:Connect(function()
            Config.AimPart = opt
            for _, e in ipairs(buttons) do
                e.paint()
            end
        end)
    end

    return holder
end

-- Toggle (1-7)
makeToggle("Aim Assist", Config.AimEnabled, 1, function(v) Config.AimEnabled = v end)
makeToggle("ESP Boxes", Config.ShowBoxes, 2, function(v) Config.ShowBoxes = v end)
makeToggle("ESP Name", Config.ShowName, 3, function(v) Config.ShowName = v end)
makeToggle("ESP HP Bar", Config.ShowHP, 4, function(v) Config.ShowHP = v end)
makeToggle("ESP Distance (studs)", Config.ShowDistance, 5, function(v) Config.ShowDistance = v end)
makeToggle("Team Check", Config.TeamCheck, 6, function(v) Config.TeamCheck = v end)
makeToggle("Show FOV Circle", Config.ShowFOVCircle, 7, function(v) Config.ShowFOVCircle = v end)

-- Slider (8-10)
makeSlider("Aim FOV (pixel)", Config.AimFOV, 10, 300, 8, function(v) Config.AimFOV = v end)
makeSlider("Aim Smoothing", Config.AimSmoothing, 0, 1, 9, function(v) Config.AimSmoothing = v end)
makeSlider("ESP Max Distance", Config.ESPMaxDistance, 100, 5000, 10, function(v) Config.ESPMaxDistance = v end)

-- Choice (11)
makeChoice("Aim Part", {"Head", "UpperTorso", "HumanoidRootPart"}, 11)

-- Toggle Mobile Buttons (12, chỉ trên thiết bị cảm ứng)
local mobileControls = nil
if IS_TOUCH then
    makeToggle("Mobile Buttons", Config.MobileButtons, 12, function(v)
        Config.MobileButtons = v
        if mobileControls then
            mobileControls.Visible = v
        end
    end)
end

-- =========================================================
-- FOV CIRCLE (vẽ bằng UI — chạy cả PC và Mobile)
-- =========================================================
local fovFrame = Instance.new("Frame")
fovFrame.Name = "FOVCircle"
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.Size = UDim2.fromOffset(Config.AimFOV * 2, Config.AimFOV * 2)
fovFrame.BackgroundTransparency = 1
fovFrame.Visible = false
fovFrame.Parent = ScreenGui
Instance.new("UICorner", fovFrame).CornerRadius = UDim.new(0.5, 0)
local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Config.UITheme.Accent
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.3
fovStroke.Parent = fovFrame

-- =========================================================
-- ESP
-- =========================================================
local espObjects = {}

local function clearEsp(player)
    local obj = espObjects[player]
    if obj then
        if obj.box then obj.box:Destroy() end
        if obj.bill then obj.bill:Destroy() end
        espObjects[player] = nil
    end
end

local function createEsp(player)
    local obj = {}
    espObjects[player] = obj

    -- LƯU Ý: Box/Billboard phải được parent thì mới render (fix bản trước)
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESP_Box_" .. player.Name
    box.Size = Vector3.new(4, 6, 2)
    box.Transparency = 0.55
    box.ZIndex = 10
    box.AlwaysOnTop = true
    box.Adornee = nil
    box.Parent = Workspace
    obj.box = box

    local bill = Instance.new("BillboardGui")
    bill.Name = "ESP_Bill_" .. player.Name
    bill.Size = UDim2.fromOffset(160, 60)
    bill.StudsOffset = Vector3.new(0, 3.5, 0)
    bill.AlwaysOnTop = true
    bill.MaxDistance = Config.ESPMaxDistance
    bill.Enabled = false
    bill.Parent = Workspace
    obj.bill = bill

    obj.billFrame = Instance.new("Frame")
    obj.billFrame.BackgroundTransparency = 1
    obj.billFrame.Size = UDim2.fromScale(1, 1)
    obj.billFrame.Parent = bill

    local function addLabel(yOffset, h, name, textSize)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, h)
        l.Position = UDim2.fromOffset(0, yOffset)
        l.BackgroundTransparency = 1
        l.Name = name
        l.Font = Config.Font
        l.TextSize = textSize
        l.TextStrokeTransparency = 0.3
        l.TextColor3 = Color3.new(1, 1, 1)
        l.Parent = obj.billFrame
        return l
    end

    obj.nameLabel = addLabel(0, 16, "Name", 13)
    obj.hpLabel = addLabel(16, 14, "HP", 12)
    obj.distLabel = addLabel(30, 14, "Dist", 12)

    obj.hpBarBG = Instance.new("Frame")
    obj.hpBarBG.Size = UDim2.new(0.8, 0, 0, 4)
    obj.hpBarBG.Position = UDim2.new(0.1, 0, 0, 46)
    obj.hpBarBG.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    obj.hpBarBG.BorderSizePixel = 0
    obj.hpBarBG.Parent = obj.billFrame
    obj.hpBar = Instance.new("Frame")
    obj.hpBar.Size = UDim2.fromScale(1, 1)
    obj.hpBar.BackgroundColor3 = Color3.fromRGB(70, 200, 120)
    obj.hpBar.BorderSizePixel = 0
    obj.hpBar.Parent = obj.hpBarBG
end

local function updateEsp(player)
    local obj = espObjects[player]
    if not obj then return end

    if not Config.ESPEnabled then
        obj.box.Visible = false
        obj.bill.Enabled = false
        return
    end

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local head = char and char:FindFirstChild("Head")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if not root or not hum or hum.Health <= 0 or not head then
        obj.box.Adornee = nil
        obj.bill.Enabled = false
        return
    end

    local color = Color3.fromRGB(255, 80, 80)
    if Config.ShowTeamColor and player.TeamColor then
        local myTeam = LocalPlayer.Team
        color = (player.Team and player.Team ~= myTeam)
            and player.TeamColor.Color
            or Color3.fromRGB(80, 200, 255)
    end

    if Config.ShowBoxes then
        obj.box.Adornee = root
        obj.box.Color3 = color
        obj.box.Visible = true
    else
        obj.box.Visible = false
    end

    obj.bill.Adornee = head
    obj.bill.Enabled = true
    obj.bill.MaxDistance = Config.ESPMaxDistance   -- cập nhật live theo slider

    local rootMine = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local dist = rootMine
        and math.floor((rootMine.Position - root.Position).Magnitude)
        or math.floor((Camera.CFrame.Position - root.Position).Magnitude)

    obj.nameLabel.Text = player.Name
    obj.nameLabel.TextColor3 = color
    obj.nameLabel.Visible = Config.ShowName

    obj.hpLabel.Text = Config.ShowHP and ("%d HP"):format(math.floor(hum.Health)) or ""
    obj.hpLabel.TextColor3 = hum.Health / hum.MaxHealth > 0.5
        and Color3.fromRGB(70, 200, 120)
        or Color3.fromRGB(255, 100, 70)

    if Config.ShowHP and obj.hpBar and obj.hpBarBG then
        obj.hpBarBG.Visible = true
        obj.hpBar.Size = UDim2.fromScale(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 1)
    else
        obj.hpBarBG.Visible = false
    end

    obj.distLabel.Text = Config.ShowDistance and (dist .. " studs") or ""
    obj.distLabel.TextColor3 = Config.UITheme.SubText
end

-- =========================================================
-- AIM ASSIST
-- =========================================================
local aiming = false

-- Tâm ngắm: PC = theo chuột, Mobile = theo điểm chạm cuối / giữa màn hình
local aimOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
local function trackAimOrigin(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        aimOrigin = Vector2.new(input.Position.X, input.Position.Y + INSET_Y)
    end
end
UserInputService.InputBegan:Connect(trackAimOrigin)
UserInputService.InputChanged:Connect(trackAimOrigin)
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    aimOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end)

local function getAimTarget()
    local best, bestDist = nil, Config.AimFOV
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not Config.TeamCheck or player.Team ~= LocalPlayer.Team then
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                -- fallback: nếu AimPart không tồn tại (vd R6 không có UpperTorso)
                local part = char and (
                    char:FindFirstChild(Config.AimPart)
                    or char:FindFirstChild("HumanoidRootPart")
                )
                if part and hum and hum.Health > 0 then
                    local screen, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local d = (Vector2.new(screen.X, screen.Y) - aimOrigin).Magnitude
                        if d < bestDist then
                            bestDist = d
                            best = part
                        end
                    end
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    -- FOV circle
    local showFov = Config.ShowFOVCircle and Config.AimEnabled and (aiming or IS_TOUCH)
    fovFrame.Visible = showFov
    if showFov then
        fovFrame.Position = UDim2.fromOffset(aimOrigin.X, aimOrigin.Y)
        fovFrame.Size = UDim2.fromOffset(Config.AimFOV * 2, Config.AimFOV * 2)
    end

    -- ESP
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not espObjects[player] then createEsp(player) end
            updateEsp(player)
        end
    end

    -- aim
    if Config.AimEnabled and aiming then
        local target = getAimTarget()
        if target then
            local camPos = Camera.CFrame.Position
            local look = (target.Position - camPos).Unit
            local targetCFrame = CFrame.lookAt(camPos, camPos + look)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 - Config.AimSmoothing)
        end
    end
end)

Players.PlayerRemoving:Connect(clearEsp)

-- =========================================================
-- INPUT (PC)
-- =========================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Config.AimKey then
        aiming = true
    elseif input.KeyCode == Enum.KeyCode.M then
        Main.Visible = not Main.Visible
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Config.AimKey then
        aiming = false
    end
end)

-- Nút UI
MinBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
end)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    for player in pairs(espObjects) do clearEsp(player) end
end)

-- =========================================================
-- NÚT MOBILE (chỉ hiện trên thiết bị cảm ứng)
-- =========================================================
if IS_TOUCH then
    mobileControls = Instance.new("Frame")
    mobileControls.Name = "MobileControls"
    mobileControls.Size = UDim2.fromScale(1, 1)
    mobileControls.BackgroundTransparency = 1
    mobileControls.Visible = Config.MobileButtons
    mobileControls.Parent = ScreenGui

    -- Nút ☰ mở/đóng menu
    local menuBtn = Instance.new("TextButton")
    menuBtn.Size = UDim2.fromOffset(52, 52)
    menuBtn.Position = UDim2.new(1, -66, 0, 50)
    menuBtn.BackgroundColor3 = Config.UITheme.Panel
    menuBtn.BackgroundTransparency = 0.25
    menuBtn.Text = "☰"
    menuBtn.TextColor3 = Config.UITheme.Text
    menuBtn.Font = Config.Font
    menuBtn.TextSize = 24
    menuBtn.BorderSizePixel = 0
    menuBtn.Parent = mobileControls
    Instance.new("UICorner", menuBtn).CornerRadius = UDim.new(0, 10)

    menuBtn.MouseButton1Click:Connect(function()
        Main.Visible = not Main.Visible
    end)

    -- Nút AIM (tap = bật/tắt aim, thay cho giữ phím E)
    local aimBtn = Instance.new("TextButton")
    aimBtn.Size = UDim2.fromOffset(92, 92)
    aimBtn.Position = UDim2.new(1, -116, 1, -112)
    aimBtn.BackgroundColor3 = Config.UITheme.Off
    aimBtn.BackgroundTransparency = 0.35
    aimBtn.Text = "AIM\nOFF"
    aimBtn.TextColor3 = Color3.new(1, 1, 1)
    aimBtn.Font = Config.Font
    aimBtn.TextSize = 16
    aimBtn.BorderSizePixel = 0
    aimBtn.Parent = mobileControls
    Instance.new("UICorner", aimBtn).CornerRadius = UDim.new(0.5, 0)

    aimBtn.MouseButton1Click:Connect(function()
        aiming = not aiming
        aimBtn.Text = aiming and "AIM\nON" or "AIM\nOFF"
        aimBtn.BackgroundColor3 = aiming and Config.UITheme.On or Config.UITheme.Off
    end)
end

print("[AimEspHub v3] Loaded!", IS_TOUCH
    and "Mobile: ☰ = menu, AIM = bật/tắt. Slider FOV/Smoothing/Distance + AimPart có trong menu."
    or "PC: M = menu, giữ E = aim. Slider FOV/Smoothing/Distance + AimPart có trong menu.")
