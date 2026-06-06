printl("=== WORKSPACE DEEP DUMP ===")
local ws = workspace

-- Helper
local function dumpInstance(v, indent)
    indent = indent or 0
    local pad = string.rep("  ", indent)
    local extra = ""
    if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("Part") then
        extra = " POS=" .. tostring(v.Position)
        if v:IsA("Part") and v.Shape == Enum.PartType.Ball then extra = extra .. " (Ball)" end
    end
    if v:IsA("Script") then extra = extra .. " [Script] " .. tostring(v.Disabled and "Disabled" or "Enabled") end
    if v:IsA("LocalScript") then extra = extra .. " [LocalScript]" end
    if v:IsA("RemoteEvent") then extra = extra .. " [RemoteEvent]" end
    if v:IsA("RemoteFunction") then extra = extra .. " [RemoteFunction]" end
    if v:IsA("TouchTransmitter") then extra = extra .. " [TouchTransmitter]" end
    if v:IsA("ProximityPrompt") then extra = extra .. " [ProximityPrompt] HoldDuration=" .. tostring(v.HoldDuration) .. " ActionText=" .. tostring(v.ActionText) end
    if v:IsA("Attachment") then extra = extra .. " [Attachment]" end
    if v:IsA("Sound") then extra = extra .. " [Sound]" end
    if v:IsA("BoolValue") then extra = extra .. " = " .. tostring(v.Value) end
    if v:IsA("NumberValue") then extra = extra .. " = " .. tostring(v.Value) end
    if v:IsA("StringValue") then extra = extra .. " = " .. tostring(v.Value) end
    if v:IsA("IntValue") then extra = extra .. " = " .. tostring(v.Value) end
    if v:IsA("Vector3Value") then extra = extra .. " = " .. tostring(v.Value) end
    if v:IsA("CFrameValue") then extra = extra .. " = " .. tostring(v.Value) end
    if v:IsA("ObjectValue") then extra = extra .. " -> " .. tostring(v.Value) end
    if v:IsA("Model") then extra = extra .. " [Model]" end
    if v:IsA("Folder") then extra = extra .. " [Folder]" end
    if v:IsA("SurfaceAppearance") then extra = extra .. " [SurfaceAppearance]" end
    if v:IsA("Decal") or v:IsA("Texture") then extra = extra .. " [Texture]" end
    if v:IsA("BillboardGui") then extra = extra .. " [BillboardGui]" end
    if v:IsA("Part") and v:FindFirstChildWhichIsA("TouchTransmitter") then extra = extra .. " <HAS TOUCH>" end
    printl(pad .. v.Name .. " (" .. v.ClassName .. ")" .. extra)
end

local function dumpFolder(folder, maxDepth, currentDepth)
    currentDepth = currentDepth or 0
    if maxDepth and currentDepth > maxDepth then return end
    for _, v in ipairs(folder:GetChildren()) do
        dumpInstance(v, currentDepth)
        if v:IsA("Model") or v:IsA("Folder") or v:IsA("Part") or v:IsA("MeshPart") then
            if #v:GetChildren() > 0 then
                dumpFolder(v, maxDepth, currentDepth + 1)
            end
        end
    end
end

-- Structure / Stages - detailed
local structure = ws:FindFirstChild("Structure")
if structure then
    printl("=== STRUCTURE (Stages) ===")
    for _, v in ipairs(structure:GetChildren()) do
        printl("")
        printl("--- " .. v.Name .. " ---")
        dumpFolder(v, 3)
    end
end

-- Checkpoints
local checkpoints = ws:FindFirstChild("Checkpoints")
if checkpoints then
    printl("")
    printl("=== CHECKPOINTS ===")
    dumpFolder(checkpoints, 3)
end

-- Keycaps detailed
local keycaps = ws:FindFirstChild("Keycaps")
if keycaps then
    printl("")
    printl("=== KEYCAPS ===")
    local count = 0
    for _, v in ipairs(keycaps:GetChildren()) do
        count = count + 1
        if count <= 5 then
            printl("--- " .. v.Name .. " ---")
            dumpFolder(v, 2)
        end
    end
    printl("... total children: " .. tostring(#keycaps:GetChildren()))
end

-- Treadmill detailed
local treadmill = ws:FindFirstChild("Treadmill")
if treadmill then
    printl("")
    printl("=== TREADMILL ===")
    for _, v in ipairs(treadmill:GetChildren()) do
        printl("--- " .. v.Name .. " ---")
        dumpFolder(v, 2)
    end
end

-- Awards
local awards = ws:FindFirstChild("Awards")
if awards then
    printl("")
    printl("=== AWARDS ===")
    dumpFolder(awards, 3)
end

-- Events
local events = ws:FindFirstChild("Events")
if events then
    printl("")
    printl("=== EVENTS ===")
    dumpFolder(events, 3)
end

-- Lava
local lava = ws:FindFirstChild("Lava")
if lava then
    printl("")
    printl("=== LAVA ===")
    dumpFolder(lava, 3)
end

-- ReviveZone
local revive = ws:FindFirstChild("ReviveZone")
if revive then
    printl("")
    printl("=== REVIVEZONE ===")
    dumpFolder(revive, 3)
end

-- Boards&Gamepass
local boards = ws:FindFirstChild("Boards&Gamepass")
if boards then
    printl("")
    printl("=== BOARDS&GAMEPASS ===")
    dumpFolder(boards, 3)
end

-- Spawn locations
printl("")
printl("=== SPAWN LOCATIONS ===")
for _, v in ipairs(ws:GetChildren()) do
    if v:IsA("BasePart") or v:IsA("Part") or v:IsA("MeshPart") then
        if v.Name:lower():find("spawn") then
            printl(v.Name .. " POS=" .. tostring(v.Position))
        end
    end
end

-- Look for Part with spawn-ish names anywhere
printl("")
printl("=== ANY Spawn/Start Parts ===")
for _, v in ipairs(ws:GetDescendants()) do
    local lname = v.Name:lower()
    if (v:IsA("Part") or v:IsA("MeshPart")) and (lname:find("spawn") or lname:find("start") or lname:find("hub") or lname:find("lobby")) then
        printl(v:GetFullName() .. " POS=" .. tostring(v.Position))
    end
end

-- Look for RemoteEvents/RemoteFunctions anywhere
printl("")
printl("=== REMOTES (important) ===")
for _, v in ipairs(ws:GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("BindableEvent") or v:IsA("BindableFunction") then
        printl(v:GetFullName() .. " (" .. v.ClassName .. ")")
    end
end

printl("")
printl("=== DUMP COMPLETE ===")
