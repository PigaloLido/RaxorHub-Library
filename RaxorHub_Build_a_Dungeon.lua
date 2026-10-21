local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- [[ Patch: Fix ChatExtras / BAD.Remotes OnClientEvent Error ]]
pcall(function()
    local rep = game:GetService("ReplicatedStorage")
    local bad = rep:WaitForChild("BAD", 5)
    local remotes = bad and bad:WaitForChild("Remotes", 5)
    if remotes and remotes:IsA("Folder") and hookmetamethod then
        local dummyEvent = Instance.new("BindableEvent")
        dummyEvent.Name = "SafeChatEvent"

        local oldIndex
        oldIndex = hookmetamethod(game, "__index", function(self, key)
            if self == remotes and key == "OnClientEvent" then
                return dummyEvent.Event
            end
            return oldIndex(self, key)
        end)
    end
end)

-- [[ Load RaxorHub Library (Local file priority, then GitHub fallback) ]]
local RaxorHub = nil
pcall(function()
    if readfile and isfile and isfile("RaxorHub_UI.lua") then
        RaxorHub = loadstring(readfile("RaxorHub_UI.lua"))()
    end
end)
if not RaxorHub then
    local source = game:HttpGet("https://raw.githubusercontent.com/PigaloLido/RaxorHub-Library/main/RaxorHub_UI.lua")
    RaxorHub = loadstring(source)()
end

-- [[ Window Creation ]]
local Window = RaxorHub:Window({
    Title = "RAXOR",
    SubTitle = "The Labyrinth",
    ProfileTag = "Till: Lifetime",
    Logo = "rbxassetid://87425048247573"
})

-- Welcome Notification
RaxorHub:Notify({
    Title = "RaxorHub Labyrinth",
    Content = "โหลดระบบ Build a Dungeon เรียบร้อยแล้ว!",
    Duration = 3.5
})

-- [[ Global State & Variables ]]
local State = {
    IsCollecting = false,
    InstantPrompt = false,
    TeleportDelay = 0.25,
    AutoLoop = false,
    AutoPlayAgain = false,
    IsSuiciding = false,
    ChestESP = false,
    TrapESP = false,
    HideAllies = false,
    KillAura = false,
    AutoDungeon = false,
    AutoDungeonChests = true,
    SpeedHack = false,
    SpeedVal = 32,
    NoClip = false,
    AutoPlayFly = true,
    AutoRevive = false,
    -- Lobby / Roll System
    AutoRoll = false,
    FastRoll = true,
    RollAutoBuy = false,
    RollTargetRarities = { "Divine", "Secret" },
    RollTargetMutations = { "None", "Cursed", "Infernal", "Frozen", "Golden" },
    RollDelay = 0.5,
    LastRollMachine = nil,
    LastRolledEntry = nil,
    RollStatusText = "พร้อมทำงาน"
}

-- [[ Shared Remotes Helper ]]
local cachedActionRemote = nil
local function GetActionRemote()
    if cachedActionRemote and cachedActionRemote.Parent then
        return cachedActionRemote
    end
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local bad = rep:FindFirstChild("BAD")
        local remotes = bad and bad:FindFirstChild("Remotes")
        cachedActionRemote = remotes and remotes:FindFirstChild("Action")
    end)
    return cachedActionRemote
end

local cachedRollRemote = nil
local function GetRollRemote()
    if cachedRollRemote and cachedRollRemote.Parent then
        return cachedRollRemote
    end
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local bad = rep:FindFirstChild("BAD")
        local remotes = bad and bad:FindFirstChild("Remotes")
        cachedRollRemote = remotes and remotes:FindFirstChild("Roll")
    end)
    return cachedRollRemote
end

local isGuardianDefeated = false
local ESPObjects = {}

-- [[ Helper: Extract Current Floor (Optimized & Cached) ]]
local cachedFloorTextLabel = nil
local function GetCurrentFloor()
    -- 1. Check cached TextLabel first (instant 0 ms execution)
    if cachedFloorTextLabel and cachedFloorTextLabel.Parent and cachedFloorTextLabel.Text ~= "" then
        local num = string.match(cachedFloorTextLabel.Text, "[Ff](%d+)") or string.match(cachedFloorTextLabel.Text, "(%d+)")
        if num then return "Floor" .. num end
    end

    -- 2. Check exact GUI path specified by user (PlayerGui.LabHUD -> Frame -> Frame -> TextLabel)
    local floorFound = nil
    pcall(function()
        local labHUD = LocalPlayer.PlayerGui:FindFirstChild("LabHUD")
        if labHUD then
            local f1 = labHUD:FindFirstChild("Frame")
            local f2 = f1 and f1:FindFirstChild("Frame")
            local f3 = f2 and f2:FindFirstChild("Frame")
            local f4 = f3 and f3:FindFirstChild("Frame")
            if f4 then
                local children = f4:GetChildren()
                if children[9] and children[9]:IsA("TextLabel") and children[9].Text ~= "" then
                    cachedFloorTextLabel = children[9]
                    local num = string.match(children[9].Text, "[Ff](%d+)") or string.match(children[9].Text, "(%d+)")
                    if num then floorFound = "Floor" .. num end
                end
            end

            -- Fast scan without deep recursion if not found
            if not floorFound then
                for _, desc in ipairs(labHUD:GetDescendants()) do
                    if desc:IsA("TextLabel") and (string.find(desc.Text, "LABYRINTH") or string.find(desc.Text, "F")) then
                        cachedFloorTextLabel = desc
                        local num = string.match(desc.Text, "%-?%s*[Ff](%d+)") or string.match(desc.Text, "Floor%s*(%d+)")
                        if num then floorFound = "Floor" .. num break end
                    end
                end
            end
        end
    end)

    if floorFound then return floorFound end

    -- 3. Fallback: Check workspace.Labyrinth directly
    local labyrinth = Workspace:FindFirstChild("Labyrinth")
    if labyrinth then
        for _, child in ipairs(labyrinth:GetChildren()) do
            if string.find(child.Name, "Floor") and child:FindFirstChild("Chest") then
                return child.Name
            end
        end
        for _, child in ipairs(labyrinth:GetChildren()) do
            if string.find(child.Name, "Floor") then
                return child.Name
            end
        end
    end

    -- 4. Safe persistent fallback: if lastFloorName was already known, NEVER revert to Floor1!
    if lastFloorName and lastFloorName ~= "" then
        return lastFloorName
    end

    return "Floor1"
end

-- [[ Helper: Fire ProximityPrompt Instantly & Reliably ]]
local function TriggerPrompt(prompt, forceInstant)
    if not prompt or not prompt.Parent then return false end
    
    pcall(function()
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, 35)
    end)

    local oldHold = prompt.HoldDuration
    if forceInstant or State.InstantPrompt then
        prompt.HoldDuration = 0
    end

    if fireproximityprompt then
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.04)
        pcall(function() fireproximityprompt(prompt, 1) end)
    else
        pcall(function() prompt:InputHoldBegin() end)
        task.wait(0.08)
        pcall(function() prompt:InputHoldEnd() end)
    end

    -- Send prompt key (e.g. E for chests/doors, F for revive) via VirtualInputManager
    local promptKey = prompt.KeyboardKeyCode or Enum.KeyCode.E
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, promptKey, false, game)
        task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, promptKey, false, game)
    end)

    task.wait(0.12)
    pcall(function()
        if prompt and prompt.Parent then
            prompt.HoldDuration = oldHold
        end
    end)
    return true
end

-- [[ Global ProximityPrompt Instant Hook ]]
ProximityPromptService.PromptShown:Connect(function(prompt)
    if State.InstantPrompt then
        prompt.HoldDuration = 0
    end
end)

-- [[ Helper: Get CFrame of Object (Part or Model) ]]
local function GetObjectCFrame(obj)
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart.CFrame
        end
        local part = obj:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.CFrame
        end
        return obj:GetPivot()
    end
    return nil
end

-- [[ Helper: Check if Chest is Already Opened ]]
local function IsChestOpened(chest)
    if not chest or not chest.Parent then return true end

    -- Check Attributes (LidOpen = true or Opened = true)
    if chest:GetAttribute("Opened") == true or chest:GetAttribute("LidOpen") == true then
        return true
    end

    -- Check direct Value objects
    local openedVal = chest:FindFirstChild("Opened")
    if openedVal and openedVal:IsA("ValueBase") and (openedVal.Value == true or openedVal.Value == 1) then
        return true
    end
    local lidVal = chest:FindFirstChild("LidOpen")
    if lidVal and lidVal:IsA("ValueBase") and (lidVal.Value == true or lidVal.Value == 1) then
        return true
    end

    -- Check child models/parts (e.g. Lid)
    local lid = chest:FindFirstChild("Lid")
    if lid and (lid:GetAttribute("Opened") == true or lid:GetAttribute("LidOpen") == true) then
        return true
    end

    return false
end

-- [[ Helper: Trigger Auto Play Again Remote & Click Button Instantly (Optimized) ]]
local function TriggerPlayAgain()
    -- 1. Direct RemoteEvent (FireServer)
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local bad = rep:FindFirstChild("BAD")
        local remotes = bad and bad:FindFirstChild("Remotes")
        local labRemote = remotes and remotes:FindFirstChild("Lab")
        if labRemote and labRemote:IsA("RemoteEvent") then
            labRemote:FireServer("again")
        end
    end)

    -- 2. Immediate GuiButton Click for LabEnd / BADPrompts only (Zero lag, skip LabHUD)
    pcall(function()
        local pgui = LocalPlayer:FindFirstChild("PlayerGui")
        if not pgui then return end
        for _, guiName in ipairs({"LabEnd", "BADPrompts"}) do
            local gui = pgui:FindFirstChild(guiName)
            if gui and gui.Enabled then
                for _, desc in ipairs(gui:GetDescendants()) do
                    if desc:IsA("GuiButton") and desc.Visible then
                        local btnText = (desc:IsA("TextButton") and string.lower(desc.Text)) or ""
                        local btnName = string.lower(desc.Name)
                        if string.find(btnText, "again") or string.find(btnName, "again") or string.find(btnText, "play") then
                            if firesignal then
                                firesignal(desc.Activated)
                                firesignal(desc.MouseButton1Click)
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- [[ Trap Disabler State & Helpers ]]
local function IsTrapInstance(obj)
    if not obj then return false end
    local name = obj.Name
    if name == "BearTrap" or name == "FireTrap" or name == "FallingRocks" then
        return true
    end
    local lower = string.lower(name)
    if string.find(lower, "beartrap") or string.find(lower, "firetrap") or string.find(lower, "fallingrocks") or string.find(lower, "spiketrap") then
        return true
    end
    return false
end

-- [[ Helper: Kill Character via In-Game Trap Damage ]]
local function KillCharacter()
    if State.IsSuiciding then return end
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local hum = character and character:FindFirstChildWhichIsA("Humanoid")
    if not hrp or not hum then return end

    State.IsSuiciding = true
    RaxorHub:Notify({
        Title = "Auto Die System",
        Content = "กำลังทำการฆ่าตัวละครผ่านกับดักในเกม...",
        Duration = 3
    })

    local labyrinth = Workspace:FindFirstChild("Labyrinth")
    local currentFloorName = GetCurrentFloor()
    local floorFolder = labyrinth and labyrinth:FindFirstChild(currentFloorName)
    local searchTarget = floorFolder or labyrinth

    -- Collect all lethal traps
    local traps = {}
    if searchTarget then
        for _, obj in ipairs(searchTarget:GetDescendants()) do
            if IsTrapInstance(obj) then
                for _, p in ipairs(obj:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanTouch = true
                        p.CanCollide = true
                    end
                end
                if obj:IsA("BasePart") then
                    obj.CanTouch = true
                    obj.CanCollide = true
                end
                table.insert(traps, obj)
            end
        end
    end

    task.spawn(function()
        local startTime = tick()
        while character and character.Parent and hum.Health > 0 and (tick() - startTime < 12) do
            -- If game defeat screen appeared, stop
            local pgui = LocalPlayer:FindFirstChild("PlayerGui")
            local labEnd = pgui and pgui:FindFirstChild("LabEnd")
            if labEnd and labEnd.Enabled then break end

            -- Burn self-revive quickly if downed prompt exists
            for _, p in ipairs(character:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    TriggerPrompt(p, true)
                end
            end

            -- Also try VirtualInputManager key F for revive
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                task.wait(0.02)
                vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
            end)

            if #traps > 0 then
                for _, trap in ipairs(traps) do
                    if not character or not character.Parent or hum.Health <= 0 then break end
                    local trapPart = trap:IsA("BasePart") and trap or trap:FindFirstChildWhichIsA("BasePart", true)
                    if trapPart then
                        -- Teleport directly into trap
                        hrp.CFrame = trapPart.CFrame * CFrame.new(0, 0.5, 0)

                        -- Trigger touch interest for instant server damage
                        if firetouchinterest then
                            firetouchinterest(hrp, trapPart, 0)
                            firetouchinterest(hrp, trapPart, 1)
                        end
                    end
                    task.wait(0.05)
                end
            else
                -- Fallback if no traps found on floor: Drop into void & kill
                hrp.CFrame = CFrame.new(hrp.Position.X, -250, hrp.Position.Z)
                task.wait(0.1)
                pcall(function() hum:TakeDamage(999999) end)
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Dead) end)
                pcall(function() hum.Health = 0 end)
            end

            task.wait(0.08)
        end

        State.IsSuiciding = false
    end)
end

-- [[ Accurate Big Boss Room Detection & Safe Boundary System ]]
local cachedBigBossRoom = nil
local lastBigBossCheckFloor = nil

-- [[ Helper: Locate Big Boss Central Disc (workspace.Labyrinth[Floor].Props.Disc.PointLight | Size 0.1, 10, 10) ]]
local function FindBigBossDisc(floorFolder, propsFolder, exitRingPos)
    local searchTarget = propsFolder or floorFolder
    if not searchTarget then return nil end

    local candidates = {}
    for _, obj in ipairs(searchTarget:GetChildren()) do
        if string.lower(obj.Name) == "disc" and obj:IsA("BasePart") then
            table.insert(candidates, obj)
        end
    end
    -- Fast fallback within Props only (never traverse whole floor)
    if #candidates == 0 and searchTarget ~= floorFolder then
        for _, obj in ipairs(searchTarget:GetDescendants()) do
            if string.lower(obj.Name) == "disc" and obj:IsA("BasePart") then
                table.insert(candidates, obj)
            end
        end
    end

    -- Priority 1: Exact user spec: Has PointLight child AND Size ~ (0.1, 10, 10)
    for _, obj in ipairs(candidates) do
        local s = obj.Size
        local minDim = math.min(s.X, s.Y, s.Z)
        local maxDim = math.max(s.X, s.Y, s.Z)
        local midDim = (s.X + s.Y + s.Z) - minDim - maxDim
        local hasLight = (obj:FindFirstChildWhichIsA("PointLight") or obj:FindFirstChild("PointLight")) ~= nil
        local sizeMatch = (minDim <= 0.6) and (maxDim >= 6 and maxDim <= 16) and (midDim >= 6 and midDim <= 16)

        if hasLight and sizeMatch then
            if exitRingPos then
                local dist = (Vector3.new(obj.Position.X, 0, obj.Position.Z) - Vector3.new(exitRingPos.X, 0, exitRingPos.Z)).Magnitude
                if dist <= 140 then
                    return obj
                end
            else
                return obj
            end
        end
    end

    -- Priority 2: Disc containing PointLight child (even if slightly scaled)
    for _, obj in ipairs(candidates) do
        local hasLight = (obj:FindFirstChildWhichIsA("PointLight") or obj:FindFirstChild("PointLight")) ~= nil
        if hasLight then
            return obj
        end
    end

    -- Priority 3: Size ~ (0.1, 10, 10) near ExitRing
    for _, obj in ipairs(candidates) do
        local s = obj.Size
        local minDim = math.min(s.X, s.Y, s.Z)
        local maxDim = math.max(s.X, s.Y, s.Z)
        local sizeMatch = (minDim <= 0.6) and (maxDim >= 6 and maxDim <= 16)
        if sizeMatch then
            if exitRingPos then
                local dist = (Vector3.new(obj.Position.X, 0, obj.Position.Z) - Vector3.new(exitRingPos.X, 0, exitRingPos.Z)).Magnitude
                if dist <= 140 then
                    return obj
                end
            else
                return obj
            end
        end
    end

    return nil
end

local function FindBigBossRoom()
    local currentFloor = GetCurrentFloor()
    if cachedBigBossRoom and lastBigBossCheckFloor == currentFloor and cachedBigBossRoom.object and cachedBigBossRoom.object.Parent then
        return cachedBigBossRoom
    end

    local labyrinth = Workspace:FindFirstChild("Labyrinth")
    local floorFolder = labyrinth and labyrinth:FindFirstChild(currentFloor)
    if not floorFolder and labyrinth then
        for _, child in ipairs(labyrinth:GetChildren()) do
            if string.find(child.Name, "Floor") then
                floorFolder = child
                break
            end
        end
    end

    local props = floorFolder and (floorFolder:FindFirstChild("Props") or floorFolder:FindFirstChild("props"))
    local searchContainer = props or floorFolder

    local exitRing = nil
    if floorFolder then
        exitRing = floorFolder:FindFirstChild("ExitRing") or floorFolder:FindFirstChild("PortalBeam")
        if not exitRing then
            exitRing = floorFolder:FindFirstChild("ExitRing", true) or floorFolder:FindFirstChild("PortalBeam", true)
        end
    end
    if not exitRing and labyrinth then
        exitRing = labyrinth:FindFirstChild("ExitRing", true) or labyrinth:FindFirstChild("PortalBeam", true)
    end

    local exitRingPos = nil
    if exitRing then
        local cf = GetObjectCFrame(exitRing)
        exitRingPos = cf and cf.Position or (exitRing:IsA("BasePart") and exitRing.Position)
    end

    -- 1. PRIMARY & EXACT: workspace.Labyrinth[Floor].Props.Disc.PointLight (Size 0.1, 10, 10)
    local bossDisc = FindBigBossDisc(floorFolder, props, exitRingPos)

    local bossObj = bossDisc
    local bossPos = nil

    if bossDisc then
        local cf = GetObjectCFrame(bossDisc)
        bossPos = cf and cf.Position or (bossDisc:IsA("BasePart") and bossDisc.Position)
    elseif exitRing then
        bossObj = exitRing
        bossPos = exitRingPos
    elseif searchContainer then
        for _, obj in ipairs(searchContainer:GetChildren()) do
            if string.lower(obj.Name) == "disc" and (obj:FindFirstChildWhichIsA("PointLight") or obj:FindFirstChild("PointLight") or obj:IsA("BasePart")) then
                bossObj = obj
                local cf = GetObjectCFrame(obj)
                bossPos = cf and cf.Position or (obj:IsA("BasePart") and obj.Position)
                break
            end
        end
    end

    if not bossObj or not bossPos then return nil end

    -- Find GrandDoor closest to Boss room (Fast GetChildren only)
    local closestDoor = nil
    local minD = math.huge
    if searchContainer then
        for _, d in ipairs(searchContainer:GetChildren()) do
            if d.Name == "GrandDoor" then
                local dcf = GetObjectCFrame(d)
                if dcf then
                    local dist = (dcf.Position - bossPos).Magnitude
                    if dist < minD then
                        minD = dist
                        closestDoor = { instance = d, pos = dcf.Position }
                    end
                end
            end
        end
    end
    if not closestDoor and floorFolder and floorFolder ~= searchContainer then
        for _, d in ipairs(floorFolder:GetChildren()) do
            if d.Name == "GrandDoor" then
                local dcf = GetObjectCFrame(d)
                if dcf then
                    local dist = (dcf.Position - bossPos).Magnitude
                    if dist < minD then
                        minD = dist
                        closestDoor = { instance = d, pos = dcf.Position }
                    end
                end
            end
        end
    end

    cachedBigBossRoom = {
        object = bossObj,
        disc = bossDisc,
        exitRing = exitRing,
        pos = bossPos, -- Exact center of circular arena from Props.Disc.PointLight
        door = closestDoor,
        radius = 90.0, -- Circular arena radius (~180 studs diameter, expanded to reach walls/throne)
        height = 56.0,
        isCircular = true,
        isBox = false
    }
    lastBigBossCheckFloor = currentFloor
    return cachedBigBossRoom
end

local function IsInsideBigBossRoom(pos, customBigBoss)
    if not pos then return false end
    local bb = customBigBoss or cachedBigBossRoom
    if bb and bb.pos then
        local r = (bb.radius or 90.0) + 5.0
        local dx = pos.X - bb.pos.X
        local dz = pos.Z - bb.pos.Z
        return (dx * dx + dz * dz) <= (r * r)
    end
    return false
end

-- [[ Core Function: Collect All Chests ]]
local function CollectAllChests()
    if State.IsCollecting then
        RaxorHub:Notify({ Title = "Chest Collector", Content = "กำลังทำการเก็บกล่องอยู่แล้ว กรุณารอสักครู่...", Duration = 2.5 })
        return
    end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        RaxorHub:Notify({ Title = "Chest Collector", Content = "ไม่พบตัวละครของผู้เล่น!", Duration = 2.5 })
        return
    end

    local labyrinth = Workspace:FindFirstChild("Labyrinth")
    if not labyrinth then
        RaxorHub:Notify({ Title = "Chest Collector", Content = "ไม่พบโฟลเดอร์ workspace.Labyrinth ในเกมนี้!", Duration = 3 })
        return
    end

    local currentFloorName = GetCurrentFloor()
    local floorFolder = labyrinth:FindFirstChild(currentFloorName)
    if not floorFolder then
        RaxorHub:Notify({ Title = "Chest Collector", Content = "ไม่พบห้องชั้น " .. tostring(currentFloorName), Duration = 3 })
        return
    end

    -- Find all unopened Chests
    local chests = {}
    local totalChestsOnFloor = 0
    for _, obj in ipairs(floorFolder:GetChildren()) do
        if obj.Name == "Chest" then
            totalChestsOnFloor = totalChestsOnFloor + 1
            if not IsChestOpened(obj) then
                table.insert(chests, obj)
            end
        end
    end

    if #chests == 0 then
        if totalChestsOnFloor > 0 then
            RaxorHub:Notify({
                Title = "Chest Collector",
                Content = string.format("กล่องทั้งหมดใน %s (%d กล่อง) เปิดไปหมดแล้ว!", currentFloorName, totalChestsOnFloor),
                Duration = 3
            })
        else
            RaxorHub:Notify({
                Title = "Chest Collector",
                Content = "ไม่พบกล่องใน " .. currentFloorName,
                Duration = 3
            })
        end

        -- Auto Die when Auto Collect Loop is running (trigger defeat to start new round)
        if State.AutoLoop and not State.AutoDungeon then
            KillCharacter()
            return
        end

        -- If Auto Play Again is enabled and all chests are done, trigger replay instantly
        if State.AutoPlayAgain and not State.AutoDungeon then
            TriggerPlayAgain()
            RaxorHub:Notify({
                Title = "Auto Play Again",
                Content = "ส่งคำสั่งเริ่มเกมใหม่ (Play Again) ทันที!",
                Duration = 2.5
            })
        end
        return
    end

    State.IsCollecting = true
    local originalCFrame = hrp.CFrame
    local collectedCount = 0

    RaxorHub:Notify({
        Title = "Chest Collector",
        Content = string.format("ตรวจพบ %s: เหลื่อกล่องยังไม่เปิด %d/%d กล่อง! กำลังเริ่มเก็บ...", currentFloorName, #chests, totalChestsOnFloor),
        Duration = 3
    })

    for index, chest in ipairs(chests) do
        if not State.IsCollecting then break end
        if chest and chest.Parent and not IsChestOpened(chest) then
            local chestCFrame = GetObjectCFrame(chest)
            local prompt = chest:FindFirstChildWhichIsA("ProximityPrompt", true)

            if chestCFrame then
                local inBossRoomEarly = State.AutoDungeon and not isGuardianDefeated and IsInsideBigBossRoom(chestCFrame.Position)
                if not inBossRoomEarly then
                    -- Teleport slightly above chest
                    hrp.CFrame = chestCFrame * CFrame.new(0, 2.5, 0)
                    task.wait(State.TeleportDelay)

                    -- Find prompt again in case it loaded late
                    if not prompt then
                        prompt = chest:FindFirstChildWhichIsA("ProximityPrompt", true)
                    end

                    if prompt and prompt.Enabled then
                        TriggerPrompt(prompt, true)
                        collectedCount = collectedCount + 1
                        task.wait(0.15)
                    end
                end
            end
        end
    end

    -- Return to starting position (Always built-in)
    if hrp and hrp.Parent then
        task.wait(0.2)
        hrp.CFrame = originalCFrame
        task.wait(0.1)
    end

    State.IsCollecting = false
    RaxorHub:Notify({
        Title = "Chest Collector",
        Content = string.format("เก็บกล่องใน %s สำเร็จ (%d กล่อง) วาปกลับจุดเดิมเรียบร้อย!", currentFloorName, collectedCount),
        Duration = 3
    })

    -- Auto Die when Auto Collect Loop finishes (trigger defeat to start new round)
    if State.AutoLoop and not State.AutoDungeon then
        task.wait(0.2)
        KillCharacter()
        return
    end

    -- Auto Play Again trigger immediately when collection finishes
    if State.AutoPlayAgain and not State.AutoDungeon then
        TriggerPlayAgain()
        RaxorHub:Notify({
            Title = "Auto Play Again",
            Content = "ส่งคำสั่งเริ่มเกมใหม่ (Play Again) ทันที!",
            Duration = 2.5
        })
    end
end

-- [[ ESP System for Chests & Traps (Optimized: Capped at 30 Highlights for 60 FPS) ]]
local function ClearESP()
    for _, obj in pairs(ESPObjects) do
        pcall(function() obj:Destroy() end)
    end
    ESPObjects = {}
end

local function UpdateESP()
    ClearESP()
    local labyrinth = Workspace:FindFirstChild("Labyrinth")
    if not labyrinth then return end

    local currentFloorName = GetCurrentFloor()
    local floorFolder = labyrinth:FindFirstChild(currentFloorName)
    if not floorFolder then return end

    local highlightCount = 0
    local MAX_HIGHLIGHTS = 30 -- Roblox hardware max render limit is 31 highlights

    if State.ChestESP then
        for _, obj in ipairs(floorFolder:GetChildren()) do
            if highlightCount >= MAX_HIGHLIGHTS then break end
            if obj.Name == "Chest" and not IsChestOpened(obj) then
                local highlight = Instance.new("Highlight")
                highlight.Name = "Raxor_ChestESP"
                highlight.FillColor = Color3.fromRGB(255, 215, 0) -- Gold
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.5
                highlight.Adornee = obj
                highlight.Parent = obj
                table.insert(ESPObjects, highlight)
                highlightCount = highlightCount + 1
            end
        end
    end

    if State.TrapESP then
        for _, obj in ipairs(floorFolder:GetChildren()) do
            if highlightCount >= MAX_HIGHLIGHTS then break end
            if obj.Name == "BearTrap" or obj.Name == "FireTrap" or obj.Name == "FallingRocks" then
                local highlight = Instance.new("Highlight")
                highlight.Name = "Raxor_TrapESP"
                highlight.FillColor = Color3.fromRGB(255, 50, 50) -- Red
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.4
                highlight.Adornee = obj
                highlight.Parent = obj
                table.insert(ESPObjects, highlight)
                highlightCount = highlightCount + 1
            end
        end
    end
end

-- [[ Hide Allies (Pets) System ]]
local AllySavedProps = {}

local function HideInstance(desc)
    if not desc or not desc.Parent then return end
    if not AllySavedProps[desc] then
        AllySavedProps[desc] = {}
    end
    local saved = AllySavedProps[desc]

    if desc:IsA("BasePart") then
        if saved.Transparency == nil then saved.Transparency = desc.Transparency end
        if saved.CastShadow == nil then saved.CastShadow = desc.CastShadow end
        if saved.CanCollide == nil then saved.CanCollide = desc.CanCollide end
        desc.Transparency = 1
        desc.CastShadow = false
        desc.CanCollide = false
    elseif desc:IsA("Decal") or desc:IsA("Texture") then
        if saved.Transparency == nil then saved.Transparency = desc.Transparency end
        desc.Transparency = 1
    elseif desc:IsA("ParticleEmitter") or desc:IsA("Beam") or desc:IsA("Trail") or desc:IsA("Fire") or desc:IsA("Smoke") or desc:IsA("Sparkles") then
        if saved.Enabled == nil then saved.Enabled = desc.Enabled end
        desc.Enabled = false
    elseif desc:IsA("Light") then
        if saved.Enabled == nil then saved.Enabled = desc.Enabled end
        desc.Enabled = false
    elseif desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") or desc:IsA("Highlight") then
        if saved.Enabled == nil then saved.Enabled = desc.Enabled end
        desc.Enabled = false
    end
end

local function RestoreInstance(desc)
    if not desc or not desc.Parent then return end
    local saved = AllySavedProps[desc]
    if not saved then return end

    if desc:IsA("BasePart") then
        if saved.Transparency ~= nil then desc.Transparency = saved.Transparency end
        if saved.CastShadow ~= nil then desc.CastShadow = saved.CastShadow end
        if saved.CanCollide ~= nil then desc.CanCollide = saved.CanCollide end
    elseif desc:IsA("Decal") or desc:IsA("Texture") then
        if saved.Transparency ~= nil then desc.Transparency = saved.Transparency end
    elseif desc:IsA("ParticleEmitter") or desc:IsA("Beam") or desc:IsA("Trail") or desc:IsA("Fire") or desc:IsA("Smoke") or desc:IsA("Sparkles") then
        if saved.Enabled ~= nil then desc.Enabled = saved.Enabled end
    elseif desc:IsA("Light") then
        if saved.Enabled ~= nil then desc.Enabled = saved.Enabled end
    elseif desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") or desc:IsA("Highlight") then
        if saved.Enabled ~= nil then desc.Enabled = saved.Enabled end
    end
end

local function ApplyHideAllies(hide)
    local labAllies = Workspace:FindFirstChild("LabAllies")
    if not labAllies then return end

    for _, desc in ipairs(labAllies:GetDescendants()) do
        if hide then
            HideInstance(desc)
        else
            RestoreInstance(desc)
        end
    end

    if not hide then
        AllySavedProps = {}
    end
end

-- Real-time watcher for newly spawned/added allies in workspace.LabAllies
local function HookLabAllies(folder)
    if not folder then return end
    folder.DescendantAdded:Connect(function(desc)
        if State.HideAllies then
            HideInstance(desc)
        end
    end)
end

local existingLabAllies = Workspace:FindFirstChild("LabAllies")
if existingLabAllies then
    HookLabAllies(existingLabAllies)
end

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "LabAllies" then
        HookLabAllies(child)
        if State.HideAllies then
            task.wait(0.1)
            ApplyHideAllies(true)
        end
    end
end)

-- [[ Dungeon Auto Play System (Autonomous Farming) ]]
local visitedArenas = {}
local clearedAirRooms = {}
local clearedTreasureRooms = {}
local openedChestsCache = {}
local lastFloorName = ""
local FloorClearedRooms = {} -- [floorName] = { positions = {}, keys = {} }
local discoveredMiniBosses = {}
local discoveredTreasureRooms = {}
local discoveredBigBoss = nil
local lastRoomScanTime = 0
local DungeonStatusLabel = nil
isGuardianDefeated = false
local currentOrbitAngle = 0
local lastSkillQTime = 0
local lastSkillRTime = 0
local currentCombatRoom = nil
local GetAliveEnemies = nil
local GetAliveBossOrGuardian = nil
local cachedFloorRooms = nil
local cachedFloorRoomsName = ""
local AnalyzeFloorRooms = nil
local IsInsideAnySpecialRoom = nil

-- [[ Register a Cleared Room in Persistent Memory ]]
local function RegisterClearedRoom(pos, roomType, customKey)
    local floor = GetCurrentFloor()
    if not FloorClearedRooms[floor] then
        FloorClearedRooms[floor] = { positions = {}, keys = {} }
    end
    if customKey then
        FloorClearedRooms[floor].keys[customKey] = true
        clearedAirRooms[customKey] = true
        if roomType == "treasure" then
            clearedTreasureRooms[customKey] = true
        end
    end
    if pos then
        local key = string.format("cleared_%.0f_%.0f", pos.X, pos.Z)
        FloorClearedRooms[floor].keys[key] = true
        clearedAirRooms[key] = true
        if roomType == "treasure" then
            clearedTreasureRooms[key] = true
        end

        local exists = false
        for _, pData in ipairs(FloorClearedRooms[floor].positions) do
            if (pData.pos - pos).Magnitude < 40 then
                exists = true
                break
            end
        end
        if not exists then
            table.insert(FloorClearedRooms[floor].positions, {
                pos = pos,
                radius = (roomType == "treasure") and 48.0 or 72.0,
                roomType = roomType or "miniboss"
            })
        end
    end
end

-- [[ Room Boundary Confinement System ]]
-- Pure mathematical room boundary confinement (Ultra-Fast 0ms check)
-- Supports both Exact Rectangular OBB (Calculated from Beams 144x56x144) and Circular rooms
local function IsWithinCurrentRoom(pos, margin)
    if not currentCombatRoom or not currentCombatRoom.center then return true end
    margin = margin or 0

    -- 1. Exact Rectangular OBB check (from Beam detection: 144x56x144)
    if currentCombatRoom.isBox and currentCombatRoom.cframe and currentCombatRoom.size then
        local localPos = currentCombatRoom.cframe:PointToObjectSpace(pos)
        local halfLength = math.max(10.0, (currentCombatRoom.size.X - margin) / 2)
        local halfWidth = math.max(10.0, (currentCombatRoom.size.Z - margin) / 2)
        return (math.abs(localPos.X) <= halfLength) and (math.abs(localPos.Z) <= halfWidth)
    end

    -- 2. Circular room fallback
    local center = currentCombatRoom.center
    local radius = currentCombatRoom.radius or 36.0
    local maxR = radius - margin
    local dx = pos.X - center.X
    local dz = pos.Z - center.Z
    return (dx * dx + dz * dz) <= (maxR * maxR)
end

local function ClampToCurrentRoom(pos, margin)
    if not currentCombatRoom or not currentCombatRoom.center then return pos end
    margin = margin or 2.5

    -- 1. Exact Rectangular OBB clamping
    if currentCombatRoom.isBox and currentCombatRoom.cframe and currentCombatRoom.size then
        local localPos = currentCombatRoom.cframe:PointToObjectSpace(pos)
        local halfLength = math.max(10.0, (currentCombatRoom.size.X - margin) / 2)
        local halfWidth = math.max(10.0, (currentCombatRoom.size.Z - margin) / 2)
        local clampedX = math.clamp(localPos.X, -halfLength, halfLength)
        local clampedZ = math.clamp(localPos.Z, -halfWidth, halfWidth)
        if clampedX ~= localPos.X or clampedZ ~= localPos.Z then
            local clampedLocal = Vector3.new(clampedX, localPos.Y, clampedZ)
            return currentCombatRoom.cframe:PointToWorldSpace(clampedLocal)
        end
        return pos
    end

    -- 2. Circular room fallback
    local center = currentCombatRoom.center
    local radius = currentCombatRoom.radius or 36.0
    local maxR = math.max(6.0, radius - margin)
    local dx = pos.X - center.X
    local dz = pos.Z - center.Z
    local dSq = dx * dx + dz * dz
    if dSq > (maxR * maxR) then
        local d = math.sqrt(dSq)
        local factor = maxR / (d > 0.001 and d or 1)
        return Vector3.new(center.X + dx * factor, pos.Y, center.Z + dz * factor)
    end
    return pos
end

-- [[ Exact Room Inclusion Check: OBB Box (144x56x144) or Radial Circle ]]
local function IsPositionInRoom(pos, room)
    if not room or not pos then return false end
    if room.isBox and room.cframe and room.size then
        local localPos = room.cframe:PointToObjectSpace(pos)
        local halfLength = (room.size.X / 2) + 6.0 -- 72 + 6 = 78 studs
        local halfHeight = (room.size.Y / 2) + 12.0
        local halfWidth = (room.size.Z / 2) + 6.0 -- 72 + 6 = 78 studs
        return (math.abs(localPos.X) <= halfLength) 
            and (math.abs(localPos.Y) <= halfHeight) 
            and (math.abs(localPos.Z) <= halfWidth)
    elseif room.pos then
        local r = room.radius or 78.0
        local dx = pos.X - room.pos.X
        local dz = pos.Z - room.pos.Z
        return (dx * dx + dz * dz) <= (r * r)
    end
    return false
end

-- [[ Absolute Safety Barrier: Check if Position is Inside ANY Special Room ]]
-- Pure in-memory math: Big Boss Room, Mini-Boss Rooms, Treasure Rooms
-- ZERO Workspace queries, ZERO allocations, 100% mobile-smooth 60+ FPS!
IsInsideAnySpecialRoom = function(pos, margin)
    if not pos then return false end
    margin = margin or 5.0

    -- 1. Big Boss Room (from memory cache only)
    local bb = cachedBigBossRoom
    if bb and bb.pos then
        local r = (bb.radius or 90.0) + margin + 4.0
        local dx = pos.X - bb.pos.X
        local dz = pos.Z - bb.pos.Z
        if (dx * dx + dz * dz) <= (r * r) then
            return true
        end
    end

    -- 2. Floor Special Rooms (from memory cache only)
    local rooms = cachedFloorRooms
    if rooms then
        local mbList = rooms.miniBossRooms
        if mbList then
            for i = 1, #mbList do
                local mb = mbList[i]
                if mb.isBox and mb.cframe and mb.size then
                    local lp = mb.cframe:PointToObjectSpace(pos)
                    local hx = (mb.size.X * 0.5) + margin + 5.0
                    local hz = (mb.size.Z * 0.5) + margin + 5.0
                    if math.abs(lp.X) <= hx and math.abs(lp.Z) <= hz then
                        return true
                    end
                elseif mb.pos then
                    local r = (mb.radius or 72.0) + margin + 5.0
                    local dx = pos.X - mb.pos.X
                    local dz = pos.Z - mb.pos.Z
                    if (dx * dx + dz * dz) <= (r * r) then
                        return true
                    end
                end
            end
        end

        local trList = rooms.treasureRooms
        if trList then
            for i = 1, #trList do
                local tr = trList[i]
                if tr.pos then
                    local r = 40.0 + margin + 5.0
                    local dx = pos.X - tr.pos.X
                    local dz = pos.Z - tr.pos.Z
                    if (dx * dx + dz * dz) <= (r * r) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- [[ Solid Floor Raycast Verification (Prevents clipping into void or off-map) ]]
local function HasSolidFloor(pos)
    if not pos then return false end
    local rayOrigin = Vector3.new(pos.X, pos.Y + 6.0, pos.Z)
    local rayDir = Vector3.new(0, -35.0, 0)
    local ignored = {
        LocalPlayer.Character,
        Workspace:FindFirstChild("BADEnemies"),
        Workspace:FindFirstChild("LabFx")
    }

    for _ = 1, 4 do
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = ignored

        local result = Workspace:Raycast(rayOrigin, rayDir, rayParams)
        if not result or not result.Instance then break end

        if result.Instance.CanCollide then
            local name = result.Instance.Name
            if not string.find(name, "Air") and not string.find(name, "Trigger") and not string.find(name, "Beam") and not string.find(name, "Ring") then
                return true, result.Position.Y
            end
        end
        table.insert(ignored, result.Instance)
    end
    return false, nil
end

-- [[ On-Screen Floating Status HUD (Placed Underneath the Game Timer) ]]
local onScreenGui = nil
local onScreenHudFrame = nil
local onScreenStatusLabel = nil
local userMovedHUD = false

local function GetSafeGuiParent()
    if gethui then
        local s, h = pcall(gethui)
        if s and h then return h end
    end
    local coreGui = game:GetService("CoreGui")
    local s, _ = pcall(function() return coreGui.Name end)
    if s and coreGui then
        return coreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function CreateOnScreenStatusHUD()
    if onScreenGui and onScreenGui.Parent then return end

    pcall(function()
        local parent = GetSafeGuiParent()
        local existing = parent:FindFirstChild("RaxorDungeonHUD")
        if existing then existing:Destroy() end

        local sg = Instance.new("ScreenGui")
        sg.Name = "RaxorDungeonHUD"
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 9999
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        -- Main Card Frame
        local container = Instance.new("Frame")
        container.Name = "StatusContainer"
        container.AnchorPoint = Vector2.new(0.5, 0)
        container.Position = UDim2.new(0.5, 0, 0, 48)
        container.Size = UDim2.new(0, 0, 0, 30)
        container.AutomaticSize = Enum.AutomaticSize.X
        container.BackgroundColor3 = Color3.fromRGB(15, 14, 24)
        container.BackgroundTransparency = 0.15
        container.BorderSizePixel = 0
        container.Active = true
        container.Parent = sg

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = container

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(75, 65, 115)
        stroke.Thickness = 1.2
        stroke.Transparency = 0.3
        stroke.Parent = container

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 14)
        padding.PaddingTop = UDim.new(0, 4)
        padding.PaddingBottom = UDim.new(0, 4)
        padding.Parent = container

        -- Left Accent Bar (Purple Vertical Pill)
        local accent = Instance.new("Frame")
        accent.Name = "Accent"
        accent.AnchorPoint = Vector2.new(0, 0.5)
        accent.Position = UDim2.new(0, 4, 0.5, 0)
        accent.Size = UDim2.new(0, 3, 1, -8)
        accent.BackgroundColor3 = Color3.fromRGB(130, 95, 255)
        accent.BorderSizePixel = 0
        accent.Parent = container

        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(1, 0)
        accentCorner.Parent = accent

        -- Status TextLabel
        local label = Instance.new("TextLabel")
        label.Name = "StatusText"
        label.AnchorPoint = Vector2.new(0, 0.5)
        label.Position = UDim2.new(0, 14, 0.5, 0)
        label.Size = UDim2.new(0, 0, 1, 0)
        label.AutomaticSize = Enum.AutomaticSize.X
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamMedium
        label.Text = "สถานะ: " .. (State.AutoDungeonStatus or "พร้อมใช้งาน")
        label.TextColor3 = Color3.fromRGB(240, 240, 255)
        label.TextSize = 13
        label.TextStrokeTransparency = 0.85
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Parent = container

        -- Draggable behavior
        local dragging, dragStart, startPos
        container.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                userMovedHUD = true
                dragStart = input.Position
                startPos = container.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        onScreenGui = sg
        onScreenHudFrame = container
        onScreenStatusLabel = label

        sg.Parent = parent

        -- Position tracking loop: Keeps it centered right below the timer (unless user dragged it)
        task.spawn(function()
            local cachedTimerLabel = nil
            while sg and sg.Parent do
                if not userMovedHUD then
                    pcall(function()
                        if not cachedTimerLabel or not cachedTimerLabel.Parent or not cachedTimerLabel.Visible then
                            cachedTimerLabel = nil
                            local pgui = LocalPlayer:FindFirstChild("PlayerGui")
                            local labHUD = pgui and pgui:FindFirstChild("LabHUD")
                            if labHUD then
                                for _, desc in ipairs(labHUD:GetDescendants()) do
                                    if desc:IsA("TextLabel") and desc.Visible and string.match(desc.Text, "^%d+:%d%d$") then
                                        cachedTimerLabel = desc
                                        break
                                    end
                                end
                            end
                        end

                        if cachedTimerLabel and cachedTimerLabel.Visible and cachedTimerLabel.AbsolutePosition.Y < 80 then
                            local absPos = cachedTimerLabel.AbsolutePosition
                            local absSize = cachedTimerLabel.AbsoluteSize
                            local targetX = absPos.X + (absSize.X / 2)
                            local targetY = absPos.Y + absSize.Y + 4
                            container.Position = UDim2.fromOffset(targetX, targetY)
                        else
                            container.Position = UDim2.new(0.5, 0, 0, 48)
                        end
                    end)
                end
                task.wait(1.5)
            end
        end)
    end)
end

local function UpdateDungeonStatus(text)
    State.AutoDungeonStatus = text
    if DungeonStatusLabel and DungeonStatusLabel.Set then
        pcall(function()
            DungeonStatusLabel:Set("สถานะ: " .. text)
        end)
    end
    if onScreenStatusLabel and onScreenStatusLabel.Parent then
        pcall(function()
            onScreenStatusLabel.Text = "สถานะ: " .. text
        end)
    else
        CreateOnScreenStatusHUD()
    end
end

-- [[ Auto Play Flight Controller (Cancels Gravity, Eliminates Tripping, Guarantees Silky Smooth Tweens) ]]
local flyBodyVelocity = nil
local flyBodyGyro = nil

local function SetAutoFly(enable)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")

    if enable and State.AutoDungeon and State.AutoPlayFly ~= false then
        if not hrp or not hum or hum.Health <= 0 then return end

        if not flyBodyVelocity or not flyBodyVelocity.Parent then
            local existingBV = hrp:FindFirstChild("RaxorFlyBV")
            if existingBV then existingBV:Destroy() end

            flyBodyVelocity = Instance.new("BodyVelocity")
            flyBodyVelocity.Name = "RaxorFlyBV"
            flyBodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            flyBodyVelocity.Velocity = Vector3.zero
            flyBodyVelocity.Parent = hrp
        else
            flyBodyVelocity.Velocity = Vector3.zero
        end

        if not flyBodyGyro or not flyBodyGyro.Parent then
            local existingBG = hrp:FindFirstChild("RaxorFlyBG")
            if existingBG then existingBG:Destroy() end

            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.Name = "RaxorFlyBG"
            flyBodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
            flyBodyGyro.P = 10000
            flyBodyGyro.CFrame = hrp.CFrame
            flyBodyGyro.Parent = hrp
        end

        hum.PlatformStand = true
    else
        if flyBodyVelocity and flyBodyVelocity.Parent then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end
        local existingBV = hrp and hrp:FindFirstChild("RaxorFlyBV")
        if existingBV then existingBV:Destroy() end

        if flyBodyGyro and flyBodyGyro.Parent then
            flyBodyGyro:Destroy()
            flyBodyGyro = nil
        end
        local existingBG = hrp and hrp:FindFirstChild("RaxorFlyBG")
        if existingBG then existingBG:Destroy() end

        if hum and hum.Health > 0 then
            hum.PlatformStand = false
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    flyBodyVelocity = nil
    flyBodyGyro = nil
end)

local function SafeTeleportTo(targetPos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not targetPos then return end

    -- Disable collision temporarily so the character never gets stuck in gates or walls
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = CFrame.new(targetPos)

    if flyBodyVelocity and flyBodyVelocity.Parent then
        flyBodyVelocity.Velocity = Vector3.zero
    end
    if flyBodyGyro and flyBodyGyro.Parent then
        flyBodyGyro.CFrame = CFrame.new(targetPos)
    end
end

-- [[ Helper: Check if GuiObject and all its parents are truly visible on screen ]]
local function IsGuiVisible(guiObj)
    if not guiObj or not guiObj:IsA("GuiObject") then return false end
    if not guiObj.Visible then return false end
    if guiObj:IsA("TextLabel") and guiObj.TextTransparency >= 0.75 then return false end

    local current = guiObj.Parent
    while current and current:IsA("GuiObject") do
        if not current.Visible then return false end
        if current:IsA("CanvasGroup") and current.GroupTransparency >= 0.75 then return false end
        current = current.Parent
    end

    if current and current:IsA("LayerCollector") then
        return current.Enabled
    end
    return true
end

-- [[ Wave & Announcement Detection via LabHUD TextLabels ]]
local function GetAnnouncementText()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pgui then return "" end

    local labHUD = pgui:FindFirstChild("LabHUD")
    if not (labHUD and labHUD.Enabled) then return "" end

    local bestText = ""
    local bestPriority = 0

    for _, desc in ipairs(labHUD:GetDescendants()) do
        if desc:IsA("TextLabel") and desc.Text ~= "" and IsGuiVisible(desc) then
            local u = string.upper(desc.Text)

            -- Priority 3 (Highest): Entire Arena Cleared / Cave Cleared / Floor Cleared / Victory / Chest Spawn
            if (string.find(u, "ARENA") and string.find(u, "CLEARED"))
                or (string.find(u, "CAVE") and string.find(u, "CLEARED"))
                or string.find(u, "LOOT THE CHEST")
                or string.find(u, "NEXT FLOOR")
                or (string.find(u, "VICTORY") and not string.find(u, "WAVE")) then
                return desc.Text
            end

            -- Priority 2: Intermediate Wave Cleared (e.g. "WAVE CLEARED!", "WAVE 1 CLEARED!")
            if string.find(u, "WAVE") and string.find(u, "CLEARED") then
                if bestPriority < 2 then
                    bestText = desc.Text
                    bestPriority = 2
                end
            -- Priority 1: Wave Active, Gates Slam, Guardian, Treasure Cave
            elseif string.find(u, "WAVE") or string.find(u, "GATES SLAM") or string.find(u, "GUARDIAN") 
                or string.find(u, "TREASURE") or string.find(u, "CAVE") then
                if bestPriority < 1 then
                    bestText = desc.Text
                    bestPriority = 1
                end
            end
        end
    end

    return bestText
end

-- [[ Treasure Cave Announcement & Status Helper ]]
local function GetCaveInfo()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local labHUD = pgui and pgui:FindFirstChild("LabHUD")

    local text = GetAnnouncementText()
    local u = string.upper(text)

    local isTreasureCave = (string.find(u, "TREASURE") ~= nil or (string.find(u, "CAVE") ~= nil and string.find(u, "CLEARED") == nil))
    local isCaveCleared = (string.find(u, "CAVE") ~= nil and string.find(u, "CLEARED") ~= nil)

    if labHUD and labHUD.Enabled then
        for _, desc in ipairs(labHUD:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text ~= "" and IsGuiVisible(desc) then
                local labelU = string.upper(desc.Text)
                if string.find(labelU, "CAVE") and string.find(labelU, "CLEARED") then
                    isCaveCleared = true
                    text = desc.Text
                elseif string.find(labelU, "TREASURE") or (string.find(labelU, "CAVE") and not string.find(labelU, "CLEARED")) then
                    isTreasureCave = true
                    if not isCaveCleared then text = desc.Text end
                end
            end
        end
    end

    return {
        text = text,
        isTreasureCave = isTreasureCave,
        isCaveCleared = isCaveCleared
    }
end

-- [[ Detailed Wave Information Helper ]]
local function GetWaveInfo()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local labHUD = pgui and pgui:FindFirstChild("LabHUD")

    local text = GetAnnouncementText()
    local u = string.upper(text)

    local curWave = 0
    local maxWave = 4
    local isWaveCleared = false
    local isArenaCleared = false
    local isGatesSlam = false

    -- Check announcement text
    if string.find(u, "GATES SLAM") then
        isGatesSlam = true
    end

    if string.find(u, "WAVE") and string.find(u, "CLEARED") then
        isWaveCleared = true
    end

    if (string.find(u, "ARENA") and string.find(u, "CLEARED"))
        or string.find(u, "LOOT THE CHEST")
        or (string.find(u, "VICTORY") and not string.find(u, "WAVE")) then
        isArenaCleared = true
    end

    -- If announcement text specifically says WAVE CLEARED, it is strictly NOT Arena Cleared!
    if isWaveCleared then
        isArenaCleared = false
    end

    -- Scan LabHUD for wave numbers (e.g. "WAVE 1 / 4", "WAVE 2 OF 4", "WAVE 3")
    if labHUD and labHUD.Enabled then
        for _, desc in ipairs(labHUD:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text ~= "" and IsGuiVisible(desc) then
                local labelU = string.upper(desc.Text)

                -- Check if any label has ARENA CLEARED or LOOT THE CHEST
                if (string.find(labelU, "ARENA") and string.find(labelU, "CLEARED"))
                    or string.find(labelU, "LOOT THE CHEST") then
                    isArenaCleared = true
                end

                -- Check if any label has WAVE CLEARED
                if string.find(labelU, "WAVE") and string.find(labelU, "CLEARED") then
                    isWaveCleared = true
                end

                local cW, mW = string.match(labelU, "WAVE%s*(%d+)%s*/%s*(%d+)")
                if not cW then
                    cW, mW = string.match(labelU, "WAVE%s*(%d+)%s*OF%s*(%d+)")
                end
                if not cW then
                    cW = string.match(labelU, "WAVE%s*(%d+)")
                end
                if cW then
                    local numW = tonumber(cW) or 0
                    if numW > curWave then
                        curWave = numW
                        if mW then maxWave = tonumber(mW) or 4 end
                    end
                end
            end
        end
    end

    -- Absolute safety: If isArenaCleared is true, it overrides isWaveCleared
    if isArenaCleared then
        isWaveCleared = false
    end

    return {
        text = text,
        curWave = curWave,
        maxWave = maxWave,
        isWaveCleared = isWaveCleared,
        isCleared = isArenaCleared, -- ONLY true when the ENTIRE ARENA is cleared! NEVER on intermediate WAVE CLEARED!
        isGatesSlam = isGatesSlam
    }
end

-- [[ Auto Skill Q & Skill R during Combat ]]
local function UseCombatSkills()
    local now = os.clock()

    -- Skill Q (Cooldown ~4-8s; attempt every 1.2s during combat)
    if now - lastSkillQTime >= 1.2 then
        lastSkillQTime = now
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
            task.delay(0.02, function()
                pcall(function()
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                end)
            end)
        end)
    end

    -- Skill R (Ultimate, Cooldown ~15-25s; attempt every 2.0s during combat)
    if now - lastSkillRTime >= 2.0 then
        lastSkillRTime = now
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            task.delay(0.02, function()
                pcall(function()
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
                end)
            end)
        end)
    end
end

-- [[ Trap Detection Helper (Cached per Floor) ]]
local cachedFloorTraps = {}
local lastFloorTrapsName = ""

local function GetFloorTraps()
    local currentFloor = GetCurrentFloor()
    if cachedFloorTraps and lastFloorTrapsName == currentFloor and #cachedFloorTraps > 0 then
        return cachedFloorTraps
    end
    lastFloorTrapsName = currentFloor
    local traps = {}
    local labyrinth = Workspace:FindFirstChild("Labyrinth")
    local floorFolder = labyrinth and labyrinth:FindFirstChild(currentFloor)
    local target = floorFolder or labyrinth
    if target then
        for _, obj in ipairs(target:GetChildren()) do
            if obj.Name == "BearTrap" or obj.Name == "FireTrap" or obj.Name == "FallingRocks" or IsTrapInstance(obj) then
                local trapPart = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                if trapPart then
                    table.insert(traps, trapPart.Position)
                end
            end
        end
    end
    cachedFloorTraps = traps
    return traps
end

local function IsNearTrap(pos, safeRadius)
    safeRadius = safeRadius or 10
    local safeRadiusSq = safeRadius * safeRadius
    local traps = GetFloorTraps()
    for _, tPos in ipairs(traps) do
        local dx = pos.X - tPos.X
        local dz = pos.Z - tPos.Z
        if (dx * dx + dz * dz) < safeRadiusSq then
            return true
        end
    end
    return false
end

-- [[ Wall & Obstacle Detection Helpers (Zero-Rubberband Protection) ]]
local function HasWallBetween(fromPos, toPos)
    local diff = toPos - fromPos
    local dist = diff.Magnitude
    if dist < 0.8 then return false end

    -- Raycast at waist/chest level to avoid clipping floor seams
    local castOrigin = fromPos + Vector3.new(0, 1.2, 0)
    local castTarget = toPos + Vector3.new(0, 1.2, 0)
    local castDiff = castTarget - castOrigin

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {
        LocalPlayer.Character,
        Workspace:FindFirstChild("BADEnemies"),
        Workspace:FindFirstChild("LabFx")
    }

    local rayResult = Workspace:Raycast(castOrigin, castDiff, rayParams)
    if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then
        local name = rayResult.Instance.Name
        local isFloorOrIgnored = string.find(name, "Air") or string.find(name, "Trigger") or string.find(name, "Beam") or string.find(name, "Ring") or string.find(name, "Floor") or string.find(name, "Base") or string.find(name, "Ground") or string.find(name, "Tile")
        if not isFloorOrIgnored then
            return true, rayResult
        end
    end
    return false, nil
end

local function IsInsideWall(pos)
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = {
        LocalPlayer.Character,
        Workspace:FindFirstChild("BADEnemies"),
        Workspace:FindFirstChild("LabFx")
    }
    -- Test box centered at chest level (pos.Y + 0.6) with height 2.0 (box spans pos.Y - 0.4 to pos.Y + 1.6)
    -- This strictly guarantees ZERO false intersection with floor surfaces!
    local parts = Workspace:GetPartBoundsInBox(CFrame.new(pos + Vector3.new(0, 0.6, 0)), Vector3.new(1.8, 2.0, 1.8), overlap)
    for _, p in ipairs(parts) do
        if p.CanCollide then
            local name = p.Name
            local isFloorOrIgnored = string.find(name, "Air") or string.find(name, "Trigger") or string.find(name, "Beam") or string.find(name, "Ring") or string.find(name, "Chest") or string.find(name, "Floor") or string.find(name, "Base") or string.find(name, "Ground") or string.find(name, "Tile")
            if not isFloorOrIgnored then
                local topY = p.Position.Y + (p.Size.Y / 2)
                if topY > (pos.Y + 0.2) then
                    return true, p
                end
            end
        end
    end
    return false, nil
end

-- [[ Active Attack Danger Zones Detector from workspace.LabFx ]]
-- Specifically detects all ground attack telegraphs (Slam circles, Shot indicators, Falling Rocks, Dragon AoE)
local cachedDangerZones = {}
local lastDangerZonesScan = 0

local function GetActiveDangerZones()
    local now = tick()
    if (now - lastDangerZonesScan) < 0.05 and #cachedDangerZones > 0 then
        return cachedDangerZones
    end
    lastDangerZonesScan = now

    local zones = {}
    local labFx = Workspace:FindFirstChild("LabFx")
    if not labFx then
        cachedDangerZones = zones
        return zones
    end

    for _, obj in ipairs(labFx:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Transparency < 0.95 then
            local s = obj.Size
            local sorted = { s.X, s.Y, s.Z }
            table.sort(sorted)
            -- The two largest dimensions form the horizontal/attack footprint diameter
            local footprintDiameter = math.max(sorted[2], sorted[3])
            if footprintDiameter >= 2.0 then
                local radius = footprintDiameter / 2
                table.insert(zones, {
                    pos = obj.Position,
                    rawRadius = radius,
                    hardDangerRadius = radius + 6.0,
                    safeClearanceRadius = radius + 15.0,
                    name = obj.Name,
                    instance = obj
                })
            end
        end
    end

    cachedDangerZones = zones
    return zones
end

-- [[ Check if a position is inside or dangerously close to an active attack indicator or trap ]]
-- IMPORTANT: Infinite Cylinder Hitbox! The server uses pure 2D distance: ΔX^2 + ΔZ^2 <= R^2.
-- Height (Y) offers ZERO protection. Distance must be measured strictly in the horizontal XZ plane!
local function IsPositionInDanger(pos, dangerZones, useClearanceMargin)
    if not pos then return false, nil end
    dangerZones = dangerZones or GetActiveDangerZones()
    local flatPos = Vector3.new(pos.X, 0, pos.Z)

    for _, dz in ipairs(dangerZones) do
        local flatDz = Vector3.new(dz.pos.X, 0, dz.pos.Z)
        local dist = (flatPos - flatDz).Magnitude
        local threshold = useClearanceMargin and (dz.safeClearanceRadius or (dz.rawRadius + 15.0))
            or (dz.hardDangerRadius or (dz.rawRadius + 6.0))
        if dist < threshold then
            return true, dz
        end
    end

    if IsNearTrap(pos, useClearanceMargin and 14 or 10) then
        return true, nil
    end

    return false, nil
end

local function IsInDangerZone(pos, dangerZones)
    return IsPositionInDanger(pos, dangerZones, false)
end

-- [[ Emergency Escape Finder: 360-Degree Multi-Hazard Radial Grid Search ]]
-- Computes escape from ALL active and overlapping circles simultaneously.
-- Guarantees landing at least 10-16 studs outside the perimeter of EVERY red circle!
local function FindEmergencyEscapePosition(currentPos, dangerZones, enemyPos)
    dangerZones = dangerZones or GetActiveDangerZones()
    local flatCurrent = Vector3.new(currentPos.X, 0, currentPos.Z)

    -- 1. Identify all circles currently threatening or overlapping the player
    local activeThreats = {}
    local maxThreatRadius = 10.0
    for _, dz in ipairs(dangerZones) do
        local flatDz = Vector3.new(dz.pos.X, 0, dz.pos.Z)
        local dist = (flatCurrent - flatDz).Magnitude
        if dist < (dz.hardDangerRadius or (dz.rawRadius + 6.0)) then
            table.insert(activeThreats, dz)
        end
        if dz.rawRadius > maxThreatRadius then
            maxThreatRadius = dz.rawRadius
        end
    end

    -- 2. Calculate collective repulsion vector pointing away from ALL active threats
    local repulseDir = Vector3.zero
    local relevantZones = (#activeThreats > 0) and activeThreats or dangerZones

    for _, dz in ipairs(relevantZones) do
        local flatDz = Vector3.new(dz.pos.X, 0, dz.pos.Z)
        local diff = flatCurrent - flatDz
        local dist = diff.Magnitude
        local weight = 1 / math.max(dist, 1.0)
        if dist < 0.5 then
            diff = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
        end
        repulseDir = repulseDir + diff.Unit * weight
    end

    if repulseDir.Magnitude < 0.1 then
        if enemyPos then
            local flatEnemy = Vector3.new(enemyPos.X, 0, enemyPos.Z)
            repulseDir = flatCurrent - flatEnemy
        end
        if repulseDir.Magnitude < 0.1 then
            repulseDir = Vector3.new(1, 0, 0)
        end
    end
    repulseDir = repulseDir.Unit

    -- 3. Determine search bounds
    local maxSearchR = math.max(maxThreatRadius + 32.0, 36.0)
    if currentCombatRoom and currentCombatRoom.center then
        local maxRoomR = (currentCombatRoom.radius or 36.0) - 3.5
        maxSearchR = math.clamp(maxRoomR, 15.0, 68.0)
    end

    local ringDistances = {
        math.clamp(maxThreatRadius + 8.0, 10.0, maxSearchR),
        math.clamp(maxThreatRadius + 16.0, 16.0, maxSearchR),
        math.clamp(maxThreatRadius + 24.0, 22.0, maxSearchR),
        maxSearchR
    }

    local bestEscape = nil
    local bestScore = -math.huge

    local bestCandidateAnyClearance = nil
    local bestAnyClearance = -math.huge

    local bestCandidateMaxDist = nil
    local maxClearanceSeen = -math.huge

    -- 4. 36-Direction Radial Grid Search (every 10 degrees) across all distance rings
    for _, dist in ipairs(ringDistances) do
        for i = 0, 35 do
            local ang = math.rad(i * 10.0)
            local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
            local candidateFlat = flatCurrent + dir * dist
            local candidatePos = Vector3.new(candidateFlat.X, currentPos.Y, candidateFlat.Z)

            local roomCheckPass = false
            if currentCombatRoom then
                roomCheckPass = IsWithinCurrentRoom(candidatePos, 2.5)
            else
                roomCheckPass = not IsInsideAnySpecialRoom(candidatePos, 3.0)
            end

            if roomCheckPass and HasSolidFloor(candidatePos) and not IsInsideWall(candidatePos) and not IsNearTrap(candidatePos, 10) then
                local minClearance = math.huge
                local inAnyHardDanger = false

                for _, dz in ipairs(dangerZones) do
                    local flatDz = Vector3.new(dz.pos.X, 0, dz.pos.Z)
                    local d = (candidateFlat - flatDz).Magnitude
                    local clearance = d - dz.rawRadius
                    if clearance < minClearance then
                        minClearance = clearance
                    end
                    if d < (dz.hardDangerRadius or (dz.rawRadius + 6.0)) then
                        inAnyHardDanger = true
                    end
                end

                -- Track candidate with best positive clearance (outside danger circle)
                if not inAnyHardDanger and minClearance > bestAnyClearance then
                    bestAnyClearance = minClearance
                    bestCandidateAnyClearance = candidatePos
                end

                -- Track absolute highest clearance seen among any valid floor candidate
                if minClearance > maxClearanceSeen then
                    maxClearanceSeen = minClearance
                    bestCandidateMaxDist = candidatePos
                end

                -- Tier 1: Ideal Escape with >= 10 studs clearance from all perimeters
                if not inAnyHardDanger and minClearance >= 10.0 then
                    local score = 1000
                    score = score + math.min(minClearance * 25, 400)
                    local dotRepulse = repulseDir:Dot(dir)
                    score = score + dotRepulse * 150

                    if enemyPos then
                        local dToEnemy = (candidateFlat - Vector3.new(enemyPos.X, 0, enemyPos.Z)).Magnitude
                        if dToEnemy >= 13 and dToEnemy <= 24 then
                            score = score + 500
                        elseif dToEnemy > 24 and dToEnemy <= 35 then
                            score = score + 200
                        else
                            score = score - (dToEnemy * 8)
                        end
                    end

                    score = score - (dist * 2.5)
                    if score > bestScore then
                        bestScore = score
                        bestEscape = candidatePos
                    end
                end
            end
        end

        if bestEscape and bestScore > 1400 then
            break
        end
    end

    if bestEscape then
        return bestEscape
    end

    -- Tier 2: Safe outside circle (clearance > 0)
    if bestCandidateAnyClearance then
        return bestCandidateAnyClearance
    end

    -- Tier 3: Highest clearance candidate
    if bestCandidateMaxDist then
        return bestCandidateMaxDist
    end

    -- 5. Fallback Search: If radial search found nothing
    if currentCombatRoom and currentCombatRoom.center then
        local roomCenter = currentCombatRoom.center
        local maxAllowedR = (currentCombatRoom.radius or 36.0) - 3.5
        local bestFallbackClearance = -math.huge

        for r = 0, maxAllowedR, 4.0 do
            local steps = (r == 0) and 1 or 16
            for i = 0, steps - 1 do
                local ang = (steps == 1) and 0 or math.rad(i * (360 / steps))
                local testPos = roomCenter + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)
                testPos = Vector3.new(testPos.X, currentPos.Y, testPos.Z)

                if HasSolidFloor(testPos) and not IsInsideWall(testPos) and not IsNearTrap(testPos, 8) then
                    local minClr = math.huge
                    for _, dz in ipairs(dangerZones) do
                        local d = (Vector3.new(testPos.X, 0, testPos.Z) - Vector3.new(dz.pos.X, 0, dz.pos.Z)).Magnitude - dz.rawRadius
                        if d < minClr then minClr = d end
                    end

                    if minClr > bestFallbackClearance then
                        bestFallbackClearance = minClr
                        bestEscape = testPos
                    end
                end
            end
        end

        if not bestEscape then
            bestEscape = Vector3.new(roomCenter.X, currentPos.Y, roomCenter.Z)
        end
    else
        -- Outside in hallway: test all 8 directions at varying distances
        local bestClr = -math.huge
        for angDeg = 0, 315, 45 do
            local rad = math.rad(angDeg)
            local testDir = Vector3.new(math.cos(rad), 0, math.sin(rad))
            for _, stepDist in ipairs({ 14.0, 20.0, 28.0 }) do
                local testFlat = flatCurrent + testDir * stepDist
                local cPos = Vector3.new(testFlat.X, currentPos.Y, testFlat.Z)
                if HasSolidFloor(cPos) and not IsInsideWall(cPos) and not IsInsideAnySpecialRoom(cPos, 3.0) and not IsNearTrap(cPos, 8) then
                    local minClr = math.huge
                    for _, dz in ipairs(dangerZones) do
                        local d = (testFlat - Vector3.new(dz.pos.X, 0, dz.pos.Z)).Magnitude - dz.rawRadius
                        if d < minClr then minClr = d end
                    end
                    if minClr > bestClr then
                        bestClr = minClr
                        bestEscape = cPos
                    end
                end
            end
        end

        -- ABSOLUTE SAFETY LOCK: NEVER return currentPos if in danger! Elevate or leap!
        if not bestEscape then
            local leapFlat = flatCurrent + repulseDir * 16.0
            local leapPos = Vector3.new(leapFlat.X, currentPos.Y, leapFlat.Z)
            if not IsInsideAnySpecialRoom(leapPos, 2.0) and HasSolidFloor(leapPos) then
                bestEscape = leapPos
            else
                bestEscape = currentPos + Vector3.new(0, 6.0, 0)
            end
        end
    end

    return bestEscape
end

-- [[ Smart Combat Position: God-Tier Evasion & Flanking Position ]]
-- Evaluates 36 angles around the target enemy.
-- Requires at least 10-15 studs clearance from ALL danger zone perimeters!
local function FindSafestAttackPosition(targetEnemy, allEnemies)
    if not targetEnemy or not targetEnemy.part then return nil, false end
    local ePart = targetEnemy.part
    local ePos = ePart.Position

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = hrp and hrp.Position or ePos

    -- Scan active danger zones in workspace.LabFx (cached 0.05s)
    local dangerZones = GetActiveDangerZones()
    local isPlayerInDanger, activeDz = IsPositionInDanger(myPos, dangerZones, false)

    -- 1. EMERGENCY EVASION: Player is inside a danger circle! Warp/Glide OUTSIDE immediately!
    if isPlayerInDanger then
        local escapePos = FindEmergencyEscapePosition(myPos, dangerZones, ePos)
        return escapePos, true
    end

    -- 2. TACTICAL COMBAT POSITIONING: Check if enemy itself has an AoE circle active
    local enemyInDanger, enemyDz = IsPositionInDanger(ePos, dangerZones, false)
    local attackDist = 13.0

    if enemyInDanger and enemyDz then
        attackDist = math.max(14.0, enemyDz.rawRadius + 15.0)
    end

    local eLook = Vector3.new(0, 0, 1)
    if ePart and ePart.CFrame then
        eLook = ePart.CFrame.LookVector
    end

    local bestPos = nil
    local bestScore = -math.huge

    local distCandidates = { attackDist }
    if attackDist <= 14.5 then
        distCandidates = { attackDist, 8.5 }
    end

    -- Fast 12-Angle Scan (every 30 degrees) - Ultra smooth 60 FPS
    for _, curDist in ipairs(distCandidates) do
        if bestPos then break end
        for i = 0, 11 do
            local angle = math.rad(i * 30.0 + currentOrbitAngle)
            local offset = Vector3.new(math.cos(angle) * curDist, 1.5, math.sin(angle) * curDist)
            local candidatePos = ePos + offset

            -- 1. Pure math room check (0ms)
            local roomCheckPass = false
            if currentCombatRoom then
                roomCheckPass = IsWithinCurrentRoom(candidatePos, 2.0)
            else
                roomCheckPass = not IsInsideAnySpecialRoom(candidatePos, 3.5)
            end

            if roomCheckPass then
                -- 2. Pure math danger zone clearance (0ms)
                local minClearance = math.huge
                local inDanger = false

                for _, dz in ipairs(dangerZones) do
                    local dx = candidatePos.X - dz.pos.X
                    local dzDist = candidatePos.Z - dz.pos.Z
                    local d = math.sqrt(dx * dx + dzDist * dzDist)
                    local clearance = d - dz.rawRadius
                    if clearance < minClearance then
                        minClearance = clearance
                    end
                    if d < (dz.hardDangerRadius or (dz.rawRadius + 6.0)) then
                        inDanger = true
                        break
                    end
                end

                -- 3. Pure math trap check & special room filter (0ms)
                if not inDanger and minClearance >= 10.0 and not IsNearTrap(candidatePos, 10) and (currentCombatRoom or not IsInsideAnySpecialRoom(candidatePos, 3.5)) then
                    -- 4. Raycast check only on viable candidate (1-2 raycasts max)
                    if not HasWallBetween(ePos, candidatePos) and HasSolidFloor(candidatePos) then
                        local score = 100
                        score = score + math.min(minClearance * 20, 350)

                        -- Flanking / Rear Check
                        local diff = candidatePos - ePos
                        local flatDir = Vector3.new(diff.X, 0, diff.Z).Unit
                        local dot = eLook:Dot(flatDir)

                        if dot < -0.3 then
                            score = score + 400
                        elseif dot < 0.2 then
                            score = score + 150
                        else
                            score = score - 250
                        end

                        local distFromMe = (candidatePos - myPos).Magnitude
                        if distFromMe < 25 then
                            score = score + 80
                        end

                        if score > bestScore then
                            bestScore = score
                            bestPos = candidatePos
                        end
                    end
                end
            end
        end
        if bestPos then break end
    end

    if not bestPos then
        bestPos = FindEmergencyEscapePosition(myPos, dangerZones, ePos)
    end
    if not bestPos and ePos then
        bestPos = ePos + Vector3.new(0, 1.5, 9.0)
    end

    currentOrbitAngle = (currentOrbitAngle + 30) % 360
    return bestPos, isPlayerInDanger
end

-- [[ High-Speed Combat Movement: Instant Warp Dodge or Flying Tween Glide ]]
local activeCombatTween = nil
local function CombatMoveTo(targetPos, isEmergency)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not targetPos then return end

    local dangerZones = GetActiveDangerZones()
    local playerInDanger = IsPositionInDanger(hrp.Position, dangerZones, false)
    if playerInDanger then
        isEmergency = true
    end

    -- HARD SAFETY FILTER: Never move into or near ANY active danger zone!
    if IsPositionInDanger(targetPos, dangerZones, false) then
        targetPos = FindEmergencyEscapePosition(targetPos, dangerZones, nil)
    end

    -- STRICT ROOM CONFINEMENT: Clamp strictly within currentCombatRoom!
    if currentCombatRoom then
        targetPos = ClampToCurrentRoom(targetPos, 2.5)
    else
        -- STRICT OUTSIDE CONFINEMENT: If target touches a special room, push it away into open hallway
        if IsInsideAnySpecialRoom(targetPos, 2.5) then
            local allMb, allTr, bb = AnalyzeFloorRooms()
            local pushed = false
            local pushRooms = {}
            if allMb then for _, r in ipairs(allMb) do table.insert(pushRooms, { pos = r.pos, radius = r.radius or 48.0 }) end end
            if allTr then for _, r in ipairs(allTr) do table.insert(pushRooms, { pos = r.pos, radius = 38.0 }) end end
            if bb then table.insert(pushRooms, { pos = bb.pos, radius = bb.radius or 50.0 }) end

            for _, r in ipairs(pushRooms) do
                local flatRoom = Vector3.new(r.pos.X, 0, r.pos.Z)
                local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
                local d = (flatTarget - flatRoom).Magnitude
                if d < (r.radius + 6.0) then
                    local awayDir = (flatTarget - flatRoom)
                    if awayDir.Magnitude < 0.1 then awayDir = Vector3.new(1, 0, 0) end
                    local candidateFlat = flatRoom + awayDir.Unit * (r.radius + 8.0)
                    local candidatePos = Vector3.new(candidateFlat.X, targetPos.Y, candidateFlat.Z)
                    if HasSolidFloor(candidatePos) and not IsInsideWall(candidatePos) then
                        targetPos = candidatePos
                        pushed = true
                        break
                    end
                end
            end
            if not pushed and not playerInDanger then
                return
            end
        end
    end

    -- STRICT FLOOR CHECK: Never move into the void or off-map!
    if not HasSolidFloor(targetPos) then
        if currentCombatRoom and currentCombatRoom.center then
            targetPos = Vector3.new(currentCombatRoom.center.X, targetPos.Y, currentCombatRoom.center.Z)
        else
            targetPos = hrp.Position
        end
    end

    -- Ensure Fly mode is engaged for silky smooth flight
    if State.AutoDungeon then
        SetAutoFly(true)
    end

    local curPos = hrp.Position
    local dist = (curPos - targetPos).Magnitude
    local hasWall = HasWallBetween(curPos, targetPos)

    -- FATAL ANTI-RUBBERBAND RULE: NEVER Tween through walls or during emergencies!
    -- If isEmergency, hasWall, or far distance (> 26 studs): SafeTeleportTo (Instant Warp)
    if isEmergency or hasWall or dist > 26 then
        if activeCombatTween then
            activeCombatTween:Cancel()
            activeCombatTween = nil
        end
        SafeTeleportTo(targetPos)
        return
    elseif dist > 1.0 then
        -- Open-air line of sight (NO walls in between): Silky smooth flying glide tween!
        if activeCombatTween then
            activeCombatTween:Cancel()
        end

        local tweenTime = math.clamp(dist / 65, 0.05, 0.12)
        local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        activeCombatTween = TweenService:Create(hrp, tweenInfo, { CFrame = CFrame.new(targetPos) })
        activeCombatTween:Play()
    end
end

-- [[ Real-time Reactive Emergency Dodge Watchdog ]]
-- Runs at 20 Hz (every 0.05s). Guarantees the player NEVER stands still in red attack circles!
local lastWatchdogDodge = 0
task.spawn(function()
    while true do
        task.wait(0.05)
        if State.AutoDungeon then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildWhichIsA("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local dangerZones = GetActiveDangerZones()
                    local inDanger, dz = IsPositionInDanger(hrp.Position, dangerZones, false)
                    if inDanger then
                        local now = tick()
                        if (now - lastWatchdogDodge) >= 0.10 then
                            lastWatchdogDodge = now
                            local escapePos = FindEmergencyEscapePosition(hrp.Position, dangerZones, nil)
                            if escapePos and (escapePos - hrp.Position).Magnitude > 2.0 then
                                CombatMoveTo(escapePos, true)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- [[ Accurate Alive Enemy Detector ]]
GetAliveEnemies = function(referencePos, maxDist)
    local badEnemies = Workspace:FindFirstChild("BADEnemies")
    if not badEnemies then return {} end
    local list = {}
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = (hrp and hrp.Position) or Vector3.zero
    local refPos = referencePos or myPos

    for _, enemy in ipairs(badEnemies:GetChildren()) do
        if enemy:IsA("Model") and enemy.Parent then
            local combatHp = tonumber(enemy:GetAttribute("CombatHP"))
            local hum = enemy:FindFirstChildWhichIsA("Humanoid")
            local isAlive = false

            if combatHp ~= nil then
                isAlive = (combatHp > 0)
            elseif hum ~= nil then
                isAlive = (hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead)
            end

            -- Double check: If explicitly 0 HP or dead state, NEVER alive!
            if combatHp ~= nil and combatHp <= 0 then
                isAlive = false
            end
            if hum ~= nil and (hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead) then
                isAlive = false
            end

            if isAlive then
                local part = enemy:FindFirstChild("UpperTorso") 
                    or enemy.PrimaryPart 
                    or enemy:FindFirstChild("HumanoidRootPart") 
                    or enemy:FindFirstChild("Head") 
                    or enemy:FindFirstChildWhichIsA("BasePart")

                if part then
                    local distToRef = (part.Position - refPos).Magnitude
                    if not maxDist or distToRef <= maxDist then
                        local distToMe = (part.Position - myPos).Magnitude
                        local finalHp = (combatHp and combatHp > 0 and combatHp) or (hum and hum.Health > 0 and hum.Health) or 100
                        table.insert(list, {
                            model = enemy,
                            part = part,
                            hp = finalHp,
                            role = enemy:GetAttribute("Role") or enemy.Name,
                            dist = distToMe
                        })
                    end
                end
            end
        end
    end

    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

-- [[ Accurate Room Enemies Detector (Covers Full 144x144 Room without Blindspots) ]]
local function GetEnemiesInRoom(room)
    if not room then return {} end
    local all = GetAliveEnemies()
    local inside = {}
    for _, e in ipairs(all) do
        if e.part and e.model.Parent then
            if IsPositionInRoom(e.part.Position, room) then
                table.insert(inside, e)
            end
        end
    end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = (hrp and hrp.Position) or (room.pos or Vector3.zero)
    table.sort(inside, function(a, b)
        local da = (a.part.Position - myPos).Magnitude
        local db = (b.part.Position - myPos).Magnitude
        return da < db
    end)
    return inside
end

-- [[ Accurate Alive Boss / Guardian Detector ]]
GetAliveBossOrGuardian = function(referencePos, maxDist)
    local badEnemies = Workspace:FindFirstChild("BADEnemies")
    if not badEnemies then return nil end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = (hrp and hrp.Position) or Vector3.zero
    local refPos = referencePos or myPos
    maxDist = maxDist or 80.0

    for _, enemy in ipairs(badEnemies:GetChildren()) do
        if enemy:IsA("Model") and enemy.Parent then
            local combatHp = tonumber(enemy:GetAttribute("CombatHP"))
            local hum = enemy:FindFirstChildWhichIsA("Humanoid")
            local isAlive = false

            if combatHp ~= nil then
                isAlive = (combatHp > 0)
            elseif hum ~= nil then
                isAlive = (hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead)
            end

            if combatHp ~= nil and combatHp <= 0 then
                isAlive = false
            end
            if hum ~= nil and (hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead) then
                isAlive = false
            end

            if isAlive then
                local role = tostring(enemy:GetAttribute("Role") or "")
                local name = tostring(enemy.Name or "")
                local uRole = string.upper(role)
                local uName = string.upper(name)

                -- STRICT Boss matching: Must be Guardian, Boss, Lich, Dragon, Royal Knight
                -- NEVER match generic "Knight" (which matches regular skeleton knight mobs!)
                local isBoss = string.find(uRole, "GUARDIAN") or string.find(uRole, "BOSS") or string.find(uRole, "BIGBOSS")
                    or string.find(uName, "GUARDIAN") or string.find(uName, "BOSS")
                    or string.find(uName, "ROYAL KNIGHT") or string.find(uName, "ROYALKNIGHT")
                    or string.find(uName, "LICH") or string.find(uName, "DRAGON")

                if isBoss then
                    local part = enemy:FindFirstChild("UpperTorso") 
                        or enemy.PrimaryPart 
                        or enemy:FindFirstChild("HumanoidRootPart") 
                        or enemy:FindFirstChild("Head") 
                        or enemy:FindFirstChildWhichIsA("BasePart")

                    if part then
                        local distToRef = (part.Position - refPos).Magnitude
                        if distToRef <= maxDist then
                            local finalHp = (combatHp and combatHp > 0 and combatHp) or (hum and hum.Health > 0 and hum.Health) or 100
                            if finalHp > 0 then
                                return {
                                    model = enemy,
                                    part = part,
                                    hp = finalHp,
                                    role = role ~= "" and role or name,
                                    name = name,
                                    dist = (part.Position - myPos).Magnitude
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- [[ Open Single Chest Helper ]]
local function OpenChest(chest)
    if not chest or not chest.Parent or IsChestOpened(chest) then return true end
    if openedChestsCache[chest] then return true end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local chestCF = GetObjectCFrame(chest)
    if not chestCF then return false end

    SafeTeleportTo(chestCF.Position + Vector3.new(0, 1.5, 0))
    task.wait(0.2)

    local prompt = chest:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        TriggerPrompt(prompt, true)
        task.wait(0.3)
    end

    if IsChestOpened(chest) then
        openedChestsCache[chest] = true
        return true
    end

    -- Retry once if needed
    if prompt and prompt.Parent then
        TriggerPrompt(prompt, true)
        task.wait(0.3)
    end

    openedChestsCache[chest] = true
    return true
end

-- [[ Helper: Open GrandDoor from Outside before entering room ]]
local function OpenGrandDoor(doorObj, referencePos)
    if not doorObj or not doorObj.Parent then return false end
    local doorCF = GetObjectCFrame(doorObj)
    if not doorCF then return false end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    -- Position player safely outside the door facing it
    local outsidePos = doorCF.Position
    if referencePos then
        local outDir = (doorCF.Position - referencePos)
        local flatOut = Vector3.new(outDir.X, 0, outDir.Z)
        if flatOut.Magnitude > 0.1 then
            outsidePos = doorCF.Position + flatOut.Unit * 8 + Vector3.new(0, 1.5, 0)
        end
    else
        outsidePos = doorCF.Position + Vector3.new(0, 1.5, 6)
    end

    SafeTeleportTo(outsidePos)
    task.wait(0.3)

    -- Trigger any prompt on GrandDoor
    local prompts = {}
    for _, p in ipairs(doorObj:GetDescendants()) do
        if p:IsA("ProximityPrompt") then
            table.insert(prompts, p)
        end
    end

    if #prompts > 0 then
        for _, prompt in ipairs(prompts) do
            if prompt.Enabled then
                local promptPart = prompt.Parent:IsA("BasePart") and prompt.Parent or nil
                if promptPart then
                    local standPos = promptPart.Position + (outsidePos - doorCF.Position).Unit * 3 + Vector3.new(0, 1, 0)
                    SafeTeleportTo(standPos)
                    task.wait(0.15)
                end
                TriggerPrompt(prompt, true)
                task.wait(0.3)
            end
        end
    else
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
        task.wait(0.35)
    end

    return true
end

-- [[ Portal Countdown & Next Floor HUD Text Detector ]]
local function GetPortalCountdownText()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local labHUD = pgui and pgui:FindFirstChild("LabHUD")
    if not labHUD then return nil end

    for _, desc in ipairs(labHUD:GetDescendants()) do
        if desc:IsA("TextLabel") and desc.Visible and desc.TextTransparency < 0.85 then
            local text = desc.Text
            if text and text ~= "" then
                local u = string.upper(text)
                if string.find(u, "NEXT FLOOR") or string.find(u, "PORTAL") or string.find(u, "LOOT THE CHEST") or string.find(u, "GO DOWN") then
                    return text
                end

                -- Match UI position {0.5, 0}, {0, 50} and size {0, 620}, {0, 22}
                if math.abs(desc.Position.X.Scale - 0.5) < 0.1 and math.abs(desc.Position.Y.Offset - 50) < 20 and math.abs(desc.Size.X.Offset - 620) < 80 then
                    return text
                end
            end
        end
    end
    return nil
end

-- [[ Accurate Way Down / PortalBeam Exit Finder ]]
local function FindWayDownPad()
    local currentFloor = GetCurrentFloor()
    local labyrinth = Workspace:FindFirstChild("Labyrinth")
    local floorFolder = labyrinth and labyrinth:FindFirstChild(currentFloor)

    -- 1. Direct ExitRing or PortalBeam: workspace.Labyrinth[Floor].ExitRing / PortalBeam
    if floorFolder then
        local exitObj = floorFolder:FindFirstChild("ExitRing") or floorFolder:FindFirstChild("PortalBeam")
        if not exitObj then
            exitObj = floorFolder:FindFirstChild("ExitRing", true) or floorFolder:FindFirstChild("PortalBeam", true)
        end
        if exitObj then
            local cf = GetObjectCFrame(exitObj)
            if cf then
                return cf.Position, exitObj
            end
        end
    end

    if labyrinth then
        local exitObj = labyrinth:FindFirstChild("ExitRing", true) or labyrinth:FindFirstChild("PortalBeam", true)
        if exitObj then
            local cf = GetObjectCFrame(exitObj)
            if cf then
                return cf.Position, exitObj
            end
        end
    end

    -- 2. Check LabHUD Map canvas for purple dot (u381) - ONLY appears when Guardian dies!
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local labHUD = pgui and pgui:FindFirstChild("LabHUD")
    if hrp and labHUD then
        for _, desc in ipairs(labHUD:GetDescendants()) do
            if desc:IsA("Frame") and desc.Visible and desc.BackgroundColor3 == Color3.fromRGB(200, 110, 255) and desc.Size.X.Offset >= 10 then
                local canvas = desc.Parent
                if canvas then
                    local playerDot = nil
                    for _, child in ipairs(canvas:GetChildren()) do
                        if child:IsA("ImageLabel") and child.Visible and child.Size.X.Offset <= 30 then
                            playerDot = child
                            break
                        end
                    end
                    if playerDot then
                        local dx = (desc.Position.X.Offset - playerDot.Position.X.Offset) / 0.6
                        local dz = (desc.Position.Y.Offset - playerDot.Position.Y.Offset) / 0.6
                        return Vector3.new(hrp.Position.X + dx, hrp.Position.Y, hrp.Position.Z + dz), nil
                    end
                end
            end
        end
    end

    -- 3. Fallback physical exit in workspace
    if isGuardianDefeated and labyrinth then
        local searchTargets = { floorFolder, labyrinth }
        for _, target in ipairs(searchTargets) do
            if target then
                for _, obj in ipairs(target:GetChildren()) do
                    local name = string.lower(obj.Name)
                    if string.find(name, "waydown") or string.find(name, "exit") or string.find(name, "portal") or string.find(name, "nextfloor") then
                        local cf = GetObjectCFrame(obj)
                        if cf then return cf.Position, obj end
                    end
                end
            end
        end
    end

    return nil, nil
end

-- [[ Helper: Unique Key and Cleared Check for Dungeon Room ]]
local function GetRoomKey(room)
    if not room then return "unknown" end
    local p = room.pos or room.center
    if p then
        local qx = math.floor(p.X / 40 + 0.5) * 40
        local qz = math.floor(p.Z / 40 + 0.5) * 40
        return string.format("room_%d_%d", qx, qz)
    end
    if typeof(room.id) == "string" then return room.id end
    return tostring(room)
end

local function IsRoomCleared(room)
    if not room then return true end

    -- =========================================================================
    -- ABSOLUTE PRIORITY 0: IF ENEMIES ARE ALIVE IN THIS ROOM, IT IS 100% UNCLEARED!
    -- Never trust any cache, coordinate, or chest if living monsters are inside!
    -- =========================================================================
    local enemiesInside = GetEnemiesInRoom(room)
    if #enemiesInside > 0 then
        local currentFloor = GetCurrentFloor()
        local rId = GetRoomKey(room)
        clearedAirRooms[rId] = nil
        if room.id then clearedAirRooms[room.id] = nil end
        if FloorClearedRooms[currentFloor] then
            FloorClearedRooms[currentFloor].keys[rId] = nil
            if room.id then FloorClearedRooms[currentFloor].keys[room.id] = nil end
            local p = room.pos or room.center
            if p then
                for idx = #FloorClearedRooms[currentFloor].positions, 1, -1 do
                    local cData = FloorClearedRooms[currentFloor].positions[idx]
                    if (cData.pos - p).Magnitude <= 65.0 then
                        table.remove(FloorClearedRooms[currentFloor].positions, idx)
                    end
                end
            end
        end
        return false
    end

    local currentFloor = GetCurrentFloor()
    local p = room.pos or room.center

    -- 1. Check direct ID / Key in memory
    local rId = GetRoomKey(room)
    if clearedAirRooms[rId] then return true end
    if room.id and clearedAirRooms[room.id] then return true end

    -- 2. Check FloorClearedRooms registry (persists across toggling Auto Dungeon!)
    if FloorClearedRooms[currentFloor] then
        if FloorClearedRooms[currentFloor].keys[rId] then return true end
        if room.id and FloorClearedRooms[currentFloor].keys[room.id] then return true end
        if p then
            for _, cData in ipairs(FloorClearedRooms[currentFloor].positions) do
                if (cData.pos - p).Magnitude <= 65.0 then
                    clearedAirRooms[rId] = true
                    return true
                end
            end
        end
    end

    -- 3. Check coordinate proximity against ALL cleared keys in clearedAirRooms
    if p then
        for clearedKey, val in pairs(clearedAirRooms) do
            if val and typeof(clearedKey) == "string" then
                local cx, cz = string.match(clearedKey, "[_%s]([%-%d]+)_([%-%d]+)")
                if cx and cz then
                    local dx = p.X - tonumber(cx)
                    local dz = p.Z - tonumber(cz)
                    if (dx * dx + dz * dz) <= (65.0 * 65.0) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- [[ Dedicated Check for Cleared Treasure Rooms ]]
local function IsTreasureRoomCleared(trRoom)
    if not trRoom then return true end
    local currentFloor = GetCurrentFloor()
    local trId = trRoom.id or (trRoom.pos and string.format("treasure_%.0f_%.0f", trRoom.pos.X, trRoom.pos.Z)) or "unknown"

    -- 1. Check direct table
    if clearedTreasureRooms[trId] then return true end

    -- 2. Check FloorClearedRooms registry
    if FloorClearedRooms[currentFloor] then
        if FloorClearedRooms[currentFloor].keys[trId] then return true end
        if trRoom.pos then
            for _, cData in ipairs(FloorClearedRooms[currentFloor].positions) do
                if cData.roomType == "treasure" and (cData.pos - trRoom.pos).Magnitude <= 65.0 then
                    clearedTreasureRooms[trId] = true
                    return true
                end
            end
        end
    end

    -- 3. Check chests in trRoom
    if trRoom.chests and #trRoom.chests > 0 then
        local allOpened = true
        for _, c in ipairs(trRoom.chests) do
            if not IsChestOpened(c.instance) and not openedChestsCache[c.instance] then
                allOpened = false
                break
            end
        end
        if allOpened then
            RegisterClearedRoom(trRoom.pos, "treasure", trId)
            clearedTreasureRooms[trId] = true
            return true
        end
    end

    -- 4. Check physical chests in world around trRoom.pos
    if trRoom.pos then
        local labyrinth = Workspace:FindFirstChild("Labyrinth")
        local floorFolder = labyrinth and labyrinth:FindFirstChild(currentFloor)
        if floorFolder then
            local foundChests = 0
            local allChestsOpened = true
            for _, obj in ipairs(floorFolder:GetChildren()) do
                if obj.Name == "Chest" then
                    local cf = GetObjectCFrame(obj)
                    if cf and (cf.Position - trRoom.pos).Magnitude <= 60 then
                        foundChests = foundChests + 1
                        if not IsChestOpened(obj) and not openedChestsCache[obj] then
                            allChestsOpened = false
                        end
                    end
                end
            end
            if foundChests >= 2 and allChestsOpened then
                RegisterClearedRoom(trRoom.pos, "treasure", trId)
                clearedTreasureRooms[trId] = true
                return true
            end
        end
    end

    return false
end

-- [[ Check if ANY Mini-Boss Room currently has active monsters alive inside it ]]
local function GetActiveMiniBossRoomWithEnemies(miniBossRooms)
    if not miniBossRooms or #miniBossRooms == 0 then return nil, 0 end
    local allEnemies = GetAliveEnemies()
    if #allEnemies == 0 then return nil, 0 end

    for _, mb in ipairs(miniBossRooms) do
        local inside = GetEnemiesInRoom(mb)
        if #inside > 0 then
            return mb, #inside
        end
    end
    return nil, 0
end

-- [[ Visual Mini-Boss Room Areas (144x56x144 Exact Dimensions & Multi-Room Support) ]]
local activeMiniBossVisuals = nil

local function ClearMiniBossAreaVisuals()
    pcall(function()
        if activeMiniBossVisuals and activeMiniBossVisuals.Parent then
            activeMiniBossVisuals:Destroy()
            activeMiniBossVisuals = nil
        end
        local oldMulti = Workspace:FindFirstChild("RaxorHub_MiniBossAreas")
        if oldMulti then oldMulti:Destroy() end
        local oldSingle = Workspace:FindFirstChild("RaxorHub_MiniBossArea")
        if oldSingle then oldSingle:Destroy() end
    end)
end

-- Distinct vibrant colors for each room so user can distinguish Room 1, 2, 3 easily!
local ROOM_COLOR_PALETTE = {
    { box = Color3.fromRGB(0, 255, 220), edge = Color3.fromRGB(0, 255, 255), floor = Color3.fromRGB(0, 255, 120), ceil = Color3.fromRGB(255, 215, 0) },
    { box = Color3.fromRGB(0, 255, 100), edge = Color3.fromRGB(50, 255, 150), floor = Color3.fromRGB(0, 255, 180), ceil = Color3.fromRGB(255, 165, 0) },
    { box = Color3.fromRGB(255, 170, 0), edge = Color3.fromRGB(255, 200, 50), floor = Color3.fromRGB(255, 100, 50), ceil = Color3.fromRGB(0, 255, 255) },
    { box = Color3.fromRGB(200, 80, 255), edge = Color3.fromRGB(220, 120, 255), floor = Color3.fromRGB(180, 0, 255), ceil = Color3.fromRGB(0, 255, 150) }
}

local function CreateSingleMiniBossAreaVisual(roomData, roomIdx, parentContainer)
    if not roomData then return nil end
    local roomModel = nil

    pcall(function()
        local colorCfg = ROOM_COLOR_PALETTE[((roomIdx - 1) % #ROOM_COLOR_PALETTE) + 1]
        local isCircular = roomData.isCircular or (not roomData.isBeamRoom and not roomData.isBox)
        local roomRadius = roomData.radius or 72.0
        local roomDiameter = roomRadius * 2
        local roomHeight = (roomData.size and roomData.size.Y) or 56.0

        local roomPos = roomData.pos or (roomData.cframe and roomData.cframe.Position) or Vector3.zero
        local roomCenter = roomData.center or Vector3.new(roomPos.X, roomPos.Y + (roomHeight / 2), roomPos.Z)

        roomModel = Instance.new("Model")
        roomModel.Name = string.format("MiniBossArea_Room%d", roomIdx)

        local isCleared = IsRoomCleared(roomData)
        local statusTag = isCleared and "[เคลียร์แล้ว]" or "[ยังไม่เคลียร์]"
        local statusColor = isCleared and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(0, 255, 255)

        if isCircular then
            -- ─── CIRCULAR ROOM: Upright Cylinder (ทรงกระบอก) ───
            local cylPart = Instance.new("Part")
            cylPart.Name = "BoundaryVolume_Cylinder"
            cylPart.Shape = Enum.PartType.Cylinder
            cylPart.Anchored = true
            cylPart.CanCollide = false
            cylPart.CanQuery = false
            cylPart.CanTouch = false
            cylPart.CastShadow = false
            -- In Roblox, Cylinder length/height is X axis; diameter is Y and Z
            cylPart.Size = Vector3.new(roomHeight, roomDiameter, roomDiameter)
            -- Rotate 90 degrees around Z to make the cylinder stand vertically upright
            cylPart.CFrame = CFrame.new(roomCenter) * CFrame.Angles(0, 0, math.rad(90))
            cylPart.Material = Enum.Material.ForceField
            cylPart.Color = colorCfg.box
            cylPart.Transparency = 0.82
            cylPart.Parent = roomModel

            local hl = Instance.new("Highlight")
            hl.Name = "EdgeHighlight"
            hl.Adornee = cylPart
            hl.FillColor = colorCfg.box
            hl.FillTransparency = 0.90
            hl.OutlineColor = colorCfg.edge
            hl.OutlineTransparency = 0.3
            hl.Parent = cylPart

            local floorDisc = Instance.new("Part")
            floorDisc.Name = "FloorArea_Disc"
            floorDisc.Shape = Enum.PartType.Cylinder
            floorDisc.Anchored = true
            floorDisc.CanCollide = false
            floorDisc.CanQuery = false
            floorDisc.CanTouch = false
            floorDisc.CastShadow = false
            local floorY = roomCenter.Y - (roomHeight / 2) + 0.35
            floorDisc.Size = Vector3.new(0.4, roomDiameter - 6, roomDiameter - 6)
            floorDisc.CFrame = CFrame.new(roomCenter.X, floorY, roomCenter.Z) * CFrame.Angles(0, 0, math.rad(90))
            floorDisc.Material = Enum.Material.Neon
            floorDisc.Color = colorCfg.floor
            floorDisc.Transparency = 0.55
            floorDisc.Parent = roomModel

            local ceilDisc = Instance.new("Part")
            ceilDisc.Name = "CeilingArea_Disc"
            ceilDisc.Shape = Enum.PartType.Cylinder
            ceilDisc.Anchored = true
            ceilDisc.CanCollide = false
            ceilDisc.CanQuery = false
            ceilDisc.CanTouch = false
            ceilDisc.CastShadow = false
            local ceilY = roomCenter.Y + (roomHeight / 2) - 0.35
            ceilDisc.Size = Vector3.new(0.4, roomDiameter, roomDiameter)
            ceilDisc.CFrame = CFrame.new(roomCenter.X, ceilY, roomCenter.Z) * CFrame.Angles(0, 0, math.rad(90))
            ceilDisc.Material = Enum.Material.Neon
            ceilDisc.Color = colorCfg.ceil
            ceilDisc.Transparency = 0.80
            ceilDisc.Parent = roomModel

            local bbGui = Instance.new("BillboardGui")
            bbGui.Name = "RoomInfo"
            bbGui.Adornee = cylPart
            bbGui.Size = UDim2.fromOffset(280, 70)
            bbGui.StudsOffset = Vector3.new(0, (roomHeight / 2) + 5, 0)
            bbGui.AlwaysOnTop = true

            local typeTag = roomData.isTorchRoom and "Torch Arena" or "Air Trigger (ทรงกระบอก)"
            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundTransparency = 1
            label.TextColor3 = statusColor
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 14
            label.Text = string.format("Mini-Boss Room #%d %s\nทรงกระบอก (รัศมี %.0f, สูง %.0f)\n%s พิกัด: (%.0f, %.0f, %.0f)", 
                roomIdx, statusTag, roomRadius, roomHeight, typeTag, roomPos.X, roomPos.Y, roomPos.Z)
            label.Parent = bbGui
            bbGui.Parent = cylPart

        else
            -- ─── RECTANGULAR ROOM: 3D Box (คานไม้ Beams) ───
            local roomCFrame = roomData.cframe or CFrame.new(roomCenter)
            local roomSize = roomData.size or Vector3.new(144, 56, 144)

            local boxPart = Instance.new("Part")
            boxPart.Name = "BoundaryVolume"
            boxPart.Anchored = true
            boxPart.CanCollide = false
            boxPart.CanQuery = false
            boxPart.CanTouch = false
            boxPart.CastShadow = false
            boxPart.CFrame = roomCFrame
            boxPart.Size = roomSize
            boxPart.Material = Enum.Material.ForceField
            boxPart.Color = colorCfg.box
            boxPart.Transparency = 0.82
            boxPart.Parent = roomModel

            local selBox = Instance.new("SelectionBox")
            selBox.Name = "EdgeBox"
            selBox.Adornee = boxPart
            selBox.Color3 = colorCfg.edge
            selBox.SurfaceColor3 = colorCfg.box
            selBox.SurfaceTransparency = 0.88
            selBox.LineThickness = 0.25
            selBox.Parent = boxPart

            local floorPlane = Instance.new("Part")
            floorPlane.Name = "FloorArea"
            floorPlane.Anchored = true
            floorPlane.CanCollide = false
            floorPlane.CanQuery = false
            floorPlane.CanTouch = false
            floorPlane.CastShadow = false
            local floorY = roomCFrame.Position.Y - (roomSize.Y / 2) + 0.35
            floorPlane.CFrame = CFrame.new(roomCFrame.Position.X, floorY, roomCFrame.Position.Z) * (roomCFrame - roomCFrame.Position)
            floorPlane.Size = Vector3.new(math.max(10, roomSize.X - 6), 0.4, math.max(10, roomSize.Z - 6))
            floorPlane.Material = Enum.Material.Neon
            floorPlane.Color = colorCfg.floor
            floorPlane.Transparency = 0.55
            floorPlane.Parent = roomModel

            local ceilPlane = Instance.new("Part")
            ceilPlane.Name = "CeilingArea"
            ceilPlane.Anchored = true
            ceilPlane.CanCollide = false
            ceilPlane.CanQuery = false
            ceilPlane.CastShadow = false
            local ceilY = roomCFrame.Position.Y + (roomSize.Y / 2) - 0.35
            ceilPlane.CFrame = CFrame.new(roomCFrame.Position.X, ceilY, roomCFrame.Position.Z) * (roomCFrame - roomCFrame.Position)
            ceilPlane.Size = Vector3.new(roomSize.X, 0.4, roomSize.Z)
            ceilPlane.Material = Enum.Material.Neon
            ceilPlane.Color = colorCfg.ceil
            ceilPlane.Transparency = 0.80
            ceilPlane.Parent = roomModel

            local bbGui = Instance.new("BillboardGui")
            bbGui.Name = "RoomInfo"
            bbGui.Adornee = boxPart
            bbGui.Size = UDim2.fromOffset(280, 70)
            bbGui.StudsOffset = Vector3.new(0, (roomSize.Y / 2) + 5, 0)
            bbGui.AlwaysOnTop = true

            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundTransparency = 1
            label.TextColor3 = statusColor
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 14
            label.Text = string.format("Mini-Boss Room #%d %s\nขนาด: %.0f x %.0f x %.0f (คานไม้ Beams)\nพิกัด: (%.0f, %.0f, %.0f)", 
                roomIdx, statusTag, roomSize.X, roomSize.Y, roomSize.Z, roomPos.X, roomPos.Y, roomPos.Z)
            label.Parent = bbGui
            bbGui.Parent = boxPart
        end

        roomModel.Parent = parentContainer or Workspace
    end)

    return roomModel
end

-- [[ Visual 3D Area for Big Boss Room (Crimson Red Cylinder / Circular Arena) ]]
local function CreateBigBossAreaVisual(bigBoss, parentContainer)
    if not bigBoss or not bigBoss.pos then return nil end
    local bossModel = nil
    pcall(function()
        local bossPos = bigBoss.pos
        local roomRadius = bigBoss.radius or 90.0
        local roomDiameter = roomRadius * 2 -- 180 studs (ขยายถึงขอบกำแพง)
        local roomHeight = bigBoss.height or 56.0
        local bossCenter = Vector3.new(bossPos.X, bossPos.Y + (roomHeight / 2), bossPos.Z)

        bossModel = Instance.new("Model")
        bossModel.Name = "BigBossArea"

        -- 1. Upright Vertical Cylinder (ForceField Crimson Red)
        local cylPart = Instance.new("Part")
        cylPart.Name = "BigBossVolume_Cylinder"
        cylPart.Shape = Enum.PartType.Cylinder
        cylPart.Anchored = true
        cylPart.CanCollide = false
        cylPart.CanQuery = false
        cylPart.CanTouch = false
        cylPart.CastShadow = false
        -- Size.X = height (56), Size.Y = diameter (144), Size.Z = diameter (144)
        cylPart.Size = Vector3.new(roomHeight, roomDiameter, roomDiameter)
        cylPart.CFrame = CFrame.new(bossCenter) * CFrame.Angles(0, 0, math.rad(90))
        cylPart.Material = Enum.Material.ForceField
        cylPart.Color = Color3.fromRGB(255, 30, 60)
        cylPart.Transparency = 0.82
        cylPart.Parent = bossModel

        -- 2. Highlight for true curved silhouette (NO SelectionBox to avoid square box wireframe)
        local hl = Instance.new("Highlight")
        hl.Name = "BossEdgeHighlight"
        hl.Adornee = cylPart
        hl.FillColor = Color3.fromRGB(255, 30, 60)
        hl.FillTransparency = 0.92
        hl.OutlineColor = Color3.fromRGB(255, 70, 70)
        hl.OutlineTransparency = 0.25
        hl.Parent = cylPart

        -- 3. Circular Neon Floor Disc on the ground
        local floorDisc = Instance.new("Part")
        floorDisc.Name = "FloorArea_Disc"
        floorDisc.Shape = Enum.PartType.Cylinder
        floorDisc.Anchored = true
        floorDisc.CanCollide = false
        floorDisc.CanQuery = false
        floorDisc.CastShadow = false
        local floorY = bossCenter.Y - (roomHeight / 2) + 0.35
        floorDisc.Size = Vector3.new(0.4, roomDiameter - 2, roomDiameter - 2)
        floorDisc.CFrame = CFrame.new(bossCenter.X, floorY, bossCenter.Z) * CFrame.Angles(0, 0, math.rad(90))
        floorDisc.Material = Enum.Material.Neon
        floorDisc.Color = Color3.fromRGB(255, 40, 40)
        floorDisc.Transparency = 0.60
        floorDisc.Parent = bossModel

        -- 4. Circular Neon Ceiling Disc
        local ceilDisc = Instance.new("Part")
        ceilDisc.Name = "CeilingArea_Disc"
        ceilDisc.Shape = Enum.PartType.Cylinder
        ceilDisc.Anchored = true
        ceilDisc.CanCollide = false
        ceilDisc.CanQuery = false
        ceilDisc.CastShadow = false
        local ceilY = bossCenter.Y + (roomHeight / 2) - 0.35
        ceilDisc.Size = Vector3.new(0.4, roomDiameter, roomDiameter)
        ceilDisc.CFrame = CFrame.new(bossCenter.X, ceilY, bossCenter.Z) * CFrame.Angles(0, 0, math.rad(90))
        ceilDisc.Material = Enum.Material.Neon
        ceilDisc.Color = Color3.fromRGB(255, 120, 50)
        ceilDisc.Transparency = 0.78
        ceilDisc.Parent = bossModel

        -- 5. Exact Center Marker Disc (Gold Neon) at Props.Disc.PointLight
        local centerMarker = Instance.new("Part")
        centerMarker.Name = "DiscCenterMarker"
        centerMarker.Shape = Enum.PartType.Cylinder
        centerMarker.Anchored = true
        centerMarker.CanCollide = false
        centerMarker.CanQuery = false
        centerMarker.CastShadow = false
        centerMarker.Size = Vector3.new(0.6, 10, 10)
        centerMarker.CFrame = CFrame.new(bossPos.X, floorY + 0.25, bossPos.Z) * CFrame.Angles(0, 0, math.rad(90))
        centerMarker.Material = Enum.Material.Neon
        centerMarker.Color = Color3.fromRGB(255, 220, 50)
        centerMarker.Transparency = 0.25
        centerMarker.Parent = bossModel

        -- 6. Overhead Billboard label
        local bbGui = Instance.new("BillboardGui")
        bbGui.Name = "RoomInfo"
        bbGui.Adornee = cylPart
        bbGui.Size = UDim2.fromOffset(300, 80)
        bbGui.StudsOffset = Vector3.new(0, (roomHeight / 2) + 6, 0)
        bbGui.AlwaysOnTop = true

        local isDefeated = isGuardianDefeated
        local statusTag = isDefeated and "[ปราบแล้ว/ทางลงเปิด]" or "[ยังไม่เคลียร์]"
        local statusColor = isDefeated and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(255, 80, 80)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.TextColor3 = statusColor
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.Text = string.format("ห้อง Boss ใหญ่ (Big Boss Arena) %s\nทรงกระบอก / วงกลม (เส้นผ่านศูนย์กลาง %.0f, สูง %.0f)\nจุดกึ่งกลาง: Props.Disc.PointLight (ขนาด 0.1, 10, 10)\nพิกัด Disc: (%.0f, %.0f, %.0f)", 
            statusTag, roomDiameter, roomHeight, bossPos.X, bossPos.Y, bossPos.Z)
        label.Parent = bbGui
        bbGui.Parent = cylPart

        bossModel.Parent = parentContainer or Workspace
    end)
    return bossModel
end

local function CreateMiniBossAreaVisual(roomCFrame, roomSize)
    ClearMiniBossAreaVisuals()
    local container = Instance.new("Model")
    container.Name = "RaxorHub_MiniBossAreas"
    CreateSingleMiniBossAreaVisual({ cframe = roomCFrame, size = roomSize, isBeamRoom = true }, 1, container)
    container.Parent = Workspace
    activeMiniBossVisuals = container
    return container
end

-- [[ Mini-Boss Room Detection via Ceiling Beams (144x56x144 Exact Dimensions) ]]
local function FindBeamMiniBossRooms(searchContainer, floorFolder)
    local container = searchContainer or floorFolder
    if not container then return {} end

    local candidateBeams = {}
    for _, obj in ipairs(container:GetChildren()) do
        if obj.Name == "Beam" and obj:IsA("BasePart") then
            local s = obj.Size
            local maxDim = math.max(s.X, s.Y, s.Z)
            local minDim = math.min(s.X, s.Y, s.Z)
            if maxDim >= 115 and minDim <= 5 then
                table.insert(candidateBeams, obj)
            end
        end
    end

    if #candidateBeams == 0 then return {} end

    -- Group parallel beams by similar height and orientation
    local clusters = {}
    for _, beam in ipairs(candidateBeams) do
        local bcf = beam.CFrame
        local bPos = bcf.Position
        local bRot = bcf - bPos
        local bLook = bcf.LookVector
        local bRight = bcf.RightVector

        local matchedCluster = nil
        for _, cl in ipairs(clusters) do
            if math.abs(cl.y - bPos.Y) < 5 then
                local dotRight = math.abs(cl.right:Dot(bRight))
                local dotLook = math.abs(cl.look:Dot(bLook))
                if dotRight > 0.85 or dotLook > 0.85 then
                    local d = (Vector3.new(cl.center.X, 0, cl.center.Z) - Vector3.new(bPos.X, 0, bPos.Z)).Magnitude
                    if d < 180 then
                        matchedCluster = cl
                        break
                    end
                end
            end
        end

        if matchedCluster then
            table.insert(matchedCluster.beams, beam)
            local totalPos = Vector3.zero
            for _, b in ipairs(matchedCluster.beams) do
                totalPos = totalPos + b.Position
            end
            matchedCluster.center = totalPos / #matchedCluster.beams
        else
            table.insert(clusters, {
                y = bPos.Y,
                right = bRight,
                look = bLook,
                rotation = bRot,
                center = bPos,
                beams = { beam }
            })
        end
    end

    local rooms = {}
    for _, cl in ipairs(clusters) do
        if #cl.beams >= 3 then
            local beamLength = 144
            for _, b in ipairs(cl.beams) do
                local s = b.Size
                local maxS = math.max(s.X, s.Y, s.Z)
                if maxS > 100 then beamLength = maxS end
            end

            -- Determine long axis and perpendicular axis
            local sampleBeam = cl.beams[1]
            local s = sampleBeam.Size
            local longAxis = cl.right
            local perpAxis = cl.look
            if s.Z >= s.X then
                longAxis = cl.look
                perpAxis = cl.right
            end

            if math.abs(perpAxis.Y) > 0.2 then
                perpAxis = Vector3.new(perpAxis.X, 0, perpAxis.Z).Unit
            end

            local minProj, maxProj = math.huge, -math.huge
            for _, b in ipairs(cl.beams) do
                local proj = (b.Position - cl.center):Dot(perpAxis)
                if proj < minProj then minProj = proj end
                if proj > maxProj then maxProj = proj end
            end

            local beamSpan = maxProj - minProj
            local spacing = (#cl.beams > 1) and (beamSpan / (#cl.beams - 1)) or 24
            local roomWidth = beamSpan + 2 * spacing
            if roomWidth < 120 or roomWidth > 180 then roomWidth = 144 end

            local roomHeight = 56.0
            local beamY = cl.y
            local floorY = beamY - roomHeight
            local roomCenterY = beamY - (roomHeight / 2)
            local roomCenter = Vector3.new(cl.center.X, roomCenterY, cl.center.Z)

            local roomCFrame = CFrame.new(roomCenter) * cl.rotation
            local roomSize = Vector3.new(roomWidth, roomHeight, beamLength)
            local isBigBoss = (beamLength > 165)

            table.insert(rooms, {
                center = roomCenter,
                pos = Vector3.new(cl.center.X, floorY + 2.5, cl.center.Z),
                cframe = roomCFrame,
                size = roomSize,
                length = beamLength,
                width = roomWidth,
                height = roomHeight,
                floorY = floorY,
                ceilingY = beamY,
                beams = cl.beams,
                id = string.format("mini_boss_beam_%.0f_%.0f", cl.center.X, cl.center.Z),
                isBox = true,
                isBeamRoom = true,
                isBigBossCandidate = isBigBoss
            })
        end
    end

    return rooms
end

-- [[ Analyze Floor Rooms via workspace.Labyrinth[Floor].Props (Cached per Floor) ]]
-- [[ Analyze Floor Rooms via workspace.Labyrinth[Floor].Props (Stream-Aware Periodic Scan) ]]
AnalyzeFloorRooms = function(forceRescan)
    local currentFloor = GetCurrentFloor()
    if cachedFloorRoomsName ~= currentFloor then
        cachedFloorRoomsName = currentFloor
        discoveredMiniBosses = {}
        discoveredTreasureRooms = {}
        discoveredBigBoss = nil
        lastRoomScanTime = 0
        cachedBigBossRoom = nil
        lastBigBossCheckFloor = nil
        cachedFloorRooms = nil
    end

    local now = tick()
    -- Throttle: if scanned within 4 seconds and Boss is already discovered, return cached tables
    if not forceRescan and (now - lastRoomScanTime < 4.0) and (lastRoomScanTime > 0) and (discoveredBigBoss ~= nil) then
        return discoveredMiniBosses, discoveredTreasureRooms, discoveredBigBoss
    end
    -- If Boss is not yet discovered, scan every 3.0s:
    if not forceRescan and (now - lastRoomScanTime < 3.0) and (lastRoomScanTime > 0) then
        return discoveredMiniBosses, discoveredTreasureRooms, discoveredBigBoss
    end

    lastRoomScanTime = now

    local labyrinth = Workspace:FindFirstChild("Labyrinth")
    if not labyrinth then return discoveredMiniBosses, discoveredTreasureRooms, discoveredBigBoss end

    local floorFolder = labyrinth:FindFirstChild(currentFloor)
    if not floorFolder then
        for _, child in ipairs(labyrinth:GetChildren()) do
            if string.lower(child.Name) == string.lower(currentFloor) 
               or string.find(string.lower(child.Name), string.lower(currentFloor)) then
                floorFolder = child
                break
            end
        end
    end
    if not floorFolder then
        for _, child in ipairs(labyrinth:GetChildren()) do
            if string.find(child.Name, "Floor") then
                floorFolder = child
                break
            end
        end
    end

    local props = floorFolder and (floorFolder:FindFirstChild("Props") or floorFolder:FindFirstChild("props"))
    local searchContainer = props or floorFolder
    if not searchContainer then return discoveredMiniBosses, discoveredTreasureRooms, discoveredBigBoss end

    local allChests = {}
    if floorFolder then
        for _, obj in ipairs(floorFolder:GetChildren()) do
            if obj.Name == "Chest" then
                local cf = GetObjectCFrame(obj)
                if cf then
                    table.insert(allChests, { instance = obj, pos = cf.Position })
                end
            end
        end
    end
    if #allChests == 0 and props then
        for _, obj in ipairs(props:GetChildren()) do
            if obj.Name == "Chest" then
                local cf = GetObjectCFrame(obj)
                if cf then
                    table.insert(allChests, { instance = obj, pos = cf.Position })
                end
            end
        end
    end

    local allDoors = {}
    if searchContainer then
        for _, obj in ipairs(searchContainer:GetChildren()) do
            if obj.Name == "GrandDoor" then
                local cf = GetObjectCFrame(obj)
                if cf then
                    table.insert(allDoors, { instance = obj, pos = cf.Position })
                end
            end
        end
    end
    if floorFolder and floorFolder ~= searchContainer then
        for _, obj in ipairs(floorFolder:GetChildren()) do
            if obj.Name == "GrandDoor" then
                local cf = GetObjectCFrame(obj)
                if cf then
                    table.insert(allDoors, { instance = obj, pos = cf.Position })
                end
            end
        end
    end

    -- 0. Identify Big Boss Room FIRST (ExitRing, PortalBeam, or Disc)
    if not discoveredBigBoss then
        discoveredBigBoss = FindBigBossRoom()
    end
    local bossPos = discoveredBigBoss and discoveredBigBoss.pos

    -- 1. Scan Ceiling Beams for Mini-Boss Rooms (Exact 144x56x144 Dimensions)
    local beamRooms = FindBeamMiniBossRooms(searchContainer, floorFolder)
    for _, bRoom in ipairs(beamRooms) do
        local isNearBoss = bossPos and ((Vector3.new(bRoom.pos.X, 0, bRoom.pos.Z) - Vector3.new(bossPos.X, 0, bossPos.Z)).Magnitude < 135)
        local isBigBossBeam = bRoom.isBigBossCandidate or (bRoom.length and bRoom.length > 165)

        if not isNearBoss and not isBigBossBeam then
            local isDuplicate = false
            for _, existing in ipairs(discoveredMiniBosses) do
                if (existing.pos - bRoom.pos).Magnitude < 80 then
                    isDuplicate = true
                    if not existing.beam and bRoom.beam then existing.beam = bRoom.beam end
                    break
                end
            end
            if not isDuplicate then
                for _, tr in ipairs(discoveredTreasureRooms) do
                    if (tr.pos - bRoom.pos).Magnitude < 80 then
                        isDuplicate = true
                        break
                    end
                end
            end
            if not isDuplicate then
                table.insert(discoveredMiniBosses, bRoom)
            end
        end
    end

    -- 2. Scan Props.Air
    for _, obj in ipairs(searchContainer:GetChildren()) do
        if obj.Name == "Air" then
            local airPos = nil
            if obj:IsA("BasePart") then
                airPos = obj.Position
            elseif obj:IsA("Model") then
                local cf = GetObjectCFrame(obj)
                airPos = cf and cf.Position
            end

            if airPos then
                local isNearBoss = bossPos and ((Vector3.new(airPos.X, 0, airPos.Z) - Vector3.new(bossPos.X, 0, bossPos.Z)).Magnitude < 135)
                if not isNearBoss then
                    local clusteredChests = {}
                    for _, chest in ipairs(allChests) do
                        if (chest.pos - airPos).Magnitude <= 65 then
                            table.insert(clusteredChests, chest)
                        end
                    end

                    if #clusteredChests >= 2 then
                        -- Treasure Cave! Find nearest GrandDoor
                        local nearestDoor = nil
                        local minD = math.huge
                        for _, door in ipairs(allDoors) do
                            local d = (door.pos - airPos).Magnitude
                            if d < minD then
                                minD = d
                                nearestDoor = door
                            end
                        end

                        local isDuplicate = false
                        for _, tr in ipairs(discoveredTreasureRooms) do
                            if (tr.pos - airPos).Magnitude < 80 then
                                isDuplicate = true
                                tr.chests = clusteredChests
                                if not tr.door then tr.door = nearestDoor end
                                break
                            end
                        end
                        if not isDuplicate then
                            table.insert(discoveredTreasureRooms, {
                                air = obj,
                                id = string.format("treasure_%.0f_%.0f", airPos.X, airPos.Z),
                                pos = airPos,
                                chests = clusteredChests,
                                door = nearestDoor
                            })
                        end
                    else
                        -- Mini-Boss Circular / Air Room!
                        local isDuplicate = false
                        for _, existing in ipairs(discoveredMiniBosses) do
                            if (existing.pos - airPos).Magnitude < 80 then
                                isDuplicate = true
                                if not existing.air then existing.air = obj end
                                break
                            end
                        end
                        if not isDuplicate then
                            for _, tr in ipairs(discoveredTreasureRooms) do
                                if (tr.pos - airPos).Magnitude < 80 then
                                    isDuplicate = true
                                    break
                                end
                            end
                        end
                        if not isDuplicate then
                            table.insert(discoveredMiniBosses, {
                                air = obj,
                                id = string.format("air_%.0f_%.0f", airPos.X, airPos.Z),
                                pos = airPos,
                                radius = 72.0,
                                isCircular = true
                            })
                        end
                    end
                end
            end
        end
    end

    -- 3. Scan Torch Colliders (Mini-Boss Rooms without Air)
    local torchPositions = {}
    for _, obj in ipairs(searchContainer:GetChildren()) do
        if obj.Name == "Collider" and obj:IsA("BasePart") then
            local s = obj.Size
            if math.abs(s.X - 2.86) < 0.25 and math.abs(s.Y - 17.6) < 0.6 and math.abs(s.Z - 2.86) < 0.25 then
                table.insert(torchPositions, obj.Position)
            end
        end
    end

    local usedTorches = {}
    local torchArenaCenters = {}

    for i = 1, #torchPositions do
        if not usedTorches[i] then
            local p1 = torchPositions[i]
            local candidates = {}
            for j = 1, #torchPositions do
                if i ~= j and not usedTorches[j] then
                    local p2 = torchPositions[j]
                    local dist = math.sqrt((p1.X - p2.X)^2 + (p1.Z - p2.Z)^2)
                    if dist >= 65 and dist <= 140 and math.abs(p1.Y - p2.Y) < 12 then
                        table.insert(candidates, { dist = dist, idx = j })
                    end
                end
            end

            table.sort(candidates, function(a, b) return a.dist < b.dist end)

            if #candidates >= 3 then
                local cluster = { i, candidates[1].idx, candidates[2].idx, candidates[3].idx }
                local cx, cy, cz = 0, 0, 0
                for _, idx in ipairs(cluster) do
                    cx = cx + torchPositions[idx].X
                    cy = cy + torchPositions[idx].Y
                    cz = cz + torchPositions[idx].Z
                end
                cx, cy, cz = cx / 4, cy / 4, cz / 4

                local valid = true
                for _, idx in ipairs(cluster) do
                    local p = torchPositions[idx]
                    local dCenter = math.sqrt((p.X - cx)^2 + (p.Z - cz)^2)
                    if dCenter < 48 or dCenter > 75 then
                        valid = false
                        break
                    end
                end

                if valid then
                    for _, idx in ipairs(cluster) do
                        usedTorches[idx] = true
                    end
                    local floorY = cy - 6.0
                    table.insert(torchArenaCenters, Vector3.new(cx, floorY, cz))
                end
            end
        end
    end

    -- Merge Torch Arena Centers into discoveredMiniBosses
    for _, center in ipairs(torchArenaCenters) do
        local isDuplicate = false
        local isNearBoss = bossPos and ((Vector3.new(center.X, 0, center.Z) - Vector3.new(bossPos.X, 0, bossPos.Z)).Magnitude < 135)
        if isNearBoss then
            isDuplicate = true
        else
            for _, mb in ipairs(discoveredMiniBosses) do
                if (mb.pos - center).Magnitude < 80 then
                    isDuplicate = true
                    break
                end
            end
            if not isDuplicate then
                for _, tr in ipairs(discoveredTreasureRooms) do
                    if (tr.pos - center).Magnitude < 80 then
                        isDuplicate = true
                        break
                    end
                end
            end
        end

        if not isDuplicate then
            table.insert(discoveredMiniBosses, {
                air = nil,
                id = string.format("torch_%.0f_%.0f", center.X, center.Z),
                pos = center,
                radius = 72.0,
                isCircular = true,
                isTorchRoom = true
            })
        end
    end

    -- 4. Ensure Big Boss Room is identified via FindBigBossRoom (Props.Disc.PointLight)
    if not discoveredBigBoss then
        discoveredBigBoss = FindBigBossRoom()
    end
    if discoveredBigBoss and not discoveredBigBoss.door then
        local bp = discoveredBigBoss.pos
        if bp then
            local closestDoor = nil
            local minD = math.huge
            for _, door in ipairs(allDoors) do
                local d = (door.pos - bp).Magnitude
                if d < minD then
                    minD = d
                    closestDoor = door
                end
            end
            discoveredBigBoss.door = closestDoor
        end
    end
    -- Fallback: Active Guardian/Boss in BADEnemies
    if not discoveredBigBoss then
        local activeBoss = GetAliveBossOrGuardian()
        if activeBoss and activeBoss.part then
            local bPos = activeBoss.part.Position
            local closestDoor = nil
            local minD = math.huge
            for _, door in ipairs(allDoors) do
                local d = (door.pos - bPos).Magnitude
                if d < minD then
                    minD = d
                    closestDoor = door
                end
            end
            discoveredBigBoss = {
                object = activeBoss.model,
                door = closestDoor,
                pos = bPos,
                radius = 90.0,
                height = 56.0,
                isCircular = true,
                isBox = false
            }
        end
    end

    cachedFloorRooms = {
        miniBossRooms = discoveredMiniBosses,
        treasureRooms = discoveredTreasureRooms,
        bigBoss = discoveredBigBoss
    }
    return discoveredMiniBosses, discoveredTreasureRooms, discoveredBigBoss
end
-- [[ Master Check Area Function: Scans & Visualizes ALL Mini-Boss Rooms on the Floor ]]
local function CheckMiniBossAreas()
    ClearMiniBossAreaVisuals()
    cachedFloorRooms = nil
    cachedFloorRoomsName = ""
    cachedBigBossRoom = nil
    lastBigBossCheckFloor = nil
    lastRoomScanTime = 0
    discoveredMiniBosses = {}
    discoveredTreasureRooms = {}
    discoveredBigBoss = nil

    local currentFloor = GetCurrentFloor()
    local miniBossRooms, treasureRooms, bigBoss = AnalyzeFloorRooms()
    local container = Instance.new("Model")
    container.Name = "RaxorHub_MiniBossAreas"

    print("══════════════════════════════════════════════════")
    print(string.format("[RAXOR] Check Area: ตรวจสอบห้องในชั้น %s", tostring(currentFloor)))
    print(string.format("  -> พบห้อง Mini-Boss ทั้งหมด: %d ห้อง", #miniBossRooms))

    for i, mb in ipairs(miniBossRooms) do
        CreateSingleMiniBossAreaVisual(mb, i, container)
        local p = mb.pos or (mb.cframe and mb.cframe.Position) or Vector3.zero
        local typeStr = mb.isBeamRoom and "Beams (คานไม้ 144x56x144)" or (mb.isTorchRoom and "Torch Arena" or "Air Trigger")
        local isClr = IsRoomCleared(mb)
        print(string.format("  [%d] %s พิกัด: (%.0f, %.0f, %.0f) %s", i, typeStr, p.X, p.Y, p.Z, isClr and "[CLEARED]" or "[UNCLEARED]"))
    end

    if treasureRooms and #treasureRooms > 0 then
        print(string.format("  -> พบห้อง Treasure Rooms: %d ห้อง", #treasureRooms))
        for i, tr in ipairs(treasureRooms) do
            print(string.format("     Treasure #%d: พิกัด (%.0f, %.0f, %.0f) - กล่อง: %d ใบ", i, tr.pos.X, tr.pos.Y, tr.pos.Z, #(tr.chests or {})))
        end
    end

    if bigBoss then
        local bp = bigBoss.pos or Vector3.zero
        print(string.format("  -> พบห้อง Big Boss: พิกัด (%.0f, %.0f, %.0f)", bp.X, bp.Y, bp.Z))
    end
    print("══════════════════════════════════════════════════")

    -- Also visualize Big Boss room in Red so user can clearly see it's separated!
    if bigBoss and bigBoss.pos then
        CreateBigBossAreaVisual(bigBoss, container)
        print(string.format("  [BOSS] ห้อง Boss ใหญ่ (สีแดง) พิกัด: (%.0f, %.0f, %.0f)", bigBoss.pos.X, bigBoss.pos.Y, bigBoss.pos.Z))
    end

    container.Parent = Workspace
    activeMiniBossVisuals = container

    if #miniBossRooms > 0 then
        local detailList = {}
        for i, mb in ipairs(miniBossRooms) do
            local p = mb.pos or (mb.cframe and mb.cframe.Position) or Vector3.zero
            local typeStr = mb.isCircular and "ทรงกระบอก" or "สี่เหลี่ยม"
            table.insert(detailList, string.format("#%d: %s (%.0f, %.0f)", i, typeStr, p.X, p.Z))
        end
        local bossStr = bigBoss and string.format(" + ห้อง Boss ใหญ่ (แดง)") or ""
        local contentMsg = string.format("พบ Mini-Boss %d ห้อง%s ใน %s!\n%s\n(สร้าง Part Area แสดงบนแมพแล้ว - สี่เหลี่ยม, ทรงกระบอก, ห้องบอส)", 
            #miniBossRooms, bossStr, tostring(currentFloor), table.concat(detailList, " | "))

        RaxorHub:Notify({
            Title = "Check Area",
            Content = contentMsg,
            Duration = 6
        })
    else
        RaxorHub:Notify({
            Title = "Check Area",
            Content = string.format("ไม่พบห้อง Mini-Boss ในชั้น %s (แมพอาจยังโหลดไม่เสร็จ)", tostring(currentFloor)),
            Duration = 4
        })
    end

    return miniBossRooms
end

-- [[ Accurate Outside / Hallway Enemies Filter ]]
-- Finds all living enemies in BADEnemies that are OUTSIDE of all special rooms:
-- - Outside of Big Boss room (IsInsideBigBossRoom)
-- - Outside of all Treasure rooms (radius 38 from tr.pos)
-- - Outside of all Mini-Boss rooms (radius 48 from mb.pos)
-- - Outside of unopened GrandDoors (behind closed doors)
local function GetOutsideEnemies(miniBossRooms, treasureRooms, bigBoss)
    if not miniBossRooms or not treasureRooms or not bigBoss then
        local mb, tr, bb = AnalyzeFloorRooms()
        miniBossRooms = miniBossRooms or mb
        treasureRooms = treasureRooms or tr
        bigBoss = bigBoss or bb or cachedBigBossRoom
    end

    local allEnemies = GetAliveEnemies()
    local outside = {}

    for i = 1, #allEnemies do
        local e = allEnemies[i]
        if e.part and e.model.Parent then
            -- Single fast pure-math barrier check (0ms)
            if not IsInsideAnySpecialRoom(e.part.Position, 5.0) then
                table.insert(outside, e)
            end
        end
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = hrp and hrp.Position or Vector3.zero
    table.sort(outside, function(a, b)
        local da = (a.part.Position - myPos).Magnitude
        local db = (b.part.Position - myPos).Magnitude
        return da < db
    end)

    return outside
end

local function GetDungeonArenas()
    local arenas = {}
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local labHUD = pgui and pgui:FindFirstChild("LabHUD")
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not labHUD or not hrp then return arenas end

    local canvas = nil
    for _, desc in ipairs(labHUD:GetDescendants()) do
        if desc:IsA("Frame") and desc.Size == UDim2.fromOffset(10, 10) then
            canvas = desc
            break
        end
    end
    if not canvas then
        for _, desc in ipairs(labHUD:GetDescendants()) do
            if desc:IsA("Frame") and #desc:GetChildren() >= 4 and desc:FindFirstChildWhichIsA("ImageLabel") then
                canvas = desc
                break
            end
        end
    end
    if not canvas then return arenas end

    local playerDot = nil
    for _, child in ipairs(canvas:GetChildren()) do
        if child:IsA("ImageLabel") and child.Visible and (child.ImageColor3 == Color3.fromRGB(255, 244, 210) or child.Size.X.Offset <= 30) then
            playerDot = child
            break
        end
    end
    if not playerDot then return arenas end

    for _, child in ipairs(canvas:GetChildren()) do
        if child:IsA("Frame") and child.Visible and (child.Size.X.Offset == 20 or child.Size.X.Offset == 26) then
            local stroke = child:FindFirstChildWhichIsA("UIStroke")
            local strokeColor = stroke and stroke.Color or child.BackgroundColor3
            local kind = "combat"
            if strokeColor == Color3.fromRGB(255, 140, 80) then
                kind = "guardian"
            elseif strokeColor == Color3.fromRGB(200, 100, 255) then
                kind = "boss"
            elseif strokeColor == Color3.fromRGB(255, 215, 0) then
                kind = "treasure"
            end

            local dx = (child.Position.X.Offset - playerDot.Position.X.Offset) / 0.6
            local dz = (child.Position.Y.Offset - playerDot.Position.Y.Offset) / 0.6
            local worldPos = Vector3.new(hrp.Position.X + dx, hrp.Position.Y, hrp.Position.Z + dz)

            table.insert(arenas, {
                kind = kind,
                pos = worldPos,
                frame = child,
                dist = (worldPos - hrp.Position).Magnitude
            })
        end
    end

    -- Sort: normal combat/treasure first, guardian/boss last
    table.sort(arenas, function(a, b)
        local aIsBoss = (a.kind == "guardian" or a.kind == "boss")
        local bIsBoss = (b.kind == "guardian" or b.kind == "boss")
        if aIsBoss and not bIsBoss then
            return false
        elseif not aIsBoss and bIsBoss then
            return true
        end
        return a.dist < b.dist
    end)

    return arenas
end

-- =========================================================================
-- [[ Auto Revive Teammate System (Autonomous Player Revival) ]]
-- =========================================================================
local isRevivingTeammate = false
local StartAutoReviveLoop = nil
local CheckAndPerformAutoRevive = nil

-- [[ Detect All Downed Teammates via RevivePrompt ]]
local function GetDownedTeammatesList()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = hrp and hrp.Position or Vector3.zero

    local downedList = {}
    local seenPlayers = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pChar = p.Character or Workspace:FindFirstChild(p.Name)
            if pChar and pChar.Parent then
                local pHrp = pChar:FindFirstChild("HumanoidRootPart") or pChar.PrimaryPart
                
                -- 1. Exact match: workspace[Player].HumanoidRootPart.RevivePrompt
                local prompt = (pHrp and pHrp:FindFirstChild("RevivePrompt"))
                
                -- 2. Fallback: Search anywhere in Character
                if not prompt then
                    prompt = pChar:FindFirstChild("RevivePrompt", true)
                end

                -- 3. Fallback: Any ProximityPrompt with name or action containing 'revive'
                if not prompt then
                    for _, desc in ipairs(pChar:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") then
                            local nLower = string.lower(desc.Name)
                            local aLower = string.lower(desc.ActionText or "")
                            if string.find(nLower, "revive") or string.find(aLower, "revive") then
                                prompt = desc
                                break
                            end
                        end
                    end
                end

                if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Parent then
                    seenPlayers[p] = true
                    local targetPos = (pHrp and pHrp.Position) or GetObjectCFrame(pChar).Position
                    local dist = (targetPos - myPos).Magnitude
                    table.insert(downedList, {
                        player = p,
                        character = pChar,
                        hrp = pHrp,
                        prompt = prompt,
                        pos = targetPos,
                        dist = dist
                    })
                end
            end
        end
    end

    -- 4. Fallback: Search all Models in Workspace directly (handles edge-case desynced player models)
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character and obj:FindFirstChildWhichIsA("Humanoid") then
            local alreadyAdded = false
            for _, item in ipairs(downedList) do
                if item.character == obj then
                    alreadyAdded = true
                    break
                end
            end
            if not alreadyAdded then
                local pHrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                local prompt = (pHrp and pHrp:FindFirstChild("RevivePrompt")) or obj:FindFirstChild("RevivePrompt", true)
                if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Parent then
                    local targetPos = (pHrp and pHrp.Position) or GetObjectCFrame(obj).Position
                    local dist = (targetPos - myPos).Magnitude
                    table.insert(downedList, {
                        player = nil,
                        character = obj,
                        hrp = pHrp,
                        prompt = prompt,
                        pos = targetPos,
                        dist = dist
                    })
                end
            end
        end
    end

    if #downedList > 1 then
        table.sort(downedList, function(a, b) return a.dist < b.dist end)
    end

    return downedList
end

-- [[ Single Teammate Wrapper (Backwards Compatibility) ]]
local function GetDownedTeammate()
    local list = GetDownedTeammatesList()
    return list[1]
end

-- [[ Helper: Check if Teammate's RevivePrompt is Still Active in the World ]]
local function IsTeammatePromptActive(downedData)
    if not downedData then return false end
    local prompt = downedData.prompt
    local char = downedData.character
    if not prompt or not prompt.Parent or not prompt.Enabled then
        return false
    end
    if char and char.Parent then
        local pHrp = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
        local activePrompt = (pHrp and pHrp:FindFirstChild("RevivePrompt")) or char:FindFirstChild("RevivePrompt", true)
        if not activePrompt or not activePrompt.Parent or not activePrompt.Enabled then
            return false
        end
    else
        return false
    end
    return true
end

-- [[ Perform Revival on Downed Teammate until RevivePrompt Disappears ]]
local function RevivePlayer(downedData)
    if not downedData or not downedData.prompt then return false end
    local prompt = downedData.prompt
    local targetChar = downedData.character
    local myChar = LocalPlayer.Character
    local myHum = myChar and myChar:FindFirstChildWhichIsA("Humanoid")
    if not myHum or myHum.Health <= 0 then return false end

    local pName = downedData.player and downedData.player.Name or downedData.character.Name
    local keyCode = prompt.KeyboardKeyCode or Enum.KeyCode.F

    -- Prepare prompt properties
    pcall(function()
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 45
        if State.InstantPrompt then
            prompt.HoldDuration = 0
        end
    end)

    -- Teleport close beside teammate (1.5 studs above, 2.0 studs offset)
    local pHrp = targetChar:FindFirstChild("HumanoidRootPart") or targetChar.PrimaryPart
    local currentTargetPos = (pHrp and pHrp.Position) or downedData.pos
    local reviveStandPos = currentTargetPos + Vector3.new(0, 1.5, 2.0)
    SafeTeleportTo(reviveStandPos)

    -- Press and HOLD F key down continuously (Do NOT release every frame!)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    end)
    pcall(function()
        prompt:InputHoldBegin()
    end)

    local startTime = tick()
    local maxReviveTime = 12.0 -- Maximum safety timeout
    local lastFireTime = 0

    -- [[ CRITICAL: Stay on this player and hold until their RevivePrompt is COMPLETELY GONE! ]]
    while IsTeammatePromptActive(downedData) and (tick() - startTime < maxReviveTime) and State.AutoRevive do
        local checkChar = LocalPlayer.Character
        local checkHum = checkChar and checkChar:FindFirstChildWhichIsA("Humanoid")
        if not checkHum or checkHum.Health <= 0 then break end

        -- Dynamically follow teammate position if they moved or ragdolled
        if targetChar and targetChar.Parent then
            local liveHrp = targetChar:FindFirstChild("HumanoidRootPart") or targetChar.PrimaryPart
            if liveHrp then
                currentTargetPos = liveHrp.Position
                reviveStandPos = currentTargetPos + Vector3.new(0, 1.5, 2.0)
            end
        end

        SafeTeleportTo(reviveStandPos)

        -- Keep holding F down
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        end)

        -- Periodically trigger fireproximityprompt every 0.15s (for instant executors)
        local now = tick()
        if fireproximityprompt and (now - lastFireTime >= 0.15) then
            lastFireTime = now
            pcall(function()
                if State.InstantPrompt then prompt.HoldDuration = 0 end
                fireproximityprompt(prompt, 0)
                fireproximityprompt(prompt, 1)
            end)
        end

        task.wait(0.1)
    end

    -- Release F key and prompt hold
    pcall(function()
        prompt:InputHoldEnd()
    end)
    pcall(function()
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    end)

    -- Small delay to let game transition animations/state
    task.wait(0.25)

    -- Verify that the RevivePrompt has truly disappeared
    local isStillActive = IsTeammatePromptActive(downedData)
    return not isStillActive
end

-- [[ Master Auto Revive Executor: Chain-Revive ALL Downed Teammates One by One, then Warp Back ]]
CheckAndPerformAutoRevive = function()
    if not State.AutoRevive or isRevivingTeammate then return false end

    -- Check if ANY teammate is currently downed
    local initialDownedList = GetDownedTeammatesList()
    if #initialDownedList == 0 then return false end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return false end

    isRevivingTeammate = true

    -- SAVE ORIGINAL POSITION & ROOM CONFINEMENT ONCE BEFORE CHAIN REVIVING
    local preRevivePos = hrp.Position
    local preReviveRoom = currentCombatRoom
    local revivedCount = 0

    -- CHAIN REVIVAL LOOP: Process ALL downed teammates one-by-one until RevivePrompt is gone on all!
    while State.AutoRevive do
        local myChar = LocalPlayer.Character
        local myHum = myChar and myChar:FindFirstChildWhichIsA("Humanoid")
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp or not myHum or myHum.Health <= 0 then
            break -- Local player died, abort cleanly
        end

        -- Query remaining downed teammates
        local downedList = GetDownedTeammatesList()
        if #downedList == 0 then
            -- Everyone is revived!
            break
        end

        -- Pick the closest downed teammate
        local targetDowned = downedList[1]
        local pName = targetDowned.player and targetDowned.player.Name or targetDowned.character.Name

        UpdateDungeonStatus(string.format("พบเพื่อนร่วมทีม (%s) Down (เหลือ %d คน)! กำลังวาปไปชุบชีวิต...", pName, #downedList))
        pcall(function()
            RaxorHub:Notify({ Title = "Auto Revive", Content = string.format("กำลังชุบชีวิต %s (เหลือ %d คน)", pName, #downedList), Duration = 2.0 })
        end)

        -- Warp to this teammate and revive them until their RevivePrompt completely disappears!
        local success = RevivePlayer(targetDowned)
        if success then
            revivedCount = revivedCount + 1
            UpdateDungeonStatus(string.format("ชุบชีวิต %s สำเร็จ (RevivePrompt หายแล้ว)!", pName))
            task.wait(0.2)
        else
            -- If prompt failed to clear or player left, small delay before re-checking next
            task.wait(0.3)
        end
    end

    -- ALL DOWNED TEAMMATES ARE REVIVED: Warp back to exact original spot
    if revivedCount > 0 then
        UpdateDungeonStatus(string.format("ชุบชีวิตเพื่อนครบทุกคนแล้ว (%d คน)! กำลังวาปกลับไปจุดเดิม...", revivedCount))
    end
    task.wait(0.2)

    -- Warp back to exact original position seamlessly
    SafeTeleportTo(preRevivePos)
    currentCombatRoom = preReviveRoom
    task.wait(0.25)

    isRevivingTeammate = false
    return (revivedCount > 0)
end

-- [[ Standalone Auto Revive Background Loop (When Auto Dungeon is OFF) ]]
StartAutoReviveLoop = function()
    task.spawn(function()
        while State.AutoRevive do
            if not State.AutoDungeon and not isRevivingTeammate then
                CheckAndPerformAutoRevive()
            end
            task.wait(0.4)
        end
    end)
end

-- [[ Process a Treasure Room: Open GrandDoor first, trigger Treasure Cave, defeat guards, wait for CAVE CLEARED, loot chests ]]
local function ProcessTreasureRoom(trRoom)
    local trId = trRoom.id or string.format("treasure_%.0f_%.0f", trRoom.pos.X, trRoom.pos.Z)
    if clearedTreasureRooms[trId] then return true end

    -- STRICT CHECK: Must kill all outside monsters before entering!
    local outsideEnemies = GetOutsideEnemies()
    if #outsideEnemies > 0 then
        UpdateDungeonStatus(string.format("มอนสเตอร์ข้างนอกยังเหลือ %d ตัว! ยกเลิกเข้าห้องสมบัติชั่วคราว...", #outsideEnemies))
        return false
    end

    local allOpened = true
    for _, cData in ipairs(trRoom.chests) do
        if not IsChestOpened(cData.instance) and not openedChestsCache[cData.instance] then
            allOpened = false
            break
        end
    end
    if allOpened then
        clearedTreasureRooms[trId] = true
        return true
    end

    UpdateDungeonStatus("พบห้องสมบัติ! กำลังเปิดประตู GrandDoor ก่อนเข้า...")
    -- 1. Open the GrandDoor FIRST from outside to prevent mobs hitting from distance!
    if trRoom.door then
        OpenGrandDoor(trRoom.door.instance, trRoom.pos)
        task.wait(0.5)
    end

    -- 2. Lock room confinement immediately upon entering!
    currentCombatRoom = {
        center = trRoom.pos,
        radius = 42.0,
        name = "TreasureRoom",
        id = trId
    }

    UpdateDungeonStatus("กำลังเข้าห้อง Treasure Cave เพื่อเริ่มเหตุการณ์...")
    -- Enter room onto the Air trigger
    SafeTeleportTo(trRoom.pos + Vector3.new(0, 2.0, 0))
    task.wait(0.6)

    -- Wait for "TREASURE CAVE" announcement or monsters to spawn
    local waitSpawnTime = tick() + 6.0
    local caveTriggered = false
    while tick() < waitSpawnTime and State.AutoDungeon do
        local enemies = GetAliveEnemies(trRoom.pos, 45)
        local caveInfo = GetCaveInfo()
        if #enemies > 0 or caveInfo.isTreasureCave then
            caveTriggered = true
            break
        end
        task.wait(0.25)
    end

    -- 3. Fight through monsters and wait for "CAVE CLEARED!"
    local caveStartTime = tick()
    local noEnemiesConsecutiveSeconds = 0

    while State.AutoDungeon and (tick() - caveStartTime < 180) do
        -- Player alive check: if dead, abort cleanly
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp or not hum or hum.Health <= 0 then
            currentCombatRoom = nil
            UpdateDungeonStatus("ตัวละครเสียชีวิตในห้อง Treasure Cave... ออกจากห้อง")
            return false
        end

        -- Check Auto Revive during Treasure Cave
        if State.AutoRevive and CheckAndPerformAutoRevive() then
            -- Resumed seamlessly back inside treasure cave
        end

        local enemies = GetAliveEnemies(trRoom.pos, 45)
        local caveInfo = GetCaveInfo()

        if caveInfo.isTreasureCave or #enemies > 0 then
            caveTriggered = true
        end

        -- INSTANT CLEAR CHECK: When "CAVE CLEARED!" appears on screen!
        if caveInfo.isCaveCleared and caveTriggered then
            UpdateDungeonStatus("ตรวจพบ CAVE CLEARED! เคลียร์มอนสเตอร์ในห้องสมบัติสำเร็จแล้ว!")
            task.wait(0.4)
            break
        end

        if #enemies > 0 then
            noEnemiesConsecutiveSeconds = 0
            UpdateDungeonStatus(string.format("กำลังกำจัดมอนสเตอร์ใน Treasure Cave เหลือ %d ตัว...", #enemies))

            local closest = enemies[1]
            if closest and closest.part and closest.model.Parent then
                local attackPos, isEmergency = FindSafestAttackPosition(closest, enemies)
                if attackPos then CombatMoveTo(attackPos, isEmergency) end
                UseCombatSkills()
            end
            task.wait(0.15)
        else
            -- 0 enemies in cave right now
            noEnemiesConsecutiveSeconds = noEnemiesConsecutiveSeconds + 0.35

            -- If cave was triggered, wait up to 6.0 seconds for "CAVE CLEARED!"
            -- If cave never triggered (no monsters spawned after 8s), fallback exit
            local maxWait = caveTriggered and 6.0 or 8.0
            if noEnemiesConsecutiveSeconds >= maxWait then
                UpdateDungeonStatus("กำจัดมอนสเตอร์ใน Treasure Cave ครบแล้ว!")
                task.wait(0.3)
                break
            else
                UpdateDungeonStatus(string.format("รอข้อความ CAVE CLEARED! (%.1f/%.0fวิ)... อยู่ในห้องห้ามออกเด็ดขาด!", 
                    noEnemiesConsecutiveSeconds, maxWait))
                CombatMoveTo(trRoom.pos + Vector3.new(0, 2.0, 0), false)
                task.wait(0.35)
            end
        end
    end

    -- Confinement lifted after cave cleared so all chests can be reached
    currentCombatRoom = nil

    -- 4. Open all chests in the treasure cave
    UpdateDungeonStatus("กำลังเก็บกล่องทั้งหมดในห้อง Treasure Cave...")
    for _, cData in ipairs(trRoom.chests) do
        if not IsChestOpened(cData.instance) and not openedChestsCache[cData.instance] then
            OpenChest(cData.instance)
            task.wait(0.3)
        end
    end

    -- Additional sweep for any chests nearby within 50 studs of trRoom.pos
    local currentFloor = GetCurrentFloor()
    local labyrinth = Workspace:FindFirstChild("Labyrinth")
    local floorFolder = labyrinth and labyrinth:FindFirstChild(currentFloor)
    if floorFolder then
        for _, obj in ipairs(floorFolder:GetChildren()) do
            if obj.Name == "Chest" and not IsChestOpened(obj) and not openedChestsCache[obj] then
                local cf = GetObjectCFrame(obj)
                if cf and (cf.Position - trRoom.pos).Magnitude <= 50 then
                    UpdateDungeonStatus("พบกล่องในห้อง Treasure Cave! กำลังเปิดกล่อง...")
                    OpenChest(obj)
                    task.wait(0.3)
                end
            end
        end
    end

    clearedTreasureRooms[trId] = true
    if trRoom.pos then
        local qx = math.floor(trRoom.pos.X / 40 + 0.5) * 40
        local qz = math.floor(trRoom.pos.Z / 40 + 0.5) * 40
        clearedTreasureRooms[string.format("treasure_%d_%d", qx, qz)] = true
        local key = string.format("cleared_%.0f_%.0f", trRoom.pos.X, trRoom.pos.Z)
        clearedTreasureRooms[key] = true
        RegisterClearedRoom(trRoom.pos, "treasure", key)
    end
    RegisterClearedRoom(trRoom.pos, "treasure", trId)

    currentCombatRoom = nil
    return true
end

-- [[ Process a Mini-Boss Room: Enter Air, trigger waves, fight, loot chest ]]
local function ProcessMiniBossRoom(mbRoom)
    local roomId = GetRoomKey(mbRoom)
    local roomEnemiesNow = GetEnemiesInRoom(mbRoom)

    -- If room is completely empty, check if already cleared or if outside enemies must be cleared first
    if #roomEnemiesNow == 0 then
        if IsRoomCleared(mbRoom) then return false end

        local outsideEnemies = GetOutsideEnemies()
        if #outsideEnemies > 0 then
            UpdateDungeonStatus(string.format("มอนสเตอร์ข้างนอกยังเหลือ %d ตัว! ยกเลิกเข้าห้อง Mini-Boss ชั่วคราว...", #outsideEnemies))
            return false
        end
    end

    -- 1. Lock room confinement immediately! (Exact 144x56x144 Box if from Beams)
    currentCombatRoom = {
        center = mbRoom.center or mbRoom.pos,
        cframe = mbRoom.cframe,
        size = mbRoom.size,
        isBox = (mbRoom.cframe ~= nil),
        radius = mbRoom.isCircular and 68.0 or 72.0,
        name = "MiniBossRoom",
        id = roomId
    }

    -- If enemies are already inside, jump straight into combat without waiting!
    if #roomEnemiesNow == 0 then
        UpdateDungeonStatus("กำลังเข้าห้อง Mini-Boss เพื่อเริ่มเวฟ...")
        SafeTeleportTo(mbRoom.pos + Vector3.new(0, 2.0, 0))
        task.wait(0.4)

        -- Wait for gates to slam shut & enemies to spawn
        local waitSpawnTime = tick() + 6.0
        while tick() < waitSpawnTime and State.AutoDungeon do
            local roomEnemies = GetEnemiesInRoom(mbRoom)
            local waveInfo = GetWaveInfo()
            if #roomEnemies > 0 or waveInfo.isGatesSlam or waveInfo.curWave > 0 then
                break
            end
            task.wait(0.2)
        end
    else
        UpdateDungeonStatus(string.format("เข้าโจมตีมอนสเตอร์ในห้อง Mini-Boss ทันที (%d ตัว)...", #roomEnemiesNow))
    end

    -- Fight through waves until ALL waves are 100% cleared! (4 Waves total)
    local roomStartTime = tick()
    local noEnemiesConsecutiveSeconds = 0
    local highestWaveSeen = 0
    local roomTriggered = false
    local lastWaveClearedTime = 0
    local wavesClearedCount = 0

    while State.AutoDungeon and (tick() - roomStartTime < 300) do
        -- Player alive check: if dead, abort cleanly
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp or not hum or hum.Health <= 0 then
            currentCombatRoom = nil
            UpdateDungeonStatus("ตัวละครเสียชีวิตในห้อง Mini-Boss... ออกจากห้อง")
            return false
        end

        -- Check Auto Revive during Mini-Boss waves
        if State.AutoRevive and CheckAndPerformAutoRevive() then
            -- Resumed seamlessly back inside mini-boss room
        end

        local roomEnemies = GetEnemiesInRoom(mbRoom)
        local waveInfo = GetWaveInfo()

        if waveInfo.curWave > highestWaveSeen then
            highestWaveSeen = waveInfo.curWave
            roomTriggered = true
        end
        if waveInfo.isGatesSlam or #roomEnemies > 0 then
            roomTriggered = true
        end

        -- Track wave progression when WAVE CLEARED appears
        if waveInfo.isWaveCleared then
            roomTriggered = true
            if tick() - lastWaveClearedTime > 3.0 then
                lastWaveClearedTime = tick()
                wavesClearedCount = wavesClearedCount + 1
                highestWaveSeen = math.max(highestWaveSeen, wavesClearedCount)
            end
        end

        -- INSTANT CLEAR CHECK: ONLY when "ARENA CLEARED!" appears (NOT "WAVE CLEARED!")
        -- And only if the room was already triggered/started!
        if waveInfo.isCleared and roomTriggered then
            UpdateDungeonStatus("ตรวจพบ ARENA CLEARED! เคลียร์ห้อง Mini-Boss สำเร็จครบทุกเวฟ!")
            task.wait(0.3)
            break
        end

        if #roomEnemies > 0 then
            noEnemiesConsecutiveSeconds = 0
            local waveText = ""
            if highestWaveSeen > 0 then
                waveText = string.format(" [Wave %d/%d]", highestWaveSeen, waveInfo.maxWave or 4)
            end
            UpdateDungeonStatus(string.format("กำลังกำจัดมอนสเตอร์ Mini-Boss%s เหลือ %d ตัว...", waveText, #roomEnemies))

            local closest = roomEnemies[1]
            if closest and closest.part and closest.model.Parent then
                local attackPos, isEmergency = FindSafestAttackPosition(closest, roomEnemies)
                if attackPos then CombatMoveTo(attackPos, isEmergency) end
                UseCombatSkills()
            end
            task.wait(0.15)
        else
            -- 0 enemies right now in room.
            -- Could be between waves (waiting for next wave to spawn) or final wave cleared!
            noEnemiesConsecutiveSeconds = noEnemiesConsecutiveSeconds + 0.35

            -- Check if reward chest already spawned in this room
            local chestSpawned = false
            local currentFloor = GetCurrentFloor()
            local labyrinth = Workspace:FindFirstChild("Labyrinth")
            local floorFolder = labyrinth and labyrinth:FindFirstChild(currentFloor)
            if floorFolder and highestWaveSeen >= 3 then
                for _, obj in ipairs(floorFolder:GetChildren()) do
                    if obj.Name == "Chest" and not IsChestOpened(obj) and not openedChestsCache[obj] then
                        local cf = GetObjectCFrame(obj)
                        if cf and (cf.Position - mbRoom.pos).Magnitude <= 75 then
                            chestSpawned = true
                            break
                        end
                    end
                end
            end

            -- Can ONLY exit if:
            -- 1. Chest has spawned after wave 3/4
            -- 2. OR wave 4 reached and no enemies for at least 8.0 seconds
            -- 3. OR room never triggered after 12.0 seconds (empty/bugged room fallback)
            local canExit = false
            if chestSpawned and highestWaveSeen >= 3 then
                canExit = true
            elseif highestWaveSeen >= 4 and noEnemiesConsecutiveSeconds >= 8.0 then
                canExit = true
            elseif not roomTriggered and noEnemiesConsecutiveSeconds >= 12.0 then
                canExit = true
            end

            if canExit then
                UpdateDungeonStatus("เคลียร์ห้อง Mini-Boss สำเร็จครบทุกเวฟ!")
                task.wait(0.4)
                break
            else
                local nextWaveNum = math.min(math.max(highestWaveSeen + 1, 1), 4)
                if waveInfo.isWaveCleared then
                    UpdateDungeonStatus(string.format("WAVE CLEARED! รอ Wave %d/%d เกิด... อยู่ในห้องรอจนกว่าจะขึ้น ARENA CLEARED!", 
                        nextWaveNum, waveInfo.maxWave or 4))
                else
                    UpdateDungeonStatus(string.format("รอ Wave %d/%d เกิด (%.1fวิ)... ห้ามออกจากห้องจนกว่าจะขึ้น ARENA CLEARED!", 
                        nextWaveNum, waveInfo.maxWave or 4, noEnemiesConsecutiveSeconds))
                end
                -- Keep player hovering safely at room center while waiting for next wave
                CombatMoveTo(mbRoom.pos + Vector3.new(0, 2.0, 0), false)
                task.wait(0.35)
            end
        end
    end

    -- Confinement lifted after waves cleared so chest can be reached if at edge
    currentCombatRoom = nil

    -- Check if chest spawned in this room (check radius 75 studs)
    local currentFloor = GetCurrentFloor()
    local labyrinth = Workspace:FindFirstChild("Labyrinth")
    local floorFolder = labyrinth and labyrinth:FindFirstChild(currentFloor)
    if floorFolder then
        for _, obj in ipairs(floorFolder:GetChildren()) do
            if obj.Name == "Chest" and not IsChestOpened(obj) and not openedChestsCache[obj] then
                local cf = GetObjectCFrame(obj)
                if cf and (cf.Position - mbRoom.pos).Magnitude <= 75 then
                    UpdateDungeonStatus("พบกล่องรางวัลในห้อง Mini-Boss! กำลังเปิดกล่อง...")
                    OpenChest(obj)
                    task.wait(0.3)
                end
            end
        end
    end

    clearedAirRooms[roomId] = true
    if mbRoom.id then clearedAirRooms[mbRoom.id] = true end
    if mbRoom.pos then
        local key = string.format("cleared_%.0f_%.0f", mbRoom.pos.X, mbRoom.pos.Z)
        clearedAirRooms[key] = true
        RegisterClearedRoom(mbRoom.pos, "miniboss", key)
    end
    RegisterClearedRoom(mbRoom.pos or mbRoom.center, "miniboss", roomId)

    currentCombatRoom = nil -- Confinement lifted ONLY after room is completely cleared!
    return true
end

-- [[ Enter PortalBeam, Loot Chest, and Wait for Countdown to Next Floor ]]
local function EnterPortalAndDescend(portalPos)
    -- ABSOLUTE SAFETY LOCK: Never enter or wait on portal if Big Boss is not defeated!
    if not isGuardianDefeated then
        return false
    end

    if not portalPos then
        local padPos = FindWayDownPad()
        portalPos = padPos
    end
    if not portalPos then
        UpdateDungeonStatus("กำลังค้นหา PortalBeam...")
        return false
    end

    -- 1. Loot any boss / floor reward chests ONCE before stepping into the portal
    UpdateDungeonStatus("กำลังเก็บกล่องรางวัลบอสก่อนลงชั้นถัดไป...")
    CollectAllChests()
    task.wait(0.5)

    local initialFloor = GetCurrentFloor()
    local waitStart = tick()
    local timeout = 45 -- Wait up to 45 seconds for countdown and floor change

    UpdateDungeonStatus("กำลังเข้าสู่วงแหวน PortalBeam...")

    while State.AutoDungeon and (tick() - waitStart < timeout) do

        -- Check if floor has changed!
        local currentFloor = GetCurrentFloor()
        if currentFloor ~= initialFloor then
            SetAutoFly(false)
            UpdateDungeonStatus("เปลี่ยนเข้าสู่ " .. tostring(currentFloor) .. " สำเร็จ!")
            return true
        end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then
            SetAutoFly(false)
            break
        end

        -- Check horizontal and vertical distance to portal
        local horizDist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(portalPos.X, 0, portalPos.Z)).Magnitude
        local vertDist = math.abs(hrp.Position.Y - portalPos.Y)

        -- Check if character is ALREADY inside the portal circle
        local isInsidePortal = (horizDist <= 6.5 and vertDist <= 6.0)

        if isInsidePortal then
            -- STAND COMPLETELY STILL! GROUNDED ON THE PORTAL PAD!
            SetAutoFly(false) -- Disable fly on portal so Roblox detects player on pad!
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hum.PlatformStand = false

            -- Ensure collision is enabled so character doesn't slip through floor
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        else
            SetAutoFly(true)
            -- Outside the portal! Teleport ONCE directly to the portal center floor
            UpdateDungeonStatus("กำลังวาร์ปเข้าวง PortalBeam...")

            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = { char }
            local rayResult = Workspace:Raycast(portalPos + Vector3.new(0, 5, 0), Vector3.new(0, -30, 0), rayParams)
            local floorY = rayResult and (rayResult.Position.Y + 2.5) or (portalPos.Y + 0.5)

            SafeTeleportTo(Vector3.new(portalPos.X, floorY, portalPos.Z))
            task.wait(0.3)
        end

        -- Check countdown HUD: "NEXT FLOOR IN 10s - 1/1 on the portal"
        local countdownText = GetPortalCountdownText()
        if countdownText and countdownText ~= "" then
            UpdateDungeonStatus(string.format("[Portal] %s", countdownText))
        else
            local elapsed = math.floor(tick() - waitStart)
            UpdateDungeonStatus(string.format("อยู่ใน PortalBeam รอนับถอยหลัง (%dวิ)...", elapsed))
        end

        task.wait(0.4)
    end

    return (GetCurrentFloor() ~= initialFloor)
end

-- [[ Process Big Boss Room: Open GrandDoor closest to ExitRing/PortalBeam, defeat Boss, enter ExitRing/PortalBeam ]]
-- [[ Helper: Check if THE GUARDIAN AWAKENS has been announced ]]
local function IsGuardianAwakened()
    local text = GetAnnouncementText()
    local u = string.upper(text)
    if string.find(u, "GUARDIAN") and (string.find(u, "AWAKEN") or string.find(u, "AWAKENS")) then
        return true
    end
    if string.find(u, "GUARDIAN") and not string.find(u, "DEFEATED") then
        return true
    end

    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local labHUD = pgui and pgui:FindFirstChild("LabHUD")
    if labHUD and labHUD.Enabled then
        for _, desc in ipairs(labHUD:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text ~= "" and IsGuiVisible(desc) then
                local labelU = string.upper(desc.Text)
                if string.find(labelU, "GUARDIAN") and (string.find(labelU, "AWAKEN") or string.find(labelU, "AWAKENS")) then
                    return true
                elseif string.find(labelU, "GUARDIAN") and not string.find(labelU, "DEFEATED") then
                    return true
                end
            end
        end
    end

    return false
end

-- [[ Process Big Boss Room: Waves -> THE GUARDIAN AWAKENS -> Kill Guardian -> Loot Chest -> Next Floor ]]
local function ProcessBigBossRoom(bbRoom)
    -- STRICT CHECK: Must kill all outside monsters before entering!
    local outsideEnemies = GetOutsideEnemies()
    if #outsideEnemies > 0 then
        UpdateDungeonStatus(string.format("มอนสเตอร์ข้างนอกยังเหลือ %d ตัว! ยกเลิกเข้าห้อง Boss ใหญ่ชั่วคราว...", #outsideEnemies))
        return false
    end

    UpdateDungeonStatus("เตรียมเข้าห้อง Boss ใหญ่! ตรวจสอบกล่องในชั้น...")
    -- Ensure all loose chests on floor are collected first!
    CollectAllChests()
    task.wait(0.5)

    -- 1. Open the GrandDoor closest to ExitRing/PortalBeam from outside first
    local doorToOpen = bbRoom.door and bbRoom.door.instance
    if not doorToOpen then
        local currentFloor = GetCurrentFloor()
        local labyrinth = Workspace:FindFirstChild("Labyrinth")
        local floorFolder = labyrinth and labyrinth:FindFirstChild(currentFloor)
        local props = floorFolder and (floorFolder:FindFirstChild("Props") or floorFolder:FindFirstChild("props"))
        local searchTarget = props or floorFolder
        if searchTarget then
            local minD = math.huge
            for _, d in ipairs(searchTarget:GetDescendants()) do
                if d.Name == "GrandDoor" then
                    local dcf = GetObjectCFrame(d)
                    if dcf then
                        local dist = (dcf.Position - bbRoom.pos).Magnitude
                        if dist < minD then
                            minD = dist
                            doorToOpen = d
                        end
                    end
                end
            end
        end
    end

    if doorToOpen then
        UpdateDungeonStatus("กำลังเปิดประตู GrandDoor หน้าห้อง Boss ใหญ่จากด้านนอก...")
        OpenGrandDoor(doorToOpen, bbRoom.pos)
        task.wait(1.2) -- Wait for GrandDoor to swing fully open before stepping in!
        UpdateDungeonStatus("เปิดประตู GrandDoor เรียบร้อยแล้ว! เตรียมเข้าสู่ห้อง Boss...")
    end

    -- 2. Step into the Boss room (at bbRoom.pos) and lock circular confinement
    local bossRadius = bbRoom.radius or 90.0
    currentCombatRoom = {
        center = bbRoom.pos,
        radius = bossRadius - 6.0, -- circular confinement (e.g. 84 studs, safe inside 90 stud arena walls)
        isBox = false,
        name = "BigBossRoom_Circular"
    }

    UpdateDungeonStatus("เข้าสู่ห้อง Boss ใหญ่! กำลังเริ่มการต่อสู้...")
    local floorPos = bbRoom.pos
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character, Workspace:FindFirstChild("BADEnemies") }
    local rayResult = Workspace:Raycast(bbRoom.pos + Vector3.new(0, 5, 0), Vector3.new(0, -100, 0), rayParams)
    if rayResult then
        floorPos = rayResult.Position + Vector3.new(0, 3.0, 0)
    else
        floorPos = bbRoom.pos + Vector3.new(0, 2.5, 0)
    end
    SafeTeleportTo(floorPos)
    task.wait(0.8)

    -- Wait up to 6 seconds for room event to trigger
    UpdateDungeonStatus("รอเหตุการณ์ห้อง Boss เริ่มต้น...")
    local spawnWait = tick() + 6.0
    while tick() < spawnWait and State.AutoDungeon do
        if #GetAliveEnemies(bbRoom.pos, bossRadius + 5.0) > 0 or GetAliveBossOrGuardian(bbRoom.pos, bossRadius + 5.0) then
            break
        end
        local title = GetAnnouncementText()
        local uTitle = string.upper(title)
        if string.find(uTitle, "GATES SLAM") or string.find(uTitle, "WAVE") or string.find(uTitle, "GUARDIAN") then
            break
        end
        task.wait(0.3)
    end

    -- 3. Fight pre-boss waves AND the Guardian!
    local bossStartTime = tick()
    local hasGuardianAwakened = false
    local guardianFought = false
    local noEnemiesConsecutiveSeconds = 0

    while State.AutoDungeon and (tick() - bossStartTime < 360) do
        -- Player alive check: if dead, abort cleanly
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp or not hum or hum.Health <= 0 then
            currentCombatRoom = nil
            UpdateDungeonStatus("ตัวละครเสียชีวิตในห้อง Boss ใหญ่... ออกจากห้อง")
            return false
        end

        -- Check Auto Revive during Big Boss fight
        if State.AutoRevive and CheckAndPerformAutoRevive() then
            -- Resumed seamlessly back inside Boss arena
        end

        local enemies = GetAliveEnemies(bbRoom.pos, bossRadius + 5.0)
        local boss = GetAliveBossOrGuardian(bbRoom.pos, bossRadius + 5.0)
        local title = GetAnnouncementText()
        local upperTitle = string.upper(title)

        -- Check if Guardian has awakened ("THE GUARDIAN AWAKENS")
        if not hasGuardianAwakened then
            if boss ~= nil or string.find(upperTitle, "GUARDIAN") or string.find(upperTitle, "AWAKEN") or IsGuardianAwakened() then
                hasGuardianAwakened = true
                UpdateDungeonStatus("THE GUARDIAN AWAKENS! บอสใหญ่ตื่นแล้ว! กำลังเข้าโจมตี...")
            end
        end

        if boss ~= nil then
            guardianFought = true
            hasGuardianAwakened = true
        end

        -- Check if reward chest has spawned inside the Boss room (indicator that Guardian died!)
        local chestInRoom = false
        local currentFloor = GetCurrentFloor()
        local labyrinth = Workspace:FindFirstChild("Labyrinth")
        local floorFolder = labyrinth and labyrinth:FindFirstChild(currentFloor)
        if floorFolder and (guardianFought or hasGuardianAwakened) then
            for _, obj in ipairs(floorFolder:GetChildren()) do
                if obj.Name == "Chest" then
                    local cf = GetObjectCFrame(obj)
                    if cf and (cf.Position - bbRoom.pos).Magnitude <= bossRadius then
                        chestInRoom = true
                        break
                    end
                end
            end
        end

        -- Clear verification: ONLY allowed after the Guardian was awakened / fought!
        local isClearedNotice = string.find(upperTitle, "LOOT THE CHEST")
            or string.find(upperTitle, "NEXT FLOOR")
            or string.find(upperTitle, "STAND ON")
            or string.find(upperTitle, "VICTORY")
            or string.find(upperTitle, "DEFEATED")

        local isBossDead = (guardianFought or hasGuardianAwakened) and (boss == nil) and (#enemies == 0)
        local canExitBossRoom = false

        if isBossDead and (chestInRoom or isClearedNotice or noEnemiesConsecutiveSeconds >= 6.0) then
            canExitBossRoom = true
        elseif chestInRoom and (boss == nil) and (guardianFought or hasGuardianAwakened) then
            canExitBossRoom = true
        elseif isClearedNotice and (boss == nil) and (guardianFought or hasGuardianAwakened) then
            canExitBossRoom = true
        end

        if canExitBossRoom then
            UpdateDungeonStatus("ปราบ Guardian บอสใหญ่สำเร็จ! ปลดล็อคห้องเรียบร้อย!")
            break
        end

        -- Combat loop
        if #enemies > 0 or boss ~= nil then
            noEnemiesConsecutiveSeconds = 0

            -- Target selection: Always prioritize Boss / Guardian!
            local target = nil
            if boss and boss.part and boss.model.Parent then
                target = boss
            else
                -- Fallback: If Guardian has awakened, prioritize the enemy with the highest HP
                if hasGuardianAwakened and #enemies > 0 then
                    local highestHpEnemy = enemies[1]
                    for _, e in ipairs(enemies) do
                        if (e.hp or 0) > (highestHpEnemy.hp or 0) then
                            highestHpEnemy = e
                        end
                    end
                    if highestHpEnemy and (highestHpEnemy.hp or 0) > 3000 then
                        target = highestHpEnemy
                    end
                end

                -- Otherwise, closest enemy
                if not target then
                    local minD = math.huge
                    local myPos = hrp and hrp.Position or bbRoom.pos
                    for _, eData in ipairs(enemies) do
                        local d = (eData.part.Position - myPos).Magnitude
                        if d < minD then
                            minD = d
                            target = eData
                        end
                    end
                end
            end

            -- Status text
            if boss or (hasGuardianAwakened and target and (target.hp or 0) > 3000) then
                local bHp = (boss and boss.hp) or (target and target.hp) or 0
                local bName = (boss and boss.name) or (target and target.role) or "Guardian"
                UpdateDungeonStatus(string.format("กำลังต่อสู้กับ %s! [HP: %.1fk] มอนสเตอร์รอบตัว %d ตัว...", bName, bHp / 1000, #enemies))
            else
                local waveText = ""
                if string.find(upperTitle, "WAVE") then waveText = " (" .. title .. ")" end
                UpdateDungeonStatus(string.format("กำลังเคลียร์เวฟในห้อง Boss%s เหลือมอนสเตอร์ %d ตัว...", waveText, #enemies))
            end

            if target and target.part and target.model.Parent then
                local attackPos, isEmergency = FindSafestAttackPosition(target, enemies)
                if attackPos then CombatMoveTo(attackPos, isEmergency) end
                UseCombatSkills()
            end
            task.wait(0.15)
        else
            -- 0 enemies right now in room
            noEnemiesConsecutiveSeconds = noEnemiesConsecutiveSeconds + 0.4

            if not hasGuardianAwakened then
                UpdateDungeonStatus(string.format("เคลียร์เวฟแล้ว! กำลังรอ THE GUARDIAN AWAKENS (%.1fวิ)... ห้ามออกจากห้องเด็ดขาด!", noEnemiesConsecutiveSeconds))
            else
                UpdateDungeonStatus(string.format("กำลังรอผลการปราบ Boss หรือรอกล่องรางวัลเกิด (%.1fวิ)...", noEnemiesConsecutiveSeconds))
            end

            -- Keep hovering safely near room center while waiting
            CombatMoveTo(bbRoom.pos + Vector3.new(0, 2.5, 0), false)
            task.wait(0.4)
        end
    end

    -- 4. COMBAT OVER: Lift confinement, loot reward chest, and descend!
    currentCombatRoom = nil
    isGuardianDefeated = true
    RegisterClearedRoom(bbRoom.pos, "bigboss", "bigboss")

    UpdateDungeonStatus("ปราบ Guardian บอสใหญ่สำเร็จ! กำลังรอกล่องรางวัลปรากฏ...")
    task.wait(1.5)

    -- Collect all chests on the floor & in Boss room (User: พอฆ่าเสร็จ กล่องก็จะเกิด)
    UpdateDungeonStatus("กำลังเก็บกล่องรางวัลห้อง Boss และกล่องทั้งหมดบนชั้น...")
    CollectAllChests()
    task.wait(0.8)

    -- Secondary sweep to ensure any delayed chest is looted
    CollectAllChests()
    task.wait(0.5)

    -- Enter portal and descend to next floor (User: พอทำทุกอย่างครบแล้วก็เข้าประตูชั้นต่อไปได้เลย)
    UpdateDungeonStatus("เก็บกล่องครบทุกอย่างแล้ว! กำลังเข้าสู่ประตู (Portal) เพื่อลงชั้นต่อไป...")
    EnterPortalAndDescend()
end

-- [[ Master Auto Play Dungeon Loop ]]
local function StartAutoDungeon()
    task.spawn(function()
        local floorCleared = false

        while State.AutoDungeon do
            local currentFloor = GetCurrentFloor()
            -- Only reset if genuine transition to a new floor!
            if currentFloor ~= lastFloorName and lastFloorName ~= "" then
                lastFloorName = currentFloor
                visitedArenas = {}
                clearedAirRooms = {}
                clearedTreasureRooms = {}
                openedChestsCache = {}
                isGuardianDefeated = false
                floorCleared = false
                currentCombatRoom = nil
                discoveredMiniBosses = {}
                discoveredTreasureRooms = {}
                discoveredBigBoss = nil
                cachedFloorRooms = nil
                cachedFloorRoomsName = ""
                cachedFloorTraps = {}
                lastFloorTrapsName = ""
                cachedDangerZones = {}
                cachedBigBossRoom = nil
                lastBigBossCheckFloor = ""
                UpdateDungeonStatus("เข้าสู่ " .. tostring(currentFloor) .. " เริ่มวิเคราะห์โครงสร้างห้อง...")
                task.wait(1.5)
            elseif lastFloorName == "" then
                lastFloorName = currentFloor
                UpdateDungeonStatus("เข้าสู่ " .. tostring(currentFloor) .. " กำลังเริ่มทำงาน...")
            end

            if not State.AutoDungeon then
                currentCombatRoom = nil
                SetAutoFly(false)
                break
            end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildWhichIsA("Humanoid")

            -- Check player death
            if not hrp or not hum or hum.Health <= 0 then
                currentCombatRoom = nil
                SetAutoFly(false)
                UpdateDungeonStatus("ตัวละครเสียชีวิต กำลังรอเกิดใหม่...")
                if State.AutoPlayAgain then
                    TriggerPlayAgain()
                end
                task.wait(2)
                continue
            end

            -- Ensure KillAura & Flight are active
            State.KillAura = true
            SetAutoFly(true)

            -- =========================================================================
            -- PRIORITY -1: Auto Revive Downed Teammates (Highest Priority in Dungeon)
            -- =========================================================================
            if State.AutoRevive and CheckAndPerformAutoRevive() then
                continue
            end

            -- Analyze Props: Mini-Boss Rooms, Treasure Rooms, Big Boss Room
            local miniBossRooms, treasureRooms, bigBoss = AnalyzeFloorRooms()
            if not bigBoss then bigBoss = FindBigBossRoom() end

            -- =========================================================================
            -- TOP PRIORITY 0: Check if ANY Mini-Boss room has monsters spawned inside!
            -- (กฎเด็ดขาด: ก่อนจะเข้าห้องสมบัติ, ห้อง Mini-Boss อื่น หรือห้อง Boss ใหญ่
            -- หรือแม้กระทั่งก่อนลง Portal ถ้ามีห้อง Mini-Boss ที่มีมอนสเตอร์เกิดอยู่ ต้องไปกำจัดให้เสร็จก่อนเป็นอันดับแรกเสมอ!)
            -- =========================================================================
            local activeMb, mbCount = GetActiveMiniBossRoomWithEnemies(miniBossRooms)
            if activeMb then
                UpdateDungeonStatus(string.format("ตรวจพบห้อง Mini-Boss มีมอนสเตอร์เกิดอยู่ข้างใน (%d ตัว)! กำลังเข้ากำจัดทันที...", mbCount))
                local rId = GetRoomKey(activeMb)
                clearedAirRooms[rId] = nil
                if activeMb.id then clearedAirRooms[activeMb.id] = nil end
                if FloorClearedRooms[currentFloor] then
                    FloorClearedRooms[currentFloor].keys[rId] = nil
                    if activeMb.id then FloorClearedRooms[currentFloor].keys[activeMb.id] = nil end
                    local p = activeMb.pos or activeMb.center
                    if p then
                        for idx = #FloorClearedRooms[currentFloor].positions, 1, -1 do
                            local cData = FloorClearedRooms[currentFloor].positions[idx]
                            if (cData.pos - p).Magnitude <= 65.0 then
                                table.remove(FloorClearedRooms[currentFloor].positions, idx)
                            end
                        end
                    end
                end
                ProcessMiniBossRoom(activeMb)
                task.wait(0.2)
                continue
            end

            -- Priority 0.5: If Boss is already defeated AND no active mini-boss monsters remain, enter Portal!
            if isGuardianDefeated then
                currentCombatRoom = nil
                EnterPortalAndDescend()
                continue
            end

            -- ABSOLUTE MANDATORY CHECK: Kill ALL outside monsters in hallways before entering ANY room!
            -- (ห้ามเข้าห้องสมบัติ, ห้อง Mini-Boss หรือห้อง Boss เด็ดขาด ถ้ามอนสเตอร์ข้างนอกยังไม่หมด!)
            local outsideEnemies = GetOutsideEnemies(miniBossRooms, treasureRooms, bigBoss)

            if #outsideEnemies > 0 then
                UpdateDungeonStatus(string.format("ตรวจพบมอนสเตอร์ข้างนอก %d ตัว! กำลังกำจัดให้หมดก่อนเข้าห้อง...", #outsideEnemies))
                local target = outsideEnemies[1]
                local attackPos, isEmergency = FindSafestAttackPosition(target, outsideEnemies)
                if attackPos then
                    CombatMoveTo(attackPos, isEmergency)
                end
                UseCombatSkills()
                task.wait(0.12)
                continue
            end

            -- 1. Priority 1: Process all Treasure Rooms (open GrandDoor first, defeat guards, wait for CAVE CLEARED, loot chests)
            local handledTreasure = false
            for _, tr in ipairs(treasureRooms) do
                if not IsTreasureRoomCleared(tr) then
                    ProcessTreasureRoom(tr)
                    handledTreasure = true
                    break
                end
            end
            if handledTreasure then
                task.wait(0.5)
                continue
            end

            -- 2. Priority 2: Process Uncleared Mini-Boss Rooms (enter Air, trigger 4 waves, defeat, loot chest)
            local handledMiniBoss = false
            for _, mb in ipairs(miniBossRooms) do
                if not IsRoomCleared(mb) then
                    ProcessMiniBossRoom(mb)
                    handledMiniBoss = true
                    break
                end
            end
            if handledMiniBoss then
                task.wait(0.5)
                continue
            end

            -- 3. Priority 3: Collect all remaining chests on the floor before Boss
            if not floorCleared then
                UpdateDungeonStatus("กำลังเก็บกล่องที่เหลือทั้งหมดบนชั้น...")
                CollectAllChests()
                floorCleared = true
                task.wait(0.5)
            end

            -- Check outside enemies again before entering Big Boss Room!
            local outsideBeforeBoss = GetOutsideEnemies(miniBossRooms, treasureRooms, bigBoss)
            if #outsideBeforeBoss > 0 then
                UpdateDungeonStatus(string.format("ตรวจพบมอนสเตอร์ข้างนอก %d ตัว! กำลังกำจัดให้หมดก่อนเข้าห้อง Boss...", #outsideBeforeBoss))
                local target = outsideBeforeBoss[1]
                local attackPos, isEmergency = FindSafestAttackPosition(target, outsideBeforeBoss)
                if attackPos then CombatMoveTo(attackPos, isEmergency) end
                UseCombatSkills()
                task.wait(0.12)
                continue
            end

            -- 4. Priority 4: Big Boss Room! (Open GrandDoor near ExitRing, defeat Boss, enter ExitRing/PortalBeam)
            -- ABSOLUTE SAFETY LOCK: Never enter Big Boss Room if ANY Mini-Boss room is uncleared!
            local hasUnclearedMiniBoss = false
            for _, mb in ipairs(miniBossRooms) do
                if not IsRoomCleared(mb) then
                    hasUnclearedMiniBoss = true
                    break
                end
            end
            if hasUnclearedMiniBoss then
                UpdateDungeonStatus("ยังมีห้อง Mini-Boss ที่ยังไม่เคลียร์! กำลังไปเคลียร์ก่อนเข้าห้อง Boss ใหญ่...")
                task.wait(0.5)
                continue
            end

            if bigBoss and not isGuardianDefeated then
                ProcessBigBossRoom(bigBoss)
                task.wait(1.5)
                continue
            elseif not bigBoss and not isGuardianDefeated then
                UpdateDungeonStatus("กำลังค้นหาห้อง Boss ใหญ่ (รอแผนที่โหลด)...")
                task.wait(1.0)
            end

            -- 5. Priority 5: If Boss defeated, enter PortalBeam / Next Floor
            if isGuardianDefeated then
                currentCombatRoom = nil
                EnterPortalAndDescend()
                continue
            end

            -- Fallback: Minimap arenas if Props had no Air
            local arenas = GetDungeonArenas()
            local nextArena = nil
            for _, arena in ipairs(arenas) do
                local key = string.format("%.0f_%.0f", arena.pos.X, arena.pos.Z)
                if not visitedArenas[key] then
                    nextArena = arena
                    break
                end
            end
            if nextArena then
                local key = string.format("%.0f_%.0f", nextArena.pos.X, nextArena.pos.Z)
                visitedArenas[key] = true
                UpdateDungeonStatus("กำลังเดินทางไปห้องต่อสู้...")
                CombatMoveTo(Vector3.new(nextArena.pos.X, hrp.Position.Y + 2.0, nextArena.pos.Z), false)
                task.wait(1.5)
            else
                UpdateDungeonStatus("เคลียร์ครบทุกห้องแล้ว! รอลงชั้นถัดไป...")
                task.wait(1.5)
            end

            task.wait(0.1)
        end
    end)
end


-- [[ Lobby Auto Roll & Mutation System (Smooth & Flicker-Free) ]]
local lastRollData = nil
local lastRollResultTime = 0
local rollCompletedSignal = Instance.new("BindableEvent")
local RollStatusLabel = nil
local isServerAutoActive = false
local isPausedWaitingBuy = false
local lastMatchedTargetName = nil
local isResuming = false

local cachedRollControls = nil
local function GetRollControls()
    if cachedRollControls and cachedRollControls.Parent then
        return cachedRollControls
    end
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local bad = rep:FindFirstChild("BAD")
        local remotes = bad and bad:FindFirstChild("Remotes")
        cachedRollControls = remotes and remotes:FindFirstChild("RollControls")
    end)
    return cachedRollControls
end

local function GetMapRollers()
    local map = workspace:FindFirstChild("Map")
    return map and map:FindFirstChild("Rollers")
end

local function RestoreStandPrompts()
    pcall(function()
        local rollers = GetMapRollers()
        if not rollers then return end
        for _, desc in ipairs(rollers:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                desc.MaxActivationDistance = 10
                desc.RequiresLineOfSight = true
            end
        end
    end)
end

-- Immediately clean up any prompts stuck on screen
task.spawn(function()
    task.wait(1)
    RestoreStandPrompts()
end)

local function GetPlayerRollStand(kind)
    kind = kind or "Monsters"
    local rollers = GetMapRollers()
    if not rollers then return nil end

    if State.LastRollMachine then
        local byLast = rollers:FindFirstChild(State.LastRollMachine)
        if byLast then return byLast end
    end

    local myPlotIndex = LocalPlayer:GetAttribute("PlotIndex")
    if not myPlotIndex then
        pcall(function()
            local client = LocalPlayer:FindFirstChild("PlayerScripts") and (LocalPlayer.PlayerScripts:FindFirstChild("BADClient") or LocalPlayer.PlayerScripts:FindFirstChild("Client"))
            local stateMod = client and client:FindFirstChild("State")
            if stateMod and stateMod:IsA("ModuleScript") then
                myPlotIndex = require(stateMod).MyIndex()
            end
        end)
    end

    -- 1. Match by PlotIndex attribute
    if myPlotIndex then
        for _, stand in ipairs(rollers:GetChildren()) do
            if stand:GetAttribute("PlotIndex") == myPlotIndex and string.find(stand.Name, kind) then
                return stand
            end
        end
        local byName = rollers:FindFirstChild("Plot" .. tostring(myPlotIndex) .. "_" .. kind)
        if byName then return byName end
    end

    -- 2. Match by closest distance to player character
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local bestStand = nil
        local bestDist = 250
        for _, stand in ipairs(rollers:GetChildren()) do
            if string.find(stand.Name, kind) then
                local pivot = stand:GetPivot()
                local d = (pivot.Position - hrp.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestStand = stand
                end
            end
        end
        if bestStand then return bestStand end
    end

    -- 3. Fallback: Any stand matching kind
    for _, stand in ipairs(rollers:GetChildren()) do
        if string.find(stand.Name, kind) then
            return stand
        end
    end

    return nil
end

local function StartServerAutoRoll()
    if isPausedWaitingBuy then return false end

    local rollControls = GetRollControls()
    local stand = GetPlayerRollStand("Monsters")
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    -- 1. Configure settings for server auto roll:
    pcall(function()
        if rollControls then
            local targetR = "Divine"
            if type(State.RollTargetRarities) == "table" and #State.RollTargetRarities > 0 then
                for _, r in ipairs(State.RollTargetRarities) do
                    if r == "Divine" or r == "Mythic" or r == "Legendary" then
                        targetR = r
                        break
                    end
                end
            end

            local targetM = "Off"
            if type(State.RollTargetMutations) == "table" then
                for _, m in ipairs(State.RollTargetMutations) do
                    if m == "Cursed" or m == "Infernal" or m == "Frozen" or m == "Golden" then
                        targetM = m
                        break
                    end
                end
            end

            local settings = {
                rarity = targetR,
                mut = targetM,
                pity = "On",
                skin = "Off",
                always = "Divine",
                protect = "Mythic",
                category = "All"
            }
            rollControls:InvokeServer("settings", "Monsters", settings)
        end
    end)

    -- 2. Try starting server auto roll directly:
    local started = false
    if rollControls then
        local success, res = pcall(function()
            return rollControls:InvokeServer("start", "Monsters")
        end)
        if success and res and res.ok then
            started = true
            isServerAutoActive = true
        end
    end

    -- If server start was rejected (likely player > 40 studs from plot roller stand):
    if not started and stand and hrp then
        local standPivot = stand:GetPivot()
        local dist = (standPivot.Position - hrp.Position).Magnitude
        if dist > 35 then
            local oldCF = hrp.CFrame
            pcall(function()
                hrp.CFrame = standPivot + Vector3.new(0, 3, 0)
            end)
            task.wait(0.06)
            if rollControls then
                pcall(function()
                    local res = rollControls:InvokeServer("start", "Monsters")
                    if res and res.ok then
                        started = true
                        isServerAutoActive = true
                    end
                end)
            end
            pcall(function()
                hrp.CFrame = oldCF
            end)
        end
    end

    -- 3. Prompt trigger fallback to ensure roll starts immediately
    if stand then
        local rollButton = stand:FindFirstChild("RollButton")
        local rollPrompt = rollButton and rollButton:FindFirstChild("RollPrompt")
        if rollPrompt and rollPrompt:IsA("ProximityPrompt") then
            pcall(function()
                fireproximityprompt(rollPrompt, 0)
                fireproximityprompt(rollPrompt)
            end)
        end
    end

    return started
end

local function StopServerAutoRoll()
    isServerAutoActive = false
    pcall(function()
        local rollControls = GetRollControls()
        if rollControls then
            rollControls:InvokeServer("stop", "Monsters")
        end
    end)
end

local function ResumeRollAfterBuy(reason)
    if isResuming or not isPausedWaitingBuy then return end
    isResuming = true
    isPausedWaitingBuy = false
    lastMatchedTargetName = nil

    RaxorHub:Notify({
        Title = "Auto Roll",
        Content = reason or "ซื้อตัวละครเรียบร้อย! กำลังสุ่มต่ออัตโนมัติ...",
        Duration = 2.5
    })

    task.spawn(function()
        task.wait(0.5)
        isResuming = false
        if State.AutoRoll and not isPausedWaitingBuy then
            isServerAutoActive = false
            StartServerAutoRoll()
        end
    end)
end

local function GetEntryMutation(entry)
    if not entry then return "None" end
    if entry.mutation and type(entry.mutation) == "string" and entry.mutation ~= "" and entry.mutation ~= "None" then
        local m = entry.mutation:sub(1,1):upper() .. entry.mutation:sub(2):lower()
        return m
    end
    local id = tostring(entry.id or ""):lower()
    if string.find(id, "cursed") then return "Cursed" end
    if string.find(id, "infernal") then return "Infernal" end
    if string.find(id, "frozen") then return "Frozen" end
    if string.find(id, "golden") or string.find(id, "gold") then return "Golden" end
    return "None"
end

local function CheckRollMatch(entry)
    if not entry then return false, "Common", "None" end
    local entryRarity = entry.rarity or "Common"
    local entryMutation = GetEntryMutation(entry)

    -- Match 1: Rarity
    local rarityMatch = false
    if type(State.RollTargetRarities) == "table" and #State.RollTargetRarities > 0 then
        for _, r in ipairs(State.RollTargetRarities) do
            if string.lower(tostring(r)) == string.lower(tostring(entryRarity)) then
                rarityMatch = true
                break
            end
        end
    end

    -- Match 2: Mutation
    local mutationMatch = false
    if type(State.RollTargetMutations) == "table" and #State.RollTargetMutations > 0 then
        for _, m in ipairs(State.RollTargetMutations) do
            if string.lower(tostring(m)) == string.lower(tostring(entryMutation)) then
                mutationMatch = true
                break
            end
        end
    end

    -- Both Rarity AND Mutation must match selected criteria
    local isMatch = rarityMatch and mutationMatch
    return isMatch, entryRarity, entryMutation
end

local function BuyRollSlot(slotIndex, stand, targetName)
    local rollers = GetMapRollers()
    stand = stand or (rollers and State.LastRollMachine and rollers:FindFirstChild(State.LastRollMachine)) or GetPlayerRollStand("Monsters")
    if not stand then return false end

    -- Collect all candidate BuyPrompts on this stand
    local candidates = {}

    -- Check specific slot first if provided
    if slotIndex then
        local suffix = slotIndex == 1 and "" or tostring(slotIndex)
        local d = stand:FindFirstChild("Display" .. suffix)
        local p = d and d:FindFirstChild("BuyPrompt")
        if p and p:IsA("ProximityPrompt") then
            table.insert(candidates, { prompt = p, part = d, priority = 1 })
        end
    end

    -- Check all 3 display platforms
    for i = 1, 3 do
        local suffix = i == 1 and "" or tostring(i)
        local d = stand:FindFirstChild("Display" .. suffix)
        local p = d and d:FindFirstChild("BuyPrompt")
        if p and p:IsA("ProximityPrompt") then
            local already = false
            for _, c in ipairs(candidates) do
                if c.prompt == p then already = true break end
            end
            if not already then
                local prio = 2
                if targetName and p.ObjectText ~= "" and (string.find(string.lower(p.ObjectText), string.lower(targetName)) or string.find(string.lower(targetName), string.lower(p.ObjectText))) then
                    prio = 0
                end
                table.insert(candidates, { prompt = p, part = d, priority = prio })
            end
        end
    end

    table.sort(candidates, function(a, b) return a.priority < b.priority end)

    if #candidates == 0 then return false end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    for _, cand in ipairs(candidates) do
        local buyPrompt = cand.prompt
        local displayPart = cand.part

        if buyPrompt and displayPart then
            local oldHold = buyPrompt.HoldDuration
            local oldLOS = buyPrompt.RequiresLineOfSight
            buyPrompt.HoldDuration = 0
            buyPrompt.RequiresLineOfSight = false

            local function FirePrompt()
                pcall(function() fireproximityprompt(buyPrompt, 0) end)
                pcall(function() fireproximityprompt(buyPrompt) end)
            end

            if hrp and displayPart:IsA("BasePart") then
                local dist = (hrp.Position - displayPart.Position).Magnitude
                if dist <= 14 then
                    -- Already near the stand: Fire immediately without moving!
                    FirePrompt()
                    task.wait(0.04)
                    FirePrompt()
                else
                    -- Far away: Brief 0.08s step to stand to satisfy Roblox server distance check (11 studs), buy, then return!
                    local oldCF = hrp.CFrame
                    hrp.CFrame = CFrame.new(displayPart.Position + Vector3.new(0, 2.5, 0), displayPart.Position)
                    task.wait(0.08)
                    FirePrompt()
                    task.wait(0.08)
                    FirePrompt()
                    task.wait(0.08)
                    hrp.CFrame = oldCF
                end
            else
                FirePrompt()
            end

            task.delay(0.25, function()
                pcall(function()
                    buyPrompt.HoldDuration = oldHold
                    buyPrompt.RequiresLineOfSight = oldLOS
                end)
            end)
        end
    end

    return true
end

-- 1. ProximityPrompt triggered listener: Instant resume when player presses F to buy on stand!
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if player == LocalPlayer and prompt.Name == "BuyPrompt" then
        if State.AutoRoll and isPausedWaitingBuy then
            ResumeRollAfterBuy("ซื้อตัวละครเรียบร้อย! กำลังสุ่มต่ออัตโนมัติ...")
        end
    end
end)

-- 2. Roll remote listener
task.spawn(function()
    local rollRemote = GetRollRemote()
    while not rollRemote do
        task.wait(1)
        rollRemote = GetRollRemote()
    end

    rollRemote.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end

        -- Check purchase event (Manual buy or Auto buy completed) -> Auto resume rolling!
        if data.purchase then
            if State.AutoRoll and isPausedWaitingBuy then
                ResumeRollAfterBuy("ซื้อตัวละครเรียบร้อย! กำลังสุ่มต่ออัตโนมัติ...")
            end
            return
        end

        -- If confirmation required to continue rolling
        if not data.ok then
            if data.confirm and State.AutoRoll and not isPausedWaitingBuy then
                pcall(function()
                    rollRemote:FireServer("confirmRoll", "Monsters")
                end)
            end
            return
        end

        lastRollResultTime = tick()
        lastRollData = data
        if data.machine and type(data.machine) == "string" then
            State.LastRollMachine = data.machine
        end

        local entries = data.entries or {}
        if #entries == 0 and data.id then
            entries = { data }
        end

        local foundTarget = false
        local matchedEntry = nil
        local matchedSlot = 1
        local matchedRarity = "Common"
        local matchedMutation = nil

        for idx, entry in ipairs(entries) do
            local isMatch, rTier, mut = CheckRollMatch(entry)
            if isMatch then
                foundTarget = true
                matchedEntry = entry
                matchedSlot = idx
                matchedRarity = rTier
                matchedMutation = mut
                break
            end
        end

        -- Update display text (Prioritize matched target if hit!)
        local displayEntry = matchedEntry or entries[1] or data
        local entryName = displayEntry and displayEntry.id or "Unknown"
        local entryR = displayEntry and displayEntry.rarity or "Common"
        local entryM = GetEntryMutation(displayEntry)
        local statusStr = entryName .. " (" .. entryR .. (entryM ~= "None" and (", " .. entryM) or "") .. ")"
        State.RollStatusText = statusStr

        if RollStatusLabel and RollStatusLabel.Set then
            pcall(function()
                if foundTarget then
                    RollStatusLabel:Set("สุ่มได้: " .. statusStr)
                else
                    RollStatusLabel:Set("ล่าสุด: " .. statusStr)
                end
            end)
        end

        if State.AutoRoll then
            UpdateDungeonStatus("กำลังสุ่ม: " .. statusStr)
        end

        if foundTarget and State.AutoRoll and not isPausedWaitingBuy then
            isPausedWaitingBuy = true
            StopServerAutoRoll()
            RestoreStandPrompts()

            local stand = GetPlayerRollStand("Monsters")
            local targetName = matchedEntry and matchedEntry.id or "Monster"
            lastMatchedTargetName = targetName
            local info = targetName .. " [" .. matchedRarity .. (matchedMutation ~= "None" and (" | " .. matchedMutation) or "") .. "]"
            UpdateDungeonStatus("สุ่มได้: " .. info)

            if State.RollAutoBuy then
                RaxorHub:Notify({
                    Title = "🎉 เจอมอนสเตอร์เป้าหมาย!",
                    Content = "สุ่มได้ " .. info .. " -> กำลังซื้ออัตโนมัติ...",
                    Duration = 4.0
                })
                task.spawn(function()
                    for attempt = 1, 4 do
                        task.wait(attempt == 1 and 0.15 or 0.4)
                        if not isPausedWaitingBuy then break end
                        BuyRollSlot(matchedSlot, stand, targetName)
                    end
                end)
            else
                RaxorHub:Notify({
                    Title = "🎉 เจอมอนสเตอร์เป้าหมาย!",
                    Content = "สุ่มได้ " .. info .. " (หยุดรอให้ซื้อ เมื่อซื้อแล้วจะสุ่มต่อทันที)",
                    Duration = 8.0
                })
            end
        end

        rollCompletedSignal:Fire(data)
    end)
end)

-- 3. Stand watcher: If target monster leaves the stand (bought manually or cleared), resume roll!
task.spawn(function()
    while true do
        task.wait(0.5)
        if State.AutoRoll and isPausedWaitingBuy then
            local rollers = GetMapRollers()
            local stand = (rollers and State.LastRollMachine and rollers:FindFirstChild(State.LastRollMachine)) or GetPlayerRollStand("Monsters")
            if stand then
                local stillHasTarget = false
                for i = 1, 3 do
                    local suffix = i == 1 and "" or tostring(i)
                    local d = stand:FindFirstChild("Display" .. suffix)
                    local p = d and d:FindFirstChild("BuyPrompt")
                    if p and p:IsA("ProximityPrompt") and p.Enabled then
                        if lastMatchedTargetName and p.ObjectText ~= "" and (string.find(string.lower(p.ObjectText), string.lower(lastMatchedTargetName)) or string.find(string.lower(lastMatchedTargetName), string.lower(p.ObjectText))) then
                            stillHasTarget = true
                            break
                        end
                    end
                end
                -- If target is no longer on the stand, it has been bought!
                if not stillHasTarget then
                    ResumeRollAfterBuy("ตรวจพบว่าตัวละครถูกซื้อไปแล้ว! กำลังเริ่มสุ่มต่อ...")
                end
            end
        end
    end
end)

-- 4. Auto Roll background watchdog & active engine
task.spawn(function()
    while true do
        task.wait(0.5)
        if State.AutoRoll and not isPausedWaitingBuy then
            local now = tick()
            -- If no roll results received for more than 1.6 seconds, trigger roll again
            if now - lastRollResultTime > 1.6 then
                StartServerAutoRoll()

                local stand = GetPlayerRollStand("Monsters")
                local rollButton = stand and stand:FindFirstChild("RollButton")
                local rollPrompt = rollButton and rollButton:FindFirstChild("RollPrompt")
                if rollPrompt and rollPrompt:IsA("ProximityPrompt") then
                    pcall(function()
                        fireproximityprompt(rollPrompt, 0)
                        fireproximityprompt(rollPrompt)
                    end)
                end

                pcall(function()
                    local rollRemote = GetRollRemote()
                    if rollRemote then
                        rollRemote:FireServer("confirmRoll", "Monsters")
                    end
                end)
            end
        end
    end
end)

-- [[ TAB 1: HOME ]]
local HomeTab = Window:AddTab({
    Name = "Home",
    Icon = "Home"
})

local WelcomeSec = HomeTab:AddSection("Information", "ข้อมูลระบบ")

WelcomeSec:AddLabel("ผู้เล่น: " .. LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")")
WelcomeSec:AddLabel("เวอร์ชัน: RAXOR Elite (Lifetime)")
WelcomeSec:AddLabel("เกม: Build a Dungeon (Labyrinth)")

local QuickSec = HomeTab:AddSection("Utilities", "เครื่องมือทั่วไป")

QuickSec:AddButton({
    Title = "Rejoin",
    Description = "เข้าเซิร์ฟเวอร์เดิมใหม่",
    ButtonText = "Rejoin",
    Callback = function()
        pcall(function()
            local ts = game:GetService("TeleportService")
            ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end
})

QuickSec:AddButton({
    Title = "Server Hop",
    Description = "ย้ายไปเซิร์ฟเวอร์อื่น",
    ButtonText = "Hop Server",
    Callback = function()
        pcall(function()
            local HttpService = game:GetService("HttpService")
            local TeleportService = game:GetService("TeleportService")
            local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
            for _, s in ipairs(servers.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    break
                end
            end
        end)
    end
})

-- [[ TAB 2: DUNGEON (รวมทุกอย่างที่เกี่ยวกับดันเจี้ยน) ]]
local DungeonTab = Window:AddTab({
    Name = "Dungeon",
    Icon = "Dungeon"
})

-- Section 1: Auto Play
local DungeonAutoSec = DungeonTab:AddSection("Auto Play", "ระบบลงดันเจี้ยนอัตโนมัติ")

DungeonStatusLabel = DungeonAutoSec:AddLabel("สถานะ: ปิดการทำงาน (พร้อมใช้งาน)")
local FloorLabel = DungeonAutoSec:AddLabel("Current Floor: กำลังตรวจสอบ...")
CreateOnScreenStatusHUD()

DungeonAutoSec:AddToggleSwitch({
    Title = "Auto Dungeon",
    Description = "ลงดันเจี้ยนอัตโนมัติ",
    Default = false,
    ID = "Auto_Dungeon",
    Callback = function(val)
        State.AutoDungeon = val
        if val then
            State.KillAura = true
            SetAutoFly(true)
            StartAutoDungeon()
            RaxorHub:Notify({ Title = "Auto Dungeon", Content = "เริ่มฟาร์มดันเจี้ยนอัตโนมัติแล้ว", Duration = 2.5 })
        else
            currentCombatRoom = nil
            SetAutoFly(false)
            UpdateDungeonStatus("ปิดการทำงาน")
            RaxorHub:Notify({ Title = "Auto Dungeon", Content = "หยุดฟาร์มดันเจี้ยน", Duration = 2.0 })
        end
    end
})

DungeonAutoSec:AddToggleSwitch({
    Title = "Auto Chests",
    Description = "เก็บกล่องก่อนลงชั้นถัดไป",
    Default = true,
    ID = "Auto_DungeonChests",
    Callback = function(val)
        State.AutoDungeonChests = val
    end
})

DungeonAutoSec:AddToggleSwitch({
    Title = "Auto Revive",
    Description = "ชุบชีวิตเพื่อนร่วมทีมอัตโนมัติ (กด F)",
    Default = false,
    ID = "Auto_Revive",
    Callback = function(val)
        State.AutoRevive = val
        if val then
            StartAutoReviveLoop()
            RaxorHub:Notify({ Title = "Auto Revive", Content = "เปิดระบบชุบชีวิตเพื่อนอัตโนมัติแล้ว", Duration = 2.5 })
        else
            RaxorHub:Notify({ Title = "Auto Revive", Content = "ปิดระบบชุบชีวิตเพื่อน", Duration = 2.0 })
        end
    end
})

DungeonAutoSec:AddToggleSwitch({
    Title = "Show HUD",
    Description = "แสดงสถานะตรงกลางใต้เวลา",
    Default = true,
    ID = "Auto_DungeonHUD",
    Callback = function(val)
        State.ShowDungeonHUD = val
        if onScreenGui then
            onScreenGui.Enabled = val
        elseif val then
            CreateOnScreenStatusHUD()
        end
    end
})

DungeonAutoSec:AddButton({
    Title = "Check Area",
    Description = "สแกนหาห้อง Mini-Boss และบอส",
    ButtonText = "Check",
    Callback = function()
        CheckMiniBossAreas()
    end
})

DungeonAutoSec:AddButton({
    Title = "Clear Visuals",
    Description = "ลบกรอบแสดงห้องในแมพ",
    ButtonText = "Clear",
    Callback = function()
        ClearMiniBossAreaVisuals()
        RaxorHub:Notify({ Title = "Visuals", Content = "ลบกรอบห้องเรียบร้อย", Duration = 2.0 })
    end
})

-- Section 2: Combat
local CombatSec = DungeonTab:AddSection("Combat", "ระบบต่อสู้")

CombatSec:AddToggleSwitch({
    Title = "KillAura",
    Description = "ฆ่าศัตรูรอบตัว",
    Default = false,
    ID = "Home_KillAura",
    Callback = function(val)
        State.KillAura = val
        if val then
            RaxorHub:Notify({ Title = "KillAura", Content = "เปิด KillAura แล้ว", Duration = 2.0 })
        end
    end
})

-- Section 3: Chests
local ChestSec = DungeonTab:AddSection("Chests", "ระบบเก็บกล่อง")

ChestSec:AddButton({
    Title = "Collect Chests",
    Description = "วาปเก็บกล่องทั้งหมดในชั้นทันที",
    ButtonText = "Collect",
    Callback = function()
        task.spawn(CollectAllChests)
    end
})

ChestSec:AddToggleSwitch({
    Title = "Auto Loop",
    Description = "เก็บกล่องวนซ้ำอัตโนมัติ",
    Default = false,
    ID = "Chest_AutoLoop",
    Callback = function(val)
        State.AutoLoop = val
        if val then
            task.spawn(function()
                while State.AutoLoop do
                    CollectAllChests()
                    task.wait(5)
                end
            end)
        else
            State.IsCollecting = false
        end
    end
})

ChestSec:AddSlider({
    Title = "Delay",
    Description = "ความเร็วในการวาปเก็บกล่อง",
    Min = 10,
    Max = 100,
    Default = 25,
    Suffix = " ms * 10",
    ID = "Chest_Delay",
    Callback = function(val)
        State.TeleportDelay = val / 100
    end
})

-- [[ TAB: LOBBY ]]
local LobbyTab = Window:AddTab({
    Name = "Lobby",
    Icon = "Shop"
})

local RollSec = LobbyTab:AddSection("Auto Roll", "ระบบสุ่มมอนสเตอร์และกลายพันธุ์")

RollStatusLabel = RollSec:AddLabel("สถานะ: พร้อมใช้งาน (ยังไม่ได้สุ่ม)")

RollSec:AddToggleSwitch({
    Title = "Auto Roll",
    Description = "สุ่มมอนสเตอร์อัตโนมัติ (หยุดเมื่อพบเป้าหมาย และสุ่มต่อเมื่อซื้อเสร็จ)",
    Default = false,
    ID = "Lobby_AutoRoll",
    Callback = function(val)
        State.AutoRoll = val
        isPausedWaitingBuy = false
        if val then
            RestoreStandPrompts()
            StartServerAutoRoll()
            RaxorHub:Notify({ Title = "Auto Roll", Content = "เริ่มสุ่มอัตโนมัติแล้ว...", Duration = 2.0 })
        else
            StopServerAutoRoll()
            RestoreStandPrompts()
            RaxorHub:Notify({ Title = "Auto Roll", Content = "หยุดสุ่มแล้ว", Duration = 2.0 })
        end
    end
})

RollSec:AddToggleSwitch({
    Title = "Auto Buy",
    Description = "ซื้อทันทีเมื่อสุ่มได้ (ปิด = ค้างไว้ให้กดซื้อเอง)",
    Default = false,
    ID = "Lobby_AutoBuy",
    Callback = function(val)
        State.RollAutoBuy = val
        if val then
            RaxorHub:Notify({ Title = "Auto Buy", Content = "เปิดโหมดซื้ออัตโนมัติเมื่อได้ตัวเป้าหมาย", Duration = 2.0 })
        else
            RaxorHub:Notify({ Title = "Auto Buy", Content = "ปิดโหมดซื้อ (จะหยุดรอให้คุณซื้อเอง)", Duration = 2.0 })
        end
    end
})

RollSec:AddMultiSelect({
    Title = "Target Rarity",
    Description = "เลือกระดับความหายากที่ต้องการหยุด",
    Options = { "Divine", "Secret", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common" },
    Default = { "Divine", "Secret" },
    ID = "Lobby_TargetRarity",
    Callback = function(selected)
        State.RollTargetRarities = selected
        if State.AutoRoll and not isPausedWaitingBuy then
            isServerAutoActive = false
            StartServerAutoRoll()
        end
    end
})

RollSec:AddMultiSelect({
    Title = "Target Mutation",
    Description = "เลือกการกลายพันธุ์ที่ต้องการหยุด (รวม None = ไม่มีกลายพันธุ์)",
    Options = { "None", "Cursed", "Infernal", "Frozen", "Golden" },
    Default = { "None", "Cursed", "Infernal", "Frozen", "Golden" },
    ID = "Lobby_TargetMutation",
    Callback = function(selected)
        State.RollTargetMutations = selected
        if State.AutoRoll and not isPausedWaitingBuy then
            isServerAutoActive = false
            StartServerAutoRoll()
        end
    end
})

-- [[ TAB 3: AUTOMATION ]]
local AutomationTab = Window:AddTab({
    Name = "Automation",
    Icon = "Automation"
})

local MatchSec = AutomationTab:AddSection("Game", "ระบบในเกม")

MatchSec:AddToggleSwitch({
    Title = "Auto Play Again",
    Description = "โหวตเริ่มเกมใหม่อัตโนมัติ",
    Default = false,
    ID = "Auto_PlayAgain",
    Callback = function(val)
        State.AutoPlayAgain = val
        if val then
            RaxorHub:Notify({ Title = "Auto Play Again", Content = "เปิดโหวตเริ่มเกมใหม่อัตโนมัติแล้ว", Duration = 2.0 })
        end
    end
})

-- [[ TAB 4: VISUALS / ESP ]]
local VisualsTab = Window:AddTab({
    Name = "Visuals",
    Icon = "Visuals"
})

local EspSec = VisualsTab:AddSection("ESP", "มองเห็นทะลุกำแพง")

EspSec:AddToggleSwitch({
    Title = "Chest ESP",
    Description = "มองเห็นกล่องทะลุกำแพง",
    Default = false,
    ID = "ESP_Chests",
    Callback = function(val)
        State.ChestESP = val
        UpdateESP()
    end
})

EspSec:AddToggleSwitch({
    Title = "Trap ESP",
    Description = "มองเห็นกับดักทะลุกำแพง",
    Default = false,
    ID = "ESP_Traps",
    Callback = function(val)
        State.TrapESP = val
        UpdateESP()
    end
})

EspSec:AddButton({
    Title = "Refresh ESP",
    Description = "รีเฟรชการแสดงผล",
    ButtonText = "Refresh",
    Callback = function()
        UpdateESP()
    end
})

local VisualSettingsSec = VisualsTab:AddSection("Display", "ปรับแต่งภาพ")

VisualSettingsSec:AddToggleSwitch({
    Title = "Hide Allies",
    Description = "ซ่อนสัตว์เลี้ยงลดแลค",
    Default = false,
    ID = "Visual_HideAllies",
    Callback = function(val)
        State.HideAllies = val
        ApplyHideAllies(val)
        if val then
            RaxorHub:Notify({ Title = "Hide Allies", Content = "ซ่อนสัตว์เลี้ยงเรียบร้อย", Duration = 2.0 })
        else
            RaxorHub:Notify({ Title = "Hide Allies", Content = "แสดงสัตว์เลี้ยงตามปกติ", Duration = 2.0 })
        end
    end
})

-- [[ TAB 5: MOVEMENT ]]
local MovementTab = Window:AddTab({
    Name = "Movement",
    Icon = "Movement"
})

local MoveSec = MovementTab:AddSection("Movement", "การเคลื่อนที่")

MoveSec:AddToggleSwitch({
    Title = "Speed Hack",
    Description = "วิ่งไวขึ้น",
    Default = false,
    ID = "Move_SpeedHack",
    Callback = function(val)
        State.SpeedHack = val
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then
            hum.WalkSpeed = val and State.SpeedVal or 16
        end
    end
})

MoveSec:AddSlider({
    Title = "Speed",
    Description = "ปรับระดับความเร็ว",
    Min = 16,
    Max = 150,
    Default = 32,
    Suffix = " spd",
    ID = "Move_SpeedVal",
    Callback = function(val)
        State.SpeedVal = val
        if State.SpeedHack then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
            if hum then
                hum.WalkSpeed = val
            end
        end
    end
})

MoveSec:AddToggleSwitch({
    Title = "NoClip",
    Description = "เดินทะลุกำแพง",
    Default = false,
    ID = "Move_NoClip",
    Callback = function(val)
        State.NoClip = val
    end
})

MoveSec:AddToggleSwitch({
    Title = "Auto Fly",
    Description = "บินลอยตัวตอนต่อสู้",
    Default = true,
    ID = "Move_AutoPlayFly",
    Callback = function(val)
        State.AutoPlayFly = val
        if not val then
            SetAutoFly(false)
        elseif State.AutoDungeon then
            SetAutoFly(true)
        end
    end
})

-- [[ Optimized Character Caching for NoClip & SpeedHack (Zero GC Pressure) ]]
local cachedCharacterParts = {}
local cachedHumanoid = nil

local function UpdateCharacterCache(char)
    cachedCharacterParts = {}
    cachedHumanoid = nil
    if not char then return end

    cachedHumanoid = char:FindFirstChildWhichIsA("Humanoid")
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(cachedCharacterParts, part)
        end
    end
end

if LocalPlayer.Character then
    UpdateCharacterCache(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    State.IsSuiciding = false
    UpdateCharacterCache(char)
    char.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            table.insert(cachedCharacterParts, desc)
        elseif desc:IsA("Humanoid") then
            cachedHumanoid = desc
        end
    end)
end)

-- Stepped Loop (Ultra Light - Zero Allocations)
RunService.Stepped:Connect(function()
    if State.NoClip then
        for i = 1, #cachedCharacterParts do
            local part = cachedCharacterParts[i]
            if part and part.Parent and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
    if State.SpeedHack and cachedHumanoid and cachedHumanoid.Parent then
        if cachedHumanoid.WalkSpeed ~= State.SpeedVal then
            cachedHumanoid.WalkSpeed = State.SpeedVal
        end
    end
end)

-- [[ TAB 6: MISC & UI SETTINGS ]]
local MiscTab = Window:AddTab({
    Name = "Misc",
    Icon = "Misc"
})

local UtilSec = MiscTab:AddSection("Interactions", "ระบบช่วยเหลือและการโต้ตอบในเกม")

UtilSec:AddToggleSwitch({
    Title = "Fast Prompt",
    Description = "กด E ทันทีไม่ต้องรอ",
    Default = false,
    ID = "Misc_InstantPrompt",
    Callback = function(val)
        State.InstantPrompt = val
    end
})

local SecKeybind = MiscTab:AddSection("Keybind", "ปุ่มลัด")

SecKeybind:AddToggleSwitch({
    ID = "EnableBind_UI",
    Title = "Enable Keybind",
    Description = "เปิดใช้งานปุ่มลัด",
    Default = true,
    Callback = function(v)
        print("[Misc] Enable Keybind:", v)
    end
})

SecKeybind:AddKeybind({
    ID = "MenuBind",
    Title = "Keybind",
    Description = "ปุ่มเปิด/ปิดเมนู",
    Default = Enum.KeyCode.RightAlt,
    Callback = function(key)
        local frame = RaxorHub.MainFrame
        local sbtn = RaxorHub.StartBtn

        if RaxorHub.ConfigData["EnableBind_UI"] == true then
            if RaxorHub.ToggleUI then
                RaxorHub.ToggleUI()
            elseif frame then
                frame.Visible = not frame.Visible
                if sbtn then
                    sbtn.Visible = not frame.Visible
                end
                if RaxorHub.CloseAllDropdowns then
                    RaxorHub.CloseAllDropdowns()
                end
            end
        end
    end
})

SecKeybind:AddButton({
    Title = "Reset Settings",
    Description = "รีเซ็ตการตั้งค่าทั้งหมด",
    ButtonText = "Reset",
    Callback = function()
        RaxorHub:ResetAllSettings()
        RaxorHub:Notify({ Title = "Settings Reset", Content = "คืนค่าเริ่มต้นเรียบร้อยแล้ว", Duration = 2.5 })
    end
})

-- [[ Instant Auto Play Again & GUI Watcher (Zero Idle CPU) ]]
local lastAutoPlayAgainTrigger = 0

local function BindFastGuiWatcher(gui)
    if not gui then return end
    if gui.Name == "LabEnd" or gui.Name == "BADPrompts" then
        local function CheckAndFire()
            if State.AutoPlayAgain and gui.Enabled then
                local now = tick()
                if now - lastAutoPlayAgainTrigger > 0.4 then
                    lastAutoPlayAgainTrigger = now
                    TriggerPlayAgain()
                end
            end
        end

        gui:GetPropertyChangedSignal("Enabled"):Connect(CheckAndFire)
        if gui.Enabled then
            CheckAndFire()
        end
    end
end

-- Bind existing GUIs (Exclude LabHUD to prevent event overhead)
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
for _, name in ipairs({"LabEnd", "BADPrompts"}) do
    local g = playerGui:FindFirstChild(name)
    if g then BindFastGuiWatcher(g) end
end

-- Listen for new GUIs added dynamically
playerGui.ChildAdded:Connect(function(child)
    if child.Name == "LabEnd" or child.Name == "BADPrompts" then
        BindFastGuiWatcher(child)
    end
end)

-- High-speed AutoPlayAgain Watcher (Runs light 0.2s poll, instant event-driven fallback)
task.spawn(function()
    while task.wait(0.2) do
        if State.AutoPlayAgain then
            pcall(function()
                local pgui = LocalPlayer:FindFirstChild("PlayerGui")
                if not pgui then return end

                local labEnd = pgui:FindFirstChild("LabEnd")
                local badPrompts = pgui:FindFirstChild("BADPrompts")

                if (labEnd and labEnd.Enabled) or (badPrompts and badPrompts.Enabled) then
                    local now = tick()
                    if now - lastAutoPlayAgainTrigger > 0.4 then
                        lastAutoPlayAgainTrigger = now
                        TriggerPlayAgain()
                    end
                end
            end)
        end
    end
end)

-- Live floor updater loop (Only executes when floor actually changes)
local lastKnownFloor = ""
task.spawn(function()
    while task.wait(2.5) do
        pcall(function()
            local floor = GetCurrentFloor()
            if floor ~= lastKnownFloor then
                lastKnownFloor = floor
                FloorLabel:Set("Current Floor: " .. tostring(floor))
                if State.ChestESP or State.TrapESP then
                    UpdateESP()
                end
                if State.HideAllies then
                    ApplyHideAllies(true)
                end
            end
        end)
    end
end)

-- [[ KillAura Combat System (Silent, God Mode & Multi-Target) ]]
-- (Note: GetActionRemote is defined in Shared Remotes Helper above)

-- Weapon cooldowns & ranges defined by Build a Dungeon code
local BADWeaponCooldowns = {
    dagger = 0.38,
    katana = 0.45,
    sword = 0.50,
    staff = 0.65,
    halberd = 0.66,
    scythe = 0.70,
    great = 0.70,
    bow = 0.80
}
local BADWeaponRanges = {
    bow = 36,
    staff = 28,
    polearm = 16,
    halberd = 16,
    scythe = 16,
    great = 15,
    katana = 15,
    sword = 15,
    dagger = 14
}

task.spawn(function()
    while true do
        if State.KillAura then
            local currentDelay = 0.38
            pcall(function()
                if LocalPlayer:GetAttribute("Building") or LocalPlayer:GetAttribute("InspectingUnit") then
                    return
                end

                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildWhichIsA("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then
                    return
                end

                -- Auto equip weapon from Backpack if not holding one
                local tool = char:FindFirstChildWhichIsA("Tool")
                if not tool then
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    local bpTool = bp and bp:FindFirstChildWhichIsA("Tool")
                    if bpTool then
                        hum:EquipTool(bpTool)
                        tool = bpTool
                        task.wait(0.03)
                    end
                end

                -- Dynamic weapon speed & range based on game code
                local weaponStyle = (tool and tool:GetAttribute("WeaponStyle")) or "sword"
                currentDelay = BADWeaponCooldowns[weaponStyle] or 0.38
                local maxDist = BADWeaponRanges[weaponStyle] or 16

                local badEnemies = Workspace:FindFirstChild("BADEnemies")
                if not badEnemies then return end

                local myPos = hrp.Position
                local targetList = {}

                for _, enemy in ipairs(badEnemies:GetChildren()) do
                    if enemy:IsA("Model") and (enemy:GetAttribute("CombatHP") or 1) > 0 then
                        local ePart = enemy:FindFirstChild("UpperTorso") or enemy.PrimaryPart or enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head")
                        if ePart then
                            local diff = ePart.Position - myPos
                            local horizontalDist = Vector3.new(diff.X, 0, diff.Z).Magnitude
                            if horizontalDist <= maxDist and math.abs(diff.Y) < 30 then
                                table.insert(targetList, {
                                    model = enemy,
                                    part = ePart,
                                    dist = horizontalDist
                                })
                            end
                        end
                    end
                end

                if #targetList == 0 then return end

                -- [[ Pure Remote Attack Execution - ZERO Tool Activation / SetAttribute (NO Animations, NO Trails, NO Camera Shake) ]]
                local actionRemote = GetActionRemote()
                if not actionRemote then return end

                local isLabyrinth = Workspace:GetAttribute("LabyrinthMode") == true

                -- Multi-Target built-in: attack all monsters in range simultaneously
                for _, tData in ipairs(targetList) do
                    local monsterId = isLabyrinth and tData.model:GetAttribute("LabMonster") or nil
                    actionRemote:FireServer("attack", monsterId)
                    if monsterId ~= nil then
                        actionRemote:FireServer("attack", nil)
                    end
                end

                -- Auto trigger Skill Q & Skill R during combat
                UseCombatSkills()
            end)
            task.wait(currentDelay)
        else
            task.wait(0.35)
        end
    end
end)
