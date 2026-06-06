local function runScript()
    if not Drawing then notify("Drawing API not supported", "Error", 3) return end

    local enabled = false
    local uiVisible = true
    local uiX, uiY = 30, 30
    local isDragging, dragOffX, dragOffY = false, 0, 0
    local prevPressed = false
    local prevKeyStates = {}
    local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
    local elements = {}

    local function isKeyJustPressed(keycode)
        local pressed = iskeypressed(keycode)
        local prev = prevKeyStates[keycode]
        prevKeyStates[keycode] = pressed
        return pressed and (prev == nil or not prev)
    end

    local bg = Drawing.new("Square")
    bg.Position = Vector2.new(uiX, uiY); bg.Size = Vector2.new(200, 60)
    bg.Color = Color3.fromRGB(14, 14, 20); bg.Filled = true; bg.Visible = true
    table.insert(elements, bg)

    local border = Drawing.new("Square")
    border.Position = Vector2.new(uiX-1, uiY-1); border.Size = Vector2.new(202, 62)
    border.Color = Color3.fromRGB(55, 58, 75); border.Filled = false; border.Thickness = 1; border.Visible = true
    table.insert(elements, border)

    local label = Drawing.new("Text")
    label.Position = Vector2.new(uiX+10, uiY+6); label.Text = "AUTO E (HOLD 1.5s)"
    label.Color = Color3.fromRGB(210, 215, 240); label.Size = 13; label.Font = Drawing.Fonts.UI; label.Visible = true
    table.insert(elements, label)

    local indicator = Drawing.new("Text")
    indicator.Position = Vector2.new(uiX+10, uiY+26); indicator.Text = "[ OFF ]  Toggle: T"
    indicator.Color = Color3.fromRGB(120, 120, 130); indicator.Size = 10; indicator.Font = Drawing.Fonts.UI; indicator.Visible = true
    table.insert(elements, indicator)

    local function updatePos(dx, dy)
        uiX, uiY = dx, dy
        bg.Position = Vector2.new(uiX, uiY)
        border.Position = Vector2.new(uiX-1, uiY-1)
        label.Position = Vector2.new(uiX+10, uiY+6)
        indicator.Position = Vector2.new(uiX+10, uiY+26)
    end

    print("[Script] Auto E — T to toggle, F1 to hide")
    while true do
        local mx, my = Mouse.X, Mouse.Y
        local pressed = ismouse1pressed()
        local justPressed = pressed and not prevPressed
        local justReleased = not pressed and prevPressed

        if isKeyJustPressed(84) then
            enabled = not enabled
            if enabled then
                indicator.Text = "[ ON  ]  Holding E 1.5s..."
                indicator.Color = Color3.fromRGB(60, 220, 110)
                bg.Color = Color3.fromRGB(20, 30, 20)
            else
                keyrelease(69)
                indicator.Text = "[ OFF ]  Toggle: T"
                indicator.Color = Color3.fromRGB(120, 120, 130)
                bg.Color = Color3.fromRGB(14, 14, 20)
            end
        end

        if isKeyJustPressed(112) then
            uiVisible = not uiVisible
            for _, e in ipairs(elements) do e.Visible = uiVisible end
        end

        if justPressed then
            if mx >= uiX and mx <= uiX+200 and my >= uiY and my <= uiY+30 then
                isDragging = true; dragOffX = mx - uiX; dragOffY = my - uiY
            end
        end
        if justReleased then isDragging = false end
        if isDragging and pressed then updatePos(mx - dragOffX, my - dragOffY) end
        prevPressed = pressed

        if enabled then
            setrobloxinput(true); keypress(69); wait(1.5); keyrelease(69); wait(0.3)
        end

        wait()
    end
end
runScript()
