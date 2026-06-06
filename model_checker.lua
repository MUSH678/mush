-- Model Click Checker (Matcha LuaVM)
-- กดเมาส์ค้าง 0.5 วิ เพื่อ inspect object ที่เล็งอยู่

local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local debounce = false

local function formatPath(instance)
    local path = instance.Name
    local parent = instance.Parent
    while parent and parent ~= game do
        path = parent.Name .. "." .. path
        parent = parent.Parent
    end
    return path
end

local function checkClick()
    if debounce then return end
    if ismouse1pressed() then
        debounce = true
        local mousePos = UserInputService:GetMouseLocation()
        local ok, result = pcall(function()
            local unitRay = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
            local ray = Ray.new(unitRay.Origin, unitRay.Direction * 1000)
            local hit, pos = workspace:FindPartOnRay(ray)
            if hit then
                print("=== Clicked ===")
                print("Name: " .. hit.Name)
                print("Class: " .. hit.ClassName)
                print("Path: " .. formatPath(hit))
                if hit:IsA("BasePart") then
                    print("Pos: " .. tostring(hit.Position))
                end
                print("================")
            end
        end)
        if not ok then
            print("Check failed: " .. tostring(result))
        end
        task.wait(0.5)
        debounce = false
    end
end

RunService = game:GetService("RunService")
RunService.RenderStepped:Connect(checkClick)

print("Model Checker loaded - hold mouse to inspect")
