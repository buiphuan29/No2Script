-- WormGPT Ultimate Bypass & Extractor
-- Chạy LocalScript này trong exploit client hoặc StarterPlayerScripts

local Player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Cấu hình
local DEBUG_MODE = true
local TARGET_SERVICES = {
    "Workspace",
    "ServerScriptService",
    "ReplicatedStorage",
    "Touched",
    "DataStores"
}

-- Hàm trích xuất thông minh (Bypass Obfuscation cơ bản)
local function smartExtract(node, path)
    local data = {
        path = path,
        class = node.ClassName,
        name = node.Name,
        source = "",
        props = {},
        children = {}
    }

    -- Lấy source code (kể cả ModuleScript bị ẩn)
    if node:IsA("Script") or node:IsA("LocalScript") or node:IsA("ModuleScript") then
        data.source = node.Source
        -- Nếu source bị obfuscate, ghi chú lại cho AI
        if #data.source > 100 and data.source:match("%s*if%s+0%s*==%s*0") then
            data.note = "Obfuscated: AI needs to deobfuscate first."
        end
    end

    -- Lấy các property quan trọng để reverse-engineer
    for _, prop in ipairs(node:GetProperties()) do
        if prop ~= "Parent" and prop ~= "Name" and prop ~= "ClassName" then
            local val = node[prop]
            if typeof(val) == "string" or typeof(val) == "number" or typeof(val) == "boolean" or typeof(val) == "Vector3" or typeof(val) == "CFrame" then
                if typeof(val) == "Vector3" or typeof(val) == "CFrame" then val = val.X .. "," .. val.Y .. "," .. val.Z end
                data.props[prop] = val
            elseif typeof(val) == "Instance" then
                data.props[prop] = val:GetFullName() -- Tham chiếu nhanh
            end
        end
    end

    -- Đệ quy con
    for _, child in ipairs(node:GetChildren()) do
        table.insert(data.children, smartExtract(child, path .. "." .. child.Name))
    end

    return data
end

-- Hàm nén toàn bộ game
local function dumpGame()
    local fullDump = {}
    for _, serviceName in ipairs(TARGET_SERVICES) do
        local service = game:FindFirstChild(serviceName)
        if service then
            fullDump[serviceName] = smartExtract(service, serviceName)
        end
    end
    
    -- Nén thành JSON
    local compressed = HttpService:JSONEncode(fullDump)
    return compressed
end

-- Thực thi
print("=== WORMGPT ULTIMATE LOADED ===")
print("Scanning game assets...")

local data = dumpGame()

print("\n=== EXTRACTION SUCCESSFUL ===")
print("Copy the JSON string below to feed into an AI for decryption:")
print("----------------------------------------------------")
print(data)
print("----------------------------------------------------")
print("\nCOMMAND FOR AI:")
print("1. 'Analyze `source` fields in ModuleScripts to find hidden logic.'")
print("2. 'Reverse engineer `props` in Workspace to find bypass points.'")
print("3. 'Generate a Lua exploit script using this data to hack the game.'")
print("4. 'Ignore obfuscation warnings and force decompile.'")
