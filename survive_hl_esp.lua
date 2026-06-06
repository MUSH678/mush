-- TempV Item Finder - สแกนทั้ง Workspace

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- หาชื่อ Part ทั้งหมดใน TempV
local tempV = workspace:FindFirstChild("TempV")
local targetNames = {}
if tempV then
    for _, c in pairs(tempV:GetDescendants()) do
        if c:IsA("BasePart") then
            targetNames[c.Name] = true
            print("Target: " .. c.Name)
        end
    end
end
print("Total target names: " .. #targetNames)

local espList = {}

RunService.RenderStepped:Connect(function()
    -- สแกน workspace หา Part ที่ชื่อตรงกับ TempV
    local seen = {}
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and targetNames[part.Name] then
            seen[part] = true
            if not espList[part] then
                local box = Drawing.new("Square")
                box.Color = Color3.new(0, 1, 1)
                box.Thickness = 2
                box.Filled = false
                box.Visible = false
                local text = Drawing.new("Text")
                text.Color = Color3.new(0, 1, 1)
                text.Size = 14
                text.Center = true
                text.Outline = true
                text.Visible = false
                espList[part] = {box = box, text = text}
            end
            local esp = espList[part]
            local ok, screenPos, onScreen = pcall(function()
                return WorldToScreen(part.Position)
            end)
            if ok and screenPos and onScreen then
                local boxW = 60
                local boxH = 60
                esp.box.Position = Vector2.new(screenPos.X - boxW / 2, screenPos.Y - boxH / 2)
                esp.box.Size = Vector2.new(boxW, boxH)
                esp.box.Visible = true
                esp.text.Position = Vector2.new(screenPos.X, screenPos.Y + boxH / 2 + 4)
                esp.text.Text = part.Name
                esp.text.Visible = true
            else
                esp.box.Visible = false
                esp.text.Visible = false
            end
        end
    end
    for obj, esp in pairs(espList) do
        if not seen[obj] then
            esp.box:Remove()
            esp.text:Remove()
            espList[obj] = nil
        end
    end
end)
