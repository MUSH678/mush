local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local function getHRP()
    local char = Players.LocalPlayer and Players.LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function findPos(obj)
    local ok, x = pcall(function() return obj.WorldPosition.X end)
    if ok and type(x) == "number" then return obj.WorldPosition end
    local p = obj.Position
    ok, x = pcall(function() return p.X end)
    if ok and type(x) == "number" then return p end
    local cf = obj.CFrame
    ok, x = pcall(function() return cf.X end)
    if ok and type(x) == "number" then return Vector3.new(cf.X, cf.Y, cf.Z) end
    return nil
end

local lever = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Sewer") and
              Workspace.Map.Sewer:FindFirstChild("DoorsGreen") and
              Workspace.Map.Sewer.DoorsGreen:FindFirstChild("Lever (Green)")

if not lever then
    print("[Lever] Not found")
    return
end

local pos = findPos(lever)
if not pos then
    for _, c in ipairs(lever:GetChildren()) do
        pos = findPos(c)
        if pos then break end
    end
end

if not pos then
    print("[Lever] No position found")
    return
end

local hrp = getHRP()
if hrp then
    hrp.CFrame = CFrame.new(pos.X, pos.Y + 2, pos.Z + 2)
    print("[Lever] Warped to " .. tostring(pos))
end
