--!nocheck
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local InstNew = Instance.new
local C3_RGB = Color3.fromRGB
local U2 = UDim2.new
local AutoY = Enum.AutomaticSize.Y
local V2 = Vector2.new
local InpMB1 = Enum.UserInputType.MouseButton1
local InpTouch = Enum.UserInputType.Touch
local SO_Layout = Enum.SortOrder.LayoutOrder
local FD_H = Enum.FillDirection.Horizontal
local HA_Center = Enum.HorizontalAlignment.Center
local VA_Center = Enum.VerticalAlignment.Center
local TruncEnd = Enum.TextTruncate.AtEnd
local NS_new = NumberSequence.new
local NSK_new = NumberSequenceKeypoint.new

local UI_NAME = "RaxorHub_UI"
local UI_TITLE = "RAXOR"
local UI_CREDIT = "By : Pigalo"
local UI_VERSION = "v2.1.6"

local CoreGuiSuccess, CoreGui = pcall(function() return game:GetService("CoreGui") end)

local function DestroyAllOldUIs()
  local containers = {}
  if gethui then
  local ok, hui = pcall(gethui)
  if ok and hui then table.insert(containers, hui) end
  end
  if CoreGuiSuccess and CoreGui then table.insert(containers, CoreGui) end
  if PlayerGui then table.insert(containers, PlayerGui) end

  for _, c in ipairs(containers) do
  for _, n in ipairs({UI_NAME, "RaxorHub_UI", "RaxorHub"}) do
  local okOld, old = pcall(function() return c:FindFirstChild(n) end); old = okOld and old or nil
  if old then
  warn("[RaxorHub] Cleaning up existing instance: " .. n)
  pcall(function() old:Destroy() end)
  end
  end
  end
end

local RaxorHub
local BaseCfgDir = "RaxorHub_Configs"
local ConfigFolder, AutoloadFile
local function EnsureCfgDir()
  if isfolder and makefolder then
  pcall(function()
  if not isfolder(BaseCfgDir) then makefolder(BaseCfgDir) end
  if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
  end)
  end
end
local function SetCfgScope(scope)
  local s = scope and tostring(scope):gsub("[^%w_%-]", "") or ""
  if s == "" then
  local gid = (game.GameId and game.GameId ~= 0) and game.GameId or game.PlaceId
  s = tostring((gid and gid ~= 0) and gid or "Studio")
  end
  ConfigFolder = BaseCfgDir .. "/" .. s
  AutoloadFile = ConfigFolder .. "/autoload.txt"
  if RaxorHub then RaxorHub.ConfigFolder = ConfigFolder end
  EnsureCfgDir()
end
SetCfgScope()

local MemoryFiles = {}
local function SafeWriteFile(path, content)
  if writefile then
  pcall(function()
  EnsureCfgDir()
  writefile(path, content)
  end)
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
  if path:sub(1, #folder + 1) == folder .. "/" then
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

RaxorHub = {
  Elements = {},
  ConfigData = {},
  Objects = {},
  ConfigFolder = ConfigFolder,
  ActiveTab = nil,
  Notifications = {},
  Version = UI_VERSION
}

local activeDropdownList = nil
local activeDropdownArrow = nil
local activeDropdownFrame = nil
local activeDropdownSync = nil
local activeColorPicker = nil
local MainFrame = nil
local StartBtn = nil
local PresetsModal = nil
local IsBinding = false

local Colors = {
  WindowBg        = C3_RGB(12, 13, 19),
  MainCardBg      = C3_RGB(17, 18, 27),
  SidebarBg       = C3_RGB(15, 16, 24),
  TopBarBg        = C3_RGB(15, 16, 24),
  SectionHeaderBg = C3_RGB(20, 22, 33),
  CardBg          = C3_RGB(20, 22, 32),
  CardHover       = C3_RGB(26, 29, 43),
  CardActive      = C3_RGB(32, 36, 54),
  InputBg         = C3_RGB(16, 17, 26),
  DropdownBg      = C3_RGB(19, 21, 31),
  ModalBg         = C3_RGB(17, 19, 29),

  Accent          = C3_RGB(139, 92, 246),
  AccentHover     = C3_RGB(168, 85, 247),
  AccentMuted     = C3_RGB(88, 62, 150),
  AccentGlow      = C3_RGB(192, 132, 252),
  AccentCyan      = C3_RGB(56, 189, 248),

  Text            = C3_RGB(248, 250, 252),
  SubText         = C3_RGB(156, 163, 175),
  MutedText       = C3_RGB(100, 116, 139),

  Border          = C3_RGB(35, 38, 56),
  BorderFocus     = C3_RGB(65, 72, 102),
  BorderActive    = C3_RGB(139, 92, 246),
  BorderHover     = C3_RGB(55, 60, 88),

  CloseRed        = C3_RGB(239, 68, 68),
  CloseRedHover   = C3_RGB(248, 113, 113),
  ControlBtn      = C3_RGB(24, 26, 38),

  SwitchOn        = C3_RGB(139, 92, 246),
  SwitchOff       = C3_RGB(42, 46, 66),

  ButtonBg        = C3_RGB(28, 30, 44),
  ButtonHover     = C3_RGB(38, 42, 62),
  ButtonPress     = C3_RGB(22, 24, 35),

  White           = C3_RGB(255, 255, 255),
  Black           = C3_RGB(0, 0, 0),
}

local TXA_LEFT = Enum.TextXAlignment.Left
local Fonts = {
  Title       = Enum.Font.GothamBold,
  Medium      = Enum.Font.GothamMedium,
  Regular     = Enum.Font.Gotham,
  Brand       = Enum.Font.GothamBold,
  Code        = Enum.Font.Code
}

local I18nRegistry = _G.RaxorHub_I18nRegistry or {}
_G.RaxorHub_I18nRegistry = I18nRegistry
RaxorHub.I18nRegistry = I18nRegistry
local CurrentLanguage = _G.RaxorHub_CurrentLanguage or "EN"
_G.RaxorHub_CurrentLanguage = CurrentLanguage
RaxorHub.Language = CurrentLanguage

local TranslationDict = {
  ["Dashboard"] = { TH = "แผงควบคุม", EN = "Dashboard" },
  ["Settings"] = { TH = "ตั้งค่า", EN = "Settings" },
  ["Combat"] = { TH = "ระบบต่อสู้", EN = "Combat" },

  ["SYSTEM INFO"] = { TH = "ข้อมูลระบบ (SYSTEM INFO)", EN = "SYSTEM INFO" },
  ["SERVER MANAGEMENT"] = { TH = "จัดการเซิร์ฟเวอร์", EN = "SERVER MANAGEMENT" },
  ["FPS"] = { TH = "เฟรมเรต (FPS)", EN = "FPS" },
  ["Ping"] = { TH = "ปิง (Ping)", EN = "Ping" },
  ["Server Uptime"] = { TH = "เวลาเปิดเซิร์ฟ", EN = "Server Uptime" },
  ["Time of day"] = { TH = "เวลาในเกม", EN = "Time of day" },
  ["Players"] = { TH = "ผู้เล่นในเซิร์ฟ", EN = "Players" },
  ["Place ID"] = { TH = "ไอดีแมพ (Place ID)", EN = "Place ID" },
  ["Job ID"] = { TH = "ไอดีเซิร์ฟ (Job ID)", EN = "Job ID" },
  ["Status"] = { TH = "สถานะสคริปต์", EN = "Status" },
  ["Active (Ready)"] = { TH = "พร้อมทำงาน (Active)", EN = "Active (Ready)" },

  ["Copy Server JobID"] = { TH = "คัดลอก Job ID", EN = "Copy Server JobID" },
  ["Rejoin"] = { TH = "เชื่อมต่อใหม่", EN = "Rejoin" },
  ["Server Hop"] = { TH = "ย้ายเซิร์ฟเวอร์", EN = "Server Hop" },
  ["Server Hop (lowest)"] = { TH = "ย้ายเซิร์ฟ (คนน้อยสุด)", EN = "Server Hop (lowest)" },
  ["Copied"] = { TH = "คัดลอกสำเร็จ", EN = "Copied" },
  ["Rejoining"] = { TH = "กำลังเชื่อมต่อใหม่", EN = "Rejoining" },

  ["Menu & Keybinds"] = { TH = "เมนูและปุ่มลัด", EN = "Menu & Keybinds" },
  ["การตั้งค่าปุ่มและหน้าต่าง"] = { TH = "การตั้งค่าปุ่มและหน้าต่าง", EN = "Window toggle & shortcut configuration" },
  ["Toggle UI Keybind"] = { TH = "ปุ่มพับ UI", EN = "Toggle UI Keybind" },
  ["ปุ่มสำหรับพับหรือเปิดหน้าต่าง UI"] = { TH = "ปุ่มสำหรับพับหรือเปิดหน้าต่าง UI", EN = "Shortcut key to hide/show UI" },
  ["Theme Accent Color"] = { TH = "สีธีมหลัก UI", EN = "Theme Accent Color" },
  ["เปลี่ยนสีธีมหลักของ UI"] = { TH = "เปลี่ยนสีธีมหลักของ UI", EN = "Change main UI accent color" },
  ["Theme Wallpaper"] = { TH = "ภาพพื้นหลัง UI", EN = "Theme Wallpaper" },
  ["เปลี่ยนภาพพื้นหลังของ UI"] = { TH = "เปลี่ยนภาพพื้นหลังของ UI", EN = "Change UI background wallpaper" },
  ["Default"] = { TH = "ค่าเริ่มต้น (Obsidian)", EN = "Default" },
  ["Halloween"] = { TH = "ฮาโลวีน (Halloween)", EN = "Halloween" },
  ["Galaxy"] = { TH = "กาแล็กซี (Galaxy)", EN = "Galaxy" },
  ["Reset Config to Default"] = { TH = "รีเซ็ตการตั้งค่าเป็นค่าเริ่มต้น", EN = "Reset Config to Default" },
  ["คืนค่าการตั้งค่าทั้งหมดกลับเป็นค่าเริ่มต้น"] = { TH = "คืนค่าการตั้งค่าทั้งหมดกลับเป็นค่าเริ่มต้น", EN = "Restore all configurations to default" },
  ["Reset"] = { TH = "รีเซ็ต", EN = "Reset" },
  ["Settings Reset"] = { TH = "รีเซ็ตสำเร็จ", EN = "Settings Reset" },
  ["คืนค่าการตั้งค่าทั้งหมดเรียบร้อยแล้ว!"] = { TH = "คืนค่าการตั้งค่าทั้งหมดเรียบร้อยแล้ว!", EN = "All configurations have been reset to default!" },

  ["Search element..."] = { TH = "ค้นหาเมนู...", EN = "Search element..." },
  ["Presets Configuration"] = { TH = "จัดการพรีเซ็ต", EN = "Presets Configuration" },
  ["Hide Tabs"] = { TH = "ซ่อนแท็บ", EN = "Hide Tabs" },
  ["Show Tabs"] = { TH = "แสดงแท็บ", EN = "Show Tabs" },
  ["Minimize Window"] = { TH = "ย่อหน้าต่าง", EN = "Minimize Window" },
  ["Center Window"] = { TH = "จัดกึ่งกลาง", EN = "Center Window" },
  ["Close RaxorHub"] = { TH = "ปิด RaxorHub", EN = "Close RaxorHub" },
  ["Dev Mode"] = { TH = "โหมดนักพัฒนา", EN = "Dev Mode" }
}

function RaxorHub:AddTranslations(dict)
  if typeof(dict) == "table" then
    for k, v in pairs(dict) do
      TranslationDict[k] = v
    end
  end
end
RaxorHub.TranslationDict = TranslationDict

local function ResolveText(textOrDict, lang)
  if type(textOrDict) == "table" then
  return textOrDict[lang] or textOrDict["EN"] or textOrDict["TH"] or ""
  elseif type(textOrDict) == "string" then
  local entry = TranslationDict[textOrDict]
  if entry and entry[lang] then
  return entry[lang]
  end
  return textOrDict
  end
  return tostring(textOrDict or "")
end

local function IsThaiText(s)
  if not s or type(s) ~= "string" or s == "" then return false end
  return string.find(s, "\224\184") ~= nil or string.find(s, "\224\185") ~= nil
end

local function GetScaledTextSize(baseSize, lang)
  if not baseSize then return nil end
  if lang == "TH" then
    if baseSize <= 12 then
      return baseSize + 3
    elseif baseSize <= 14 then
      return baseSize + 3
    else
      return baseSize + 2
    end
  else
    if baseSize <= 11 then
      return baseSize + 1
    elseif baseSize <= 13 then
      return baseSize + 1
    else
      return baseSize
    end
  end
end

local function RegisterI18n(instance, property, textOrDict, customDelta)
  if not instance then return end
  local baseSize = nil
  local baseFont = nil
  local baseColor = nil
  pcall(function()
  baseSize = instance.TextSize
  baseFont = instance.Font
  baseColor = instance.TextColor3
  end)
  table.insert(I18nRegistry, {
  Instance = instance,
  Property = property,
  Source = textOrDict,
  BaseSize = baseSize,
  BaseFont = baseFont,
  BaseColor = baseColor,
  CustomDelta = customDelta
  })
  pcall(function()
  local resolved = ResolveText(textOrDict, CurrentLanguage)
  instance[property] = resolved
  if baseSize and instance.TextSize then
    local isTH = CurrentLanguage == "TH" or IsThaiText(resolved)
    local targetSize = customDelta and (baseSize + customDelta) or GetScaledTextSize(baseSize, isTH and "TH" or "EN")
    instance.TextSize = math.round(targetSize)
    if isTH then
      instance.Font = Fonts.Title -- Bold for Thai!
      if baseColor and (baseColor == Colors.SubText or baseColor == Colors.MutedText) then
        instance.TextColor3 = C3_RGB(209, 213, 219)
      end
    else
      instance.Font = baseFont or Fonts.Title
      if baseColor then
        instance.TextColor3 = baseColor
      end
    end
  end
  end)
end

local LanguageCallbacks = {}
function RaxorHub:RegisterLanguageCallback(fn)
  table.insert(LanguageCallbacks, fn)
end

function RaxorHub:SetLanguage(newLang)
  if newLang ~= "TH" and newLang ~= "EN" then return end
  CurrentLanguage = newLang
  _G.RaxorHub_CurrentLanguage = newLang
  RaxorHub.Language = newLang

  for i = #I18nRegistry, 1, -1 do
  local item = I18nRegistry[i]
  if item.Instance and item.Instance.Parent then
  pcall(function()
  local resolved = ResolveText(item.Source, newLang)
  item.Instance[item.Property] = resolved
  if item.BaseSize and item.Instance.TextSize then
    local isTH = newLang == "TH" or IsThaiText(resolved)
    local targetSize = item.CustomDelta and (item.BaseSize + item.CustomDelta) or GetScaledTextSize(item.BaseSize, isTH and "TH" or "EN")
    item.Instance.TextSize = math.round(targetSize)
    if isTH then
      item.Instance.Font = Fonts.Title -- Bold for Thai!
      if item.BaseColor and (item.BaseColor == Colors.SubText or item.BaseColor == Colors.MutedText) then
        item.Instance.TextColor3 = C3_RGB(209, 213, 219)
      end
    else
      item.Instance.Font = item.BaseFont or Fonts.Title
      if item.BaseColor then
        item.Instance.TextColor3 = item.BaseColor
      end
    end
  end
  end)
  else
  table.remove(I18nRegistry, i)
  end
  end

  local Players = game:GetService("Players")
  local lp = Players.LocalPlayer
  if lp and lp:FindFirstChild("PlayerGui") then
  for _, gui in pairs(lp.PlayerGui:GetChildren()) do
  if gui.Name == UI_NAME or gui.Name == "RaxorHub_UI" then
  local mf = gui:FindFirstChild("MainFrame")
  local tb = mf and mf:FindFirstChild("TopBar")
  local tbc = tb and tb:FindFirstChild("TopBreadcrumb")
  if tbc and RaxorHub.ActiveTabName then
    pcall(function()
    local resolved = ResolveText(RaxorHub.ActiveTabName, newLang)
    tbc.Text = "| " .. resolved
    tbc.TextSize = (newLang == "TH" or IsThaiText(resolved)) and 17 or 15
    tbc.Font = Fonts.Title
    end)
  end
  end
  end
  end

  for _, fn in ipairs(LanguageCallbacks) do
    pcall(fn, newLang)
  end

  if RaxorHub.OnLanguageChanged then
  pcall(RaxorHub.OnLanguageChanged, newLang)
  end
end

local Icons = {
  Logo        = "rbxassetid://87425048247573",
  Combat      = "rbxassetid://87875752333553",
  Movement    = "rbxassetid://89131492438764",
  Visuals     = "rbxassetid://82702843090557",
  Render      = "rbxassetid://86889350439772",
  Settings    = "rbxassetid://90986900245399",
  Misc        = "rbxassetid://90986900245399",
  Shop        = "rbxassetid://101897612481528", -- 6: Cart
  AutoBuy     = "rbxassetid://101897612481528", -- 6: Cart (Alias)
  Crown       = "rbxassetid://84838733609171",
  Owner       = "rbxassetid://84838733609171",
  Save        = "rbxassetid://107508674342176", -- 8: Floppy Disk
  Minimize    = "rbxassetid://133334866399617", -- 9: Minus Line
  Restore     = "rbxassetid://109639980556401",
  Close       = "rbxassetid://115217200764763", -- 11: Cross / Close
  Folder      = "rbxassetid://136865241981761",
  Dungeon     = "rbxassetid://88481999592471", -- 13: Dungeon
  Automation  = "rbxassetid://92268014238157", -- 14: Automation
  Home        = "rbxassetid://107021730323048",
  Dashboard   = "rbxassetid://10723346959",
  Discord     = "rbxassetid://18505728201",

  Search      = "rbxassetid://6031154871",
  ChevronDown = "rbxassetid://6034818372",
  ChevronLeft = "rbxassetid://10709790948",
  ChevronRight = "rbxassetid://10709791437",
  Checkmark   = "rbxassetid://6031094667",
  Trash       = "rbxassetid://93749431604052",
  Plus        = "rbxassetid://6031094678",
  Star        = "rbxassetid://6031068426",
  Refresh     = "rbxassetid://6031097225"
}
RaxorHub.Icons = Icons

local SizeItem = {
  BoxItem   = U2(1, -4, 0, 60),
  TitleItem = U2(1, -4, 0, 50)
}

local function AddStroke(parent, color, thickness)
  local stroke = InstNew("UIStroke")
  stroke.Color = color or Colors.Border
  stroke.Thickness = thickness or 1
  stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
  stroke.Parent = parent
  return stroke
end

local function AddCorner(parent, r)
  local c = InstNew("UICorner")
  c.CornerRadius = (r == 999) and UDim.new(1, 0) or UDim.new(0, r or 6)
  c.Parent = parent
  return c
end

local T_FAST = TweenInfo.new(0.12)
local function Tween(obj, info, props)
  if not obj or not props then return end
  local tInfo = info
  if typeof(tInfo) == "number" then
    tInfo = TweenInfo.new(tInfo)
  elseif typeof(tInfo) ~= "TweenInfo" then
    tInfo = T_FAST
  end
  local ok, t = pcall(function()
    local tw = TweenService:Create(obj, tInfo, props)
    tw:Play()
    return tw
  end)
  return ok and t or nil
end

local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local ClickSoundPool = {}
local ClickSoundIndex = 1
local CLICK_POOL_SIZE = 3

for i = 1, CLICK_POOL_SIZE do
  local s = InstNew("Sound")
  s.Name = "RaxorClick_" .. i
  s.SoundId = "rbxassetid://6895079853"
  s.Volume = 0.4
  s.Parent = SoundService
  table.insert(ClickSoundPool, s)
end

task.spawn(function()
  pcall(function()
  ContentProvider:PreloadAsync(ClickSoundPool)
  end)
end)

local function PlayClickSound(pitch)
  local s = ClickSoundPool[ClickSoundIndex]
  ClickSoundIndex = (ClickSoundIndex % CLICK_POOL_SIZE) + 1
  if s then
  s.PlaybackSpeed = pitch or 1
  s.TimePosition = 0
  s:Play()
  end
end

local Wallpapers = {
  ["Halloween"] = "rbxassetid://84734368934173",
  ["Galaxy"] = "rbxthumb://type=Asset&id=1392067539&w=768&h=432"
}

function RaxorHub:SetWallpaper(name)
  if RaxorHub.ActiveWindow and RaxorHub.ActiveWindow.SetWallpaper then
  RaxorHub.ActiveWindow.SetWallpaper(name)
  end
end

local AccentListeners = {}
local function RegisterAccent(instanceOrFunc, propertyName)
  if type(instanceOrFunc) == "function" then
  table.insert(AccentListeners, { Callback = instanceOrFunc })
  else
  table.insert(AccentListeners, { Instance = instanceOrFunc, Property = propertyName })
  end
end

function RaxorHub:SetAccentColor(newColor)
  if typeof(newColor) ~= "Color3" then return end
  Colors.Accent = newColor
  local h, s, v = newColor:ToHSV()
  Colors.AccentHover = Color3.fromHSV(h, math.clamp(s * 0.85, 0, 1), math.clamp(v * 1.15, 0, 1))
  Colors.BorderActive = newColor
  Colors.SwitchOn = newColor

  for i = #AccentListeners, 1, -1 do
  local item = AccentListeners[i]
  if item.Callback then
    pcall(item.Callback, newColor)
  elseif item.Instance and item.Instance.Parent then
    pcall(function()
      Tween(item.Instance, TweenInfo.new(0.2), {[item.Property] = newColor})
    end)
  else
    table.remove(AccentListeners, i)
  end
  end

  if self and self.OnAccentColorChanged then
  pcall(self.OnAccentColorChanged, newColor)
  elseif RaxorHub.OnAccentColorChanged then
  pcall(RaxorHub.OnAccentColorChanged, newColor)
  end
end

local function ResolveIcon(iconInput)
  if not iconInput then return Icons.Logo end
  if Icons[iconInput] then return Icons[iconInput] end
  if string.find(tostring(iconInput), "rbxassetid://") then return iconInput end
  if tonumber(iconInput) then return "rbxassetid://" .. tostring(iconInput) end
  return Icons.Logo
end

local function BindClick(btn, fn)
  local last = 0
  local function fire()
    local now = tick()
    if now - last < 0.15 then return end
    last = now
    fn()
  end
  btn.Activated:Connect(fire)
  btn.MouseButton1Click:Connect(fire)
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

UserInputService.InputBegan:Connect(function(input)
  if input.UserInputType == InpMB1 or input.UserInputType == InpTouch then
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

local ContextActionService = game:GetService("ContextActionService")

local function BlockCameraDrag()
  pcall(function()
  ContextActionService:BindActionAtPriority(
  "RaxorCameraBlock",
  function() return Enum.ContextActionResult.Sink end,
  false,
  Enum.ContextActionPriority.High.Value + 3000,
  InpTouch,
  Enum.UserInputType.MouseMovement
  )
  end)
end

local function UnblockCameraDrag()
  pcall(function()
  ContextActionService:UnbindAction("RaxorCameraBlock")
  end)
end

local function MakeDraggable(obj, dragPart)
  dragPart.Active = true
  local dragging = false
  local dragStart = nil
  local startPos = nil

  dragPart.InputBegan:Connect(function(input)
  if input.UserInputType == InpMB1 or input.UserInputType == InpTouch then
  local pg = PlayerGui or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
  if pg and input.Position then
  local pcallOk, objs = pcall(function()
    return pg:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
  end)
  if pcallOk and objs then
    for _, g in ipairs(objs) do
    if g:IsA("GuiButton") or g:IsA("TextBox") then
      return
    end
    end
  end
  end

  dragging = true
  BlockCameraDrag()
  dragStart = input.Position
  startPos = obj.Position
  input.Changed:Connect(function()
  if input.UserInputState == Enum.UserInputState.End then
    dragging = false
    UnblockCameraDrag()
  end
  end)
  end
  end)

  UserInputService.InputChanged:Connect(function(input)
  if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == InpTouch) then
  local delta = input.Position - dragStart
  if delta.Magnitude > 2 then
  obj.Position = U2(
    startPos.X.Scale,
    startPos.X.Offset + delta.X,
    startPos.Y.Scale,
    startPos.Y.Offset + delta.Y
  )
  end
  end
  end)

  UserInputService.InputEnded:Connect(function(input)
  if input.UserInputType == InpMB1 or input.UserInputType == InpTouch then
  if dragging then
  dragging = false
  UnblockCameraDrag()
  end
  end
  end)
end

local function MakeResizable(obj, dragPart, minW, minH, maxW, maxH)
  dragPart.Active = true
  local dragging = false
  local dragStart = nil
  local startSize = nil
  local startPos = nil

  minW = minW or 630
  minH = minH or 380
  maxW = maxW or 1400
  maxH = maxH or 900

  dragPart.InputBegan:Connect(function(input)
  if input.UserInputType == InpMB1 or input.UserInputType == InpTouch then
  dragging = true
  BlockCameraDrag()
  dragStart = input.Position
  startSize = obj.Size
  startPos = obj.Position

  input.Changed:Connect(function()
  if input.UserInputState == Enum.UserInputState.End then
    dragging = false
    UnblockCameraDrag()
  end
  end)
  end
  end)

  UserInputService.InputChanged:Connect(function(input)
  if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == InpTouch) then
  local delta = input.Position - dragStart

  local newWidth = math.clamp(startSize.X.Offset + delta.X, minW, maxW)
  local newHeight = math.clamp(startSize.Y.Offset + delta.Y, minH, maxH)

  local actualDeltaX = newWidth - startSize.X.Offset
  local actualDeltaY = newHeight - startSize.Y.Offset

  obj.Size = U2(0, newWidth, 0, newHeight)
  if obj.AnchorPoint == V2(0.5, 0.5) and startPos then
  obj.Position = U2(
    startPos.X.Scale,
    startPos.X.Offset + actualDeltaX / 2,
    startPos.Y.Scale,
    startPos.Y.Offset + actualDeltaY / 2
  )
  end
  end
  end)

  UserInputService.InputEnded:Connect(function(input)
  if input.UserInputType == InpMB1 or input.UserInputType == InpTouch then
  if dragging then
  dragging = false
  UnblockCameraDrag()
  end
  end
  end)
end

local wasDraggingStart = false
local lastRatioX = 0.5
local lastRatioY = 0.05

local function MakeDraggableStartBtn(obj, dragPart, clickCallback)
  local dragging = false
  local dragStart, startPos

  dragPart.InputBegan:Connect(function(input)
  if input.UserInputType == InpMB1 or input.UserInputType == InpTouch then
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
  if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == InpTouch) then
  local delta = input.Position - dragStart
  if delta.Magnitude > 6 then
  wasDraggingStart = true
  end

  local newPos = U2(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
  local parentScreen = obj:FindFirstAncestorOfClass("ScreenGui")
  if parentScreen then
  local screenSize = parentScreen.AbsoluteSize
  local currentX = newPos.X.Offset + (screenSize.X * newPos.X.Scale)
  local currentY = newPos.Y.Offset + (screenSize.Y * newPos.Y.Scale)

  local halfW = (obj.AbsoluteSize.X > 0 and obj.AbsoluteSize.X or (isMobile and 205 or 235)) * 0.5
  local btnH = (obj.AbsoluteSize.Y > 0 and obj.AbsoluteSize.Y or (isMobile and 32 or 36))

  local minX = halfW + 4
  local maxX = math.max(minX, screenSize.X - halfW - 4)
  local minY = 4
  local maxY = math.max(minY, screenSize.Y - btnH - 4)

  local finalX = math.clamp(currentX, minX, maxX)
  local finalY = math.clamp(currentY, minY, maxY)

  obj.Position = U2(0, finalX, 0, finalY)
  if screenSize.X > 56 then lastRatioX = finalX / screenSize.X end
  if screenSize.Y > 56 then lastRatioY = finalY / screenSize.Y end
  else
  obj.Position = newPos
  end
  end
  end)

  dragPart.InputEnded:Connect(function(input)
  if (input.UserInputType == InpMB1 or input.UserInputType == InpTouch) then
  if not wasDraggingStart and clickCallback then
  clickCallback()
  end
  dragging = false
  end
  end)
end

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

function RaxorHub:GetConfigList()
  local files = SafeListFiles(ConfigFolder)
  local names = {}
  for _, file in ipairs(files) do
  local cleanPath = file:gsub("\\", "/")
  local finalName = cleanPath:match("([^/]+)%.json$")
  if finalName then
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
  RaxorHub.ConfigData = {}
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
  defaultValue = (obj.Config and (obj.Config.Default or obj.Config.Min)) or 0
  elseif obj.Type == "Toggle" then
  defaultValue = (obj.Config and obj.Config.Default ~= nil and obj.Config.Default) or false
  elseif obj.Type == "Dropdown" then
  defaultValue = (obj.Config and obj.Config.Default) or ""
  elseif obj.Type == "MultiSelect" then
  defaultValue = (obj.Config and obj.Config.Default) or {}
  elseif obj.Type == "Input" then
  defaultValue = (obj.Config and obj.Config.Default) or ""
  elseif obj.Type == "ColorPicker" then
  defaultValue = (obj.Config and obj.Config.Default) or C3_RGB(139, 92, 246)
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
  local trimmed = content:match("^%s*(.-)%s*$")
  if trimmed ~= "" and trimmed ~= "None" then return trimmed end
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

local NotificationHolder = nil
function RaxorHub:Notify(config)
  if not NotificationHolder then return end
  config = config or {}
  local title = ResolveText(config.Title or "RaxorHub", CurrentLanguage)
  local content = ResolveText(config.Content or "", CurrentLanguage)
  local duration = config.Duration or 3.5

  local Toast = InstNew("Frame")
  Toast.Size = U2(1, 0, 0, 58)
  Toast.Position = U2(1, 40, 0, 0)
  Toast.BackgroundColor3 = Colors.ModalBg
  Toast.BorderSizePixel = 0
  Toast.ZIndex = 9000
  Toast.Parent = NotificationHolder
  AddCorner(Toast, 8)
  AddStroke(Toast, Colors.BorderFocus, 1)

  local AccentBar = InstNew("Frame")
  AccentBar.Size = U2(0, 3, 1, -12)
  AccentBar.Position = U2(0, 4, 0.5, 0)
  AccentBar.AnchorPoint = V2(0, 0.5)
  AccentBar.BackgroundColor3 = Colors.Accent
  AccentBar.BorderSizePixel = 0
  AccentBar.ZIndex = 9001
  AccentBar.Parent = Toast
  AddCorner(AccentBar, 999)

  local isTH = CurrentLanguage == "TH" or IsThaiText(title) or IsThaiText(content)
  local TTitle = InstNew("TextLabel")
  TTitle.Size = U2(1, -24, 0, 20)
  TTitle.Position = U2(0, 14, 0, 8)
  TTitle.Text = title
  TTitle.Font = Fonts.Title
  TTitle.TextSize = isTH and 14 or 13
  TTitle.TextColor3 = Colors.Text
  TTitle.TextXAlignment = TXA_LEFT
  TTitle.BackgroundTransparency = 1
  TTitle.ZIndex = 9001
  TTitle.Parent = Toast

  local TContent = InstNew("TextLabel")
  TContent.Size = U2(1, -24, 0, 18)
  TContent.Position = U2(0, 14, 0, 28)
  TContent.Text = content
  TContent.Font = isTH and Fonts.Title or Fonts.Regular
  TContent.TextSize = isTH and 13 or 12
  TContent.TextColor3 = Colors.SubText
  TContent.TextXAlignment = TXA_LEFT
  TContent.BackgroundTransparency = 1
  TContent.ZIndex = 9001
  TContent.Parent = Toast

  local ProgressLine = InstNew("Frame")
  ProgressLine.Size = U2(1, 0, 0, 2)
  ProgressLine.Position = U2(0, 0, 1, -2)
  ProgressLine.BackgroundColor3 = Colors.Accent
  ProgressLine.BorderSizePixel = 0
  ProgressLine.ZIndex = 9002
  ProgressLine.Parent = Toast
  AddCorner(ProgressLine, 999)

  Tween(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = U2(0, 0, 0, 0)})
  Tween(ProgressLine, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = U2(0, 0, 0, 2)})

  task.delay(duration, function()
  if Toast and Toast.Parent then
  local t = Tween(Toast, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = U2(1, 40, 0, 0)})
  if t and t.Completed then
    t.Completed:Connect(function()
      if Toast and Toast.Parent then Toast:Destroy() end
    end)
  else
    task.wait(0.3)
    if Toast and Toast.Parent then Toast:Destroy() end
  end
  end
  end)
end

function RaxorHub:Window(GuiConfig)
  GuiConfig = GuiConfig or {}
  SetCfgScope(GuiConfig.ConfigFolder or GuiConfig.GameKey)
  DestroyAllOldUIs()
  table.clear(I18nRegistry)
  local startLang = GuiConfig.Language or GuiConfig.DefaultLanguage or "EN"
  RaxorHub:SetLanguage(startLang)
  if type(GuiConfig.Title) == "table" then
    GuiConfig.Title = GuiConfig.Title[startLang] or GuiConfig.Title["EN"] or GuiConfig.Title["TH"] or "RAXOR"
  end
  GuiConfig.Title = tostring(GuiConfig.Title or "RAXOR")
  local window = {Tabs = {}, CountTab = 0, TabButtons = {}}
  local ToggleUI = nil

  local ScreenGui = InstNew("ScreenGui")
  ScreenGui.Name = UI_NAME
  ScreenGui.IgnoreGuiInset = true
  ScreenGui.ResetOnSpawn = false
  ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  ScreenGui.DisplayOrder = 9999

  if RunService:IsStudio() then
  ScreenGui.Parent = PlayerGui
  elseif syn and syn.protect_gui then
  syn.protect_gui(ScreenGui)
  ScreenGui.Parent = CoreGui
  elseif gethui then
  local okHui, hui = pcall(gethui)
  if okHui and hui then
  ScreenGui.Parent = hui
  else
  ScreenGui.Parent = PlayerGui
  end
  elseif CoreGuiSuccess and CoreGui then
  local ok = pcall(function() ScreenGui.Parent = CoreGui end)
  if not ok then ScreenGui.Parent = PlayerGui end
  else
  ScreenGui.Parent = PlayerGui
  end

  local SetLanguageEvent = InstNew("BindableEvent")
  SetLanguageEvent.Name = "SetLanguageEvent"
  SetLanguageEvent.Parent = ScreenGui
  SetLanguageEvent.Event:Connect(function(lang)
  RaxorHub:SetLanguage(lang)
  end)

  local TooltipFrame = InstNew("Frame")
  TooltipFrame.Name = "RaxorTooltip"
  TooltipFrame.Size = U2(0, 100, 0, 26)
  TooltipFrame.BackgroundColor3 = C3_RGB(24, 25, 34)
  TooltipFrame.BorderSizePixel = 0
  TooltipFrame.Visible = false
  TooltipFrame.ZIndex = 99999
  TooltipFrame.Parent = ScreenGui
  AddCorner(TooltipFrame, 6)
  AddStroke(TooltipFrame, Colors.Accent, 1)

  local TooltipLabel = InstNew("TextLabel")
  TooltipLabel.Name = "Text"
  TooltipLabel.Size = U2(1, -16, 1, 0)
  TooltipLabel.Position = U2(0, 8, 0, 0)
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
  local sz = TextService:GetTextSize(text, 11, Fonts.Medium, V2(500, 50))
  TooltipFrame.Size = U2(0, sz.X + 18, 0, 26)
  local function updatePos()
  local mousePos = UserInputService:GetMouseLocation()
  local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or V2(1280, 720)
  local tw = TooltipFrame.AbsoluteSize.X
  local posX = mousePos.X + 14
  if posX + tw > vp.X - 8 then
  posX = mousePos.X - tw - 14
  end
  local posY = mousePos.Y - 30
  if posY < 8 then
  posY = mousePos.Y + 22
  end
  TooltipFrame.Position = U2(0, posX, 0, posY)
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

  local function GetScreenSize()
  local cam = workspace.CurrentCamera
  local sz = cam and cam.ViewportSize
  if not sz or sz.X < 50 then
  sz = ScreenGui and ScreenGui.AbsoluteSize
  end
  if not sz or sz.X < 50 then
  sz = V2(1280, 720)
  end
  return sz
  end

  local function DetectIsMobile(sz)
  if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
  return true
  end
  if sz and (sz.Y < 500 or sz.X < 760) then
  return true
  end
  return false
  end

  local screenSize = GetScreenSize()
  local isMobile = false
  if GuiConfig.DeviceMode == "Mobile" then
  isMobile = true
  elseif GuiConfig.DeviceMode == "PC" then
  isMobile = false
  else
  isMobile = DetectIsMobile(screenSize)
  end

  local frameW = isMobile and math.clamp(screenSize.X - 80, 320, 520) or 810
  local frameH = isMobile and math.clamp(screenSize.Y - 45, 230, 290) or 550

  MainFrame = InstNew("Frame")
  RaxorHub.MainFrame = MainFrame
  MainFrame.Name = "MainFrame"
  MainFrame.Active = true
  MainFrame.AnchorPoint = V2(0.5, 0.5)
  MainFrame.Size = U2(0, frameW, 0, frameH)
  MainFrame.Position = U2(0.5, 0, 0.5, 0)
  MainFrame.BackgroundColor3 = Colors.WindowBg
  MainFrame.BackgroundTransparency = 0
  MainFrame.BorderSizePixel = 0
  MainFrame.ClipsDescendants = false
  MainFrame.ZIndex = 10
  MainFrame.Parent = ScreenGui

  local customMinW = isMobile and 320 or 650
  local customMinH = isMobile and 230 or 440
  local customMaxW = isMobile and 800 or 1400
  local customMaxH = isMobile and 600 or 950

  if GuiConfig.MinSize then
  if typeof(GuiConfig.MinSize) == "Vector2" then
  customMinW = GuiConfig.MinSize.X
  customMinH = GuiConfig.MinSize.Y
  elseif type(GuiConfig.MinSize) == "table" then
  customMinW = GuiConfig.MinSize.X or GuiConfig.MinSize.Width or customMinW
  customMinH = GuiConfig.MinSize.Y or GuiConfig.MinSize.Height or customMinH
  end
  end

  if GuiConfig.MaxSize then
  if typeof(GuiConfig.MaxSize) == "Vector2" then
  customMaxW = GuiConfig.MaxSize.X
  customMaxH = GuiConfig.MaxSize.Y
  elseif type(GuiConfig.MaxSize) == "table" then
  customMaxW = GuiConfig.MaxSize.X or GuiConfig.MaxSize.Width or customMaxW
  customMaxH = GuiConfig.MaxSize.Y or GuiConfig.MaxSize.Height or customMaxH
  end
  end

  local windowConstraint = InstNew("UISizeConstraint")
  windowConstraint.Name = "WindowConstraint"
  windowConstraint.MinSize = V2(customMinW, customMinH)
  windowConstraint.MaxSize = V2(customMaxW, customMaxH)
  windowConstraint.Parent = MainFrame

  AddCorner(MainFrame, 14)
  local mainStroke = AddStroke(MainFrame, Colors.Border, 1.2)
  local strokeGrad = InstNew("UIGradient")
  strokeGrad.Color = ColorSequence.new({
  ColorSequenceKeypoint.new(0, C3_RGB(168, 85, 247)),
  ColorSequenceKeypoint.new(0.35, C3_RGB(79, 70, 229)),
  ColorSequenceKeypoint.new(0.7, C3_RGB(35, 38, 56)),
  ColorSequenceKeypoint.new(1, C3_RGB(56, 189, 248))
  })
  strokeGrad.Rotation = 45
  strokeGrad.Parent = mainStroke

  local Sidebar, SidebarDivider, SidebarFade, SidebarScroll, TopBreadcrumb, MobileTabBar
  local TopBar, ContentContainer, RefreshLangVisuals

  local WindowBgImage = InstNew("ImageLabel")
  WindowBgImage.Name = "WindowBgImage"
  WindowBgImage.Size = U2(1, 0, 1, 0)
  WindowBgImage.BackgroundTransparency = 1
  WindowBgImage.ImageTransparency = 1
  WindowBgImage.ScaleType = Enum.ScaleType.Crop
  WindowBgImage.ZIndex = 11
  WindowBgImage.Parent = MainFrame
  AddCorner(WindowBgImage, 14)

  local WindowBgTint = InstNew("Frame")
  WindowBgTint.Name = "WindowBgTint"
  WindowBgTint.Size = U2(1, 0, 1, 0)
  WindowBgTint.BackgroundColor3 = C3_RGB(12, 13, 19)
  WindowBgTint.BackgroundTransparency = 0.38
  WindowBgTint.ZIndex = 12
  WindowBgTint.Visible = false
  WindowBgTint.Parent = MainFrame
  AddCorner(WindowBgTint, 14)

  local function ApplyWallpaper(name)
    local asset = Wallpapers[name]
    if asset then
      WindowBgImage.Image = asset
      WindowBgImage.ImageTransparency = 0.1
      WindowBgTint.BackgroundTransparency = 0.38
      WindowBgTint.Visible = true
      if Sidebar then
        Sidebar.BackgroundTransparency = 0.55
        if not SidebarFade then
          SidebarFade = InstNew("UIGradient")
          SidebarFade.Name = "SidebarFade"
          SidebarFade.Transparency = NS_new({
            NSK_new(0, 0.25),
            NSK_new(0.6, 0.45),
            NSK_new(1, 0.7)
          })
          SidebarFade.Parent = Sidebar
        else
          SidebarFade.Enabled = true
        end
      end
      if SidebarDivider then
        SidebarDivider.BackgroundTransparency = 0.7
      end
    else
      WindowBgImage.Image = ""
      WindowBgImage.ImageTransparency = 1
      WindowBgTint.Visible = false
      if Sidebar then
        Sidebar.BackgroundTransparency = 0
        if SidebarFade then
          SidebarFade.Enabled = false
        end
      end
      if SidebarDivider then
        SidebarDivider.BackgroundTransparency = 0
      end
    end
    pcall(function() MainFrame:SetAttribute("Wallpaper", name) end)
  end
  window.SetWallpaper = ApplyWallpaper
  MainFrame:GetAttributeChangedSignal("Wallpaper"):Connect(function()
  ApplyWallpaper(MainFrame:GetAttribute("Wallpaper"))
  end)

  NotificationHolder = InstNew("Frame")
  NotificationHolder.Name = "NotificationHolder"
  NotificationHolder.Size = U2(0, 250, 0, 0)
  NotificationHolder.AutomaticSize = AutoY
  NotificationHolder.Position = U2(1, -260, 1, -20)
  NotificationHolder.AnchorPoint = V2(0, 1)
  NotificationHolder.BackgroundTransparency = 1
  NotificationHolder.Active = false
  NotificationHolder.ZIndex = 8999
  NotificationHolder.Parent = ScreenGui

  local NotifLayout = InstNew("UIListLayout")
  NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
  NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
  NotifLayout.Padding = UDim.new(0, 8)
  NotifLayout.SortOrder = SO_Layout
  NotifLayout.Parent = NotificationHolder

  StartBtn = InstNew("TextButton")
  RaxorHub.StartBtn = StartBtn
  StartBtn.Name = "RaxorMiniWidget"
  StartBtn.Size = isMobile and U2(0, 205, 0, 32) or U2(0, 235, 0, 36)
  StartBtn.AnchorPoint = V2(0.5, 0)
  StartBtn.Position = U2(0.5, 0, 0, 6)
  StartBtn.BackgroundColor3 = C3_RGB(12, 13, 20)
  StartBtn.BackgroundTransparency = 0.05
  StartBtn.BorderSizePixel = 0
  StartBtn.Text = ""
  StartBtn.AutoButtonColor = false
  StartBtn.Visible = false
  StartBtn.ZIndex = 8000
  StartBtn.Parent = ScreenGui

  StartBtn.MouseButton1Click:Connect(function()
  if ToggleUI then ToggleUI() end
  end)

  AddCorner(StartBtn, 999)
  local miniStroke = AddStroke(StartBtn, Colors.BorderActive, 1.2)
  local miniStrokeGrad = InstNew("UIGradient")
  miniStrokeGrad.Color = ColorSequence.new({
  ColorSequenceKeypoint.new(0, C3_RGB(168, 85, 247)),
  ColorSequenceKeypoint.new(0.5, C3_RGB(79, 70, 229)),
  ColorSequenceKeypoint.new(1, C3_RGB(56, 189, 248))
  })
  miniStrokeGrad.Rotation = 45
  miniStrokeGrad.Parent = miniStroke

  local MiniLayout = InstNew("UIListLayout")
  MiniLayout.FillDirection = FD_H
  MiniLayout.HorizontalAlignment = HA_Center
  MiniLayout.VerticalAlignment = VA_Center
  MiniLayout.Padding = UDim.new(0, 7)
  MiniLayout.SortOrder = SO_Layout
  MiniLayout.Parent = StartBtn

  local MiniLogo = InstNew("ImageLabel")
  MiniLogo.Name = "MiniLogo"
  MiniLogo.Size = U2(0, 18, 0, 18)
  MiniLogo.Image = GuiConfig.Logo or Icons.Logo
  MiniLogo.ImageColor3 = Colors.White
  MiniLogo.BackgroundTransparency = 1
  MiniLogo.ZIndex = 8001
  MiniLogo.LayoutOrder = 1
  MiniLogo.Parent = StartBtn

  local MiniTitle = InstNew("TextLabel")
  MiniTitle.Name = "MiniTitle"
  MiniTitle.Text = string.upper(type(GuiConfig.Title) == "string" and GuiConfig.Title or "RAXOR")
  MiniTitle.Font = Fonts.Title
  MiniTitle.TextSize = 11
  MiniTitle.TextColor3 = Colors.White
  MiniTitle.AutomaticSize = Enum.AutomaticSize.X
  MiniTitle.BackgroundTransparency = 1
  MiniTitle.ZIndex = 8001
  MiniTitle.LayoutOrder = 2
  MiniTitle.Parent = StartBtn

  local MiniDiv1 = InstNew("Frame")
  MiniDiv1.Size = U2(0, 1, 0, 14)
  MiniDiv1.BackgroundColor3 = Colors.Border
  MiniDiv1.BorderSizePixel = 0
  MiniDiv1.ZIndex = 8001
  MiniDiv1.LayoutOrder = 3
  MiniDiv1.Parent = StartBtn

  local FpsIcon = InstNew("TextLabel")
  FpsIcon.Name = "FpsIcon"
  FpsIcon.Text = "●"
  FpsIcon.Font = Fonts.Title
  FpsIcon.TextSize = 9
  FpsIcon.TextColor3 = C3_RGB(34, 197, 94)
  FpsIcon.AutomaticSize = Enum.AutomaticSize.X
  FpsIcon.BackgroundTransparency = 1
  FpsIcon.ZIndex = 8001
  FpsIcon.LayoutOrder = 4
  FpsIcon.Parent = StartBtn

  local FpsLabel = InstNew("TextLabel")
  FpsLabel.Name = "FpsLabel"
  FpsLabel.Text = "60 FPS"
  FpsLabel.Font = Fonts.Medium
  FpsLabel.TextSize = 11
  FpsLabel.TextColor3 = C3_RGB(240, 240, 245)
  FpsLabel.AutomaticSize = Enum.AutomaticSize.X
  FpsLabel.BackgroundTransparency = 1
  FpsLabel.ZIndex = 8001
  FpsLabel.LayoutOrder = 5
  FpsLabel.Parent = StartBtn

  local MiniDiv2 = InstNew("Frame")
  MiniDiv2.Size = U2(0, 1, 0, 14)
  MiniDiv2.BackgroundColor3 = Colors.Border
  MiniDiv2.BorderSizePixel = 0
  MiniDiv2.ZIndex = 8001
  MiniDiv2.LayoutOrder = 6
  MiniDiv2.Parent = StartBtn

  local PingIcon = InstNew("TextLabel")
  PingIcon.Name = "PingIcon"
  PingIcon.Text = "⚡"
  PingIcon.Font = Fonts.Title
  PingIcon.TextSize = 10
  PingIcon.TextColor3 = C3_RGB(56, 189, 248)
  PingIcon.AutomaticSize = Enum.AutomaticSize.X
  PingIcon.BackgroundTransparency = 1
  PingIcon.ZIndex = 8001
  PingIcon.LayoutOrder = 7
  PingIcon.Parent = StartBtn

  local PingLabel = InstNew("TextLabel")
  PingLabel.Name = "PingLabel"
  PingLabel.Text = "32 ms"
  PingLabel.Font = Fonts.Medium
  PingLabel.TextSize = 11
  PingLabel.TextColor3 = C3_RGB(240, 240, 245)
  PingLabel.AutomaticSize = Enum.AutomaticSize.X
  PingLabel.BackgroundTransparency = 1
  PingLabel.ZIndex = 8001
  PingLabel.LayoutOrder = 8
  PingLabel.Parent = StartBtn

  local frameCounter = 0
  local lastStatUpdate = tick()
  RunService.RenderStepped:Connect(function(dt)
  frameCounter = frameCounter + 1
  local now = tick()
  if now - lastStatUpdate >= 0.4 then
  local fps = math.floor((frameCounter / (now - lastStatUpdate)) + 0.5)
  frameCounter = 0
  lastStatUpdate = now

  if FpsLabel and FpsLabel.Parent then
  FpsLabel.Text = tostring(fps) .. " FPS"
  if fps >= 50 then
    FpsIcon.TextColor3 = C3_RGB(34, 197, 94)
  elseif fps >= 30 then
    FpsIcon.TextColor3 = C3_RGB(245, 158, 11)
  else
    FpsIcon.TextColor3 = C3_RGB(239, 68, 68)
  end
  end

  local ping = 0
  local okPing, resPing = pcall(function()
  local stats = game:GetService("Stats")
  local ssi = stats:FindFirstChild("Network") and stats.Network:FindFirstChild("ServerStatsItem")
  if ssi and ssi:FindFirstChild("Data Ping") then
    return math.floor(ssi["Data Ping"]:GetValue())
  end
  return nil
  end)
  if okPing and resPing then
  ping = resPing
  elseif LocalPlayer then
  local okP, pVal = pcall(function() return math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
  if okP and pVal then ping = pVal end
  end

  if PingLabel and PingLabel.Parent then
  PingLabel.Text = tostring(ping) .. " ms"
  if ping < 80 then
    PingIcon.TextColor3 = C3_RGB(56, 189, 248)
  elseif ping < 150 then
    PingIcon.TextColor3 = C3_RGB(245, 158, 11)
  else
    PingIcon.TextColor3 = C3_RGB(239, 68, 68)
  end
  end
  end
  end)

  local isToggling = false
  local savedFrameSize = U2(0, frameW, 0, frameH)
  local function ToggleUI()
  if isToggling then return end
  isToggling = true
  CloseAllDropdowns()
  if PresetsModal then PresetsModal.Visible = false end
  if TooltipFrame then TooltipFrame.Visible = false end
  if MainFrame.Visible then
  savedFrameSize = MainFrame.Size
  local t = Tween(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
  Size = U2(0, MainFrame.AbsoluteSize.X * 0.95, 0, MainFrame.AbsoluteSize.Y * 0.95)
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
  MainFrame.Size = U2(0, savedFrameSize.X.Offset * 0.95, 0, savedFrameSize.Y.Offset * 0.95)
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
  ToggleUI()
  end)

  local ResizeHandle = InstNew("Frame")
  ResizeHandle.Name = "ResizeHandle"
  ResizeHandle.Size = U2(0, 24, 0, 24)
  ResizeHandle.Position = U2(1, -24, 1, -24)
  ResizeHandle.BackgroundTransparency = 1
  ResizeHandle.ZIndex = 5000
  ResizeHandle.Visible = not isMobile
  ResizeHandle.Active = not isMobile
  ResizeHandle.Parent = MainFrame

  local gripLines = {}
  local lineSpecs = {
  { size = 4,  offset = 6 },
  { size = 8,  offset = 10 },
  { size = 12, offset = 14 }
  }

  for i, spec in ipairs(lineSpecs) do
  local line = InstNew("Frame")
  line.Name = "GripLine" .. i
  line.Size = U2(0, spec.size, 0, 2)
  line.Position = U2(1, -spec.offset, 1, -spec.offset)
  line.AnchorPoint = V2(0.5, 0.5)
  line.Rotation = -45
  line.BackgroundColor3 = Colors.MutedText
  line.BackgroundTransparency = 0.4
  line.BorderSizePixel = 0
  line.ZIndex = 5001
  line.Parent = ResizeHandle
  AddCorner(line, 1)
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
  if not isMobile then
  MakeResizable(MainFrame, ResizeHandle, customMinW, customMinH, customMaxW, customMaxH)
  end

  PresetsModal = InstNew("Frame")
  PresetsModal.Name = "PresetsModal"
  PresetsModal.Active = true
  if isMobile then
  PresetsModal.Size = U2(0, 310, 1, -20)
  PresetsModal.AnchorPoint = V2(0.5, 0.5)
  PresetsModal.Position = U2(0.5, 0, 0.5, 0)
  else
  PresetsModal.Size = U2(0, 330, 1, -58)
  PresetsModal.AnchorPoint = V2(0, 0)
  PresetsModal.Position = U2(1, -340, 0, 50)
  end
  PresetsModal.BackgroundColor3 = Colors.ModalBg
  PresetsModal.BorderSizePixel = 0
  PresetsModal.Visible = false
  PresetsModal.ZIndex = 6000
  PresetsModal.Parent = MainFrame
  AddCorner(PresetsModal, 10)
  AddStroke(PresetsModal, Colors.BorderFocus, 1.2)

  local PresetsHeader = InstNew("Frame")
  PresetsHeader.Size = U2(1, 0, 0, 42)
  PresetsHeader.BackgroundTransparency = 1
  PresetsHeader.ZIndex = 6001
  PresetsHeader.Parent = PresetsModal

  local PresetsIcon = InstNew("ImageLabel")
  PresetsIcon.Size = U2(0, 18, 0, 18)
  PresetsIcon.Position = U2(0, 12, 0.5, -9)
  PresetsIcon.Image = Icons.Folder
  PresetsIcon.ImageColor3 = Colors.Accent
  PresetsIcon.BackgroundTransparency = 1
  PresetsIcon.ZIndex = 6002
  PresetsIcon.Parent = PresetsHeader

  local PresetsTitle = InstNew("TextLabel")
  PresetsTitle.Text = "Presets Configuration"
  PresetsTitle.Font = Fonts.Title
  PresetsTitle.TextSize = 13
  PresetsTitle.TextColor3 = Colors.Text
  PresetsTitle.Position = U2(0, 38, 0.5, -9)
  PresetsTitle.Size = U2(1, -80, 0, 18)
  PresetsTitle.TextXAlignment = TXA_LEFT
  PresetsTitle.BackgroundTransparency = 1
  PresetsTitle.ZIndex = 6002
  PresetsTitle.Parent = PresetsHeader
  RegisterI18n(PresetsTitle, "Text", "Presets Configuration")

  local PresetsCloseBtn = InstNew("ImageButton")
  PresetsCloseBtn.Size = U2(0, 24, 0, 24)
  PresetsCloseBtn.Position = U2(1, -32, 0.5, -12)
  PresetsCloseBtn.BackgroundColor3 = Colors.ControlBtn
  PresetsCloseBtn.Image = Icons.Close
  PresetsCloseBtn.ImageColor3 = Colors.SubText
  PresetsCloseBtn.AutoButtonColor = false
  PresetsCloseBtn.ZIndex = 6003
  PresetsCloseBtn.Parent = PresetsHeader
  AddCorner(PresetsCloseBtn, 5)

  BindClick(PresetsCloseBtn, function()
  PresetsModal.Visible = false
  end)

  local ConfigInputFrame = InstNew("Frame")
  ConfigInputFrame.Name = "ConfigInputFrame"
  ConfigInputFrame.Size = U2(1, -20, 0, 36)
  ConfigInputFrame.Position = U2(0, 10, 0, 44)
  ConfigInputFrame.BackgroundColor3 = Colors.InputBg
  ConfigInputFrame.ZIndex = 6002
  ConfigInputFrame.Parent = PresetsModal
  AddCorner(ConfigInputFrame, 7)
  AddStroke(ConfigInputFrame, Colors.Border, 1)

  local ConfigNameInput = InstNew("TextBox")
  ConfigNameInput.Size = U2(1, -44, 1, 0)
  ConfigNameInput.Position = U2(0, 12, 0, 0)
  ConfigNameInput.BackgroundTransparency = 1
  ConfigNameInput.Text = ""
  ConfigNameInput.PlaceholderText = "New config name..."
  ConfigNameInput.PlaceholderColor3 = Colors.MutedText
  ConfigNameInput.TextColor3 = Colors.Text
  ConfigNameInput.Font = Fonts.Regular
  ConfigNameInput.TextSize = 12
  ConfigNameInput.TextXAlignment = TXA_LEFT
  ConfigNameInput.ClearTextOnFocus = false
  ConfigNameInput.ZIndex = 6003
  ConfigNameInput.Parent = ConfigInputFrame

  local AddConfigBtn = InstNew("ImageButton")
  AddConfigBtn.Size = U2(0, 28, 0, 28)
  AddConfigBtn.Position = U2(1, -32, 0.5, -14)
  AddConfigBtn.BackgroundColor3 = Colors.Accent
  AddConfigBtn.Image = Icons.Save
  AddConfigBtn.ImageColor3 = Colors.White
  AddConfigBtn.AutoButtonColor = false
  AddConfigBtn.ZIndex = 6003
  AddConfigBtn.Parent = ConfigInputFrame
  AddCorner(AddConfigBtn, 6)

  AddConfigBtn.MouseEnter:Connect(function()
  Tween(AddConfigBtn, T_FAST, {BackgroundColor3 = Colors.AccentHover})
  end)
  AddConfigBtn.MouseLeave:Connect(function()
  Tween(AddConfigBtn, T_FAST, {BackgroundColor3 = Colors.Accent})
  end)
  AttachTooltip(AddConfigBtn, "Save New Preset")

  local PresetsScroll = InstNew("ScrollingFrame")
  PresetsScroll.Name = "PresetsScroll"
  PresetsScroll.Size = U2(1, -20, 1, -134)
  PresetsScroll.Position = U2(0, 10, 0, 88)
  PresetsScroll.BackgroundTransparency = 1
  PresetsScroll.BorderSizePixel = 0
  PresetsScroll.ScrollBarThickness = 3
  PresetsScroll.ScrollBarImageColor3 = Colors.Accent
  PresetsScroll.Active = true
  PresetsScroll.ScrollingEnabled = true
  PresetsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
  PresetsScroll.ElasticBehavior = Enum.ElasticBehavior.Always
  PresetsScroll.ZIndex = 6002
  PresetsScroll.Parent = PresetsModal

  local PresetsLayout = InstNew("UIListLayout")
  PresetsLayout.Padding = UDim.new(0, 6)
  PresetsLayout.SortOrder = SO_Layout
  PresetsLayout.Parent = PresetsScroll

  local FooterFrame = InstNew("Frame")
  FooterFrame.Name = "FooterFrame"
  FooterFrame.Size = U2(1, -20, 0, 36)
  FooterFrame.Position = U2(0, 10, 1, -40)
  FooterFrame.BackgroundTransparency = 1
  FooterFrame.ZIndex = 6002
  FooterFrame.Parent = PresetsModal

  local FooterDivider = InstNew("Frame")
  FooterDivider.Size = U2(1, 0, 0, 1)
  FooterDivider.Position = U2(0, 0, 0, 0)
  FooterDivider.BackgroundColor3 = Colors.Border
  FooterDivider.BorderSizePixel = 0
  FooterDivider.ZIndex = 6003
  FooterDivider.Parent = FooterFrame

  local FooterStarIcon = InstNew("ImageLabel")
  FooterStarIcon.Size = U2(0, 14, 0, 14)
  FooterStarIcon.Position = U2(0, 4, 0.5, -7)
  FooterStarIcon.Image = Icons.Star
  FooterStarIcon.ImageColor3 = Colors.Accent
  FooterStarIcon.BackgroundTransparency = 1
  FooterStarIcon.ZIndex = 6003
  FooterStarIcon.Parent = FooterFrame

  local FooterAutoLabel = InstNew("TextLabel")
  FooterAutoLabel.Size = U2(1, -84, 1, -1)
  FooterAutoLabel.Position = U2(0, 24, 0, 1)
  FooterAutoLabel.BackgroundTransparency = 1
  FooterAutoLabel.Font = Fonts.Medium
  FooterAutoLabel.TextSize = 11
  FooterAutoLabel.TextColor3 = Colors.SubText
  FooterAutoLabel.TextXAlignment = TXA_LEFT
  FooterAutoLabel.TextTruncate = TruncEnd
  FooterAutoLabel.ZIndex = 6003
  FooterAutoLabel.Parent = FooterFrame

  local FooterResetBtn = InstNew("TextButton")
  FooterResetBtn.Size = U2(0, 56, 0, 24)
  FooterResetBtn.Position = U2(1, -56, 0.5, -12)
  FooterResetBtn.BackgroundColor3 = Colors.ButtonBg
  FooterResetBtn.Text = "Reset"
  FooterResetBtn.Font = Fonts.Medium
  FooterResetBtn.TextSize = 11
  FooterResetBtn.TextColor3 = Colors.SubText
  FooterResetBtn.AutoButtonColor = false
  FooterResetBtn.ZIndex = 6003
  FooterResetBtn.Parent = FooterFrame
  AddCorner(FooterResetBtn, 5)
  AddStroke(FooterResetBtn, Colors.Border, 1)

  FooterResetBtn.MouseEnter:Connect(function()
  Tween(FooterResetBtn, T_FAST, {BackgroundColor3 = Colors.ButtonHover, TextColor3 = Colors.White})
  end)
  FooterResetBtn.MouseLeave:Connect(function()
  Tween(FooterResetBtn, T_FAST, {BackgroundColor3 = Colors.ButtonBg, TextColor3 = Colors.SubText})
  end)
  AttachTooltip(FooterResetBtn, "Clear Autoload")

  local function RefreshPresetsList()
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
  PresetsScroll.CanvasSize = U2(0, 0, 0, math.max(#configs * 50, 0))

  if #configs == 0 then
  local emptyContainer = InstNew("Frame")
  emptyContainer.Name = "EmptyState"
  emptyContainer.Size = U2(1, 0, 0, 110)
  emptyContainer.BackgroundTransparency = 1
  emptyContainer.ZIndex = 6003
  emptyContainer.Parent = PresetsScroll

  local emptyIcon = InstNew("ImageLabel")
  emptyIcon.Size = U2(0, 32, 0, 32)
  emptyIcon.Position = U2(0.5, -16, 0, 20)
  emptyIcon.Image = Icons.Folder
  emptyIcon.ImageColor3 = Colors.MutedText
  emptyIcon.ImageTransparency = 0.5
  emptyIcon.BackgroundTransparency = 1
  emptyIcon.ZIndex = 6004
  emptyIcon.Parent = emptyContainer

  local emptyLabel = InstNew("TextLabel")
  emptyLabel.Size = U2(1, 0, 0, 24)
  emptyLabel.Position = U2(0, 0, 0, 58)
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
  local itemRow = InstNew("Frame")
  itemRow.Size = U2(1, -2, 0, 44)
  itemRow.BackgroundColor3 = isAuto and Colors.CardHover or Colors.CardBg
  itemRow.Active = false
  itemRow.ZIndex = 6003
  itemRow.Parent = PresetsScroll
  AddCorner(itemRow, 7)
  local rowStroke = AddStroke(itemRow, isAuto and Colors.Accent or Colors.Border, 1)

  local itemLabel = InstNew("TextLabel")
  itemLabel.Text = (isAuto and "★ " or "") .. cfgName
  itemLabel.Font = isAuto and Fonts.Title or Fonts.Medium
  itemLabel.TextSize = 12
  itemLabel.TextColor3 = isAuto and Colors.Accent or Colors.Text
  itemLabel.Position = U2(0, 10, 0, 0)
  itemLabel.Size = U2(1, -168, 1, 0)
  itemLabel.TextXAlignment = TXA_LEFT
  itemLabel.TextTruncate = TruncEnd
  itemLabel.BackgroundTransparency = 1
  itemLabel.ZIndex = 6004
  itemLabel.Parent = itemRow

  local loadBtn = InstNew("TextButton")
  loadBtn.Size = U2(0, 44, 0, 28)
  loadBtn.Position = U2(1, -156, 0.5, -14)
  loadBtn.BackgroundColor3 = Colors.Accent
  loadBtn.Text = "Load"
  loadBtn.Font = Fonts.Title
  loadBtn.TextSize = 11
  loadBtn.TextColor3 = Colors.White
  loadBtn.AutoButtonColor = false
  loadBtn.ZIndex = 6004
  loadBtn.Parent = itemRow
  AddCorner(loadBtn, 5)

  BindClick(loadBtn, function()
  PlayClickSound()
  RaxorHub:LoadConfigData(cfgName)
  end)
  AttachTooltip(loadBtn, "Load This Preset")

  local overwriteBtn = InstNew("ImageButton")
  overwriteBtn.Size = U2(0, 28, 0, 28)
  overwriteBtn.Position = U2(1, -106, 0.5, -14)
  overwriteBtn.BackgroundColor3 = Colors.ButtonBg
  overwriteBtn.Image = Icons.Save
  overwriteBtn.ImageColor3 = Colors.SubText
  overwriteBtn.AutoButtonColor = false
  overwriteBtn.ZIndex = 6004
  overwriteBtn.Parent = itemRow
  AddCorner(overwriteBtn, 5)
  AddStroke(overwriteBtn, Colors.Border, 1)

  BindClick(overwriteBtn, function()
  PlayClickSound()
  RaxorHub:SaveCurrentConfig(cfgName)
  end)
  AttachTooltip(overwriteBtn, "Overwrite with Current Settings")

  local autoBtn = InstNew("ImageButton")
  autoBtn.Size = U2(0, 28, 0, 28)
  autoBtn.Position = U2(1, -72, 0.5, -14)
  autoBtn.BackgroundColor3 = isAuto and Colors.CardHover or Colors.ButtonBg
  autoBtn.Image = Icons.Star
  autoBtn.ImageColor3 = isAuto and Colors.Accent or Colors.MutedText
  autoBtn.AutoButtonColor = false
  autoBtn.ZIndex = 6004
  autoBtn.Parent = itemRow
  AddCorner(autoBtn, 5)
  AddStroke(autoBtn, isAuto and Colors.Accent or Colors.Border, 1)

  BindClick(autoBtn, function()
  PlayClickSound()
  if RaxorHub:GetAutoload() == cfgName then
    RaxorHub:ResetAutoload()
  else
    RaxorHub:SetAutoload(cfgName)
  end
  RefreshPresetsList()
  end)
  AttachTooltip(autoBtn, isAuto and "Disable Autoload" or "Enable Autoload")

  local delBtn = InstNew("ImageButton")
  delBtn.Size = U2(0, 28, 0, 28)
  delBtn.Position = U2(1, -38, 0.5, -14)
  delBtn.BackgroundColor3 = Colors.ButtonBg
  delBtn.Image = Icons.Trash
  delBtn.ImageColor3 = Colors.SubText
  delBtn.AutoButtonColor = false
  delBtn.ZIndex = 6004
  delBtn.Parent = itemRow
  AddCorner(delBtn, 5)
  AddStroke(delBtn, Colors.Border, 1)

  BindClick(delBtn, function()
  PlayClickSound()
  RaxorHub:DeleteConfig(cfgName)
  RefreshPresetsList()
  end)
  AttachTooltip(delBtn, "Delete This Preset Permanently")
  end
  end
  RaxorHub.RefreshPresetsList = RefreshPresetsList

  BindClick(FooterResetBtn, function()
  PlayClickSound()
  RaxorHub:ResetAutoload()
  RefreshPresetsList()
  end)

  local function DoSaveNew()
  local name = ConfigNameInput.Text
  if name and name ~= "" and name ~= "---" then
  PlayClickSound()
  RaxorHub:SaveCurrentConfig(name)
  ConfigNameInput.Text = ""
  RefreshPresetsList()
  else
  RaxorHub:Notify({
  Title = "Error",
  Content = "Please enter a preset name before saving",
  Duration = 2.5
  })
  end
  end
  BindClick(AddConfigBtn, DoSaveNew)

  ConfigNameInput.FocusLost:Connect(function(enterPressed)
  if enterPressed then
  DoSaveNew()
  end
  end)

  RefreshPresetsList()

  if not isMobile then
  local SidebarWidth = 165

  Sidebar = InstNew("Frame")
  Sidebar.Name = "Sidebar"
  Sidebar.Active = true
  Sidebar.Size = U2(0, SidebarWidth, 1, 0)
  Sidebar.Position = U2(0, 0, 0, 0)
  Sidebar.BackgroundColor3 = Colors.SidebarBg
  Sidebar.BorderSizePixel = 0
  Sidebar.ClipsDescendants = true
  Sidebar.ZIndex = 20
  Sidebar.Parent = MainFrame
  AddCorner(Sidebar, 14)

  SidebarDivider = InstNew("Frame")
  SidebarDivider.Size = U2(0, 1, 1, 0)
  SidebarDivider.Position = U2(1, -1, 0, 0)
  SidebarDivider.BackgroundColor3 = Colors.Border
  SidebarDivider.BorderSizePixel = 0
  SidebarDivider.ZIndex = 21
  SidebarDivider.Parent = Sidebar
  if MainFrame:GetAttribute("Wallpaper") and MainFrame:GetAttribute("Wallpaper") ~= "Default" then
    ApplyWallpaper(MainFrame:GetAttribute("Wallpaper"))
  end

  local BrandContainer = InstNew("Frame")
  BrandContainer.Name = "BrandContainer"
  BrandContainer.Size = U2(1, 0, 0, 50)
  BrandContainer.BackgroundTransparency = 1
  BrandContainer.ZIndex = 22
  BrandContainer.Parent = Sidebar
  MakeDraggable(MainFrame, BrandContainer)

  local BrandLogo = InstNew("ImageLabel")
  BrandLogo.Size = U2(0, 28, 0, 28)
  BrandLogo.Position = U2(0, 12, 0.5, -14)
  BrandLogo.Image = GuiConfig.Logo or Icons.Logo
  BrandLogo.ImageColor3 = Colors.White
  BrandLogo.BackgroundTransparency = 1
  BrandLogo.ZIndex = 23
  BrandLogo.Parent = BrandContainer

  local BrandTitle = InstNew("TextLabel")
  BrandTitle.Text = string.upper(type(GuiConfig.Title) == "string" and GuiConfig.Title or "RAXOR")
  BrandTitle.Font = Fonts.Brand
  BrandTitle.TextSize = 15
  BrandTitle.TextColor3 = Colors.Text
  BrandTitle.Position = U2(0, 46, 0, 9)
  BrandTitle.Size = U2(1, -50, 0, 17)
  BrandTitle.TextXAlignment = TXA_LEFT
  BrandTitle.BackgroundTransparency = 1
  BrandTitle.ZIndex = 23
  BrandTitle.Parent = BrandContainer

  local BrandAuthor = InstNew("TextLabel")
  BrandAuthor.Name = "BrandAuthor"
  BrandAuthor.Text = GuiConfig.Author or GuiConfig.Creator or "by : pigalo"
  BrandAuthor.Font = Fonts.Medium
  BrandAuthor.TextSize = 11
  BrandAuthor.TextColor3 = Colors.Accent
  BrandAuthor.Position = U2(0, 46, 0, 27)
  BrandAuthor.Size = U2(1, -50, 0, 13)
  BrandAuthor.TextXAlignment = TXA_LEFT
  BrandAuthor.BackgroundTransparency = 1
  BrandAuthor.ZIndex = 23
  BrandAuthor.Parent = BrandContainer
  RegisterAccent(BrandAuthor, "TextColor3")

  SidebarScroll = InstNew("ScrollingFrame")
  SidebarScroll.Name = "SidebarScroll"
  SidebarScroll.Size = U2(1, -8, 1, -118)
  SidebarScroll.Position = U2(0, 4, 0, 52)
  SidebarScroll.BackgroundTransparency = 1
  SidebarScroll.BorderSizePixel = 0
  SidebarScroll.ScrollBarThickness = 0
  SidebarScroll.ScrollingEnabled = true
  SidebarScroll.AutomaticCanvasSize = AutoY
  SidebarScroll.CanvasSize = U2(0, 0, 0, 0)
  SidebarScroll.ZIndex = 22
  SidebarScroll.Parent = Sidebar

  local SidebarLayout = InstNew("UIListLayout")
  SidebarLayout.Padding = UDim.new(0, 3)
  SidebarLayout.SortOrder = SO_Layout
  SidebarLayout.Parent = SidebarScroll

  local ProfileCard = InstNew("Frame")
  ProfileCard.Name = "ProfileCard"
  ProfileCard.Size = U2(1, -14, 0, 50)
  ProfileCard.Position = U2(0, 7, 1, -58)
  ProfileCard.BackgroundColor3 = Colors.CardBg
  ProfileCard.BorderSizePixel = 0
  ProfileCard.ZIndex = 25
  ProfileCard.Parent = Sidebar
  AddCorner(ProfileCard, 8)
  local profileStroke = AddStroke(ProfileCard, Colors.Border, 1)

  local AvatarImg = InstNew("ImageLabel")
  AvatarImg.Size = U2(0, 32, 0, 32)
  AvatarImg.Position = U2(0, 8, 0.5, -16)
  AvatarImg.BackgroundColor3 = Colors.MainCardBg
  AvatarImg.Image = Icons.Logo
  AvatarImg.ZIndex = 26
  AvatarImg.Parent = ProfileCard
  AddCorner(AvatarImg, 999)
  AddStroke(AvatarImg, Colors.BorderFocus, 1)

  task.spawn(function()
  pcall(function()
  local thumbType = Enum.ThumbnailType.HeadShot
  local thumbSize = Enum.ThumbnailSize.Size48x48
  local content, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, thumbType, thumbSize)
  if isReady and content then AvatarImg.Image = content end
  end)
  end)

  local realName = LocalPlayer and (LocalPlayer.DisplayName or LocalPlayer.Name) or "User"
  local isCensored = true
  if GuiConfig.CensorName ~= nil then
  isCensored = GuiConfig.CensorName
  end

  local ProfileName = InstNew("TextLabel")
  ProfileName.Name = "ProfileName"
  ProfileName.Font = Fonts.Title
  ProfileName.TextSize = 13
  ProfileName.TextColor3 = Colors.Text
  ProfileName.Size = U2(1, -52, 0, 16)
  ProfileName.Position = U2(0, 46, 0, 9)
  ProfileName.TextXAlignment = TXA_LEFT
  ProfileName.TextTruncate = TruncEnd
  ProfileName.BackgroundTransparency = 1
  ProfileName.ZIndex = 26
  ProfileName.Parent = ProfileCard

  local function MaskName(name)
  local len = #name
  if len <= 3 then
  return string.sub(name, 1, 1) .. string.rep("•", 5)
  end
  local prefix = string.sub(name, 1, 3)
  local bulletCount = math.max(6, len - 3)
  return prefix .. string.rep("•", bulletCount)
  end

  local function UpdateCensorVisuals()
  if isCensored then
  ProfileName.Text = MaskName(realName)
  else
  ProfileName.Text = realName
  end
  end

  local function ToggleCensor()
  PlayClickSound()
  isCensored = not isCensored
  UpdateCensorVisuals()
  end

  local CardHitbox = InstNew("TextButton")
  CardHitbox.Name = "CardHitbox"
  CardHitbox.Size = U2(1, 0, 1, 0)
  CardHitbox.BackgroundTransparency = 1
  CardHitbox.Text = ""
  CardHitbox.ZIndex = 27
  CardHitbox.Parent = ProfileCard
  CardHitbox.MouseButton1Click:Connect(ToggleCensor)
  AttachTooltip(CardHitbox, "Click to toggle privacy mode")

  CardHitbox.MouseEnter:Connect(function()
  Tween(ProfileCard, T_FAST, {BackgroundColor3 = Colors.CardHover})
  profileStroke.Color = Colors.BorderFocus
  end)
  CardHitbox.MouseLeave:Connect(function()
  Tween(ProfileCard, T_FAST, {BackgroundColor3 = Colors.CardBg})
  profileStroke.Color = Colors.Border
  end)

  UpdateCensorVisuals()

  local ProfileStatus = InstNew("TextLabel")
  ProfileStatus.Name = "ProfileStatus"
  ProfileStatus.Font = Fonts.Medium
  ProfileStatus.TextSize = 11
  ProfileStatus.TextColor3 = Colors.SubText
  ProfileStatus.Size = U2(1, -52, 0, 14)
  ProfileStatus.Position = U2(0, 46, 0, 26)
  ProfileStatus.TextXAlignment = TXA_LEFT
  ProfileStatus.TextTruncate = TruncEnd
  ProfileStatus.BackgroundTransparency = 1
  ProfileStatus.ZIndex = 26
  ProfileStatus.Parent = ProfileCard

  local function FormatKeyTime(val)
  if type(val) == "number" then
  local now = os.time()
  local diff = val - now
  if diff <= 0 then
    return "Key: Expired", Colors.CloseRed
  end
  local days = math.floor(diff / 86400)
  local hours = math.floor((diff % 86400) / 3600)
  local mins = math.floor((diff % 3600) / 60)
  if days > 0 then
    return string.format("Key: %dd %dh", days, hours), Colors.SubText
  elseif hours > 0 then
    return string.format("Key: %dh %02dm", hours, mins), Colors.SubText
  else
    local secs = diff % 60
    return string.format("Key: %02dm %02ds", mins, secs), Colors.AccentCyan
  end
  elseif type(val) == "string" and val ~= "" then
  local lower = val:lower()
  if lower:find("lifetime") or lower:find("permanent") then
    return "Lifetime", C3_RGB(168, 85, 247)
  elseif lower:find("key") or lower:find("expire") or lower:find("till") then
    return val, Colors.SubText
  else
    return "Key: " .. val, Colors.SubText
  end
  end
  return "Lifetime", C3_RGB(168, 85, 247)
  end

  local keySource = GuiConfig.KeyExpires or GuiConfig.KeyTime or GuiConfig.KeyRemaining or (GuiConfig.KeySystem and GuiConfig.KeySystem.Expires)
  if not keySource and GuiConfig.ProfileTag and GuiConfig.ProfileTag ~= "Dev Mode" then
  keySource = GuiConfig.ProfileTag
  end

  local statusText, statusColor = FormatKeyTime(keySource)
  ProfileStatus.Text = statusText
  ProfileStatus.TextColor3 = statusColor

  if type(keySource) == "number" and keySource > os.time() then
  task.spawn(function()
  while ScreenGui and ScreenGui.Parent and ProfileStatus and ProfileStatus.Parent do
    task.wait(30)
    local updatedText, updatedColor = FormatKeyTime(keySource)
    ProfileStatus.Text = updatedText
    ProfileStatus.TextColor3 = updatedColor
  end
  end)
  end

  function window:SetKeyStatus(val)
  local updatedText, updatedColor = FormatKeyTime(val)
  ProfileStatus.Text = updatedText
  ProfileStatus.TextColor3 = updatedColor
  end
  function window:SetCensored(censor)
  isCensored = censor
  UpdateCensorVisuals()
  end

  TopBar = InstNew("Frame")
  TopBar.Name = "TopBar"
  TopBar.Active = true
  TopBar.Size = U2(1, -SidebarWidth, 0, 48)
  TopBar.Position = U2(0, SidebarWidth, 0, 0)
  TopBar.BackgroundTransparency = 1
  TopBar.BorderSizePixel = 0
  TopBar.ZIndex = 30
  TopBar.Parent = MainFrame
  AddCorner(TopBar, 14)
  MakeDraggable(MainFrame, TopBar)

  local TopDivider = InstNew("Frame")
  TopDivider.Size = U2(1, 0, 0, 1)
  TopDivider.Position = U2(0, 0, 1, -1)
  TopDivider.BackgroundColor3 = Colors.Border
  TopDivider.BorderSizePixel = 0
  TopDivider.ZIndex = 31
  TopDivider.Parent = TopBar

  local SidebarToggleBtn = InstNew("ImageButton")
  SidebarToggleBtn.Name = "SidebarToggleBtn"
  SidebarToggleBtn.Size = U2(0, 26, 0, 26)
  SidebarToggleBtn.Position = U2(0, 10, 0.5, -13)
  SidebarToggleBtn.BackgroundColor3 = Colors.ControlBtn
  SidebarToggleBtn.Image = Icons.ChevronDown
  SidebarToggleBtn.Rotation = 90
  SidebarToggleBtn.ImageColor3 = Colors.SubText
  SidebarToggleBtn.AutoButtonColor = false
  SidebarToggleBtn.ZIndex = 36
  SidebarToggleBtn.Parent = TopBar
  AddCorner(SidebarToggleBtn, 6)
  AddStroke(SidebarToggleBtn, Colors.Border, 1)

  SidebarToggleBtn.MouseEnter:Connect(function()
  Tween(SidebarToggleBtn, T_FAST, {BackgroundColor3 = Colors.ButtonHover, ImageColor3 = Colors.White})
  end)
  SidebarToggleBtn.MouseLeave:Connect(function()
  Tween(SidebarToggleBtn, T_FAST, {BackgroundColor3 = Colors.ControlBtn, ImageColor3 = Colors.SubText})
  end)
  AttachTooltip(SidebarToggleBtn, "Hide Tabs")

  TopBreadcrumb = InstNew("TextLabel")
  TopBreadcrumb.Name = "TopBreadcrumb"
  local initialBreadcrumb = ResolveText("General", CurrentLanguage)
  TopBreadcrumb.Text = "| " .. initialBreadcrumb
  TopBreadcrumb.Font = Fonts.Title
  TopBreadcrumb.TextSize = (CurrentLanguage == "TH" or IsThaiText(initialBreadcrumb)) and 17 or 15
  TopBreadcrumb.TextColor3 = Colors.Accent
  TopBreadcrumb.Position = U2(0, 44, 0.5, -9)
  TopBreadcrumb.Size = U2(0, 110, 0, 18)
  TopBreadcrumb.TextXAlignment = TXA_LEFT
  TopBreadcrumb.BackgroundTransparency = 1
  TopBreadcrumb.ZIndex = 32
  TopBreadcrumb.Parent = TopBar
  RegisterAccent(TopBreadcrumb, "TextColor3")

  local Controls = InstNew("Frame")
  Controls.Name = "Controls"
  Controls.Size = U2(0, 235, 1, 0)
  Controls.Position = U2(1, -10, 0, 0)
  Controls.AnchorPoint = V2(1, 0)
  Controls.BackgroundTransparency = 1
  Controls.ZIndex = 35
  Controls.Parent = TopBar

  local ControlLayout = InstNew("UIListLayout")
  ControlLayout.FillDirection = FD_H
  ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
  ControlLayout.VerticalAlignment = VA_Center
  ControlLayout.Padding = UDim.new(0, 6)
  ControlLayout.SortOrder = SO_Layout
  ControlLayout.Parent = Controls

  local function CreateTopIconBtn(name, iconId, baseColor, hoverColor, order, callback)
  local btn = InstNew("ImageButton")
  btn.Name = name
  btn.LayoutOrder = order
  btn.Size = U2(0, 26, 0, 26)
  btn.BackgroundColor3 = baseColor or Colors.ControlBtn
  btn.Image = iconId or ""
  btn.ImageColor3 = Colors.SubText
  btn.AutoButtonColor = false
  btn.ZIndex = 36
  btn.Parent = Controls
  AddCorner(btn, 6)
  AddStroke(btn, Colors.Border, 1)

  btn.MouseEnter:Connect(function()
  Tween(btn, T_FAST, {BackgroundColor3 = hoverColor or Colors.ButtonHover, ImageColor3 = Colors.White})
  end)
  btn.MouseLeave:Connect(function()
  Tween(btn, T_FAST, {BackgroundColor3 = baseColor or Colors.ControlBtn, ImageColor3 = Colors.SubText})
  end)
  local lastClick = 0
  local function fire()
  local now = tick()
  if now - lastClick < 0.15 then return end
  lastClick = now
  PlayClickSound()
  callback()
  end
  btn.Activated:Connect(fire)
  btn.MouseButton1Click:Connect(fire)
  return btn
  end

  local sidebarCollapsed = false
  local function ToggleSidebar()
  sidebarCollapsed = not sidebarCollapsed
  local targetSidebarW = sidebarCollapsed and 0 or SidebarWidth
  local targetPos = sidebarCollapsed and 0 or SidebarWidth
  local targetSizeW = sidebarCollapsed and 0 or -SidebarWidth

  SidebarToggleBtn.Rotation = sidebarCollapsed and -90 or 90
  AttachTooltip(SidebarToggleBtn, sidebarCollapsed and "Show Tabs" or "Hide Tabs")

  Tween(Sidebar, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
  Size = U2(0, targetSidebarW, 1, 0)
  })
  Tween(TopBar, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
  Position = U2(0, targetPos, 0, 0),
  Size = U2(1, targetSizeW, 0, 48)
  })
  Tween(ContentContainer, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
  Position = U2(0, targetPos, 0, 48),
  Size = U2(1, targetSizeW, 1, -48)
  })
  end
  SidebarToggleBtn.MouseButton1Click:Connect(ToggleSidebar)

  local LangSwitcher = InstNew("Frame")
  LangSwitcher.Name = "LangSwitcher"
  LangSwitcher.LayoutOrder = 1
  LangSwitcher.Size = U2(0, 84, 0, 26)
  LangSwitcher.BackgroundColor3 = Colors.ControlBtn
  LangSwitcher.ZIndex = 36
  LangSwitcher.Parent = Controls
  AddCorner(LangSwitcher, 6)
  AddStroke(LangSwitcher, Colors.Border, 1)

  local langList = InstNew("UIListLayout", LangSwitcher)
  langList.FillDirection = FD_H
  langList.SortOrder = SO_Layout

  local function CreateLangBtn(langName, order)
  local btn = InstNew("TextButton")
  btn.Name = "Btn_" .. langName
  btn.LayoutOrder = order
  btn.Size = U2(0.5, 0, 1, 0)
  btn.AutoButtonColor = false
  btn.Text = langName
  btn.Font = Fonts.Title
  btn.TextSize = 11
  btn.BorderSizePixel = 0
  btn.ZIndex = 37
  btn.Parent = LangSwitcher
  AddCorner(btn, 5)
  return btn
  end

  local btnTH = CreateLangBtn("TH", 1)
  local btnEN = CreateLangBtn("EN", 2)

  local function UpdateLangBtnVisuals()
  local isTH = CurrentLanguage == "TH"
  btnTH.BackgroundColor3 = isTH and Colors.Accent or Colors.ControlBtn
  btnTH.BackgroundTransparency = isTH and 0 or 1
  btnTH.TextColor3 = isTH and Colors.White or Colors.SubText
  btnEN.BackgroundColor3 = not isTH and Colors.Accent or Colors.ControlBtn
  btnEN.BackgroundTransparency = not isTH and 0 or 1
  btnEN.TextColor3 = not isTH and Colors.White or Colors.SubText
  end

  btnTH.MouseButton1Click:Connect(function()
  PlayClickSound()
  RaxorHub:SetLanguage("TH")
  UpdateLangBtnVisuals()
  end)
  btnEN.MouseButton1Click:Connect(function()
  PlayClickSound()
  RaxorHub:SetLanguage("EN")
  UpdateLangBtnVisuals()
  end)
  UpdateLangBtnVisuals()
  RefreshLangVisuals = UpdateLangBtnVisuals
  RaxorHub.OnLanguageChanged = UpdateLangBtnVisuals
  RegisterAccent(UpdateLangBtnVisuals)

  local folderBtn = CreateTopIconBtn("FolderBtn", Icons.Folder, Colors.ControlBtn, Colors.ButtonHover, 2, function()
  if PresetsModal then
  PresetsModal.Visible = not PresetsModal.Visible
  if PresetsModal.Visible and RaxorHub.RefreshPresetsList then
    RaxorHub.RefreshPresetsList()
  end
  end
  end)
  AttachTooltip(folderBtn, "Presets Configuration")

  local minBtn = CreateTopIconBtn("MinBtn", Icons.Minimize, Colors.ControlBtn, Colors.ButtonHover, 3, function()
  if ToggleUI then ToggleUI() end
  end)
  AttachTooltip(minBtn, "Minimize Window")

  local resBtn = CreateTopIconBtn("ResBtn", Icons.Restore, Colors.ControlBtn, Colors.ButtonHover, 4, function()
  MainFrame.Position = U2(0.5, 0, 0.5, 0)
  end)
  AttachTooltip(resBtn, "Center Window")

  local closeBtn = CreateTopIconBtn("CloseBtn", Icons.Close, Colors.ControlBtn, Colors.CloseRed, 5, function()
  if window and window.OnClose then pcall(window.OnClose) end
  RaxorHub:ResetAllSettings()
  task.wait(0.1)
  ScreenGui:Destroy()
  end)
  AttachTooltip(closeBtn, "Close RaxorHub")

  local SearchContainer = InstNew("Frame")
  SearchContainer.Name = "SearchContainer"
  SearchContainer.Size = U2(1, -415, 0, 28)
  SearchContainer.Position = U2(0, 160, 0.5, -14)
  SearchContainer.BackgroundColor3 = Colors.InputBg
  SearchContainer.ZIndex = 32
  SearchContainer.Parent = TopBar
  AddCorner(SearchContainer, 6)
  local searchStroke = AddStroke(SearchContainer, Colors.Border, 1)

  local searchConstraint = InstNew("UISizeConstraint", SearchContainer)
  searchConstraint.MaxSize = V2(200, 28)
  searchConstraint.MinSize = V2(70, 28)

  local SearchIcon = InstNew("ImageLabel")
  SearchIcon.Size = U2(0, 14, 0, 14)
  SearchIcon.Position = U2(0, 8, 0.5, -7)
  SearchIcon.Image = Icons.Search
  SearchIcon.ImageColor3 = Colors.MutedText
  SearchIcon.BackgroundTransparency = 1
  SearchIcon.ZIndex = 33
  SearchIcon.Parent = SearchContainer

  local SearchInput = InstNew("TextBox")
  SearchInput.Size = U2(1, -30, 1, 0)
  SearchInput.Position = U2(0, 26, 0, 0)
  SearchInput.BackgroundTransparency = 1
  SearchInput.Text = ""
  SearchInput.PlaceholderText = "Search..."
  SearchInput.PlaceholderColor3 = Colors.MutedText
  SearchInput.TextColor3 = Colors.Text
  SearchInput.Font = Fonts.Regular
  SearchInput.TextSize = 12
  SearchInput.TextXAlignment = TXA_LEFT
  SearchInput.ClearTextOnFocus = false
  SearchInput.ZIndex = 33
  SearchInput.Parent = SearchContainer

  SearchInput.Focused:Connect(function() searchStroke.Color = Colors.Accent end)
  SearchInput.FocusLost:Connect(function() searchStroke.Color = Colors.Border end)

  ContentContainer = InstNew("Frame")
  ContentContainer.Name = "ContentContainer"
  ContentContainer.Active = true
  ContentContainer.Size = U2(1, -SidebarWidth, 1, -48)
  ContentContainer.Position = U2(0, SidebarWidth, 0, 48)
  ContentContainer.BackgroundTransparency = 1
  ContentContainer.BorderSizePixel = 0
  ContentContainer.ClipsDescendants = true
  ContentContainer.ZIndex = 25
  ContentContainer.Parent = MainFrame
  AddCorner(ContentContainer, 14)

  else
  TopBar = InstNew("Frame")
  TopBar.Name = "TopBar"
  TopBar.Active = true
  TopBar.Size = U2(1, 0, 0, 42)
  TopBar.Position = U2(0, 0, 0, 0)
  TopBar.BackgroundTransparency = 1
  TopBar.BorderSizePixel = 0
  TopBar.ZIndex = 30
  TopBar.Parent = MainFrame
  AddCorner(TopBar, 14)
  MakeDraggable(MainFrame, TopBar)

  local MobileLogo = InstNew("ImageLabel")
  MobileLogo.Size = U2(0, 22, 0, 22)
  MobileLogo.Position = U2(0, 12, 0.5, -11)
  MobileLogo.Image = GuiConfig.Logo or Icons.Logo
  MobileLogo.ImageColor3 = Colors.White
  MobileLogo.BackgroundTransparency = 1
  MobileLogo.ZIndex = 32
  MobileLogo.Parent = TopBar

  local MobileTitle = InstNew("TextLabel")
  MobileTitle.Text = string.upper(type(GuiConfig.Title) == "string" and GuiConfig.Title or "RAXOR")
  MobileTitle.Font = Fonts.Brand
  MobileTitle.TextSize = 14
  MobileTitle.TextColor3 = Colors.Text
  MobileTitle.Position = U2(0, 38, 0.5, -9)
  MobileTitle.Size = U2(0, 90, 0, 18)
  MobileTitle.TextXAlignment = TXA_LEFT
  MobileTitle.BackgroundTransparency = 1
  MobileTitle.ZIndex = 32
  MobileTitle.Parent = TopBar

  local Controls = InstNew("Frame")
  Controls.Name = "Controls"
  Controls.Size = U2(0, 190, 1, 0)
  Controls.Position = U2(1, -8, 0, 0)
  Controls.AnchorPoint = V2(1, 0)
  Controls.BackgroundTransparency = 1
  Controls.ZIndex = 35
  Controls.Parent = TopBar

  local ControlLayout = InstNew("UIListLayout")
  ControlLayout.FillDirection = FD_H
  ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
  ControlLayout.VerticalAlignment = VA_Center
  ControlLayout.Padding = UDim.new(0, 6)
  ControlLayout.SortOrder = SO_Layout
  ControlLayout.Parent = Controls

  local MobileLangSwitcher = InstNew("Frame")
  MobileLangSwitcher.Name = "MobileLangSwitcher"
  MobileLangSwitcher.LayoutOrder = 1
  MobileLangSwitcher.Size = U2(0, 72, 0, 26)
  MobileLangSwitcher.BackgroundColor3 = Colors.ControlBtn
  MobileLangSwitcher.ZIndex = 36
  MobileLangSwitcher.Parent = Controls
  AddCorner(MobileLangSwitcher, 6)
  AddStroke(MobileLangSwitcher, Colors.Border, 1)

  local mlangList = InstNew("UIListLayout", MobileLangSwitcher)
  mlangList.FillDirection = FD_H
  mlangList.SortOrder = SO_Layout

  local function CreateMobileLangBtn(langName, order)
  local btn = InstNew("TextButton")
  btn.Name = "Btn_" .. langName
  btn.LayoutOrder = order
  btn.Size = U2(0.5, 0, 1, 0)
  btn.AutoButtonColor = false
  btn.Text = langName
  btn.Font = Fonts.Title
  btn.TextSize = 11
  btn.BorderSizePixel = 0
  btn.ZIndex = 37
  btn.Parent = MobileLangSwitcher
  AddCorner(btn, 5)
  return btn
  end

  local mbtnTH = CreateMobileLangBtn("TH", 1)
  local mbtnEN = CreateMobileLangBtn("EN", 2)

  local function UpdateMobileLangBtnVisuals()
  local isTH = CurrentLanguage == "TH"
  mbtnTH.BackgroundColor3 = isTH and Colors.Accent or Colors.ControlBtn
  mbtnTH.BackgroundTransparency = isTH and 0 or 1
  mbtnTH.TextColor3 = isTH and Colors.White or Colors.SubText
  mbtnEN.BackgroundColor3 = not isTH and Colors.Accent or Colors.ControlBtn
  mbtnEN.BackgroundTransparency = not isTH and 0 or 1
  mbtnEN.TextColor3 = not isTH and Colors.White or Colors.SubText
  end

  mbtnTH.MouseButton1Click:Connect(function()
  PlayClickSound()
  RaxorHub:SetLanguage("TH")
  UpdateMobileLangBtnVisuals()
  end)
  mbtnTH.TouchTap:Connect(function()
  PlayClickSound()
  RaxorHub:SetLanguage("TH")
  UpdateMobileLangBtnVisuals()
  end)

  mbtnEN.MouseButton1Click:Connect(function()
  PlayClickSound()
  RaxorHub:SetLanguage("EN")
  UpdateMobileLangBtnVisuals()
  end)
  mbtnEN.TouchTap:Connect(function()
  PlayClickSound()
  RaxorHub:SetLanguage("EN")
  UpdateMobileLangBtnVisuals()
  end)

  UpdateMobileLangBtnVisuals()
  RefreshLangVisuals = UpdateMobileLangBtnVisuals
  RaxorHub.OnLanguageChanged = function()
  UpdateMobileLangBtnVisuals()
  end
  RegisterAccent(UpdateMobileLangBtnVisuals)

  local function CreateMobileIconBtn(name, iconId, baseColor, order, callback)
  local btn = InstNew("ImageButton")
  btn.Name = name
  btn.LayoutOrder = order + 1
  btn.Size = U2(0, 28, 0, 28)
  btn.BackgroundColor3 = baseColor or Colors.ControlBtn
  btn.Image = iconId or ""
  btn.ImageColor3 = Colors.White
  btn.AutoButtonColor = false
  btn.ZIndex = 36
  btn.Parent = Controls
  AddCorner(btn, 6)
  AddStroke(btn, Colors.Border, 1)
  local lastClick = 0
  local function fire()
  local now = tick()
  if now - lastClick < 0.15 then return end
  lastClick = now
  PlayClickSound()
  callback()
  end
  btn.Activated:Connect(fire)
  btn.MouseButton1Click:Connect(fire)
  btn.TouchTap:Connect(fire)
  return btn
  end

  CreateMobileIconBtn("FolderBtn", Icons.Folder, Colors.ControlBtn, 1, function()
  if PresetsModal then
  PresetsModal.Visible = not PresetsModal.Visible
  if PresetsModal.Visible and RaxorHub.RefreshPresetsList then
    RaxorHub.RefreshPresetsList()
  end
  end
  end)

  CreateMobileIconBtn("MinBtn", Icons.Minimize, Colors.ControlBtn, 2, function()
  if ToggleUI then ToggleUI() end
  end)

  CreateMobileIconBtn("CloseBtn", Icons.Close, Colors.CloseRed, 3, function()
  if window and window.OnClose then pcall(window.OnClose) end
  RaxorHub:ResetAllSettings()
  task.wait(0.1)
  ScreenGui:Destroy()
  end)

  local TopDivider = InstNew("Frame")
  TopDivider.Size = U2(1, 0, 0, 1)
  TopDivider.Position = U2(0, 0, 1, -1)
  TopDivider.BackgroundColor3 = Colors.Border
  TopDivider.BorderSizePixel = 0
  TopDivider.ZIndex = 31
  TopDivider.Parent = TopBar

  local MobileTabStrip = InstNew("Frame")
  MobileTabStrip.Name = "MobileTabStrip"
  MobileTabStrip.Size = U2(1, 0, 0, 42)
  MobileTabStrip.Position = U2(0, 0, 0, 42)
  MobileTabStrip.BackgroundColor3 = C3_RGB(15, 16, 22)
  MobileTabStrip.BorderSizePixel = 0
  MobileTabStrip.ZIndex = 32
  MobileTabStrip.Parent = MainFrame

  local MobileTabDivider = InstNew("Frame")
  MobileTabDivider.Name = "MobileTabDivider"
  MobileTabDivider.Size = U2(1, 0, 0, 1)
  MobileTabDivider.Position = U2(0, 0, 1, -1)
  MobileTabDivider.BackgroundColor3 = Colors.Border
  MobileTabDivider.BorderSizePixel = 0
  MobileTabDivider.ZIndex = 33
  MobileTabDivider.Parent = MobileTabStrip

  MobileTabBar = InstNew("ScrollingFrame")
  MobileTabBar.Name = "MobileTabBar"
  MobileTabBar.Active = true
  MobileTabBar.Size = U2(1, -20, 1, 0)
  MobileTabBar.Position = U2(0, 10, 0, 0)
  MobileTabBar.BackgroundTransparency = 1
  MobileTabBar.BorderSizePixel = 0
  MobileTabBar.ScrollBarThickness = 0
  MobileTabBar.ScrollingEnabled = true
  MobileTabBar.ScrollingDirection = Enum.ScrollingDirection.X
  MobileTabBar.ElasticBehavior = Enum.ElasticBehavior.Always
  MobileTabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
  MobileTabBar.CanvasSize = U2(0, 0, 0, 0)
  MobileTabBar.ZIndex = 34
  MobileTabBar.Parent = MobileTabStrip

  local MobileTabLayout = InstNew("UIListLayout")
  MobileTabLayout.FillDirection = FD_H
  MobileTabLayout.Padding = UDim.new(0, 8)
  MobileTabLayout.VerticalAlignment = VA_Center
  MobileTabLayout.SortOrder = SO_Layout
  MobileTabLayout.Parent = MobileTabBar

  ContentContainer = InstNew("Frame")
  ContentContainer.Name = "ContentContainer"
  ContentContainer.Active = true
  ContentContainer.Size = U2(1, 0, 1, -84)
  ContentContainer.Position = U2(0, 0, 0, 84)
  ContentContainer.BackgroundTransparency = 1
  ContentContainer.BorderSizePixel = 0
  ContentContainer.ClipsDescendants = true
  ContentContainer.ZIndex = 25
  ContentContainer.Parent = MainFrame
  AddCorner(ContentContainer, 14)
  end

  function window:AddTab(TabConfig)
  local tab = {CountSection = 0}
  local tabIconAsset = ResolveIcon(TabConfig.Icon)
  local tabNameRaw = TabConfig.Name or TabConfig.Title or "Tab"
  local tabNameStr = type(tabNameRaw) == "table" and (tabNameRaw.EN or tabNameRaw.TH or "Tab") or tostring(tabNameRaw)

  local Page = InstNew("ScrollingFrame")
  tab.Page = Page
  Page.Name = tabNameStr .. "_Page"
  Page.Active = true
  Page.Size = U2(1, 0, 1, 0)
  Page.BackgroundTransparency = 1
  Page.Visible = false
  Page.ScrollBarThickness = 4
  Page.ScrollBarImageColor3 = Colors.Accent
  Page.BorderSizePixel = 0
  Page.ScrollingEnabled = true
  Page.ScrollingDirection = Enum.ScrollingDirection.Y
  Page.ElasticBehavior = Enum.ElasticBehavior.Always
  Page.AutomaticCanvasSize = AutoY
  Page.CanvasSize = U2(0, 0, 0, 0)
  Page.ZIndex = 26
  Page.ClipsDescendants = true
  Page.Parent = ContentContainer

  local PagePadding = InstNew("UIPadding", Page)
  PagePadding.PaddingTop = UDim.new(0, 10)
  PagePadding.PaddingLeft = UDim.new(0, isMobile and 10 or 14)
  PagePadding.PaddingRight = UDim.new(0, isMobile and 12 or 16)
  PagePadding.PaddingBottom = UDim.new(0, isMobile and 16 or 24)

  local LeftColumn, RightColumn
  local UpdateTabVisuals = nil

  if not isMobile then
  local TabBtn = InstNew("TextButton")
  TabBtn.Size = U2(1, 0, 0, 38)
  TabBtn.LayoutOrder = TabConfig.LayoutOrder or window.CountTab
  TabBtn.BackgroundColor3 = Colors.CardActive
  TabBtn.BackgroundTransparency = 1
  TabBtn.AutoButtonColor = false
  TabBtn.Text = ""
  TabBtn.BorderSizePixel = 0
  TabBtn.ZIndex = 23
  TabBtn.Parent = SidebarScroll
  AddCorner(TabBtn, 6)

  local Indicator = InstNew("Frame")
  Indicator.Name = "Indicator"
  Indicator.Size = U2(0, 3, 0, 20)
  Indicator.Position = U2(0, 0, 0.5, -10)
  Indicator.BackgroundColor3 = Colors.Accent
  Indicator.BackgroundTransparency = 1
  Indicator.BorderSizePixel = 0
  Indicator.ZIndex = 24
  Indicator.Parent = TabBtn
  AddCorner(Indicator, 999)

  local TabContent = InstNew("Frame")
  TabContent.Name = "Frame"
  TabContent.Size = U2(1, 0, 1, 0)
  TabContent.BackgroundTransparency = 1
  TabContent.Parent = TabBtn

  local TabIcon = InstNew("ImageLabel")
  TabIcon.Name = "Icon"
  TabIcon.Size = U2(0, 18, 0, 18)
  TabIcon.Position = U2(0, 12, 0.5, -9)
  TabIcon.Image = tabIconAsset
  TabIcon.ImageColor3 = Colors.SubText
  TabIcon.BackgroundTransparency = 1
  TabIcon.ZIndex = 24
  TabIcon.Parent = TabContent

  local TabLabel = InstNew("TextLabel")
  TabLabel.Name = "Label"
  TabLabel.Text = ResolveText(tabNameRaw, CurrentLanguage)
  TabLabel.Size = U2(1, -44, 1, 0)
  TabLabel.Position = U2(0, 38, 0, 0)
  TabLabel.Font = Fonts.Medium
  TabLabel.TextSize = 13
  TabLabel.TextColor3 = Colors.SubText
  TabLabel.TextXAlignment = TXA_LEFT
  TabLabel.BackgroundTransparency = 1
  TabLabel.ZIndex = 24
  TabLabel.Parent = TabContent
  RegisterI18n(TabLabel, "Text", tabNameRaw)

  local PageLayout = InstNew("UIListLayout")
  PageLayout.Padding = UDim.new(0, 10)
  PageLayout.HorizontalAlignment = HA_Center
  PageLayout.SortOrder = SO_Layout
  PageLayout.Parent = Page

  UpdateTabVisuals = function()
  for _, b in pairs(SidebarScroll:GetChildren()) do
    if b:IsA("TextButton") then
    b.BackgroundTransparency = 1
    if b:FindFirstChild("Indicator") then b.Indicator.BackgroundTransparency = 1 end
    if b:FindFirstChild("Frame") and b.Frame:FindFirstChild("Label") then
      local isThaiTab = CurrentLanguage == "TH" or IsThaiText(b.Frame.Label.Text)
      b.Frame.Label.TextColor3 = isThaiTab and C3_RGB(180, 186, 200) or Colors.SubText
      b.Frame.Label.Font = Fonts.Title
      b.Frame.Label.TextSize = isThaiTab and 15 or 13
      if b.Frame:FindFirstChild("Icon") then
      b.Frame.Icon.ImageColor3 = Colors.SubText
      end
    end
    end
  end
  TabBtn.BackgroundTransparency = (MainFrame:GetAttribute("Wallpaper") and MainFrame:GetAttribute("Wallpaper") ~= "Default") and 0.28 or 0
  Indicator.BackgroundTransparency = 0
  TabLabel.TextColor3 = Colors.White
  TabLabel.Font = Fonts.Title
  local isThaiActive = CurrentLanguage == "TH" or IsThaiText(TabLabel.Text)
  TabLabel.TextSize = isThaiActive and 15 or 13
  TabIcon.ImageColor3 = Colors.Accent
  RaxorHub.ActivePage = Page
  RaxorHub.ActiveTabName = tabNameStr
  if TopBreadcrumb then
    local resolved = ResolveText(tabNameRaw, CurrentLanguage)
    TopBreadcrumb.Text = "| " .. resolved
    TopBreadcrumb.TextSize = (CurrentLanguage == "TH" or IsThaiText(resolved)) and 17 or 15
    TopBreadcrumb.Font = Fonts.Title
  end
  end

  local function ActivateTab()
  PlayClickSound()
  CloseAllDropdowns()
  for _, p in pairs(ContentContainer:GetChildren()) do
    if p:IsA("ScrollingFrame") then p.Visible = false end
  end
  UpdateTabVisuals()
  Page.Visible = true
  end

  TabBtn.MouseButton1Click:Connect(ActivateTab)
  TabBtn.TouchTap:Connect(ActivateTab)

  else
  local TabBtn = InstNew("TextButton")
  TabBtn.Name = tabNameStr .. "_TabBtn"
  TabBtn.Size = U2(0, 0, 0, 28)
  TabBtn.LayoutOrder = TabConfig.LayoutOrder or window.CountTab
  TabBtn.AutomaticSize = Enum.AutomaticSize.X
  TabBtn.BackgroundColor3 = Colors.CardBg
  TabBtn.BackgroundTransparency = (MainFrame:GetAttribute("Wallpaper") and MainFrame:GetAttribute("Wallpaper") ~= "Default") and 0.28 or 0
  TabBtn.AutoButtonColor = false
  TabBtn.Text = ""
  TabBtn.BorderSizePixel = 0
  TabBtn.ZIndex = 33
  TabBtn.Parent = MobileTabBar
  AddCorner(TabBtn, 6)
  local btnStroke = AddStroke(TabBtn, Colors.Border, 1)

  local btnPadding = InstNew("UIPadding", TabBtn)
  btnPadding.PaddingLeft = UDim.new(0, 10)
  btnPadding.PaddingRight = UDim.new(0, 10)

  local btnLayout = InstNew("UIListLayout", TabBtn)
  btnLayout.FillDirection = FD_H
  btnLayout.VerticalAlignment = VA_Center
  btnLayout.Padding = UDim.new(0, 6)

  local TabIcon = InstNew("ImageLabel")
  TabIcon.Name = "Icon"
  TabIcon.Size = U2(0, 14, 0, 14)
  TabIcon.Image = tabIconAsset
  TabIcon.ImageColor3 = Colors.SubText
  TabIcon.BackgroundTransparency = 1
  TabIcon.ZIndex = 34
  TabIcon.Parent = TabBtn

  local TabLabel = InstNew("TextLabel")
  TabLabel.Name = "Label"
  TabLabel.Text = ResolveText(tabNameRaw, CurrentLanguage)
  TabLabel.AutomaticSize = Enum.AutomaticSize.X
  TabLabel.Size = U2(0, 0, 1, 0)
  TabLabel.Font = Fonts.Medium
  TabLabel.TextSize = 12
  TabLabel.TextColor3 = Colors.SubText
  TabLabel.BackgroundTransparency = 1
  TabLabel.ZIndex = 34
  TabLabel.Parent = TabBtn
  RegisterI18n(TabLabel, "Text", tabNameRaw)

  local PageLayout = InstNew("UIListLayout")
  PageLayout.Padding = UDim.new(0, 8)
  PageLayout.HorizontalAlignment = HA_Center
  PageLayout.SortOrder = SO_Layout
  PageLayout.Parent = Page

  LeftColumn = Page
  RightColumn = Page

  UpdateTabVisuals = function()
  for _, b in pairs(MobileTabBar:GetChildren()) do
    if b:IsA("TextButton") then
    b.BackgroundColor3 = Colors.CardBg
    local stroke = b:FindFirstChildOfClass("UIStroke")
    if stroke then stroke.Color = Colors.Border end
    if b:FindFirstChild("Label") then
      b.Label.TextColor3 = Colors.SubText
      b.Label.Font = Fonts.Medium
    end
    if b:FindFirstChild("Icon") then
      b.Icon.ImageColor3 = Colors.SubText
    end
    end
  end
  TabBtn.BackgroundColor3 = Colors.CardActive
  btnStroke.Color = Colors.Accent
  TabLabel.TextColor3 = Colors.White
  TabLabel.Font = Fonts.Title
  TabIcon.ImageColor3 = Colors.Accent
  RaxorHub.ActivePage = Page
  end

  local function ActivateTab()
  PlayClickSound()
  CloseAllDropdowns()
  for _, p in pairs(ContentContainer:GetChildren()) do
    if p:IsA("ScrollingFrame") then p.Visible = false end
  end
  UpdateTabVisuals()
  Page.Visible = true
  end

  TabBtn.MouseButton1Click:Connect(ActivateTab)
  TabBtn.TouchTap:Connect(ActivateTab)
  end

  tab.LeftColumn = LeftColumn
  tab.RightColumn = RightColumn
  tab.LeftCount = 0
  tab.RightCount = 0
  table.insert(window.Tabs, tab)

  if window.CountTab == 0 then
  Page.Visible = true
  UpdateTabVisuals()
  end
  window.CountTab = window.CountTab + 1
  function tab:AddSection(Title, Description, IconID, Side)
  local titleStr, descStr, iconStr, sideArg = Title, Description, IconID, Side
  if type(Title) == "table" and not (Title.TH or Title.EN) then
    titleStr = Title.Title or Title.Name
    descStr = Title.Description or Title.Desc
    iconStr = Title.Icon or Title.IconID
    sideArg = Title.Side or Title.Type or Title.Position
  end

  local sectionItems = {}
  local SectionFrame = InstNew("Frame")
  SectionFrame.Name = "SectionFrame"
  SectionFrame.Size = U2(1, 0, 0, 50)
  SectionFrame.AutomaticSize = AutoY
  SectionFrame.BackgroundTransparency = 1
  SectionFrame.ZIndex = 27
  SectionFrame.ClipsDescendants = false
  tab.CountSection = tab.CountSection + 1

  local sideRaw = sideArg and tostring(sideArg):lower():gsub("%s+", "") or ""
  local isFull = (sideRaw == "full" or sideRaw == "both" or sideRaw == "center" or sideRaw == "fill" or sideRaw == "wide" or sideRaw == "row" or sideRaw == "top" or sideRaw == "bottom" or sideArg == 0)

  if isMobile then
    SectionFrame.LayoutOrder = tab.CountSection
    SectionFrame.Parent = Page
  elseif isFull then
    tab.ActiveDualRow = nil
    if sideRaw == "top" then
      SectionFrame.LayoutOrder = 0
    elseif sideRaw == "bottom" then
      SectionFrame.LayoutOrder = 9999
    else
      SectionFrame.LayoutOrder = tab.CountSection
    end
    SectionFrame.Parent = Page
  else
    local targetSide = "left"
    if sideRaw == "right" or sideArg == 2 then
      targetSide = "right"
    elseif sideRaw == "left" or sideArg == 1 then
      targetSide = "left"
    else
      if not tab.ActiveDualRow or tab.ActiveDualRow.LeftCount == 0 then
        targetSide = "left"
      elseif tab.ActiveDualRow.RightCount == 0 then
        targetSide = "right"
      else
        targetSide = (tab.ActiveDualRow.LeftCount <= tab.ActiveDualRow.RightCount) and "left" or "right"
      end
    end

    if not tab.ActiveDualRow then
      local DualRow = InstNew("Frame")
      DualRow.Name = "DualColumnsRow"
      DualRow.Size = U2(1, 0, 0, 0)
      DualRow.AutomaticSize = AutoY
      DualRow.BackgroundTransparency = 1
      DualRow.ZIndex = 27
      DualRow.LayoutOrder = tab.CountSection
      DualRow.Parent = Page

      local colLayout = InstNew("UIListLayout")
      colLayout.FillDirection = FD_H
      colLayout.Padding = UDim.new(0, 10)
      colLayout.HorizontalAlignment = HA_Center
      colLayout.VerticalAlignment = Enum.VerticalAlignment.Top
      colLayout.SortOrder = SO_Layout
      colLayout.Parent = DualRow

      local LeftCol = InstNew("Frame")
      LeftCol.Name = "LeftColumn"
      LeftCol.Size = U2(0.5, -5, 0, 0)
      LeftCol.AutomaticSize = AutoY
      LeftCol.BackgroundTransparency = 1
      LeftCol.ZIndex = 27
      LeftCol.LayoutOrder = 1
      LeftCol.Parent = DualRow
      local LeftLayout = InstNew("UIListLayout")
      LeftLayout.Padding = UDim.new(0, 8)
      LeftLayout.HorizontalAlignment = HA_Center
      LeftLayout.SortOrder = SO_Layout
      LeftLayout.Parent = LeftCol

      local RightCol = InstNew("Frame")
      RightCol.Name = "RightColumn"
      RightCol.Size = U2(0.5, -5, 0, 0)
      RightCol.AutomaticSize = AutoY
      RightCol.BackgroundTransparency = 1
      RightCol.ZIndex = 27
      RightCol.LayoutOrder = 2
      RightCol.Parent = DualRow
      local RightLayout = InstNew("UIListLayout")
      RightLayout.Padding = UDim.new(0, 8)
      RightLayout.HorizontalAlignment = HA_Center
      RightLayout.SortOrder = SO_Layout
      RightLayout.Parent = RightCol

      tab.ActiveDualRow = {
        Row = DualRow,
        LeftCol = LeftCol,
        RightCol = RightCol,
        LeftCount = 0,
        RightCount = 0
      }
    end

    local dRow = tab.ActiveDualRow
    if targetSide == "left" then
      SectionFrame.Parent = dRow.LeftCol
      dRow.LeftCount += 1
    else
      SectionFrame.Parent = dRow.RightCol
      dRow.RightCount += 1
    end
    SectionFrame.LayoutOrder = (targetSide == "left") and dRow.LeftCount or dRow.RightCount

    local function UpdateRowLayout()
      if dRow.LeftCount > 0 and dRow.RightCount > 0 then
        dRow.LeftCol.Size = U2(0.5, -5, 0, 0)
        dRow.LeftCol.Visible = true
        dRow.RightCol.Size = U2(0.5, -5, 0, 0)
        dRow.RightCol.Visible = true
      elseif dRow.LeftCount > 0 then
        dRow.LeftCol.Size = U2(1, 0, 0, 0)
        dRow.LeftCol.Visible = true
        dRow.RightCol.Visible = false
      elseif dRow.RightCount > 0 then
        dRow.RightCol.Size = U2(1, 0, 0, 0)
        dRow.RightCol.Visible = true
        dRow.LeftCol.Visible = false
      end
    end
    UpdateRowLayout()
    tab.UpdateColumns = UpdateRowLayout
    tab.LeftColumn = dRow.LeftCol
    tab.RightColumn = dRow.RightCol
  end

  sectionItems.Frame = SectionFrame
  function sectionItems:SetVisible(visible)
  SectionFrame.Visible = visible
  end

  local SectionLayout = InstNew("UIListLayout")
  SectionLayout.Padding = UDim.new(0, 6)
  SectionLayout.HorizontalAlignment = HA_Center
  SectionLayout.SortOrder = SO_Layout
  SectionLayout.Parent = SectionFrame

  local hasDesc = descStr and descStr ~= ""

  local HeaderHeight = hasDesc and 44 or 30
  local HeaderContainer = InstNew("Frame")
  HeaderContainer.Name = "HeaderContainer"
  HeaderContainer.Size = U2(1, -4, 0, HeaderHeight)
  HeaderContainer.BackgroundTransparency = 1
  HeaderContainer.BorderSizePixel = 0
  HeaderContainer.ZIndex = 28
  HeaderContainer.Parent = SectionFrame

  local TitleRow = InstNew("Frame")
  TitleRow.Name = "TitleRow"
  TitleRow.Size = U2(1, -20, 0, 20)
  TitleRow.Position = hasDesc and U2(0.5, 0, 0, 5) or U2(0.5, 0, 0.5, 0)
  TitleRow.AnchorPoint = hasDesc and V2(0.5, 0) or V2(0.5, 0.5)
  TitleRow.BackgroundTransparency = 1
  TitleRow.ZIndex = 29
  TitleRow.Parent = HeaderContainer

  local CenterBlock = InstNew("Frame")
  CenterBlock.Name = "CenterBlock"
  CenterBlock.Size = U2(0, 0, 1, 0)
  CenterBlock.AutomaticSize = Enum.AutomaticSize.X
  CenterBlock.Position = U2(0.5, 0, 0.5, 0)
  CenterBlock.AnchorPoint = V2(0.5, 0.5)
  CenterBlock.BackgroundTransparency = 1
  CenterBlock.ZIndex = 30
  CenterBlock.Parent = TitleRow

  local centerLayout = InstNew("UIListLayout", CenterBlock)
  centerLayout.FillDirection = FD_H
  centerLayout.HorizontalAlignment = HA_Center
  centerLayout.VerticalAlignment = VA_Center
  centerLayout.Padding = UDim.new(0, 6)

  if iconStr then
  local SecIcon = InstNew("ImageLabel")
  SecIcon.Size = U2(0, 16, 0, 16)
  SecIcon.Image = ResolveIcon(iconStr)
  SecIcon.BackgroundTransparency = 1
  SecIcon.ImageColor3 = Colors.AccentHover
  SecIcon.ZIndex = 31
  SecIcon.Parent = CenterBlock
  end

  local HeaderTitle = InstNew("TextLabel")
  HeaderTitle.Name = "HeaderTitle"
  HeaderTitle.AutomaticSize = Enum.AutomaticSize.X
  HeaderTitle.Size = U2(0, 0, 1, 0)
  HeaderTitle.Text = ResolveText(titleStr or "", CurrentLanguage)
  HeaderTitle.Font = Fonts.Title
  HeaderTitle.TextSize = 15
  HeaderTitle.TextColor3 = Colors.AccentHover
  HeaderTitle.TextXAlignment = Enum.TextXAlignment.Center
  HeaderTitle.BackgroundTransparency = 1
  HeaderTitle.ZIndex = 31
  HeaderTitle.Parent = CenterBlock
  RegisterI18n(HeaderTitle, "Text", titleStr)
  RegisterAccent(HeaderTitle, "TextColor3")

  local LeftLine = InstNew("Frame")
  LeftLine.Name = "LeftLine"
  LeftLine.Size = U2(0.24, 0, 0, 1)
  LeftLine.Position = U2(0, 0, 0.5, 0)
  LeftLine.AnchorPoint = V2(0, 0.5)
  LeftLine.BackgroundColor3 = Colors.Accent
  LeftLine.BorderSizePixel = 0
  LeftLine.ZIndex = 29
  LeftLine.Parent = TitleRow
  RegisterAccent(LeftLine, "BackgroundColor3")

  local leftGrad = InstNew("UIGradient", LeftLine)
  leftGrad.Transparency = NS_new({
  NSK_new(0, 0.85),
  NSK_new(1, 0.05)
  })

  local RightLine = InstNew("Frame")
  RightLine.Name = "RightLine"
  RightLine.Size = U2(0.24, 0, 0, 1)
  RightLine.Position = U2(1, 0, 0.5, 0)
  RightLine.AnchorPoint = V2(1, 0.5)
  RightLine.BackgroundColor3 = Colors.Accent
  RightLine.BorderSizePixel = 0
  RightLine.ZIndex = 29
  RightLine.Parent = TitleRow
  RegisterAccent(RightLine, "BackgroundColor3")

  local rightGrad = InstNew("UIGradient", RightLine)
  rightGrad.Transparency = NS_new({
  NSK_new(0, 0.05),
  NSK_new(1, 0.85)
  })

  local function UpdateLineGeometry()
  local rowW = TitleRow.AbsoluteSize.X
  local centerW = CenterBlock.AbsoluteSize.X
  if centerW <= 0 then
    local TextService = game:GetService("TextService")
    local sz = TextService:GetTextSize(ResolveText(titleStr or "", CurrentLanguage), 15, Fonts.Title, V2(1000, 1000))
    centerW = sz.X + (iconStr and 22 or 0)
  end
  if rowW > 0 and centerW > 0 then
    local halfW = math.ceil(centerW / 2)
    local lineLen = math.max(12, math.floor((rowW / 2) - halfW - 10))
    LeftLine.Size = U2(0, lineLen, 0, 1)
    RightLine.Size = U2(0, lineLen, 0, 1)
  end
  end

  CenterBlock:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateLineGeometry)
  TitleRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateLineGeometry)
  task.defer(UpdateLineGeometry)

  if hasDesc then
  local Desc = InstNew("TextLabel")
  Desc.Name = "HeaderDesc"
  Desc.Size = U2(1, -20, 0, 15)
  Desc.Position = U2(0.5, 0, 0, 25)
  Desc.AnchorPoint = V2(0.5, 0)
  Desc.Text = ResolveText(descStr or "", CurrentLanguage)
  Desc.Font = Fonts.Medium
  Desc.TextSize = 12
  Desc.TextColor3 = Colors.SubText
  Desc.TextXAlignment = Enum.TextXAlignment.Center
  Desc.BackgroundTransparency = 1
  Desc.ZIndex = 29
  Desc.Parent = HeaderContainer
  RegisterI18n(Desc, "Text", descStr)
  end

  SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
  SectionFrame.Size = U2(1, 0, 0, SectionLayout.AbsoluteContentSize.Y + 8)
  end)

  local function SetupRowText(row, title, desc, rightSpace)
  local hasRowDesc = desc and desc ~= ""
  local isFraction = type(rightSpace) == "number" and rightSpace <= 1
  local textWidth = isFraction and U2(1 - rightSpace, -16, 0, 22) or U2(1, -(rightSpace + 16), 0, 22)
  local TTitle = InstNew("TextLabel")
  TTitle.Name = "TTitle"
  TTitle.Text = ResolveText(title or "", CurrentLanguage)
  TTitle.Size = textWidth
  TTitle.Position = hasRowDesc and U2(0, 14, 0, 7) or U2(0, 14, 0.5, -11)
  TTitle.Font = Fonts.Title
  TTitle.TextSize = 13
  TTitle.TextColor3 = Colors.Text
  TTitle.TextXAlignment = TXA_LEFT
  TTitle.TextTruncate = TruncEnd
  TTitle.ClipsDescendants = false
  TTitle.BackgroundTransparency = 1
  TTitle.ZIndex = 30
  TTitle.Parent = row
  RegisterI18n(TTitle, "Text", title)

  if hasRowDesc then
    local TDesc = InstNew("TextLabel")
    TDesc.Name = "TDesc"
    TDesc.Text = ResolveText(desc, CurrentLanguage)
    TDesc.Size = textWidth
    TDesc.Position = U2(0, 14, 0, 29)
    TDesc.Font = Fonts.Medium
    TDesc.TextSize = 12
    TDesc.TextColor3 = Colors.SubText
    TDesc.TextXAlignment = TXA_LEFT
    TDesc.TextTruncate = TruncEnd
    TDesc.ClipsDescendants = false
    TDesc.BackgroundTransparency = 1
    TDesc.ZIndex = 30
    TDesc.Parent = row
    RegisterI18n(TDesc, "Text", desc)
  end
  end

  function sectionItems:AddToggleSwitch(Config)
  local Row = InstNew("Frame")
  Row.Name = "ToggleRow"
  Row.Size = SizeItem.BoxItem
  Row.BackgroundColor3 = Colors.CardBg
  Row.ZIndex = 28
  Row.Parent = SectionFrame
  AddCorner(Row, 10)
  AddStroke(Row, Colors.Border, 1)

  SetupRowText(Row, Config.Title, Config.Description, 80)

  local SwitchBg = InstNew("TextButton")
  SwitchBg.Name = "SwitchBg"
  SwitchBg.Size = U2(0, 44, 0, 22)
  SwitchBg.Position = U2(1, -56, 0.5, -11)
  SwitchBg.BackgroundColor3 = Config.Default and Colors.SwitchOn or Colors.SwitchOff
  SwitchBg.AutoButtonColor = false
  SwitchBg.Text = ""
  SwitchBg.ZIndex = 31
  SwitchBg.Parent = Row
  AddCorner(SwitchBg, 999)
  AddStroke(SwitchBg, Colors.Border, 1)

  local Knob = InstNew("Frame")
  Knob.Name = "Knob"
  Knob.Size = U2(0, 16, 0, 16)
  Knob.Position = Config.Default and U2(1, -19, 0.5, -8) or U2(0, 3, 0.5, -8)
  Knob.BackgroundColor3 = Config.Default and Colors.White or C3_RGB(200, 205, 220)
  Knob.ZIndex = 32
  Knob.Active = false
  Knob.Parent = SwitchBg
  AddCorner(Knob, 999)

  local state = Config.Default or false
  UpdateState(Config.ID, state)

  local function VisualUpdate(val)
    local targetPos = val and U2(1, -19, 0.5, -8) or U2(0, 3, 0.5, -8)
    local targetColor = val and Colors.SwitchOn or Colors.SwitchOff
    local knobColor = val and Colors.White or C3_RGB(200, 205, 220)
    Tween(Knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    Position = targetPos,
    BackgroundColor3 = knobColor
    })
    Tween(SwitchBg, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = targetColor})
  end

  local lastToggleTime = 0
  local function ToggleAction()
    local now = tick()
    if now - lastToggleTime < 0.12 then return end
    lastToggleTime = now
    PlayClickSound(state and 0.95 or 1.1)
    state = not state
    VisualUpdate(state)
    UpdateState(Config.ID, state)
    if Config.Callback then Config.Callback(state) end
  end

  SwitchBg.Activated:Connect(ToggleAction)
  SwitchBg.MouseButton1Click:Connect(ToggleAction)

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

  function sectionItems:AddSlider(Config)
  local Row = InstNew("Frame")
  Row.Size = SizeItem.BoxItem
  Row.BackgroundColor3 = Colors.CardBg
  Row.ZIndex = 28
  Row.Parent = SectionFrame
  AddCorner(Row, 10)
  AddStroke(Row, Colors.Border, 1)

  SetupRowText(Row, Config.Title, Config.Description, 0.48)

  local SliderContainer = InstNew("Frame")
  SliderContainer.Name = "SliderContainer"
  SliderContainer.AnchorPoint = V2(1, 0.5)
  SliderContainer.Size = U2(0.48, 0, 0, 36)
  SliderContainer.Position = U2(1, -12, 0.5, 0)
  SliderContainer.BackgroundTransparency = 1
  SliderContainer.ZIndex = 30
  SliderContainer.Parent = Row

  local sizeConstraint = InstNew("UISizeConstraint", SliderContainer)
  sizeConstraint.MinSize = V2(135, 36)
  sizeConstraint.MaxSize = V2(240, 36)

  local suffix = Config.Suffix or ""
  local currentVal = Config.Default or Config.Min

  local ValueBox = InstNew("TextBox")
  ValueBox.Name = "ValueBox"
  ValueBox.Size = U2(0, 68, 0, 20)
  ValueBox.AnchorPoint = V2(1, 0)
  ValueBox.Position = U2(1, 0, 0, 0)
  ValueBox.BackgroundColor3 = C3_RGB(24, 25, 35)
  ValueBox.BackgroundTransparency = 0.4
  ValueBox.Text = tostring(currentVal) .. suffix
  ValueBox.TextColor3 = Colors.Text
  ValueBox.Font = Fonts.Title
  ValueBox.TextSize = 12
  ValueBox.TextXAlignment = Enum.TextXAlignment.Center
  ValueBox.ClearTextOnFocus = false
  ValueBox.ZIndex = 31
  ValueBox.Parent = SliderContainer
  AddCorner(ValueBox, 4)
  local valueStroke = AddStroke(ValueBox, Colors.Border, 1)

  ValueBox.Focused:Connect(function()
    ValueBox.Text = tostring(currentVal)
    Tween(ValueBox, T_FAST, {BackgroundTransparency = 0})
    valueStroke.Color = Colors.Accent
  end)

  local SliderBack = InstNew("Frame")
  SliderBack.Size = U2(1, 0, 0, 6)
  SliderBack.Position = U2(0, 0, 0, 26)
  SliderBack.BackgroundColor3 = Colors.InputBg
  SliderBack.BorderSizePixel = 0
  SliderBack.ZIndex = 31
  SliderBack.Parent = SliderContainer
  AddCorner(SliderBack, 999)
  AddStroke(SliderBack, Colors.Border, 1)

  local initRatio = math.clamp(((Config.Default or Config.Min) - Config.Min) / (Config.Max - Config.Min), 0, 1)

  local SliderFill = InstNew("Frame")
  SliderFill.Size = U2(initRatio, 0, 1, 0)
  SliderFill.BackgroundColor3 = Colors.Accent
  SliderFill.BorderSizePixel = 0
  SliderFill.ZIndex = 32
  SliderFill.Parent = SliderBack
  AddCorner(SliderFill, 999)
  RegisterAccent(SliderFill, "BackgroundColor3")

  local Handle = InstNew("Frame")
  Handle.Size = U2(0, 14, 0, 14)
  Handle.AnchorPoint = V2(0.5, 0.5)
  Handle.Position = U2(initRatio, 0, 0.5, 0)
  Handle.BackgroundColor3 = Colors.White
  Handle.ZIndex = 33
  Handle.Active = true
  Handle.Parent = SliderBack
  AddCorner(Handle, 999)
  AddStroke(Handle, Colors.Accent, 1)

  local dragging = false
  UpdateState(Config.ID, Config.Default or Config.Min)

  local function VisualUpdate(val)
    currentVal = val
    local relativeX = math.clamp((val - Config.Min) / (Config.Max - Config.Min), 0, 1)
    SliderFill.Size = U2(relativeX, 0, 1, 0)
    Handle.Position = U2(relativeX, 0, 0.5, 0)
    if not ValueBox:IsFocused() then
    ValueBox.Text = tostring(val) .. suffix
    end
  end

  ValueBox.FocusLost:Connect(function()
    Tween(ValueBox, T_FAST, {BackgroundTransparency = 0.4})
    valueStroke.Color = Colors.Border
    local inputNum = tonumber(ValueBox.Text)
    if inputNum then
    local step = Config.Step or 1
    local value = math.floor((inputNum / step) + 0.5) * step
    value = math.clamp(value, Config.Min, Config.Max)
    VisualUpdate(value)
    UpdateState(Config.ID, value)
    if Config.Callback then Config.Callback(value) end
    else
    ValueBox.Text = tostring(currentVal) .. suffix
    end
  end)

  if Config.ID and RaxorHub.Objects then
    RaxorHub.Objects[Config.ID] = {
    Type = "Slider",
    Instance = SliderFill,
    Handle = Handle,
    Label = ValueBox,
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
    currentVal = value

    VisualUpdate(value)
    UpdateState(Config.ID, value)
    if Config.Callback then Config.Callback(value) end
  end

  SliderBack.Active = true
  Handle.Active = true

  SliderBack.InputBegan:Connect(function(input)
    if input.UserInputType == InpMB1 or input.UserInputType == InpTouch then
    dragging = true
    BlockCameraDrag()
    UpdateSlider(input)
    end
  end)

  Handle.InputBegan:Connect(function(input)
    if input.UserInputType == InpMB1 or input.UserInputType == InpTouch then
    dragging = true
    BlockCameraDrag()
    end
  end)

  UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == InpMB1 or input.UserInputType == InpTouch then
    if dragging then
      dragging = false
      UnblockCameraDrag()
    end
    end
  end)

  UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == InpTouch) then
    UpdateSlider(input)
    end
  end)
  end

  function sectionItems:AddDropdown(Config)
  local Row = InstNew("Frame")
  Row.Size = SizeItem.BoxItem
  Row.BackgroundColor3 = Colors.CardBg
  Row.ZIndex = 28
  Row.Parent = SectionFrame
  AddCorner(Row, 10)
  AddStroke(Row, Colors.Border, 1)

  SetupRowText(Row, Config.Title, Config.Description, 0.48)

  local Frame = InstNew("Frame")
  Frame.Name = "DropdownFrame"
  Frame.AnchorPoint = V2(1, 0.5)
  Frame.Size = U2(0.48, 0, 0, 30)
  Frame.Position = U2(1, -12, 0.5, 0)
  Frame.BackgroundColor3 = Colors.InputBg
  Frame.ZIndex = 30
  Frame.Parent = Row
  AddCorner(Frame, 6)
  AddStroke(Frame, Colors.BorderFocus, 1)

  local sizeConstraint = InstNew("UISizeConstraint", Frame)
  sizeConstraint.MinSize = V2(145, 30)
  sizeConstraint.MaxSize = V2(240, 30)

  local Label = InstNew("TextLabel")
  Label.Text = Config.Default or "Select..."
  Label.Size = U2(1, -36, 1, 0)
  Label.Position = U2(0, 10, 0, 0)
  Label.BackgroundTransparency = 1
  Label.TextColor3 = Colors.Text
  Label.Font = Fonts.Medium
  Label.TextSize = 12
  Label.TextXAlignment = TXA_LEFT
  Label.TextTruncate = TruncEnd
  Label.ClipsDescendants = true
  Label.ZIndex = 31
  Label.Parent = Frame

  local ArrowIcon = InstNew("ImageLabel")
  ArrowIcon.Image = Icons.ChevronDown
  ArrowIcon.Size = U2(0, 14, 0, 14)
  ArrowIcon.Position = U2(1, -22, 0.5, -7)
  ArrowIcon.BackgroundTransparency = 1
  ArrowIcon.ImageColor3 = Colors.SubText
  ArrowIcon.ZIndex = 32
  ArrowIcon.Parent = Frame

  local DropdownClickBtn = InstNew("TextButton")
  DropdownClickBtn.Size = U2(1, 0, 1, 0)
  DropdownClickBtn.BackgroundTransparency = 1
  DropdownClickBtn.Text = ""
  DropdownClickBtn.ZIndex = 33
  DropdownClickBtn.Parent = Frame

  local List = InstNew("Frame")
  List.Name = "DropdownList"
  List.BackgroundColor3 = Colors.DropdownBg
  List.ZIndex = 9500
  List.Visible = false
  List.ClipsDescendants = true
  List.Parent = MainFrame
  AddCorner(List, 6)
  AddStroke(List, Colors.BorderFocus, 1)

  local SearchBox = InstNew("TextBox")
  SearchBox.Size = U2(1, -10, 0, 26)
  SearchBox.Position = U2(0, 5, 0, 5)
  SearchBox.BackgroundColor3 = Colors.InputBg
  SearchBox.PlaceholderText = "Search..."
  SearchBox.PlaceholderColor3 = Colors.MutedText
  SearchBox.TextColor3 = Colors.Text
  SearchBox.Font = Fonts.Regular
  SearchBox.Text = ""
  SearchBox.TextSize = 11
  SearchBox.ZIndex = 9501
  SearchBox.Parent = List
  AddCorner(SearchBox, 4)
  AddStroke(SearchBox, Colors.Border, 1)

  local ItemScroll = InstNew("ScrollingFrame")
  ItemScroll.Size = U2(1, -8, 1, -38)
  ItemScroll.Position = U2(0, 4, 0, 35)
  ItemScroll.BackgroundTransparency = 1
  ItemScroll.BorderSizePixel = 0
  ItemScroll.ScrollBarThickness = 2
  ItemScroll.ScrollBarImageColor3 = Colors.Accent
  ItemScroll.ZIndex = 9501
  ItemScroll.Parent = List

  local ItemListLayout = InstNew("UIListLayout", ItemScroll)
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
    ItemScroll.CanvasSize = U2(0, 0, 0, contentHeight + 4)
    local dynamicHeight = math.clamp(contentHeight + 42, 70, 200)

    List.Size = U2(0, Frame.AbsoluteSize.X, 0, dynamicHeight)
    List.Position = U2(0, relX, 0, relY + Frame.AbsoluteSize.Y + 2)
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
      local itemBtn = InstNew("TextButton")
      itemBtn.Size = U2(1, -4, 0, 26)
      itemBtn.BorderSizePixel = 0
      itemBtn.AutoButtonColor = false
      itemBtn.Text = "  " .. tostring(item)
      itemBtn.Font = isSelected and Fonts.Title or Fonts.Medium
      itemBtn.TextSize = 12
      itemBtn.TextXAlignment = TXA_LEFT
      itemBtn.ZIndex = 9502
      itemBtn.BackgroundColor3 = isSelected and Colors.Accent or Colors.CardBg
      itemBtn.TextColor3 = isSelected and Colors.White or Colors.Text
      itemBtn.Parent = ItemScroll
      AddCorner(itemBtn, 4)

      itemBtn.Activated:Connect(function()
      PlayClickSound()
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
    local emptyMsg = InstNew("TextLabel")
    emptyMsg.Name = "EmptyMsg"
    emptyMsg.Size = U2(1, 0, 0, 26)
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

  DropdownClickBtn.Activated:Connect(function()
    PlayClickSound()
    if List.Visible then
    CloseAllDropdowns()
    else
    CloseAllDropdowns()
    List.Visible = true
    activeDropdownList = List
    activeDropdownArrow = ArrowIcon
    activeDropdownFrame = Frame
    Tween(ArrowIcon, TweenInfo.new(0.15), {Rotation = 180})
    ItemScroll.CanvasPosition = V2(0, 0)
    SearchBox.Text = ""
    Populate("")
    UpdateListPosition()
    activeDropdownSync = RunService.RenderStepped:Connect(UpdateListPosition)
    end
  end)

  return dropdownFunc
  end

  function sectionItems:AddMultiSelect(Config)
  local Row = InstNew("Frame")
  Row.Size = SizeItem.BoxItem
  Row.BackgroundColor3 = Colors.CardBg
  Row.ZIndex = 28
  Row.Parent = SectionFrame
  AddCorner(Row, 10)
  AddStroke(Row, Colors.Border, 1)

  SetupRowText(Row, Config.Title, Config.Description, 0.48)

  local Frame = InstNew("Frame")
  Frame.Name = "DropdownFrame"
  Frame.AnchorPoint = V2(1, 0.5)
  Frame.Size = U2(0.48, 0, 0, 30)
  Frame.Position = U2(1, -12, 0.5, 0)
  Frame.BackgroundColor3 = Colors.InputBg
  Frame.ZIndex = 30
  Frame.Parent = Row
  AddCorner(Frame, 6)
  AddStroke(Frame, Colors.BorderFocus, 1)

  local sizeConstraint = InstNew("UISizeConstraint", Frame)
  sizeConstraint.MinSize = V2(145, 30)
  sizeConstraint.MaxSize = V2(240, 30)

  local Label = InstNew("TextLabel")
  Label.Text = "None"
  Label.Size = U2(1, -36, 1, 0)
  Label.Position = U2(0, 10, 0, 0)
  Label.BackgroundTransparency = 1
  Label.TextColor3 = Colors.Text
  Label.Font = Fonts.Medium
  Label.TextSize = 12
  Label.TextXAlignment = TXA_LEFT
  Label.TextTruncate = TruncEnd
  Label.ClipsDescendants = true
  Label.ZIndex = 31
  Label.Parent = Frame

  local ArrowIcon = InstNew("ImageLabel")
  ArrowIcon.Image = Icons.ChevronDown
  ArrowIcon.Size = U2(0, 14, 0, 14)
  ArrowIcon.Position = U2(1, -22, 0.5, -7)
  ArrowIcon.BackgroundTransparency = 1
  ArrowIcon.ImageColor3 = Colors.SubText
  ArrowIcon.ZIndex = 32
  ArrowIcon.Parent = Frame

  local MultiClickBtn = InstNew("TextButton")
  MultiClickBtn.Size = U2(1, 0, 1, 0)
  MultiClickBtn.BackgroundTransparency = 1
  MultiClickBtn.Text = ""
  MultiClickBtn.ZIndex = 33
  MultiClickBtn.Parent = Frame

  local List = InstNew("Frame")
  List.Name = "MultiSelectList"
  List.BackgroundColor3 = Colors.DropdownBg
  List.ZIndex = 9500
  List.Visible = false
  List.ClipsDescendants = true
  List.Parent = MainFrame
  AddCorner(List, 6)
  AddStroke(List, Colors.BorderFocus, 1)

  local SearchBox = InstNew("TextBox")
  SearchBox.Size = U2(1, -10, 0, 26)
  SearchBox.Position = U2(0, 5, 0, 5)
  SearchBox.BackgroundColor3 = Colors.InputBg
  SearchBox.PlaceholderText = "Search..."
  SearchBox.PlaceholderColor3 = Colors.MutedText
  SearchBox.TextColor3 = Colors.Text
  SearchBox.Font = Fonts.Regular
  SearchBox.Text = ""
  SearchBox.TextSize = 11
  SearchBox.ZIndex = 9501
  SearchBox.Parent = List
  AddCorner(SearchBox, 4)
  AddStroke(SearchBox, Colors.Border, 1)

  local ItemScroll = InstNew("ScrollingFrame")
  ItemScroll.Size = U2(1, -8, 1, -38)
  ItemScroll.Position = U2(0, 4, 0, 35)
  ItemScroll.BackgroundTransparency = 1
  ItemScroll.BorderSizePixel = 0
  ItemScroll.ScrollBarThickness = 2
  ItemScroll.ScrollBarImageColor3 = Colors.Accent
  ItemScroll.ZIndex = 9501
  ItemScroll.Parent = List

  local ListLayout = InstNew("UIListLayout", ItemScroll)
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
    ItemScroll.CanvasSize = U2(0, 0, 0, contentHeight + 4)
    local dynamicHeight = math.clamp(contentHeight + 42, 70, 200)

    List.Size = U2(0, Frame.AbsoluteSize.X, 0, dynamicHeight)
    List.Position = U2(0, relX, 0, relY + Frame.AbsoluteSize.Y + 2)
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
      local itemBtn = InstNew("TextButton")
      itemBtn.Size = U2(1, -4, 0, 26)
      itemBtn.BorderSizePixel = 0
      itemBtn.AutoButtonColor = false
      itemBtn.Text = ""
      itemBtn.ZIndex = 9502
      itemBtn.BackgroundColor3 = isSelected and Colors.CardActive or Colors.CardBg
      itemBtn.Parent = ItemScroll
      AddCorner(itemBtn, 4)

      local checkIcon = InstNew("ImageLabel")
      checkIcon.Size = U2(0, 14, 0, 14)
      checkIcon.Position = U2(0, 6, 0.5, -7)
      checkIcon.Image = Icons.Checkmark
      checkIcon.ImageColor3 = Colors.Accent
      checkIcon.BackgroundTransparency = 1
      checkIcon.Visible = isSelected and true or false
      checkIcon.ZIndex = 9503
      checkIcon.Parent = itemBtn

      local tText = InstNew("TextLabel")
      tText.Size = U2(1, -28, 1, 0)
      tText.Position = U2(0, 26, 0, 0)
      tText.Text = tostring(item)
      tText.Font = isSelected and Fonts.Title or Fonts.Regular
      tText.TextSize = 12
      tText.TextColor3 = isSelected and Colors.White or Colors.Text
      tText.TextXAlignment = TXA_LEFT
      tText.BackgroundTransparency = 1
      tText.ZIndex = 9503
      tText.Parent = itemBtn

      itemBtn.Activated:Connect(function()
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
    local emptyMsg = InstNew("TextLabel")
    emptyMsg.Name = "EmptyMsg"
    emptyMsg.Size = U2(1, 0, 0, 26)
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

  MultiClickBtn.Activated:Connect(function()
    if List.Visible then
    CloseAllDropdowns()
    else
    CloseAllDropdowns()
    List.Visible = true
    activeDropdownList = List
    activeDropdownArrow = ArrowIcon
    activeDropdownFrame = Frame
    Tween(ArrowIcon, TweenInfo.new(0.15), {Rotation = 180})
    ItemScroll.CanvasPosition = V2(0, 0)
    SearchBox.Text = ""
    Populate("")
    UpdateListPosition()
    activeDropdownSync = RunService.RenderStepped:Connect(UpdateListPosition)
    end
  end)

  return multiFunc
  end

  function sectionItems:AddColorPicker(Config)
  local Row = InstNew("Frame")
  Row.Name = "ColorPickerRow"
  Row.Size = SizeItem.BoxItem
  Row.BackgroundColor3 = Colors.CardBg
  Row.ZIndex = 28
  Row.Parent = SectionFrame
  AddCorner(Row, 10)
  AddStroke(Row, Colors.Border, 1)

  SetupRowText(Row, Config.Title, Config.Description, 100)

  local currentColor = Config.Default or Colors.Accent
  local currentH, currentS, currentV = currentColor:ToHSV()
  UpdateState(Config.ID, currentColor)

  local ColorBox = InstNew("TextButton")
  ColorBox.Name = "ColorBoxBtn"
  ColorBox.Size = U2(0, 36, 0, 22)
  ColorBox.Position = U2(1, -48, 0.5, -11)
  ColorBox.BackgroundColor3 = currentColor
  ColorBox.Text = ""
  ColorBox.AutoButtonColor = false
  ColorBox.ZIndex = 30
  ColorBox.Parent = Row
  AddCorner(ColorBox, 5)
  AddStroke(ColorBox, Colors.BorderFocus, 1)

  local PickerModal = InstNew("Frame")
  PickerModal.Name = "ColorPickerModal"
  PickerModal.Size = U2(0, 220, 0, 242)
  PickerModal.BackgroundColor3 = Colors.ModalBg
  PickerModal.Visible = false
  PickerModal.ZIndex = 7500
  PickerModal.ClipsDescendants = true
  PickerModal.Parent = MainFrame
  AddCorner(PickerModal, 8)
  AddStroke(PickerModal, Colors.BorderFocus, 1.2)

  local PickerTitle = InstNew("TextLabel")
  PickerTitle.Text = ResolveText(Config.Title or "Color Picker", CurrentLanguage)
  PickerTitle.Font = Fonts.Title
  PickerTitle.TextSize = 12
  PickerTitle.TextColor3 = Colors.Text
  PickerTitle.Size = U2(1, -38, 0, 20)
  PickerTitle.Position = U2(0, 10, 0, 5)
  PickerTitle.TextXAlignment = TXA_LEFT
  PickerTitle.BackgroundTransparency = 1
  PickerTitle.ZIndex = 7501
  PickerTitle.Parent = PickerModal

  local ClosePickerBtn = InstNew("ImageButton")
  ClosePickerBtn.Size = U2(0, 16, 0, 16)
  ClosePickerBtn.Position = U2(1, -24, 0, 7)
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

  local svCanvas = InstNew("TextButton")
  svCanvas.Name = "SVCanvas"
  svCanvas.Size = U2(1, -20, 0, 116)
  svCanvas.Position = U2(0, 10, 0, 27)
  svCanvas.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
  svCanvas.BorderSizePixel = 0
  svCanvas.AutoButtonColor = false
  svCanvas.Text = ""
  svCanvas.ClipsDescendants = true
  svCanvas.ZIndex = 7501
  svCanvas.Parent = PickerModal
  AddCorner(svCanvas, 6)
  AddStroke(svCanvas, Colors.Border, 1)

  local whiteOverlay = InstNew("Frame")
  whiteOverlay.Size = U2(1, 0, 1, 0)
  whiteOverlay.BackgroundColor3 = Color3.new(1, 1, 1)
  whiteOverlay.BorderSizePixel = 0
  whiteOverlay.ZIndex = 7502
  whiteOverlay.Parent = svCanvas
  local whiteGrad = InstNew("UIGradient", whiteOverlay)
  whiteGrad.Rotation = 0
  whiteGrad.Transparency = NS_new({
    NSK_new(0, 0),
    NSK_new(1, 1)
  })

  local blackOverlay = InstNew("Frame")
  blackOverlay.Size = U2(1, 0, 1, 0)
  blackOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
  blackOverlay.BorderSizePixel = 0
  blackOverlay.ZIndex = 7503
  blackOverlay.Parent = svCanvas
  local blackGrad = InstNew("UIGradient", blackOverlay)
  blackGrad.Rotation = 90
  blackGrad.Transparency = NS_new({
    NSK_new(0, 1),
    NSK_new(1, 0)
  })

  local svCursor = InstNew("Frame")
  svCursor.Name = "Cursor"
  svCursor.Size = U2(0, 12, 0, 12)
  svCursor.AnchorPoint = V2(0.5, 0.5)
  svCursor.Position = U2(currentS, 0, 1 - currentV, 0)
  svCursor.BackgroundColor3 = currentColor
  svCursor.BorderSizePixel = 0
  svCursor.ZIndex = 7505
  svCursor.Parent = svCanvas
  AddCorner(svCursor, 999)
  AddStroke(svCursor, Color3.new(1, 1, 1), 2)

  local hueBar = InstNew("TextButton")
  hueBar.Name = "HueBar"
  hueBar.Size = U2(1, -20, 0, 14)
  hueBar.Position = U2(0, 10, 0, 149)
  hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
  hueBar.BorderSizePixel = 0
  hueBar.AutoButtonColor = false
  hueBar.Text = ""
  hueBar.ClipsDescendants = false
  hueBar.ZIndex = 7501
  hueBar.Parent = PickerModal
  AddCorner(hueBar, 7)
  AddStroke(hueBar, Colors.Border, 1)

  local hueGrad = InstNew("UIGradient", hueBar)
  hueGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0/6, 1, 1)),
    ColorSequenceKeypoint.new(0.17, Color3.fromHSV(1/6, 1, 1)),
    ColorSequenceKeypoint.new(0.33, Color3.fromHSV(2/6, 1, 1)),
    ColorSequenceKeypoint.new(0.50, Color3.fromHSV(3/6, 1, 1)),
    ColorSequenceKeypoint.new(0.67, Color3.fromHSV(4/6, 1, 1)),
    ColorSequenceKeypoint.new(0.83, Color3.fromHSV(5/6, 1, 1)),
    ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1.0, 1, 1))
  })

  local hueCursor = InstNew("Frame")
  hueCursor.Name = "HueCursor"
  hueCursor.Size = U2(0, 8, 0, 18)
  hueCursor.AnchorPoint = V2(0.5, 0.5)
  hueCursor.Position = U2(currentH, 0, 0.5, 0)
  hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
  hueCursor.BorderSizePixel = 0
  hueCursor.ZIndex = 7505
  hueCursor.Parent = hueBar
  AddCorner(hueCursor, 4)
  AddStroke(hueCursor, C3_RGB(30, 32, 40), 1.5)

  local InfoRow = InstNew("Frame")
  InfoRow.Size = U2(1, -20, 0, 22)
  InfoRow.Position = U2(0, 10, 0, 171)
  InfoRow.BackgroundTransparency = 1
  InfoRow.ZIndex = 7501
  InfoRow.Parent = PickerModal

  local PreviewBox = InstNew("Frame")
  PreviewBox.Size = U2(0, 22, 0, 22)
  PreviewBox.Position = U2(0, 0, 0, 0)
  PreviewBox.BackgroundColor3 = currentColor
  PreviewBox.BorderSizePixel = 0
  PreviewBox.ZIndex = 7502
  PreviewBox.Parent = InfoRow
  AddCorner(PreviewBox, 4)
  AddStroke(PreviewBox, Colors.BorderFocus, 1)

  local HexInput = InstNew("TextBox")
  HexInput.Size = U2(0, 72, 0, 22)
  HexInput.Position = U2(0, 28, 0, 0)
  HexInput.BackgroundColor3 = Colors.InputBg
  HexInput.Text = "#" .. currentColor:ToHex():upper()
  HexInput.Font = Fonts.Code
  HexInput.TextSize = 11
  HexInput.TextColor3 = Colors.Text
  HexInput.ClearTextOnFocus = false
  HexInput.ZIndex = 7502
  HexInput.Parent = InfoRow
  AddCorner(HexInput, 4)
  AddStroke(HexInput, Colors.Border, 1)

  local RGBLabel = InstNew("TextLabel")
  RGBLabel.Size = U2(1, -106, 0, 22)
  RGBLabel.Position = U2(0, 106, 0, 0)
  RGBLabel.BackgroundTransparency = 1
  RGBLabel.Font = Fonts.Code
  RGBLabel.TextSize = 10
  RGBLabel.TextColor3 = Colors.SubText
  RGBLabel.TextXAlignment = Enum.TextXAlignment.Right
  RGBLabel.Text = string.format("R:%d G:%d B:%d", math.round(currentColor.R * 255), math.round(currentColor.G * 255), math.round(currentColor.B * 255))
  RGBLabel.ZIndex = 7502
  RGBLabel.Parent = InfoRow

  local PaletteRow = InstNew("Frame")
  PaletteRow.Size = U2(1, -20, 0, 24)
  PaletteRow.Position = U2(0, 10, 0, 202)
  PaletteRow.BackgroundTransparency = 1
  PaletteRow.ZIndex = 7501
  PaletteRow.Parent = PickerModal

  local PaletteLayout = InstNew("UIListLayout", PaletteRow)
  PaletteLayout.FillDirection = FD_H
  PaletteLayout.HorizontalAlignment = HA_Center
  PaletteLayout.Padding = UDim.new(0, 7)

  local presets = {
    C3_RGB(124, 92, 252),    C3_RGB(56, 150, 255),
    C3_RGB(46, 213, 115),
    C3_RGB(255, 177, 66),
    C3_RGB(255, 71, 87),
    C3_RGB(255, 107, 181), -- Hot Pink
    C3_RGB(255, 255, 255)
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
    local dot = InstNew("TextButton")
    dot.Size = U2(0, 18, 0, 18)
    dot.BackgroundColor3 = pColor
    dot.Text = ""
    dot.AutoButtonColor = false
    dot.ZIndex = 7502
    dot.Parent = PaletteRow
    AddCorner(dot, 999)
    AddStroke(dot, Colors.Border, 1)

    dot.MouseButton1Click:Connect(function()
      PlayClickSound()
      currentH, currentS, currentV = pColor:ToHSV()
      svCanvas.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
      svCursor.Position = U2(currentS, 0, 1 - currentV, 0)
      hueCursor.Position = U2(currentH, 0, 0.5, 0)
      ApplyColorChange()
    end)
  end

  HexInput.FocusLost:Connect(function()
    local text = HexInput.Text:gsub("#", ""):gsub("%s+", "")
    if #text == 6 then
    local ok, parsed = pcall(function() return Color3.fromHex(text) end)
    if ok and parsed then
      currentH, currentS, currentV = parsed:ToHSV()
      svCanvas.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
      svCursor.Position = U2(currentS, 0, 1 - currentV, 0)
      hueCursor.Position = U2(currentH, 0, 0.5, 0)
      ApplyColorChange(true)
    else
      HexInput.Text = "#" .. currentColor:ToHex():upper()
    end
    else
    HexInput.Text = "#" .. currentColor:ToHex():upper()
    end
  end)

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
    svCursor.Position = U2(currentS, 0, 1 - currentV, 0)
    ApplyColorChange()
    end
  end

  local function UpdateHue(inputPos)
    local barPos = hueBar.AbsolutePosition
    local barSize = hueBar.AbsoluteSize
    if barSize.X > 0 then
    local relX = math.clamp((inputPos.X - barPos.X) / barSize.X, 0, 1)
    currentH = relX
    hueCursor.Position = U2(currentH, 0, 0.5, 0)
    svCanvas.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
    ApplyColorChange()
    end
  end

  svCanvas.InputBegan:Connect(function(input)
    if input.UserInputType == InpMB1 or input.UserInputType == InpTouch then
    isDraggingSV = true
    UpdateSV(input.Position)
    end
  end)

  hueBar.InputBegan:Connect(function(input)
    if input.UserInputType == InpMB1 or input.UserInputType == InpTouch then
    isDraggingHue = true
    UpdateHue(input.Position)
    end
  end)

  UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == InpTouch then
    if isDraggingSV then
      UpdateSV(input.Position)
    elseif isDraggingHue then
      UpdateHue(input.Position)
    end
    end
  end)

  UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == InpMB1 or input.UserInputType == InpTouch then
    isDraggingSV = false
    isDraggingHue = false
    end
  end)

  local function ToggleColorPicker()
    PlayClickSound()
    if PickerModal.Visible then
      PickerModal.Visible = false
      activeColorPicker = nil
      isDraggingSV = false
      isDraggingHue = false
    else
      CloseAllDropdowns()
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

      PickerModal.Position = U2(0, targetX, 0, targetY)
      task.defer(function()
        PickerModal.Visible = true
        activeColorPicker = PickerModal
      end)
    end
  end
  BindClick(ColorBox, ToggleColorPicker)

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
      svCursor.Position = U2(currentS, 0, 1 - currentV, 0)
      svCursor.BackgroundColor3 = currentColor
      hueCursor.Position = U2(currentH, 0, 0.5, 0)
      HexInput.Text = "#" .. currentColor:ToHex():upper()
      RGBLabel.Text = string.format("R:%d G:%d B:%d", math.round(currentColor.R * 255), math.round(currentColor.G * 255), math.round(currentColor.B * 255))
      end
    end,
    Callback = Config.Callback or function() end
    }
  end
  end

  function sectionItems:AddInput(Config)
  local Row = InstNew("Frame")
  Row.Size = SizeItem.BoxItem
  Row.BackgroundColor3 = Colors.CardBg
  Row.ZIndex = 28
  Row.Parent = SectionFrame
  AddCorner(Row, 10)
  AddStroke(Row, Colors.Border, 1)

  SetupRowText(Row, Config.Title, Config.Description, 0.48)

  local InputFrame = InstNew("Frame")
  InputFrame.Name = "InputFrame"
  InputFrame.AnchorPoint = V2(1, 0.5)
  InputFrame.Size = U2(0.48, 0, 0, 30)
  InputFrame.Position = U2(1, -12, 0.5, 0)
  InputFrame.BackgroundColor3 = Colors.InputBg
  InputFrame.ClipsDescendants = true
  InputFrame.ZIndex = 30
  InputFrame.Parent = Row
  AddCorner(InputFrame, 6)
  local stroke = AddStroke(InputFrame, Colors.BorderFocus, 1)

  local sizeConstraint = InstNew("UISizeConstraint", InputFrame)
  sizeConstraint.MinSize = V2(145, 30)
  sizeConstraint.MaxSize = V2(240, 30)

  local TextBox = InstNew("TextBox")
  TextBox.Size = U2(1, -16, 1, 0)
  TextBox.Position = U2(0, 8, 0, 0)
  TextBox.BackgroundTransparency = 1
  TextBox.Text = Config.Default or ""
  TextBox.PlaceholderText = ResolveText(Config.Placeholder or "Input...", CurrentLanguage)
  TextBox.PlaceholderColor3 = Colors.MutedText
  TextBox.TextColor3 = Colors.Text
  TextBox.TextSize = 12
  TextBox.Font = Fonts.Regular
  TextBox.TextXAlignment = TXA_LEFT
  TextBox.ClearTextOnFocus = false
  TextBox.ZIndex = 31
  TextBox.Parent = InputFrame
  RegisterI18n(TextBox, "PlaceholderText", Config.Placeholder or "Input...")

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

  function sectionItems:AddButton(Config)
  local Row = InstNew("Frame")
  Row.Size = SizeItem.BoxItem
  Row.BackgroundColor3 = Colors.CardBg
  Row.ZIndex = 28
  Row.Parent = SectionFrame
  AddCorner(Row, 10)
  AddStroke(Row, Colors.Border, 1)

  local btnText = Config.ButtonText or "Execute"
  local resolvedBtnText = ResolveText(btnText, CurrentLanguage)
  local TextService = game:GetService("TextService")
  local textW = TextService:GetTextSize(resolvedBtnText, 12, Fonts.Title, V2(1000, 1000)).X
  local btnW = math.clamp(textW + 28, 70, 120)
  SetupRowText(Row, Config.Title, Config.Description, btnW + 22)

  local Button = InstNew("TextButton")
  Button.Name = "RaxorButton"
  Button.Size = U2(0, btnW, 0, 30)
  Button.Position = U2(1, -(btnW + 14), 0.5, -15)
  Button.BackgroundColor3 = Colors.ButtonBg
  Button.AutoButtonColor = false
  Button.Text = resolvedBtnText
  Button.Font = Fonts.Title
  Button.TextSize = 12
  Button.TextColor3 = Colors.Text
  Button.ZIndex = 31
  Button.Parent = Row
  RegisterI18n(Button, "Text", btnText)
  AddCorner(Button, 6)
  AddStroke(Button, Colors.BorderFocus, 1)

  Button.MouseEnter:Connect(function()
    Tween(Button, T_FAST, {BackgroundColor3 = Colors.ButtonHover})
  end)
  Button.MouseLeave:Connect(function()
    Tween(Button, T_FAST, {BackgroundColor3 = Colors.ButtonBg})
  end)
  Button.MouseButton1Down:Connect(function()
    Tween(Button, TweenInfo.new(0.08), {BackgroundColor3 = Colors.Accent})
  end)
  Button.MouseButton1Up:Connect(function()
    Tween(Button, TweenInfo.new(0.08), {BackgroundColor3 = Colors.ButtonHover})
  end)
  Button.Activated:Connect(function()
    PlayClickSound()
    if Config.Callback then Config.Callback() end
  end)

  return Button
  end

  function sectionItems:AddLabel(Title)
  local Row = InstNew("Frame")
  Row.Size = U2(1, -4, 0, 32)
  Row.BackgroundColor3 = C3_RGB(20, 21, 29)
  Row.BorderSizePixel = 0
  Row.ZIndex = 28
  Row.Parent = SectionFrame
  AddCorner(Row, 10)
  local stroke = AddStroke(Row, Colors.BorderFocus, 1)
  stroke.Transparency = 0.5

  local Accent = InstNew("Frame")
  Accent.Size = U2(0, 3, 1, -12)
  Accent.Position = U2(0, 8, 0.5, 0)
  Accent.AnchorPoint = V2(0, 0.5)
  Accent.BackgroundColor3 = Colors.Accent
  Accent.BorderSizePixel = 0
  Accent.ZIndex = 29
  Accent.Parent = Row
  AddCorner(Accent, 999)

  local TTitle = InstNew("TextLabel")
  TTitle.Text = ResolveText(Title, CurrentLanguage)
  TTitle.Size = U2(1, -26, 1, 0)
  TTitle.Position = U2(0, 18, 0, 0)
  TTitle.Font = Fonts.Medium
  TTitle.TextSize = 12
  TTitle.TextColor3 = Colors.Text
  TTitle.TextXAlignment = TXA_LEFT
  TTitle.TextWrapped = true
  TTitle.BackgroundTransparency = 1
  TTitle.ZIndex = 29
  TTitle.Parent = Row
  RegisterI18n(TTitle, "Text", Title)

  local labelFunc = {}
  function labelFunc:Set(newText)
    for _, item in ipairs(I18nRegistry) do
      if item.Instance == TTitle and item.Property == "Text" then
        item.Source = newText
        break
      end
    end
    TTitle.Text = ResolveText(newText, CurrentLanguage)
  end
  function labelFunc:SetColor(color)
    Accent.BackgroundColor3 = color
    TTitle.TextColor3 = color
  end
  return labelFunc
  end

  function sectionItems:AddLogBox(Config)
  Config = Config or {}
  local boxHeight = Config.Height or 170
  local maxEntries = Config.MaxEntries or 80
  local entriesList = {}

  local Container = InstNew("Frame")
  Container.Name = "RaxorLogBox"
  Container.Size = U2(1, -4, 0, boxHeight + 46)
  Container.BackgroundColor3 = Colors.CardBg
  Container.ZIndex = 28
  Container.Parent = SectionFrame
  AddCorner(Container, 6)
  AddStroke(Container, Colors.Border, 1)

  local Header = InstNew("Frame")
  Header.Name = "LogHeader"
  Header.Size = U2(1, -16, 0, 32)
  Header.Position = U2(0, 8, 0, 4)
  Header.BackgroundTransparency = 1
  Header.ZIndex = 29
  Header.Parent = Container

  local HeaderAccent = InstNew("Frame")
  HeaderAccent.Size = U2(0, 3, 0, 14)
  HeaderAccent.Position = U2(0, 0, 0.5, -7)
  HeaderAccent.BackgroundColor3 = Colors.Accent
  HeaderAccent.BorderSizePixel = 0
  HeaderAccent.ZIndex = 30
  HeaderAccent.Parent = Header
  AddCorner(HeaderAccent, 999)

  local TitleLabel = InstNew("TextLabel")
  TitleLabel.Text = ResolveText(Config.Title or "Activity Log", CurrentLanguage)
  TitleLabel.Font = Fonts.Title
  TitleLabel.TextSize = 13
  TitleLabel.TextColor3 = Colors.Text
  TitleLabel.Size = U2(1, -140, 1, 0)
  TitleLabel.Position = U2(0, 10, 0, 0)
  TitleLabel.TextXAlignment = TXA_LEFT
  TitleLabel.BackgroundTransparency = 1
  TitleLabel.ZIndex = 30
  TitleLabel.Parent = Header

  local CounterBadge = InstNew("TextLabel")
  CounterBadge.Text = "(0)"
  CounterBadge.Font = Fonts.Medium
  CounterBadge.TextSize = 11
  CounterBadge.TextColor3 = Colors.SubText
  CounterBadge.Size = U2(0, 45, 1, 0)
  CounterBadge.Position = U2(0, 10 + TitleLabel.TextBounds.X + 8, 0, 0)
  CounterBadge.TextXAlignment = TXA_LEFT
  CounterBadge.BackgroundTransparency = 1
  CounterBadge.ZIndex = 30
  CounterBadge.Parent = Header

  TitleLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
    CounterBadge.Position = U2(0, 10 + TitleLabel.TextBounds.X + 8, 0, 0)
  end)

  local ClearBtn = InstNew("TextButton")
  ClearBtn.Name = "ClearBtn"
  ClearBtn.Size = U2(0, 60, 0, 22)
  ClearBtn.Position = U2(1, -60, 0.5, -11)
  ClearBtn.BackgroundColor3 = Colors.ButtonBg
  ClearBtn.AutoButtonColor = false
  ClearBtn.Text = "Clear"
  ClearBtn.Font = Fonts.Medium
  ClearBtn.TextSize = 11
  ClearBtn.TextColor3 = Colors.SubText
  ClearBtn.ZIndex = 31
  ClearBtn.Parent = Header
  AddCorner(ClearBtn, 4)
  AddStroke(ClearBtn, Colors.Border, 1)

  ClearBtn.MouseEnter:Connect(function()
    Tween(ClearBtn, T_FAST, {BackgroundColor3 = Colors.ButtonHover, TextColor3 = Colors.White})
  end)
  ClearBtn.MouseLeave:Connect(function()
    Tween(ClearBtn, T_FAST, {BackgroundColor3 = Colors.ButtonBg, TextColor3 = Colors.SubText})
  end)

  local Scroll = InstNew("ScrollingFrame")
  Scroll.Name = "LogScroll"
  Scroll.Size = U2(1, -16, 0, boxHeight)
  Scroll.Position = U2(0, 8, 0, 38)
  Scroll.BackgroundColor3 = C3_RGB(17, 18, 23)
  Scroll.BorderSizePixel = 0
  Scroll.ScrollBarThickness = 3
  Scroll.ScrollBarImageColor3 = Colors.BorderFocus
  Scroll.CanvasSize = U2(0, 0, 0, 0)
  Scroll.AutomaticCanvasSize = AutoY
  Scroll.ZIndex = 29
  Scroll.Parent = Container
  AddCorner(Scroll, 4)
  AddStroke(Scroll, Colors.Border, 1)

  local ScrollPadding = InstNew("UIPadding", Scroll)
  ScrollPadding.PaddingTop = UDim.new(0, 4)
  ScrollPadding.PaddingBottom = UDim.new(0, 4)
  ScrollPadding.PaddingLeft = UDim.new(0, 4)
  ScrollPadding.PaddingRight = UDim.new(0, 4)

  local LogLayout = InstNew("UIListLayout", Scroll)
  LogLayout.SortOrder = SO_Layout
  LogLayout.Padding = UDim.new(0, 4)

  local EmptyLabel = InstNew("TextLabel")
  EmptyLabel.Name = "EmptyLabel"
  EmptyLabel.Size = U2(1, 0, 1, 0)
  EmptyLabel.Text = ResolveText(Config.EmptyText or "No log records yet (Waiting for activity...)", CurrentLanguage)
  EmptyLabel.Font = Fonts.Regular
  EmptyLabel.TextSize = 11
  EmptyLabel.TextColor3 = Colors.MutedText
  EmptyLabel.TextXAlignment = Enum.TextXAlignment.Center
  EmptyLabel.BackgroundTransparency = 1
  EmptyLabel.ZIndex = 30
  EmptyLabel.Parent = Scroll

  local function UpdateCounter()
    pcall(function()
    if CounterBadge and CounterBadge.Parent then
      CounterBadge.Text = "(" .. tostring(#entriesList) .. ")"
    end
    if EmptyLabel and EmptyLabel.Parent then
      EmptyLabel.Visible = (#entriesList == 0)
    end
    end)
  end

  local RarityColors = {
    ["Divine"]    = C3_RGB(255, 220, 80),
    ["Secret"]    = C3_RGB(235, 90, 255),
    ["Mythic"]    = C3_RGB(255, 68, 85),
    ["Legendary"] = C3_RGB(255, 170, 40),
    ["Epic"]      = C3_RGB(180, 100, 255),
    ["Rare"]      = C3_RGB(80, 165, 255),
    ["Uncommon"]  = C3_RGB(100, 225, 120),
    ["Common"]    = C3_RGB(180, 185, 195)
  }

  local logObj = {}

  function logObj:AddEntry(data)
    pcall(function()
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
    local item = InstNew("Frame")
    item.Name = "Entry_" .. tostring(order)
    item.Size = U2(1, -2, 0, 28)
    item.LayoutOrder = -order -- Newest on top!
    item.BackgroundColor3 = C3_RGB(22, 23, 31)
    item.ZIndex = 30
    item.Parent = Scroll
    AddCorner(item, 4)
    AddStroke(item, Colors.Border, 1)

    local hasPrice = (data.Price and tostring(data.Price) ~= "" and tostring(data.Price) ~= "Standard Price")
    local priceReserved = hasPrice and 90 or 8

    local leftRow = InstNew("Frame")
    leftRow.Name = "LeftRow"
    leftRow.Size = U2(1, -priceReserved, 1, 0)
    leftRow.Position = U2(0, 6, 0, 0)
    leftRow.BackgroundTransparency = 1
    leftRow.ClipsDescendants = false
    leftRow.ZIndex = 31
    leftRow.Parent = item

    local leftLayout = InstNew("UIListLayout", leftRow)
    leftLayout.FillDirection = FD_H
    leftLayout.VerticalAlignment = VA_Center
    leftLayout.SortOrder = SO_Layout
    leftLayout.Padding = UDim.new(0, 6)

    local timeStr = data.Time or os.date("%H:%M:%S")
    local timeLbl = InstNew("TextLabel")
    timeLbl.LayoutOrder = 1
    timeLbl.Size = U2(0, 48, 0, 18)
    timeLbl.Text = timeStr
    timeLbl.Font = Fonts.Medium
    timeLbl.TextSize = 10
    timeLbl.TextColor3 = Colors.MutedText
    timeLbl.BackgroundTransparency = 1
    timeLbl.ZIndex = 32
    timeLbl.Parent = leftRow

    local action = tostring(data.Tag or data.Action or "INFO"):upper()
    local actBg = data.Color or Colors.ButtonBg
    local actFg = Colors.White
    if not data.Color then
    if action == "BUY" or action == "SUCCESS" then
      actBg = C3_RGB(34, 130, 75)
    elseif action == "ROLL" or action == "TARGET" or action == "SYSTEM" then
      actBg = Colors.Accent
    elseif action == "WARN" or action == "STATS" then
      actBg = C3_RGB(56, 189, 248)
    elseif action == "ERROR" then
      actBg = Colors.CloseRed
    elseif action == "MANUAL" or action == "MANUAL BUY" then
      actBg = C3_RGB(150, 100, 30)
    end
    end

    local badgeW = math.clamp(#action * 7 + 10, 38, 70)
    local actBadge = InstNew("Frame")
    actBadge.LayoutOrder = 2
    actBadge.Size = U2(0, badgeW, 0, 18)
    actBadge.BackgroundColor3 = actBg
    actBadge.ZIndex = 32
    actBadge.Parent = leftRow
    AddCorner(actBadge, 3)

    local actText = InstNew("TextLabel")
    actText.Size = U2(1, 0, 1, 0)
    actText.Text = action
    actText.Font = Fonts.Title
    actText.TextSize = 9
    actText.TextColor3 = actFg
    actText.BackgroundTransparency = 1
    actText.ZIndex = 33
    actText.Parent = actBadge

    local slotW = 0
    if data.Slot then
    slotW = 24 + 6
    local slotBadge = InstNew("Frame")
    slotBadge.LayoutOrder = 3
    slotBadge.Size = U2(0, 24, 0, 18)
    slotBadge.BackgroundColor3 = C3_RGB(30, 32, 42)
    slotBadge.ZIndex = 32
    slotBadge.Parent = leftRow
    AddCorner(slotBadge, 3)

    local slotText = InstNew("TextLabel")
    slotText.Size = U2(1, 0, 1, 0)
    slotText.Text = "S" .. tostring(data.Slot)
    slotText.Font = Fonts.Medium
    slotText.TextSize = 9
    slotText.TextColor3 = Colors.SubText
    slotText.BackgroundTransparency = 1
    slotText.ZIndex = 33
    slotText.Parent = slotBadge
    end

    local mutW = 0
    if data.Mutation and data.Mutation ~= "None" and data.Mutation ~= "" then
    mutW = 54 + 6
    local mutBadge = InstNew("Frame")
    mutBadge.LayoutOrder = 4
    mutBadge.Size = U2(0, 54, 0, 18)
    mutBadge.BackgroundColor3 = C3_RGB(40, 30, 55)
    mutBadge.ZIndex = 32
    mutBadge.Parent = leftRow
    AddCorner(mutBadge, 3)
    AddStroke(mutBadge, C3_RGB(150, 80, 220), 1)

    local mutText = InstNew("TextLabel")
    mutText.Size = U2(1, 0, 1, 0)
    mutText.Text = tostring(data.Mutation)
    mutText.Font = Fonts.Medium
    mutText.TextSize = 9
    mutText.TextColor3 = C3_RGB(220, 170, 255)
    mutText.BackgroundTransparency = 1
    mutText.ZIndex = 33
    mutText.Parent = mutBadge
    end

    local nameStr = tostring(data.Message or data.Name or "Log event")
    if data.Rarity and tostring(data.Rarity) ~= "" and tostring(data.Rarity) ~= "Common" then
    nameStr = nameStr .. " [" .. tostring(data.Rarity) .. "]"
    end
    local rarityStr = tostring(data.Rarity or "Common")
    local rColor = (data.Rarity and RarityColors[rarityStr]) or Colors.Text

    local fixedUsed = 48 + 6 + badgeW + 6 + slotW + mutW
    local nameLbl = InstNew("TextLabel")
    nameLbl.LayoutOrder = 5
    nameLbl.Size = U2(1, -fixedUsed, 0, 18)
    nameLbl.Text = nameStr
    nameLbl.Font = Fonts.Title
    nameLbl.TextSize = 11
    nameLbl.TextColor3 = rColor
    nameLbl.TextXAlignment = TXA_LEFT
    nameLbl.TextTruncate = TruncEnd
    nameLbl.BackgroundTransparency = 1
    nameLbl.ZIndex = 32
    nameLbl.Parent = leftRow

    if hasPrice then
    local priceLbl = InstNew("TextLabel")
    priceLbl.Name = "PriceLabel"
    priceLbl.AnchorPoint = V2(1, 0.5)
    priceLbl.Position = U2(1, -6, 0.5, 0)
    priceLbl.Size = U2(0, 80, 0, 18)
    priceLbl.Text = "Price: " .. tostring(data.Price)
    priceLbl.Font = Fonts.Medium
    priceLbl.TextSize = 10
    priceLbl.TextColor3 = C3_RGB(255, 215, 60)
    priceLbl.TextXAlignment = Enum.TextXAlignment.Right
    priceLbl.BackgroundTransparency = 1
    priceLbl.ZIndex = 32
    priceLbl.Parent = item
    end
    end)
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

  function sectionItems:AddKeybind(Config)
  local Row = InstNew("Frame")
  Row.Name = "KeybindRow"
  Row.Size = SizeItem.BoxItem
  Row.BackgroundColor3 = Colors.CardBg
  Row.ZIndex = 28
  Row.Parent = SectionFrame
  AddCorner(Row, 10)
  AddStroke(Row, Colors.Border, 1)

  SetupRowText(Row, Config.Title, Config.Description, 120)

  local currentKey = Config.Default
  local keyConnection

  local BindButton = InstNew("TextButton")
  BindButton.Size = U2(0, 90, 0, 28)
  BindButton.Position = U2(1, -104, 0.5, -14)
  BindButton.BackgroundColor3 = Colors.ButtonBg
  BindButton.AutoButtonColor = false
  BindButton.Text = currentKey and "[" .. currentKey.Name .. "]" or "[ ... ]"
  BindButton.Font = Fonts.Code
  BindButton.TextSize = 12
  BindButton.TextColor3 = Colors.Text
  BindButton.ZIndex = 30
  BindButton.Parent = Row
  AddCorner(BindButton, 6)
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

  BindButton.Activated:Connect(function()
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

  ContentContainer.InputBegan:Connect(function(input)
  if input.UserInputType == InpMB1 or input.UserInputType == InpTouch then
  CloseAllDropdowns()
  end
  end)

  local function BuildDashboard(dashTab, cfg)
  local Page, isMob = dashTab.Page, isMobile
  local dFrame = InstNew("Frame")
  dFrame.Name = "DashboardContainer"
  dFrame.Size = U2(1, isMob and -22 or -28, 0, 0)
  dFrame.AutomaticSize = AutoY
  dFrame.BackgroundTransparency = 1
  dFrame.ZIndex = 27
  dFrame.LayoutOrder = 1
  dFrame.Parent = Page

  local dLayout = InstNew("UIListLayout")
  dLayout.SortOrder = SO_Layout
  dLayout.Padding = UDim.new(0, 8)
  dLayout.Parent = dFrame

  local function MakeCard(p, sz, ord)
    local c = InstNew("Frame")
    c.Size = sz
    c.BackgroundColor3 = C3_RGB(15, 17, 24)
    c.BackgroundTransparency = 0.25
    c.BorderSizePixel = 0
    c.ZIndex = 28
    c.LayoutOrder = ord or 1
    c.Parent = p
    AddCorner(c, 10)
    local s = AddStroke(c, C3_RGB(255, 255, 255), 1)
    s.Transparency = 0.91
    return c
  end

  local function MakeLbl(p, txt, f, sz, col, pos, s, trunc)
    local l = InstNew("TextLabel")
    l.Text = txt or ""
    l.Font = f or Fonts.Regular
    l.TextSize = sz or 12
    l.TextColor3 = col or Colors.Text
    l.Position = pos or U2(0, 0, 0, 0)
    l.Size = s or U2(1, 0, 1, 0)
    l.TextXAlignment = TXA_LEFT
    if trunc then l.TextTruncate = TruncEnd end
    l.BackgroundTransparency = 1
    l.ZIndex = 29
    l.Parent = p
    return l
  end

  local function MakeHeader(titleText, ord)
    local h = InstNew("Frame")
    h.Size = U2(1, 0, 0, 22)
    h.BackgroundTransparency = 1
    h.ZIndex = 28
    h.LayoutOrder = ord
    h.Parent = dFrame
    local bar = InstNew("Frame")
    bar.Size = U2(0, 3, 0, 13)
    bar.Position = U2(0, 2, 0.5, -6)
    bar.BackgroundColor3 = Colors.Accent
    bar.BorderSizePixel = 0
    bar.ZIndex = 29
    bar.Parent = h
    AddCorner(bar, 999)
    RegisterAccent(bar)
    local lbl = MakeLbl(h, titleText, Fonts.Title, 12, C3_RGB(240, 243, 248), U2(0, 12, 0.5, -8), U2(0, 240, 0, 16))
    RegisterI18n(lbl, "Text", titleText)
    return h
  end

  local discUrl = cfg and cfg.Discord or "https://discord.com/invite/6XZa668SJh"
  local rawPlaceName = nil
  local gNameLbl = nil

  local banner = MakeCard(dFrame, U2(1, 0, 0, isMob and 74 or 62), 1)
  banner.ClipsDescendants = true

  local topGlow = InstNew("Frame")
  topGlow.Size = U2(1, -24, 0, 1)
  topGlow.Position = U2(0.5, 0, 0, 1)
  topGlow.AnchorPoint = V2(0.5, 0)
  topGlow.BackgroundColor3 = C3_RGB(255, 255, 255)
  topGlow.BorderSizePixel = 0
  topGlow.ZIndex = 30
  topGlow.Parent = banner
  local tgGrad = InstNew("UIGradient", topGlow)
  tgGrad.Transparency = NS_new({
    NSK_new(0, 1),
    NSK_new(0.5, 0.72),
    NSK_new(1, 1)
  })

  local gameThumb = InstNew("ImageLabel")
  gameThumb.Size = U2(isMob and 0.5 or 0.52, 0, 1, 0)
  gameThumb.Position = U2(isMob and 0.5 or 0.48, 0, 0, 0)
  gameThumb.BackgroundTransparency = 1
  gameThumb.Image = "rbxthumb://type=Asset&id=" .. tostring(game.PlaceId) .. "&w=420&h=420"
  gameThumb.ScaleType = Enum.ScaleType.Crop
  gameThumb.ZIndex = 28
  gameThumb.Parent = banner
  local imgGrad = InstNew("UIGradient", gameThumb)
  imgGrad.Transparency = NS_new({
    NSK_new(0, 1),
    NSK_new(0.35, 0.7),
    NSK_new(0.75, 0.15),
    NSK_new(1, 0.05)
  })

  local avatar = InstNew("ImageLabel")
  avatar.Size = U2(0, 42, 0, 42)
  avatar.Position = U2(0, 10, 0.5, -21)
  avatar.BackgroundColor3 = C3_RGB(20, 22, 30)
  avatar.BorderSizePixel = 0
  avatar.ZIndex = 29
  avatar.Parent = banner
  AddCorner(avatar, 999)
  local avStroke = AddStroke(avatar, C3_RGB(255, 255, 255), 1)
  avStroke.Transparency = 0.85
  task.spawn(function()
    pcall(function()
      avatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
  end)

  local dot = InstNew("Frame")
  dot.Size = U2(0, 11, 0, 11)
  dot.Position = U2(1, -11, 1, -11)
  dot.BackgroundColor3 = C3_RGB(34, 197, 94)
  dot.BorderSizePixel = 0
  dot.ZIndex = 30
  dot.Parent = avatar
  AddCorner(dot, 999)
  AddStroke(dot, C3_RGB(15, 17, 24), 1.5)

  local realName = LocalPlayer and (LocalPlayer.DisplayName or LocalPlayer.Name) or "User"
  local rawUser = LocalPlayer and LocalPlayer.Name or "Player"
  local isCensored = true
  local function MaskStr(s)
    local l = #s
    if l <= 3 then return string.sub(s, 1, 1) .. string.rep("•", 5) end
    return string.sub(s, 1, 3) .. string.rep("•", math.max(6, l - 3))
  end

  local leftBoundary = isMob and 0.44 or 0.40
  local dNameLbl = MakeLbl(banner, MaskStr(realName), Fonts.Title, 13, Colors.Text, U2(0, 60, 0, 13), U2(leftBoundary, -66, 0, 18), true)
  local uRow = InstNew("Frame")
  uRow.Size = U2(leftBoundary, -64, 0, 16)
  uRow.Position = U2(0, 60, 0, 33)
  uRow.BackgroundTransparency = 1
  uRow.ZIndex = 29
  uRow.Parent = banner

  local uLayout = InstNew("UIListLayout", uRow)
  uLayout.FillDirection = FD_H
  uLayout.VerticalAlignment = VA_Center
  uLayout.SortOrder = SO_Layout
  uLayout.Padding = UDim.new(0, 4)

  local uNameLbl = InstNew("TextLabel")
  uNameLbl.Text = "@" .. MaskStr(rawUser)
  uNameLbl.Font = Fonts.Medium
  uNameLbl.TextSize = 11
  uNameLbl.TextColor3 = Colors.SubText
  uNameLbl.AutomaticSize = Enum.AutomaticSize.X
  uNameLbl.Size = U2(0, 0, 1, 0)
  uNameLbl.LayoutOrder = 1
  uNameLbl.BackgroundTransparency = 1
  uNameLbl.ZIndex = 29
  uNameLbl.Parent = uRow

  local copyUserBtn = InstNew("ImageButton")
  copyUserBtn.Size = U2(0, 13, 0, 13)
  copyUserBtn.LayoutOrder = 2
  copyUserBtn.BackgroundTransparency = 1
  copyUserBtn.Image = "rbxassetid://10709812159"
  copyUserBtn.ImageColor3 = Colors.SubText
  copyUserBtn.ZIndex = 30
  copyUserBtn.Parent = uRow
  copyUserBtn.MouseEnter:Connect(function() copyUserBtn.ImageColor3 = Colors.White end)
  copyUserBtn.MouseLeave:Connect(function() copyUserBtn.ImageColor3 = Colors.SubText end)
  copyUserBtn.MouseButton1Click:Connect(function()
    PlayClickSound()
    pcall(function() if setclipboard then setclipboard(rawUser) end end)
    RaxorHub:Notify({
      Title = { TH = "คัดลอกสำเร็จ", EN = "Copied" },
      Content = { TH = "คัดลอกชื่อผู้ใช้แล้ว!", EN = "Username copied to clipboard!" },
      Duration = 2
    })
  end)

  banner.InputBegan:Connect(function(inp)
    if inp.UserInputType == InpMB1 then
      local mx = inp.Position.X - banner.AbsolutePosition.X
      if mx < banner.AbsoluteSize.X * leftBoundary then
        isCensored = not isCensored
        dNameLbl.Text = isCensored and MaskStr(realName) or realName
        uNameLbl.Text = "@" .. (isCensored and MaskStr(rawUser) or rawUser)
        PlayClickSound()
      end
    end
  end)

  local rightX = isMob and 0.45 or 0.42
  gNameLbl = MakeLbl(banner, "[🎮] Roblox Game", Fonts.Title, 13, Colors.Text, U2(rightX, 10, 0, 13), U2(1 - rightX, -16, 0, 18), true)

  local function UpdatePlaceName()
    if rawPlaceName and gNameLbl then
      local disp = rawPlaceName
      if CurrentLanguage == "EN" then
        if disp:find("สถานที่ของ") then
          local owner = disp:match('สถานที่ของ%s*"?([^"]+)"?') or "Player"
          disp = owner .. "'s Place"
        end
      else
        if disp:find("'s Place") then
          local owner = disp:match('^(.+)\'s Place') or "Player"
          disp = 'สถานที่ของ "' .. owner .. '"'
        end
      end
      gNameLbl.Text = "[🎮] " .. disp
    end
  end
  task.spawn(function()
    pcall(function()
      local inf = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
      if inf and inf.Name then
        rawPlaceName = inf.Name
        UpdatePlaceName()
      end
    end)
  end)
  RaxorHub:RegisterLanguageCallback(UpdatePlaceName)
  RegisterAccent(UpdatePlaceName)

  local cleanUrl = discUrl
  if cleanUrl:find("discord%.com/invite/") then
    cleanUrl = cleanUrl:gsub("https?://discord%.com/invite/", "https://discord.gg/")
  end
  local discBtn = InstNew("TextButton")
  discBtn.Size = U2(1 - rightX, -16, 0, 16)
  discBtn.Position = U2(rightX, 10, 0, 33)
  discBtn.BackgroundTransparency = 1
  discBtn.Text = cleanUrl
  discBtn.Font = Fonts.Medium
  discBtn.TextSize = 11
  discBtn.TextColor3 = C3_RGB(148, 163, 184)
  discBtn.TextXAlignment = TXA_LEFT
  discBtn.TextTruncate = TruncEnd
  discBtn.ZIndex = 30
  discBtn.Parent = banner
  discBtn.MouseEnter:Connect(function() discBtn.TextColor3 = Colors.White end)
  discBtn.MouseLeave:Connect(function() discBtn.TextColor3 = C3_RGB(148, 163, 184) end)
  discBtn.MouseButton1Click:Connect(function()
    PlayClickSound()
    pcall(function() if setclipboard then setclipboard(discUrl) end end)
    RaxorHub:Notify({
      Title = { TH = "ดิสคอร์ดทางการ", EN = "Discord Community" },
      Content = { TH = "คัดลอกลิงก์ Discord แล้ว!", EN = "Discord link copied to clipboard!" },
      Duration = 2.5
    })
  end)

  MakeHeader("SYSTEM INFO", 2)
  local statsGrid = InstNew("Frame")
  statsGrid.Size = U2(1, 0, 0, 118)
  statsGrid.BackgroundTransparency = 1
  statsGrid.ZIndex = 28
  statsGrid.LayoutOrder = 3
  statsGrid.Parent = dFrame
  local sLayout = InstNew("UIGridLayout")
  sLayout.CellSize = U2(0.5, -5, 0, 54)
  sLayout.CellPadding = U2(0, 10, 0, 6)
  sLayout.Parent = statsGrid

  local function MakeMetric(title, val, iconId, col)
    local c = InstNew("Frame")
    c.BackgroundColor3 = C3_RGB(15, 17, 24)
    c.BackgroundTransparency = 0.25
    c.BorderSizePixel = 0
    c.ZIndex = 28
    c.ClipsDescendants = true
    c.Parent = statsGrid
    AddCorner(c, 8)
    local cStroke = AddStroke(c, C3_RGB(255, 255, 255), 1)
    cStroke.Transparency = 0.91

    local topHairline = InstNew("Frame")
    topHairline.Size = U2(1, -12, 0, 1)
    topHairline.Position = U2(0.5, 0, 0, 1)
    topHairline.AnchorPoint = V2(0.5, 0)
    topHairline.BackgroundColor3 = col
    topHairline.BorderSizePixel = 0
    topHairline.ZIndex = 30
    topHairline.Parent = c
    local thGrad = InstNew("UIGradient", topHairline)
    thGrad.Transparency = NS_new({
      NSK_new(0, 0.95),
      NSK_new(0.5, 0.1),
      NSK_new(1, 0.95)
    })

    local ibg = InstNew("Frame")
    ibg.Size = U2(0, 36, 0, 36)
    ibg.Position = U2(0, 10, 0.5, -18)
    ibg.BackgroundColor3 = col
    ibg.BackgroundTransparency = 0.84
    ibg.BorderSizePixel = 0
    ibg.ZIndex = 29
    ibg.Parent = c
    AddCorner(ibg, 8)
    local is = AddStroke(ibg, col, 1)
    is.Transparency = 0.55

    local ico = InstNew("ImageLabel")
    ico.Size = U2(0, 18, 0, 18)
    ico.Position = U2(0.5, -9, 0.5, -9)
    ico.BackgroundTransparency = 1
    ico.Image = iconId
    ico.ImageColor3 = col
    ico.ZIndex = 30
    ico.Parent = ibg

    local tl = MakeLbl(c, title, Fonts.Medium, 11, C3_RGB(156, 163, 175), U2(0, 54, 0, 12), U2(1, -58, 0, 14))
    RegisterI18n(tl, "Text", title)
    local vl = MakeLbl(c, val, Fonts.Title, 16, C3_RGB(255, 255, 255), U2(0, 54, 0, 27), U2(1, -58, 0, 20))
    return vl
  end

  local metricDefs = {
    {"FPS", "60", "rbxassetid://10709770317", C3_RGB(16, 185, 129)},
    {"Ping", "0 ms", "rbxassetid://10747382504", C3_RGB(6, 182, 212)},
    {"Server Uptime", "00h 00m", "rbxassetid://10734949856", C3_RGB(168, 85, 247)},
    {"Time of day", "00:00", "rbxassetid://10709805144", C3_RGB(245, 158, 11)}
  }
  local mLabels = {}
  for _, d in ipairs(metricDefs) do
    mLabels[d[1]] = MakeMetric(d[1], d[2], d[3], d[4])
  end

  local pillsRow = InstNew("Frame")
  pillsRow.Size = U2(1, 0, 0, isMob and 72 or 32)
  pillsRow.BackgroundTransparency = 1
  pillsRow.ZIndex = 28
  pillsRow.LayoutOrder = 4
  pillsRow.Parent = dFrame
  local pLayout = InstNew("UIGridLayout")
  pLayout.CellSize = U2(isMob and 0.5 or 0.25, isMob and -5 or -8, 0, 32)
  pLayout.CellPadding = U2(0, 10, 0, 8)
  pLayout.Parent = pillsRow

  local function MakePill(label, val, iconId, col, cb)
    local pill = InstNew("TextButton")
    pill.BackgroundColor3 = C3_RGB(15, 17, 24)
    pill.BackgroundTransparency = 0.3
    pill.BorderSizePixel = 0
    pill.Text = ""
    pill.AutoButtonColor = false
    pill.ZIndex = 28
    pill.Parent = pillsRow
    AddCorner(pill, 7)
    local pStroke = AddStroke(pill, C3_RGB(255, 255, 255), 1)
    pStroke.Transparency = 0.91

    local pibg = InstNew("Frame")
    pibg.Size = U2(0, 22, 0, 22)
    pibg.Position = U2(0, 5, 0.5, -11)
    pibg.BackgroundColor3 = col
    pibg.BackgroundTransparency = 0.82
    pibg.BorderSizePixel = 0
    pibg.ZIndex = 29
    pibg.Parent = pill
    AddCorner(pibg, 5)

    local pico = InstNew("ImageLabel")
    pico.Size = U2(0, 12, 0, 12)
    pico.Position = U2(0.5, -6, 0.5, -6)
    pico.BackgroundTransparency = 1
    pico.Image = iconId
    pico.ImageColor3 = col
    pico.ZIndex = 30
    pico.Parent = pibg

    local l = MakeLbl(pill, label, Fonts.Regular, 10, C3_RGB(148, 163, 184), U2(0, 32, 0, 3), U2(1, -36, 0, 12))
    RegisterI18n(l, "Text", label)
    local v = MakeLbl(pill, val, Fonts.Medium, 11, col or Colors.Text, U2(0, 32, 0, 16), U2(1, -36, 0, 14), true)
    if cb then
      pill.MouseButton1Click:Connect(function() PlayClickSound(); cb() end)
    end
    return v
  end

  local pillDefs = {
    {"Players", tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers), "rbxassetid://10747373176", C3_RGB(192, 132, 252)},
    {"Place ID", tostring(game.PlaceId), "rbxassetid://10723345088", C3_RGB(96, 165, 250), function()
      pcall(function() if setclipboard then setclipboard(tostring(game.PlaceId)) end end)
      RaxorHub:Notify({
        Title = { TH = "คัดลอกสำเร็จ", EN = "Copied" },
        Content = { TH = "คัดลอก Place ID แล้ว!", EN = "Place ID copied to clipboard!" },
        Duration = 2
      })
    end},
    {"Job ID", string.sub(game.JobId ~= "" and game.JobId or "SinglePlayer", 1, 14) .. "...", "rbxassetid://10709798792", C3_RGB(45, 212, 191), function()
      pcall(function() if setclipboard then setclipboard(game.JobId) end end)
      RaxorHub:Notify({
        Title = { TH = "คัดลอกสำเร็จ", EN = "Copied" },
        Content = { TH = "คัดลอก Job ID แล้ว!", EN = "Job ID copied to clipboard!" },
        Duration = 2
      })
    end},
    {"Status", "Active (Ready)", "rbxassetid://10709790298", C3_RGB(74, 222, 128)}
  }
  local pLabels = {}
  for _, p in ipairs(pillDefs) do
    pLabels[p[1]] = MakePill(p[1], p[2], p[3], p[4], p[5])
  end

  MakeHeader("SERVER MANAGEMENT", 5)
  local srvRow = InstNew("Frame")
  srvRow.Size = U2(1, 0, 0, isMob and 72 or 32)
  srvRow.BackgroundTransparency = 1
  srvRow.ZIndex = 28
  srvRow.LayoutOrder = 6
  srvRow.Parent = dFrame
  local svLayout = InstNew("UIGridLayout")
  svLayout.CellSize = U2(isMob and 0.5 or 0.25, isMob and -5 or -8, 0, 32)
  svLayout.CellPadding = U2(0, 10, 0, 8)
  svLayout.Parent = srvRow

  local function MakeSrvBtn(text, iconId, cb)
    local b = InstNew("TextButton")
    b.BackgroundColor3 = C3_RGB(18, 20, 28)
    b.BackgroundTransparency = 0.25
    b.BorderSizePixel = 0
    b.Text = ""
    b.AutoButtonColor = false
    b.ZIndex = 29
    b.Parent = srvRow
    AddCorner(b, 7)
    local bs = AddStroke(b, C3_RGB(255, 255, 255), 1)
    bs.Transparency = 0.88

    local bLayout = InstNew("UIListLayout", b)
    bLayout.FillDirection = FD_H
    bLayout.HorizontalAlignment = HA_Center
    bLayout.VerticalAlignment = VA_Center
    bLayout.Padding = UDim.new(0, 6)

    local ico = InstNew("ImageLabel")
    ico.Size = U2(0, 13, 0, 13)
    ico.BackgroundTransparency = 1
    ico.Image = iconId or "rbxassetid://10709790948"
    ico.ImageColor3 = C3_RGB(180, 190, 205)
    ico.ZIndex = 30
    ico.Parent = b

    local lbl = InstNew("TextLabel")
    lbl.Text = text
    lbl.Font = Fonts.Medium
    lbl.TextSize = 10.5
    lbl.TextTruncate = TruncEnd
    lbl.TextColor3 = C3_RGB(240, 243, 248)
    lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.Size = U2(0, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.ZIndex = 30
    lbl.Parent = b
    RegisterI18n(lbl, "Text", text)

    b.MouseEnter:Connect(function()
      Tween(b, T_FAST, {BackgroundColor3 = C3_RGB(28, 32, 45)})
      bs.Transparency = 0.65
      ico.ImageColor3 = Colors.White
    end)
    b.MouseLeave:Connect(function()
      Tween(b, T_FAST, {BackgroundColor3 = C3_RGB(18, 20, 28)})
      bs.Transparency = 0.88
      ico.ImageColor3 = C3_RGB(180, 190, 205)
    end)
    b.MouseButton1Click:Connect(function()
      PlayClickSound()
      if cb then cb() end
    end)
    return b
  end

  local TeleportService = game:GetService("TeleportService")
  local function HopSrv(lowest)
    RaxorHub:Notify({
      Title = { TH = "ย้ายเซิร์ฟเวอร์", EN = "Server Hop" },
      Content = { TH = "กำลังค้นหาเซิร์ฟเวอร์...", EN = "Searching for servers..." },
      Duration = 3
    })
    task.spawn(function()
      pcall(function()
        local u = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=" .. (lowest and "Asc" or "Desc") .. "&limit=50"
        local req = game:HttpGet(u)
        local d = HttpService:JSONDecode(req)
        if d and d.data then
          for _, s in ipairs(d.data) do
            if s.playing and s.playing < s.maxPlayers and s.id ~= game.JobId then
              TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
              return
            end
          end
        end
      end)
      TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
  end

  local srvBtns = {
    {"Copy Server JobID", "rbxassetid://10709812159", function()
      pcall(function() if setclipboard then setclipboard(game.JobId) end end)
      RaxorHub:Notify({
        Title = { TH = "คัดลอกสำเร็จ", EN = "Copied" },
        Content = { TH = "คัดลอก Server Job ID แล้ว!", EN = "Server Job ID copied!" },
        Duration = 2
      })
    end},
    {"Rejoin", "rbxassetid://10734933222", function()
      RaxorHub:Notify({
        Title = { TH = "กำลังเชื่อมต่อใหม่", EN = "Rejoining" },
        Content = { TH = "กำลังเชื่อมต่อเข้าเซิร์ฟเวอร์ใหม่...", EN = "Reconnecting to server..." },
        Duration = 3
      })
      task.wait(0.5)
      pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
    end},
    {"Server Hop", "rbxassetid://10734953451", function() HopSrv(false) end},
    {"Server Hop (lowest)", "rbxassetid://10709767827", function() HopSrv(true) end}
  }
  for _, sb in ipairs(srvBtns) do
    MakeSrvBtn(sb[1], sb[2], sb[3])
  end

  task.spawn(function()
    local frames = 0
    local lastT = os.clock()
    local conn = RunService.RenderStepped:Connect(function()
      frames += 1
      local now = os.clock()
      if now - lastT >= 0.5 then
        local fps = math.floor(frames / (now - lastT))
        frames = 0
        lastT = now
        if mLabels["FPS"] and mLabels["FPS"].Parent then mLabels["FPS"].Text = tostring(fps) end
      end
    end)

    while ScreenGui and ScreenGui.Parent and dFrame and dFrame.Parent do
      task.wait(1)
      pcall(function()
        local ping = 0
        pcall(function() ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        if mLabels["Ping"] then mLabels["Ping"].Text = tostring(ping) .. " ms" end

        local up = math.floor(workspace.DistributedGameTime)
        if mLabels["Server Uptime"] then
          mLabels["Server Uptime"].Text = string.format("%02dh %02dm", math.floor(up / 3600), math.floor((up % 3600) / 60))
        end
        if mLabels["Time of day"] then mLabels["Time of day"].Text = os.date("%H:%M") end
        if pLabels["Players"] then pLabels["Players"].Text = tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers) end
      end)
    end
    if conn then conn:Disconnect() end
  end)
  end

  local DashboardTab = window:AddTab({
  Name = "Dashboard",
  Icon = "Dashboard",
  LayoutOrder = 1
  })
  window.DashboardTab = DashboardTab
  BuildDashboard(DashboardTab, GuiConfig)

  RaxorHub.OnAccentColorChanged = function(newCol)
  if RefreshLangVisuals then
  pcall(RefreshLangVisuals)
  end
  if SidebarScroll then
  for _, b in pairs(SidebarScroll:GetChildren()) do
  if b:IsA("TextButton") and b.BackgroundTransparency == 0 then
    if b:FindFirstChild("Indicator") then
    b.Indicator.BackgroundColor3 = newCol
    end
    if b:FindFirstChild("Frame") and b.Frame:FindFirstChild("Icon") then
    b.Frame.Icon.ImageColor3 = newCol
    end
  end
  end
  end
  if MobileTabBar then
  for _, b in pairs(MobileTabBar:GetChildren()) do
  if b:IsA("TextButton") then
    local stroke = b:FindFirstChildOfClass("UIStroke")
    if stroke and stroke.Color ~= Colors.Border then
    stroke.Color = newCol
    if b:FindFirstChild("Icon") then b.Icon.ImageColor3 = newCol end
    if b:FindFirstChild("Label") then b.Label.TextColor3 = newCol end
    end
  end
  end
  end
  for _, obj in pairs(RaxorHub.Objects) do
  if obj and obj.Type == "Toggle" and obj.State == true and obj.Instance then
  local track = obj.Instance:FindFirstChild("Track", true)
  if track then
    track.BackgroundColor3 = newCol
  end
  end
  end
  end

  task.spawn(function()
  task.wait(0.6)
  local autoPreset = RaxorHub:GetAutoload()
  if autoPreset and autoPreset ~= "" and autoPreset ~= "None" then
  RaxorHub:LoadConfigData(autoPreset)
  end
  end)

  task.defer(function()
  if not ScreenGui or not ScreenGui.Parent then return end
  local SettingsTab = window:AddTab({
  Name = "Settings",
  Icon = "Settings",
  LayoutOrder = 9999
  })
  window.SettingsTab = SettingsTab

  local SettingsSec = SettingsTab:AddSection("Menu & Keybinds", "การตั้งค่าปุ่มและหน้าต่าง", nil, "Left")
  SettingsSec:AddKeybind({
  Title = "Toggle UI Keybind",
  Description = "ปุ่มสำหรับพับหรือเปิดหน้าต่าง UI",
  Default = Enum.KeyCode.RightAlt,
  ID = "Raxor_ToggleKey",
  Callback = function()
  if ToggleUI then ToggleUI() end
  end
  })

  SettingsSec:AddColorPicker({
    Title = "Theme Accent Color",
    Description = "เปลี่ยนสีธีมหลักของ UI",
    Default = Colors.Accent,
    ID = "Raxor_ThemeAccent",
    Callback = function(newCol)
      RaxorHub:SetAccentColor(newCol)
      if RefreshLangVisuals then
        RefreshLangVisuals()
      end
    end
  })

  SettingsSec:AddDropdown({
  Title = "Theme Wallpaper",
  Description = "เปลี่ยนภาพพื้นหลังของ UI",
  Options = {"Default", "Halloween", "Galaxy"},
  Default = "Default",
  ID = "Raxor_ThemeWallpaper",
  Callback = function(val)
    ApplyWallpaper(val)
  end
  })

  SettingsSec:AddButton({
  Title = "Reset Config to Default",
  Description = "คืนค่าการตั้งค่าทั้งหมดกลับเป็นค่าเริ่มต้น",
  ButtonText = "Reset",
  Callback = function()
  RaxorHub:ResetAllSettings()
  RaxorHub:Notify({
    Title = { TH = "รีเซ็ตสำเร็จ", EN = "Settings Reset" },
    Content = { TH = "คืนค่าการตั้งค่าทั้งหมดเรียบร้อยแล้ว!", EN = "All configurations have been reset to default!" },
    Duration = 3
  })
  end
  })
  end)

  _G.RaxorHub = RaxorHub
  _G.RaxorWindow = window
  shared.RaxorHub = RaxorHub
  shared.RaxorWindow = window
  RaxorHub.ActiveWindow = window
  RaxorHub.ToggleSidebar = ToggleSidebar
  return window
end

return RaxorHub