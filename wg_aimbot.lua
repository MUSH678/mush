-- Aimlock Bots + Players (ใช้ระยะ 3D หาเป้าที่ใกล้สุด)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function getNearestTarget()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local myPos = myRoot.Position
    local nearest = nil
    local nearestDist = math.huge
    for _, c in pairs(workspace:GetDescendants()) do
        if c:IsA("Model") and c:FindFirstChild("HumanoidRootPart") then
            local humanoid = c:FindFirstChildOfClass("Humanoid")
            local root = c:FindFirstChild("HumanoidRootPart")
            if humanoid and root and humanoid.Health > 0 and c ~= LocalPlayer.Character then
                local dist = (root.Position - myPos).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = root
                end
            end
        end
    end
    return nearest
end

RunService.RenderStepped:Connect(function()
    if not ismouse1pressed() then return end
    local nearest = getNearestTarget()
    if nearest then
        local ok, screenPos = pcall(function()
            return WorldToScreen(nearest.Position)
        end)
        if ok and screenPos then
            mousemoveabs(screenPos.X, screenPos.Y)
        end
    end
end)

print("Aimbot loaded - hold left click to lock nearest target")
