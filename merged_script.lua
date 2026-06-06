local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local function runScript()
    if not Drawing then notify("Drawing API not supported", "Error", 3) return end

    -- ============================================================
    --  SHARED
    -- ============================================================
    local Mouse = Players.LocalPlayer:GetMouse()
    local prevPressed = false
    local uiX, uiY = 30, 30
    local isDragging, dragOffX, dragOffY = false, 0, 0
    local pauseRoll = false
    local lastActionTime = tick()
    local uiElements = {}
    local uiVisible = true
    local lastF1 = 0
    local lastEggTime = 0
    local EGG_COOLDOWN = 3

    local function hasPos(obj)
        local ok, x = pcall(function() return obj.Position.X end)
        return ok and type(x) == "number"
    end

    local function findPartIn(obj, depth)
        depth = depth or 0
        if depth > 8 then return nil end
        if hasPos(obj) then return obj end
        for _, c in ipairs(obj:GetChildren()) do
            local r = findPartIn(c, depth + 1)
            if r then return r end
        end
        return nil
    end

    local function isPartOrModel(obj)
        local cn = obj and obj.ClassName
        if not cn then return false end
        if cn == "Part" or cn == "MeshPart" or cn == "UnionOperation" then return true end
        if cn == "Model" then return true end
        return false
    end

    local function findPos(obj)
        local ok, x = pcall(function() return obj.WorldPosition.X end)
        if ok and type(x) == "number" then return obj.WorldPosition end
        local p, cf = obj.Position, obj.CFrame
        ok, x = pcall(function() return p.X end)
        if ok and type(x) == "number" then return p end
        ok, x = pcall(function() return cf.X end)
        if ok and type(x) == "number" then return Vector3.new(cf.X, cf.Y, cf.Z) end
        local wcf = obj.WorldCFrame
        ok, x = pcall(function() return wcf.X end)
        if ok and type(x) == "number" then return Vector3.new(wcf.X, wcf.Y, wcf.Z) end
        return nil
    end

    local W = 290
    local TITLE_H  = 28
    local SEC_H    = 52
    local DIV_H    = 8
    local BOT_PAD  = 18
    local TOTAL_H  = TITLE_H + SEC_H * 4 + DIV_H * 3 + BOT_PAD

    local function makeSquare(x, y, w, h, r, g, b, filled, thickness)
        local s = Drawing.new("Square")
        s.Position = Vector2.new(x, y); s.Size = Vector2.new(w, h)
        s.Color = Color3.fromRGB(r, g, b); s.Filled = filled
        s.Thickness = thickness or 1; s.Visible = true
        table.insert(uiElements, s)
        return s
    end
    local function makeText(x, y, txt, r, g, b, sz)
        local t = Drawing.new("Text")
        t.Position = Vector2.new(x, y); t.Text = txt
        t.Color = Color3.fromRGB(r, g, b); t.Size = sz
        t.Font = Drawing.Fonts.UI; t.Visible = true
        table.insert(uiElements, t)
        return t
    end
    local function makeLine(x1, y1, x2, y2, r, g, b)
        local l = Drawing.new("Line")
        l.From = Vector2.new(x1, y1); l.To = Vector2.new(x2, y2)
        l.Color = Color3.fromRGB(r, g, b); l.Thickness = 1; l.Visible = true
        table.insert(uiElements, l)
        return l
    end

    -- ---- Build UI ----
    local COL = {
        warp = {70, 160, 255},
        roll = {170, 110, 255},
        egg  = {255, 190, 70},
        crate= {70, 210, 110}
    }

    local PAD = 14

    local bgB  = makeSquare(uiX-1,  uiY-1,   W+2, TOTAL_H+2, 55, 58, 75, false)
    local bgM  = makeSquare(uiX,    uiY,     W,   TOTAL_H,   14, 14, 20, true)
    local tiBg = makeSquare(uiX, uiY, W, TITLE_H, 24, 24, 34, true)
    local tiAc = makeSquare(uiX, uiY, 4, TITLE_H, 70, 160, 255, true)
    local tiTx = makeText(uiX+PAD, uiY+7, "PUNPUNKUY  |  Build-A-Ring", 210, 215, 240, 13)
    local tAfkInd = makeText(uiX+W-44, uiY+7, "AFK", 120, 120, 130, 9)

    local function calcSecYs()
        local Y1 = uiY + TITLE_H + 4
        local Y2 = Y1 + SEC_H + DIV_H
        local Y3 = Y2 + SEC_H + DIV_H
        local Y4 = Y3 + SEC_H + DIV_H
        return Y1, Y2, Y3, Y4
    end
    local S1_Y, S2_Y, S3_Y, S4_Y = calcSecYs()
    local D1_Y = S1_Y + SEC_H
    local D2_Y = S2_Y + SEC_H
    local D3_Y = S3_Y + SEC_H
    local dv1 = makeLine(uiX+PAD, D1_Y, uiX+W-PAD, D1_Y, 45, 45, 60)
    local dv2 = makeLine(uiX+PAD, D2_Y, uiX+W-PAD, D2_Y, 45, 45, 60)
    local dv3 = makeLine(uiX+PAD, D3_Y, uiX+W-PAD, D3_Y, 45, 45, 60)

    -- Consistent row offsets within each section
    local AC_Y = 2; local AC_H = 14
    local LB_Y = 4
    local SR_Y = 20; local SR_H = 14
    local ST_Y = 21
    local BR_Y = 36; local BR_H = 14
    local BT_Y = 37

    -- ---- Section 1: Auto Warp ----
    local s1Ac  = makeSquare(uiX+PAD-4, S1_Y+AC_Y, 3, AC_H, COL.warp[1], COL.warp[2], COL.warp[3], true)
    local wS1Label  = makeText(uiX+PAD+2, S1_Y+LB_Y,  "AUTO WARP", COL.warp[1], COL.warp[2], COL.warp[3], 11)
    local s1StB = makeSquare(uiX+PAD+2, S1_Y+SR_Y, W-PAD*2-4, SR_H, 22, 22, 30, true)
    local tS1Status = makeText(uiX+PAD+5, S1_Y+ST_Y, "Standby", 160, 170, 190, 10)
    local wS1BtnBg  = makeSquare(uiX+PAD+2, S1_Y+BR_Y, W-PAD*2-4, BR_H, 55, 22, 22, true)
    local wS1BtnBrd = makeSquare(uiX+PAD+1, S1_Y+BR_Y-1, W-PAD*2-2, BR_H+2, 75, 78, 90, false)
    local tS1Btn    = makeText(uiX+PAD+5, S1_Y+BT_Y, "[ START ]", 230, 235, 245, 10)

    -- ---- Section 2: Auto Roll ----
    local s2Ac  = makeSquare(uiX+PAD-4, S2_Y+AC_Y, 3, AC_H, COL.roll[1], COL.roll[2], COL.roll[3], true)
    local wS2Label  = makeText(uiX+PAD+2, S2_Y+LB_Y,  "AUTO ROLL SEED", COL.roll[1], COL.roll[2], COL.roll[3], 11)
    local s2StB = makeSquare(uiX+PAD+2, S2_Y+SR_Y, W-PAD*2-4, SR_H, 22, 22, 30, true)
    local tS2Status = makeText(uiX+PAD+5, S2_Y+ST_Y, "Idle", 160, 170, 190, 10)
    local wS2BtnBg  = makeSquare(uiX+PAD+2, S2_Y+BR_Y, W-PAD*2-4, BR_H, 55, 22, 22, true)
    local wS2BtnBrd = makeSquare(uiX+PAD+1, S2_Y+BR_Y-1, W-PAD*2-2, BR_H+2, 75, 78, 90, false)
    local tS2Btn    = makeText(uiX+PAD+5, S2_Y+BT_Y, "[ START ]", 230, 235, 245, 10)

    -- ---- Section 3: Auto Egg ----
    local s3Ac   = makeSquare(uiX+PAD-4, S3_Y+AC_Y, 3, AC_H, COL.egg[1], COL.egg[2], COL.egg[3], true)
    local wS3Label   = makeText(uiX+PAD+2, S3_Y+LB_Y,  "AUTO EGG", COL.egg[1], COL.egg[2], COL.egg[3], 11)
    local EGG_TG_Y   = S3_Y + SR_Y
    local EGG_TG_H   = SR_H
    local eggTgComBg = makeSquare(uiX+PAD+2, EGG_TG_Y, 72, EGG_TG_H, 40, 160, 40, true)
    local eggTgComTx = makeText(uiX+PAD+10, EGG_TG_Y+2, "Common", 255, 255, 255, 10)
    local eggTgRarBg = makeSquare(uiX+PAD+82, EGG_TG_Y, 56, EGG_TG_H, 40, 160, 40, true)
    local eggTgRarTx = makeText(uiX+PAD+90, EGG_TG_Y+2, "Rare", 255, 255, 255, 10)
    local eggTgEpiBg = makeSquare(uiX+PAD+146, EGG_TG_Y, 50, EGG_TG_H, 40, 160, 40, true)
    local eggTgEpiTx = makeText(uiX+PAD+154, EGG_TG_Y+2, "Epic", 255, 255, 255, 10)
    local wS3BtnBg  = makeSquare(uiX+PAD+2, S3_Y+BR_Y, W-PAD*2-4, BR_H, 22, 70, 32, true)
    local wS3BtnBrd = makeSquare(uiX+PAD+1, S3_Y+BR_Y-1, W-PAD*2-2, BR_H+2, 45, 130, 60, false)
    local tS3Btn    = makeText(uiX+PAD+5, S3_Y+BT_Y, "[ STOP ]", 230, 235, 245, 10)

    -- ---- Section 4: Auto Crate ----
    local s4Ac  = makeSquare(uiX+PAD-4, S4_Y+AC_Y, 3, AC_H, COL.crate[1], COL.crate[2], COL.crate[3], true)
    local wS4Label  = makeText(uiX+PAD+2, S4_Y+LB_Y,  "AUTO CRATE", COL.crate[1], COL.crate[2], COL.crate[3], 11)
    local s4StB = makeSquare(uiX+PAD+2, S4_Y+SR_Y, W-PAD*2-4, SR_H, 22, 22, 30, true)
    local tS4Status = makeText(uiX+PAD+5, S4_Y+ST_Y, "Idle", 160, 170, 190, 10)
    local wS4BtnBg  = makeSquare(uiX+PAD+2, S4_Y+BR_Y, W-PAD*2-4, BR_H, 55, 22, 22, true)
    local wS4BtnBrd = makeSquare(uiX+PAD+1, S4_Y+BR_Y-1, W-PAD*2-2, BR_H+2, 75, 78, 90, false)
    local tS4Btn    = makeText(uiX+PAD+5, S4_Y+BT_Y, "[ START ]", 230, 235, 245, 10)

    -- Anti-AFK status
    local afkSt = makeText(uiX+PAD, uiY+TOTAL_H-14, "Anti-AFK: Guarding", 100, 105, 115, 9)

    local function updateAllPos(dx, dy)
        uiX, uiY = dx, dy
        S1_Y, S2_Y, S3_Y, S4_Y = calcSecYs()
        D1_Y = S1_Y + SEC_H; D2_Y = S2_Y + SEC_H; D3_Y = S3_Y + SEC_H
        bgB.Position  = Vector2.new(uiX-1,  uiY-1)
        bgM.Position  = Vector2.new(uiX,    uiY)
        tiBg.Position = Vector2.new(uiX,    uiY)
        tiAc.Position = Vector2.new(uiX,    uiY)
        tiTx.Position = Vector2.new(uiX+PAD, uiY+7)
        tAfkInd.Position = Vector2.new(uiX+W-44, uiY+7)
        EGG_TG_Y = S3_Y + SR_Y
        dv1.From = Vector2.new(uiX+PAD, D1_Y); dv1.To = Vector2.new(uiX+W-PAD, D1_Y)
        dv2.From = Vector2.new(uiX+PAD, D2_Y); dv2.To = Vector2.new(uiX+W-PAD, D2_Y)
        dv3.From = Vector2.new(uiX+PAD, D3_Y); dv3.To = Vector2.new(uiX+W-PAD, D3_Y)
        s1Ac.Position    = Vector2.new(uiX+PAD-4, S1_Y+AC_Y)
        wS1Label.Position  = Vector2.new(uiX+PAD+2, S1_Y+LB_Y)
        s1StB.Position     = Vector2.new(uiX+PAD+2, S1_Y+SR_Y)
        tS1Status.Position = Vector2.new(uiX+PAD+5, S1_Y+ST_Y)
        wS1BtnBg.Position  = Vector2.new(uiX+PAD+2, S1_Y+BR_Y)
        wS1BtnBrd.Position = Vector2.new(uiX+PAD+1, S1_Y+BR_Y-1)
        tS1Btn.Position    = Vector2.new(uiX+PAD+5, S1_Y+BT_Y)
        s2Ac.Position    = Vector2.new(uiX+PAD-4, S2_Y+AC_Y)
        wS2Label.Position  = Vector2.new(uiX+PAD+2, S2_Y+LB_Y)
        s2StB.Position     = Vector2.new(uiX+PAD+2, S2_Y+SR_Y)
        tS2Status.Position = Vector2.new(uiX+PAD+5, S2_Y+ST_Y)
        wS2BtnBg.Position  = Vector2.new(uiX+PAD+2, S2_Y+BR_Y)
        wS2BtnBrd.Position = Vector2.new(uiX+PAD+1, S2_Y+BR_Y-1)
        tS2Btn.Position    = Vector2.new(uiX+PAD+5, S2_Y+BT_Y)
        s3Ac.Position       = Vector2.new(uiX+PAD-4, S3_Y+AC_Y)
        wS3Label.Position   = Vector2.new(uiX+PAD+2, S3_Y+LB_Y)
        eggTgComBg.Position = Vector2.new(uiX+PAD+2, EGG_TG_Y)
        eggTgComTx.Position = Vector2.new(uiX+PAD+10, EGG_TG_Y+2)
        eggTgRarBg.Position = Vector2.new(uiX+PAD+82, EGG_TG_Y)
        eggTgRarTx.Position = Vector2.new(uiX+PAD+90, EGG_TG_Y+2)
        eggTgEpiBg.Position = Vector2.new(uiX+PAD+146, EGG_TG_Y)
        eggTgEpiTx.Position = Vector2.new(uiX+PAD+154, EGG_TG_Y+2)
        wS3BtnBg.Position  = Vector2.new(uiX+PAD+2, S3_Y+BR_Y)
        wS3BtnBrd.Position = Vector2.new(uiX+PAD+1, S3_Y+BR_Y-1)
        tS3Btn.Position    = Vector2.new(uiX+PAD+5, S3_Y+BT_Y)
        s4Ac.Position    = Vector2.new(uiX+PAD-4, S4_Y+AC_Y)
        wS4Label.Position  = Vector2.new(uiX+PAD+2, S4_Y+LB_Y)
        s4StB.Position     = Vector2.new(uiX+PAD+2, S4_Y+SR_Y)
        tS4Status.Position = Vector2.new(uiX+PAD+5, S4_Y+ST_Y)
        wS4BtnBg.Position  = Vector2.new(uiX+PAD+2, S4_Y+BR_Y)
        wS4BtnBrd.Position = Vector2.new(uiX+PAD+1, S4_Y+BR_Y-1)
        tS4Btn.Position    = Vector2.new(uiX+PAD+5, S4_Y+BT_Y)
        afkSt.Position     = Vector2.new(uiX+PAD, uiY+TOTAL_H-14)
    end

    -- ============================================================
    --  LOGIC 1 — Auto Warp
    -- ============================================================
    local warpEnabled     = false
    local plantKeyPressed = false
    local currentTarget   = nil
    local function warpAndPress(hrp, pos, name)
        if not hrp or not pos then return end
        tS1Status.Text  = "Warping to " .. name
        tS1Status.Color = Color3.fromRGB(255, 200, 0)
        hrp.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z + 2)
        wait(0.1)
        setrobloxinput(true); keypress(69); wait(1); keyrelease(69)
        lastActionTime = tick()
        wait(0.5)
        tS1Status.Text  = "Pressed E at " .. name
        tS1Status.Color = Color3.fromRGB(0, 255, 100)
    end
    local function checkEvents(hrp, folder)
        if not folder then return false end
        local qb = folder:FindFirstChild("QueenBee")
        local rh = qb and qb:FindFirstChild("RuntimeHoneycombs")
        local hc = rh and rh:FindFirstChild("Honeycomb")
        if hc then
            local part = findPartIn(hc)
            if part then warpAndPress(hrp, part.Position, "QueenBee") return true end
        end
        local ai = folder:FindFirstChild("AlienInvasion")
        if ai then
            for _, child in pairs(ai:GetChildren()) do
                if string.sub(child.Name, 1, 9) == "AlienDrop" then
                    local part = findPartIn(child)
                    if part then warpAndPress(hrp, part.Position, child.Name) return true end
                end
            end
        end
        return false
    end
    local function findBestMob(runtime)
        if not runtime then return nil, nil end
        for _, name in ipairs({"Boss Plant","Medium Plant","Tough Plant","Small Plant"}) do
            local mob = runtime:FindFirstChild(name)
            if mob then
                local part = mob:FindFirstChild("HumanoidRootPart")
                if part then return name, part end
            end
        end
        return nil, nil
    end
    local function togglePlantRush(hrp, folder)
        if not folder then return false end
        local runtime = folder:FindFirstChild("Runtime")
        if not runtime then return false end
        local mobName, mobPart = findBestMob(runtime)
        if mobName and mobPart then
            if not plantKeyPressed then
                tS1Status.Text  = "Warp + Key1 -> " .. mobName
                tS1Status.Color = Color3.fromRGB(255, 200, 0)
                hrp.CFrame = CFrame.new(mobPart.Position.X, mobPart.Position.Y + 3, mobPart.Position.Z + 2)
                wait(0.1)
                setrobloxinput(true); keypress(49); wait(0.2); keyrelease(49)
                lastActionTime = tick()
                plantKeyPressed = true; currentTarget = mobName
                tS1Status.Text  = "Engaged: " .. mobName
                tS1Status.Color = Color3.fromRGB(0, 255, 100)
                wait(0.5)
                return true
            elseif currentTarget ~= mobName then
                hrp.CFrame = CFrame.new(mobPart.Position.X, mobPart.Position.Y + 3, mobPart.Position.Z + 2)
                lastActionTime = tick()
                currentTarget  = mobName
                tS1Status.Text  = "Switched -> " .. mobName
                tS1Status.Color = Color3.fromRGB(100, 200, 255)
                wait(0.5)
                return true
            else
                tS1Status.Text  = "Attacking: " .. mobName
                tS1Status.Color = Color3.fromRGB(100, 200, 255)
                return true
            end
        else
            if plantKeyPressed then
                setrobloxinput(true); keypress(49); wait(0.2); keyrelease(49)
                lastActionTime = tick()
                plantKeyPressed = false; currentTarget = nil
                warpEnabled = false
                wS1BtnBg.Color  = Color3.fromRGB(55, 22, 22)
                wS1BtnBrd.Color = Color3.fromRGB(75, 78, 90)
                tS1Btn.Text     = "[ START ]"
                wS1Label.Color  = Color3.fromRGB(COL.warp[1], COL.warp[2], COL.warp[3])
                tS1Status.Text  = "No mobs — stopped"
                tS1Status.Color = Color3.fromRGB(255, 200, 0)
                return true
            end
            return false
        end
    end

    -- ============================================================
    --  LOGIC 2 — Auto Roll Seed
    -- ============================================================
    local rollEnabled = false
    local rollRunning = false
    local TARGET_SEEDS = {
        "Void Fruit", "Papaya", "Ghost Pepper", "Durian", "Ember Fruit"
    }
    local function getMyPlot()
        local hrp2 = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp2 then return nil end
        local plots = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Plots")
        if not plots then return nil end
        local closest, closestDist = nil, math.huge
        for _, plot in ipairs(plots:GetChildren()) do
            local part = findPartIn(plot)
            if part then
                local dist = (hrp2.Position - part.Position).Magnitude
                if dist < closestDist then closestDist = dist; closest = plot end
            end
        end
        return closest
    end
    local function getPosition(obj)
        local pos = findPos(obj)
        if pos then return pos end
        if obj.PrimaryPart then
            local pp = obj.PrimaryPart
            pos = findPos(pp)
            if pos then return pos end
        end
        local function walk(o, depth)
            if depth > 5 then return nil end
            for _, c in ipairs(o:GetChildren()) do
                local p = findPos(c)
                if p then return p end
                local r = walk(c, depth + 1)
                if r then return r end
            end
            return nil
        end
        return walk(obj, 0)
    end
    local function stopRollUI()
        rollEnabled = false
        wS2BtnBg.Color  = Color3.fromRGB(55, 22, 22)
        wS2BtnBrd.Color = Color3.fromRGB(75, 78, 90)
        tS2Btn.Text     = "[ START ]"
        wS2Label.Color  = Color3.fromRGB(COL.roll[1], COL.roll[2], COL.roll[3])
    end
    local function runRollLoop()
        rollRunning = true
        tS2Status.Text  = "Finding plot..."
        tS2Status.Color = Color3.fromRGB(255, 200, 0)
        local plot = getMyPlot()
        if not plot then
            tS2Status.Text  = "Plot not found!"
            tS2Status.Color = Color3.fromRGB(255, 100, 100)
            stopRollUI(); rollRunning = false; return
        end
        tS2Status.Text  = "Plot: " .. plot.Name
        tS2Status.Color = Color3.fromRGB(100, 200, 255)
        local ok, lever = pcall(function()
            return plot.RollPlatform.Lever.LeverModel.Icosphere
        end)
        if not ok or not lever then
            tS2Status.Text  = "Lever not found!"
            tS2Status.Color = Color3.fromRGB(255, 100, 100)
            stopRollUI(); rollRunning = false; return
        end
        while rollEnabled do
            while pauseRoll and rollEnabled do
                tS2Status.Text  = "Paused (event active)..."
                tS2Status.Color = Color3.fromRGB(255, 200, 0)
                wait(0.5)
            end
            if not rollEnabled then break end
            local hrp2 = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp2 then wait(1) end
            if not hrp2 then break end
            tS2Status.Text  = "Rolling..."
            tS2Status.Color = Color3.fromRGB(255, 200, 0)
            hrp2.CFrame = CFrame.new(lever.Position.X, lever.Position.Y + 3, lever.Position.Z + 2)
            wait(0.3)
            if rollEnabled then
                local pok = pcall(function()
                    setrobloxinput(true); keypress(69); wait(2); keyrelease(69)
                end)
                if not pok then
                    tS2Status.Text  = "Error pressing lever"
                    tS2Status.Color = Color3.fromRGB(255, 100, 100)
                    break
                end
            end
            wait(1.5)
            local allFound = true
            local pok, _ = pcall(function()
                for _, seedName in ipairs(TARGET_SEEDS) do
                    local obj = Workspace:FindFirstChild(seedName)
                    if obj then
                        local pos = getPosition(obj)
                        if pos then
                            tS2Status.Text  = "Buying: " .. seedName
                            tS2Status.Color = Color3.fromRGB(255, 200, 0)
                            hrp2 = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if hrp2 then
                                hrp2.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z + 2)
                                wait(0.2)
                                setrobloxinput(true); keypress(69); wait(1); keyrelease(69)
                                wait(0.1)
                            end
                            hrp2 = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if hrp2 then
                                hrp2.CFrame = CFrame.new(lever.Position.X, lever.Position.Y + 3, lever.Position.Z + 2)
                                wait(0.1)
                            end
                        end
                    else
                        allFound = false
                    end
                end
            end)
            if not pok then
                tS2Status.Text  = "Buy error, retrying..."
                tS2Status.Color = Color3.fromRGB(255, 100, 100)
            end
            if allFound then
                tS2Status.Text  = "All seeds bought!"
                tS2Status.Color = Color3.fromRGB(0, 255, 100)
                stopRollUI(); break
            else
                tS2Status.Text  = "Re-rolling..."
                tS2Status.Color = Color3.fromRGB(180, 180, 255)
            end
            wait()
        end
        rollRunning = false
    end

    -- ============================================================
    --  LOGIC 3 — Auto Egg
    -- ============================================================
    local eggEnabled = true
    local eggToggles = { CommonEgg = true, RareEgg = true, EpicEgg = true }
    local EGG_FOLDERS = {"CommonEgg", "EpicEgg", "RareEgg"}
    local function findEggs()
        local results = {}
        for _, folderName in ipairs(EGG_FOLDERS) do
            if eggToggles[folderName] then
                local folder = Workspace:FindFirstChild(folderName)
                if folder then
                    for _, child in ipairs(folder:GetChildren()) do
                        if isPartOrModel(child) then
                            table.insert(results, child)
                        end
                    end
                end
            end
        end
        return results
    end
    local function getEggPosition(egg)
        local pos = findPos(egg)
        if pos then return pos end
        local primary = egg:FindFirstChild("PrimaryPart")
        if primary then
            pos = findPos(primary)
            if pos then return pos end
        end
        local part = findPartIn(egg)
        if part then return part.Position end
        local ok, cf = pcall(function() return egg:GetModelCFrame() end)
        if ok then return cf.Position end
        return nil
    end
    local function warpToEgg(pos)
        local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(pos.X, pos.Y, pos.Z + 2) end
    end
    local function updateEggToggleColors()
        eggTgComBg.Color = eggToggles.CommonEgg and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(55, 28, 28)
        eggTgRarBg.Color = eggToggles.RareEgg and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(55, 28, 28)
        eggTgEpiBg.Color = eggToggles.EpicEgg and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(55, 28, 28)
    end
    updateEggToggleColors()

    -- ============================================================
    --  LOGIC 4 — Auto Crate
    -- ============================================================
    local crateEnabled = false
    local lastCrateSellTime = 0
    local CRATE_COOLDOWN = 600
    local function getCratePositions(plot)
        local list = {}
        local crates = plot:FindFirstChild("Crates")
        if crates then
            for _, c in ipairs(crates:GetChildren()) do
                local center = c:FindFirstChild("Center")
                if center then
                    local pos = findPos(center)
                    if pos then table.insert(list, pos) end
                end
            end
        end
        return list
    end
    local function getSellPosition(plot)
        local sell = plot:FindFirstChild("Sell")
        if sell then
            local desk = sell:FindFirstChild("Desk")
            if desk then
                for _, child in ipairs(desk:GetChildren()) do
                    local pos = findPos(child)
                    if pos then return pos end
                end
            end
        end
        return nil
    end
    local function getHRP()
        local char = Players.LocalPlayer and Players.LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end
    local function crateCollectAndSell(plot)
        local cratePoss = getCratePositions(plot)
        local count = 0
        for i = 1, math.min(2, #cratePoss) do
            local pos = cratePoss[i]
            if pos then
                local hrp = getHRP()
                if not hrp then break end
                tS4Status.Text = "Collecting crate " .. i
                tS4Status.Color = Color3.fromRGB(255, 200, 0)
                hrp.CFrame = CFrame.new(pos.X, pos.Y + 2, pos.Z)
                wait(0.5)
                setrobloxinput(true); keypress(69); wait(2); keyrelease(69)
                count = count + 1
                wait(0.3)
            end
        end
        if count > 0 then
            local sellPos = getSellPosition(plot)
            if sellPos then
                local hrp = getHRP()
                if hrp then
                    tS4Status.Text = "Selling crates..."
                    tS4Status.Color = Color3.fromRGB(255, 200, 0)
                    hrp.CFrame = CFrame.new(sellPos.X, sellPos.Y + 2, sellPos.Z)
                    wait(0.5)
                    setrobloxinput(true); keypress(69); wait(2); keyrelease(69)
                    tS4Status.Text = "Sold! Cooldown 10min"
                    tS4Status.Color = Color3.fromRGB(0, 255, 100)
                    lastCrateSellTime = tick()
                else
                    tS4Status.Text = "Died during collect"
                    tS4Status.Color = Color3.fromRGB(255, 100, 100)
                end
            else
                tS4Status.Text = "Sell desk not found"
                tS4Status.Color = Color3.fromRGB(255, 100, 100)
            end
        else
            tS4Status.Text = "No crates to collect"
            tS4Status.Color = Color3.fromRGB(255, 100, 100)
        end
    end

    -- ============================================================
    --  MAIN LOOP
    -- ============================================================
    print("[Script] UI Redesigned – PunpunKuy Toolkit")
    while true do
        local didAction = false
        local mx, my    = Mouse.X, Mouse.Y
        local isPressed  = ismouse1pressed()
        local justPressed  = isPressed and not prevPressed
        local justReleased = not isPressed and prevPressed

        -- F1 toggle UI
        local f1down = pcall(function() return game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.F1) end)
        if f1down and tick() - lastF1 > 0.3 then
            lastF1 = tick()
            uiVisible = not uiVisible
            for _, e in ipairs(uiElements) do e.Visible = uiVisible end
        end

        if justPressed then
            if mx >= uiX and mx <= uiX+W and my >= uiY and my <= uiY+TITLE_H then
                isDragging = true
                dragOffX = mx - uiX; dragOffY = my - uiY
            end
            -- S1 button
            local b1x, b1y = wS1BtnBg.Position.X, wS1BtnBg.Position.Y
            local b1w, b1h = wS1BtnBg.Size.X, wS1BtnBg.Size.Y
            if mx >= b1x and mx <= b1x+b1w and my >= b1y and my <= b1y+b1h and not isDragging then
                warpEnabled = not warpEnabled
                if warpEnabled then
                    wS1BtnBg.Color  = Color3.fromRGB(22, 70, 32)
                    wS1BtnBrd.Color = Color3.fromRGB(45, 130, 60)
                    tS1Btn.Text     = "[ STOP ]"
                    tS1Status.Text  = "Active"
                    tS1Status.Color = Color3.fromRGB(0, 255, 100)
                    wS1Label.Color  = Color3.fromRGB(0, 200, 100)
                else
                    wS1BtnBg.Color  = Color3.fromRGB(55, 22, 22)
                    wS1BtnBrd.Color = Color3.fromRGB(75, 78, 90)
                    tS1Btn.Text     = "[ START ]"
                    tS1Status.Text  = "Paused"
                    tS1Status.Color = Color3.fromRGB(255, 100, 100)
                    wS1Label.Color  = Color3.fromRGB(COL.warp[1], COL.warp[2], COL.warp[3])
                end
            end
            -- S2 button
            local b2x, b2y = wS2BtnBg.Position.X, wS2BtnBg.Position.Y
            local b2w, b2h = wS2BtnBg.Size.X, wS2BtnBg.Size.Y
            if mx >= b2x and mx <= b2x+b2w and my >= b2y and my <= b2y+b2h and not isDragging then
                rollEnabled = not rollEnabled
                if rollEnabled then
                    wS2BtnBg.Color  = Color3.fromRGB(22, 70, 32)
                    wS2BtnBrd.Color = Color3.fromRGB(45, 130, 60)
                    tS2Btn.Text     = "[ STOP ]"
                    tS2Status.Text  = "Starting..."
                    tS2Status.Color = Color3.fromRGB(0, 255, 100)
                    wS2Label.Color  = Color3.fromRGB(0, 200, 100)
                    if not rollRunning then task.spawn(runRollLoop) end
                else
                    wS2BtnBg.Color  = Color3.fromRGB(55, 22, 22)
                    wS2BtnBrd.Color = Color3.fromRGB(75, 78, 90)
                    tS2Btn.Text     = "[ START ]"
                    tS2Status.Text  = "Stopping..."
                    tS2Status.Color = Color3.fromRGB(255, 100, 100)
                    wS2Label.Color  = Color3.fromRGB(COL.roll[1], COL.roll[2], COL.roll[3])
                end
            end
            -- S3 button
            local b3x, b3y = wS3BtnBg.Position.X, wS3BtnBg.Position.Y
            local b3w, b3h = wS3BtnBg.Size.X, wS3BtnBg.Size.Y
            if mx >= b3x and mx <= b3x+b3w and my >= b3y and my <= b3y+b3h and not isDragging then
                eggEnabled = not eggEnabled
                if eggEnabled then
                    wS3BtnBg.Color  = Color3.fromRGB(22, 70, 32)
                    wS3BtnBrd.Color = Color3.fromRGB(45, 130, 60)
                    tS3Btn.Text     = "[ STOP ]"
                    wS3Label.Color  = Color3.fromRGB(0, 200, 100)
                else
                    wS3BtnBg.Color  = Color3.fromRGB(55, 22, 22)
                    wS3BtnBrd.Color = Color3.fromRGB(75, 78, 90)
                    tS3Btn.Text     = "[ START ]"
                    wS3Label.Color  = Color3.fromRGB(COL.egg[1], COL.egg[2], COL.egg[3])
                end
            end
            -- S3 egg type pills
            if my >= EGG_TG_Y and my <= EGG_TG_Y + EGG_TG_H and not isDragging then
                if mx >= uiX+PAD+2 and mx <= uiX+PAD+74 then
                    eggToggles.CommonEgg = not eggToggles.CommonEgg
                    updateEggToggleColors()
                elseif mx >= uiX+PAD+82 and mx <= uiX+PAD+138 then
                    eggToggles.RareEgg = not eggToggles.RareEgg
                    updateEggToggleColors()
                elseif mx >= uiX+PAD+146 and mx <= uiX+PAD+196 then
                    eggToggles.EpicEgg = not eggToggles.EpicEgg
                    updateEggToggleColors()
                end
            end
            -- S4 button
            local b4x, b4y = wS4BtnBg.Position.X, wS4BtnBg.Position.Y
            local b4w, b4h = wS4BtnBg.Size.X, wS4BtnBg.Size.Y
            if mx >= b4x and mx <= b4x+b4w and my >= b4y and my <= b4y+b4h and not isDragging then
                crateEnabled = not crateEnabled
                if crateEnabled then
                    wS4BtnBg.Color  = Color3.fromRGB(22, 70, 32)
                    wS4BtnBrd.Color = Color3.fromRGB(45, 130, 60)
                    tS4Btn.Text     = "[ STOP ]"
                    tS4Status.Text  = "Active"
                    tS4Status.Color = Color3.fromRGB(0, 255, 100)
                    wS4Label.Color  = Color3.fromRGB(0, 200, 100)
                else
                    wS4BtnBg.Color  = Color3.fromRGB(55, 22, 22)
                    wS4BtnBrd.Color = Color3.fromRGB(75, 78, 90)
                    tS4Btn.Text     = "[ START ]"
                    tS4Status.Text  = "Stopped"
                    tS4Status.Color = Color3.fromRGB(255, 100, 100)
                    wS4Label.Color  = Color3.fromRGB(COL.crate[1], COL.crate[2], COL.crate[3])
                end
            end
        end
        if justReleased then isDragging = false end
        if isDragging and isPressed then updateAllPos(mx - dragOffX, my - dragOffY) end
        prevPressed = isPressed

        -- Anti-AFK
        local now = tick()
        local idleSec = now - lastActionTime
        if idleSec >= 50 then
            tAfkInd.Text = "AFK!"
            tAfkInd.Color = Color3.fromRGB(255, 200, 0)
            afkSt.Text = "Anti-AFK: About to nudge..."
            afkSt.Color = Color3.fromRGB(255, 200, 0)
        else
            tAfkInd.Text = "AFK"
            tAfkInd.Color = Color3.fromRGB(120, 120, 130)
            afkSt.Text = "Anti-AFK: Guarding"
            afkSt.Color = Color3.fromRGB(100, 105, 115)
        end
        if idleSec >= 55 then
            local char = Players.LocalPlayer and Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.new(0, 0.15, 0)
                wait(0.05)
                hrp.CFrame = hrp.CFrame * CFrame.new(0, -0.15, 0)
                afkSt.Text = "Anti-AFK: Nudged! " .. os.date("%H:%M:%S")
                afkSt.Color = Color3.fromRGB(60, 220, 110)
            end
            lastActionTime = now
        end

        -- Auto Warp logic
        pauseRoll = false
        if not didAction and warpEnabled then
            local char = Players.LocalPlayer and Players.LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                tS1Status.Text  = "Scanning..."
                tS1Status.Color = Color3.fromRGB(180, 180, 255)
                local ie    = Workspace:FindFirstChild("InteractiveEvents")
                local found = false
                if ie then
                    found = checkEvents(hrp, ie)
                    if not found then
                        local pr = ie:FindFirstChild("PlantRush")
                        if pr then found = togglePlantRush(hrp, pr) end
                    end
                end
                if found then
                    pauseRoll = true; didAction = true
                else
                    tS1Status.Text  = "Waiting for event..."
                    tS1Status.Color = Color3.fromRGB(160, 160, 180)
                end
            else
                tS1Status.Text  = "No Character"
                tS1Status.Color = Color3.fromRGB(255, 100, 100)
            end
        end

        -- Auto Egg logic
        if not didAction and eggEnabled then
            local now = tick()
            local eggHasActive = eggToggles.CommonEgg or eggToggles.RareEgg or eggToggles.EpicEgg
            if not eggHasActive then
                tS3Btn.Text  = "No type selected"
                tS3Btn.Color = Color3.fromRGB(255, 180, 80)
            elseif now - lastEggTime >= EGG_COOLDOWN then
                local char = Players.LocalPlayer and Players.LocalPlayer.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local eggs = findEggs()
                    if #eggs > 0 then
                        local chosen = eggs[math.random(1, #eggs)]
                        local pos = getEggPosition(chosen)
                        if pos then
                            pauseRoll = true
                            tS3Btn.Text  = "Warping to " .. chosen.Name
                            tS3Btn.Color = Color3.fromRGB(255, 200, 0)
                            warpToEgg(pos)
                            setrobloxinput(true); keypress(69); wait(1); keyrelease(69)
                            lastEggTime = now
                            didAction = true
                            tS3Btn.Text  = "Opened " .. chosen.Name
                            tS3Btn.Color = Color3.fromRGB(0, 255, 100)
                        end
                    else
                        local activeList = {}
                        if eggToggles.CommonEgg then table.insert(activeList, "Common") end
                        if eggToggles.RareEgg then table.insert(activeList, "Rare") end
                        if eggToggles.EpicEgg then table.insert(activeList, "Epic") end
                        tS3Btn.Text  = "No " .. table.concat(activeList, "/") .. " eggs"
                        tS3Btn.Color = Color3.fromRGB(255, 180, 80)
                    end
                end
            end
        end

        -- Auto Crate logic
        if not didAction and crateEnabled then
            local char = Players.LocalPlayer and Players.LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local now = tick()
                if now - lastCrateSellTime >= CRATE_COOLDOWN then
                    local plot = getMyPlot()
                    if plot then
                        pauseRoll = true
                        tS4Status.Text = "Plot: " .. plot.Name
                        tS4Status.Color = Color3.fromRGB(100, 200, 255)
                        crateCollectAndSell(plot)
                        didAction = true
                    else
                        tS4Status.Text = "No plot found"
                        tS4Status.Color = Color3.fromRGB(255, 100, 100)
                    end
                else
                    local remain = math.ceil(CRATE_COOLDOWN - (now - lastCrateSellTime))
                    tS4Status.Text = "Cooldown: " .. remain .. "s"
                    tS4Status.Color = Color3.fromRGB(160, 160, 180)
                end
            else
                tS4Status.Text = "No Character"
                tS4Status.Color = Color3.fromRGB(255, 100, 100)
            end
        end

        wait()
    end
end
runScript()
