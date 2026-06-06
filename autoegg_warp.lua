local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local E_KEY = 0x45
local SCAN_RADIUS = 1000

local function getChar()
    return LP.Character
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local EGG_FOLDERS = {"EpicEgg", "RareEgg"}

local function findEggs()
    local results = {}
    for _, folderName in ipairs(EGG_FOLDERS) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("BasePart") or child:IsA("Model") then
                    table.insert(results, child)
                end
            end
        end
    end
    return results
end

local function getEggPosition(egg)
    if egg:IsA("BasePart") then
        return egg.Position
    end
    local primary = egg:FindFirstChild("PrimaryPart") or egg:FindFirstChildWhichIsA("BasePart")
    return primary and primary.Position or egg:GetModelCFrame().Position
end

local function warpTo(pos)
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = CFrame.new(pos.X, pos.Y + 2, pos.Z)
    end
end

local function holdE(duration)
    keypress(E_KEY)
    wait(duration or 0.5)
    keyrelease(E_KEY)
end

local function interactAt()
    holdE(1)
end

while true do
    local hrp = getHRP()
    if not hrp then
        LP.CharacterAdded:Wait()
    end

    local eggs = findEggs()
    if #eggs > 0 then
        local chosen = eggs[math.random(1, #eggs)]
        local pos = getEggPosition(chosen)
        if pos then
            warpTo(pos)
            wait(0.2)
            interactAt()
        end
    end

    wait(0.3)
end
