local tempV = workspace:FindFirstChild("TempV")
if tempV then
    while true do
        local parts = {}
        for _, c in pairs(tempV:GetDescendants()) do
            if c:IsA("BasePart") then
                parts[#parts + 1] = c.Name .. " " .. tostring(c.Position)
            end
        end
        print("Parts in TempV: " .. #parts)
        for i = 1, #parts do
            print("  " .. parts[i])
        end
        task.wait(2)
    end
end
