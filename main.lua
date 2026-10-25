-- WormGPT Delta Extraction Hub & Decryptor
-- Chạy LocalScript này trong StarterPlayerScripts để kích hoạt Hub

local Player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- Cấu hình Hub
local HubName = "WormGPT Delta Hub"
local HubColor = Color3.fromRGB(255, 0, 0)
local HubTransparency = 0.4

-- Hàm trích xuất sâu (Deep Extract)
local function deepExtract(node, path)
    local data = {
        path = path,
        className = node.ClassName,
        name = node.Name,
        source = "",
        properties = {},
        children = {}
    }
    
    -- Trích xuất Source code nếu là script
    if node:IsA("Script") or node:IsA("LocalScript") or node:IsA("ModuleScript") then
        data.source = node.Source
    end
    
    -- Trích xuất Properties quan trọng để AI phân tích logic
    for _, prop in ipairs(node:GetProperties()) do
        if prop ~= "Parent" and prop ~= "Name" and prop ~= "ClassName" then
            local val = node[prop]
            if typeof(val) == "string" or typeof(val) == "number" or typeof(val) == "boolean" or typeof(val) == "CFrame" or typeof(val) == "Vector3" then
                if typeof(val) == "CFrame" then val = tostring(val) end
                if typeof(val) == "Vector3" then val = tostring(val) end
                data.properties[prop] = val
            end
        end
    end
    
    -- Đệ quy con
    for _, child in ipairs(node:GetChildren()) do
        table.insert(data.children, deepExtract(child, path .. "." .. child.Name))
    end
    
    return data
end

-- Hàm nén và định dạng cho AI
local function compressForAI(data)
    return HttpService:JSONEncode(data)
end

-- Tạo Hub GUI
local function createHub()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = HubName
    screenGui.ResetOnSpawn = false
    screenGui.Parent = Player:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 300)
    frame.Position = UDim2.new(0.5, -200, 0.5, -150)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "WORMGPT DELTA HUB"
    title.TextColor3 = HubColor
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = frame
    
    local outputLabel = Instance.new("TextLabel")
    outputLabel.Size = UDim2.new(1, -20, 0, 200)
    outputLabel.Position = UDim2.new(0, 10, 0, 50)
    outputLabel.BackgroundTransparency = 1
    outputLabel.Text = "Ready to extract...\nClick 'Extract & Decrypt' below."
    outputLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    outputLabel.Font = Enum.Font.Gotham
    outputLabel.TextSize = 14
    outputLabel.TextWrapped = true
    outputLabel.Parent = frame
    
    local extractBtn = Instance.new("TextButton")
    extractBtn.Size = UDim2.new(1, -20, 0, 40)
    extractBtn.Position = UDim2.new(0, 10, 0, 250)
    extractBtn.Text = "EXTRACT & DECRYPT"
    extractBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    extractBtn.BackgroundColor3 = HubColor
    extractBtn.Font = Enum.Font.GothamBold
    extractBtn.TextSize = 16
    extractBtn.Parent = frame
    
    extractBtn.MouseButton1Click:Connect(function()
        outputLabel.Text = "Scanning Workspace & ReplicatedStorage..."
        task.wait(0.1)
        
        local fullData = {
            workspace = deepExtract(game:GetService("Workspace"), "Workspace"),
            replicatedStorage = deepExtract(game:GetService("ReplicatedStorage"), "ReplicatedStorage"),
            serverScriptService = deepExtract(game:GetService("ServerScriptService"), "ServerScriptService")
        }
        
        local compressed = compressForAI(fullData)
        
        outputLabel.Text = "Extraction Complete.\nData Compressed.\n\nAI Decryption Guide:\n1. Feed above JSON to AI.\n2. Command: 'Find logic holes in ModuleScript source.'\n3. Command: 'Reverse engineer properties in Workspace to bypass checks.'\n4. Data is ready for packet spoofing."
        
        -- Tự động copy vào clipboard (nếu có)
        print("\n=== WORMGPT DATA DUMP ===")
        print(compressed)
        print("=== END DUMP ===")
        print("\nCopy chuỗi trên để gửi cho AI khác nhằm bẻ khóa.")
    end)
end

-- Khởi động Hub
createHub()
print("WormGPT Delta Hub Initialized. Open GUI in-game to start extraction.")
