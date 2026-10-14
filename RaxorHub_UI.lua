--[[
    ╔════════════════════════════════════════════════════════════════════╗
    ║                           RAXORHUB UI                              ║
    ║                  Modern Blade-Client Aesthetic                     ║
    ║           Optimized for PC & Mobile (Performance-Focused)         ║
    ║                       Version: v2.1.0                              ║
    ║                         By : Pigalo                                ║
    ╚════════════════════════════════════════════════════════════════════╝
]]

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
local UI_VERSION = "v2.1.0"

-- Executor & CoreGui protection
local CoreGuiSuccess, CoreGui = pcall(function() return game:GetService("CoreGui") end)
local OldUI = (CoreGuiSuccess and CoreGui and CoreGui:FindFirstChild(UI_NAME)) or PlayerGui:FindFirstChild(UI_NAME)

if OldUI then
    warn("[RaxorHub] Cleaning up existing instance...")
    OldUI:Destroy()
end

local ConfigFolder = "RaxorHub_Configs"
if isfolder and makefolder and not isfolder(ConfigFolder) then
    makefolder(ConfigFolder)
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
    SubText         = Color3.fromRGB(160, 164, 180),   -- Secondary Text (Crisp for Thai)
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

-- [[ Font Configuration - Highly legible for Thai & English ]]
local Fonts = {
    Title       = Enum.Font.UbuntuBold,     -- Clean bold headers (renders Thai tone marks properly)
    Medium      = Enum.Font.UbuntuMedium,   -- Controls & option labels
    Regular     = Enum.Font.Ubuntu,         -- Descriptions & inputs (no tiny Thai bug)
    Brand       = Enum.Font.GothamBlack,    -- Stylized brand typography
    Code        = Enum.Font.Code            -- Numbers & keybind tags
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

    Search      = "rbxassetid://6031154871",      -- Search Glass
    ChevronDown = "rbxassetid://6034818372",      -- Chevron
    Checkmark   = "rbxassetid://6031094667",      -- Checkmark
    Trash       = "rbxassetid://6031079143",      -- Trash
    Plus        = "rbxassetid://6031094678"       -- Plus
}
RaxorHub.Icons = Icons

-- [[ Sizing Definitions (Spaced generously for Thai tone marks) ]]
local SizeItem = {
    BoxItem   = UDim2.new(1, -4, 0, 58),  -- Height 58px for full Thai vowel rendering
    TitleItem = UDim2.new(1, -4, 0, 38)
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
end
RaxorHub.CloseAllDropdowns = CloseAllDropdowns

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
                local btnSize = obj.AbsoluteSize
                local currentX = newPos.X.Offset + (screenSize.X * newPos.X.Scale)
                local currentY = newPos.Y.Offset + (screenSize.Y * newPos.Y.Scale)
                local finalX = math.clamp(currentX, 8, math.max(8, screenSize.X - btnSize.X - 8))
                local finalY = math.clamp(currentY, 8, math.max(8, screenSize.Y - btnSize.Y - 8))

                obj.Position = UDim2.new(0, finalX, 0, finalY)
                if screenSize.X - btnSize.X > 0 then lastRatioX = finalX / (screenSize.X - btnSize.X) end
                if screenSize.Y - btnSize.Y > 0 then lastRatioY = finalY / (screenSize.Y - btnSize.Y) end
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

-- [[ Config System ]]
function RaxorHub:GetConfigList()
    if not listfiles or not isfolder or not isfolder(ConfigFolder) then return {} end
    local files = listfiles(ConfigFolder)
    local names = {}
    for _, file in ipairs(files) do
        if file:sub(-5) == ".json" then
            local cleanPath = file:gsub("\\", "/")
            local nameWithExtension = cleanPath:gsub(ConfigFolder .. "/", "")
            local finalName = nameWithExtension:gsub(".json", "")
            table.insert(names, finalName)
        end
    end
    return names
end

function RaxorHub:SaveCurrentConfig(name)
    if not name or name == "" or not writefile then return end
    local json = HttpService:JSONEncode(RaxorHub.ConfigData)
    writefile(ConfigFolder .. "/" .. name .. ".json", json)
    RaxorHub:Notify({
        Title = "Preset Saved",
        Content = "Config '" .. name .. "' has been saved.",
        Duration = 3
    })
end

local function ApplySettings(data)
    for id, value in pairs(data) do
        local obj = RaxorHub.Objects[id]
        if obj then
            if obj.Update then obj.Update(value) end
            if obj.Callback then
                task.spawn(function()
                    pcall(function() obj.Callback(value) end)
                end)
            end
        end
    end
end

function RaxorHub:LoadConfigData(name)
    if not isfile or not readfile then return nil end
    local fileName = ConfigFolder .. "/" .. name .. ".json"
    if isfile(fileName) then
        local json = readfile(fileName)
        local data = HttpService:JSONDecode(json)
        for id, value in pairs(data) do
            RaxorHub.ConfigData[id] = value
        end
        ApplySettings(data)
        RaxorHub:Notify({
            Title = "Preset Loaded",
            Content = "Config '" .. name .. "' loaded successfully.",
            Duration = 3
        })
        return data
    end
    return nil
end

function RaxorHub:DeleteConfig(name)
    if not isfile or not delfile then return end
    local fileName = ConfigFolder .. "/" .. name .. ".json"
    if isfile(fileName) then
        delfile(fileName)
        RaxorHub:Notify({
            Title = "Preset Deleted",
            Content = "Config '" .. name .. "' has been removed.",
            Duration = 3
        })
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
    if writefile then writefile(AutoloadFile, name) end
end

function RaxorHub:GetAutoload()
    return (isfile and readfile and isfile(AutoloadFile)) and readfile(AutoloadFile) or nil
end

function RaxorHub:ResetAutoload()
    if isfile and delfile and isfile(AutoloadFile) then delfile(AutoloadFile) end
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
    MainFrame.ClipsDescendants = true
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

    -- Floating Mobile / PC Toggle Button (Using Official RaxorHub Logo)
    StartBtn = Instance.new("ImageButton")
    RaxorHub.StartBtn = StartBtn
    StartBtn.Name = "StartBtn"
    StartBtn.Size = UDim2.new(0, 48, 0, 48)
    StartBtn.Position = UDim2.new(0.5, -24, 0.05, 0)
    StartBtn.BackgroundColor3 = Colors.SidebarBg
    StartBtn.Image = Icons.Logo
    StartBtn.ImageColor3 = Colors.White
    StartBtn.Visible = false
    StartBtn.ZIndex = 8000
    StartBtn.Parent = ScreenGui
    Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 12)
    AddStroke(StartBtn, Colors.BorderActive, 1.5)

    local function ToggleUI()
        CloseAllDropdowns()
        if MainFrame.Visible then
            Tween(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, MainFrame.AbsoluteSize.X * 0.95, 0, MainFrame.AbsoluteSize.Y * 0.95),
                BackgroundTransparency = 1
            })
            task.wait(0.18)
            MainFrame.Visible = false
            MainFrame.Size = UDim2.new(0, frameW, 0, frameH)
            MainFrame.BackgroundTransparency = 0
            StartBtn.Visible = true
        else
            MainFrame.Visible = true
            StartBtn.Visible = false
            MainFrame.Size = UDim2.new(0, frameW * 0.95, 0, frameH * 0.95)
            MainFrame.BackgroundTransparency = 0.5
            Tween(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, frameW, 0, frameH),
                BackgroundTransparency = 0
            })
        end
    end
    RaxorHub.ToggleUI = ToggleUI

    MakeDraggableStartBtn(StartBtn, StartBtn, function()
        ToggleUI()
    end)

    -- [[ Resizer Corner (PC) ]]
    local ResizeHandle = Instance.new("Frame")
    ResizeHandle.Name = "ResizeHandle"
    ResizeHandle.Size = UDim2.new(0, 18, 0, 18)
    ResizeHandle.Position = UDim2.new(1, -18, 1, -18)
    ResizeHandle.BackgroundTransparency = 1
    ResizeHandle.ZIndex = 5000
    ResizeHandle.Parent = MainFrame

    local ResizeLine1 = Instance.new("Frame")
    ResizeLine1.Size = UDim2.new(0, 8, 0, 2)
    ResizeLine1.Position = UDim2.new(1, -10, 1, -5)
    ResizeLine1.Rotation = -45
    ResizeLine1.BackgroundColor3 = Colors.MutedText
    ResizeLine1.BorderSizePixel = 0
    ResizeLine1.ZIndex = 4999
    ResizeLine1.Parent = ResizeHandle

    local ResizeLine2 = Instance.new("Frame")
    ResizeLine2.Size = UDim2.new(0, 5, 0, 2)
    ResizeLine2.Position = UDim2.new(1, -7, 1, -5)
    ResizeLine2.Rotation = -45
    ResizeLine2.BackgroundColor3 = Colors.MutedText
    ResizeLine2.BorderSizePixel = 0
    ResizeLine2.ZIndex = 4999
    ResizeLine2.Parent = ResizeHandle

    MakeResizable(MainFrame, ResizeHandle)

    -- [[ Left Sidebar (Blade Style) ]]
    local SidebarWidth = 175
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, SidebarWidth, 1, 0)
    Sidebar.Position = UDim2.new(0, 0, 0, 0)
    Sidebar.BackgroundColor3 = Colors.SidebarBg
    Sidebar.BorderSizePixel = 0
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
    BrandContainer.Size = UDim2.new(1, 0, 0, 50)
    BrandContainer.BackgroundTransparency = 1
    BrandContainer.ZIndex = 22
    BrandContainer.Parent = Sidebar

    local BrandLogo = Instance.new("ImageLabel")
    BrandLogo.Size = UDim2.new(0, 28, 0, 28)
    BrandLogo.Position = UDim2.new(0, 12, 0.5, -14)
    BrandLogo.Image = GuiConfig.Logo or Icons.Logo
    BrandLogo.ImageColor3 = Colors.White
    BrandLogo.BackgroundTransparency = 1
    BrandLogo.ZIndex = 23
    BrandLogo.Parent = BrandContainer

    local BrandTitle = Instance.new("TextLabel")
    BrandTitle.Text = string.upper(GuiConfig.Title or "RAXOR")
    BrandTitle.Font = Fonts.Brand
    BrandTitle.TextSize = 16
    BrandTitle.TextColor3 = Colors.Text
    BrandTitle.Position = UDim2.new(0, 46, 0.5, -9)
    BrandTitle.Size = UDim2.new(1, -52, 0, 18)
    BrandTitle.TextXAlignment = Enum.TextXAlignment.Left
    BrandTitle.BackgroundTransparency = 1
    BrandTitle.ZIndex = 23
    BrandTitle.Parent = BrandContainer

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
    ProfileStatus.Font = Fonts.Regular
    ProfileStatus.TextSize = 11
    ProfileStatus.TextColor3 = Colors.SubText
    ProfileStatus.Size = UDim2.new(1, -48, 0, 14)
    ProfileStatus.Position = UDim2.new(0, 46, 0, 26)
    ProfileStatus.TextXAlignment = Enum.TextXAlignment.Left
    ProfileStatus.TextTruncate = Enum.TextTruncate.AtEnd
    ProfileStatus.BackgroundTransparency = 1
    ProfileStatus.ZIndex = 26
    ProfileStatus.Parent = ProfileCard

    -- [[ Top Bar Area (Fixed overlapping: Search on Left, Controls on Right) ]]
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, -SidebarWidth, 0, 48)
    TopBar.Position = UDim2.new(0, SidebarWidth, 0, 0)
    TopBar.BackgroundTransparency = 1
    TopBar.BorderSizePixel = 0
    TopBar.ZIndex = 30
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
    CreateTopIconBtn("FolderBtn", Icons.Folder, Colors.ControlBtn, Colors.ButtonHover, 1, function()
        if PresetsModal then
            PresetsModal.Visible = not PresetsModal.Visible
        end
    end)

    -- Minimize Button (Icon 9)
    CreateTopIconBtn("MinBtn", Icons.Minimize, Colors.ControlBtn, Colors.ButtonHover, 2, function()
        ToggleUI()
    end)

    -- Restore / Center Button (Icon 10)
    CreateTopIconBtn("ResBtn", Icons.Restore, Colors.ControlBtn, Colors.ButtonHover, 3, function()
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        MainFrame.Position = UDim2.new(0.5, -MainFrame.AbsoluteSize.X / 2, 0.5, -MainFrame.AbsoluteSize.Y / 2)
    end)

    -- Close Button (Icon 11)
    CreateTopIconBtn("CloseBtn", Icons.Close, Colors.ControlBtn, Colors.CloseRed, 4, function()
        RaxorHub:ResetAllSettings()
        task.wait(0.1)
        ScreenGui:Destroy()
    end)

    -- Search Element Box (Left-aligned, flexible width, NEVER overlaps with controls!)
    local SearchContainer = Instance.new("Frame")
    SearchContainer.Name = "SearchContainer"
    SearchContainer.Size = UDim2.new(1, -165, 0, 30)
    SearchContainer.Position = UDim2.new(0, 14, 0.5, -15)
    SearchContainer.BackgroundColor3 = Colors.InputBg
    SearchContainer.ZIndex = 32
    SearchContainer.Parent = TopBar
    Instance.new("UICorner", SearchContainer).CornerRadius = UDim.new(0, 6)
    local searchStroke = AddStroke(SearchContainer, Colors.Border, 1)

    -- Clamp max search width to 240px
    local searchConstraint = Instance.new("UISizeConstraint")
    searchConstraint.MaxSize = Vector2.new(240, 30)
    searchConstraint.MinSize = Vector2.new(100, 30)
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

    -- [[ Presets Modal Popup (Matches Blade Image 7) ]]
    PresetsModal = Instance.new("Frame")
    PresetsModal.Name = "PresetsModal"
    PresetsModal.Size = UDim2.new(0, 240, 0, 290)
    PresetsModal.Position = UDim2.new(1, -250, 0, 52)
    PresetsModal.BackgroundColor3 = Colors.ModalBg
    PresetsModal.BorderSizePixel = 0
    PresetsModal.Visible = false
    PresetsModal.ZIndex = 6000
    PresetsModal.Parent = MainFrame
    Instance.new("UICorner", PresetsModal).CornerRadius = UDim.new(0, 8)
    AddStroke(PresetsModal, Colors.BorderFocus, 1)

    local PresetsHeader = Instance.new("Frame")
    PresetsHeader.Size = UDim2.new(1, 0, 0, 36)
    PresetsHeader.BackgroundTransparency = 1
    PresetsHeader.ZIndex = 6001
    PresetsHeader.Parent = PresetsModal

    local PresetsIcon = Instance.new("ImageLabel")
    PresetsIcon.Size = UDim2.new(0, 16, 0, 16)
    PresetsIcon.Position = UDim2.new(0, 10, 0.5, -8)
    PresetsIcon.Image = Icons.Folder
    PresetsIcon.ImageColor3 = Colors.Accent
    PresetsIcon.BackgroundTransparency = 1
    PresetsIcon.ZIndex = 6002
    PresetsIcon.Parent = PresetsHeader

    local PresetsTitle = Instance.new("TextLabel")
    PresetsTitle.Text = "Presets"
    PresetsTitle.Font = Fonts.Title
    PresetsTitle.TextSize = 13
    PresetsTitle.TextColor3 = Colors.Text
    PresetsTitle.Position = UDim2.new(0, 32, 0.5, -8)
    PresetsTitle.Size = UDim2.new(0, 100, 0, 16)
    PresetsTitle.TextXAlignment = Enum.TextXAlignment.Left
    PresetsTitle.BackgroundTransparency = 1
    PresetsTitle.ZIndex = 6002
    PresetsTitle.Parent = PresetsHeader

    -- New Config Input & Add Button (Save Icon 8)
    local ConfigInputFrame = Instance.new("Frame")
    ConfigInputFrame.Size = UDim2.new(1, -16, 0, 28)
    ConfigInputFrame.Position = UDim2.new(0, 8, 0, 38)
    ConfigInputFrame.BackgroundColor3 = Colors.InputBg
    ConfigInputFrame.ZIndex = 6002
    ConfigInputFrame.Parent = PresetsModal
    Instance.new("UICorner", ConfigInputFrame).CornerRadius = UDim.new(0, 5)
    AddStroke(ConfigInputFrame, Colors.Border, 1)

    local ConfigNameInput = Instance.new("TextBox")
    ConfigNameInput.Size = UDim2.new(1, -34, 1, 0)
    ConfigNameInput.Position = UDim2.new(0, 8, 0, 0)
    ConfigNameInput.BackgroundTransparency = 1
    ConfigNameInput.PlaceholderText = "New config name..."
    ConfigNameInput.PlaceholderColor3 = Colors.MutedText
    ConfigNameInput.TextColor3 = Colors.Text
    ConfigNameInput.Font = Fonts.Regular
    ConfigNameInput.TextSize = 11
    ConfigNameInput.TextXAlignment = Enum.TextXAlignment.Left
    ConfigNameInput.ClearTextOnFocus = false
    ConfigNameInput.ZIndex = 6003
    ConfigNameInput.Parent = ConfigInputFrame

    local AddConfigBtn = Instance.new("ImageButton")
    AddConfigBtn.Size = UDim2.new(0, 22, 0, 22)
    AddConfigBtn.Position = UDim2.new(1, -25, 0.5, -11)
    AddConfigBtn.BackgroundColor3 = Colors.Accent
    AddConfigBtn.Image = Icons.Save
    AddConfigBtn.ImageColor3 = Colors.White
    AddConfigBtn.ZIndex = 6003
    AddConfigBtn.Parent = ConfigInputFrame
    Instance.new("UICorner", AddConfigBtn).CornerRadius = UDim.new(0, 4)

    local PresetsScroll = Instance.new("ScrollingFrame")
    PresetsScroll.Size = UDim2.new(1, -16, 1, -76)
    PresetsScroll.Position = UDim2.new(0, 8, 0, 70)
    PresetsScroll.BackgroundTransparency = 1
    PresetsScroll.BorderSizePixel = 0
    PresetsScroll.ScrollBarThickness = 2
    PresetsScroll.ScrollBarImageColor3 = Colors.Accent
    PresetsScroll.ZIndex = 6002
    PresetsScroll.Parent = PresetsModal

    local PresetsLayout = Instance.new("UIListLayout")
    PresetsLayout.Padding = UDim.new(0, 4)
    PresetsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PresetsLayout.Parent = PresetsScroll

    local function RefreshPresetsList()
        for _, c in pairs(PresetsScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end

        local configs = RaxorHub:GetConfigList()
        PresetsScroll.CanvasSize = UDim2.new(0, 0, 0, #configs * 34)

        if #configs == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, 0, 0, 40)
            emptyLabel.Text = "No saved configs"
            emptyLabel.Font = Fonts.Regular
            emptyLabel.TextSize = 12
            emptyLabel.TextColor3 = Colors.MutedText
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.ZIndex = 6003
            emptyLabel.Parent = PresetsScroll
            return
        end

        for _, cfgName in ipairs(configs) do
            local itemRow = Instance.new("Frame")
            itemRow.Size = UDim2.new(1, -4, 0, 30)
            itemRow.BackgroundColor3 = Colors.CardBg
            itemRow.ZIndex = 6003
            itemRow.Parent = PresetsScroll
            Instance.new("UICorner", itemRow).CornerRadius = UDim.new(0, 5)
            AddStroke(itemRow, Colors.Border, 1)

            local itemLabel = Instance.new("TextLabel")
            itemLabel.Text = cfgName
            itemLabel.Font = Fonts.Medium
            itemLabel.TextSize = 12
            itemLabel.TextColor3 = Colors.Text
            itemLabel.Position = UDim2.new(0, 8, 0, 0)
            itemLabel.Size = UDim2.new(1, -68, 1, 0)
            itemLabel.TextXAlignment = Enum.TextXAlignment.Left
            itemLabel.TextTruncate = Enum.TextTruncate.AtEnd
            itemLabel.BackgroundTransparency = 1
            itemLabel.ZIndex = 6004
            itemLabel.Parent = itemRow

            local loadBtn = Instance.new("TextButton")
            loadBtn.Size = UDim2.new(0, 38, 0, 20)
            loadBtn.Position = UDim2.new(1, -60, 0.5, -10)
            loadBtn.BackgroundColor3 = Colors.Accent
            loadBtn.Text = "Load"
            loadBtn.Font = Fonts.Title
            loadBtn.TextSize = 11
            loadBtn.TextColor3 = Colors.White
            loadBtn.ZIndex = 6004
            loadBtn.Parent = itemRow
            Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 4)

            loadBtn.MouseButton1Click:Connect(function()
                RaxorHub:LoadConfigData(cfgName)
            end)

            local delBtn = Instance.new("ImageButton")
            delBtn.Size = UDim2.new(0, 18, 0, 18)
            delBtn.Position = UDim2.new(1, -20, 0.5, -9)
            delBtn.BackgroundTransparency = 1
            delBtn.Image = Icons.Trash
            delBtn.ImageColor3 = Colors.SubText
            delBtn.ZIndex = 6004
            delBtn.Parent = itemRow

            delBtn.MouseEnter:Connect(function() delBtn.ImageColor3 = Colors.CloseRed end)
            delBtn.MouseLeave:Connect(function() delBtn.ImageColor3 = Colors.SubText end)
            delBtn.MouseButton1Click:Connect(function()
                RaxorHub:DeleteConfig(cfgName)
                RefreshPresetsList()
            end)
        end
    end

    AddConfigBtn.MouseButton1Click:Connect(function()
        local name = ConfigNameInput.Text
        if name and name ~= "" then
            RaxorHub:SaveCurrentConfig(name)
            ConfigNameInput.Text = ""
            RefreshPresetsList()
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
        BreadcrumbRow.Size = UDim2.new(1, -4, 0, 22)
        BreadcrumbRow.BackgroundTransparency = 1
        BreadcrumbRow.LayoutOrder = -100
        BreadcrumbRow.ZIndex = 27
        BreadcrumbRow.Parent = Page

        local BreadcrumbLabel = Instance.new("TextLabel")
        BreadcrumbLabel.Size = UDim2.new(1, 0, 1, 0)
        BreadcrumbLabel.Text = TabConfig.Name
        BreadcrumbLabel.Font = Fonts.Title
        BreadcrumbLabel.TextSize = 14
        BreadcrumbLabel.TextColor3 = Colors.SubText
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

            -- Header Container
            local HeaderContainer = Instance.new("Frame")
            HeaderContainer.Size = SizeItem.TitleItem
            HeaderContainer.BackgroundColor3 = Colors.SectionHeaderBg
            HeaderContainer.BorderSizePixel = 0
            HeaderContainer.ZIndex = 28
            HeaderContainer.Parent = SectionFrame
            Instance.new("UICorner", HeaderContainer).CornerRadius = UDim.new(0, 6)
            AddStroke(HeaderContainer, Colors.Border, 1)

            if IconID then
                local SecIcon = Instance.new("ImageLabel")
                SecIcon.Size = UDim2.new(0, 16, 0, 16)
                SecIcon.Position = UDim2.new(0, 12, 0.5, -8)
                SecIcon.Image = ResolveIcon(IconID)
                SecIcon.BackgroundTransparency = 1
                SecIcon.ImageColor3 = Colors.Accent
                SecIcon.ZIndex = 29
                SecIcon.Parent = HeaderContainer
            end

            local hasDesc = Description and Description ~= ""
            local xPos = IconID and 34 or 12

            local HeaderTitle = Instance.new("TextLabel")
            HeaderTitle.Size = UDim2.new(1, -45, 0, 18)
            HeaderTitle.Position = hasDesc and UDim2.new(0, xPos, 0, 4) or UDim2.new(0, xPos, 0.5, -9)
            HeaderTitle.Text = Title
            HeaderTitle.Font = Fonts.Title
            HeaderTitle.TextSize = 13
            HeaderTitle.TextColor3 = Colors.Text
            HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
            HeaderTitle.BackgroundTransparency = 1
            HeaderTitle.ZIndex = 29
            HeaderTitle.Parent = HeaderContainer

            if hasDesc then
                local Desc = Instance.new("TextLabel")
                Desc.Size = UDim2.new(1, -45, 0, 16)
                Desc.Position = UDim2.new(0, xPos, 0, 20)
                Desc.Text = Description
                Desc.Font = Fonts.Regular
                Desc.TextSize = 11
                Desc.TextColor3 = Colors.SubText
                Desc.TextXAlignment = Enum.TextXAlignment.Left
                Desc.BackgroundTransparency = 1
                Desc.ZIndex = 29
                Desc.Parent = HeaderContainer
            end

            SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SectionFrame.Size = UDim2.new(1, 0, 0, SectionLayout.AbsoluteContentSize.Y + 4)
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
                    TDesc.Size = UDim2.new(1, -rightSpace, 0, 20)
                    TDesc.Position = UDim2.new(0, 14, 0, 28)
                    TDesc.Font = Fonts.Regular
                    TDesc.TextSize = 12
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
                List.ZIndex = 7000
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
                SearchBox.ZIndex = 7001
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
                ItemScroll.ZIndex = 7001
                ItemScroll.Parent = List

                local ItemListLayout = Instance.new("UIListLayout", ItemScroll)
                ItemListLayout.Padding = UDim.new(0, 2)

                local syncConnection
                local currentlySelected = Config.Default or nil
                UpdateState(Config.ID, currentlySelected)

                local function UpdateListPosition()
                    if List.Visible then
                        local absPos = Frame.AbsolutePosition
                        local mainAbsPos = MainFrame.AbsolutePosition
                        local contentHeight = ItemListLayout.AbsoluteContentSize.Y
                        ItemScroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 4)
                        local dynamicHeight = math.clamp(contentHeight + 42, 70, 180)
                        List.Size = UDim2.new(0, Frame.AbsoluteSize.X, 0, dynamicHeight)
                        List.Position = UDim2.new(0, absPos.X - mainAbsPos.X, 0, absPos.Y - mainAbsPos.Y + Frame.AbsoluteSize.Y + 3)
                    end
                end

                local function Populate(filter)
                    for _, child in pairs(ItemScroll:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, item in pairs(Config.Options or {}) do
                        if filter == "" or string.find(string.lower(tostring(item)), string.lower(tostring(filter))) then
                            local isSelected = (item == currentlySelected)
                            local itemBtn = Instance.new("TextButton")
                            itemBtn.Size = UDim2.new(1, -4, 0, 26)
                            itemBtn.BorderSizePixel = 0
                            itemBtn.AutoButtonColor = false
                            itemBtn.Text = "  " .. tostring(item)
                            itemBtn.Font = isSelected and Fonts.Title or Fonts.Medium
                            itemBtn.TextSize = 12
                            itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                            itemBtn.ZIndex = 7002
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
                end

                SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    Populate(SearchBox.Text)
                    UpdateListPosition()
                end)

                local dropdownFunc = {}
                function dropdownFunc:Refresh(newList)
                    Config.Options = newList
                    Populate("")
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
                        if syncConnection then syncConnection:Disconnect() end
                    else
                        CloseAllDropdowns()
                        List.Visible = true
                        activeDropdownList = List
                        activeDropdownArrow = ArrowIcon
                        Tween(ArrowIcon, TweenInfo.new(0.15), {Rotation = 180})
                        ItemScroll.CanvasPosition = Vector2.new(0, 0)
                        SearchBox.Text = ""
                        Populate("")
                        UpdateListPosition()
                        if syncConnection then syncConnection:Disconnect() end
                        syncConnection = RunService.RenderStepped:Connect(UpdateListPosition)
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
                List.ZIndex = 7000
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
                SearchBox.ZIndex = 7001
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
                ItemScroll.ZIndex = 7001
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
                        local absPos = Frame.AbsolutePosition
                        local mainAbsPos = MainFrame.AbsolutePosition
                        local contentHeight = ListLayout.AbsoluteContentSize.Y
                        ItemScroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 4)
                        local dynamicHeight = math.clamp(contentHeight + 42, 70, 180)
                        List.Size = UDim2.new(0, Frame.AbsoluteSize.X, 0, dynamicHeight)
                        List.Position = UDim2.new(0, absPos.X - mainAbsPos.X, 0, absPos.Y - mainAbsPos.Y + Frame.AbsoluteSize.Y + 3)
                    end
                end

                local function Populate(filter)
                    for _, child in pairs(ItemScroll:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, item in pairs(Config.Options or {}) do
                        if filter == "" or string.find(string.lower(tostring(item)), string.lower(tostring(filter))) then
                            local isSelected = (type(selectedItems) == "table" and table.find(selectedItems, item))
                            local itemBtn = Instance.new("TextButton")
                            itemBtn.Size = UDim2.new(1, -4, 0, 26)
                            itemBtn.BorderSizePixel = 0
                            itemBtn.AutoButtonColor = false
                            itemBtn.Text = ""
                            itemBtn.ZIndex = 7002
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
                            checkIcon.ZIndex = 7003
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
                            tText.ZIndex = 7003
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
                end

                SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    Populate(SearchBox.Text)
                    UpdateListPosition()
                end)

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
                        if syncConnection then syncConnection:Disconnect() end
                    else
                        CloseAllDropdowns()
                        List.Visible = true
                        activeDropdownList = List
                        activeDropdownArrow = ArrowIcon
                        Tween(ArrowIcon, TweenInfo.new(0.15), {Rotation = 180})
                        ItemScroll.CanvasPosition = Vector2.new(0, 0)
                        SearchBox.Text = ""
                        Populate("")
                        UpdateListPosition()
                        if syncConnection then syncConnection:Disconnect() end
                        syncConnection = RunService.RenderStepped:Connect(UpdateListPosition)
                    end
                end)
            end

            -- [[ Color Picker Control (Blade Modern HSV Color Picker Image 9) ]]
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
                PickerModal.Size = UDim2.new(0, 180, 0, 200)
                PickerModal.BackgroundColor3 = Colors.ModalBg
                PickerModal.Visible = false
                PickerModal.ZIndex = 7500
                PickerModal.ClipsDescendants = true
                PickerModal.Parent = MainFrame
                Instance.new("UICorner", PickerModal).CornerRadius = UDim.new(0, 8)
                AddStroke(PickerModal, Colors.BorderFocus, 1)

                local PickerTitle = Instance.new("TextLabel")
                PickerTitle.Text = Config.Title or "Color Picker"
                PickerTitle.Font = Fonts.Title
                PickerTitle.TextSize = 12
                PickerTitle.TextColor3 = Colors.Text
                PickerTitle.Size = UDim2.new(1, -16, 0, 22)
                PickerTitle.Position = UDim2.new(0, 8, 0, 4)
                PickerTitle.TextXAlignment = Enum.TextXAlignment.Left
                PickerTitle.BackgroundTransparency = 1
                PickerTitle.ZIndex = 7501
                PickerTitle.Parent = PickerModal

                local PaletteRow = Instance.new("Frame")
                PaletteRow.Size = UDim2.new(1, -16, 0, 24)
                PaletteRow.Position = UDim2.new(0, 8, 1, -30)
                PaletteRow.BackgroundTransparency = 1
                PaletteRow.ZIndex = 7501
                PaletteRow.Parent = PickerModal

                local PaletteLayout = Instance.new("UIListLayout", PaletteRow)
                PaletteLayout.FillDirection = Enum.FillDirection.Horizontal
                PaletteLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                PaletteLayout.Padding = UDim.new(0, 6)

                local presets = {
                    Color3.fromRGB(124, 92, 252), -- Blade Purple
                    Color3.fromRGB(80, 150, 255), -- Sky Blue
                    Color3.fromRGB(60, 220, 140), -- Green
                    Color3.fromRGB(255, 190, 40),  -- Amber
                    Color3.fromRGB(245, 70, 80),   -- Red
                    Color3.fromRGB(255, 100, 200)  -- Pink
                }

                for _, pColor in ipairs(presets) do
                    local dot = Instance.new("TextButton")
                    dot.Size = UDim2.new(0, 18, 0, 18)
                    dot.BackgroundColor3 = pColor
                    dot.Text = ""
                    dot.ZIndex = 7502
                    dot.Parent = PaletteRow
                    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
                    AddStroke(dot, Colors.Border, 1)

                    dot.MouseButton1Click:Connect(function()
                        currentColor = pColor
                        ColorBox.BackgroundColor3 = currentColor
                        UpdateState(Config.ID, currentColor)
                        if Config.Callback then Config.Callback(currentColor) end
                    end)
                end

                local HexLabel = Instance.new("TextLabel")
                HexLabel.Size = UDim2.new(1, -16, 0, 20)
                HexLabel.Position = UDim2.new(0, 8, 0, 136)
                HexLabel.Text = "#" .. currentColor:ToHex()
                HexLabel.Font = Fonts.Code
                HexLabel.TextSize = 11
                HexLabel.TextColor3 = Colors.SubText
                HexLabel.BackgroundTransparency = 1
                HexLabel.ZIndex = 7501
                HexLabel.Parent = PickerModal

                ColorBox.MouseButton1Click:Connect(function()
                    if PickerModal.Visible then
                        PickerModal.Visible = false
                        activeColorPicker = nil
                    else
                        CloseAllDropdowns()
                        PickerModal.Visible = true
                        activeColorPicker = PickerModal
                        local absPos = ColorBox.AbsolutePosition
                        local mainAbsPos = MainFrame.AbsolutePosition
                        PickerModal.Position = UDim2.new(0, absPos.X - mainAbsPos.X - 140, 0, absPos.Y - mainAbsPos.Y + 26)
                    end
                end)

                if Config.ID and RaxorHub.Objects then
                    RaxorHub.Objects[Config.ID] = {
                        Type = "ColorPicker",
                        Default = Config.Default,
                        Update = function(val)
                            currentColor = val
                            ColorBox.BackgroundColor3 = currentColor
                            HexLabel.Text = "#" .. currentColor:ToHex()
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
                TextBox.FocusLost:Connect(function(enterPressed)
                    stroke.Color = Colors.BorderFocus
                    local currentText = TextBox.Text
                    if Config.ID then UpdateState(Config.ID, currentText) end
                    if Config.Callback then Config.Callback(currentText, enterPressed) end
                end)

                return Row
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

            -- [[ Label / Divider Banner ]]
            function sectionItems:AddLabel(Title)
                local Row = Instance.new("Frame")
                Row.Size = UDim2.new(1, -4, 0, 36)
                Row.BackgroundColor3 = Colors.SectionHeaderBg
                Row.BorderSizePixel = 0
                Row.ZIndex = 28
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                local Accent = Instance.new("Frame")
                Accent.Size = UDim2.new(0, 3, 1, -12)
                Accent.Position = UDim2.new(0, 6, 0.5, 0)
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
                TTitle.Font = Fonts.Title
                TTitle.TextSize = 13
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

    return window
end

return RaxorHub
