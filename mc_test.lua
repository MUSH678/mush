-- Model Click Checker (Matcha LuaVM)
-- คลิกซ้ายที่ object เพื่อดูชื่อ + path

local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local function formatPath(instance)
    local path = instance.Name
    local parent = instance.Parent
    while parent and parent ~= game do
        path = parent.Name .. "." .. path
        parent = parent.Parent
    end
    return path
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
            print("Click check failed: " .. tostring(result))
        end
    end
end)

print("Model Checker loaded - click any object to inspect")
