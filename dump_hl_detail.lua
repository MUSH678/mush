printl("=== MAP CITY (Full) ===")
local mapCity = workspace:FindFirstChild("Map City")
if mapCity then
    local function dump(v, d)
        d = d or 0
        local pad = string.rep("  ", d)
        for _, c in ipairs(v:GetChildren()) do
            local extra = ""
            if c:IsA("BasePart") or c:IsA("MeshPart") or c:IsA("Part") then
                extra = " POS=" .. tostring(c.Position)
                if c:FindFirstChildWhichIsA("TouchTransmitter") then extra = extra .. " [TOUCH]" end
            end
            if c:IsA("ProximityPrompt") then extra = extra .. " [Prompt] " .. tostring(c.ActionText) end
            if c:IsA("RemoteEvent") then extra = extra .. " [RE]" end
            if c:IsA("Script") then extra = extra .. " [Script]" end
            if c:IsA("Folder") then extra = extra .. " [Folder]" end
            if c:IsA("Model") then extra = extra .. " [Model]" end
            if d == 0 then printl("") end
            printl(pad .. c.Name .. " (" .. c.ClassName .. ")" .. extra)
            local children = c:GetChildren()
            if #children > 0 and d < 3 then dump(c, d + 1) end
        end
    end
    dump(mapCity, 0)
else
    printl("NOT FOUND")
end

printl("")
printl("=== ITEMS ===")
local items = workspace:FindFirstChild("Items")
if items then
    for _, v in ipairs(items:GetChildren()) do
        local extra = ""
        if v:IsA("BasePart") or v:IsA("MeshPart") then extra = " POS=" .. tostring(v.Position) end
        printl(v.Name .. " (" .. v.ClassName .. ")" .. extra)
        for _, c in ipairs(v:GetChildren()) do
            local e2 = ""
            if c:IsA("BasePart") then e2 = " POS=" .. tostring(c.Position) end
            if c:IsA("ProximityPrompt") then e2 = " [Prompt] " .. tostring(c.ActionText) end
            if c:IsA("TouchTransmitter") then e2 = " [TOUCH]" end
            if c:IsA("Script") then e2 = " [Script]" end
            if c:IsA("RemoteEvent") then e2 = " [RE]" end
            printl("  " .. c.Name .. " (" .. c.ClassName .. ")" .. e2)
        end
    end
end

printl("")
printl("=== LOBBY ===")
local lobby = workspace:FindFirstChild("Lobby")
if lobby then
    for _, v in ipairs(lobby:GetChildren()) do
        local extra = ""
        if v:IsA("BasePart") then extra = " POS=" .. tostring(v.Position) end
        if v:IsA("ProximityPrompt") then extra = " [Prompt] " .. tostring(v.ActionText) end
        printl(v.Name .. " (" .. v.ClassName .. ")" .. extra)
    end
end

printl("")
printl("=== CHARACTERS ===")
local chars = workspace:FindFirstChild("Characters")
if chars then
    for _, v in ipairs(chars:GetChildren()) do
        printl(v.Name .. " (" .. v.ClassName .. ")")
        for _, c in ipairs(v:GetChildren()) do
            if c:IsA("Part") or c:IsA("MeshPart") or c:IsA("Accessory") or c:IsA("Tool") or c:IsA("Script") then
                printl("  " .. c.Name .. " (" .. c.ClassName .. ")")
            end
        end
    end
end

printl("")
printl("=== SETUP ===")
local setup = workspace:FindFirstChild("Setup")
if setup then
    for _, v in ipairs(setup:GetChildren()) do
        local extra = ""
        if v:IsA("Script") then extra = " [Script]" end
        if v:IsA("RemoteEvent") then extra = " [RE]" end
        if v:IsA("RemoteFunction") then extra = " [RF]" end
        if v:IsA("Folder") then extra = " [Folder]" end
        if v:IsA("StringValue") then extra = " = " .. tostring(v.Value) end
        if v:IsA("ObjectValue") then extra = " -> " .. tostring(v.Value) end
        printl(v.Name .. " (" .. v.ClassName .. ")" .. extra)
        for _, c in ipairs(v:GetChildren()) do
            local e2 = ""
            if c:IsA("RemoteEvent") then e2 = " [RE]" end
            if c:IsA("Script") then e2 = " [Script]" end
            if c:IsA("StringValue") then e2 = " = " .. tostring(c.Value) end
            if c:IsA("ObjectValue") then e2 = " -> " .. tostring(c.Value) end
            if c:IsA("Folder") then e2 = " [Folder]" end
            printl("  " .. c.Name .. " (" .. c.ClassName .. ")" .. e2)
        end
    end
end

printl("")
printl("=== PLAYER TEAMS ===")
for _, t in ipairs(game:GetService("Teams"):GetChildren()) do
    printl(t.Name .. " Color=" .. tostring(t.TeamColor))
end

printl("")
printl("=== REMOTES (all) ===")
for _, v in ipairs(workspace:GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("BindableEvent") or v:IsA("BindableFunction") then
        printl(v:GetFullName() .. " (" .. v.ClassName .. ")")
    end
end

printl("")
printl("=== DUMP END ===")
