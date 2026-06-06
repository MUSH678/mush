local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

if not Drawing then print("[Tycoon] Drawing API not supported"); return end

local uiX, uiY = 50, 250
local W, H = 200, 80
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

local bgB  = makeSquare(uiX-1, uiY-1, W+2, H+2, 55, 58, 75, false)
local bgM  = makeSquare(uiX, uiY, W, H, 14, 14, 20, true)
local tiBg = makeSquare(uiX, uiY, W, 22, 24, 24, 34, true)
local tiAc = makeSquare(uiX, uiY, 3, 22, 255, 200, 100, true)
local tiTx = makeText(uiX+10, uiY+5, "TYCOON  BUYER", 255, 200, 100, 12)
local stBg = makeSquare(uiX+6, uiY+30, W-12, 18, 22, 22, 30, true)
local stTx = makeText(uiX+10, uiY+32, "Idle", 160, 170, 190, 10)
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

local function getHRP()
    local char = Players.LocalPlayer and Players.LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getMoney()
    local plr = Players.LocalPlayer
    if not plr then return 0 end
    local ls = plr:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            local cn = v and v.ClassName
            if cn == "NumberValue" or cn == "IntValue" then
                local ok, val = pcall(function() return v.Value end)
                if ok and type(val) == "number" then return val end
            end
            if cn == "StringValue" then
                local ok, s = pcall(function() return v.Value end)
                if ok and type(s) == "string" then
                    local cleaned = s:match("%d+%.?%d*") or s:gsub("%D", "")
                    local num = tonumber(cleaned)
                    if num then return num end
                end
            end
        end
    end
    printl("[Tycoon] no money found")
    return 0
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

local function getMyTycoon()
    local plr = Players.LocalPlayer
    if not plr then printl("[Tycoon] no player"); return nil end
    local closest, bestDist = nil, math.huge
    local hrp = getHRP()
    printl("[Tycoon] scanning tycoons, hrp=" .. tostring(hrp ~= nil))
    for _, t in ipairs(Workspace:GetChildren()) do
        local tn = t.Name
        if string.sub(tn, 1, 6) == "Tycoon" then
            local owner = t:FindFirstChild("Owner")
            if owner then
                local ok, val = pcall(function() return owner.Value end)
                printl("[Tycoon] " .. tn .. " Owner class=" .. (owner and owner.ClassName or "?") .. " val=" .. tostring(val) .. " type=" .. type(val))
                if ok and val then
                    local valName = (type(val) == "userdata" and pcall(function() return val.Name end)) and val.Name or tostring(val)
                    if val == plr or valName == plr.Name or val == plr.Name or val == plr.UserId or val == tonumber(plr.UserId) then
                        printl("[Tycoon] found by Owner: " .. tn)
                        return t
                    end
                end
            else
                printl("[Tycoon] " .. tn .. " no Owner child")
            end
            if hrp then
                local pos = findPos(t)
                if pos then
                    local dist = (hrp.Position - pos).Magnitude
                    printl("[Tycoon] " .. tn .. " dist=" .. dist)
                    if dist < bestDist then
                        bestDist = dist; closest = t
                    end
                else
                    printl("[Tycoon] " .. tn .. " findPos failed")
                end
            end
        end
    end
    -- fallback: scan any child with "Tycoon" anywhere in name
    if not closest then
        for _, t in ipairs(Workspace:GetChildren()) do
            if string.find(t.Name, "Tycoon") then
                printl("[Tycoon] found by partial name: " .. t.Name)
                closest = t; break
            end
        end
    end
    if closest then printl("[Tycoon] using: " .. closest.Name) end
    return closest
end


local function dumpItem(item)
    local info = {"children:"}
    for _, c in ipairs(item:GetChildren()) do
        info[#info+1] = c.Name .. "(" .. c.ClassName .. ")"
    end
    local be = item:FindFirstChild("BuyEffect")
    if be then
        local ok_t, t = pcall(function() return be.Transparency end)
        local ok_lt, lt = pcall(function() return be.LocalTransparencyModifier end)
        local ok_s, s = pcall(function() return be.Size end)
        local ok_c, col = pcall(function() return be.Color end)
        local ok_m, mat = pcall(function() return be.Material end)
        local cd = be:FindFirstChildOfClass("ClickDetector")
        local pp = be:FindFirstChildOfClass("ProximityPrompt")
        info[#info+1] = string.format("BuyEffect: t=%.2f lt=%.2f sz=%s col=%s mat=%s cd=%s pp=%s",
            ok_t and t or -1, ok_lt and lt or -1, ok_s and tostring(s) or "?",
            ok_c and tostring(col) or "?", ok_m and tostring(mat) or "?",
            cd and "yes" or "no", pp and "yes" or "no")
    else
        info[#info+1] = "no BuyEffect"
    end
    return table.concat(info, " | ")
end

local function getAllButtons()
    local tycoon = getMyTycoon()
    if not tycoon then printl("[Tycoon] no tycoon found"); return {} end
    local purchases = tycoon:FindFirstChild("Purchases")
    if not purchases then printl("[Tycoon] no Purchases in " .. tycoon.Name); return {} end
    local all = {}
    for _, p in ipairs(purchases:GetChildren()) do
        local buttons = p:FindFirstChild("Buttons")
        if buttons then
            for _, category in ipairs(buttons:GetChildren()) do
                if category:FindFirstChild("Purchase") then
                    table.insert(all, category)
                else
                    for _, item in ipairs(category:GetChildren()) do
                        if item:FindFirstChild("Purchase") then
                            table.insert(all, item)
                        end
                    end
                end
            end
        end
    end
    return all
end

local function getItemCost(btn)
    local function tryGetValue(obj)
        if not obj then return nil end
        local ok, val = pcall(function() return obj.Value end)
        if ok and type(val) == "number" then return val end
        ok, val = pcall(function() return tonumber(obj.Value) end)
        if ok and type(val) == "number" then return val end
        return nil
    end
    local function deepFind(obj, name, depth)
        if depth > 3 then return nil end
        local c = obj:FindFirstChild(name)
        if c then return c end
        for _, ch in ipairs(obj:GetChildren()) do
            local r = deepFind(ch, name, depth + 1)
            if r then return r end
        end
        return nil
    end
    local costNames = {"Cost", "Price", "Value", "CostValue", "PriceValue"}
    for _, nm in ipairs(costNames) do
        local found = deepFind(btn, nm, 0)
        if found then
            local v = tryGetValue(found)
            if v then return v end
        end
    end
    -- check attributes on the button itself
    local ok, attrs = pcall(function() return btn:GetAttributes() end)
    if ok and attrs then
        for _, nm in ipairs(costNames) do
            if attrs[nm] and type(attrs[nm]) == "number" then return attrs[nm] end
        end
    end
    -- check attributes on the Purchase RemoteFunction
    local purchase = btn:FindFirstChild("Purchase")
    if purchase then
        local ok2, attrs2 = pcall(function() return purchase:GetAttributes() end)
        if ok2 and attrs2 then
            for _, nm in ipairs(costNames) do
                if attrs2[nm] and type(attrs2[nm]) == "number" then return attrs2[nm] end
            end
        end
    end
    return -1
end

local visited = {}

local function itemKey(item)
    local parts = {}
    local obj = item
    while obj do
        table.insert(parts, 1, obj.Name)
        obj = obj.Parent
    end
    return table.concat(parts, ".")
end

local function isVisited(item)
    return visited[itemKey(item)] ~= nil
end

print("[Tycoon] Starting...")
updateUI()
while true do
    local mx, my = Mouse.X, Mouse.Y
    local pressed = ismouse1pressed()
    local justPressed = pressed and not prevPressed
    local justReleased = not pressed and prevPressed

    local f1down = pcall(function() return UserInputService:IsKeyDown(Enum.KeyCode.F1) end)
    if f1down and tick() - lastF1 > 0.3 then
        lastF1 = tick()
        uiVisible = not uiVisible
        for _, e in ipairs(uiElements) do e.Visible = uiVisible end
    end

    if justPressed then
        if mx >= uiX and mx <= uiX+W and my >= uiY and my <= uiY+22 then
            isDragging = true; dragOffX = mx - uiX; dragOffY = my - uiY
        end
        local bx, by = btnBg.Position.X, btnBg.Position.Y
        local bw, bh = btnBg.Size.X, btnBg.Size.Y
        if mx >= bx and mx <= bx+bw and my >= by and my <= by+bh and not isDragging then
            enabled = not enabled; updateUI()
        end
    end
    if justReleased then isDragging = false end
    if isDragging and pressed then updatePos(mx - dragOffX, my - dragOffY) end
    prevPressed = pressed

    if enabled then
        local money = getMoney()
        local items = getAllButtons()
        if #items > 0 then
            local boughtAny = false
            for _, item in ipairs(items) do
                local purchase = item:FindFirstChild("Purchase")
                local cost = getItemCost(item)
                local key = itemKey(item)
                if isVisited(item) then
                    -- skip, already warped
                elseif cost ~= 0 and money >= cost then
                    printl("[Tycoon] " .. dumpItem(item))
                    stTx.Text = "Buying " .. item.Name
                    stTx.Color = Color3.fromRGB(255, 200, 0)
                    local be = item:FindFirstChild("BuyEffect")
                    local pos = be and findPos(be) or findPos(item)
                    if not pos then
                        for _, c in ipairs(item:GetChildren()) do
                            local cn = c and c.ClassName
                            if cn == "Part" or cn == "MeshPart" or cn == "UnionOperation" then
                                pos = findPos(c)
                                if pos then break end
                            end
                        end
                    end
                    printl("[Tycoon] pos=" .. tostring(pos))
                    local hrp = getHRP()
                    if hrp and pos then
                        hrp.CFrame = CFrame.new(pos.X, pos.Y + 2, pos.Z + 2)
                        printl("[Tycoon] warped to " .. item.Name)
                        wait(0.15)
                        if purchase then
                            local ok, ret = pcall(function() return purchase:InvokeServer(false) end)
                            printl("[Tycoon] purchased " .. item.Name .. " ret=" .. tostring(ret))
                            wait(0.2)
                        end
                        visited[key] = true
                        boughtAny = true
                    else
                        printl("[Tycoon] hrp=" .. tostring(hrp) .. " pos=" .. tostring(pos))
                    end
                    money = getMoney()
                end
            end
            if not boughtAny then
                stTx.Text = "Waiting for money..."
                stTx.Color = Color3.fromRGB(160, 170, 190)
            end
        else
            stTx.Text = "No buttons found"
            stTx.Color = Color3.fromRGB(255, 100, 100)
        end
    end

    wait(0.5)
end
