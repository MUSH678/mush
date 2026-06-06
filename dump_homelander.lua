printl("=== [A-TRAIN] Survive Homelander DEEP DUMP ===")
local ws = workspace

local function dumpInst(v, depth)
    depth = depth or 0
    local pad = string.rep("  ", depth)
    local extra = ""
    if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("Part") then
        extra = " POS=" .. tostring(v.Position)
        if v:FindFirstChildWhichIsA("TouchTransmitter") then extra = extra .. " [TOUCH]" end
    end
    if v:IsA("Script") then extra = extra .. " [Script]" end
    if v:IsA("LocalScript") then extra = extra .. " [LocalScript]" end
    if v:IsA("RemoteEvent") then extra = extra .. " [RE]" end
    if v:IsA("RemoteFunction") then extra = extra .. " [RF]" end
    if v:IsA("ProximityPrompt") then extra = extra .. " [Prompt] " .. tostring(v.ActionText) end
    if v:IsA("BoolValue") then extra = extra .. " = " .. tostring(v.Value) end
    if v:IsA("NumberValue") then extra = extra .. " = " .. tostring(v.Value) end
    if v:IsA("StringValue") then extra = extra .. " = " .. tostring(v.Value) end
    if v:IsA("ObjectValue") then extra = extra .. " -> " .. tostring(v.Value) end
    if v:IsA("Folder") then extra = extra .. " [Folder]" end
    if v:IsA("Model") then extra = extra .. " [Model]" end
    if v:IsA("Attachment") then extra = extra .. " [Attach]" end
    if v:IsA("BillboardGui") then extra = extra .. " [BBGui]" end
    if v:IsA("SurfaceAppearance") then extra = extra .. " [Surface]" end
    printl(pad .. v.Name .. " (" .. v.ClassName .. ")" .. extra)
end

local function dumpDeep(folder, maxD, curD)
    curD = curD or 0
    if maxD and curD > maxD then return end
    for _, v in ipairs(folder:GetChildren()) do
        dumpInst(v, curD)
        if v:IsA("Model") or v:IsA("Folder") then
            if #v:GetChildren() > 0 then dumpDeep(v, maxD, curD + 1) end
        end
    end
end

-- Top level
printl("\n=== TOP LEVEL WORKSPACE ===")
for _, v in ipairs(ws:GetChildren()) do
    dumpInst(v, 0)
end

-- Look for specific folders/objects
local targets = {"HidingSpot", "hiding", "Hide", "Phone", "Collectible", "collect", "Item", "item", "Objective", "objective", "Spawn", "spawn", "Door", "door", "Vent", "vent", "Locker", "locker", "Closet", "closet", "Escape", "escape", "Tool", "tool", "Key", "key", "Evidence", "evidence", "Camera", "camera", "Computer", "computer"}
printl("\n=== SEARCHING KEY OBJECTS ===")
for _, name in ipairs(targets) do
    for _, v in ipairs(ws:GetDescendants()) do
        if v.Name:lower():find(name:lower()) and (v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("Part") or v:IsA("Model") or v:IsA("Folder")) then
            local pos = ""
            if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("Part") then pos = " POS=" .. tostring(v.Position) end
            printl(v:GetFullName() .. " (" .. v.ClassName .. ")" .. pos)
        end
    end
end

-- Player-related
printl("\n=== PLAYERS ===")
for _, p in ipairs(game:GetService("Players"):GetChildren()) do
    printl(p.Name .. " userId=" .. tostring(p.UserId) .. " Team=" .. tostring(p.TeamColor or "none"))
    local char = p.Character
    if char then
        for _, c in ipairs(char:GetChildren()) do
            if c:IsA("Tool") or c:IsA("Folder") or c:IsA("Model") or c:IsA("StringValue") or c:IsA("BoolValue") then
                printl("  " .. c.Name .. " (" .. c.ClassName .. ")")
            end
        end
    end
end

-- Lighting / services
printl("\n=== TEAMS ===")
for _, t in ipairs(game:GetService("Teams"):GetChildren()) do
    printl(t.Name .. " Color=" .. tostring(t.TeamColor))
end

printl("\n=== DUMP COMPLETE ===")
