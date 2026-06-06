local versionNumber = "1.3.0"

_G.ConfigFolderName = "MushPickaxeTycoon"

-- Polyfill wait for Matcha (task.wait requires coroutine context)
local function safeWait(seconds)
  seconds = seconds or 0
  if coroutine.running() then
    task.wait(seconds)
  else
    local start = tick()
    repeat until tick() - start >= seconds
  end
end
wait = safeWait

-- Gui toggles
_G.AutoFarm = false
_G.AutoBuyPickaxe = false
_G.CollectAllOres = false
_G.AutoMerge = false
_G.FarmAllPlots = false
_G.AutoSell = false
_G.AutoRebirth = false

-- Settings variables
_G.DrawOreHitboxes = false
_G.DrawTroughHitboxes = false
_G.DrawPlayerHitboxes = false
_G.DrawSellPosition = false
_G.DrawTweenPath = false
_G.OreTeamCheck = true

-- Ui elements
local uiTable = {MTab = 1, hTab = 1, currentTab = "HOME", firstTime = true, notificationList = {}, sliderInfo = {selected = nil}, closeUi = false, textBoxOpen = false, dropDownOpen = false}

-- Ui config
local uiConfig = {x = 100, y = 50, editing = false, editMode = false, mousePos = Vector2.new(0, 0), offset = Vector2.new(0, 0), scale = 1, opacity = 1, rainbow = false}

-- Drawed event (custom, no Instance.new)
local DUI = {_connections = {}}
function DUI:Connect(fn)
  table.insert(self._connections, fn)
  return {Disconnect = function() end}
end
function DUI:Fire(...)
  for _, fn in next, self._connections do
    local s, e = pcall(fn, ...)
    if not s then warn("DUI error:", e) end
  end
end

--// Filled on init
local ScreenSize = workspace.CurrentCamera.ViewportSize

-- Objects
local TextObjects = {}
local CircleObjects = {}
local SquareObjects = {}
local LineObjects = {}
local ImageObjects = {}

-- Functions

function DrawSquare(args)
  local square = Drawing.new("Square")
  square.Visible = args.Visible or false
  square.Size = args.Size or Vector2.new(0,0)
  square.Position = args.Position or Vector2.new(0,0)
  square.Color = args.Color or Color3.fromRGB(255,255,255)
  square.Transparency = args.Transparency or 1
  square.Filled = args.Filled or false
  square.Thickness = args.Thickness or 1
  square.ZIndex = args.ZIndex or 0
  table.insert(SquareObjects, square)
  return square
end

function DrawText(args)
  local text = Drawing.new("Text")
  text.Visible = args.Visible or false
  text.Center = args.Center or false
  text.Outline = args.Outline or false
  text.Position = args.Position or Vector2.new(0,0)
  text.Size = args.Size or 14
  text.Color = args.Color or Color3.fromRGB(255,255,255)
  text.Transparency = args.Transparency or 1
  text.Text = args.Text or ""
  text.Font = args.Font or 1
  text.ZIndex = args.ZIndex or 0
  table.insert(TextObjects, text)
  return text
end

function DrawCircle(args)
  local circle = Drawing.new("Circle")
  circle.Visible = args.Visible or false
  circle.Radius = args.Radius or 0
  circle.Position = args.Position or Vector2.new(0,0)
  circle.Color = args.Color or Color3.fromRGB(255,255,255)
  circle.Transparency = args.Transparency or 1
  circle.Filled = args.Filled or false
  circle.Thickness = args.Thickness or 1
  circle.ZIndex = args.ZIndex or 0
  circle.NumSides = args.NumSides or 60
  table.insert(CircleObjects, circle)
  return circle
end

function DrawLine(args)
  local line = Drawing.new("Line")
  line.Visible = args.Visible or false
  line.From = args.From or Vector2.new(0,0)
  line.To = args.To or Vector2.new(0,0)
  line.Color = args.Color or Color3.fromRGB(255,255,255)
  line.Transparency = args.Transparency or 1
  line.Thickness = args.Thickness or 1
  line.ZIndex = args.ZIndex or 0
  table.insert(LineObjects, line)
  return line
end

function DrawImage(args)
  local img = Drawing.new("Image")
  img.Visible = args.Visible or false
  img.Position = args.Position or Vector2.new(0,0)
  img.Size = args.Size or Vector2.new(0,0)
  img.Color = args.Color or Color3.fromRGB(255,255,255)
  img.Transparency = args.Transparency or 1
  img.ZIndex = args.ZIndex or 0
  table.insert(ImageObjects, img)
  return img
end

local function updateObj()
  for _, v in next, SquareObjects do
    if v and v.Visible then
      v.Size = v.Size
      v.Position = v.Position
    end
  end
  for _, v in next, TextObjects do
    if v and v.Visible then
      v.Position = v.Position
    end
  end
  for _, v in next, CircleObjects do
    if v and v.Visible then
      v.Position = v.Position
    end
  end
  for _, v in next, LineObjects do
    if v and v.Visible then
      v.From = v.From
      v.To = v.To
    end
  end
  for _, v in next, ImageObjects do
    if v and v.Visible then
      v.Position = v.Position
      v.Size = v.Size
    end
  end
end

local function removeObj()
  for i, v in next, SquareObjects do
    if v then v:Remove() end
    SquareObjects[i] = nil
  end
  for i, v in next, TextObjects do
    if v then v:Remove() end
    TextObjects[i] = nil
  end
  for i, v in next, CircleObjects do
    if v then v:Remove() end
    CircleObjects[i] = nil
  end
  for i, v in next, LineObjects do
    if v then v:Remove() end
    LineObjects[i] = nil
  end
  for i, v in next, ImageObjects do
    if v then v:Remove() end
    ImageObjects[i] = nil
  end
end

-- Tween/lerp functions
local tweenTable = {}

local function calculateTween(current, target, speed)
  return current + (target - current) * speed
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function lerpColor(a, b, t)
  return Color3.new(lerp(a.R, b.R, t), lerp(a.G, b.G, t), lerp(a.B, b.B, t))
end

local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function formatNumber(number)
  local num = number
  if num >= 10^15 then
    return round(num / 10^15, 2) .. "Qd"
  elseif num >= 10^12 then
    return round(num / 10^12, 2) .. "T"
  elseif num >= 10^9 then
    return round(num / 10^9, 2) .. "B"
  elseif num >= 10^6 then
    return round(num / 10^6, 2) .. "M"
  elseif num >= 10^3 then
    return round(num / 10^3, 2) .. "K"
  else
    return round(num, 2)
  end
end

local function commaValue(amount)
  local formatted = tostring(amount)
  local k
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
    if k == 0 then break end
  end
  return formatted
end

local function IsPositionInsideTrough(troughPosition, troughCFrame, objectPosition)
  local success, relativePoint = pcall(function()
    return troughCFrame:PointToObjectSpace(objectPosition)
  end)
  if not success then
    local diff = objectPosition - troughPosition
    return math.abs(diff.X) < 5 and math.abs(diff.Z) < 5 and math.abs(diff.Y) < 5
  end
  return relativePoint.X > -3 and relativePoint.X < 3 and relativePoint.Z > -3 and relativePoint.Z < 3 and relativePoint.Y > -3 and relativePoint.Y < 3
end


-- WalkToService
local WalkToService = {}
WalkToService.__index = WalkToService

local LocalPlayer = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")

function WalkToService.TP(targetPos)
  local char = LocalPlayer.Character
  if not char then return end
  local root = char:FindFirstChild("HumanoidRootPart")
  if not root then return end
  root.Position = targetPos
end

function WalkToService.WalkTo(targetPos, tolerance)
  tolerance = tolerance or 5
  local char = LocalPlayer.Character
  if not char then return end
  local hum = char:FindFirstChild("Humanoid")
  if not hum then return end
  hum:MoveTo(targetPos)
end

function WalkToService.getDistance(fromPos, toPos)
  return (fromPos - toPos).Magnitude
end

function WalkToService.isAtPosition(currentPos, targetPos, tolerance)
  tolerance = tolerance or 5
  return (currentPos - targetPos).Magnitude <= tolerance
end

-- Tween/Animation services
function TweenToPosition(targetPos, speed)
  speed = speed or 250
  local character = LocalPlayer.Character
  if not character then return end
  local rootPart = character:FindFirstChild("HumanoidRootPart")
  if not rootPart then return end
  local direction = (targetPos - rootPart.Position).Unit
  local distance = (targetPos - rootPart.Position).Magnitude
  if distance > 1 then
    rootPart.Velocity = direction * math.min(speed, distance * 10)
  else
    rootPart.Velocity = Vector3.new(0, 0, 0)
  end
end

function TeleportToPosition(targetPos)
  local character = LocalPlayer.Character
  if not character then return end
  local rootPart = character:FindFirstChild("HumanoidRootPart")
  if not rootPart then return end
  rootPart.Position = targetPos
  rootPart.Velocity = Vector3.new(0, 0, 0)
end

function StopTween()
  local character = LocalPlayer.Character
  if not character then return end
  local rootPart = character:FindFirstChild("HumanoidRootPart")
  if not rootPart then return end
  rootPart.Velocity = Vector3.new(0, 0, 0)
  local hum = character:FindFirstChild("Humanoid")
  if hum then
    hum:MoveTo(rootPart.Position)
  end
end

-- Game interaction functions
local function GetOreInstances()
  local ores = {}
  local oreFolder = workspace:FindFirstChild("OreFolder")
  if not oreFolder then
    for _, v in next, workspace:GetDescendants() do
      if v:IsA("BasePart") and v.Name:lower():find("ore") then
        table.insert(ores, v)
      end
    end
    return ores
  end
  for _, v in next, oreFolder:GetChildren() do
    if v:IsA("BasePart") and v:FindFirstChild("OreValue") then
      table.insert(ores, v)
    end
  end
  return ores
end

local function GetOwnedPlot()
  local plots = {}
  local plotService = game:GetService("ReplicatedStorage"):FindFirstChild("PlotData")
  if plotService then
    for _, plot in next, plotService:GetChildren() do
      if plot:FindFirstChild("Owner") and plot.Owner.Value == LocalPlayer.UserId then
        table.insert(plots, plot)
      end
    end
  end
  return plots
end

local function GetSellPosition(plot)
  if not plot then return nil end
  local sellPart = plot:FindFirstChild("SellPart") or plot:FindFirstChild("SellZone")
  if sellPart then
    return sellPart.Position
  end
  return nil
end

-- Farm action handlers
local function CollectOres(plot)
  if not _G.CollectAllOres then return end
  local ores = GetOreInstances()
  local collected = 0
  for _, ore in next, ores do
    if not ore.Parent then continue end
    local distance = (ore.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    if distance < 30 then
      local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
      if tool then
        tool:Activate()
      end
      fireclickdetector(ore:FindFirstChildOfClass("ClickDetector"))
      collected = collected + 1
    end
  end
  return collected
end

local function AutoMerge(plot)
  if not _G.AutoMerge then return end
  local mergeFolder = plot:FindFirstChild("MergeArea") or plot:FindFirstChild("MergeFolder")
  if not mergeFolder then
    for _, v in next, plot:GetDescendants() do
      if v:IsA("BasePart") and v.Name:lower():find("merge") then
        fireclickdetector(v:FindFirstChildOfClass("ClickDetector"))
      end
    end
    return
  end
  for _, v in next, mergeFolder:GetChildren() do
    if v:FindFirstChildOfClass("ClickDetector") then
      fireclickdetector(v:FindFirstChildOfClass("ClickDetector"))
    end
  end
end

local function AutoBuyPickaxe()
  if not _G.AutoBuyPickaxe then return end
  local shopGUI = LocalPlayer.PlayerGui:FindFirstChild("ShopGUI")
  if not shopGUI then return end
  local buyButton = shopGUI:FindFirstChild("BuyPickaxe") or shopGUI:FindFirstChild("BuyButton")
  if buyButton and buyButton:IsA("GuiButton") then
    fireclickdetector(buyButton:FindFirstChildOfClass("ClickDetector"))
  end
end

local function HandleFarmSellActions(plot)
  if not _G.AutoSell then return end
  local sellPos = GetSellPosition(plot)
  if not sellPos then return end
  local char = LocalPlayer.Character
  if not char then return end
  local root = char:FindFirstChild("HumanoidRootPart")
  if not root then return end
  local distance = (root.Position - sellPos).Magnitude
  if distance > 15 then
    TeleportToPosition(sellPos)
    return
  end
  local sellPart = plot:FindFirstChild("SellPart") or plot:FindFirstChild("SellZone")
  if sellPart then
    fireclickdetector(sellPart:FindFirstChildOfClass("ClickDetector"))
  end
end

-- Notification system
local function AddNotification(title, text, duration, notifType)
  duration = duration or 3
  notifType = notifType or "Info"
  local notif = {title = title, text = text, duration = duration, startTime = tick(), type = notifType, alpha = 0, yOffset = 0}
  table.insert(uiTable.notificationList, notif)
  return notif
end

-- Get config folder path
local function GetConfigFolderPath()
  local success, path = pcall(function()
    return game:GetService("HttpService"):GetAsync("https://httpbin.org/get")
  end)
  if success then
    local folder = isfolder and isfolder("MushBase")
    if folder then
      return "MushBase"
    end
  end
  local paths = {
    "MushPickaxeTycoon",
    "MushBase"
  }
  for _, p in next, paths do
    local s, _ = pcall(function()
      if isfolder and isfolder(p) then return p end
    end)
    if s then return p end
  end
  return "MushPickaxeTycoon"
end

-- Save/Load config
local function SaveConfig()
  local data = {
    autoFarm = _G.AutoFarm,
    autoBuyPickaxe = _G.AutoBuyPickaxe,
    collectAllOres = _G.CollectAllOres,
    autoMerge = _G.AutoMerge,
    farmAllPlots = _G.FarmAllPlots,
    autoSell = _G.AutoSell,
    autoRebirth = _G.AutoRebirth,
    drawOreHitboxes = _G.DrawOreHitboxes,
    drawTroughHitboxes = _G.DrawTroughHitboxes,
    drawPlayerHitboxes = _G.DrawPlayerHitboxes,
    drawSellPosition = _G.DrawSellPosition,
    drawTweenPath = _G.DrawTweenPath,
    oreTeamCheck = _G.OreTeamCheck
  }
  local success, json = pcall(function()
    return game:GetService("HttpService"):JSONEncode(data)
  end)
  if success then
    local path = GetConfigFolderPath()
    pcall(function()
      writefile(path .. "/PickaxeTycoonConfig.json", json)
    end)
  end
end

local function LoadConfig()
  local path = GetConfigFolderPath()
  local success, content = pcall(function()
    return readfile(path .. "/PickaxeTycoonConfig.json")
  end)
  if success and content then
    local s, data = pcall(function()
      return game:GetService("HttpService"):JSONDecode(content)
    end)
    if s and type(data) == "table" then
      for k, v in next, data do
        if _G[k] ~= nil then
          _G[k] = v
        end
      end
    end
  end
end

-- UI Build functions
local function BuildShell()
  local shell = {}
  shell.elements = {}

  function shell:AddSquare(args)
    local sq = DrawSquare(args)
    table.insert(self.elements, sq)
    return sq
  end

  function shell:AddText(args)
    local txt = DrawText(args)
    table.insert(self.elements, txt)
    return txt
  end

  function shell:AddCircle(args)
    local circ = DrawCircle(args)
    table.insert(self.elements, circ)
    return circ
  end

  function shell:AddLine(args)
    local line = DrawLine(args)
    table.insert(self.elements, line)
    return line
  end

  function shell:AddImage(args)
    local img = DrawImage(args)
    table.insert(self.elements, img)
    return img
  end

  function shell:Destroy()
    for _, v in next, self.elements do
      if v and v.Remove then
        pcall(function() v:Remove() end)
      end
    end
    self.elements = {}
  end

  return shell
end

local function BuildLoadingScreen()
  local shell = BuildShell()
  local alpha = 0
  local state = "fadein"
  local dots = ""
  local dotTimer = 0

  local bg = shell:AddSquare({Size = ScreenSize, Position = Vector2.new(0, 0), Color = Color3.fromRGB(20, 20, 20), Transparency = 1, Filled = true, ZIndex = 999, Visible = true})
  local logo = shell:AddText({Text = "M", Position = Vector2.new(ScreenSize.X / 2, ScreenSize.Y / 2 - 40), Size = 60, Color = Color3.fromRGB(255, 200, 50), Transparency = 1, Center = true, Visible = true, ZIndex = 1000})
  local loadingText = shell:AddText({Text = "Loading", Position = Vector2.new(ScreenSize.X / 2, ScreenSize.Y / 2 + 20), Size = 20, Color = Color3.fromRGB(200, 200, 200), Transparency = 1, Center = true, Visible = true, ZIndex = 1000})

  local con
  con = DUI:Connect(function(dt)
    if state == "fadein" then
      alpha = math.min(alpha + dt * 2, 1)
      bg.Transparency = 1 - alpha
      logo.Transparency = 1 - alpha
      loadingText.Transparency = 1 - alpha
      if alpha >= 1 then
        state = "wait"
      end
    elseif state == "wait" then
      dotTimer = dotTimer + dt
      if dotTimer > 0.5 then
        dotTimer = 0
        if #dots < 3 then
          dots = dots .. "."
        else
          dots = ""
        end
        loadingText.Text = "Loading" .. dots
      end
    elseif state == "fadeout" then
      alpha = math.max(alpha - dt * 3, 0)
      bg.Transparency = 1 - alpha
      logo.Transparency = 1 - alpha
      loadingText.Transparency = 1 - alpha
      if alpha <= 0 then
        con:Disconnect()
        shell:Destroy()
      end
    end
  end)

  local function finish()
    state = "fadeout"
  end

  return finish
end

local function BuildActiveTab(tab)
  local shell = BuildShell()
  local basePos = Vector2.new(uiConfig.x, uiConfig.y)
  local s = uiConfig.scale
  local opacity = uiConfig.opacity

  if tab == "HOME" then
    local yOff = 0
    shell:AddText({Text = "Mush Pickaxe Tycoon", Position = basePos + Vector2.new(10 * s, yOff), Size = 18 * s, Color = Color3.fromRGB(255, 200, 50), Transparency = opacity, Visible = true, ZIndex = 10})
    yOff = yOff + 30 * s
    shell:AddText({Text = "by Mush", Position = basePos + Vector2.new(10 * s, yOff), Size = 12 * s, Color = Color3.fromRGB(180, 180, 180), Transparency = opacity, Visible = true, ZIndex = 10})
    yOff = yOff + 25 * s
    shell:AddText({Text = "Version: " .. versionNumber, Position = basePos + Vector2.new(10 * s, yOff), Size = 11 * s, Color = Color3.fromRGB(150, 150, 150), Transparency = opacity, Visible = true, ZIndex = 10})
  elseif tab == "FARM" then
    local yOff = 0
    local toggles = {
      {label = "Auto Farm", key = "AutoFarm"},
      {label = "Collect All Ores", key = "CollectAllOres"},
      {label = "Auto Merge", key = "AutoMerge"},
      {label = "Auto Buy Pickaxe", key = "AutoBuyPickaxe"},
      {label = "Auto Sell", key = "AutoSell"},
      {label = "Farm All Plots", key = "FarmAllPlots"},
      {label = "Auto Rebirth", key = "AutoRebirth"}
    }
    for _, t in next, toggles do
      local bgColor = _G[t.key] and Color3.fromRGB(60, 200, 80) or Color3.fromRGB(60, 60, 60)
      shell:AddSquare({Position = basePos + Vector2.new(10 * s, yOff), Size = Vector2.new(180 * s, 22 * s), Color = bgColor, Transparency = opacity, Filled = true, ZIndex = 10, Visible = true})
      shell:AddText({Text = t.label, Position = basePos + Vector2.new(16 * s, yOff + 3 * s), Size = 12 * s, Color = Color3.fromRGB(255, 255, 255), Transparency = opacity, Visible = true, ZIndex = 11})
      yOff = yOff + 26 * s
    end
  elseif tab == "MISC" then
    local yOff = 0
    local drawToggles = {
      {label = "Ore Hitboxes", key = "DrawOreHitboxes"},
      {label = "Trough Hitboxes", key = "DrawTroughHitboxes"},
      {label = "Player Hitboxes", key = "DrawPlayerHitboxes"},
      {label = "Sell Position", key = "DrawSellPosition"},
      {label = "Tween Path", key = "DrawTweenPath"},
      {label = "Team Check", key = "OreTeamCheck"}
    }
    for _, t in next, drawToggles do
      local bgColor = _G[t.key] and Color3.fromRGB(60, 200, 80) or Color3.fromRGB(60, 60, 60)
      shell:AddSquare({Position = basePos + Vector2.new(10 * s, yOff), Size = Vector2.new(180 * s, 22 * s), Color = bgColor, Transparency = opacity, Filled = true, ZIndex = 10, Visible = true})
      shell:AddText({Text = t.label, Position = basePos + Vector2.new(16 * s, yOff + 3 * s), Size = 12 * s, Color = Color3.fromRGB(255, 255, 255), Transparency = opacity, Visible = true, ZIndex = 11})
      yOff = yOff + 26 * s
    end
  elseif tab == "TELEPORTS" then
    local yOff = 0
    local teleports = {
      {label = "Spawn", pos = Vector3.new(0, 10, 0)},
      {label = "Shop", pos = Vector3.new(50, 10, 0)},
      {label = "Mine", pos = Vector3.new(-50, 10, 0)}
    }
    for _, tp in next, teleports do
      shell:AddSquare({Position = basePos + Vector2.new(10 * s, yOff), Size = Vector2.new(180 * s, 22 * s), Color = Color3.fromRGB(40, 80, 160), Transparency = opacity, Filled = true, ZIndex = 10, Visible = true})
      shell:AddText({Text = tp.label, Position = basePos + Vector2.new(16 * s, yOff + 3 * s), Size = 12 * s, Color = Color3.fromRGB(255, 255, 255), Transparency = opacity, Visible = true, ZIndex = 11})
      shell.teleportData = shell.teleportData or {}
      table.insert(shell.teleportData, {label = tp.label, pos = tp.pos, y = yOff})
      yOff = yOff + 26 * s
    end
  elseif tab == "SETTINGS" then
    local yOff = 0
    shell:AddText({Text = "UI Settings", Position = basePos + Vector2.new(10 * s, yOff), Size = 14 * s, Color = Color3.fromRGB(255, 200, 50), Transparency = opacity, Visible = true, ZIndex = 10})
    yOff = yOff + 24 * s
    shell:AddText({Text = "Drag to move | Right-click to close", Position = basePos + Vector2.new(10 * s, yOff), Size = 10 * s, Color = Color3.fromRGB(150, 150, 150), Transparency = opacity, Visible = true, ZIndex = 10})
    yOff = yOff + 20 * s
    local scaleText = shell:AddText({Text = "Scale: " .. tostring(math.floor(uiConfig.scale * 100)) .. "%", Position = basePos + Vector2.new(10 * s, yOff), Size = 12 * s, Color = Color3.fromRGB(200, 200, 200), Transparency = opacity, Visible = true, ZIndex = 10})
    shell.settingsTexts = {scale = scaleText}
  end

  return shell
end

-- Vector3 world to screen conversion
local function WorldToScreenFunc(worldPos)
  local success, result = pcall(function()
    return workspace.CurrentCamera:WorldToScreenPoint(worldPos)
  end)
  if success and result then
    return Vector2.new(result.X, result.Y), result.Z
  end
  local s, v = pcall(WorldToScreen, worldPos)
  if s and v then
    return v, v.Z or 0
  end
  return Vector2.new(0, 0), 999
end

-- Hitbox drawing
local function DrawOreHitboxesFunc()
  if not _G.DrawOreHitboxes then return end
  local ores = GetOreInstances()
  for _, ore in next, ores do
    local screenPos, onScreen = WorldToScreenFunc(ore.Position)
    if onScreen then
      local size = math.max(300 / (onScreen + 1), 2)
      local sq = DrawSquare({Position = screenPos - Vector2.new(size / 2, size / 2), Size = Vector2.new(size, size), Color = Color3.fromRGB(255, 200, 50), Transparency = 0.7, Filled = false, Thickness = 1, ZIndex = 5, Visible = true})
    end
  end
end

local function DrawTroughHitboxesFunc()
  if not _G.DrawTroughHitboxes then return end
  local plots = GetOwnedPlot()
  for _, plot in next, plots do
    local trough = plot:FindFirstChild("Trough") or plot:FindFirstChild("TroughPart")
    if trough then
      local screenPos, onScreen = WorldToScreenFunc(trough.Position)
      if onScreen then
        local size = math.max(300 / (onScreen + 1), 4)
        local sq = DrawSquare({Position = screenPos - Vector2.new(size / 2, size / 2), Size = Vector2.new(size, size), Color = Color3.fromRGB(50, 200, 255), Transparency = 0.7, Filled = false, Thickness = 2, ZIndex = 5, Visible = true})
      end
    end
  end
end

local function DrawPlayerHitboxesFunc()
  if not _G.DrawPlayerHitboxes then return end
  for _, player in next, game:GetService("Players"):GetPlayers() do
    if player == LocalPlayer then continue end
    local char = player.Character
    if not char then continue end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then continue end
    local screenPos, onScreen = WorldToScreenFunc(root.Position)
    if onScreen then
      local size = math.max(300 / (onScreen + 1), 4)
      local sq = DrawSquare({Position = screenPos - Vector2.new(size / 2, size / 2), Size = Vector2.new(size, size), Color = Color3.fromRGB(255, 50, 50), Transparency = 0.7, Filled = false, Thickness = 2, ZIndex = 5, Visible = true})
    end
  end
end

-- Input handling
local function HandleInput()
  local mousePos = Vector2.new(0, 0)
  local success, result = pcall(function()
    return game:GetService("UserInputService"):GetMouseLocation()
  end)
  if success and result then
    mousePos = Vector2.new(result.X, result.Y)
  else
    mousePos = Vector2.new(0, 0)
  end

  if ismouse1pressed and ismouse1pressed() then
    if uiConfig.editing then
      local delta = mousePos - uiConfig.mousePos
      uiConfig.x = uiConfig.x + delta.X
      uiConfig.y = uiConfig.y + delta.Y
    end
    uiConfig.mousePos = mousePos
    uiConfig.editing = true
  else
    if uiConfig.editing then
      uiConfig.editing = false
      SaveConfig()
    end
  end

  if ismouse1pressed and ismouse1pressed() then
    local clickPos = mousePos
    local relativePos = clickPos - Vector2.new(uiConfig.x, uiConfig.y)
    local s = uiConfig.scale
    local yOff = 0
    local tab = uiTable.currentTab

    if tab == "HOME" then
    elseif tab == "FARM" then
      yOff = 0
      local toggles = {"AutoFarm", "CollectAllOres", "AutoMerge", "AutoBuyPickaxe", "AutoSell", "FarmAllPlots", "AutoRebirth"}
      for i, key in next, toggles do
        local bx = 10 * s; local by = yOff
        local bw = 180 * s; local bh = 22 * s
        if relativePos.X >= bx and relativePos.X <= bx + bw and relativePos.Y >= by and relativePos.Y <= by + bh then
          _G[key] = not _G[key]
          SaveConfig()
          break
        end
        yOff = yOff + 26 * s
      end
    elseif tab == "MISC" then
      yOff = 0
      local toggles = {"DrawOreHitboxes", "DrawTroughHitboxes", "DrawPlayerHitboxes", "DrawSellPosition", "DrawTweenPath", "OreTeamCheck"}
      for i, key in next, toggles do
        local bx = 10 * s; local by = yOff
        local bw = 180 * s; local bh = 22 * s
        if relativePos.X >= bx and relativePos.X <= bx + bw and relativePos.Y >= by and relativePos.Y <= by + bh then
          _G[key] = not _G[key]
          SaveConfig()
          break
        end
        yOff = yOff + 26 * s
      end
    elseif tab == "TELEPORTS" then
      yOff = 0
      local teleports = {
        {label = "Spawn", pos = Vector3.new(0, 10, 0)},
        {label = "Shop", pos = Vector3.new(50, 10, 0)},
        {label = "Mine", pos = Vector3.new(-50, 10, 0)}
      }
      for _, tp in next, teleports do
        local bx = 10 * s; local by = yOff
        local bw = 180 * s; local bh = 22 * s
        if relativePos.X >= bx and relativePos.X <= bx + bw and relativePos.Y >= by and relativePos.Y <= by + bh then
          TeleportToPosition(tp.pos)
          break
        end
        yOff = yOff + 26 * s
      end
    end
  end
end

-- Tab rendering
local function DrawTabs(shell)
  local s = uiConfig.scale
  local tabs = {"HOME", "FARM", "MISC", "TELEPORTS", "SETTINGS"}
  local tabWidth = 40 * s
  local totalWidth = #tabs * tabWidth
  local startX = uiConfig.x + 5 * s
  local yPos = uiConfig.y + 5 * s

  for i, tabName in next, tabs do
    local selected = tabName == uiTable.currentTab
    local bgColor = selected and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(40, 40, 40)
    local textColor = selected and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(200, 200, 200)
    shell:AddSquare({Position = Vector2.new(startX + (i - 1) * tabWidth, yPos), Size = Vector2.new(tabWidth - 2, 22 * s), Color = bgColor, Transparency = uiConfig.opacity, Filled = true, ZIndex = 10, Visible = true})
    shell:AddText({Text = tabName, Position = Vector2.new(startX + (i - 1) * tabWidth + tabWidth / 2, yPos + 3 * s), Size = 11 * s, Color = textColor, Transparency = uiConfig.opacity, Center = true, Visible = true, ZIndex = 11})
  end
end

-- Main update
local function UpdateUI(dt)
  if uiTable.closeUi then return end
  removeObj()

  local shell = BuildShell()

  -- Main background
  shell:AddSquare({Position = Vector2.new(uiConfig.x, uiConfig.y), Size = Vector2.new(220 * uiConfig.scale, 300 * uiConfig.scale), Color = Color3.fromRGB(25, 25, 25), Transparency = uiConfig.opacity, Filled = true, ZIndex = 9, Visible = true})
  shell:AddSquare({Position = Vector2.new(uiConfig.x, uiConfig.y), Size = Vector2.new(220 * uiConfig.scale, 300 * uiConfig.scale), Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Filled = false, Thickness = 1, ZIndex = 10, Visible = true})

  DrawTabs(shell)

  -- Content area
  local contentShell = BuildActiveTab(uiTable.currentTab)
  shell:Destroy()
end

-- Main farm logic
local function FarmLoop()
  while wait(0.5) do
    if not _G.AutoFarm then
      wait(1)
      continue
    end
    local plots = GetOwnedPlot()
    if #plots == 0 then
      wait(2)
      continue
    end
    for _, plot in next, plots do
      if not _G.AutoFarm then break end
      CollectOres(plot)
      AutoMerge(plot)
      HandleFarmSellActions(plot)
    end
    if _G.AutoBuyPickaxe then
      AutoBuyPickaxe()
    end
  end
end

-- Init
local function Init()
  local loadingFinish = BuildLoadingScreen()
  LoadConfig()
  AddNotification("Mush Pickaxe Tycoon", "Script loaded successfully", 3, "Info")
  wait(1.5)
  loadingFinish()
end

-- Main render loop
local renderCon
renderCon = game:GetService("RunService").RenderStepped:Connect(function(dt)
  if uiTable.closeUi then
    removeObj()
    renderCon:Disconnect()
    return
  end
  updateObj()
  DUI:Fire(dt)
  UpdateUI(dt)
  HandleInput()
  DrawOreHitboxesFunc()
  DrawTroughHitboxesFunc()
  DrawPlayerHitboxesFunc()
end)

-- Start farm loop in background
task.spawn(FarmLoop)

-- Start init
task.spawn(Init)

-- Close handler
local closeButton = DrawSquare({Position = Vector2.new(uiConfig.x + 200 * uiConfig.scale, uiConfig.y + 2), Size = Vector2.new(16, 16), Color = Color3.fromRGB(200, 50, 50), Transparency = 0.8, Filled = true, ZIndex = 100, Visible = true})
local closeText = DrawText({Text = "X", Position = Vector2.new(uiConfig.x + 208 * uiConfig.scale, uiConfig.y + 3), Size = 13, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.8, Center = true, ZIndex = 101, Visible = true})

-- Keybind toggle (Insert key)
local insertDebounce = 0
local keybindCon
keybindCon = game:GetService("RunService").RenderStepped:Connect(function()
  local keyPressed = false
  local success, result = pcall(function()
    return game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Insert)
  end)
  if success and result then
    keyPressed = result
  else
    local s, r = pcall(function()
      return iskeypressed(0x2D)
    end)
    if s then keyPressed = r end
  end
  if keyPressed and tick() - insertDebounce > 0.3 then
    uiTable.closeUi = not uiTable.closeUi
    insertDebounce = tick()
  end
end)

print("Mush Pickaxe Tycoon loaded successfully!")
