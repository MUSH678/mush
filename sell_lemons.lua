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
local uiVisible = true

-- UI
local uiX, uiY = 30, 30
local isDragging = false
local dragOffX, dragOffY = 0, 0
local prevPressed = false
local prevKeyStates = {}

local function isKeyJustPressed(keycode)
    local pressed = iskeypressed(keycode)
    local prev = prevKeyStates[keycode]
    prevKeyStates[keycode] = pressed
    return pressed and (prev == nil or not prev)
end

local bg = Drawing.new("Square")
bg.Position = Vector2.new(uiX, uiY); bg.Size = Vector2.new(210, 82)
bg.Color = Color3.fromRGB(14, 14, 20); bg.Filled = true; bg.Visible = true

local border = Drawing.new("Square")
border.Position = Vector2.new(uiX-1, uiY-1); border.Size = Vector2.new(212, 84)
border.Color = Color3.fromRGB(55, 58, 75); border.Filled = false; border.Thickness = 1; border.Visible = true

local titleTx = Drawing.new("Text")
titleTx.Position = Vector2.new(uiX+10, uiY+4); titleTx.Text = "SELL LEMONS"
titleTx.Color = Color3.fromRGB(210, 215, 240); titleTx.Size = 13; titleTx.Font = Drawing.Fonts.UI; titleTx.Visible = true

local buyTx = Drawing.new("Text")
buyTx.Position = Vector2.new(uiX+10, uiY+24); buyTx.Text = "Auto Buy: [ OFF ]"
buyTx.Color = Color3.fromRGB(120, 120, 130); buyTx.Size = 10; buyTx.Font = Drawing.Fonts.UI; buyTx.Visible = true

local farmTx = Drawing.new("Text")
farmTx.Position = Vector2.new(uiX+10, uiY+38); farmTx.Text = "Lemon Farm: [ OFF ]"
farmTx.Color = Color3.fromRGB(120, 120, 130); farmTx.Size = 10; farmTx.Font = Drawing.Fonts.UI; farmTx.Visible = true

local hintTx = Drawing.new("Text")
hintTx.Position = Vector2.new(uiX+10, uiY+56); hintTx.Text = "T:Buy  Y:Farm  U:Stop  F1:Hide"
hintTx.Color = Color3.fromRGB(80, 85, 95); hintTx.Size = 8; hintTx.Font = Drawing.Fonts.UI; hintTx.Visible = true

local function updateUI()
    if autoBuyActive then
        buyTx.Text = "Auto Buy: [ ON  ]"
        buyTx.Color = Color3.fromRGB(60, 220, 110)
    else
        buyTx.Text = "Auto Buy: [ OFF ]"
        buyTx.Color = Color3.fromRGB(120, 120, 130)
    end
    if lemonFarmActive then
        farmTx.Text = "Lemon Farm: [ ON  ]"
        farmTx.Color = Color3.fromRGB(60, 220, 110)
    else
        farmTx.Text = "Lemon Farm: [ OFF ]"
        farmTx.Color = Color3.fromRGB(120, 120, 130)
    end
end

local function updatePos(dx, dy)
    uiX, uiY = dx, dy
    bg.Position = Vector2.new(uiX, uiY)
    border.Position = Vector2.new(uiX-1, uiY-1)
    titleTx.Position = Vector2.new(uiX+10, uiY+4)
    buyTx.Position = Vector2.new(uiX+10, uiY+24)
    farmTx.Position = Vector2.new(uiX+10, uiY+38)
    hintTx.Position = Vector2.new(uiX+10, uiY+56)
end

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
    if not _G.SellLemonsActive then
        for _, e in ipairs({bg, border, titleTx, buyTx, farmTx, hintTx}) do e.Visible = false end
        return
    end

    local mx, my = player:GetMouse().X, player:GetMouse().Y
    local pressed = ismouse1pressed()
    local justPressed = pressed and not prevPressed
    local justReleased = not pressed and prevPressed

    -- F1 toggle UI
    if isKeyJustPressed(112) then
        uiVisible = not uiVisible
        for _, e in ipairs({bg, border, titleTx, buyTx, farmTx, hintTx}) do e.Visible = uiVisible end
    end

    -- drag
    if justPressed then
        if mx >= uiX and mx <= uiX+210 and my >= uiY and my <= uiY+18 then
            isDragging = true; dragOffX = mx - uiX; dragOffY = my - uiY
        end
    end
    if justReleased then isDragging = false end
    if isDragging and pressed then updatePos(mx - dragOffX, my - dragOffY) end
    prevPressed = pressed

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
            updateUI()
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
            updateUI()
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
            updateUI()
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
