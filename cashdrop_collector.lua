local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

if not Drawing then print("[CashDrop] Drawing API not supported"); return end

-- UI vars
local uiX, uiY = 50, 150
local W, H = 180, 80
local isDragging, dragOffX, dragOffY = false, 0, 0
local enabled = true
local uiVisible = true
local uiElements = {}
local Mouse = Players.LocalPlayer:GetMouse()
local prevPressed = false
local lastF1 = 0

local function makeSquare(x, y, w, h, r, g, b, filled, thick)
    local s = Drawing.new("Square")
    s.Position = Vector2.new(x, y); s.Size = Vector2.new(w, h)
    s.Color = Color3.fromRGB(r, g, b); s.Filled = filled
    s.Thickness = thick or 1; s.Visible = true
    table.insert(uiElements, s); return s
end
local function makeText(x, y, txt, r, g, b, sz)
    local t = Drawing.new("Text")
    t.Position = Vector2.new(x, y); t.Text = txt
    t.Color = Color3.fromRGB(r, g, b); t.Size = sz
    t.Font = Drawing.Fonts.UI; t.Visible = true
    table.insert(uiElements, t); return t
end

-- Build UI
local bgB  = makeSquare(uiX-1, uiY-1, W+2, H+2, 55, 58, 75, false)
local bgM  = makeSquare(uiX, uiY, W, H, 14, 14, 20, true)
local tiBg = makeSquare(uiX, uiY, W, 22, 24, 24, 34, true)
local tiAc = makeSquare(uiX, uiY, 3, 22, 255, 200, 50, true)
local tiTx = makeText(uiX+10, uiY+5, "CASH DROP", 255, 200, 50, 12)
local stBg = makeSquare(uiX+6, uiY+30, W-12, 18, 22, 22, 30, true)
local stTx = makeText(uiX+10, uiY+32, "Running...", 160, 170, 190, 10)
local btnBg = makeSquare(uiX+6, uiY+54, W-12, 20, 22, 70, 32, true)
local btnBd = makeSquare(uiX+5, uiY+53, W-10, 22, 45, 130, 60, false)
local btnTx = makeText(uiX+10, uiY+56, "[ STOP ]", 230, 235, 245, 10)

local function updateUI()
    stTx.Text = enabled and "Running..." or "Paused"
    stTx.Color = enabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 100, 100)
    btnTx.Text = enabled and "[ STOP ]" or "[ START ]"
    btnBg.Color = enabled and Color3.fromRGB(22, 70, 32) or Color3.fromRGB(55, 22, 22)
    btnBd.Color = enabled and Color3.fromRGB(45, 130, 60) or Color3.fromRGB(75, 78, 90)
end

local function updatePos(dx, dy)
    uiX, uiY = dx, dy
    bgB.Position  = Vector2.new(uiX-1,  uiY-1)
    bgM.Position  = Vector2.new(uiX,    uiY)
    tiBg.Position = Vector2.new(uiX,    uiY)
    tiAc.Position = Vector2.new(uiX,    uiY)
    tiTx.Position = Vector2.new(uiX+10, uiY+5)
    stBg.Position = Vector2.new(uiX+6,  uiY+30)
    stTx.Position = Vector2.new(uiX+10, uiY+32)
    btnBg.Position= Vector2.new(uiX+6,  uiY+54)
    btnBd.Position= Vector2.new(uiX+5,  uiY+53)
    btnTx.Position= Vector2.new(uiX+10, uiY+56)
end

-- Logic
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

local function findCashDrops()
    local list = {}
    local folder = Workspace:FindFirstChild("CashDrops")
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            if child.Name == "CashDrop" then
                local pos = findPos(child)
                if not pos then
                    for _, c in ipairs(child:GetChildren()) do
                        pos = findPos(c)
                        if pos then break end
                    end
                end
                if pos then table.insert(list, pos) end
            end
        end
    end
    return list
end

-- Main loop
print("[CashDrop] Starting...")
updateUI()
while true do
    local mx, my = Mouse.X, Mouse.Y
    local pressed = ismouse1pressed()
    local justPressed = pressed and not prevPressed
    local justReleased = not pressed and prevPressed

    -- F1 toggle UI
    local f1down = pcall(function() return game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.F1) end)
    if f1down and tick() - lastF1 > 0.3 then
        lastF1 = tick()
        uiVisible = not uiVisible
        for _, e in ipairs(uiElements) do e.Visible = uiVisible end
    end

    if justPressed then
        -- title drag
        if mx >= uiX and mx <= uiX+W and my >= uiY and my <= uiY+22 then
            isDragging = true; dragOffX = mx - uiX; dragOffY = my - uiY
        end
        -- toggle button
        local bx, by = btnBg.Position.X, btnBg.Position.Y
        local bw, bh = btnBg.Size.X, btnBg.Size.Y
        if mx >= bx and mx <= bx+bw and my >= by and my <= by+bh and not isDragging then
            enabled = not enabled
            updateUI()
        end
    end
    if justReleased then isDragging = false end
    if isDragging and pressed then updatePos(mx - dragOffX, my - dragOffY) end
    prevPressed = pressed

    -- Collect logic
    if enabled then
        local drops = findCashDrops()
        if #drops > 0 then
            local origin
            local hrp = getHRP()
            if hrp then
                origin = hrp.CFrame
                for _, pos in ipairs(drops) do
                    hrp = getHRP()
                    if not hrp then break end
                    hrp.CFrame = CFrame.new(pos.X, pos.Y + 1, pos.Z)
                    wait()
                end
                wait(0.8)
                hrp = getHRP()
                if hrp and origin then
                    hrp.CFrame = origin
                    wait()
                end
            end
        end
    end

    wait()
end
