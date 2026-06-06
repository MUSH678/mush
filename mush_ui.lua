if not math.clamp then
    math.clamp = function(val, min, max)
        return math.min(math.max(val, min), max)
    end
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local LocalMouse = LocalPlayer and LocalPlayer:GetMouse() or nil

local Theme = {
    bg = Color3.fromRGB(22, 23, 28),
    shell = Color3.fromRGB(27, 29, 35),
    sidebar = Color3.fromRGB(31, 33, 39),
    panel = Color3.fromRGB(31, 33, 39),
    panelAlt = Color3.fromRGB(39, 41, 49),
    card = Color3.fromRGB(37, 39, 47),
    border = Color3.fromRGB(47, 50, 58),
    borderSoft = Color3.fromRGB(40, 42, 49),
    topHighlight = Color3.fromRGB(59, 62, 72),
    cardInner = Color3.fromRGB(43, 45, 54),
    accent = Color3.fromRGB(54, 248, 87),
    accentSoft = Color3.fromRGB(40, 180, 70),
    text = Color3.fromRGB(242, 243, 246),
    textDim = Color3.fromRGB(161, 165, 174),
    textMuted = Color3.fromRGB(128, 132, 141),
    success = Color3.fromRGB(255, 255, 255),
}

local AccentThemes = {
    ["Green"] = { accent = Color3.fromRGB(54, 248, 87), accentSoft = Color3.fromRGB(40, 180, 70) },
    ["Blue"] = { accent = Color3.fromRGB(70, 170, 255), accentSoft = Color3.fromRGB(50, 120, 195) },
    ["Red"] = { accent = Color3.fromRGB(255, 92, 92), accentSoft = Color3.fromRGB(190, 68, 68) },
    ["Orange"] = { accent = Color3.fromRGB(255, 164, 58), accentSoft = Color3.fromRGB(195, 116, 38) },
    ["Pink"] = { accent = Color3.fromRGB(255, 105, 180), accentSoft = Color3.fromRGB(196, 73, 136) },
    ["White"] = { accent = Color3.fromRGB(235, 235, 235), accentSoft = Color3.fromRGB(155, 155, 155) },
    ["Black"] = { accent = Color3.fromRGB(18, 18, 18), accentSoft = Color3.fromRGB(48, 48, 48) },
    ["Rainbow"] = { accent = Color3.fromRGB(54, 248, 87), accentSoft = Color3.fromRGB(40, 180, 70) },
}

local function LerpNumber(a, b, t)
    return a + ((b - a) * t)
end

local function LerpColor(a, b, t)
    return Color3.new(LerpNumber(a.R, b.R, t), LerpNumber(a.G, b.G, t), LerpNumber(a.B, b.B, t))
end

local function SmoothFactor(speed, dt)
    return 1 - math.exp(-(speed or 1) * (dt or (1 / 60)))
end

local function NearlyEqual(a, b, epsilon)
    return math.abs((a or 0) - (b or 0)) <= (epsilon or 0.001)
end

local function NewBucket()
    return { objects = {}, visible = false, built = false, deferVisible = false }
end

---@class MushUI
local UI = {
    isRunning = true,
    isBooting = true,
    bootReady = false,
    bootStartedAt = tick(),
    bootDuration = 0.5,
    bootPanelScale = 0.4,
    bootVisualProgress = 0,
    bootVisualTarget = 0.06,
    uiVisible = true,
    uiAlpha = 1,
    uiOffset = 0,
    renderX = nil,
    renderY = nil,
    renderScale = 1,
    contentAlpha = 1,
    contentOffset = 0,
    activeTabHighlightY = 0,
    animatedScrollThumbY = nil,
    needsRedraw = true,
    shellDirty = true,
    tabDirty = {},
    hitboxes = {},
    hoveredId = nil,
    lastMousePressed = false,
    draggingWindow = false,
    draggingScroll = false,
    draggingSlider = false,
    activeSlider = nil,
    dragOffsetX = 0,
    dragOffsetY = 0,
    scrollDragOffset = 0,
    lastToggleTick = 0,
    launchTick = tick(),
    lastHomeStatRefresh = 0,
    lastConfigSaveTick = nil,
    expandedDropdown = nil,
    selectedTab = 1,
    settingsTabIndex = nil,
    animationState = {
        tabHover = {},
        tabActive = {},
        controlHover = {},
        dropdownOpen = {},
        sliderFill = {},
        toggleFill = {},
        checkboxFill = {},
    },
    window = {
        x = 220, y = 140,
        width = 620, height = 352,
        headerHeight = 42, footerHeight = 20,
        padding = 16, sidebarWidth = 185,
    },
    scroll = { offset = 0, max = 0 },
    shellBucket = NewBucket(),
    loadingBucket = NewBucket(),
    tabBuckets = {},
    tabs = {},
    controls = {},
}

function UI:Init(config)
    config = config or {}
    self.window.x = config.x or 220
    self.window.y = config.y or 140
    self.window.width = config.width or 620
    self.window.height = config.height or 352
    self.window.sidebarWidth = config.sidebarWidth or 185
    self.tabs = config.tabs or {}
    self.controls = config.controls or {}
    self.configFolderName = config.configFolder or "mush_config"
    self.configFileName = config.configFile or "config.json"
    self.bootDuration = config.bootDuration or 0.5
    self.settingsTabIndex = config.settingsTabIndex or nil

    self.tabDirty = {}
    self.tabBuckets = {}
    for i = 1, #self.tabs do
        self.tabDirty[i] = true
        self.tabBuckets[i] = NewBucket()
    end

    for _, tabControls in ipairs(self.controls) do
        for _, ctrl in ipairs(tabControls) do
            if ctrl.type == "toggle" or ctrl.type == "checkbox" then
                ctrl.value = ctrl.value == true
            elseif ctrl.type == "slider" then
                ctrl.value = tonumber(ctrl.value) or ctrl.min or 0
            end
        end
    end
end

function UI:Track(bucket, obj)
    if bucket and bucket.deferVisible then obj.Visible = false end
    table.insert(bucket.objects, obj)
    return obj
end

function UI:GetRenderTransparency(value)
    return math.clamp((value or 1) * (self.renderAlpha or 1), 0, 1)
end

function UI:SetDrawingProperty(obj, property, value, epsilon)
    local current = obj[property]
    if type(current) == "number" and type(value) == "number" then
        if NearlyEqual(current, value, epsilon) then return false end
    elseif current == value then
        return false
    end
    obj[property] = value
    return true
end

function UI:IsShellHitboxId(id)
    return type(id) == "string" and string.sub(id, 1, 4) == "tab_"
end

function UI:ClearBucket(bucket)
    for _, obj in ipairs(bucket.objects) do
        pcall(function() obj:Remove() end)
    end
    bucket.objects = {}
    bucket.visible = false
    bucket.built = false
end

function UI:HideBucket(bucket)
    for _, obj in ipairs(bucket.objects) do obj.Visible = false end
    bucket.visible = false
end

function UI:ShowBucket(bucket)
    for _, obj in ipairs(bucket.objects) do obj.Visible = true end
    bucket.visible = true
end

function UI:CreateSquare(bucket, x, y, w, h, color, transparency, filled, thickness)
    local square = Drawing.new("Square")
    local tx, ty = self:TransformPoint(x, y)
    local tw, th = self:TransformSize(w, h)
    self:SetDrawingProperty(square, "Position", Vector2.new(tx, ty))
    self:SetDrawingProperty(square, "Size", Vector2.new(tw, th))
    self:SetDrawingProperty(square, "Color", color)
    self:SetDrawingProperty(square, "Transparency", self:GetRenderTransparency(transparency or 1), 0.001)
    self:SetDrawingProperty(square, "Filled", filled ~= false)
    self:SetDrawingProperty(square, "Visible", not (bucket and bucket.deferVisible))
    if not square.Filled then
        self:SetDrawingProperty(square, "Thickness", thickness or 1, 0.001)
    end
    return self:Track(bucket, square)
end

function UI:CreateText(bucket, text, x, y, color, size, center)
    local label = Drawing.new("Text")
    local tx, ty = self:TransformPoint(x, y)
    self:SetDrawingProperty(label, "Text", text)
    self:SetDrawingProperty(label, "Position", Vector2.new(tx, ty))
    self:SetDrawingProperty(label, "Color", color)
    self:SetDrawingProperty(label, "Transparency", 1, 0.001)
    self:SetDrawingProperty(label, "Size", math.max(8, math.floor((size or 13) * (self.renderScale or 1) + 0.5)), 0.001)
    self:SetDrawingProperty(label, "Center", center or false)
    self:SetDrawingProperty(label, "Outline", true)
    self:SetDrawingProperty(label, "Visible", not (bucket and bucket.deferVisible))
    self:SetDrawingProperty(label, "Font", 1)
    return self:Track(bucket, label)
end

function UI:CreateRightText(bucket, text, rightX, y, color, size)
    local content = tostring(text or "")
    local fontSize = size or 13
    local estimatedWidth = math.max(0, math.floor(#content * (fontSize * 0.52)))
    return self:CreateText(bucket, content, rightX - estimatedWidth, y, color, fontSize, false)
end

function UI:CreateLine(bucket, fromX, fromY, toX, toY, color, transparency, thickness)
    local line = Drawing.new("Line")
    local tx1, ty1 = self:TransformPoint(fromX, fromY)
    local tx2, ty2 = self:TransformPoint(toX, toY)
    self:SetDrawingProperty(line, "From", Vector2.new(tx1, ty1))
    self:SetDrawingProperty(line, "To", Vector2.new(tx2, ty2))
    self:SetDrawingProperty(line, "Color", color)
    self:SetDrawingProperty(line, "Transparency", self:GetRenderTransparency(transparency or 1), 0.001)
    self:SetDrawingProperty(line, "Thickness", math.max(1, math.floor((thickness or 1) * (self.renderScale or 1) + 0.5)), 0.001)
    self:SetDrawingProperty(line, "Visible", not (bucket and bucket.deferVisible))
    return self:Track(bucket, line)
end

function UI:CreateCircle(bucket, x, y, radius, color, transparency, filled, thickness)
    local circle = Drawing.new("Circle")
    local tx, ty = self:TransformPoint(x, y)
    self:SetDrawingProperty(circle, "Position", Vector2.new(tx, ty))
    self:SetDrawingProperty(circle, "Radius", math.max(1, radius * (self.renderScale or 1)), 0.001)
    self:SetDrawingProperty(circle, "Color", color)
    self:SetDrawingProperty(circle, "Transparency", self:GetRenderTransparency(transparency or 1), 0.001)
    self:SetDrawingProperty(circle, "Filled", filled ~= false)
    self:SetDrawingProperty(circle, "Visible", not (bucket and bucket.deferVisible))
    if not circle.Filled then
        self:SetDrawingProperty(circle, "Thickness", math.max(1, math.floor((thickness or 1) * (self.renderScale or 1) + 0.5)), 0.001)
    end
    return self:Track(bucket, circle)
end

function UI:CreateImage(bucket, data, x, y, w, h, transparency)
    local ok, image = pcall(Drawing.new, "Image")
    if not ok or not image then return nil end
    local tx, ty = self:TransformPoint(x, y)
    local tw, th = self:TransformSize(w, h)
    local applied = pcall(function()
        self:SetDrawingProperty(image, "Position", Vector2.new(tx, ty))
        self:SetDrawingProperty(image, "Size", Vector2.new(tw, th))
        self:SetDrawingProperty(image, "Visible", not (bucket and bucket.deferVisible))
        self:SetDrawingProperty(image, "Transparency", self:GetRenderTransparency(transparency or 1), 0.001)
        self:SetDrawingProperty(image, "Data", data)
    end)
    if not applied then
        pcall(function() image:Remove() end)
        return nil
    end
    return self:Track(bucket, image)
end

function UI:CreateRoundedBox(bucket, x, y, w, h, radius, color)
    radius = math.floor(math.max(0, math.min(radius or 0, math.min(w, h) / 2)))
    if radius <= 0 then
        self:CreateSquare(bucket, x, y, w, h, color, 1, true)
        return
    end
    self:CreateSquare(bucket, x + radius, y, w - (radius * 2), h, color, 1, true)
    self:CreateSquare(bucket, x, y + radius, w, h - (radius * 2), color, 1, true)
    self:CreateCircle(bucket, x + radius, y + radius, radius, color, 1, true)
    self:CreateCircle(bucket, x + w - radius, y + radius, radius, color, 1, true)
    self:CreateCircle(bucket, x + radius, y + h - radius, radius, color, 1, true)
    self:CreateCircle(bucket, x + w - radius, y + h - radius, radius, color, 1, true)
end

function UI:AnimateValue(store, key, target, speed, dt, defaultValue)
    local current = store[key]
    if current == nil then current = defaultValue ~= nil and defaultValue or target end
    local nextValue = LerpNumber(current, target, SmoothFactor(speed or 12, dt))
    if math.abs(nextValue - target) < 0.001 then nextValue = target end
    store[key] = nextValue
    return nextValue, nextValue ~= target
end

function UI:GetAnimatedWindowYOffset()
    return math.floor(self.uiOffset + 0.5)
end

function UI:GetViewportSize()
    local camera = workspace and workspace.CurrentCamera or nil
    if camera and camera.ViewportSize then return camera.ViewportSize end
    return Vector2.new(1280, 720)
end

function UI:GetRenderWindowPosition()
    return math.floor((self.renderX or self.window.x) + 0.5), math.floor((self.renderY or self.window.y) + 0.5)
end

function UI:GetTransformCenter()
    local renderX, renderY = self:GetRenderWindowPosition()
    local baseY = renderY + self:GetAnimatedWindowYOffset()
    return renderX + (self.window.width * 0.5), baseY + (self.window.height * 0.5)
end

function UI:TransformPoint(x, y)
    local scale = self.renderScale or 1
    if math.abs(scale - 1) < 0.001 then return x, y end
    local centerX, centerY = self:GetTransformCenter()
    return centerX + ((x - centerX) * scale), centerY + ((y - centerY) * scale)
end

function UI:TransformSize(w, h)
    local scale = self.renderScale or 1
    if math.abs(scale - 1) < 0.001 then return w, h end
    return w * scale, h * scale
end

function UI:ResetContentAnimation()
    self.contentAlpha = 0
    self.contentOffset = 6
    self:MarkCurrentTabDirty()
end

function UI:AreAnimationsEnabled()
    if not self.settingsTabIndex then return true end
    local ctrl = self:GetControl(self.settingsTabIndex, "ui_animations")
    return not ctrl or ctrl.value == true
end

function UI:UpdateAnimations(dt)
    if not self:AreAnimationsEnabled() then
        self.uiAlpha = self.uiVisible and 1 or 0
        self.uiOffset = 0
        self.renderX = self.window.x
        self.renderY = self.window.y
        self.renderScale = 1
        self.contentAlpha = self.uiVisible and 1 or 0
        self.contentOffset = 0
        self.activeTabHighlightY = 110 + ((self.selectedTab - 1) * 32)
        for tabIndex = 1, #self.tabs do
            self.animationState.tabHover[tabIndex] = self.hoveredId == ("tab_" .. tostring(tabIndex)) and 1 or 0
            self.animationState.tabActive[tabIndex] = self.selectedTab == tabIndex and 1 or 0
        end
        for _, tabControls in ipairs(self.controls or {}) do
            for _, control in ipairs(tabControls) do
                self.animationState.controlHover[control.id] = self.hoveredId == control.id and 1 or 0
                self.animationState.dropdownOpen[control.id] = self.expandedDropdown == control.id and 1 or 0
                self.animationState.sliderFill[control.id] = control.type == "slider" and self:GetSliderPercent(control) or self.animationState.sliderFill[control.id]
                self.animationState.toggleFill[control.id] = control.type == "toggle" and (control.value and 1 or 0) or self.animationState.toggleFill[control.id]
                self.animationState.checkboxFill[control.id] = control.type == "checkbox" and (control.value and 1 or 0) or self.animationState.checkboxFill[control.id]
            end
        end
        local _, _, _, _, thumbTargetY = self:GetScrollbarMetrics()
        self.animatedScrollThumbY = thumbTargetY
        return
    end

    local shellAnimating = false
    local tabAnimating = false
    local alphaTarget = self.uiVisible and 1 or 0
    self.uiAlpha = LerpNumber(self.uiAlpha or alphaTarget, alphaTarget, SmoothFactor(16, dt))
    if math.abs(self.uiAlpha - alphaTarget) < 0.002 then self.uiAlpha = alphaTarget else shellAnimating = true; tabAnimating = true end

    local offsetTarget = self.uiVisible and 0 or 10
    self.uiOffset = LerpNumber(self.uiOffset or offsetTarget, offsetTarget, SmoothFactor(16, dt))
    if math.abs(self.uiOffset - offsetTarget) >= 0.02 then shellAnimating = true; tabAnimating = true else self.uiOffset = offsetTarget end

    self.renderX = self.window.x
    self.renderY = self.window.y

    local scaleTarget = self.uiVisible and 1 or 0.2
    self.renderScale = LerpNumber(self.renderScale or scaleTarget, scaleTarget, SmoothFactor(16, dt))
    if math.abs((self.renderScale or scaleTarget) - scaleTarget) >= 0.002 then shellAnimating = true; tabAnimating = true else self.renderScale = scaleTarget end

    local contentTarget = self.uiVisible and 1 or 0
    self.contentAlpha = LerpNumber(self.contentAlpha or contentTarget, contentTarget, SmoothFactor(14, dt))
    self.contentOffset = LerpNumber(self.contentOffset or 0, self.uiVisible and 0 or 4, SmoothFactor(14, dt))
    if math.abs(self.contentAlpha - contentTarget) >= 0.002 or math.abs(self.contentOffset - (self.uiVisible and 0 or 4)) >= 0.02 then
        tabAnimating = true
    else
        self.contentAlpha = contentTarget
        self.contentOffset = self.uiVisible and 0 or 4
    end

    local activeTabTargetY = 110 + ((self.selectedTab - 1) * 32)
    if self.draggingWindow then
        self.activeTabHighlightY = activeTabTargetY
    else
        self.activeTabHighlightY = LerpNumber(self.activeTabHighlightY or activeTabTargetY, activeTabTargetY, SmoothFactor(18, dt))
    end
    if math.abs((self.activeTabHighlightY or activeTabTargetY) - activeTabTargetY) >= 0.02 then shellAnimating = true else self.activeTabHighlightY = activeTabTargetY end

    for tabIndex = 1, #self.tabs do
        local hoverTarget = self.hoveredId == ("tab_" .. tostring(tabIndex)) and 1 or 0
        local activeTarget = self.selectedTab == tabIndex and 1 or 0
        local _, hoverMoving = self:AnimateValue(self.animationState.tabHover, tabIndex, hoverTarget, 18, dt, 0)
        local _, activeMoving = self:AnimateValue(self.animationState.tabActive, tabIndex, activeTarget, 18, dt, activeTarget)
        shellAnimating = shellAnimating or hoverMoving or activeMoving
    end

    for _, tabControls in ipairs(self.controls or {}) do
        for _, control in ipairs(tabControls) do
            local hoverTarget = self.hoveredId == control.id and 1 or 0
            local _, hoverMoving = self:AnimateValue(self.animationState.controlHover, control.id, hoverTarget, 16, dt, 0)
            tabAnimating = tabAnimating or hoverMoving

            if control.type == "dropdown_single" or control.type == "dropdown_multi" then
                local _, moving = self:AnimateValue(self.animationState.dropdownOpen, control.id, self.expandedDropdown == control.id and 1 or 0, 18, dt, 0)
                tabAnimating = tabAnimating or moving
            elseif control.type == "slider" then
                local _, moving = self:AnimateValue(self.animationState.sliderFill, control.id, self:GetSliderPercent(control), 14, dt, self:GetSliderPercent(control))
                tabAnimating = tabAnimating or moving
            elseif control.type == "toggle" then
                local _, moving = self:AnimateValue(self.animationState.toggleFill, control.id, control.value and 1 or 0, 16, dt, control.value and 1 or 0)
                tabAnimating = tabAnimating or moving
            elseif control.type == "checkbox" then
                local _, moving = self:AnimateValue(self.animationState.checkboxFill, control.id, control.value and 1 or 0, 16, dt, control.value and 1 or 0)
                tabAnimating = tabAnimating or moving
            end
        end
    end

    local _, _, _, _, thumbTargetY = self:GetScrollbarMetrics()
    self.animatedScrollThumbY = LerpNumber(self.animatedScrollThumbY or thumbTargetY, thumbTargetY, SmoothFactor(16, dt))
    if math.abs((self.animatedScrollThumbY or thumbTargetY) - thumbTargetY) >= 0.02 then tabAnimating = true else self.animatedScrollThumbY = thumbTargetY end

    if shellAnimating then self:MarkShellDirty() end
    if tabAnimating then self:MarkCurrentTabDirty() end
end

function UI:DrawCardFrame(bucket, x, y, w, h, outlineColor)
    self:CreateSquare(bucket, x, y, w, h, Theme.card, 1, true)
    self:CreateSquare(bucket, x, y, w, h, outlineColor or Theme.border, 1, false, 1)
    self:CreateLine(bucket, x + 1, y + 1, x + w - 2, y + 1, Theme.topHighlight, 0.42, 1)
    self:CreateLine(bucket, x + 1, y + 2, x + w - 2, y + 2, Theme.cardInner, 0.2, 1)
end

function UI:RegisterHitbox(id, x, y, w, h, callback, priority)
    table.insert(self.hitboxes, { id = id, x = x, y = y, w = w, h = h, callback = callback, priority = priority or 0 })
end

function UI:IsPointInRect(point, x, y, w, h)
    return point.X >= x and point.X <= (x + w) and point.Y >= y and point.Y <= (y + h)
end

function UI:IsPointInMainWindow(point)
    local wx, wyBase = self:GetRenderWindowPosition()
    local wy = wyBase + self:GetAnimatedWindowYOffset()
    return self:IsPointInRect(point, wx, wy, self.window.width, self.window.height)
end

function UI:IsPointInLoadingWindow(point)
    local loadingScale = 0.4
    local loadW = math.floor(self.window.width * loadingScale)
    local loadH = math.floor(self.window.height * loadingScale)
    local viewport = self:GetViewportSize()
    local loadX = math.floor((viewport.X - loadW) * 0.5)
    local loadY = math.floor((viewport.Y - loadH) * 0.5)
    return self:IsPointInRect(point, loadX, loadY, loadW, loadH)
end

function UI:GetMouseLocation()
    local ok, pos = pcall(function() return UserInputService:GetMouseLocation() end)
    if ok and pos then return pos end
    if LocalMouse then return Vector2.new(LocalMouse.X or 0, LocalMouse.Y or 0) end
    return Vector2.new(0, 0)
end

function UI:IsMousePressed()
    local ok, pressed = pcall(function() return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end)
    if ok then return pressed == true end
    local fn = ismouse1pressed
    if type(fn) == "function" then
        local pressOk, result = pcall(fn)
        if pressOk then return result == true end
    end
    return false
end

function UI:GetActiveControls()
    return self.controls[self.selectedTab] or {}
end

function UI:GetControl(tabIndex, controlId)
    local tabControls = self.controls[tabIndex] or {}
    for _, control in ipairs(tabControls) do
        if control.id == controlId then return control end
    end
    return nil
end

function UI:SetStatValue(controlId, value)
    local control = self:GetControl(1, controlId)
    local nextValue = tostring(value or "")
    if control and control.value ~= nextValue then
        control.value = nextValue
        self:MarkTabDirty(1)
    end
end

function UI:FormatDuration(seconds)
    local total = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(total / 3600)
    local minutes = math.floor((total % 3600) / 60)
    local secs = total % 60
    if hours > 0 then return string.format("%dh %dm %ds", hours, minutes, secs) end
    if minutes > 0 then return string.format("%dm %ds", minutes, secs) end
    return string.format("%ds", secs)
end

function UI:RefreshHomeStats(force)
    if not force and self.selectedTab ~= 1 then return end
    local now = tick()
    if not force and (now - (self.lastHomeStatRefresh or 0)) < 1 then return end
    self.lastHomeStatRefresh = now
    self:SetStatValue("uptime_stat", self:FormatDuration(now - (self.launchTick or now)))
    self:SetStatValue("profile_stat", LocalPlayer and LocalPlayer.Name or "Unknown")
    self:SetStatValue("game_stat", tostring(game and game.PlaceId or 0))
end

function UI:ApplyAccentTheme(themeName)
    local palette = AccentThemes[tostring(themeName or "")] or AccentThemes["Green"]
    Theme.accent = palette.accent
    Theme.accentSoft = palette.accentSoft
end

function UI:UpdateRainbowAccent()
    if not self.settingsTabIndex then return end
    local accentControl = self:GetControl(self.settingsTabIndex, "accent_theme")
    if not accentControl or accentControl.value ~= "Rainbow" then return end
    local hue = (tick() * 0.12) % 1
    local previousAccent = Theme.accent
    local previousAccentSoft = Theme.accentSoft
    Theme.accent = Color3.fromHSV(hue, 0.72, 1)
    Theme.accentSoft = Color3.fromHSV(hue, 0.62, 0.78)
    local accentChanged = not previousAccent or math.abs(previousAccent.R - Theme.accent.R) > 0.01 or math.abs(previousAccent.G - Theme.accent.G) > 0.01 or math.abs(previousAccent.B - Theme.accent.B) > 0.01
    local accentSoftChanged = not previousAccentSoft or math.abs(previousAccentSoft.R - Theme.accentSoft.R) > 0.01 or math.abs(previousAccentSoft.G - Theme.accentSoft.G) > 0.01 or math.abs(previousAccentSoft.B - Theme.accentSoft.B) > 0.01
    if accentChanged or accentSoftChanged then
        self:MarkShellDirty()
        self:MarkCurrentTabDirty()
        self.needsRedraw = true
    end
end

function UI:GetConfigFolderPath() return self.configFolderName or "mush_config" end
function UI:GetConfigFilePath() return self:GetConfigFolderPath() .. "/" .. (self.configFileName or "config.json") end

function UI:EnsureConfigStorage()
    if type(isfolder) == "function" then
        local ok, exists = pcall(isfolder, self:GetConfigFolderPath())
        if ok and exists then return true end
    end
    if type(makefolder) == "function" then
        local ok = pcall(makefolder, self:GetConfigFolderPath())
        if ok then return true end
    end
    return false
end

function UI:IsAutoSaveConfigEnabled()
    if not self.settingsTabIndex then return false end
    local control = self:GetControl(self.settingsTabIndex, "auto_save_config")
    return control and control.value == true
end

function UI:BuildConfigData()
    local data = { version = 1, controls = {} }
    for tabIndex, tabControls in ipairs(self.controls or {}) do
        for _, control in ipairs(tabControls) do
            if control.type ~= "button" and control.type ~= "stat" then
                local entry = { tab = tabIndex, type = control.type }
                if control.type == "dropdown_multi" then
                    entry.selected = control.selected or {}
                else
                    entry.value = control.value
                end
                data.controls[control.id] = entry
            end
        end
    end
    return data
end

function UI:ApplyConfigData(data)
    if type(data) ~= "table" or type(data.controls) ~= "table" then return end
    for controlId, saved in pairs(data.controls) do
        if type(saved) == "table" then
            local tabIndex = tonumber(saved.tab)
            local control = tabIndex and self:GetControl(tabIndex, controlId) or nil
            if control then
                if control.type == "dropdown_multi" and type(saved.selected) == "table" then
                    local applied = {}
                    for option, isSelected in pairs(saved.selected) do applied[tostring(option)] = isSelected == true end
                    control.selected = applied
                elseif saved.value ~= nil then
                    control.value = saved.value
                end
            end
        end
    end
    local widthControl = self.settingsTabIndex and self:GetControl(self.settingsTabIndex, "ui_scale")
    if widthControl and widthControl.value then self.window.width = widthControl.value end
    local heightControl = self.settingsTabIndex and self:GetControl(self.settingsTabIndex, "ui_height")
    if heightControl and heightControl.value then self.window.height = heightControl.value end
    local accentControl = self.settingsTabIndex and self:GetControl(self.settingsTabIndex, "accent_theme")
    if accentControl then self:ApplyAccentTheme(accentControl.value) end
    self:MarkShellDirty()
    for tabIndex = 1, #self.tabDirty do self:MarkTabDirty(tabIndex) end
end

function UI:SaveConfig(force)
    if not force and not self:IsAutoSaveConfigEnabled() then return false end
    if type(writefile) ~= "function" or not HttpService then return false end
    self:EnsureConfigStorage()
    local encodeOk, payload = pcall(function() return HttpService:JSONEncode(self:BuildConfigData()) end)
    if not encodeOk or not payload then return false end
    local writeOk = pcall(writefile, self:GetConfigFilePath(), payload)
    if writeOk then self.lastConfigSaveTick = tick() end
    return writeOk
end

function UI:LoadConfig()
    if type(readfile) ~= "function" or type(isfile) ~= "function" or not HttpService then return false end
    self:EnsureConfigStorage()
    local existsOk, exists = pcall(isfile, self:GetConfigFilePath())
    if not existsOk or not exists then return false end
    local readOk, payload = pcall(readfile, self:GetConfigFilePath())
    if not readOk or not payload or payload == "" then return false end
    local decodeOk, data = pcall(function() return HttpService:JSONDecode(payload) end)
    if not decodeOk or type(data) ~= "table" then return false end
    self:ApplyConfigData(data)
    return true
end

function UI:Notify(message, title, duration)
    if type(notify) == "function" then
        pcall(notify, tostring(message or ""), tostring(title or "mush"), tonumber(duration) or 3)
    end
end

function UI:GetLocalRootPart()
    local character = LocalPlayer and LocalPlayer.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

function UI:MarkShellDirty()
    if not self.shellDirty then self.shellDirty = true end
    if not self.needsRedraw then self.needsRedraw = true end
end

function UI:MarkTabDirty(tabIndex)
    if not self.tabDirty[tabIndex] then self.tabDirty[tabIndex] = true end
    if not self.needsRedraw then self.needsRedraw = true end
end

function UI:MarkCurrentTabDirty() self:MarkTabDirty(self.selectedTab) end

function UI:SetScrollOffset(offset)
    local nextOffset = math.clamp(math.floor(offset), 0, self.scroll.max)
    if self.scroll.offset == nextOffset then return false end
    self.scroll.offset = nextOffset
    self:MarkCurrentTabDirty()
    return true
end

function UI:ToggleDropdown(controlId)
    local previous = self.expandedDropdown
    if self.expandedDropdown == controlId then self.expandedDropdown = nil else self.expandedDropdown = controlId end
    if previous ~= self.expandedDropdown then self:UpdateScrollLimit(); self:MarkCurrentTabDirty() end
end

function UI:GetSliderPercent(control)
    local minValue = control.min or 0
    local maxValue = control.max or 1
    local value = control.value or minValue
    if maxValue <= minValue then return 0 end
    return math.clamp((value - minValue) / (maxValue - minValue), 0, 1)
end

function UI:SetSliderValue(control, percent)
    local minValue = control.min or 0
    local maxValue = control.max or 1
    local stepValue = control.step or 1
    local rawValue = minValue + ((maxValue - minValue) * math.clamp(percent, 0, 1))
    local steppedValue = minValue + math.floor(((rawValue - minValue) / stepValue) + 0.5) * stepValue
    steppedValue = math.clamp(steppedValue, minValue, maxValue)
    if control.value ~= steppedValue then
        control.value = steppedValue
        if control.id == "ui_scale" then self.window.width = steppedValue; self:MarkShellDirty()
        elseif control.id == "ui_height" then self.window.height = steppedValue; self:MarkShellDirty() end
        self:MarkCurrentTabDirty()
        self:SaveConfig(false)
    end
end

function UI:SetSliderFromMouse(control, mouseX)
    local sliderX = control._sliderX or 0
    local sliderW = control._sliderW or 1
    self:SetSliderValue(control, (mouseX - sliderX) / sliderW)
end

function UI:GetFormattedDropdownValue(control)
    if control.type == "dropdown_single" then return tostring(control.value or "Select") end
    local active = {}
    for _, option in ipairs(control.options or {}) do
        if control.selected and control.selected[option] then table.insert(active, option) end
    end
    if #active == 0 then return "None" end
    if #active <= 2 then return table.concat(active, ", ") end
    return active[1] .. ", " .. active[2] .. " +" .. tostring(#active - 2)
end

function UI:HandleControlClick(control)
    if control.type == "toggle" or control.type == "checkbox" then
        control.value = not control.value
        self:SaveConfig(control.id == "auto_save_config")
    elseif control.type == "button" then
        control.flashUntil = tick() + 0.35
        if control.callback then
            local ok, err = pcall(control.callback)
            if not ok then warn(err) end
        end
    elseif control.type == "dropdown_single" or control.type == "dropdown_multi" then
        self:ToggleDropdown(control.id)
        return
    end
    self:MarkCurrentTabDirty()
end

function UI:HandleDropdownOption(control, option)
    if control.type == "dropdown_single" then
        control.value = option
        self.expandedDropdown = nil
    else
        control.selected = control.selected or {}
        control.selected[option] = not control.selected[option]
    end
    if control.id == "accent_theme" then self:ApplyAccentTheme(control.value); self:MarkShellDirty() end
    if control.callback then
        local ok, err = pcall(control.callback, control, option)
        if not ok then warn(err) end
    end
    self:UpdateScrollLimit()
    self:MarkCurrentTabDirty()
    self:SaveConfig(false)
end

function UI:GetContentBounds()
    local renderX, renderY = self:GetRenderWindowPosition()
    local x = renderX + self.window.sidebarWidth + 14
    local y = renderY + 16 + self:GetAnimatedWindowYOffset()
    local width = self.window.width - self.window.sidebarWidth - 28
    local height = self.window.height - 32
    return x, y, width, height
end

function UI:GetScrollbarMetrics()
    local x, y, width, height = self:GetContentBounds()
    local scrollbarX = x + width - 10
    local scrollbarY = y + 8
    local scrollbarW = 4
    local scrollbarH = height - 16
    local thumbH = 0
    local thumbY = scrollbarY
    if self.scroll.max > 0 then
        thumbH = math.max(34, math.floor(scrollbarH * (height / (height + self.scroll.max))))
        local available = math.max(1, scrollbarH - thumbH)
        thumbY = scrollbarY + math.floor((self.scroll.offset / self.scroll.max) * available)
    end
    return scrollbarX, scrollbarY, scrollbarW, scrollbarH, thumbY, thumbH
end

function UI:UpdateScrollLimit()
    local previousMax = self.scroll.max
    local previousOffset = self.scroll.offset
    local _, _, _, viewportHeight = self:GetContentBounds()
    local contentHeight = 28
    for _, control in ipairs(self:GetActiveControls()) do
        contentHeight = contentHeight + ((control.type == "stat") and 54 or 98)
        if self.expandedDropdown == control.id and control.options then
            contentHeight = contentHeight + (#control.options * 30) + 10
        end
    end
    self.scroll.max = math.max(0, contentHeight - viewportHeight + 12)
    self.scroll.offset = math.clamp(self.scroll.offset, 0, self.scroll.max)
    return previousMax ~= self.scroll.max or previousOffset ~= self.scroll.offset
end

function UI:DrawToggle(bucket, control, x, y, w, h)
    local fill = self.animationState.toggleFill[control.id] or (control.value and 1 or 0)
    local boxSize = h
    local radius = math.max(3, math.floor(boxSize / 4))
    if fill <= 0.01 then
        self:CreateSquare(bucket, x, y, boxSize, boxSize, LerpColor(Theme.panelAlt, Theme.accentSoft, fill), 1, true)
        self:CreateSquare(bucket, x, y, boxSize, boxSize, LerpColor(Theme.border, Theme.accent, fill), 1, false, 1)
    else
        local borderColor = LerpColor(Theme.border, Theme.accent, fill)
        local fillColor = LerpColor(Theme.panelAlt, Theme.accent, fill)
        self:CreateRoundedBox(bucket, x, y, boxSize, boxSize, radius, borderColor)
        self:CreateRoundedBox(bucket, x + 1, y + 1, boxSize - 2, boxSize - 2, math.max(2, radius - 1), fillColor)
    end
end

function UI:DrawCheckbox(bucket, control, x, y, w, h)
    local fill = self.animationState.checkboxFill[control.id] or (control.value and 1 or 0)
    self:CreateSquare(bucket, x, y, w, h, LerpColor(Theme.panelAlt, Theme.accentSoft, fill), 1, true)
    self:CreateSquare(bucket, x, y, w, h, LerpColor(Theme.border, Theme.accent, fill), 1, false, 1)
    if fill > 0.01 then
        local inset = 4 + math.floor((1 - fill) * 2)
        self:CreateSquare(bucket, x + inset, y + inset, math.max(2, w - (inset * 2)), math.max(2, h - (inset * 2)), Theme.accent, fill, true)
    end
end

function UI:DrawButton(bucket, control, x, y, w, h)
    local activeFlash = control.flashUntil and tick() < control.flashUntil
    local pressOffset = activeFlash and 1 or 0
    local fillColor = activeFlash and Theme.panelAlt or Theme.panel
    local outlineColor = activeFlash and Theme.accentSoft or Theme.border
    self:CreateSquare(bucket, x, y, w, h, fillColor, 1, true)
    self:CreateSquare(bucket, x, y, w, h, outlineColor, 1, false, 1)
    if activeFlash then
        self:CreateLine(bucket, x + 1, y + h - 2, x + w - 2, y + h - 2, Theme.topHighlight, 0.28, 1)
    else
        self:CreateLine(bucket, x + 1, y + 1, x + w - 2, y + 1, Theme.topHighlight, 0.45, 1)
    end
    self:CreateText(bucket, control.label, x + math.floor(w / 2), y + 12 + pressOffset, Theme.text, 12, true)
end

function UI:DrawSlider(bucket, control, x, y, w, h)
    self:CreateText(bucket, tostring(control.value), x + w + 8, y - 2, Theme.text, 12, false)
    self:CreateSquare(bucket, x, y + 5, w, 8, Theme.panelAlt, 1, true)
    self:CreateSquare(bucket, x, y + 6, w, 6, Theme.borderSoft, 1, false, 1)
    local percent = self.animationState.sliderFill[control.id] or self:GetSliderPercent(control)
    local fillW = math.max(8, math.floor(w * percent))
    self:CreateSquare(bucket, x, y + 5, fillW, 8, Theme.accent, 1, true)
    local handleX = x + math.floor(w * percent)
    self:CreateSquare(bucket, handleX - 3, y + 3, 6, 12, Theme.text, 1, true)
    self:CreateSquare(bucket, handleX - 3, y + 3, 6, 12, Theme.border, 1, false, 1)
    control._sliderX = x
    control._sliderW = w
end

function UI:DrawDropdown(bucket, control, x, y, w, h)
    self:CreateSquare(bucket, x, y, w, h, Theme.panel, 1, true)
    self:CreateSquare(bucket, x, y, w, h, Theme.border, 1, false, 1)
    self:CreateLine(bucket, x + 1, y + 1, x + w - 2, y + 1, Theme.topHighlight, 0.45, 1)
    self:CreateLine(bucket, x + w - 30, y + 5, x + w - 30, y + h - 6, Theme.borderSoft, 0.65, 1)
    self:CreateText(bucket, self:GetFormattedDropdownValue(control), x + 12, y + 7, Theme.text, 12, false)
    self:CreateText(bucket, "v", x + w - 19, y + 7, Theme.text, 12, false)
end

function UI:HandleHotkeys()
    local VK_Z = 0x5A
    if type(iskeypressed) ~= "function" then return end
    local now = tick()
    if now - self.lastToggleTick < 0.2 then return end
    local okZ, zPressed = pcall(iskeypressed, VK_Z)
    if okZ and zPressed then
        self.uiVisible = not self.uiVisible
        if self.uiVisible then self.contentAlpha = 0.85; self.contentOffset = 4 end
        self:MarkShellDirty()
        self:MarkCurrentTabDirty()
        self.lastToggleTick = now
    end
end

function UI:HandleTransientEffects()
    local now = tick()
    local dirty = false
    for _, tabControls in ipairs(self.controls) do
        for _, control in ipairs(tabControls) do
            if control.type == "button" and control.flashUntil and now >= control.flashUntil then
                control.flashUntil = nil
                dirty = true
            end
        end
    end
    if dirty then self:MarkCurrentTabDirty() end
end

function UI:HandleInput()
    local mousePos = self:GetMouseLocation()
    local mouseDown = self:IsMousePressed()

    if self.draggingWindow and mouseDown then
        local nextX = math.floor(mousePos.X - self.dragOffsetX)
        local nextY = math.floor(mousePos.Y - self.dragOffsetY)
        if self.window.x ~= nextX or self.window.y ~= nextY then
            self.window.x = nextX
            self.window.y = nextY
            self:MarkShellDirty()
            self:MarkCurrentTabDirty()
        end
    elseif self.draggingWindow and not mouseDown then self.draggingWindow = false end

    if self.draggingSlider and self.activeSlider and mouseDown then
        self:SetSliderFromMouse(self.activeSlider, mousePos.X)
    elseif self.draggingSlider and not mouseDown then self.draggingSlider = false; self.activeSlider = nil end

    if self.draggingScroll and mouseDown then
        local scrollbarX, scrollbarY, scrollbarW, scrollbarH, _, thumbH = self:GetScrollbarMetrics()
        local available = math.max(1, scrollbarH - thumbH)
        local newThumbY = math.clamp(mousePos.Y - self.scrollDragOffset, scrollbarY, scrollbarY + available)
        self:SetScrollOffset(((newThumbY - scrollbarY) / available) * self.scroll.max)
    elseif self.draggingScroll and not mouseDown then self.draggingScroll = false end

    local hovered = nil
    local clickedHitbox = false
    for index = #self.hitboxes, 1, -1 do
        local hitbox = self.hitboxes[index]
        if mousePos.X >= hitbox.x and mousePos.X <= hitbox.x + hitbox.w and mousePos.Y >= hitbox.y and mousePos.Y <= hitbox.y + hitbox.h then
            hovered = hitbox.id
            if mouseDown and not self.lastMousePressed and hitbox.callback then
                clickedHitbox = true
                hitbox.callback()
            end
            break
        end
    end

    if mouseDown and not self.lastMousePressed and not clickedHitbox then
        local canDrag = (not self.isBooting and self:IsPointInMainWindow(mousePos)) or (self.isBooting and self:IsPointInLoadingWindow(mousePos))
        if canDrag then self.draggingWindow = true; self.dragOffsetX = mousePos.X - self.window.x; self.dragOffsetY = mousePos.Y - self.window.y end
    end

    if hovered ~= self.hoveredId then
        local previous = self.hoveredId
        local prevIsShell = self:IsShellHitboxId(previous)
        local hoverIsShell = self:IsShellHitboxId(hovered)
        self.hoveredId = hovered
        if prevIsShell or hoverIsShell then self:MarkShellDirty() end
        if (previous ~= nil and not prevIsShell) or (hovered ~= nil and not hoverIsShell) then self:MarkCurrentTabDirty() end
    end

    self.lastMousePressed = mouseDown
end

function UI:BuildShell()
    local bucket = self.shellBucket
    self:ClearBucket(bucket)
    bucket.deferVisible = true
    self.renderAlpha = self.uiAlpha
    local wx, wyBase = self:GetRenderWindowPosition()
    local wy = wyBase + self:GetAnimatedWindowYOffset()
    local ww = self.window.width
    local wh = self.window.height
    local sidebarW = self.window.sidebarWidth

    self:CreateSquare(bucket, wx, wy, ww, wh, Theme.bg, 1, true)
    self:CreateSquare(bucket, wx, wy, ww, wh, Theme.accent, 1, false, 1)
    self:CreateSquare(bucket, wx + 1, wy + 1, ww - 2, wh - 2, Theme.border, 1, false, 1)
    self:CreateSquare(bucket, wx + 1, wy + 1, sidebarW - 1, wh - 2, Theme.sidebar, 1, true)
    self:CreateLine(bucket, wx + sidebarW, wy + 2, wx + sidebarW, wy + wh - 2, Theme.borderSoft, 1, 1)

    local iconX = wx + 16
    local iconY = wy + 16
    self:CreateText(bucket, "mush", iconX + 18, iconY + 6, Theme.text, 17)
    self:CreateText(bucket, self.title or "Script", iconX + 18, iconY + 22, Theme.textDim, 14)
    self:CreateText(bucket, "TABS", wx + 16, wy + 82, Theme.textDim, 12)

    local tabY = wy + 110
    local highlightY = wy + math.floor((self.activeTabHighlightY or 110) + 0.5)
    self:CreateSquare(bucket, wx + 14, highlightY, sidebarW - 28, 27, Theme.accent, 1, true)
    self:CreateSquare(bucket, wx + 14, highlightY + 2, 2, 23, Theme.success, 0.18, true)
    self:CreateLine(bucket, wx + 18, highlightY + 2, wx + sidebarW - 17, highlightY + 2, Theme.success, 0.1, 1)

    for tabIndex, tab in ipairs(self.tabs) do
        local selectedAmount = self.animationState.tabActive[tabIndex] or (self.selectedTab == tabIndex and 1 or 0)
        local hoverAmount = self.animationState.tabHover[tabIndex] or 0
        local buttonY = tabY + ((tabIndex - 1) * 32)
        local buttonX = wx + 14
        local buttonW = sidebarW - 28
        local buttonH = 27
        self:CreateSquare(bucket, buttonX, buttonY, buttonW, buttonH, LerpColor(Theme.shell, Theme.panel, hoverAmount), 1 - (selectedAmount * 0.95), true)
        if hoverAmount > 0.01 and selectedAmount < 0.99 then
            self:CreateSquare(bucket, buttonX + 1, buttonY + 1, buttonW - 2, buttonH - 2, Theme.topHighlight, 0.04 * hoverAmount, true)
        end
        self:CreateText(bucket, tab.name, wx + 24, buttonY + 7, LerpColor(LerpColor(Theme.textDim, Theme.text, hoverAmount), Theme.success, selectedAmount), 13, false)
        self:RegisterHitbox("tab_" .. tostring(tabIndex), buttonX, buttonY, buttonW, buttonH, function()
            if self.selectedTab ~= tabIndex then
                self.selectedTab = tabIndex
                self.expandedDropdown = nil
                self.scroll.offset = 0
                self:ResetContentAnimation()
                self:UpdateScrollLimit()
                self:MarkShellDirty()
                self:MarkCurrentTabDirty()
            end
        end, 1)
    end

    self:CreateText(bucket, "Z = toggle", wx + ww - 72, wy + wh - 16, Theme.textMuted, 12)
    self:RegisterHitbox("window_drag", wx, wy, ww, 18, function()
        self.draggingWindow = true
        local mousePos = self:GetMouseLocation()
        self.dragOffsetX = mousePos.X - wx
        self.dragOffsetY = mousePos.Y - wy
    end, 1)

    bucket.built = true
    bucket.deferVisible = false
    self:ShowBucket(bucket)
    self.renderAlpha = 1
end

function UI:BuildLoadingScreen()
    local bucket = self.loadingBucket
    self:ClearBucket(bucket)
    bucket.deferVisible = true
    self.renderAlpha = 1
    local loadingScale = 0.4
    local loadW = math.floor(self.window.width * loadingScale)
    local loadH = math.floor(self.window.height * loadingScale)
    local viewport = self:GetViewportSize()
    local loadX = math.floor((viewport.X - loadW) * 0.5)
    local loadY = math.floor((viewport.Y - loadH) * 0.5)
    self.renderScale = self.bootPanelScale or 0.4

    self:CreateSquare(bucket, loadX, loadY, loadW, loadH, Theme.bg, 1, true)
    self:CreateSquare(bucket, loadX, loadY, loadW, loadH, Theme.accent, 1, false, 1)
    self:CreateSquare(bucket, loadX + 1, loadY + 1, loadW - 2, loadH - 2, Theme.border, 1, false, 1)
    self:CreateSquare(bucket, loadX, loadY, loadW, 2, Theme.accent, 1, true)

    local iconSize = 52
    local iconX = loadX + math.floor((loadW - iconSize) * 0.5)
    local iconY = loadY + 18
    self:CreateText(bucket, "mush", iconX + math.floor(iconSize * 0.5), iconY + 12, Theme.success, 24, true)
    self:CreateText(bucket, self.bootReady and "Ready" or "Loading...", loadX + math.floor(loadW * 0.5), loadY + 92, self.bootReady and Theme.text or Theme.textDim, 13, true)

    local progress = math.clamp(self.bootVisualProgress or 0, 0, 1)
    local barW = math.max(80, loadW - 40)
    local barX = loadX + math.floor((loadW - barW) * 0.5)
    local barY = loadY + loadH - 22
    self:CreateSquare(bucket, barX, barY, barW, 8, Theme.panelAlt, 1, true)
    self:CreateSquare(bucket, barX, barY, barW, 8, Theme.borderSoft, 1, false, 1)
    self:CreateSquare(bucket, barX, barY, math.max(8, math.floor(barW * progress)), 8, Theme.accent, 1, true)

    if self.bootReady then
        local buttonW = 78
        local buttonH = 24
        local buttonX = loadX + math.floor((loadW - buttonW) * 0.5)
        local buttonY = barY - 34
        local buttonHovered = self.hoveredId == "loading_load_button"
        self:CreateSquare(bucket, buttonX, buttonY, buttonW, buttonH, buttonHovered and Theme.panelAlt or Theme.panel, 1, true)
        self:CreateSquare(bucket, buttonX, buttonY, buttonW, buttonH, Theme.border, 1, false, 1)
        self:CreateLine(bucket, buttonX + 1, buttonY + 1, buttonX + buttonW - 2, buttonY + 1, Theme.topHighlight, 0.45, 1)
        self:CreateText(bucket, "Load", buttonX + math.floor(buttonW * 0.5), buttonY + 12, Theme.text, 12, true)
        self:RegisterHitbox("loading_load_button", buttonX, buttonY, buttonW, buttonH, function()
            self.isBooting = false
            self.bootReady = false
            if self:AreAnimationsEnabled() then
                self.uiAlpha = 0
                self.renderScale = 0.82
                self.contentAlpha = 0
                self.contentOffset = 4
            else
                self.uiAlpha = 1
                self.renderScale = 1
                self.contentAlpha = 1
                self.contentOffset = 0
            end
            self.needsRedraw = true
        end, 3)
    end

    self:RegisterHitbox("loading_drag", loadX, loadY, loadW, 18, function()
        self.draggingWindow = true
        local mousePos = self:GetMouseLocation()
        self.dragOffsetX = mousePos.X - self.window.x
        self.dragOffsetY = mousePos.Y - self.window.y
    end, 1)

    bucket.built = true
    bucket.deferVisible = false
    self:ShowBucket(bucket)
    self.renderAlpha = 1
    self.renderScale = 1
end

function UI:BuildActiveTab()
    local bucket = self.tabBuckets[self.selectedTab]
    self:ClearBucket(bucket)
    bucket.deferVisible = true
    self.renderAlpha = self.uiAlpha * self.contentAlpha
    local x, y, width, height = self:GetContentBounds()
    local cardX = x + 12
    local cardW = width - 28
    local drawY = y + 10 + math.floor((self.contentOffset or 0) + 0.5) - self.scroll.offset
    local bottomY = y + height

    for _, control in ipairs(self:GetActiveControls()) do
        local dropdownProgress = self.animationState.dropdownOpen[control.id] or ((self.expandedDropdown == control.id) and 1 or 0)
        local expanded = dropdownProgress > 0.01
        local optionCount = control.options and #control.options or 0
        local extraHeight = math.floor((((optionCount) * 30) + 8) * dropdownProgress)
        local cardH = ((control.type == "slider") and 56 or 44) + extraHeight
        local baseCardHeight = cardH - extraHeight
        local shouldDrawCard = drawY >= y and (drawY + baseCardHeight) <= bottomY

        if shouldDrawCard then
            if control.type == "stat" then
                self:DrawCardFrame(bucket, cardX, drawY, cardW, baseCardHeight, Theme.border)
                self:CreateText(bucket, control.label, cardX + 16, drawY + 16, Theme.textMuted, 13)
                self:CreateRightText(bucket, tostring(control.value or "-"), cardX + cardW - 18, drawY + 16, Theme.text, 13)
            else
                local hovered = self.animationState.controlHover[control.id] or 0
                self:DrawCardFrame(bucket, cardX, drawY, cardW, baseCardHeight, LerpColor(Theme.border, Theme.topHighlight, hovered))
                self:CreateText(bucket, control.label, cardX + 16, drawY + 16, Theme.text, 13)
                if control.type == "toggle" then self:DrawToggle(bucket, control, cardX + cardW - 32, drawY + 14, 16, 16)
                elseif control.type == "checkbox" then self:DrawCheckbox(bucket, control, cardX + cardW - 32, drawY + 14, 16, 16)
                elseif control.type == "button" then self:DrawButton(bucket, control, cardX + cardW - 128, drawY + 10, 114, 24)
                elseif control.type == "slider" then self:DrawSlider(bucket, control, cardX + 16, drawY + 32, cardW - 86, 18)
                else self:DrawDropdown(bucket, control, cardX + 176, drawY + 10, cardW - 192, 24) end

                if control.type == "slider" then
                    self:RegisterHitbox(control.id, cardX + 16, drawY + 26, cardW - 62, 24, function()
                        self.draggingSlider = true; self.activeSlider = control; self:SetSliderFromMouse(control, self:GetMouseLocation().X)
                    end, 2)
                elseif control.type ~= "stat" then
                    self:RegisterHitbox(control.id, cardX, drawY, cardW, baseCardHeight, function() self:HandleControlClick(control) end, 1)
                end

                if expanded then
                    local listY = drawY + baseCardHeight
                    local listH = math.max(0, extraHeight - 2)
                    self:CreateSquare(bucket, cardX, listY, cardW, listH, Theme.shell, 1, true)
                    self:CreateSquare(bucket, cardX, listY, cardW, listH, Theme.border, dropdownProgress, false, 1)
                    self:CreateLine(bucket, cardX + 1, listY + 1, cardX + cardW - 2, listY + 1, Theme.topHighlight, 0.35 * dropdownProgress, 1)
                    for optionIndex, option in ipairs(control.options) do
                        local rowY = listY + 4 + ((optionIndex - 1) * 30)
                        local selected = control.type == "dropdown_single" and control.value == option or (control.selected and control.selected[option] == true)
                        local optionHoverId = control.id .. "_opt_" .. optionIndex
                        local optionHovered = self.hoveredId == optionHoverId
                        if rowY + 26 <= listY + listH + 2 then
                            self:CreateSquare(bucket, cardX + 4, rowY, cardW - 8, 26, selected and Theme.accentSoft or (optionHovered and Theme.panelAlt or Theme.panel), dropdownProgress, true)
                            self:CreateSquare(bucket, cardX + 4, rowY, cardW - 8, 26, selected and Theme.accent or (optionHovered and Theme.topHighlight or Theme.borderSoft), dropdownProgress, false, 1)
                            local previousAlpha = self.renderAlpha
                            self.renderAlpha = previousAlpha * dropdownProgress
                            self:CreateText(bucket, option, cardX + 14, rowY + 6, Theme.text, 12)
                            self.renderAlpha = previousAlpha
                            if selected then self:CreateSquare(bucket, cardX + cardW - 24, rowY + 8, 8, 8, Theme.accent, dropdownProgress, true) end
                            if dropdownProgress > 0.96 then
                                self:RegisterHitbox(optionHoverId, cardX + 4, rowY, cardW - 8, 26, function() self:HandleDropdownOption(control, option) end, 2)
                            end
                        end
                    end
                end
            end
        end
        drawY = drawY + cardH + 10
    end

    local scrollbarX, scrollbarY, scrollbarW, scrollbarH, thumbY, thumbH = self:GetScrollbarMetrics()
    self:CreateSquare(bucket, scrollbarX, scrollbarY, scrollbarW, scrollbarH, Theme.panel, 1, true)
    self:CreateSquare(bucket, scrollbarX, scrollbarY, scrollbarW, scrollbarH, Theme.borderSoft, 1, false, 1)
    if self.scroll.max > 0 and self.scroll.offset < (self.scroll.max - 2) then
        self:CreateText(bucket, "v", x + math.floor((width - 16) * 0.5), y + height - 14, Theme.textDim, 12, true)
    end
    if self.scroll.max <= 0 then
        self:CreateSquare(bucket, scrollbarX + 1, scrollbarY + 1, scrollbarW - 2, scrollbarH - 2, Theme.panelAlt, 0.55, true)
    else
        local animatedThumbY = math.floor((self.animatedScrollThumbY or thumbY) + 0.5)
        self:CreateSquare(bucket, scrollbarX + 1, animatedThumbY, scrollbarW - 2, thumbH, Theme.accent, 1, true)
        self:CreateLine(bucket, scrollbarX + 1, animatedThumbY, scrollbarX + scrollbarW - 2, animatedThumbY, Theme.success, 0.18, 1)
        self:RegisterHitbox("scrollbar_thumb", scrollbarX - 10, animatedThumbY - 2, scrollbarW + 20, thumbH + 4, function()
            self.draggingScroll = true; self.scrollDragOffset = self:GetMouseLocation().Y - animatedThumbY
        end, 3)
    end

    bucket.built = true
    bucket.deferVisible = false
    self:ShowBucket(bucket)
    self.renderAlpha = 1
end

function UI:Render()
    self.hitboxes = {}
    if self.isBooting then
        self:HideBucket(self.shellBucket)
        for _, b in ipairs(self.tabBuckets) do self:HideBucket(b) end
        self:BuildLoadingScreen()
        self.needsRedraw = false
        return
    end
    self:HideBucket(self.loadingBucket)
    if (not self.uiVisible) and (self.uiAlpha or 0) <= 0.01 then
        self:HideBucket(self.shellBucket)
        self:HideBucket(self.loadingBucket)
        for _, b in ipairs(self.tabBuckets) do self:HideBucket(b) end
        self.needsRedraw = false
        return
    end
    self:UpdateScrollLimit()
    for tabIndex, bucket in ipairs(self.tabBuckets) do
        if tabIndex ~= self.selectedTab then self:HideBucket(bucket) end
    end
    local shellRebuilt = false
    if self.shellDirty or not self.shellBucket.built then
        self:BuildShell()
        self.shellDirty = false
        shellRebuilt = true
    else
        self:ShowBucket(self.shellBucket)
    end
    if shellRebuilt or self.tabDirty[self.selectedTab] or not self.tabBuckets[self.selectedTab].built then
        self:BuildActiveTab()
        self.tabDirty[self.selectedTab] = false
    else
        self:ShowBucket(self.tabBuckets[self.selectedTab])
    end
    self.needsRedraw = false
end

function UI:Start()
    self.title = self.title or "Script"
    self:ApplyAccentTheme("Green")
    pcall(function() self:LoadConfig() end)
    if self.controls[1] then
        self:RefreshHomeStats(true)
    end
    self:Render()

    RunService.RenderStepped:Connect(function(dt)
        if not self.isRunning then return end
        self:UpdateRainbowAccent()
        if self.isBooting then
            local oldProgress = self.bootVisualProgress or 0
            local oldTarget = self.bootVisualTarget or 0
            local oldReady = self.bootReady == true
            local oldPanelScale = self.bootPanelScale or 0.4
            local elapsed = tick() - self.bootStartedAt
            local duration = math.max(0.01, self.bootDuration)
            local timeProgress = math.clamp(elapsed / duration, 0, 1)
            local minProgress = math.min(0.985, timeProgress * 0.9)
            self.bootPanelScale = LerpNumber(self.bootPanelScale or 0.4, 1, SmoothFactor(10, dt or (1 / 60)))
            if math.abs((self.bootPanelScale or 1) - 1) < 0.001 then self.bootPanelScale = 1 end
            if (self.bootVisualTarget or 0) <= (self.bootVisualProgress or 0) + 0.01 then
                local remaining = math.max(minProgress + 0.02, 0.98 - (math.random() * 0.06))
                self.bootVisualTarget = math.clamp((self.bootVisualProgress or 0) + (0.03 + (math.random() * 0.14)), 0.08, remaining)
            end
            self.bootVisualProgress = math.max(minProgress, LerpNumber(self.bootVisualProgress or 0, self.bootVisualTarget or minProgress, SmoothFactor(2.2 + (math.random() * 0.8), dt or (1 / 60))))
            if timeProgress >= 1 then self.bootVisualProgress = 1 end
            if (tick() - self.bootStartedAt) >= self.bootDuration and (self.bootVisualProgress or 0) >= 0.999 then
                self.bootReady = true
            end
            if math.abs((self.bootVisualProgress or 0) - oldProgress) >= 0.002 or math.abs((self.bootVisualTarget or 0) - oldTarget) >= 0.01 or math.abs((self.bootPanelScale or 0.4) - oldPanelScale) >= 0.002 or (self.bootReady == true) ~= oldReady then
                self.needsRedraw = true
            end
        end
        pcall(function() self:UpdateAnimations(dt or (1 / 60)) end)
        pcall(function() self:HandleHotkeys() end)
        if self.controls[1] then
            pcall(function() self:RefreshHomeStats(false) end)
        end
        if self.isBooting then
            pcall(function() self:HandleInput() end)
        elseif self.uiVisible and (self.uiAlpha or 0) > 0.9 and (self.renderScale or 1) > 0.98 then
            pcall(function() self:HandleInput() end)
            pcall(function() self:HandleTransientEffects() end)
        end
        if self.needsRedraw then pcall(function() self:Render() end) end
    end)
end

return UI
