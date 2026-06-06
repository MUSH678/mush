printl("--- Lemon Stand Purchases ---")
for _, v in ipairs(workspace.Tycoon1.Purchases["Lemon Stand"]:GetChildren()) do
    for _, c in ipairs(v:GetChildren()) do
        printl(v.Name .. " > " .. c.Name .. " (" .. c.ClassName .. ")")
    end
end

printl("--- CashDrops ---")
for _, v in ipairs(workspace.CashDrops:GetChildren()) do
    printl(v.Name .. " (" .. v.ClassName .. ")")
    for _, c in ipairs(v:GetChildren()) do
        printl("  " .. c.Name .. " (" .. c.ClassName .. ")")
    end
end

printl("--- Trees ---")
for _, v in ipairs(workspace.Tycoon1.Constant.Trees:GetChildren()) do
    printl(v.Name .. " (" .. v.ClassName .. ")")
    for _, c in ipairs(v:GetChildren()) do
        printl("  " .. c.Name .. " (" .. c.ClassName .. ")")
    end
end

printl("--- Locations ---")
for _, v in ipairs(workspace.Locations:GetChildren()) do
    pcall(function() printl(v.Name .. " " .. tostring(v.Position)) end)
end

printl("--- Sewer DoorsGreen ---")
for _, v in ipairs(workspace.Map.Sewer.DoorsGreen:GetChildren()) do
    printl(v.Name .. " (" .. v.ClassName .. ")")
    for _, c in ipairs(v:GetChildren()) do
        printl("  " .. c.Name .. " (" .. c.ClassName .. ")")
    end
end

printl("--- Sewer CashVine ---")
for _, v in ipairs(workspace.Map.Sewer.CashVine:GetChildren()) do
    printl(v.Name .. " (" .. v.ClassName .. ")")
end

printl("--- Tycoon1.Remotes ---")
for _, v in ipairs(workspace.Tycoon1.Remotes:GetChildren()) do
    printl(v.Name .. " (" .. v.ClassName .. ")")
end

printl("--- Tycoon1.Values ---")
for _, v in ipairs(workspace.Tycoon1.Values:GetChildren()) do
    printl(v.Name .. " (" .. v.ClassName .. ")")
end
