-- ABA AFK Script
-- Auto-press skills (1,2,3,4) + auto-attack (Mouse1 hold)

local running = false
local toggleKey = 0x59 -- Y

local skillKeys = {0x31, 0x32, 0x33, 0x34, 0x47} -- 1, 2, 3, 4, G

local debounce = 0

local function pressKey(key)
  pcall(keypress, key)
  task.wait(0.05)
  pcall(keyrelease, key)
end

local function doComboAsync()
  -- Hold mouse1 while running
  pcall(mouse1press)
  while running do
    -- Press all skill keys
    for _, key in next, skillKeys do
      if not running then break end
      pressKey(key)
      task.wait(0.15)
    end
    task.wait(0.3)
  end
  pcall(mouse1release)
end

local toggleCon
toggleCon = game:GetService("RunService").RenderStepped:Connect(function()
  local pressed = false
  local s, r = pcall(function()
    return iskeypressed(toggleKey)
  end)
  if s then pressed = r end

  if pressed and tick() - debounce > 0.3 then
    running = not running
    debounce = tick()
    if running then
      print("[ABA AFK] ON")
      task.spawn(doComboAsync)
    else
      print("[ABA AFK] OFF")
    end
  end
end)

local indicator = Drawing.new("Text")
indicator.Text = "[ ABA OFF ]"
indicator.Size = 16
indicator.Color = Color3.fromRGB(255, 92, 92)
indicator.Transparency = 1
indicator.Outline = true
indicator.Font = 1
indicator.Position = Vector2.new(16, 60)
indicator.Visible = true

spawn(function()
    while wait(0.1) do
        if running then
            indicator.Text = "[ ABA ON  ]"
            indicator.Color = Color3.fromRGB(54, 248, 87)
        else
            indicator.Text = "[ ABA OFF ]"
            indicator.Color = Color3.fromRGB(255, 92, 92)
        end
    end
end)

print("[ABA AFK] Loaded. Press Y to toggle.")
