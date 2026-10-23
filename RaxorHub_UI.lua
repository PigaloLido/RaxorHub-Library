local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local UI_NAME = "RaxorHub_UI"
local UI_TITLE = "RAXOR"
local UI_CREDIT = "By : Pigalo"
local UI_VERSION = "v2.1.6"

-- Executor & CoreGui protection
local CoreGuiSuccess, CoreGui = pcall(function() return game:GetService("CoreGui") end)
local OldUI = (CoreGuiSuccess and CoreGui and CoreGui:FindFirstChild(UI_NAME)) or PlayerGui:FindFirstChild(UI_NAME)

if OldUI then
    warn("[RaxorHub] Cleaning up existing instance...")
    OldUI:Destroy()
end

local ConfigFolder = "RaxorHub_Configs"
if isfolder and makefolder and not isfolder(ConfigFolder) then
    pcall(function() makefolder(ConfigFolder) end)
end

-- Fallback memory storage for environments without file API or Roblox Studio
local MemoryFiles = {}
local function SafeWriteFile(path, content)
    if writefile then
        pcall(function() writefile(path, content) end)
    end
    MemoryFiles[path] = content
end

local function SafeReadFile(path)
    if isfile and readfile then
        local ok, res = pcall(function()
            if isfile(path) then
                return readfile(path)
            end
        end)
        if ok and res then return res end
    end
    return MemoryFiles[path]
end

local function SafeIsFile(path)
    if isfile then
        local ok, res = pcall(function() return isfile(path) end)
        if ok and res then return true end
    end
    return MemoryFiles[path] ~= nil
end

local function SafeDelFile(path)
    if isfile and delfile then
        pcall(function()
            if isfile(path) then delfile(path) end
        end)
    end
    MemoryFiles[path] = nil
end

local function SafeListFiles(folder)
    local list = {}
    if isfolder and listfiles then
        pcall(function()
            if isfolder(folder) then
                local res = listfiles(folder)
                if type(res) == "table" then
                    for _, f in ipairs(res) do
                        table.insert(list, f)
                    end
                end
            end
        end)
    end
    for path, _ in pairs(MemoryFiles) do
        if path:sub(1, #folder) == folder then
            local already = false
            for _, existing in ipairs(list) do
                if existing:gsub("\\", "/") == path:gsub("\\", "/") then
                    already = true
                    break
                end
            end
            if not already then
                table.insert(list, path)
            end
        end
    end
    return list
end


local RaxorHub = {
    Elements = {},
    ConfigData = {},
    Objects = {},
    ConfigFolder = ConfigFolder,
    ActiveTab = nil,
    Notifications = {},
    Version = UI_VERSION
}

-- Active overlays tracking
local activeDropdownList = nil
local activeDropdownArrow = nil
local activeDropdownFrame = nil
local activeDropdownSync = nil
local activeColorPicker = nil
local MainFrame = nil
local StartBtn = nil
local PresetsModal = nil
local IsBinding = false

-- [[ Modern Blade-Client Color Scheme ]]
local Colors = {
    WindowBg        = Color3.fromRGB(15, 16, 20),      -- Deep Dark Slate #0F1014
    MainCardBg      = Color3.fromRGB(20, 21, 27),      -- Container Card #14151B
    SidebarBg       = Color3.fromRGB(18, 19, 25),      -- Sidebar Background #121319
    TopBarBg        = Color3.fromRGB(18, 19, 25),      -- Top Bar Background
    SectionHeaderBg = Color3.fromRGB(23, 24, 32),      -- Subheaders
    CardBg          = Color3.fromRGB(24, 25, 33),      -- Item Cards #181921
    CardHover       = Color3.fromRGB(30, 32, 42),      -- Item Hover
    CardActive      = Color3.fromRGB(34, 36, 48),      -- Active/Pressed
    InputBg         = Color3.fromRGB(20, 21, 28),      -- Inputs / Fields
    DropdownBg      = Color3.fromRGB(22, 23, 31),      -- Flyout menus
    ModalBg         = Color3.fromRGB(22, 23, 31),      -- Modals / Popups

    Accent          = Color3.fromRGB(124, 92, 252),    -- Blade Purple #7C5CFC
    AccentHover     = Color3.fromRGB(142, 114, 255),   -- Soft Purple Hover #8E72FF
    AccentMuted     = Color3.fromRGB(75, 58, 140),     -- Low Accent
    AccentGlow      = Color3.fromRGB(124, 92, 252),    -- Glow Highlights

    Text            = Color3.fromRGB(245, 246, 250),   -- Primary White Text
    SubText         = Color3.fromRGB(175, 180, 198),   -- Secondary Text (Crisp for Thai)
    MutedText       = Color3.fromRGB(105, 110, 128),   -- Muted / Placeholder Text

    Border          = Color3.fromRGB(34, 36, 46),      -- Subtle Border #22242E
    BorderFocus     = Color3.fromRGB(56, 59, 76),      -- Focused Border #383B4C
    BorderActive    = Color3.fromRGB(124, 92, 252),    -- Active Purple Border

    CloseRed        = Color3.fromRGB(235, 68, 75),     -- Close Button Red
    CloseRedHover   = Color3.fromRGB(255, 85, 92),
    ControlBtn      = Color3.fromRGB(28, 30, 40),      -- Window Control Buttons

    SwitchOn        = Color3.fromRGB(124, 92, 252),    -- Toggle Switch Active
    SwitchOff       = Color3.fromRGB(36, 38, 50),      -- Toggle Switch Inactive

    ButtonBg        = Color3.fromRGB(32, 34, 45),
    ButtonHover     = Color3.fromRGB(42, 45, 60),
    ButtonPress     = Color3.fromRGB(25, 27, 36),
    White           = Color3.fromRGB(255, 255, 255),
    Black           = Color3.fromRGB(0, 0, 0)
}

-- [[ Font Configuration - Original Gotham Fonts with Enhanced Thai Sizes ]]
local Fonts = {
    Title       = Enum.Font.GothamBold,
    Medium      = Enum.Font.GothamMedium,
    Regular     = Enum.Font.Gotham,
    Brand       = Enum.Font.GothamBold,
    Code        = Enum.Font.Code
}

-- [[ Built-in Custom Asset Icons (Blade & RaxorHub White Line Icons) ]]
local Icons = {
    Logo        = "rbxassetid://87425048247573",  -- RaxorHub Official Logo
    Combat      = "rbxassetid://87875752333553",  -- 1: Sword
    Movement    = "rbxassetid://89131492438764",  -- 2: Sprint Shoe
    Visuals     = "rbxassetid://82702843090557",  -- 3: Eye
    Render      = "rbxassetid://86889350439772",  -- 4: 3D Cube
    Settings    = "rbxassetid://90986900245399",  -- 5: Gear
    Misc        = "rbxassetid://90986900245399",  -- 5: Gear (Alias)
    Shop        = "rbxassetid://101897612481528", -- 6: Cart
    AutoBuy     = "rbxassetid://101897612481528", -- 6: Cart (Alias)
    Crown       = "rbxassetid://84838733609171",  -- 7: Crown / Owner
    Owner       = "rbxassetid://84838733609171",  -- 7: Crown (Alias)
    Save        = "rbxassetid://107508674342176", -- 8: Floppy Disk
    Minimize    = "rbxassetid://133334866399617", -- 9: Minus Line
    Restore     = "rbxassetid://109639980556401", -- 10: Window / Restore
    Close       = "rbxassetid://115217200764763", -- 11: Cross / Close
    Folder      = "rbxassetid://136865241981761", -- 12: Presets Folder
    Dungeon     = "rbxassetid://88481999592471", -- 13: Dungeon
    Automation  = "rbxassetid://92268014238157", -- 14: Automation
    Home        = "rbxassetid://107021730323048", -- 15: Home

    Search      = "rbxassetid://6031154871",      -- Search Glass
    ChevronDown = "rbxassetid://6034818372",      -- Chevron
    Checkmark   = "rbxassetid://6031094667",      -- Checkmark
    Trash       = "rbxassetid://93749431604052",  -- Trash
    Plus        = "rbxassetid://6031094678",      -- Plus
    Star        = "rbxassetid://6031068426",      -- Star / Autoload
    Refresh     = "rbxassetid://6031097225"       -- Refresh / Sync
}
RaxorHub.Icons = Icons

-- [[ Sizing Definitions (Spaced generously for Thai tone marks) ]]
local SizeItem = {
    BoxItem   = UDim2.new(1, -4, 0, 60),  -- Height 60px for full Thai vowel rendering
    TitleItem = UDim2.new(1, -4, 0, 50)   -- Height 50px for Section headers with Thai description
}

-- [[ Helper Utilities ]]
local function AddStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Colors.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function Tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function ResolveIcon(iconInput)
    if not iconInput then return Icons.Logo end
    if Icons[iconInput] then return Icons[iconInput] end
    if string.find(tostring(iconInput), "rbxassetid://") then return iconInput end
    if tonumber(iconInput) then return "rbxassetid://" .. tostring(iconInput) end
    return Icons.Logo
end

local function CloseAllDropdowns()
    if activeDropdownSync then
        pcall(function() activeDropdownSync:Disconnect() end)
        activeDropdownSync = nil
    end
    if activeDropdownList then
        activeDropdownList.Visible = false
        activeDropdownList = nil
    end
    if activeDropdownArrow then
        Tween(activeDropdownArrow, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 0})
        activeDropdownArrow = nil
    end
    if activeColorPicker then
        activeColorPicker.Visible = false
        activeColorPicker = nil
    end
    activeDropdownFrame = nil
end
RaxorHub.CloseAllDropdowns = CloseAllDropdowns

-- Close dropdown on clicking outside
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if activeDropdownList and activeDropdownList.Visible then
            local pos = input.Position
            local listAbsPos = activeDropdownList.AbsolutePosition
            local listAbsSize = activeDropdownList.AbsoluteSize
            local inList = (pos.X >= listAbsPos.X and pos.X <= listAbsPos.X + listAbsSize.X and
                            pos.Y >= listAbsPos.Y and pos.Y <= listAbsPos.Y + listAbsSize.Y)
            local inBtn = false
            if activeDropdownFrame then
                local bPos = activeDropdownFrame.AbsolutePosition
                local bSize = activeDropdownFrame.AbsoluteSize
                inBtn = (pos.X >= bPos.X and pos.X <= bPos.X + bSize.X and
                         pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y)
            end
            if not inList and not inBtn then
                CloseAllDropdowns()
            end
        end
    end
end)

-- Fast and lightweight dragging support (PC & Mobile Touch)
local function MakeDraggable(obj, dragPart)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    dragPart.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = obj.Position
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
            obj.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Resizing support with mobile constraints
local function MakeResizable(obj, dragPart)
    local dragging = false
    local dragStart = nil
    local startSize = nil

    dragPart.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startSize = obj.Size
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local minW = (UserInputService.TouchEnabled and 480) or 520
            local minH = (UserInputService.TouchEnabled and 320) or 360
            local newWidth = math.max(minW, startSize.X.Offset + delta.X)
            local newHeight = math.max(minH, startSize.Y.Offset + delta.Y)
            obj.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Floating Mobile/PC Open Button (StartBtn)
local wasDraggingStart = false
local lastRatioX = 0.5
local lastRatioY = 0.05

local function MakeDraggableStartBtn(obj, dragPart, clickCallback)
    local dragging = false
    local dragStart, startPos

    dragPart.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            wasDraggingStart = false
            dragStart = input.Position
            startPos = obj.Position
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
            if delta.Magnitude > 6 then
                wasDraggingStart = true
            end

            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            local parentScreen = obj:FindFirstAncestorOfClass("ScreenGui")
            if parentScreen then
                local screenSize = parentScreen.AbsoluteSize
                local currentX = newPos.X.Offset + (screenSize.X * newPos.X.Scale)
                local currentY = newPos.Y.Offset + (screenSize.Y * newPos.Y.Scale)
                local finalX = math.clamp(currentX, 28, math.max(28, screenSize.X - 28))
                local finalY = math.clamp(currentY, 28, math.max(28, screenSize.Y - 28))

                obj.Position = UDim2.new(0, finalX, 0, finalY)
                if screenSize.X > 56 then lastRatioX = finalX / screenSize.X end
                if screenSize.Y > 56 then lastRatioY = finalY / screenSize.Y end
            else
                obj.Position = newPos
            end
        end
    end)

    dragPart.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            if not wasDraggingStart and clickCallback then
                clickCallback()
            end
            dragging = false
        end
    end)
end

-- [[ Serialization for Custom Data Types (Color3, EnumItem, etc.) ]]
local function SerializeData(data)
    local serialized = {}
    for k, v in pairs(data) do
        if typeof(v) == "Color3" then
            serialized[k] = {__type = "Color3", r = v.R, g = v.G, b = v.B}
        elseif typeof(v) == "EnumItem" then
            serialized[k] = {__type = "EnumItem", enum = tostring(v.EnumType), name = v.Name}
        else
            serialized[k] = v
        end
    end
    return serialized
end

local function DeserializeData(data)
    local deserialized = {}
    for k, v in pairs(data) do
        if type(v) == "table" and v.__type == "Color3" then
            deserialized[k] = Color3.new(v.r, v.g, v.b)
        elseif type(v) == "table" and v.__type == "EnumItem" and Enum[v.enum] and Enum[v.enum][v.name] then
            deserialized[k] = Enum[v.enum][v.name]
        else
            deserialized[k] = v
        end
    end
    return deserialized
end

-- [[ Config System ]]
function RaxorHub:GetConfigList()
    local files = SafeListFiles(ConfigFolder)
    local names = {}
    for _, file in ipairs(files) do
        if file:sub(-5) == ".json" then
            local cleanPath = file:gsub("\\", "/")
            local nameWithExtension = cleanPath:gsub(ConfigFolder .. "/", "")
            local finalName = nameWithExtension:gsub("%.json$", "")
            table.insert(names, finalName)
        end
    end
    return names
end

function RaxorHub:SaveCurrentConfig(name)
    if not name or name == "" or name == "---" then return end
    local cleanName = name:gsub("%.json$", "")
    local serialized = SerializeData(RaxorHub.ConfigData)
    local ok, json = pcall(function() return HttpService:JSONEncode(serialized) end)
    if not ok or not json then return end

    SafeWriteFile(ConfigFolder .. "/" .. cleanName .. ".json", json)
    RaxorHub:Notify({
        Title = "Preset Saved",
        Content = "Config '" .. cleanName .. "' has been saved.",
        Duration = 3
    })
    if RaxorHub.OnConfigListChanged then
        pcall(function() RaxorHub.OnConfigListChanged() end)
    end
    if RaxorHub.RefreshPresetsList then
        pcall(function() RaxorHub.RefreshPresetsList() end)
    end
end

function RaxorHub:OverwriteConfig(name)
    if not name or name == "" or name == "---" then
        RaxorHub:Notify({
            Title = "Overwrite Failed",
            Content = "Please select a valid config file.",
            Duration = 2.5
        })
        return
    end
    RaxorHub:SaveCurrentConfig(name)
end

local function ApplySettings(data)
    for id, value in pairs(data) do
        local obj = RaxorHub.Objects[id]
        if obj then
            if obj.Update then obj.Update(value) end
            if obj.Type ~= "Keybind" and obj.Callback then
                task.spawn(function()
                    pcall(function() obj.Callback(value) end)
                end)
            end
        end
    end
end

function RaxorHub:LoadConfigData(name)
    if not name or name == "" or name == "---" then return nil end
    local cleanName = name:gsub("%.json$", "")
    local fileName = ConfigFolder .. "/" .. cleanName .. ".json"
    if SafeIsFile(fileName) then
        local json = SafeReadFile(fileName)
        if json and json ~= "" then
            local ok, rawData = pcall(function() return HttpService:JSONDecode(json) end)
            if ok and type(rawData) == "table" then
                local data = DeserializeData(rawData)
                for id, value in pairs(data) do
                    RaxorHub.ConfigData[id] = value
                end
                ApplySettings(data)
                RaxorHub:Notify({
                    Title = "Preset Loaded",
                    Content = "Config '" .. cleanName .. "' loaded successfully.",
                    Duration = 3
                })
                return data
            end
        end
    end
    return nil
end

function RaxorHub:DeleteConfig(name)
    if not name or name == "" or name == "---" then return end
    local cleanName = name:gsub("%.json$", "")
    local fileName = ConfigFolder .. "/" .. cleanName .. ".json"
    if SafeIsFile(fileName) then
        SafeDelFile(fileName)
        if RaxorHub:GetAutoload() == cleanName then
            RaxorHub:ResetAutoload()
        end
        RaxorHub:Notify({
            Title = "Preset Deleted",
            Content = "Config '" .. cleanName .. "' has been removed.",
            Duration = 3
        })
        if RaxorHub.OnConfigListChanged then
            pcall(function() RaxorHub.OnConfigListChanged() end)
        end
        if RaxorHub.RefreshPresetsList then
            pcall(function() RaxorHub.RefreshPresetsList() end)
        end
    end
end

local function UpdateState(id, value)
    if id then
        RaxorHub.ConfigData[id] = value
    end
end

function RaxorHub:ResetAllSettings()
    for _, obj in pairs(RaxorHub.Objects) do
        if obj.Type == "Keybind" then
            pcall(function()
                if obj.Stop then obj.Stop()
                elseif obj.Connection then obj.Connection:Disconnect() end
            end)
            continue
        end

        if obj.Callback then
            local defaultValue = nil
            if obj.Type == "Slider" then
                defaultValue = (obj.Config and obj.Config.Min) or 0
            elseif obj.Type == "Toggle" then
                defaultValue = false
            elseif obj.Type == "Dropdown" then
                defaultValue = obj.Default or ""
            elseif obj.Type == "MultiSelect" then
                defaultValue = {}
            elseif obj.Type == "Input" then
                defaultValue = ""
            elseif obj.Type == "ColorPicker" then
                defaultValue = obj.Default or Colors.Accent
            end

            if defaultValue ~= nil then
                task.spawn(function()
                    pcall(function() obj.Callback(defaultValue) end)
                end)
            end

            if obj.Update then
                pcall(function() obj.Update(defaultValue) end)
            end
        end
    end
end

local AutoloadFile = ConfigFolder .. "/autoload.txt"
function RaxorHub:SetAutoload(name)
    if not name or name == "" or name == "---" then return end
    local cleanName = name:gsub("%.json$", "")
    SafeWriteFile(AutoloadFile, cleanName)
    RaxorHub:Notify({
        Title = "Autoload Set",
        Content = "Set autoload to '" .. cleanName .. "'.",
        Duration = 3
    })
    if RaxorHub.OnAutoloadChanged then
        pcall(function() RaxorHub.OnAutoloadChanged(cleanName) end)
    end
    if RaxorHub.RefreshPresetsList then
        pcall(function() RaxorHub.RefreshPresetsList() end)
    end
end

function RaxorHub:GetAutoload()
    if SafeIsFile(AutoloadFile) then
        local content = SafeReadFile(AutoloadFile)
        if content and content ~= "" and content ~= "None" then
            return content:gsub("%s+", "")
        end
    end
    return nil
end

function RaxorHub:ResetAutoload()
    if SafeIsFile(AutoloadFile) then
        SafeDelFile(AutoloadFile)
    end
    RaxorHub:Notify({
        Title = "Autoload Reset",
        Content = "Autoload has been reset.",
        Duration = 3
    })
    if RaxorHub.OnAutoloadChanged then
        pcall(function() RaxorHub.OnAutoloadChanged(nil) end)
    end
    if RaxorHub.RefreshPresetsList then
        pcall(function() RaxorHub.RefreshPresetsList() end)
    end
end

function RaxorHub:CheckPlaceId(allowedMaps)
    if type(allowedMaps) ~= "table" then return true end
    local currentId = game.PlaceId
    for _, id in ipairs(allowedMaps) do
        if currentId == id then return true end
    end
    LocalPlayer:Kick("Unsupported Game | PlaceId: " .. tostring(currentId))
    return false
end

-- [[ Modern Notification Toast System ]]
local NotificationHolder = nil
function RaxorHub:Notify(config)
    if not NotificationHolder then return end
    config = config or {}
    local title = config.Title or "RaxorHub"
    local content = config.Content or ""
    local duration = config.Duration or 3.5

    local Toast = Instance.new("Frame")
    Toast.Size = UDim2.new(1, 0, 0, 58)
    Toast.Position = UDim2.new(1, 40, 0, 0)
    Toast.BackgroundColor3 = Colors.ModalBg
    Toast.BorderSizePixel = 0
    Toast.ZIndex = 9000
    Toast.Parent = NotificationHolder
    Instance.new("UICorner", Toast).CornerRadius = UDim.new(0, 8)
    AddStroke(Toast, Colors.BorderFocus, 1)

    local AccentBar = Instance.new("Frame")
    AccentBar.Size = UDim2.new(0, 3, 1, -12)
    AccentBar.Position = UDim2.new(0, 4, 0.5, 0)
    AccentBar.AnchorPoint = Vector2.new(0, 0.5)
    AccentBar.BackgroundColor3 = Colors.Accent
    AccentBar.BorderSizePixel = 0
    AccentBar.ZIndex = 9001
    AccentBar.Parent = Toast
    Instance.new("UICorner", AccentBar).CornerRadius = UDim.new(1, 0)

    local TTitle = Instance.new("TextLabel")
    TTitle.Size = UDim2.new(1, -24, 0, 20)
    TTitle.Position = UDim2.new(0, 14, 0, 8)
    TTitle.Text = title
    TTitle.Font = Fonts.Title
    TTitle.TextSize = 13
    TTitle.TextColor3 = Colors.Text
    TTitle.TextXAlignment = Enum.TextXAlignment.Left
    TTitle.BackgroundTransparency = 1
    TTitle.ZIndex = 9001
    TTitle.Parent = Toast

    local TContent = Instance.new("TextLabel")
    TContent.Size = UDim2.new(1, -24, 0, 18)
    TContent.Position = UDim2.new(0, 14, 0, 28)
    TContent.Text = content
    TContent.Font = Fonts.Regular
    TContent.TextSize = 12
    TContent.TextColor3 = Colors.SubText
    TContent.TextXAlignment = Enum.TextXAlignment.Left
    TContent.BackgroundTransparency = 1
    TContent.ZIndex = 9001
    TContent.Parent = Toast

    local ProgressLine = Instance.new("Frame")
    ProgressLine.Size = UDim2.new(1, 0, 0, 2)
    ProgressLine.Position = UDim2.new(0, 0, 1, -2)
    ProgressLine.BackgroundColor3 = Colors.Accent
    ProgressLine.BorderSizePixel = 0
    ProgressLine.ZIndex = 9002
    ProgressLine.Parent = Toast
    Instance.new("UICorner", ProgressLine).CornerRadius = UDim.new(1, 0)

    Tween(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
    Tween(ProgressLine, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)})

    task.delay(duration, function()
        if Toast and Toast.Parent then
            local t = Tween(Toast, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1, 40, 0, 0)})
            t.Completed:Connect(function()
                Toast:Destroy()
            end)
        end
    end)
end

-- [[ Main Window Constructor ]]
function RaxorHub:Window(GuiConfig)
    GuiConfig = GuiConfig or {}
    local window = {Tabs = {}, CountTab = 0, TabButtons = {}}

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = UI_NAME
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    ScreenGui.DisplayOrder = 9999

    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    elseif gethui then
        ScreenGui.Parent = gethui()
    elseif CoreGuiSuccess and CoreGui then
        local ok = pcall(function() ScreenGui.Parent = CoreGui end)
        if not ok then ScreenGui.Parent = PlayerGui end
    else
        ScreenGui.Parent = PlayerGui
    end

    -- [[ Tooltip System for PC Hover (Blade Aesthetic) ]]
    local TooltipFrame = Instance.new("Frame")
    TooltipFrame.Name = "RaxorTooltip"
    TooltipFrame.Size = UDim2.new(0, 100, 0, 26)
    TooltipFrame.BackgroundColor3 = Color3.fromRGB(24, 25, 34)
    TooltipFrame.BorderSizePixel = 0
    TooltipFrame.Visible = false
    TooltipFrame.ZIndex = 99999
    TooltipFrame.Parent = ScreenGui
    Instance.new("UICorner", TooltipFrame).CornerRadius = UDim.new(0, 6)
    AddStroke(TooltipFrame, Colors.Accent, 1)

    local TooltipLabel = Instance.new("TextLabel")
    TooltipLabel.Name = "Text"
    TooltipLabel.Size = UDim2.new(1, -16, 1, 0)
    TooltipLabel.Position = UDim2.new(0, 8, 0, 0)
    TooltipLabel.BackgroundTransparency = 1
    TooltipLabel.Font = Fonts.Medium
    TooltipLabel.TextSize = 11
    TooltipLabel.TextColor3 = Colors.Text
    TooltipLabel.TextXAlignment = Enum.TextXAlignment.Center
    TooltipLabel.ZIndex = 100000
    TooltipLabel.Parent = TooltipFrame

    local tooltipConn = nil
    local function ShowTooltip(text)
        if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then return end
        TooltipLabel.Text = text
        local TextService = game:GetService("TextService")
        local sz = TextService:GetTextSize(text, 11, Fonts.Medium, Vector2.new(500, 50))
        TooltipFrame.Size = UDim2.new(0, sz.X + 18, 0, 26)
        local function updatePos()
            local mousePos = UserInputService:GetMouseLocation()
            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
            local tw = TooltipFrame.AbsoluteSize.X
            local posX = mousePos.X + 14
            if posX + tw > vp.X - 8 then
                posX = mousePos.X - tw - 14
            end
            local posY = mousePos.Y - 30
            if posY < 8 then
                posY = mousePos.Y + 22
            end
            TooltipFrame.Position = UDim2.new(0, posX, 0, posY)
        end
        updatePos()
        TooltipFrame.Visible = true
        if tooltipConn then tooltipConn:Disconnect() end
        tooltipConn = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                updatePos()
            end
        end)
    end

    local function HideTooltip()
        TooltipFrame.Visible = false
        if tooltipConn then
            tooltipConn:Disconnect()
            tooltipConn = nil
        end
    end

    local function AttachTooltip(guiObject, tooltipText)
        if not guiObject then return end
        guiObject.MouseEnter:Connect(function()
            ShowTooltip(tooltipText)
        end)
        guiObject.MouseLeave:Connect(function()
            HideTooltip()
        end)
    end

    -- Responsive default size for Mobile & PC
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local frameW = math.clamp(viewport.X * 0.85, 520, 700)
    local frameH = math.clamp(viewport.Y * 0.82, 360, 460)

    if not isMobile and viewport.X > 900 then
        frameW = 680
        frameH = 450
    end

    MainFrame = Instance.new("Frame")
    RaxorHub.MainFrame = MainFrame
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, frameW, 0, frameH)
    MainFrame.Position = UDim2.new(0.5, -frameW / 2, 0.5, -frameH / 2)
    MainFrame.BackgroundColor3 = Colors.WindowBg
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = false
    MainFrame.ZIndex = 10
    MainFrame.Parent = ScreenGui

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
    AddStroke(MainFrame, Colors.Border, 1)

    -- Notification Stack Holder
    NotificationHolder = Instance.new("Frame")
    NotificationHolder.Name = "NotificationHolder"
    NotificationHolder.Size = UDim2.new(0, 250, 1, -40)
    NotificationHolder.Position = UDim2.new(1, -260, 1, -20)
    NotificationHolder.AnchorPoint = Vector2.new(0, 1)
    NotificationHolder.BackgroundTransparency = 1
    NotificationHolder.ZIndex = 8999
    NotificationHolder.Parent = ScreenGui

    local NotifLayout = Instance.new("UIListLayout")
    NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    NotifLayout.Padding = UDim.new(0, 8)
    NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifLayout.Parent = NotificationHolder

    -- Floating Mobile / PC Toggle Button (Clean transparent logo only, with tilt animation)
    StartBtn = Instance.new("ImageButton")
    RaxorHub.StartBtn = StartBtn
    StartBtn.Name = "StartBtn"
    StartBtn.Size = UDim2.new(0, 52, 0, 52)
    StartBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    StartBtn.Position = UDim2.new(0.5, 0, 0.06, 26)
    StartBtn.BackgroundTransparency = 1
    StartBtn.BorderSizePixel = 0
    StartBtn.Image = Icons.Logo
    StartBtn.ImageColor3 = Colors.White
    StartBtn.Visible = false
    StartBtn.ZIndex = 8000
    StartBtn.Parent = ScreenGui

    local isLogoAnimating = false
    local function PlayLogoTiltAnimation(callback)
        if isLogoAnimating then
            if callback then callback() end
            return
        end
        isLogoAnimating = true
        -- Cool tilt animation (-16 degrees) with bounce
        local t1 = Tween(StartBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Rotation = -16,
            Size = UDim2.new(0, 46, 0, 46)
        })
        t1.Completed:Connect(function()
            local t2 = Tween(StartBtn, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Rotation = 0,
                Size = UDim2.new(0, 52, 0, 52)
            })
            t2.Completed:Connect(function()
                isLogoAnimating = false
                if callback then callback() end
            end)
        end)
    end

    StartBtn.MouseEnter:Connect(function()
        if not isLogoAnimating then
            Tween(StartBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Rotation = -6,
                Size = UDim2.new(0, 56, 0, 56)
            })
        end
    end)
    StartBtn.MouseLeave:Connect(function()
        if not isLogoAnimating then
            Tween(StartBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Rotation = 0,
                Size = UDim2.new(0, 52, 0, 52)
            })
        end
    end)

    local isToggling = false
    local savedFrameSize = UDim2.new(0, frameW, 0, frameH)
    local function ToggleUI()
        if isToggling then return end
        isToggling = true
        CloseAllDropdowns()
        if PresetsModal then PresetsModal.Visible = false end
        if MainFrame.Visible then
            savedFrameSize = MainFrame.Size
            local t = Tween(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, MainFrame.AbsoluteSize.X * 0.95, 0, MainFrame.AbsoluteSize.Y * 0.95)
            })
            t.Completed:Connect(function()
                MainFrame.Visible = false
                MainFrame.Size = savedFrameSize
                MainFrame.BackgroundTransparency = 0
                StartBtn.Visible = true
                isToggling = false
            end)
        else
            MainFrame.Visible = true
            StartBtn.Visible = false
            MainFrame.Size = UDim2.new(0, savedFrameSize.X.Offset * 0.95, 0, savedFrameSize.Y.Offset * 0.95)
            MainFrame.BackgroundTransparency = 0
            local t = Tween(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = savedFrameSize,
                BackgroundTransparency = 0
            })
            t.Completed:Connect(function()
                isToggling = false
            end)
        end
    end
    RaxorHub.ToggleUI = ToggleUI

    MakeDraggableStartBtn(StartBtn, StartBtn, function()
        PlayLogoTiltAnimation(function()
            ToggleUI()
        end)
    end)

    -- [[ Resizer Corner (Sleek Modern Diagonal Grip Lines) ]]
    local ResizeHandle = Instance.new("Frame")
    ResizeHandle.Name = "ResizeHandle"
    ResizeHandle.Size = UDim2.new(0, 24, 0, 24)
    ResizeHandle.Position = UDim2.new(1, -24, 1, -24)
    ResizeHandle.BackgroundTransparency = 1
    ResizeHandle.ZIndex = 5000
    ResizeHandle.Parent = MainFrame

    local gripLines = {}
    local lineSpecs = {
        { size = 4,  offset = 6 },
        { size = 8,  offset = 10 },
        { size = 12, offset = 14 }
    }

    for i, spec in ipairs(lineSpecs) do
        local line = Instance.new("Frame")
        line.Name = "GripLine" .. i
        line.Size = UDim2.new(0, spec.size, 0, 2)
        line.Position = UDim2.new(1, -spec.offset, 1, -spec.offset)
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Rotation = -45
        line.BackgroundColor3 = Colors.MutedText
        line.BackgroundTransparency = 0.4
        line.BorderSizePixel = 0
        line.ZIndex = 5001
        line.Parent = ResizeHandle
        Instance.new("UICorner", line).CornerRadius = UDim.new(0, 1)
        table.insert(gripLines, line)
    end

    ResizeHandle.MouseEnter:Connect(function()
        for _, line in ipairs(gripLines) do
            Tween(line, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Colors.AccentHover,
                BackgroundTransparency = 0
            })
        end
    end)
    ResizeHandle.MouseLeave:Connect(function()
        for _, line in ipairs(gripLines) do
            Tween(line, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Colors.MutedText,
                BackgroundTransparency = 0.4
            })
        end
    end)

    AttachTooltip(ResizeHandle, "Drag to Resize Window")

    MakeResizable(MainFrame, ResizeHandle)

    -- [[ Left Sidebar (Blade Style) ]]
    local SidebarWidth = 175
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, SidebarWidth, 1, 0)
    Sidebar.Position = UDim2.new(0, 0, 0, 0)
    Sidebar.BackgroundColor3 = Colors.SidebarBg
    Sidebar.BorderSizePixel = 0
    Sidebar.ClipsDescendants = true
    Sidebar.ZIndex = 20
    Sidebar.Parent = MainFrame
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

    local SidebarDivider = Instance.new("Frame")
    SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
    SidebarDivider.Position = UDim2.new(1, -1, 0, 0)
    SidebarDivider.BackgroundColor3 = Colors.Border
    SidebarDivider.BorderSizePixel = 0
    SidebarDivider.ZIndex = 21
    SidebarDivider.Parent = Sidebar

    -- Logo & Brand Header in Sidebar (RaxorHub Official Logo)
    local BrandContainer = Instance.new("Frame")
    BrandContainer.Name = "BrandContainer"
    BrandContainer.Size = UDim2.new(1, 0, 0, 50)
    BrandContainer.BackgroundTransparency = 1
    BrandContainer.ZIndex = 22
    BrandContainer.Active = true
    BrandContainer.Parent = Sidebar

    local BrandLogo = Instance.new("ImageLabel")
    BrandLogo.Size = UDim2.new(0, 28, 0, 28)
    BrandLogo.Position = UDim2.new(0, 12, 0.5, -14)
    BrandLogo.Image = GuiConfig.Logo or Icons.Logo
    BrandLogo.ImageColor3 = Colors.White
    BrandLogo.BackgroundTransparency = 1
    BrandLogo.Active = false
    BrandLogo.ZIndex = 23
    BrandLogo.Parent = BrandContainer

    local BrandTitle = Instance.new("TextLabel")
    BrandTitle.Text = string.upper(GuiConfig.Title or "RAXOR")
    BrandTitle.Font = Fonts.Brand
    BrandTitle.TextSize = 16
    BrandTitle.TextColor3 = Colors.Text
    BrandTitle.Position = UDim2.new(0, 46, 0.5, -9)
    BrandTitle.Size = UDim2.new(1, -80, 0, 18)
    BrandTitle.TextTruncate = Enum.TextTruncate.AtEnd
    BrandTitle.TextXAlignment = Enum.TextXAlignment.Left
    BrandTitle.BackgroundTransparency = 1
    BrandTitle.Active = false
    BrandTitle.ZIndex = 23
    BrandTitle.Parent = BrandContainer

    -- Mini Collapse Button on the header of the sidebar itself
    local SidebarHeaderCloseBtn = Instance.new("ImageButton")
    SidebarHeaderCloseBtn.Name = "SidebarHeaderCloseBtn"
    SidebarHeaderCloseBtn.Size = UDim2.new(0, 24, 0, 24)
    SidebarHeaderCloseBtn.Position = UDim2.new(1, -32, 0.5, -12)
    SidebarHeaderCloseBtn.BackgroundColor3 = Colors.ControlBtn
    SidebarHeaderCloseBtn.AutoButtonColor = false
    SidebarHeaderCloseBtn.ZIndex = 24
    SidebarHeaderCloseBtn.Parent = BrandContainer
    Instance.new("UICorner", SidebarHeaderCloseBtn).CornerRadius = UDim.new(0, 6)
    local headerCloseStroke = AddStroke(SidebarHeaderCloseBtn, Colors.Border, 1)

    local headerCloseIcon = Instance.new("ImageLabel")
    headerCloseIcon.Size = UDim2.new(0, 12, 0, 12)
    headerCloseIcon.Position = UDim2.new(0.5, -6, 0.5, -6)
    headerCloseIcon.Image = Icons.ChevronDown
    headerCloseIcon.Rotation = 90 -- Points left ❮
    headerCloseIcon.ImageColor3 = Colors.SubText
    headerCloseIcon.BackgroundTransparency = 1
    headerCloseIcon.ZIndex = 25
    headerCloseIcon.Parent = SidebarHeaderCloseBtn

    SidebarHeaderCloseBtn.MouseEnter:Connect(function()
        Tween(SidebarHeaderCloseBtn, TweenInfo.new(0.12), { BackgroundColor3 = Colors.ButtonHover })
        Tween(headerCloseIcon, TweenInfo.new(0.12), { ImageColor3 = Colors.White })
        headerCloseStroke.Color = Colors.Accent
    end)
    SidebarHeaderCloseBtn.MouseLeave:Connect(function()
        Tween(SidebarHeaderCloseBtn, TweenInfo.new(0.12), { BackgroundColor3 = Colors.ControlBtn })
        Tween(headerCloseIcon, TweenInfo.new(0.12), { ImageColor3 = Colors.SubText })
        headerCloseStroke.Color = Colors.Border
    end)
    AttachTooltip(SidebarHeaderCloseBtn, "Collapse Sidebar (Hide Tabs)")

    -- Sidebar Tab Navigation Scroll
    local SidebarScroll = Instance.new("ScrollingFrame")
    SidebarScroll.Size = UDim2.new(1, -8, 1, -118)
    SidebarScroll.Position = UDim2.new(0, 4, 0, 52)
    SidebarScroll.BackgroundTransparency = 1
    SidebarScroll.BorderSizePixel = 0
    SidebarScroll.ScrollBarThickness = 0
    SidebarScroll.ScrollingEnabled = true
    SidebarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    SidebarScroll.ZIndex = 22
    SidebarScroll.Parent = Sidebar

    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.Padding = UDim.new(0, 3)
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.Parent = SidebarScroll

    -- [[ User Profile Card at Bottom Left (Blade Past Owl Widget) ]]
    local ProfileCard = Instance.new("Frame")
    ProfileCard.Name = "ProfileCard"
    ProfileCard.Size = UDim2.new(1, -14, 0, 50)
    ProfileCard.Position = UDim2.new(0, 7, 1, -58)
    ProfileCard.BackgroundColor3 = Colors.CardBg
    ProfileCard.BorderSizePixel = 0
    ProfileCard.ZIndex = 25
    ProfileCard.Parent = Sidebar
    Instance.new("UICorner", ProfileCard).CornerRadius = UDim.new(0, 8)
    AddStroke(ProfileCard, Colors.Border, 1)

    local AvatarImg = Instance.new("ImageLabel")
    AvatarImg.Size = UDim2.new(0, 32, 0, 32)
    AvatarImg.Position = UDim2.new(0, 8, 0.5, -16)
    AvatarImg.BackgroundColor3 = Colors.MainCardBg
    AvatarImg.Image = Icons.Logo
    AvatarImg.ZIndex = 26
    AvatarImg.Parent = ProfileCard
    Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)
    AddStroke(AvatarImg, Colors.BorderFocus, 1)

    task.spawn(function()
        pcall(function()
            local thumbType = Enum.ThumbnailType.HeadShot
            local thumbSize = Enum.ThumbnailSize.Size48x48
            local content, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, thumbType, thumbSize)
            if isReady and content then
                AvatarImg.Image = content
            end
        end)
    end)

    local ProfileName = Instance.new("TextLabel")
    ProfileName.Text = LocalPlayer and LocalPlayer.DisplayName or "User"
    ProfileName.Font = Fonts.Title
    ProfileName.TextSize = 13
    ProfileName.TextColor3 = Colors.Text
    ProfileName.Size = UDim2.new(1, -48, 0, 16)
    ProfileName.Position = UDim2.new(0, 46, 0, 9)
    ProfileName.TextXAlignment = Enum.TextXAlignment.Left
    ProfileName.TextTruncate = Enum.TextTruncate.AtEnd
    ProfileName.BackgroundTransparency = 1
    ProfileName.ZIndex = 26
    ProfileName.Parent = ProfileCard

    local ProfileStatus = Instance.new("TextLabel")
    ProfileStatus.Text = GuiConfig.ProfileTag or "Till: Lifetime"
    ProfileStatus.Font = Fonts.Medium
    ProfileStatus.TextSize = 12
    ProfileStatus.TextColor3 = Colors.SubText
    ProfileStatus.Size = UDim2.new(1, -48, 0, 14)
    ProfileStatus.Position = UDim2.new(0, 46, 0, 26)
    ProfileStatus.TextXAlignment = Enum.TextXAlignment.Left
    ProfileStatus.TextTruncate = Enum.TextTruncate.AtEnd
    ProfileStatus.BackgroundTransparency = 1
    ProfileStatus.ZIndex = 26
    ProfileStatus.Parent = ProfileCard

    -- [[ Top Bar Area (Fixed overlapping: Search on Left, Controls on Right) ]]
    -- Dedicated Full-Top Drag Area (entire top width except 145px for top-right control buttons)
    local TopDragZone = Instance.new("Frame")
    TopDragZone.Name = "TopDragZone"
    TopDragZone.Size = UDim2.new(1, -145, 0, 50)
    TopDragZone.Position = UDim2.new(0, 0, 0, 0)
    TopDragZone.BackgroundTransparency = 1
    TopDragZone.ZIndex = 34
    TopDragZone.Active = true
    TopDragZone.Parent = MainFrame

    MakeDraggable(MainFrame, TopDragZone)
    MakeDraggable(MainFrame, BrandContainer)

    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, -SidebarWidth, 0, 48)
    TopBar.Position = UDim2.new(0, SidebarWidth, 0, 0)
    TopBar.BackgroundColor3 = Colors.TopBarBg
    TopBar.BackgroundTransparency = 0
    TopBar.BorderSizePixel = 0
    TopBar.ZIndex = 30
    TopBar.Active = true
    TopBar.Parent = MainFrame

    MakeDraggable(MainFrame, TopBar)

    local TopDivider = Instance.new("Frame")
    TopDivider.Size = UDim2.new(1, 0, 0, 1)
    TopDivider.Position = UDim2.new(0, 0, 1, -1)
    TopDivider.BackgroundColor3 = Colors.Border
    TopDivider.BorderSizePixel = 0
    TopDivider.ZIndex = 31
    TopDivider.Parent = TopBar

    -- Top Right Controls (Folder, Min, Restore, Close) - Fixed width 140px
    local Controls = Instance.new("Frame")
    Controls.Name = "Controls"
    Controls.Size = UDim2.new(0, 140, 1, 0)
    Controls.Position = UDim2.new(1, -10, 0, 0)
    Controls.AnchorPoint = Vector2.new(1, 0)
    Controls.BackgroundTransparency = 1
    Controls.ZIndex = 35
    Controls.Parent = TopBar

    local ControlLayout = Instance.new("UIListLayout")
    ControlLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlLayout.Padding = UDim.new(0, 6)
    ControlLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ControlLayout.Parent = Controls

    -- Helper to create sleek top buttons with custom white line icons
    local function CreateTopIconBtn(name, iconId, baseColor, hoverColor, order, callback)
        local btn = Instance.new("ImageButton")
        btn.Name = name
        btn.LayoutOrder = order
        btn.Size = UDim2.new(0, 26, 0, 26)
        btn.BackgroundColor3 = baseColor or Colors.ControlBtn
        btn.Image = iconId or ""
        btn.ImageColor3 = Colors.SubText
        btn.AutoButtonColor = false
        btn.ZIndex = 36
        btn.Parent = Controls
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        AddStroke(btn, Colors.Border, 1)

        btn.MouseEnter:Connect(function()
            Tween(btn, TweenInfo.new(0.12), {BackgroundColor3 = hoverColor or Colors.ButtonHover, ImageColor3 = Colors.White})
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, TweenInfo.new(0.12), {BackgroundColor3 = baseColor or Colors.ControlBtn, ImageColor3 = Colors.SubText})
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- Folder Button -> Opens Presets Modal (Icon 12)
    local folderBtn = CreateTopIconBtn("FolderBtn", Icons.Folder, Colors.ControlBtn, Colors.ButtonHover, 1, function()
        if PresetsModal then
            PresetsModal.Visible = not PresetsModal.Visible
        end
    end)
    AttachTooltip(folderBtn, "Presets Configuration (Config Hub)")

    -- Minimize Button (Icon 9)
    local minBtn = CreateTopIconBtn("MinBtn", Icons.Minimize, Colors.ControlBtn, Colors.ButtonHover, 2, function()
        ToggleUI()
    end)
    AttachTooltip(minBtn, "Minimize Window")

    -- Restore / Center Button (Icon 10)
    local resBtn = CreateTopIconBtn("ResBtn", Icons.Restore, Colors.ControlBtn, Colors.ButtonHover, 3, function()
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        MainFrame.Position = UDim2.new(0.5, -MainFrame.AbsoluteSize.X / 2, 0.5, -MainFrame.AbsoluteSize.Y / 2)
    end)
    AttachTooltip(resBtn, "Center Window on Screen")

    -- Close Button (Icon 11)
    local closeBtn = CreateTopIconBtn("CloseBtn", Icons.Close, Colors.ControlBtn, Colors.CloseRed, 4, function()
        if window and window.OnClose then
            pcall(window.OnClose)
        elseif RaxorHub.OnClose then
            pcall(RaxorHub.OnClose)
        end
        RaxorHub:ResetAllSettings()
        task.wait(0.1)
        ScreenGui:Destroy()
    end)
    AttachTooltip(closeBtn, "Close RaxorHub")

    -- [[ Sidebar Collapse / Expand Toggle Button (Responsive & Mobile Touch Ready) ]]
    local isSidebarCollapsed = false
    local isSidebarAnimating = false
    local ToggleSidebar = nil

    local toggleBtnW = (isMobile and 30) or 28
    local toggleBtnH = (isMobile and 30) or 28

    local SidebarToggleBtn = Instance.new("ImageButton")
    SidebarToggleBtn.Name = "SidebarToggleBtn"
    SidebarToggleBtn.Size = UDim2.new(0, toggleBtnW, 0, toggleBtnH)
    SidebarToggleBtn.Position = UDim2.new(0, 10, 0.5, -toggleBtnH / 2)
    SidebarToggleBtn.BackgroundColor3 = Colors.ControlBtn
    SidebarToggleBtn.AutoButtonColor = false
    SidebarToggleBtn.ZIndex = 36
    SidebarToggleBtn.Parent = TopBar
    Instance.new("UICorner", SidebarToggleBtn).CornerRadius = UDim.new(0, 6)
    local toggleBtnStroke = AddStroke(SidebarToggleBtn, Colors.Border, 1)

    -- Toggle Icon: Chevron that rotates smoothly to indicate collapse / expand
    local ToggleIcon = Instance.new("ImageLabel")
    ToggleIcon.Name = "ToggleIcon"
    ToggleIcon.Size = UDim2.new(0, 14, 0, 14)
    ToggleIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
    ToggleIcon.Image = Icons.ChevronDown
    ToggleIcon.Rotation = 90 -- Points left ❮ when sidebar is open (meaning: click to collapse)
    ToggleIcon.ImageColor3 = Colors.SubText
    ToggleIcon.BackgroundTransparency = 1
    ToggleIcon.ZIndex = 37
    ToggleIcon.Parent = SidebarToggleBtn

    -- Subtle accent indicator pill inside the button (stylish Blade aesthetic)
    local TogglePill = Instance.new("Frame")
    TogglePill.Name = "TogglePill"
    TogglePill.Size = UDim2.new(0, 2, 0, 14)
    TogglePill.Position = UDim2.new(0, 4, 0.5, -7)
    TogglePill.BackgroundColor3 = Colors.Accent
    TogglePill.BorderSizePixel = 0
    TogglePill.ZIndex = 37
    TogglePill.Parent = SidebarToggleBtn
    Instance.new("UICorner", TogglePill).CornerRadius = UDim.new(1, 0)

    -- Hover effect
    SidebarToggleBtn.MouseEnter:Connect(function()
        if not isSidebarAnimating then
            Tween(SidebarToggleBtn, TweenInfo.new(0.15), { BackgroundColor3 = Colors.ButtonHover })
            Tween(ToggleIcon, TweenInfo.new(0.15), { ImageColor3 = Colors.White })
            toggleBtnStroke.Color = Colors.Accent
        end
    end)
    SidebarToggleBtn.MouseLeave:Connect(function()
        if not isSidebarAnimating then
            local baseBg = isSidebarCollapsed and Colors.ButtonHover or Colors.ControlBtn
            local baseStroke = isSidebarCollapsed and Colors.Accent or Colors.Border
            local baseIconCol = isSidebarCollapsed and Colors.Accent or Colors.SubText
            Tween(SidebarToggleBtn, TweenInfo.new(0.15), { BackgroundColor3 = baseBg })
            Tween(ToggleIcon, TweenInfo.new(0.15), { ImageColor3 = baseIconCol })
            toggleBtnStroke.Color = baseStroke
        end
    end)

    AttachTooltip(SidebarToggleBtn, "Collapse Sidebar (Hide Tabs)")

    -- Search Element Box (Left-aligned, flexible width, NEVER overlaps with controls!)
    local searchOffsetLeft = 10 + toggleBtnW + 8 -- 46px on PC, 48px on Mobile
    local SearchContainer = Instance.new("Frame")
    SearchContainer.Name = "SearchContainer"
    SearchContainer.Size = UDim2.new(1, -searchOffsetLeft - 150, 0, 30)
    SearchContainer.Position = UDim2.new(0, searchOffsetLeft, 0.5, -15)
    SearchContainer.BackgroundColor3 = Colors.InputBg
    SearchContainer.ZIndex = 32
    SearchContainer.Parent = TopBar
    Instance.new("UICorner", SearchContainer).CornerRadius = UDim.new(0, 6)
    local searchStroke = AddStroke(SearchContainer, Colors.Border, 1)

    -- Clamp max search width to 240px
    local searchConstraint = Instance.new("UISizeConstraint")
    searchConstraint.MaxSize = Vector2.new(220, 30)
    searchConstraint.MinSize = Vector2.new(70, 30)
    searchConstraint.Parent = SearchContainer

    local SearchIcon = Instance.new("ImageLabel")
    SearchIcon.Size = UDim2.new(0, 14, 0, 14)
    SearchIcon.Position = UDim2.new(0, 8, 0.5, -7)
    SearchIcon.Image = Icons.Search
    SearchIcon.ImageColor3 = Colors.MutedText
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.ZIndex = 33
    SearchIcon.Parent = SearchContainer

    local SearchInput = Instance.new("TextBox")
    SearchInput.Size = UDim2.new(1, -30, 1, 0)
    SearchInput.Position = UDim2.new(0, 26, 0, 0)
    SearchInput.BackgroundTransparency = 1
    SearchInput.Text = ""
    SearchInput.PlaceholderText = "Search element..."
    SearchInput.PlaceholderColor3 = Colors.MutedText
    SearchInput.TextColor3 = Colors.Text
    SearchInput.Font = Fonts.Regular
    SearchInput.TextSize = 12
    SearchInput.TextXAlignment = Enum.TextXAlignment.Left
    SearchInput.ClearTextOnFocus = false
    SearchInput.ZIndex = 33
    SearchInput.Parent = SearchContainer

    SearchInput.Focused:Connect(function() searchStroke.Color = Colors.Accent end)
    SearchInput.FocusLost:Connect(function() searchStroke.Color = Colors.Border end)

    -- [[ Main Content Container ]]
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -SidebarWidth, 1, -48)
    ContentContainer.Position = UDim2.new(0, SidebarWidth, 0, 48)
    ContentContainer.BackgroundColor3 = Colors.WindowBg
    ContentContainer.BorderSizePixel = 0
    ContentContainer.ClipsDescendants = true
    ContentContainer.ZIndex = 25
    ContentContainer.Parent = MainFrame

    -- [[ Smooth Sidebar Toggle Controller (Desktop & Mobile Touch Optimized) ]]
    ToggleSidebar = function(forceState)
        if isSidebarAnimating then return end
        if forceState ~= nil and forceState == isSidebarCollapsed then return end

        isSidebarAnimating = true
        CloseAllDropdowns()

        local targetState = (forceState ~= nil) and forceState or (not isSidebarCollapsed)
        isSidebarCollapsed = targetState

        local animDuration = 0.28
        local animEasing = Enum.EasingStyle.Quart

        if isSidebarCollapsed then
            -- [[ COLLAPSE SIDEBAR: Expand content to full window width ]]
            Sidebar.ClipsDescendants = true

            -- Button bounce animation & icon rotation
            Tween(SidebarToggleBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, toggleBtnW - 3, 0, toggleBtnH - 3)
            }).Completed:Connect(function()
                Tween(SidebarToggleBtn, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, toggleBtnW, 0, toggleBtnH)
                })
            end)

            Tween(ToggleIcon, TweenInfo.new(animDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Rotation = -90, -- Points right ❯ to expand
                ImageColor3 = Colors.Accent
            })
            Tween(TogglePill, TweenInfo.new(animDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.8
            })
            toggleBtnStroke.Color = Colors.Accent
            AttachTooltip(SidebarToggleBtn, "Expand Sidebar (Show Tabs)")

            local tSidebar = Tween(Sidebar, TweenInfo.new(animDuration, animEasing, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 0, 1, 0)
            })
            local tTopBar = Tween(TopBar, TweenInfo.new(animDuration, animEasing, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, 48)
            })
            local tContent = Tween(ContentContainer, TweenInfo.new(animDuration, animEasing, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 48),
                Size = UDim2.new(1, 0, 1, -48)
            })

            tSidebar.Completed:Connect(function()
                if isSidebarCollapsed then
                    Sidebar.Visible = false
                end
                isSidebarAnimating = false
            end)
        else
            -- [[ EXPAND SIDEBAR: Restore normal sidebar & layout ]]
            Sidebar.Visible = true
            Sidebar.ClipsDescendants = true

            -- Button bounce animation & icon rotation
            Tween(SidebarToggleBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, toggleBtnW - 3, 0, toggleBtnH - 3)
            }).Completed:Connect(function()
                Tween(SidebarToggleBtn, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, toggleBtnW, 0, toggleBtnH)
                })
            end)

            Tween(ToggleIcon, TweenInfo.new(animDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Rotation = 90, -- Points left ❮ to collapse
                ImageColor3 = Colors.SubText
            })
            Tween(TogglePill, TweenInfo.new(animDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0
            })
            toggleBtnStroke.Color = Colors.Border
            AttachTooltip(SidebarToggleBtn, "Collapse Sidebar (Hide Tabs)")

            local tSidebar = Tween(Sidebar, TweenInfo.new(animDuration, animEasing, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, SidebarWidth, 1, 0)
            })
            local tTopBar = Tween(TopBar, TweenInfo.new(animDuration, animEasing, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, SidebarWidth, 0, 0),
                Size = UDim2.new(1, -SidebarWidth, 0, 48)
            })
            local tContent = Tween(ContentContainer, TweenInfo.new(animDuration, animEasing, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, SidebarWidth, 0, 48),
                Size = UDim2.new(1, -SidebarWidth, 1, -48)
            })

            tSidebar.Completed:Connect(function()
                isSidebarAnimating = false
            end)
        end
    end

    -- Wire click & touch events for both buttons
    SidebarToggleBtn.Activated:Connect(function()
        ToggleSidebar()
    end)
    SidebarHeaderCloseBtn.Activated:Connect(function()
        ToggleSidebar(true)
    end)

    window.ToggleSidebar = ToggleSidebar
    RaxorHub.ToggleSidebar = ToggleSidebar

    -- [[ Presets Modal Popup (Complete Configuration Hub - Mobile & PC Optimized) ]]
    PresetsModal = Instance.new("Frame")
    PresetsModal.Name = "PresetsModal"
    PresetsModal.Size = UDim2.new(0, 320, 1, -58)
    PresetsModal.Position = UDim2.new(1, -330, 0, 50)
    PresetsModal.BackgroundColor3 = Colors.ModalBg
    PresetsModal.BorderSizePixel = 0
    PresetsModal.Visible = false
    PresetsModal.ZIndex = 6000
    PresetsModal.Parent = MainFrame
    Instance.new("UICorner", PresetsModal).CornerRadius = UDim.new(0, 10)
    AddStroke(PresetsModal, Colors.BorderFocus, 1.2)

    local PresetsHeader = Instance.new("Frame")
    PresetsHeader.Size = UDim2.new(1, 0, 0, 42)
    PresetsHeader.BackgroundTransparency = 1
    PresetsHeader.ZIndex = 6001
    PresetsHeader.Parent = PresetsModal

    local PresetsIcon = Instance.new("ImageLabel")
    PresetsIcon.Size = UDim2.new(0, 18, 0, 18)
    PresetsIcon.Position = UDim2.new(0, 12, 0.5, -9)
    PresetsIcon.Image = Icons.Folder
    PresetsIcon.ImageColor3 = Colors.Accent
    PresetsIcon.BackgroundTransparency = 1
    PresetsIcon.ZIndex = 6002
    PresetsIcon.Parent = PresetsHeader

    local PresetsTitle = Instance.new("TextLabel")
    PresetsTitle.Text = "Presets Configuration"
    PresetsTitle.Font = Fonts.Title
    PresetsTitle.TextSize = 13
    PresetsTitle.TextColor3 = Colors.Text
    PresetsTitle.Position = UDim2.new(0, 38, 0.5, -9)
    PresetsTitle.Size = UDim2.new(1, -78, 0, 18)
    PresetsTitle.TextXAlignment = Enum.TextXAlignment.Left
    PresetsTitle.BackgroundTransparency = 1
    PresetsTitle.ZIndex = 6002
    PresetsTitle.Parent = PresetsHeader

    local PresetsCloseBtn = Instance.new("ImageButton")
    PresetsCloseBtn.Size = UDim2.new(0, 26, 0, 26)
    PresetsCloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
    PresetsCloseBtn.BackgroundColor3 = Colors.CardBg
    PresetsCloseBtn.BackgroundTransparency = 0.5
    PresetsCloseBtn.Image = Icons.Close
    PresetsCloseBtn.ImageColor3 = Colors.SubText
    PresetsCloseBtn.AutoButtonColor = false
    PresetsCloseBtn.ZIndex = 6002
    PresetsCloseBtn.Parent = PresetsHeader
    Instance.new("UICorner", PresetsCloseBtn).CornerRadius = UDim.new(0, 6)

    PresetsCloseBtn.MouseEnter:Connect(function()
        PresetsCloseBtn.ImageColor3 = Colors.CloseRed
        PresetsCloseBtn.BackgroundTransparency = 0
    end)
    PresetsCloseBtn.MouseLeave:Connect(function()
        PresetsCloseBtn.ImageColor3 = Colors.SubText
        PresetsCloseBtn.BackgroundTransparency = 0.5
    end)
    PresetsCloseBtn.MouseButton1Click:Connect(function()
        PresetsModal.Visible = false
    end)
    AttachTooltip(PresetsCloseBtn, "Close Presets")

    -- New Config Input & Save Button (Large touch target for Mobile)
    local ConfigInputFrame = Instance.new("Frame")
    ConfigInputFrame.Size = UDim2.new(1, -20, 0, 36)
    ConfigInputFrame.Position = UDim2.new(0, 10, 0, 44)
    ConfigInputFrame.BackgroundColor3 = Colors.InputBg
    ConfigInputFrame.ZIndex = 6002
    ConfigInputFrame.Parent = PresetsModal
    Instance.new("UICorner", ConfigInputFrame).CornerRadius = UDim.new(0, 7)
    AddStroke(ConfigInputFrame, Colors.Border, 1)

    local ConfigNameInput = Instance.new("TextBox")
    ConfigNameInput.Size = UDim2.new(1, -44, 1, 0)
    ConfigNameInput.Position = UDim2.new(0, 12, 0, 0)
    ConfigNameInput.BackgroundTransparency = 1
    ConfigNameInput.Text = ""
    ConfigNameInput.PlaceholderText = "New config name..."
    ConfigNameInput.PlaceholderColor3 = Colors.MutedText
    ConfigNameInput.TextColor3 = Colors.Text
    ConfigNameInput.Font = Fonts.Regular
    ConfigNameInput.TextSize = 12
    ConfigNameInput.TextXAlignment = Enum.TextXAlignment.Left
    ConfigNameInput.ClearTextOnFocus = false
    ConfigNameInput.ZIndex = 6003
    ConfigNameInput.Parent = ConfigInputFrame

    local AddConfigBtn = Instance.new("ImageButton")
    AddConfigBtn.Size = UDim2.new(0, 28, 0, 28)
    AddConfigBtn.Position = UDim2.new(1, -32, 0.5, -14)
    AddConfigBtn.BackgroundColor3 = Colors.Accent
    AddConfigBtn.Image = Icons.Save
    AddConfigBtn.ImageColor3 = Colors.White
    AddConfigBtn.AutoButtonColor = false
    AddConfigBtn.ZIndex = 6003
    AddConfigBtn.Parent = ConfigInputFrame
    Instance.new("UICorner", AddConfigBtn).CornerRadius = UDim.new(0, 6)

    AddConfigBtn.MouseEnter:Connect(function()
        Tween(AddConfigBtn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.AccentHover})
    end)
    AddConfigBtn.MouseLeave:Connect(function()
        Tween(AddConfigBtn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.Accent})
    end)
    AttachTooltip(AddConfigBtn, "Save New Preset")

    -- Configs Scrolling List
    local PresetsScroll = Instance.new("ScrollingFrame")
    PresetsScroll.Size = UDim2.new(1, -20, 1, -134)
    PresetsScroll.Position = UDim2.new(0, 10, 0, 88)
    PresetsScroll.BackgroundTransparency = 1
    PresetsScroll.BorderSizePixel = 0
    PresetsScroll.ScrollBarThickness = 3
    PresetsScroll.ScrollBarImageColor3 = Colors.Accent
    PresetsScroll.ZIndex = 6002
    PresetsScroll.Parent = PresetsModal

    local PresetsLayout = Instance.new("UIListLayout")
    PresetsLayout.Padding = UDim.new(0, 6)
    PresetsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PresetsLayout.Parent = PresetsScroll

    -- Footer: Autoload Status & Reset Button
    local FooterFrame = Instance.new("Frame")
    FooterFrame.Size = UDim2.new(1, -20, 0, 36)
    FooterFrame.Position = UDim2.new(0, 10, 1, -40)
    FooterFrame.BackgroundTransparency = 1
    FooterFrame.ZIndex = 6002
    FooterFrame.Parent = PresetsModal

    local FooterDivider = Instance.new("Frame")
    FooterDivider.Size = UDim2.new(1, 0, 0, 1)
    FooterDivider.Position = UDim2.new(0, 0, 0, 0)
    FooterDivider.BackgroundColor3 = Colors.Border
    FooterDivider.BorderSizePixel = 0
    FooterDivider.ZIndex = 6003
    FooterDivider.Parent = FooterFrame

    local FooterStarIcon = Instance.new("ImageLabel")
    FooterStarIcon.Size = UDim2.new(0, 14, 0, 14)
    FooterStarIcon.Position = UDim2.new(0, 4, 0.5, -7)
    FooterStarIcon.Image = Icons.Star
    FooterStarIcon.ImageColor3 = Colors.Accent
    FooterStarIcon.BackgroundTransparency = 1
    FooterStarIcon.ZIndex = 6003
    FooterStarIcon.Parent = FooterFrame

    local FooterAutoLabel = Instance.new("TextLabel")
    FooterAutoLabel.Size = UDim2.new(1, -84, 1, -1)
    FooterAutoLabel.Position = UDim2.new(0, 24, 0, 1)
    FooterAutoLabel.BackgroundTransparency = 1
    FooterAutoLabel.Font = Fonts.Medium
    FooterAutoLabel.TextSize = 11
    FooterAutoLabel.TextColor3 = Colors.SubText
    FooterAutoLabel.TextXAlignment = Enum.TextXAlignment.Left
    FooterAutoLabel.TextTruncate = Enum.TextTruncate.AtEnd
    FooterAutoLabel.ZIndex = 6003
    FooterAutoLabel.Parent = FooterFrame

    local FooterResetBtn = Instance.new("TextButton")
    FooterResetBtn.Size = UDim2.new(0, 56, 0, 24)
    FooterResetBtn.Position = UDim2.new(1, -56, 0.5, -12)
    FooterResetBtn.BackgroundColor3 = Colors.ButtonBg
    FooterResetBtn.Text = "Reset"
    FooterResetBtn.Font = Fonts.Medium
    FooterResetBtn.TextSize = 11
    FooterResetBtn.TextColor3 = Colors.SubText
    FooterResetBtn.AutoButtonColor = false
    FooterResetBtn.ZIndex = 6003
    FooterResetBtn.Parent = FooterFrame
    Instance.new("UICorner", FooterResetBtn).CornerRadius = UDim.new(0, 5)
    AddStroke(FooterResetBtn, Colors.Border, 1)

    FooterResetBtn.MouseEnter:Connect(function()
        Tween(FooterResetBtn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.ButtonHover, TextColor3 = Colors.White})
    end)
    FooterResetBtn.MouseLeave:Connect(function()
        Tween(FooterResetBtn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.ButtonBg, TextColor3 = Colors.SubText})
    end)
    AttachTooltip(FooterResetBtn, "Clear Autoload")

    local function RefreshPresetsList()
        -- FIX BUG: Clean up ALL previous items (including TextLabel and Frames) except layouts
        for _, c in pairs(PresetsScroll:GetChildren()) do
            if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
                c:Destroy()
            end
        end

        local currentAutoload = RaxorHub:GetAutoload()
        if currentAutoload and currentAutoload ~= "" then
            FooterAutoLabel.Text = "Auto: " .. currentAutoload
            FooterAutoLabel.TextColor3 = Colors.Accent
            FooterStarIcon.ImageColor3 = Colors.Accent
            FooterResetBtn.Visible = true
        else
            FooterAutoLabel.Text = "Auto: None"
            FooterAutoLabel.TextColor3 = Colors.MutedText
            FooterStarIcon.ImageColor3 = Colors.MutedText
            FooterResetBtn.Visible = false
        end

        local configs = RaxorHub:GetConfigList()
        PresetsScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(#configs * 50, 0))

        if #configs == 0 then
            local emptyContainer = Instance.new("Frame")
            emptyContainer.Name = "EmptyState"
            emptyContainer.Size = UDim2.new(1, 0, 0, 110)
            emptyContainer.BackgroundTransparency = 1
            emptyContainer.ZIndex = 6003
            emptyContainer.Parent = PresetsScroll

            local emptyIcon = Instance.new("ImageLabel")
            emptyIcon.Size = UDim2.new(0, 32, 0, 32)
            emptyIcon.Position = UDim2.new(0.5, -16, 0, 20)
            emptyIcon.Image = Icons.Folder
            emptyIcon.ImageColor3 = Colors.MutedText
            emptyIcon.ImageTransparency = 0.5
            emptyIcon.BackgroundTransparency = 1
            emptyIcon.ZIndex = 6004
            emptyIcon.Parent = emptyContainer

            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, 0, 0, 24)
            emptyLabel.Position = UDim2.new(0, 0, 0, 58)
            emptyLabel.Text = "No saved configs"
            emptyLabel.Font = Fonts.Medium
            emptyLabel.TextSize = 12
            emptyLabel.TextColor3 = Colors.MutedText
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.ZIndex = 6004
            emptyLabel.Parent = emptyContainer
            return
        end

        for _, cfgName in ipairs(configs) do
            local isAuto = (currentAutoload == cfgName)
            local itemRow = Instance.new("Frame")
            itemRow.Size = UDim2.new(1, -2, 0, 44)
            itemRow.BackgroundColor3 = isAuto and Colors.CardHover or Colors.CardBg
            itemRow.ZIndex = 6003
            itemRow.Parent = PresetsScroll
            Instance.new("UICorner", itemRow).CornerRadius = UDim.new(0, 7)
            local rowStroke = AddStroke(itemRow, isAuto and Colors.Accent or Colors.Border, 1)

            local itemLabel = Instance.new("TextLabel")
            itemLabel.Text = (isAuto and "★ " or "") .. cfgName
            itemLabel.Font = isAuto and Fonts.Title or Fonts.Medium
            itemLabel.TextSize = 12
            itemLabel.TextColor3 = isAuto and Colors.Accent or Colors.Text
            itemLabel.Position = UDim2.new(0, 10, 0, 0)
            itemLabel.Size = UDim2.new(1, -168, 1, 0)
            itemLabel.TextXAlignment = Enum.TextXAlignment.Left
            itemLabel.TextTruncate = Enum.TextTruncate.AtEnd
            itemLabel.BackgroundTransparency = 1
            itemLabel.ZIndex = 6004
            itemLabel.Parent = itemRow

            -- 1. Load Button (Width 44, Height 28)
            local loadBtn = Instance.new("TextButton")
            loadBtn.Size = UDim2.new(0, 44, 0, 28)
            loadBtn.Position = UDim2.new(1, -156, 0.5, -14)
            loadBtn.BackgroundColor3 = Colors.Accent
            loadBtn.Text = "Load"
            loadBtn.Font = Fonts.Title
            loadBtn.TextSize = 11
            loadBtn.TextColor3 = Colors.White
            loadBtn.AutoButtonColor = false
            loadBtn.ZIndex = 6004
            loadBtn.Parent = itemRow
            Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 5)

            loadBtn.MouseEnter:Connect(function()
                Tween(loadBtn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.AccentHover})
            end)
            loadBtn.MouseLeave:Connect(function()
                Tween(loadBtn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.Accent})
            end)
            loadBtn.MouseButton1Click:Connect(function()
                RaxorHub:LoadConfigData(cfgName)
            end)
            AttachTooltip(loadBtn, "Load This Preset")

            -- 2. Overwrite Button (Width 28, Height 28)
            local overwriteBtn = Instance.new("ImageButton")
            overwriteBtn.Size = UDim2.new(0, 28, 0, 28)
            overwriteBtn.Position = UDim2.new(1, -106, 0.5, -14)
            overwriteBtn.BackgroundColor3 = Colors.ButtonBg
            overwriteBtn.Image = Icons.Save
            overwriteBtn.ImageColor3 = Colors.SubText
            overwriteBtn.AutoButtonColor = false
            overwriteBtn.ZIndex = 6004
            overwriteBtn.Parent = itemRow
            Instance.new("UICorner", overwriteBtn).CornerRadius = UDim.new(0, 5)
            AddStroke(overwriteBtn, Colors.Border, 1)

            overwriteBtn.MouseEnter:Connect(function()
                Tween(overwriteBtn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.ButtonHover, ImageColor3 = Colors.White})
            end)
            overwriteBtn.MouseLeave:Connect(function()
                Tween(overwriteBtn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.ButtonBg, ImageColor3 = Colors.SubText})
            end)
            overwriteBtn.MouseButton1Click:Connect(function()
                RaxorHub:SaveCurrentConfig(cfgName)
                RaxorHub:Notify({
                    Title = "Preset Overwritten",
                    Content = "Overwrote preset '" .. cfgName .. "' successfully",
                    Duration = 2.5
                })
            end)
            AttachTooltip(overwriteBtn, "Overwrite with Current Settings")

            -- 3. Autoload Toggle Button (Width 28, Height 28)
            local autoBtn = Instance.new("ImageButton")
            autoBtn.Size = UDim2.new(0, 28, 0, 28)
            autoBtn.Position = UDim2.new(1, -72, 0.5, -14)
            autoBtn.BackgroundColor3 = isAuto and Colors.CardHover or Colors.ButtonBg
            autoBtn.Image = Icons.Star
            autoBtn.ImageColor3 = isAuto and Colors.Accent or Colors.MutedText
            autoBtn.AutoButtonColor = false
            autoBtn.ZIndex = 6004
            autoBtn.Parent = itemRow
            Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 5)
            AddStroke(autoBtn, isAuto and Colors.Accent or Colors.Border, 1)

            autoBtn.MouseEnter:Connect(function()
                Tween(autoBtn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.ButtonHover, ImageColor3 = Colors.Accent})
            end)
            autoBtn.MouseLeave:Connect(function()
                local currAuto = (RaxorHub:GetAutoload() == cfgName)
                Tween(autoBtn, TweenInfo.new(0.12), {
                    BackgroundColor3 = currAuto and Colors.CardHover or Colors.ButtonBg,
                    ImageColor3 = currAuto and Colors.Accent or Colors.MutedText
                })
            end)
            autoBtn.MouseButton1Click:Connect(function()
                if RaxorHub:GetAutoload() == cfgName then
                    RaxorHub:ResetAutoload()
                else
                    RaxorHub:SetAutoload(cfgName)
                end
                RefreshPresetsList()
            end)
            AttachTooltip(autoBtn, isAuto and "Disable Autoload" or "Enable Autoload")

            -- 4. Delete Button (Width 28, Height 28 - Custom Asset 93749431604052)
            local delBtn = Instance.new("ImageButton")
            delBtn.Size = UDim2.new(0, 28, 0, 28)
            delBtn.Position = UDim2.new(1, -38, 0.5, -14)
            delBtn.BackgroundColor3 = Colors.ButtonBg
            delBtn.Image = Icons.Trash
            delBtn.ImageColor3 = Colors.SubText
            delBtn.AutoButtonColor = false
            delBtn.ZIndex = 6004
            delBtn.Parent = itemRow
            Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 5)
            AddStroke(delBtn, Colors.Border, 1)

            delBtn.MouseEnter:Connect(function()
                Tween(delBtn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.CloseRed, ImageColor3 = Colors.White})
            end)
            delBtn.MouseLeave:Connect(function()
                Tween(delBtn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.ButtonBg, ImageColor3 = Colors.SubText})
            end)
            delBtn.MouseButton1Click:Connect(function()
                RaxorHub:DeleteConfig(cfgName)
                RefreshPresetsList()
                RaxorHub:Notify({
                    Title = "Preset Deleted",
                    Content = "Deleted preset '" .. cfgName .. "' successfully",
                    Duration = 2.5
                })
            end)
            AttachTooltip(delBtn, "Delete This Preset Permanently")
        end
    end
    RaxorHub.RefreshPresetsList = RefreshPresetsList

    FooterResetBtn.MouseButton1Click:Connect(function()
        RaxorHub:ResetAutoload()
        RefreshPresetsList()
    end)

    AddConfigBtn.MouseButton1Click:Connect(function()
        local name = ConfigNameInput.Text
        if name and name ~= "" and name ~= "---" then
            RaxorHub:SaveCurrentConfig(name)
            ConfigNameInput.Text = ""
            RefreshPresetsList()
            RaxorHub:Notify({
                Title = "Preset Saved",
                Content = "Saved preset '" .. name .. "' successfully",
                Duration = 2.5
            })
        else
            RaxorHub:Notify({
                Title = "Error",
                Content = "Please enter a preset name before saving",
                Duration = 2.5
            })
        end
    end)

    ConfigNameInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local name = ConfigNameInput.Text
            if name and name ~= "" and name ~= "---" then
                RaxorHub:SaveCurrentConfig(name)
                ConfigNameInput.Text = ""
                RefreshPresetsList()
                RaxorHub:Notify({
                    Title = "Preset Saved",
                    Content = "Saved preset '" .. name .. "' successfully",
                    Duration = 2.5
                })
            end
        end
    end)

    RefreshPresetsList()

    -- Real-time Search Filter for Elements in Active Page
    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(SearchInput.Text)
        if RaxorHub.ActivePage then
            for _, section in ipairs(RaxorHub.ActivePage:GetChildren()) do
                if section:IsA("Frame") and section.Name == "SectionFrame" then
                    local matchedAny = false
                    for _, row in ipairs(section:GetChildren()) do
                        if row:IsA("Frame") and row:FindFirstChild("TTitle") then
                            local text = string.lower(row.TTitle.Text)
                            local descText = row:FindFirstChild("TDesc") and string.lower(row.TDesc.Text) or ""
                            if query == "" or string.find(text, query) or string.find(descText, query) then
                                row.Visible = true
                                matchedAny = true
                            else
                                row.Visible = false
                            end
                        end
                    end
                    section.Visible = (query == "" or matchedAny)
                end
            end
        end
    end)

    -- [[ Tab Constructor ]]
    function window:AddTab(TabConfig)
        local tab = {CountSection = 0}
        local tabIconAsset = ResolveIcon(TabConfig.Icon)

        -- Left Tab Button
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 38)
        TabBtn.BackgroundColor3 = Colors.CardActive
        TabBtn.BackgroundTransparency = 1
        TabBtn.AutoButtonColor = false
        TabBtn.Text = ""
        TabBtn.BorderSizePixel = 0
        TabBtn.ZIndex = 23
        TabBtn.Parent = SidebarScroll
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

        -- Active Vertical Pill Indicator (Blade Purple Bar)
        local Indicator = Instance.new("Frame")
        Indicator.Name = "Indicator"
        Indicator.Size = UDim2.new(0, 3, 0, 20)
        Indicator.Position = UDim2.new(0, 0, 0.5, -10)
        Indicator.BackgroundColor3 = Colors.Accent
        Indicator.BackgroundTransparency = 1
        Indicator.BorderSizePixel = 0
        Indicator.ZIndex = 24
        Indicator.Parent = TabBtn
        Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

        local TabContent = Instance.new("Frame")
        TabContent.Name = "Frame"
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.Parent = TabBtn

        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Name = "Icon"
        TabIcon.Size = UDim2.new(0, 18, 0, 18)
        TabIcon.Position = UDim2.new(0, 12, 0.5, -9)
        TabIcon.Image = tabIconAsset
        TabIcon.ImageColor3 = Colors.SubText
        TabIcon.BackgroundTransparency = 1
        TabIcon.ZIndex = 24
        TabIcon.Parent = TabContent

        local TabLabel = Instance.new("TextLabel")
        TabLabel.Name = "Label"
        TabLabel.Text = TabConfig.Name
        TabLabel.Size = UDim2.new(1, -44, 1, 0)
        TabLabel.Position = UDim2.new(0, 38, 0, 0)
        TabLabel.Font = Fonts.Medium
        TabLabel.TextSize = 13
        TabLabel.TextColor3 = Colors.SubText
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.BackgroundTransparency = 1
        TabLabel.ZIndex = 24
        TabLabel.Parent = TabContent

        -- Page Scrolling Frame
        local Page = Instance.new("ScrollingFrame")
        Page.Name = TabConfig.Name .. "_Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Colors.Accent
        Page.BorderSizePixel = 0
        Page.ScrollingEnabled = true
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.ZIndex = 26
        Page.ClipsDescendants = true
        Page.Parent = ContentContainer

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 12)
        PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = Page

        local PagePadding = Instance.new("UIPadding", Page)
        PagePadding.PaddingTop = UDim.new(0, 10)
        PagePadding.PaddingLeft = UDim.new(0, 14)
        PagePadding.PaddingRight = UDim.new(0, 16)
        PagePadding.PaddingBottom = UDim.new(0, 16)

        -- Breadcrumb Header inside Page (Matches Blade Image 1 & 4!)
        local BreadcrumbRow = Instance.new("Frame")
        BreadcrumbRow.Name = "BreadcrumbRow"
        BreadcrumbRow.Size = UDim2.new(1, -4, 0, 26)
        BreadcrumbRow.BackgroundTransparency = 1
        BreadcrumbRow.LayoutOrder = -100
        BreadcrumbRow.ZIndex = 27
        BreadcrumbRow.Parent = Page

        local BreadcrumbTag = Instance.new("Frame")
        BreadcrumbTag.Name = "BreadcrumbTag"
        BreadcrumbTag.Size = UDim2.new(0, 4, 0, 16)
        BreadcrumbTag.Position = UDim2.new(0, 4, 0.5, -8)
        BreadcrumbTag.BackgroundColor3 = Colors.Accent
        BreadcrumbTag.BorderSizePixel = 0
        BreadcrumbTag.ZIndex = 28
        BreadcrumbTag.Parent = BreadcrumbRow
        Instance.new("UICorner", BreadcrumbTag).CornerRadius = UDim.new(1, 0)

        local BreadcrumbLabel = Instance.new("TextLabel")
        BreadcrumbLabel.Size = UDim2.new(1, -18, 1, 0)
        BreadcrumbLabel.Position = UDim2.new(0, 16, 0, 0)
        BreadcrumbLabel.Text = TabConfig.Name
        BreadcrumbLabel.Font = Fonts.Title
        BreadcrumbLabel.TextSize = 16
        BreadcrumbLabel.TextColor3 = Colors.White
        BreadcrumbLabel.TextXAlignment = Enum.TextXAlignment.Left
        BreadcrumbLabel.BackgroundTransparency = 1
        BreadcrumbLabel.ZIndex = 28
        BreadcrumbLabel.Parent = BreadcrumbRow

        local function UpdateTabVisuals()
            for _, b in pairs(SidebarScroll:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundTransparency = 1
                    if b:FindFirstChild("Indicator") then
                        b.Indicator.BackgroundTransparency = 1
                    end
                    if b:FindFirstChild("Frame") then
                        b.Frame.Label.TextColor3 = Colors.SubText
                        b.Frame.Label.Font = Fonts.Medium
                        b.Frame.Icon.ImageColor3 = Colors.SubText
                    end
                end
            end
            TabBtn.BackgroundTransparency = 0
            Indicator.BackgroundTransparency = 0
            TabLabel.TextColor3 = Colors.White
            TabLabel.Font = Fonts.Title
            TabIcon.ImageColor3 = Colors.Accent
            RaxorHub.ActivePage = Page
        end

        TabBtn.MouseButton1Click:Connect(function()
            CloseAllDropdowns()
            for _, p in pairs(ContentContainer:GetChildren()) do
                if p:IsA("ScrollingFrame") then p.Visible = false end
            end
            UpdateTabVisuals()
            Page.Visible = true

            -- Mobile Auto-Collapse: On compact mobile screens, auto-collapse sidebar so tab contents have maximum space!
            if isMobile and not isSidebarCollapsed and viewport.X < 720 and ToggleSidebar then
                task.delay(0.08, function()
                    if not isSidebarCollapsed then
                        ToggleSidebar(true)
                    end
                end)
            end
        end)

        if window.CountTab == 0 then
            Page.Visible = true
            UpdateTabVisuals()
        end
        window.CountTab = window.CountTab + 1

        -- [[ Section Constructor ]]
        function tab:AddSection(Title, Description, IconID)
            local sectionItems = {}
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Name = "SectionFrame"
            SectionFrame.Size = UDim2.new(1, 0, 0, 50)
            SectionFrame.BackgroundTransparency = 1
            SectionFrame.ZIndex = 27
            SectionFrame.ClipsDescendants = false
            tab.CountSection = tab.CountSection + 1
            SectionFrame.LayoutOrder = tab.CountSection
            SectionFrame.Parent = Page

            local SectionLayout = Instance.new("UIListLayout")
            SectionLayout.Padding = UDim.new(0, 6)
            SectionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            SectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            SectionLayout.Parent = SectionFrame

            local hasDesc = Description and Description ~= ""

            -- Header Container (Centered Prominent Section Divider)
            local HeaderHeight = hasDesc and 44 or 30
            local HeaderContainer = Instance.new("Frame")
            HeaderContainer.Name = "HeaderContainer"
            HeaderContainer.Size = UDim2.new(1, -4, 0, HeaderHeight)
            HeaderContainer.BackgroundColor3 = Color3.fromRGB(24, 20, 36)
            HeaderContainer.BackgroundTransparency = 0.35
            HeaderContainer.BorderSizePixel = 0
            HeaderContainer.ZIndex = 28
            HeaderContainer.Parent = SectionFrame
            Instance.new("UICorner", HeaderContainer).CornerRadius = UDim.new(0, 8)
            local stroke = AddStroke(HeaderContainer, Colors.Accent, 1)
            stroke.Transparency = 0.65

            -- Title Row: Holds LeftLine, Center Title (with optional Icon), and RightLine all on the EXACT same vertical center
            local TitleRow = Instance.new("Frame")
            TitleRow.Name = "TitleRow"
            TitleRow.Size = UDim2.new(1, -20, 0, 20)
            TitleRow.Position = hasDesc and UDim2.new(0.5, 0, 0, 5) or UDim2.new(0.5, 0, 0.5, 0)
            TitleRow.AnchorPoint = hasDesc and Vector2.new(0.5, 0) or Vector2.new(0.5, 0.5)
            TitleRow.BackgroundTransparency = 1
            TitleRow.ZIndex = 29
            TitleRow.Parent = HeaderContainer

            -- Center Title Block (Icon + Title centered)
            local CenterBlock = Instance.new("Frame")
            CenterBlock.Name = "CenterBlock"
            CenterBlock.Size = UDim2.new(0, 0, 1, 0)
            CenterBlock.AutomaticSize = Enum.AutomaticSize.X
            CenterBlock.Position = UDim2.new(0.5, 0, 0.5, 0)
            CenterBlock.AnchorPoint = Vector2.new(0.5, 0.5)
            CenterBlock.BackgroundTransparency = 1
            CenterBlock.ZIndex = 30
            CenterBlock.Parent = TitleRow

            local centerLayout = Instance.new("UIListLayout", CenterBlock)
            centerLayout.FillDirection = Enum.FillDirection.Horizontal
            centerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            centerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            centerLayout.Padding = UDim.new(0, 6)

            if IconID then
                local SecIcon = Instance.new("ImageLabel")
                SecIcon.Size = UDim2.new(0, 16, 0, 16)
                SecIcon.Image = ResolveIcon(IconID)
                SecIcon.BackgroundTransparency = 1
                SecIcon.ImageColor3 = Colors.AccentHover
                SecIcon.ZIndex = 31
                SecIcon.Parent = CenterBlock
            end

            local HeaderTitle = Instance.new("TextLabel")
            HeaderTitle.Name = "HeaderTitle"
            HeaderTitle.AutomaticSize = Enum.AutomaticSize.X
            HeaderTitle.Size = UDim2.new(0, 0, 1, 0)
            HeaderTitle.Text = tostring(Title)
            HeaderTitle.Font = Fonts.Title
            HeaderTitle.TextSize = 15
            HeaderTitle.TextColor3 = Colors.AccentHover
            HeaderTitle.TextXAlignment = Enum.TextXAlignment.Center
            HeaderTitle.BackgroundTransparency = 1
            HeaderTitle.ZIndex = 31
            HeaderTitle.Parent = CenterBlock

            -- Left decorative accent gradient line (Flanks title from left edge to title)
            local LeftLine = Instance.new("Frame")
            LeftLine.Name = "LeftLine"
            LeftLine.Size = UDim2.new(0.24, 0, 0, 1)
            LeftLine.Position = UDim2.new(0, 0, 0.5, 0)
            LeftLine.AnchorPoint = Vector2.new(0, 0.5)
            LeftLine.BackgroundColor3 = Colors.Accent
            LeftLine.BorderSizePixel = 0
            LeftLine.ZIndex = 29
            LeftLine.Parent = TitleRow

            local leftGrad = Instance.new("UIGradient", LeftLine)
            leftGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.85),
                NumberSequenceKeypoint.new(1, 0.05)
            })

            -- Right decorative accent gradient line (Flanks title from title to right edge)
            local RightLine = Instance.new("Frame")
            RightLine.Name = "RightLine"
            RightLine.Size = UDim2.new(0.24, 0, 0, 1)
            RightLine.Position = UDim2.new(1, 0, 0.5, 0)
            RightLine.AnchorPoint = Vector2.new(1, 0.5)
            RightLine.BackgroundColor3 = Colors.Accent
            RightLine.BorderSizePixel = 0
            RightLine.ZIndex = 29
            RightLine.Parent = TitleRow

            local rightGrad = Instance.new("UIGradient", RightLine)
            rightGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.05),
                NumberSequenceKeypoint.new(1, 0.85)
            })

            -- Dynamic line length adjustment so lines directly connect with the center title with 10px margin
            local function UpdateLineGeometry()
                local rowW = TitleRow.AbsoluteSize.X
                local centerW = CenterBlock.AbsoluteSize.X
                if centerW <= 0 then
                    local TextService = game:GetService("TextService")
                    local sz = TextService:GetTextSize(tostring(Title), 15, Fonts.Title, Vector2.new(1000, 1000))
                    centerW = sz.X + (IconID and 22 or 0)
                end
                if rowW > 0 and centerW > 0 then
                    local halfW = math.ceil(centerW / 2)
                    local lineLen = math.max(12, math.floor((rowW / 2) - halfW - 10))
                    LeftLine.Size = UDim2.new(0, lineLen, 0, 1)
                    RightLine.Size = UDim2.new(0, lineLen, 0, 1)
                end
            end

            CenterBlock:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateLineGeometry)
            TitleRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateLineGeometry)
            task.defer(UpdateLineGeometry)

            if hasDesc then
                local Desc = Instance.new("TextLabel")
                Desc.Name = "HeaderDesc"
                Desc.Size = UDim2.new(1, -20, 0, 15)
                Desc.Position = UDim2.new(0.5, 0, 0, 25)
                Desc.AnchorPoint = Vector2.new(0.5, 0)
                Desc.Text = tostring(Description)
                Desc.Font = Fonts.Medium
                Desc.TextSize = 12
                Desc.TextColor3 = Colors.SubText
                Desc.TextXAlignment = Enum.TextXAlignment.Center
                Desc.BackgroundTransparency = 1
                Desc.ZIndex = 29
                Desc.Parent = HeaderContainer
            end

            SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SectionFrame.Size = UDim2.new(1, 0, 0, SectionLayout.AbsoluteContentSize.Y + 8)
            end)

            -- Text Helper for Row Labels (High Legibility & Thai Vowel Space)
            local function SetupRowText(row, title, desc, rightSpace)
                local hasRowDesc = desc and desc ~= ""
                local TTitle = Instance.new("TextLabel")
                TTitle.Name = "TTitle"
                TTitle.Text = title or ""
                TTitle.Size = UDim2.new(1, -rightSpace, 0, 20)
                TTitle.Position = hasRowDesc and UDim2.new(0, 14, 0, 8) or UDim2.new(0, 14, 0.5, -10)
                TTitle.Font = Fonts.Title
                TTitle.TextSize = 14
                TTitle.TextColor3 = Colors.Text
                TTitle.TextXAlignment = Enum.TextXAlignment.Left
                TTitle.BackgroundTransparency = 1
                TTitle.ZIndex = 30
                TTitle.Parent = row

                if hasRowDesc then
                    local TDesc = Instance.new("TextLabel")
                    TDesc.Name = "TDesc"
                    TDesc.Text = desc
                    TDesc.Size = UDim2.new(1, -rightSpace, 0, 22)
                    TDesc.Position = UDim2.new(0, 14, 0, 29)
                    TDesc.Font = Fonts.Medium
                    TDesc.TextSize = 14
                    TDesc.TextColor3 = Colors.SubText
                    TDesc.TextXAlignment = Enum.TextXAlignment.Left
                    TDesc.BackgroundTransparency = 1
                    TDesc.ZIndex = 30
                    TDesc.Parent = row
                end
            end

            -- [[ Toggle Switch (Blade Modern Switch) ]]
            function sectionItems:AddToggleSwitch(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.ZIndex = 28
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                SetupRowText(Row, Config.Title, Config.Description, 80)

                local SwitchBg = Instance.new("TextButton")
                SwitchBg.Size = UDim2.new(0, 44, 0, 22)
                SwitchBg.Position = UDim2.new(1, -56, 0.5, -11)
                SwitchBg.BackgroundColor3 = Config.Default and Colors.SwitchOn or Colors.SwitchOff
                SwitchBg.AutoButtonColor = false
                SwitchBg.Text = ""
                SwitchBg.ZIndex = 31
                SwitchBg.Parent = Row
                Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
                AddStroke(SwitchBg, Colors.Border, 1)

                local Knob = Instance.new("Frame")
                Knob.Size = UDim2.new(0, 16, 0, 16)
                Knob.Position = Config.Default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                Knob.BackgroundColor3 = Colors.White
                Knob.ZIndex = 32
                Knob.Parent = SwitchBg
                Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

                local state = Config.Default or false
                UpdateState(Config.ID, state)

                local function VisualUpdate(val)
                    local targetPos = val and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                    local targetColor = val and Colors.SwitchOn or Colors.SwitchOff
                    Tween(Knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos})
                    Tween(SwitchBg, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = targetColor})
                end

                if Config.ID and RaxorHub.Objects then
                    RaxorHub.Objects[Config.ID] = {
                        Type = "Toggle",
                        Instance = SwitchBg,
                        Knob = Knob,
                        Callback = Config.Callback,
                        Update = function(val)
                            state = val
                            VisualUpdate(val)
                        end
                    }
                end

                SwitchBg.MouseButton1Click:Connect(function()
                    state = not state
                    VisualUpdate(state)
                    UpdateState(Config.ID, state)
                    if Config.Callback then Config.Callback(state) end
                end)

                local toggleFunc = {
                    Set = function(self, val)
                        state = val
                        VisualUpdate(val)
                        UpdateState(Config.ID, val)
                        if Config.Callback then Config.Callback(val) end
                    end,
                    Get = function(self)
                        return state
                    end
                }
                return toggleFunc
            end

            -- [[ Slider Control (Blade Dual/Single Modern Slider) ]]
            function sectionItems:AddSlider(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.ZIndex = 28
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                SetupRowText(Row, Config.Title, Config.Description, 185)

                local SliderContainer = Instance.new("Frame")
                SliderContainer.Size = UDim2.new(0, 160, 0, 38)
                SliderContainer.Position = UDim2.new(1, -172, 0.5, -19)
                SliderContainer.BackgroundTransparency = 1
                SliderContainer.ZIndex = 30
                SliderContainer.Parent = Row

                local suffix = Config.Suffix or ""
                local ValueLabel = Instance.new("TextLabel")
                ValueLabel.Size = UDim2.new(1, 0, 0, 18)
                ValueLabel.Position = UDim2.new(0, 0, 0, 0)
                ValueLabel.BackgroundTransparency = 1
                ValueLabel.Text = tostring(Config.Default or Config.Min) .. suffix
                ValueLabel.TextColor3 = Colors.Text
                ValueLabel.Font = Fonts.Title
                ValueLabel.TextSize = 13
                ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                ValueLabel.ZIndex = 31
                ValueLabel.Parent = SliderContainer

                local SliderBack = Instance.new("Frame")
                SliderBack.Size = UDim2.new(1, 0, 0, 6)
                SliderBack.Position = UDim2.new(0, 0, 0, 24)
                SliderBack.BackgroundColor3 = Colors.InputBg
                SliderBack.BorderSizePixel = 0
                SliderBack.ZIndex = 31
                SliderBack.Parent = SliderContainer
                Instance.new("UICorner", SliderBack).CornerRadius = UDim.new(1, 0)
                AddStroke(SliderBack, Colors.Border, 1)

                local initRatio = math.clamp(((Config.Default or Config.Min) - Config.Min) / (Config.Max - Config.Min), 0, 1)

                local SliderFill = Instance.new("Frame")
                SliderFill.Size = UDim2.new(initRatio, 0, 1, 0)
                SliderFill.BackgroundColor3 = Colors.Accent
                SliderFill.BorderSizePixel = 0
                SliderFill.ZIndex = 32
                SliderFill.Parent = SliderBack
                Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

                local Handle = Instance.new("Frame")
                Handle.Size = UDim2.new(0, 14, 0, 14)
                Handle.AnchorPoint = Vector2.new(0.5, 0.5)
                Handle.Position = UDim2.new(initRatio, 0, 0.5, 0)
                Handle.BackgroundColor3 = Colors.White
                Handle.ZIndex = 33
                Handle.Active = true
                Handle.Parent = SliderBack
                Instance.new("UICorner", Handle).CornerRadius = UDim.new(1, 0)
                AddStroke(Handle, Colors.Accent, 1)

                local dragging = false
                UpdateState(Config.ID, Config.Default or Config.Min)

                local function VisualUpdate(val)
                    local relativeX = math.clamp((val - Config.Min) / (Config.Max - Config.Min), 0, 1)
                    SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
                    Handle.Position = UDim2.new(relativeX, 0, 0.5, 0)
                    ValueLabel.Text = tostring(val) .. suffix
                end

                if Config.ID and RaxorHub.Objects then
                    RaxorHub.Objects[Config.ID] = {
                        Type = "Slider",
                        Instance = SliderFill,
                        Handle = Handle,
                        Label = ValueLabel,
                        Config = Config,
                        Callback = Config.Callback,
                        Update = VisualUpdate
                    }
                end

                local function UpdateSlider(input)
                    local relativeX = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                    local step = Config.Step or 1
                    local rawVal = Config.Min + (Config.Max - Config.Min) * relativeX
                    local value = math.floor((rawVal / step) + 0.5) * step
                    value = math.clamp(value, Config.Min, Config.Max)

                    VisualUpdate(value)
                    UpdateState(Config.ID, value)
                    if Config.Callback then Config.Callback(value) end
                end

                SliderBack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        UpdateSlider(input)
                    end
                end)

                Handle.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        UpdateSlider(input)
                    end
                end)
            end

            -- [[ Dropdown Control (Blade Single Select) ]]
            function sectionItems:AddDropdown(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.ZIndex = 28
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                SetupRowText(Row, Config.Title, Config.Description, 200)

                local Frame = Instance.new("Frame")
                Frame.Size = UDim2.new(0, 175, 0, 32)
                Frame.Position = UDim2.new(1, -188, 0.5, -16)
                Frame.BackgroundColor3 = Colors.InputBg
                Frame.ZIndex = 30
                Frame.Parent = Row
                Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
                AddStroke(Frame, Colors.BorderFocus, 1)

                local Label = Instance.new("TextLabel")
                Label.Text = Config.Default or "Select..."
                Label.Size = UDim2.new(1, -36, 1, 0)
                Label.Position = UDim2.new(0, 10, 0, 0)
                Label.BackgroundTransparency = 1
                Label.TextColor3 = Colors.Text
                Label.Font = Fonts.Medium
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextTruncate = Enum.TextTruncate.AtEnd
                Label.ClipsDescendants = true
                Label.ZIndex = 31
                Label.Parent = Frame

                local ArrowIcon = Instance.new("ImageLabel")
                ArrowIcon.Image = Icons.ChevronDown
                ArrowIcon.Size = UDim2.new(0, 14, 0, 14)
                ArrowIcon.Position = UDim2.new(1, -22, 0.5, -7)
                ArrowIcon.BackgroundTransparency = 1
                ArrowIcon.ImageColor3 = Colors.SubText
                ArrowIcon.ZIndex = 32
                ArrowIcon.Parent = Frame

                local DropdownClickBtn = Instance.new("TextButton")
                DropdownClickBtn.Size = UDim2.new(1, 0, 1, 0)
                DropdownClickBtn.BackgroundTransparency = 1
                DropdownClickBtn.Text = ""
                DropdownClickBtn.ZIndex = 33
                DropdownClickBtn.Parent = Frame

                local List = Instance.new("Frame")
                List.Name = "DropdownList"
                List.BackgroundColor3 = Colors.DropdownBg
                List.ZIndex = 9500
                List.Visible = false
                List.ClipsDescendants = true
                List.Parent = MainFrame
                Instance.new("UICorner", List).CornerRadius = UDim.new(0, 6)
                AddStroke(List, Colors.BorderFocus, 1)

                local SearchBox = Instance.new("TextBox")
                SearchBox.Size = UDim2.new(1, -10, 0, 26)
                SearchBox.Position = UDim2.new(0, 5, 0, 5)
                SearchBox.BackgroundColor3 = Colors.InputBg
                SearchBox.PlaceholderText = "Search..."
                SearchBox.PlaceholderColor3 = Colors.MutedText
                SearchBox.TextColor3 = Colors.Text
                SearchBox.Font = Fonts.Regular
                SearchBox.Text = ""
                SearchBox.TextSize = 11
                SearchBox.ZIndex = 9501
                SearchBox.Parent = List
                Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 4)
                AddStroke(SearchBox, Colors.Border, 1)

                local ItemScroll = Instance.new("ScrollingFrame")
                ItemScroll.Size = UDim2.new(1, -8, 1, -38)
                ItemScroll.Position = UDim2.new(0, 4, 0, 35)
                ItemScroll.BackgroundTransparency = 1
                ItemScroll.BorderSizePixel = 0
                ItemScroll.ScrollBarThickness = 2
                ItemScroll.ScrollBarImageColor3 = Colors.Accent
                ItemScroll.ZIndex = 9501
                ItemScroll.Parent = List

                local ItemListLayout = Instance.new("UIListLayout", ItemScroll)
                ItemListLayout.Padding = UDim.new(0, 2)

                local syncConnection
                local currentlySelected = Config.Default or nil
                UpdateState(Config.ID, currentlySelected)

                local function UpdateListPosition()
                    if List.Visible then
                        if not MainFrame.Visible or not Frame.Visible then
                            CloseAllDropdowns()
                            return
                        end
                        local absPos = Frame.AbsolutePosition
                        local mainPos = MainFrame.AbsolutePosition
                        local relX = absPos.X - mainPos.X
                        local relY = absPos.Y - mainPos.Y

                        local contentTop = ContentContainer.AbsolutePosition.Y
                        local contentBottom = contentTop + ContentContainer.AbsoluteSize.Y
                        if absPos.Y + Frame.AbsoluteSize.Y < contentTop or absPos.Y > contentBottom then
                            CloseAllDropdowns()
                            return
                        end

                        local count = 0
                        for _, child in pairs(ItemScroll:GetChildren()) do
                            if child:IsA("TextButton") then count = count + 1 end
                        end
                        local contentHeight = math.max(ItemListLayout.AbsoluteContentSize.Y, count * 28)
                        ItemScroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 4)
                        local dynamicHeight = math.clamp(contentHeight + 42, 70, 200)

                        List.Size = UDim2.new(0, Frame.AbsoluteSize.X, 0, dynamicHeight)
                        List.Position = UDim2.new(0, relX, 0, relY + Frame.AbsoluteSize.Y + 2)
                    end
                end

                local function Populate(filter)
                    for _, child in pairs(ItemScroll:GetChildren()) do
                        if child:IsA("TextButton") or child.Name == "EmptyMsg" then child:Destroy() end
                    end
                    local matchCount = 0
                    for _, item in pairs(Config.Options or {}) do
                        if filter == "" or string.find(string.lower(tostring(item)), string.lower(tostring(filter))) then
                            matchCount = matchCount + 1
                            local isSelected = (item == currentlySelected)
                            local itemBtn = Instance.new("TextButton")
                            itemBtn.Size = UDim2.new(1, -4, 0, 26)
                            itemBtn.BorderSizePixel = 0
                            itemBtn.AutoButtonColor = false
                            itemBtn.Text = "  " .. tostring(item)
                            itemBtn.Font = isSelected and Fonts.Title or Fonts.Medium
                            itemBtn.TextSize = 12
                            itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                            itemBtn.ZIndex = 9502
                            itemBtn.BackgroundColor3 = isSelected and Colors.Accent or Colors.CardBg
                            itemBtn.TextColor3 = isSelected and Colors.White or Colors.Text
                            itemBtn.Parent = ItemScroll
                            Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 4)

                            itemBtn.MouseButton1Click:Connect(function()
                                Label.Text = tostring(item)
                                currentlySelected = item
                                CloseAllDropdowns()
                                if syncConnection then syncConnection:Disconnect() end
                                UpdateState(Config.ID, item)
                                if Config.Callback then Config.Callback(item) end
                            end)
                        end
                    end
                    if matchCount == 0 then
                        local emptyMsg = Instance.new("TextLabel")
                        emptyMsg.Name = "EmptyMsg"
                        emptyMsg.Size = UDim2.new(1, 0, 0, 26)
                        emptyMsg.BackgroundTransparency = 1
                        emptyMsg.Text = "No options found"
                        emptyMsg.Font = Fonts.Regular
                        emptyMsg.TextSize = 11
                        emptyMsg.TextColor3 = Colors.MutedText
                        emptyMsg.TextXAlignment = Enum.TextXAlignment.Center
                        emptyMsg.ZIndex = 9502
                        emptyMsg.Parent = ItemScroll
                    end
                end

                SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    Populate(SearchBox.Text)
                    UpdateListPosition()
                end)

                local dropdownFunc = {}
                function dropdownFunc:Refresh(newList)
                    Config.Options = newList
                    Populate("")
                    UpdateListPosition()
                end
                function dropdownFunc:Update(val)
                    Label.Text = tostring(val)
                    currentlySelected = val
                end
                function dropdownFunc:Set(val)
                    Label.Text = tostring(val)
                    currentlySelected = val
                    UpdateState(Config.ID, val)
                    if Config.Callback then Config.Callback(val) end
                end

                if Config.ID then
                    RaxorHub.Objects[Config.ID] = {
                        Type = "Dropdown",
                        Default = Config.Default,
                        Update = function(val)
                            Label.Text = tostring(val)
                            currentlySelected = val
                        end,
                        Callback = Config.Callback or function() end
                    }
                end

                DropdownClickBtn.MouseButton1Click:Connect(function()
                    if List.Visible then
                        CloseAllDropdowns()
                    else
                        CloseAllDropdowns()
                        List.Visible = true
                        activeDropdownList = List
                        activeDropdownArrow = ArrowIcon
                        activeDropdownFrame = Frame
                        Tween(ArrowIcon, TweenInfo.new(0.15), {Rotation = 180})
                        ItemScroll.CanvasPosition = Vector2.new(0, 0)
                        SearchBox.Text = ""
                        Populate("")
                        UpdateListPosition()
                        activeDropdownSync = RunService.RenderStepped:Connect(UpdateListPosition)
                    end
                end)

                return dropdownFunc
            end

            -- [[ Multi-Select Control (Blade Multi-Option Dropdown Image 3) ]]
            function sectionItems:AddMultiSelect(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.ZIndex = 28
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                SetupRowText(Row, Config.Title, Config.Description, 200)

                local Frame = Instance.new("Frame")
                Frame.Size = UDim2.new(0, 175, 0, 32)
                Frame.Position = UDim2.new(1, -188, 0.5, -16)
                Frame.BackgroundColor3 = Colors.InputBg
                Frame.ZIndex = 30
                Frame.Parent = Row
                Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
                AddStroke(Frame, Colors.BorderFocus, 1)

                local Label = Instance.new("TextLabel")
                Label.Text = "None"
                Label.Size = UDim2.new(1, -36, 1, 0)
                Label.Position = UDim2.new(0, 10, 0, 0)
                Label.BackgroundTransparency = 1
                Label.TextColor3 = Colors.Text
                Label.Font = Fonts.Medium
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextTruncate = Enum.TextTruncate.AtEnd
                Label.ClipsDescendants = true
                Label.ZIndex = 31
                Label.Parent = Frame

                local ArrowIcon = Instance.new("ImageLabel")
                ArrowIcon.Image = Icons.ChevronDown
                ArrowIcon.Size = UDim2.new(0, 14, 0, 14)
                ArrowIcon.Position = UDim2.new(1, -22, 0.5, -7)
                ArrowIcon.BackgroundTransparency = 1
                ArrowIcon.ImageColor3 = Colors.SubText
                ArrowIcon.ZIndex = 32
                ArrowIcon.Parent = Frame

                local MultiClickBtn = Instance.new("TextButton")
                MultiClickBtn.Size = UDim2.new(1, 0, 1, 0)
                MultiClickBtn.BackgroundTransparency = 1
                MultiClickBtn.Text = ""
                MultiClickBtn.ZIndex = 33
                MultiClickBtn.Parent = Frame

                local List = Instance.new("Frame")
                List.Name = "MultiSelectList"
                List.BackgroundColor3 = Colors.DropdownBg
                List.ZIndex = 9500
                List.Visible = false
                List.ClipsDescendants = true
                List.Parent = MainFrame
                Instance.new("UICorner", List).CornerRadius = UDim.new(0, 6)
                AddStroke(List, Colors.BorderFocus, 1)

                local SearchBox = Instance.new("TextBox")
                SearchBox.Size = UDim2.new(1, -10, 0, 26)
                SearchBox.Position = UDim2.new(0, 5, 0, 5)
                SearchBox.BackgroundColor3 = Colors.InputBg
                SearchBox.PlaceholderText = "Search..."
                SearchBox.PlaceholderColor3 = Colors.MutedText
                SearchBox.TextColor3 = Colors.Text
                SearchBox.Font = Fonts.Regular
                SearchBox.Text = ""
                SearchBox.TextSize = 11
                SearchBox.ZIndex = 9501
                SearchBox.Parent = List
                Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 4)
                AddStroke(SearchBox, Colors.Border, 1)

                local ItemScroll = Instance.new("ScrollingFrame")
                ItemScroll.Size = UDim2.new(1, -8, 1, -38)
                ItemScroll.Position = UDim2.new(0, 4, 0, 35)
                ItemScroll.BackgroundTransparency = 1
                ItemScroll.BorderSizePixel = 0
                ItemScroll.ScrollBarThickness = 2
                ItemScroll.ScrollBarImageColor3 = Colors.Accent
                ItemScroll.ZIndex = 9501
                ItemScroll.Parent = List

                local ListLayout = Instance.new("UIListLayout", ItemScroll)
                ListLayout.Padding = UDim.new(0, 2)

                local syncConnection
                local selectedItems = Config.Default or {}
                UpdateState(Config.ID, selectedItems)

                local function UpdateLabel()
                    if type(selectedItems) == "table" then
                        if #selectedItems == 0 then
                            Label.Text = "None"
                        elseif #selectedItems == 1 then
                            Label.Text = tostring(selectedItems[1])
                        else
                            Label.Text = tostring(selectedItems[1]) .. ", +" .. tostring(#selectedItems - 1)
                        end
                    else
                        Label.Text = tostring(selectedItems)
                    end
                end
                UpdateLabel()

                local function UpdateListPosition()
                    if List.Visible then
                        if not MainFrame.Visible or not Frame.Visible then
                            CloseAllDropdowns()
                            return
                        end
                        local absPos = Frame.AbsolutePosition
                        local mainPos = MainFrame.AbsolutePosition
                        local relX = absPos.X - mainPos.X
                        local relY = absPos.Y - mainPos.Y

                        local contentTop = ContentContainer.AbsolutePosition.Y
                        local contentBottom = contentTop + ContentContainer.AbsoluteSize.Y
                        if absPos.Y + Frame.AbsoluteSize.Y < contentTop or absPos.Y > contentBottom then
                            CloseAllDropdowns()
                            return
                        end

                        local count = 0
                        for _, child in pairs(ItemScroll:GetChildren()) do
                            if child:IsA("TextButton") then count = count + 1 end
                        end
                        local contentHeight = math.max(ListLayout.AbsoluteContentSize.Y, count * 28)
                        ItemScroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 4)
                        local dynamicHeight = math.clamp(contentHeight + 42, 70, 200)

                        List.Size = UDim2.new(0, Frame.AbsoluteSize.X, 0, dynamicHeight)
                        List.Position = UDim2.new(0, relX, 0, relY + Frame.AbsoluteSize.Y + 2)
                    end
                end

                local function Populate(filter)
                    for _, child in pairs(ItemScroll:GetChildren()) do
                        if child:IsA("TextButton") or child.Name == "EmptyMsg" then child:Destroy() end
                    end
                    local matchCount = 0
                    for _, item in pairs(Config.Options or {}) do
                        if filter == "" or string.find(string.lower(tostring(item)), string.lower(tostring(filter))) then
                            matchCount = matchCount + 1
                            local isSelected = (type(selectedItems) == "table" and table.find(selectedItems, item))
                            local itemBtn = Instance.new("TextButton")
                            itemBtn.Size = UDim2.new(1, -4, 0, 26)
                            itemBtn.BorderSizePixel = 0
                            itemBtn.AutoButtonColor = false
                            itemBtn.Text = ""
                            itemBtn.ZIndex = 9502
                            itemBtn.BackgroundColor3 = isSelected and Colors.CardActive or Colors.CardBg
                            itemBtn.Parent = ItemScroll
                            Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 4)

                            local checkIcon = Instance.new("ImageLabel")
                            checkIcon.Size = UDim2.new(0, 14, 0, 14)
                            checkIcon.Position = UDim2.new(0, 6, 0.5, -7)
                            checkIcon.Image = Icons.Checkmark
                            checkIcon.ImageColor3 = Colors.Accent
                            checkIcon.BackgroundTransparency = 1
                            checkIcon.Visible = isSelected and true or false
                            checkIcon.ZIndex = 9503
                            checkIcon.Parent = itemBtn

                            local tText = Instance.new("TextLabel")
                            tText.Size = UDim2.new(1, -28, 1, 0)
                            tText.Position = UDim2.new(0, 26, 0, 0)
                            tText.Text = tostring(item)
                            tText.Font = isSelected and Fonts.Title or Fonts.Regular
                            tText.TextSize = 12
                            tText.TextColor3 = isSelected and Colors.White or Colors.Text
                            tText.TextXAlignment = Enum.TextXAlignment.Left
                            tText.BackgroundTransparency = 1
                            tText.ZIndex = 9503
                            tText.Parent = itemBtn

                            itemBtn.MouseButton1Click:Connect(function()
                                if type(selectedItems) ~= "table" then selectedItems = {} end
                                local foundIndex = table.find(selectedItems, item)
                                if foundIndex then
                                    table.remove(selectedItems, foundIndex)
                                    checkIcon.Visible = false
                                    tText.TextColor3 = Colors.Text
                                    tText.Font = Fonts.Regular
                                    itemBtn.BackgroundColor3 = Colors.CardBg
                                else
                                    table.insert(selectedItems, item)
                                    checkIcon.Visible = true
                                    tText.TextColor3 = Colors.White
                                    tText.Font = Fonts.Title
                                    itemBtn.BackgroundColor3 = Colors.CardActive
                                end
                                UpdateLabel()
                                UpdateState(Config.ID, selectedItems)
                                if Config.Callback then Config.Callback(selectedItems) end
                            end)
                        end
                    end
                    if matchCount == 0 then
                        local emptyMsg = Instance.new("TextLabel")
                        emptyMsg.Name = "EmptyMsg"
                        emptyMsg.Size = UDim2.new(1, 0, 0, 26)
                        emptyMsg.BackgroundTransparency = 1
                        emptyMsg.Text = "No options found"
                        emptyMsg.Font = Fonts.Regular
                        emptyMsg.TextSize = 11
                        emptyMsg.TextColor3 = Colors.MutedText
                        emptyMsg.TextXAlignment = Enum.TextXAlignment.Center
                        emptyMsg.ZIndex = 9502
                        emptyMsg.Parent = ItemScroll
                    end
                end

                SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    Populate(SearchBox.Text)
                    UpdateListPosition()
                end)

                local multiFunc = {}
                function multiFunc:Refresh(newList)
                    Config.Options = newList
                    Populate("")
                    UpdateListPosition()
                end
                function multiFunc:Set(vals)
                    selectedItems = vals or {}
                    UpdateLabel()
                    UpdateState(Config.ID, selectedItems)
                    Populate("")
                    if Config.Callback then Config.Callback(selectedItems) end
                end

                if Config.ID and RaxorHub.Objects then
                    RaxorHub.Objects[Config.ID] = {
                        Type = "MultiSelect",
                        Update = function(val)
                            if type(val) == "table" then
                                selectedItems = val
                            else
                                selectedItems = {val}
                            end
                            UpdateLabel()
                        end,
                        Callback = Config.Callback or function() end
                    }
                end

                MultiClickBtn.MouseButton1Click:Connect(function()
                    if List.Visible then
                        CloseAllDropdowns()
                    else
                        CloseAllDropdowns()
                        List.Visible = true
                        activeDropdownList = List
                        activeDropdownArrow = ArrowIcon
                        activeDropdownFrame = Frame
                        Tween(ArrowIcon, TweenInfo.new(0.15), {Rotation = 180})
                        ItemScroll.CanvasPosition = Vector2.new(0, 0)
                        SearchBox.Text = ""
                        Populate("")
                        UpdateListPosition()
                        activeDropdownSync = RunService.RenderStepped:Connect(UpdateListPosition)
                    end
                end)

                return multiFunc
            end

            -- [[ Color Picker Control (Blade Modern Full HSV Color Picker) ]]
            function sectionItems:AddColorPicker(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.ZIndex = 28
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                SetupRowText(Row, Config.Title, Config.Description, 100)

                local currentColor = Config.Default or Colors.Accent
                local currentH, currentS, currentV = currentColor:ToHSV()
                UpdateState(Config.ID, currentColor)

                local ColorBox = Instance.new("TextButton")
                ColorBox.Size = UDim2.new(0, 36, 0, 22)
                ColorBox.Position = UDim2.new(1, -48, 0.5, -11)
                ColorBox.BackgroundColor3 = currentColor
                ColorBox.Text = ""
                ColorBox.AutoButtonColor = false
                ColorBox.ZIndex = 30
                ColorBox.Parent = Row
                Instance.new("UICorner", ColorBox).CornerRadius = UDim.new(0, 5)
                AddStroke(ColorBox, Colors.BorderFocus, 1)

                local PickerModal = Instance.new("Frame")
                PickerModal.Name = "ColorPickerModal"
                PickerModal.Size = UDim2.new(0, 220, 0, 242)
                PickerModal.BackgroundColor3 = Colors.ModalBg
                PickerModal.Visible = false
                PickerModal.ZIndex = 7500
                PickerModal.ClipsDescendants = true
                PickerModal.Parent = MainFrame
                Instance.new("UICorner", PickerModal).CornerRadius = UDim.new(0, 8)
                AddStroke(PickerModal, Colors.BorderFocus, 1.2)

                local PickerTitle = Instance.new("TextLabel")
                PickerTitle.Text = Config.Title or "Color Picker"
                PickerTitle.Font = Fonts.Title
                PickerTitle.TextSize = 12
                PickerTitle.TextColor3 = Colors.Text
                PickerTitle.Size = UDim2.new(1, -38, 0, 20)
                PickerTitle.Position = UDim2.new(0, 10, 0, 5)
                PickerTitle.TextXAlignment = Enum.TextXAlignment.Left
                PickerTitle.BackgroundTransparency = 1
                PickerTitle.ZIndex = 7501
                PickerTitle.Parent = PickerModal

                local ClosePickerBtn = Instance.new("ImageButton")
                ClosePickerBtn.Size = UDim2.new(0, 16, 0, 16)
                ClosePickerBtn.Position = UDim2.new(1, -24, 0, 7)
                ClosePickerBtn.BackgroundTransparency = 1
                ClosePickerBtn.Image = Icons.Close
                ClosePickerBtn.ImageColor3 = Colors.SubText
                ClosePickerBtn.AutoButtonColor = false
                ClosePickerBtn.ZIndex = 7502
                ClosePickerBtn.Parent = PickerModal

                ClosePickerBtn.MouseEnter:Connect(function() ClosePickerBtn.ImageColor3 = Colors.CloseRed end)
                ClosePickerBtn.MouseLeave:Connect(function() ClosePickerBtn.ImageColor3 = Colors.SubText end)
                ClosePickerBtn.MouseButton1Click:Connect(function()
                    PickerModal.Visible = false
                    activeColorPicker = nil
                end)

                -- 2D Saturation / Value Canvas Box
                local svCanvas = Instance.new("TextButton")
                svCanvas.Name = "SVCanvas"
                svCanvas.Size = UDim2.new(1, -20, 0, 116)
                svCanvas.Position = UDim2.new(0, 10, 0, 27)
                svCanvas.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
                svCanvas.BorderSizePixel = 0
                svCanvas.AutoButtonColor = false
                svCanvas.Text = ""
                svCanvas.ClipsDescendants = true
                svCanvas.ZIndex = 7501
                svCanvas.Parent = PickerModal
                Instance.new("UICorner", svCanvas).CornerRadius = UDim.new(0, 6)
                AddStroke(svCanvas, Colors.Border, 1)

                -- Horizontal White Overlay (Saturation: 0 at left, 1 at right)
                local whiteOverlay = Instance.new("Frame")
                whiteOverlay.Size = UDim2.new(1, 0, 1, 0)
                whiteOverlay.BackgroundColor3 = Color3.new(1, 1, 1)
                whiteOverlay.BorderSizePixel = 0
                whiteOverlay.ZIndex = 7502
                whiteOverlay.Parent = svCanvas
                local whiteGrad = Instance.new("UIGradient", whiteOverlay)
                whiteGrad.Rotation = 0
                whiteGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                })

                -- Vertical Black Overlay (Brightness/Value: 1 at top, 0 at bottom)
                local blackOverlay = Instance.new("Frame")
                blackOverlay.Size = UDim2.new(1, 0, 1, 0)
                blackOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
                blackOverlay.BorderSizePixel = 0
                blackOverlay.ZIndex = 7503
                blackOverlay.Parent = svCanvas
                local blackGrad = Instance.new("UIGradient", blackOverlay)
                blackGrad.Rotation = 90
                blackGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0)
                })

                -- Circular Selector Pin on SV Canvas
                local svCursor = Instance.new("Frame")
                svCursor.Name = "Cursor"
                svCursor.Size = UDim2.new(0, 12, 0, 12)
                svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                svCursor.Position = UDim2.new(currentS, 0, 1 - currentV, 0)
                svCursor.BackgroundColor3 = currentColor
                svCursor.BorderSizePixel = 0
                svCursor.ZIndex = 7505
                svCursor.Parent = svCanvas
                Instance.new("UICorner", svCursor).CornerRadius = UDim.new(1, 0)
                AddStroke(svCursor, Color3.new(1, 1, 1), 2)

                -- Hue Rainbow Slider Bar
                local hueBar = Instance.new("TextButton")
                hueBar.Name = "HueBar"
                hueBar.Size = UDim2.new(1, -20, 0, 14)
                hueBar.Position = UDim2.new(0, 10, 0, 149)
                hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
                hueBar.BorderSizePixel = 0
                hueBar.AutoButtonColor = false
                hueBar.Text = ""
                hueBar.ClipsDescendants = false
                hueBar.ZIndex = 7501
                hueBar.Parent = PickerModal
                Instance.new("UICorner", hueBar).CornerRadius = UDim.new(0, 7)
                AddStroke(hueBar, Colors.Border, 1)

                local hueGrad = Instance.new("UIGradient", hueBar)
                hueGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0/6, 1, 1)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromHSV(1/6, 1, 1)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromHSV(2/6, 1, 1)),
                    ColorSequenceKeypoint.new(0.50, Color3.fromHSV(3/6, 1, 1)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromHSV(4/6, 1, 1)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromHSV(5/6, 1, 1)),
                    ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1.0, 1, 1))
                })

                local hueCursor = Instance.new("Frame")
                hueCursor.Name = "HueCursor"
                hueCursor.Size = UDim2.new(0, 8, 0, 18)
                hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                hueCursor.Position = UDim2.new(currentH, 0, 0.5, 0)
                hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
                hueCursor.BorderSizePixel = 0
                hueCursor.ZIndex = 7505
                hueCursor.Parent = hueBar
                Instance.new("UICorner", hueCursor).CornerRadius = UDim.new(0, 4)
                AddStroke(hueCursor, Color3.fromRGB(30, 32, 40), 1.5)

                -- Info / Hex / RGB Row
                local InfoRow = Instance.new("Frame")
                InfoRow.Size = UDim2.new(1, -20, 0, 22)
                InfoRow.Position = UDim2.new(0, 10, 0, 171)
                InfoRow.BackgroundTransparency = 1
                InfoRow.ZIndex = 7501
                InfoRow.Parent = PickerModal

                local PreviewBox = Instance.new("Frame")
                PreviewBox.Size = UDim2.new(0, 22, 0, 22)
                PreviewBox.Position = UDim2.new(0, 0, 0, 0)
                PreviewBox.BackgroundColor3 = currentColor
                PreviewBox.BorderSizePixel = 0
                PreviewBox.ZIndex = 7502
                PreviewBox.Parent = InfoRow
                Instance.new("UICorner", PreviewBox).CornerRadius = UDim.new(0, 4)
                AddStroke(PreviewBox, Colors.BorderFocus, 1)

                local HexInput = Instance.new("TextBox")
                HexInput.Size = UDim2.new(0, 72, 0, 22)
                HexInput.Position = UDim2.new(0, 28, 0, 0)
                HexInput.BackgroundColor3 = Colors.InputBg
                HexInput.Text = "#" .. currentColor:ToHex():upper()
                HexInput.Font = Fonts.Code
                HexInput.TextSize = 11
                HexInput.TextColor3 = Colors.Text
                HexInput.ClearTextOnFocus = false
                HexInput.ZIndex = 7502
                HexInput.Parent = InfoRow
                Instance.new("UICorner", HexInput).CornerRadius = UDim.new(0, 4)
                AddStroke(HexInput, Colors.Border, 1)

                local RGBLabel = Instance.new("TextLabel")
                RGBLabel.Size = UDim2.new(1, -106, 0, 22)
                RGBLabel.Position = UDim2.new(0, 106, 0, 0)
                RGBLabel.BackgroundTransparency = 1
                RGBLabel.Font = Fonts.Code
                RGBLabel.TextSize = 10
                RGBLabel.TextColor3 = Colors.SubText
                RGBLabel.TextXAlignment = Enum.TextXAlignment.Right
                RGBLabel.Text = string.format("R:%d G:%d B:%d", math.round(currentColor.R * 255), math.round(currentColor.G * 255), math.round(currentColor.B * 255))
                RGBLabel.ZIndex = 7502
                RGBLabel.Parent = InfoRow

                -- Preset Palette Dots Row
                local PaletteRow = Instance.new("Frame")
                PaletteRow.Size = UDim2.new(1, -20, 0, 24)
                PaletteRow.Position = UDim2.new(0, 10, 0, 202)
                PaletteRow.BackgroundTransparency = 1
                PaletteRow.ZIndex = 7501
                PaletteRow.Parent = PickerModal

                local PaletteLayout = Instance.new("UIListLayout", PaletteRow)
                PaletteLayout.FillDirection = Enum.FillDirection.Horizontal
                PaletteLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                PaletteLayout.Padding = UDim.new(0, 7)

                local presets = {
                    Color3.fromRGB(124, 92, 252), -- Blade Purple
                    Color3.fromRGB(56, 150, 255),  -- Sky Blue
                    Color3.fromRGB(46, 213, 115),  -- Emerald Green
                    Color3.fromRGB(255, 177, 66),  -- Amber Gold
                    Color3.fromRGB(255, 71, 87),   -- Crimson Red
                    Color3.fromRGB(255, 107, 181), -- Hot Pink
                    Color3.fromRGB(255, 255, 255)  -- Pure White
                }

                local function ApplyColorChange(skipHex)
                    currentColor = Color3.fromHSV(currentH, currentS, currentV)
                    ColorBox.BackgroundColor3 = currentColor
                    PreviewBox.BackgroundColor3 = currentColor
                    svCursor.BackgroundColor3 = currentColor
                    if not skipHex then
                        HexInput.Text = "#" .. currentColor:ToHex():upper()
                    end
                    RGBLabel.Text = string.format("R:%d G:%d B:%d", math.round(currentColor.R * 255), math.round(currentColor.G * 255), math.round(currentColor.B * 255))
                    UpdateState(Config.ID, currentColor)
                    if Config.Callback then
                        Config.Callback(currentColor)
                    end
                end

                for _, pColor in ipairs(presets) do
                    local dot = Instance.new("TextButton")
                    dot.Size = UDim2.new(0, 18, 0, 18)
                    dot.BackgroundColor3 = pColor
                    dot.Text = ""
                    dot.AutoButtonColor = false
                    dot.ZIndex = 7502
                    dot.Parent = PaletteRow
                    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
                    AddStroke(dot, Colors.Border, 1)

                    dot.MouseButton1Click:Connect(function()
                        currentH, currentS, currentV = pColor:ToHSV()
                        svCanvas.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
                        svCursor.Position = UDim2.new(currentS, 0, 1 - currentV, 0)
                        hueCursor.Position = UDim2.new(currentH, 0, 0.5, 0)
                        ApplyColorChange()
                    end)
                end

                -- Direct Hex Input handler
                HexInput.FocusLost:Connect(function()
                    local text = HexInput.Text:gsub("#", ""):gsub("%s+", "")
                    if #text == 6 then
                        local ok, parsed = pcall(function() return Color3.fromHex(text) end)
                        if ok and parsed then
                            currentH, currentS, currentV = parsed:ToHSV()
                            svCanvas.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
                            svCursor.Position = UDim2.new(currentS, 0, 1 - currentV, 0)
                            hueCursor.Position = UDim2.new(currentH, 0, 0.5, 0)
                            ApplyColorChange(true)
                        else
                            HexInput.Text = "#" .. currentColor:ToHex():upper()
                        end
                    else
                        HexInput.Text = "#" .. currentColor:ToHex():upper()
                    end
                end)

                -- Dragging Logic for SV Canvas and Hue Bar
                local isDraggingSV = false
                local isDraggingHue = false

                local function UpdateSV(inputPos)
                    local canvasPos = svCanvas.AbsolutePosition
                    local canvasSize = svCanvas.AbsoluteSize
                    if canvasSize.X > 0 and canvasSize.Y > 0 then
                        local relX = math.clamp((inputPos.X - canvasPos.X) / canvasSize.X, 0, 1)
                        local relY = math.clamp((inputPos.Y - canvasPos.Y) / canvasSize.Y, 0, 1)
                        currentS = relX
                        currentV = 1 - relY
                        svCursor.Position = UDim2.new(currentS, 0, 1 - currentV, 0)
                        ApplyColorChange()
                    end
                end

                local function UpdateHue(inputPos)
                    local barPos = hueBar.AbsolutePosition
                    local barSize = hueBar.AbsoluteSize
                    if barSize.X > 0 then
                        local relX = math.clamp((inputPos.X - barPos.X) / barSize.X, 0, 1)
                        currentH = relX
                        hueCursor.Position = UDim2.new(currentH, 0, 0.5, 0)
                        svCanvas.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
                        ApplyColorChange()
                    end
                end

                svCanvas.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDraggingSV = true
                        UpdateSV(input.Position)
                    end
                end)

                hueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDraggingHue = true
                        UpdateHue(input.Position)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                        if isDraggingSV then
                            UpdateSV(input.Position)
                        elseif isDraggingHue then
                            UpdateHue(input.Position)
                        end
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDraggingSV = false
                        isDraggingHue = false
                    end
                end)

                ColorBox.MouseButton1Click:Connect(function()
                    if PickerModal.Visible then
                        PickerModal.Visible = false
                        activeColorPicker = nil
                        isDraggingSV = false
                        isDraggingHue = false
                    else
                        CloseAllDropdowns()
                        PickerModal.Visible = true
                        activeColorPicker = PickerModal

                        local absPos = ColorBox.AbsolutePosition
                        local mainAbsPos = MainFrame.AbsolutePosition
                        local mainSize = MainFrame.AbsoluteSize
                        local modalW = 220
                        local modalH = 242

                        local targetX = absPos.X - mainAbsPos.X - modalW + 40
                        local targetY = absPos.Y - mainAbsPos.Y + 26

                        if targetX + modalW > mainSize.X - 10 then
                            targetX = mainSize.X - modalW - 10
                        end
                        if targetX < 10 then
                            targetX = 10
                        end

                        if targetY + modalH > mainSize.Y - 10 then
                            targetY = (absPos.Y - mainAbsPos.Y) - modalH - 4
                            if targetY < 10 then targetY = 10 end
                        end

                        PickerModal.Position = UDim2.new(0, targetX, 0, targetY)
                    end
                end)

                if Config.ID and RaxorHub.Objects then
                    RaxorHub.Objects[Config.ID] = {
                        Type = "ColorPicker",
                        Default = Config.Default,
                        Update = function(val)
                            if typeof(val) == "Color3" then
                                currentColor = val
                                currentH, currentS, currentV = currentColor:ToHSV()
                                ColorBox.BackgroundColor3 = currentColor
                                PreviewBox.BackgroundColor3 = currentColor
                                svCanvas.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
                                svCursor.Position = UDim2.new(currentS, 0, 1 - currentV, 0)
                                svCursor.BackgroundColor3 = currentColor
                                hueCursor.Position = UDim2.new(currentH, 0, 0.5, 0)
                                HexInput.Text = "#" .. currentColor:ToHex():upper()
                                RGBLabel.Text = string.format("R:%d G:%d B:%d", math.round(currentColor.R * 255), math.round(currentColor.G * 255), math.round(currentColor.B * 255))
                            end
                        end,
                        Callback = Config.Callback or function() end
                    }
                end
            end

            -- [[ Input Box (Blade Text Field) ]]
            function sectionItems:AddInput(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.ZIndex = 28
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                SetupRowText(Row, Config.Title, Config.Description, 175)

                local InputFrame = Instance.new("Frame")
                InputFrame.Size = UDim2.new(0, 150, 0, 32)
                InputFrame.Position = UDim2.new(1, -164, 0.5, -16)
                InputFrame.BackgroundColor3 = Colors.InputBg
                InputFrame.ClipsDescendants = true
                InputFrame.ZIndex = 30
                InputFrame.Parent = Row
                Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 6)
                local stroke = AddStroke(InputFrame, Colors.BorderFocus, 1)

                local TextBox = Instance.new("TextBox")
                TextBox.Size = UDim2.new(1, -16, 1, 0)
                TextBox.Position = UDim2.new(0, 8, 0, 0)
                TextBox.BackgroundTransparency = 1
                TextBox.Text = Config.Default or ""
                TextBox.PlaceholderText = Config.Placeholder or "Input..."
                TextBox.PlaceholderColor3 = Colors.MutedText
                TextBox.TextColor3 = Colors.Text
                TextBox.TextSize = 12
                TextBox.Font = Fonts.Regular
                TextBox.TextXAlignment = Enum.TextXAlignment.Left
                TextBox.ClearTextOnFocus = false
                TextBox.ZIndex = 31
                TextBox.Parent = InputFrame

                if Config.ID and RaxorHub.Objects then
                    UpdateState(Config.ID, Config.Default or "")
                    RaxorHub.Objects[Config.ID] = {
                        Type = "Input",
                        Instance = TextBox,
                        Callback = Config.Callback,
                        Update = function(val)
                            TextBox.Text = tostring(val)
                        end
                    }
                end

                TextBox.Focused:Connect(function() stroke.Color = Colors.Accent end)
                TextBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local currentText = TextBox.Text
                    if Config.ID then UpdateState(Config.ID, currentText) end
                    if Config.Callback then Config.Callback(currentText, false) end
                end)
                TextBox.FocusLost:Connect(function(enterPressed)
                    stroke.Color = Colors.BorderFocus
                    local currentText = TextBox.Text
                    if Config.ID then UpdateState(Config.ID, currentText) end
                    if Config.Callback then Config.Callback(currentText, enterPressed) end
                end)

                local inputFunc = {
                    Instance = TextBox,
                    Set = function(self, val)
                        TextBox.Text = tostring(val)
                        if Config.ID then UpdateState(Config.ID, tostring(val)) end
                    end,
                    Get = function(self)
                        return TextBox.Text
                    end
                }
                return inputFunc
            end

            -- [[ Button Control (Blade Sleek Clickable) ]]
            function sectionItems:AddButton(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.ZIndex = 28
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                SetupRowText(Row, Config.Title, Config.Description, 140)

                local Button = Instance.new("TextButton")
                Button.Name = "RaxorButton"
                Button.Size = UDim2.new(0, 110, 0, 30)
                Button.Position = UDim2.new(1, -124, 0.5, -15)
                Button.BackgroundColor3 = Colors.ButtonBg
                Button.AutoButtonColor = false
                Button.Text = Config.ButtonText or "Execute"
                Button.Font = Fonts.Title
                Button.TextSize = 12
                Button.TextColor3 = Colors.Text
                Button.ZIndex = 31
                Button.Parent = Row
                Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)
                AddStroke(Button, Colors.BorderFocus, 1)

                Button.MouseEnter:Connect(function()
                    Tween(Button, TweenInfo.new(0.12), {BackgroundColor3 = Colors.ButtonHover})
                end)
                Button.MouseLeave:Connect(function()
                    Tween(Button, TweenInfo.new(0.12), {BackgroundColor3 = Colors.ButtonBg})
                end)
                Button.MouseButton1Down:Connect(function()
                    Tween(Button, TweenInfo.new(0.08), {BackgroundColor3 = Colors.Accent})
                end)
                Button.MouseButton1Up:Connect(function()
                    Tween(Button, TweenInfo.new(0.08), {BackgroundColor3 = Colors.ButtonHover})
                end)
                Button.MouseButton1Click:Connect(function()
                    if Config.Callback then Config.Callback() end
                end)

                return Button
            end

            -- [[ Label / Information Banner ]]
            function sectionItems:AddLabel(Title)
                local Row = Instance.new("Frame")
                Row.Size = UDim2.new(1, -4, 0, 32)
                Row.BackgroundColor3 = Color3.fromRGB(20, 21, 29)
                Row.BorderSizePixel = 0
                Row.ZIndex = 28
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                local stroke = AddStroke(Row, Colors.BorderFocus, 1)
                stroke.Transparency = 0.5

                local Accent = Instance.new("Frame")
                Accent.Size = UDim2.new(0, 3, 1, -12)
                Accent.Position = UDim2.new(0, 8, 0.5, 0)
                Accent.AnchorPoint = Vector2.new(0, 0.5)
                Accent.BackgroundColor3 = Colors.Accent
                Accent.BorderSizePixel = 0
                Accent.ZIndex = 29
                Accent.Parent = Row
                Instance.new("UICorner", Accent).CornerRadius = UDim.new(1, 0)

                local TTitle = Instance.new("TextLabel")
                TTitle.Text = tostring(Title)
                TTitle.Size = UDim2.new(1, -26, 1, 0)
                TTitle.Position = UDim2.new(0, 18, 0, 0)
                TTitle.Font = Fonts.Medium
                TTitle.TextSize = 12
                TTitle.TextColor3 = Colors.Text
                TTitle.TextXAlignment = Enum.TextXAlignment.Left
                TTitle.TextWrapped = true
                TTitle.BackgroundTransparency = 1
                TTitle.ZIndex = 29
                TTitle.Parent = Row

                local labelFunc = {}
                function labelFunc:Set(newText)
                    TTitle.Text = tostring(newText)
                end
                function labelFunc:SetColor(color)
                    Accent.BackgroundColor3 = color
                    TTitle.TextColor3 = color
                end
                return labelFunc
            end

            -- [[ Log Box / History Audit Control (Sleek Modern Feed with Badges & Clear) ]]
            function sectionItems:AddLogBox(Config)
                Config = Config or {}
                local boxHeight = Config.Height or 170
                local maxEntries = Config.MaxEntries or 80
                local entriesList = {}

                local Container = Instance.new("Frame")
                Container.Name = "RaxorLogBox"
                Container.Size = UDim2.new(1, -4, 0, boxHeight + 46)
                Container.BackgroundColor3 = Colors.CardBg
                Container.ZIndex = 28
                Container.Parent = SectionFrame
                Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)
                AddStroke(Container, Colors.Border, 1)

                -- Header Frame
                local Header = Instance.new("Frame")
                Header.Name = "LogHeader"
                Header.Size = UDim2.new(1, -16, 0, 32)
                Header.Position = UDim2.new(0, 8, 0, 4)
                Header.BackgroundTransparency = 1
                Header.ZIndex = 29
                Header.Parent = Container

                local HeaderAccent = Instance.new("Frame")
                HeaderAccent.Size = UDim2.new(0, 3, 0, 14)
                HeaderAccent.Position = UDim2.new(0, 0, 0.5, -7)
                HeaderAccent.BackgroundColor3 = Colors.Accent
                HeaderAccent.BorderSizePixel = 0
                HeaderAccent.ZIndex = 30
                HeaderAccent.Parent = Header
                Instance.new("UICorner", HeaderAccent).CornerRadius = UDim.new(1, 0)

                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Text = tostring(Config.Title or "Activity Log")
                TitleLabel.Font = Fonts.Title
                TitleLabel.TextSize = 13
                TitleLabel.TextColor3 = Colors.Text
                TitleLabel.Size = UDim2.new(1, -140, 1, 0)
                TitleLabel.Position = UDim2.new(0, 10, 0, 0)
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.ZIndex = 30
                TitleLabel.Parent = Header

                local CounterBadge = Instance.new("TextLabel")
                CounterBadge.Text = "(0)"
                CounterBadge.Font = Fonts.Medium
                CounterBadge.TextSize = 11
                CounterBadge.TextColor3 = Colors.SubText
                CounterBadge.Size = UDim2.new(0, 45, 1, 0)
                CounterBadge.Position = UDim2.new(0, 10 + TitleLabel.TextBounds.X + 8, 0, 0)
                CounterBadge.TextXAlignment = Enum.TextXAlignment.Left
                CounterBadge.BackgroundTransparency = 1
                CounterBadge.ZIndex = 30
                CounterBadge.Parent = Header

                TitleLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
                    CounterBadge.Position = UDim2.new(0, 10 + TitleLabel.TextBounds.X + 8, 0, 0)
                end)

                -- Clear Button
                local ClearBtn = Instance.new("TextButton")
                ClearBtn.Name = "ClearBtn"
                ClearBtn.Size = UDim2.new(0, 60, 0, 22)
                ClearBtn.Position = UDim2.new(1, -60, 0.5, -11)
                ClearBtn.BackgroundColor3 = Colors.ButtonBg
                ClearBtn.AutoButtonColor = false
                ClearBtn.Text = "Clear"
                ClearBtn.Font = Fonts.Medium
                ClearBtn.TextSize = 11
                ClearBtn.TextColor3 = Colors.SubText
                ClearBtn.ZIndex = 31
                ClearBtn.Parent = Header
                Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 4)
                AddStroke(ClearBtn, Colors.Border, 1)

                ClearBtn.MouseEnter:Connect(function()
                    Tween(ClearBtn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.ButtonHover, TextColor3 = Colors.White})
                end)
                ClearBtn.MouseLeave:Connect(function()
                    Tween(ClearBtn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.ButtonBg, TextColor3 = Colors.SubText})
                end)

                -- Content Frame (ScrollingFrame)
                local Scroll = Instance.new("ScrollingFrame")
                Scroll.Name = "LogScroll"
                Scroll.Size = UDim2.new(1, -16, 0, boxHeight)
                Scroll.Position = UDim2.new(0, 8, 0, 38)
                Scroll.BackgroundColor3 = Color3.fromRGB(17, 18, 23)
                Scroll.BorderSizePixel = 0
                Scroll.ScrollBarThickness = 3
                Scroll.ScrollBarImageColor3 = Colors.BorderFocus
                Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                Scroll.ZIndex = 29
                Scroll.Parent = Container
                Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 4)
                AddStroke(Scroll, Colors.Border, 1)

                local ScrollPadding = Instance.new("UIPadding", Scroll)
                ScrollPadding.PaddingTop = UDim.new(0, 4)
                ScrollPadding.PaddingBottom = UDim.new(0, 4)
                ScrollPadding.PaddingLeft = UDim.new(0, 4)
                ScrollPadding.PaddingRight = UDim.new(0, 4)

                local LogLayout = Instance.new("UIListLayout", Scroll)
                LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
                LogLayout.Padding = UDim.new(0, 4)

                local EmptyLabel = Instance.new("TextLabel")
                EmptyLabel.Name = "EmptyLabel"
                EmptyLabel.Size = UDim2.new(1, 0, 1, 0)
                EmptyLabel.Text = Config.EmptyText or "No log records yet (Waiting for activity...)"
                EmptyLabel.Font = Fonts.Regular
                EmptyLabel.TextSize = 11
                EmptyLabel.TextColor3 = Colors.MutedText
                EmptyLabel.TextXAlignment = Enum.TextXAlignment.Center
                EmptyLabel.BackgroundTransparency = 1
                EmptyLabel.ZIndex = 30
                EmptyLabel.Parent = Scroll

                local function UpdateCounter()
                    CounterBadge.Text = "(" .. tostring(#entriesList) .. ")"
                    EmptyLabel.Visible = (#entriesList == 0)
                end

                local RarityColors = {
                    ["Divine"]    = Color3.fromRGB(255, 220, 80),
                    ["Secret"]    = Color3.fromRGB(235, 90, 255),
                    ["Mythic"]    = Color3.fromRGB(255, 68, 85),
                    ["Legendary"] = Color3.fromRGB(255, 170, 40),
                    ["Epic"]      = Color3.fromRGB(180, 100, 255),
                    ["Rare"]      = Color3.fromRGB(80, 165, 255),
                    ["Uncommon"]  = Color3.fromRGB(100, 225, 120),
                    ["Common"]    = Color3.fromRGB(180, 185, 195)
                }

                local logObj = {}

                function logObj:AddEntry(data)
                    if type(data) ~= "table" then
                        data = { Name = tostring(data) }
                    end

                    table.insert(entriesList, data)
                    if #entriesList > maxEntries then
                        table.remove(entriesList, 1)
                        local firstChild = Scroll:FindFirstChild("Entry_1")
                        if firstChild then firstChild:Destroy() end
                    end

                    UpdateCounter()

                    local order = #entriesList
                    local item = Instance.new("Frame")
                    item.Name = "Entry_" .. tostring(order)
                    item.Size = UDim2.new(1, -2, 0, 28)
                    item.LayoutOrder = -order -- Newest on top!
                    item.BackgroundColor3 = Color3.fromRGB(22, 23, 31)
                    item.ZIndex = 30
                    item.Parent = Scroll
                    Instance.new("UICorner", item).CornerRadius = UDim.new(0, 4)
                    AddStroke(item, Colors.Border, 1)

                    -- Left Container (holds Timestamp, Action, Slot, Monster Name & Mutation)
                    local leftRow = Instance.new("Frame")
                    leftRow.Name = "LeftRow"
                    leftRow.Size = UDim2.new(1, -120, 1, 0)
                    leftRow.Position = UDim2.new(0, 6, 0, 0)
                    leftRow.BackgroundTransparency = 1
                    leftRow.ClipsDescendants = true
                    leftRow.ZIndex = 31
                    leftRow.Parent = item

                    local leftLayout = Instance.new("UIListLayout", leftRow)
                    leftLayout.FillDirection = Enum.FillDirection.Horizontal
                    leftLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    leftLayout.Padding = UDim.new(0, 6)

                    -- 1. Timestamp Pill
                    local timeStr = data.Time or os.date("%H:%M:%S")
                    local timeLbl = Instance.new("TextLabel")
                    timeLbl.LayoutOrder = 1
                    timeLbl.Size = UDim2.new(0, 50, 0, 18)
                    timeLbl.Text = timeStr
                    timeLbl.Font = Fonts.Medium
                    timeLbl.TextSize = 10
                    timeLbl.TextColor3 = Colors.MutedText
                    timeLbl.BackgroundTransparency = 1
                    timeLbl.ZIndex = 32
                    timeLbl.Parent = leftRow

                    -- 2. Action Badge
                    local action = tostring(data.Action or "INFO"):upper()
                    local actBg = Colors.ButtonBg
                    local actFg = Colors.White
                    if action == "BUY" then
                        actBg = Color3.fromRGB(34, 130, 75)
                    elseif action == "ROLL" or action == "TARGET" then
                        actBg = Colors.Accent
                    elseif action == "MANUAL" or action == "MANUAL BUY" then
                        actBg = Color3.fromRGB(150, 100, 30)
                    end

                    local actBadge = Instance.new("Frame")
                    actBadge.LayoutOrder = 2
                    actBadge.Size = UDim2.new(0, (action == "MANUAL BUY" or action == "TARGET") and 52 or 42, 0, 18)
                    actBadge.BackgroundColor3 = actBg
                    actBadge.ZIndex = 32
                    actBadge.Parent = leftRow
                    Instance.new("UICorner", actBadge).CornerRadius = UDim.new(0, 3)

                    local actText = Instance.new("TextLabel")
                    actText.Size = UDim2.new(1, 0, 1, 0)
                    actText.Text = action
                    actText.Font = Fonts.Title
                    actText.TextSize = 9
                    actText.TextColor3 = actFg
                    actText.BackgroundTransparency = 1
                    actText.ZIndex = 33
                    actText.Parent = actBadge

                    -- 3. Slot badge (if provided)
                    if data.Slot then
                        local slotBadge = Instance.new("Frame")
                        slotBadge.LayoutOrder = 3
                        slotBadge.Size = UDim2.new(0, 24, 0, 18)
                        slotBadge.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
                        slotBadge.ZIndex = 32
                        slotBadge.Parent = leftRow
                        Instance.new("UICorner", slotBadge).CornerRadius = UDim.new(0, 3)

                        local slotText = Instance.new("TextLabel")
                        slotText.Size = UDim2.new(1, 0, 1, 0)
                        slotText.Text = "S" .. tostring(data.Slot)
                        slotText.Font = Fonts.Medium
                        slotText.TextSize = 9
                        slotText.TextColor3 = Colors.SubText
                        slotText.BackgroundTransparency = 1
                        slotText.ZIndex = 33
                        slotText.Parent = slotBadge
                    end

                    -- 4. Monster Name & Rarity
                    local nameStr = tostring(data.Name or data.Message or "Unknown")
                    local rarityStr = tostring(data.Rarity or "Common")
                    local rColor = RarityColors[rarityStr] or Colors.Text

                    -- Strip redundant mutation suffix from name if mutation badge is shown
                    if data.Mutation and data.Mutation ~= "None" and data.Mutation ~= "" then
                        local suffix = "_" .. tostring(data.Mutation)
                        if string.sub(nameStr:lower(), -#suffix) == suffix:lower() then
                            nameStr = string.sub(nameStr, 1, #nameStr - #suffix)
                        end
                    end

                    local hasMutation = (data.Mutation and data.Mutation ~= "None" and data.Mutation ~= "")
                    local nameLbl = Instance.new("TextLabel")
                    nameLbl.LayoutOrder = 4
                    nameLbl.Size = UDim2.new(0, hasMutation and 145 or 195, 0, 18)
                    nameLbl.Text = nameStr .. " [" .. rarityStr .. "]"
                    nameLbl.Font = Fonts.Title
                    nameLbl.TextSize = 11
                    nameLbl.TextColor3 = rColor
                    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.ZIndex = 32
                    nameLbl.Parent = leftRow

                    -- 5. Mutation Tag (if not None)
                    if hasMutation then
                        local mutBadge = Instance.new("Frame")
                        mutBadge.LayoutOrder = 5
                        mutBadge.Size = UDim2.new(0, 54, 0, 18)
                        mutBadge.BackgroundColor3 = Color3.fromRGB(40, 30, 55)
                        mutBadge.ZIndex = 32
                        mutBadge.Parent = leftRow
                        Instance.new("UICorner", mutBadge).CornerRadius = UDim.new(0, 3)
                        AddStroke(mutBadge, Color3.fromRGB(150, 80, 220), 1)

                        local mutText = Instance.new("TextLabel")
                        mutText.Size = UDim2.new(1, 0, 1, 0)
                        mutText.Text = tostring(data.Mutation)
                        mutText.Font = Fonts.Medium
                        mutText.TextSize = 9
                        mutText.TextColor3 = Color3.fromRGB(220, 170, 255)
                        mutText.BackgroundTransparency = 1
                        mutText.ZIndex = 33
                        mutText.Parent = mutBadge
                    end

                    -- 6. Price Tag (Right-Anchored Pinned at Right Edge)
                    if data.Price and tostring(data.Price) ~= "" and tostring(data.Price) ~= "Standard Price" then
                        local priceLbl = Instance.new("TextLabel")
                        priceLbl.Name = "PriceLabel"
                        priceLbl.AnchorPoint = Vector2.new(1, 0.5)
                        priceLbl.Position = UDim2.new(1, -8, 0.5, 0)
                        priceLbl.Size = UDim2.new(0, 110, 0, 18)
                        priceLbl.Text = "Price: " .. tostring(data.Price)
                        priceLbl.Font = Fonts.Medium
                        priceLbl.TextSize = 10
                        priceLbl.TextColor3 = Color3.fromRGB(255, 215, 60)
                        priceLbl.TextXAlignment = Enum.TextXAlignment.Right
                        priceLbl.BackgroundTransparency = 1
                        priceLbl.ZIndex = 32
                        priceLbl.Parent = item
                    end
                end

                function logObj:Clear()
                    entriesList = {}
                    for _, child in ipairs(Scroll:GetChildren()) do
                        if child:IsA("Frame") and string.find(child.Name, "Entry_") then
                            child:Destroy()
                        end
                    end
                    UpdateCounter()
                end

                ClearBtn.MouseButton1Click:Connect(function()
                    logObj:Clear()
                end)

                return logObj
            end

            -- [[ Keybind Control (Blade Keybind Modal Image 6) ]]
            function sectionItems:AddKeybind(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.ZIndex = 28
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                SetupRowText(Row, Config.Title, Config.Description, 120)

                local currentKey = Config.Default
                local keyConnection

                local BindButton = Instance.new("TextButton")
                BindButton.Size = UDim2.new(0, 90, 0, 28)
                BindButton.Position = UDim2.new(1, -104, 0.5, -14)
                BindButton.BackgroundColor3 = Colors.ButtonBg
                BindButton.AutoButtonColor = false
                BindButton.Text = currentKey and "[" .. currentKey.Name .. "]" or "[ ... ]"
                BindButton.Font = Fonts.Code
                BindButton.TextSize = 12
                BindButton.TextColor3 = Colors.Text
                BindButton.ZIndex = 30
                BindButton.Parent = Row
                Instance.new("UICorner", BindButton).CornerRadius = UDim.new(0, 6)
                AddStroke(BindButton, Colors.BorderFocus, 1)

                if currentKey then UpdateState(Config.ID, currentKey.Name) end

                local function StartListening()
                    if keyConnection then keyConnection:Disconnect() end
                    if not currentKey then return end

                    keyConnection = UserInputService.InputBegan:Connect(function(input, gp)
                        if gp or IsBinding then return end
                        if input.KeyCode == currentKey then
                            if Config.Callback then Config.Callback(currentKey) end
                        end
                    end)

                    if Config.ID and RaxorHub.Objects[Config.ID] then
                        RaxorHub.Objects[Config.ID].Connection = keyConnection
                    end
                end

                if Config.ID and RaxorHub.Objects then
                    RaxorHub.Objects[Config.ID] = {
                        Type = "Keybind",
                        Stop = function()
                            if keyConnection then
                                keyConnection:Disconnect()
                                keyConnection = nil
                            end
                        end,
                        Update = function(valName)
                            if not valName or valName == "" then return end
                            if typeof(valName) == "string" and Enum.KeyCode[valName] then
                                currentKey = Enum.KeyCode[valName]
                                BindButton.Text = "[" .. valName .. "]"
                                StartListening()
                            end
                        end
                    }
                end

                if currentKey then StartListening() end

                BindButton.MouseButton1Click:Connect(function()
                    if IsBinding then return end
                    IsBinding = true
                    BindButton.Text = "[ ... ]"
                    BindButton.TextColor3 = Colors.Accent

                    local tempConnection
                    tempConnection = UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            local newKey = input.KeyCode
                            if newKey ~= Enum.KeyCode.Escape then
                                currentKey = newKey
                                BindButton.Text = "[" .. newKey.Name .. "]"
                                UpdateState(Config.ID, newKey.Name)
                                StartListening()
                            else
                                BindButton.Text = currentKey and "[" .. currentKey.Name .. "]" or "[ ... ]"
                            end
                            BindButton.TextColor3 = Colors.Text
                            tempConnection:Disconnect()
                            task.wait(0.05)
                            IsBinding = false
                        end
                    end)
                end)

                local keybindFunc = {
                    Set = function(self, key)
                        if typeof(key) == "EnumItem" then
                            currentKey = key
                            BindButton.Text = "[" .. key.Name .. "]"
                            UpdateState(Config.ID, key.Name)
                            StartListening()
                        elseif type(key) == "string" and Enum.KeyCode[key] then
                            currentKey = Enum.KeyCode[key]
                            BindButton.Text = "[" .. key .. "]"
                            UpdateState(Config.ID, key)
                            StartListening()
                        end
                    end,
                    Get = function(self)
                        return currentKey
                    end
                }
                return keybindFunc
            end

            return sectionItems
        end
        return tab
    end

    -- Close dropdowns on canvas click
    ContentContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            CloseAllDropdowns()
        end
    end)

    -- [[ Automatically Load Autoload Preset on Startup ]]
    task.spawn(function()
        task.wait(0.6)
        local autoPreset = RaxorHub:GetAutoload()
        if autoPreset and autoPreset ~= "" and autoPreset ~= "None" then
            RaxorHub:LoadConfigData(autoPreset)
        end
    end)

    return window
end

return RaxorHub
