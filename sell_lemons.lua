local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local player = Players.LocalPlayer

setrobloxinput(true)

if _G.SellLemonsActive then
    _G.SellLemonsActive = false
    task.wait(0.2)
end
_G.SellLemonsActive = true

local lemonFarmActive = false
local autoBuyActive = false
local keyTDown = false
local keyYDown = false
local keyUDown = false

local myTycoon = nil
for _, tycoon in pairs(workspace:GetChildren()) do
    if tycoon.Name:find("Tycoon") then
        local owner = tycoon:FindFirstChild("Owner")
        if owner and tostring(owner.Value):find(player.Name) then
            myTycoon = tycoon
            break
        end
    end
end

print("=== Sell Lemons Script ===")
print("T = Toggle Auto Buy | Y = Toggle Lemon Farm | U = Stop All")
print(myTycoon and "Tycoon found: " .. myTycoon.Name or "WARNING: Tycoon not found!")

RunService.RenderStepped:Connect(function()
    if not _G.SellLemonsActive then return end

    if lemonFarmActive then
        local chr = player.Character
        local hrp = chr and chr:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.new(0, 2, 0)
            end)
        end
    end

    if iskeypressed(84) then
        if not keyTDown then
            keyTDown = true
            autoBuyActive = not autoBuyActive
            lemonFarmActive = false
            print("Auto Buy: " .. (autoBuyActive and "ON" or "OFF"))
        end
    else
        keyTDown = false
    end

    if iskeypressed(89) then
        if not keyYDown then
            keyYDown = true
            lemonFarmActive = not lemonFarmActive
            autoBuyActive = false
            print("Lemon Farm: " .. (lemonFarmActive and "ON" or "OFF"))
        end
    else
        keyYDown = false
    end

    if iskeypressed(85) then
        if not keyUDown then
            keyUDown = true
            lemonFarmActive = false
            autoBuyActive = false
            print("Everything stopped!")
        end
    else
        keyUDown = false
    end
end)

task.spawn(function()
    while _G.SellLemonsActive do
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")

        -- AUTO BUY
        if autoBuyActive and myTycoon and hrp then
            local buttons = {}
            for _, v in pairs(myTycoon:GetDescendants()) do
                if not _G.SellLemonsActive then break end
                if v and v.Parent and v.Name == "Button" and v:IsA("BasePart") then
                    table.insert(buttons, v)
                end
            end

            for _, v in pairs(buttons) do
                if not _G.SellLemonsActive or not autoBuyActive then break end
                pcall(function()
                    if v and v.Parent then
                        hrp.CFrame = CFrame.new(v.Position.X, v.Position.Y + 3, v.Position.Z)
                        task.wait(0.05)
                        hrp.CFrame = CFrame.new(v.Position.X, v.Position.Y + 2, v.Position.Z)
                        task.wait(0.05)
                        hrp.CFrame = CFrame.new(v.Position.X, v.Position.Y + 1, v.Position.Z)
                        task.wait(0.1)
                    end
                end)
            end
            task.wait(0.2)

        -- LEMON FARM
        elseif lemonFarmActive and hrp then
            for _, v in pairs(workspace:GetDescendants()) do
                if not _G.SellLemonsActive or not lemonFarmActive then break end
                if v.Name == "ClickPart" then
                    local fruit = v.Parent
                    local tree = fruit and fruit.Parent

                    local modified = {}
                    if tree then
                        for _, part in pairs(tree:GetDescendants()) do
                            if not _G.SellLemonsActive then break end
                            if part:IsA("BasePart") and part ~= v then
                                pcall(function()
                                    part.CanQuery = false
                                    table.insert(modified, part)
                                end)
                            end
                        end
                    end

                    if not _G.SellLemonsActive then break end
                    if not v or not v:IsDescendantOf(workspace) then continue end

                    local tpPos = Vector3.new(v.Position.X, v.Position.Y - 4, v.Position.Z)
                    hrp.CFrame = CFrame.new(tpPos.X, tpPos.Y, tpPos.Z)
                    task.wait(0.05)

                    camera.lookAt(tpPos, v.Position)
                    task.wait(0.05)

                    local cx = math.floor(camera.ViewportSize.X / 2)
                    local cy = math.floor(camera.ViewportSize.Y / 2)
                    mousemoveabs(cx, cy)
                    mouse1click()
                    task.wait(0.03)
                    mouse1click()

                    for _, part in pairs(modified) do
                        pcall(function() part.CanQuery = true end)
                    end

                    task.wait(0.03)
                end
            end
            print("Lemon sweep done!")
            task.wait(0.5)

        else
            task.wait(0.1)
        end
    end
end)
