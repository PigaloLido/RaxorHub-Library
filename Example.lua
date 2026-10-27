local source = game:HttpGet("https://raw.githubusercontent.com/PigaloLido/RaxorHub-Library/main/RaxorHub_UI.lua")
local RaxorHub = loadstring(source)()

-- [[ สร้างหน้าต่างหลัก (Window) ]]
local Window = RaxorHub:Window({
    Title = "RAXOR",
    SubTitle = "Example & Documentation",
    ProfileTag = "Till: Lifetime",
    Logo = "rbxassetid://87425048247573"
})

-- [[ แจ้งเตือนเริ่มต้น (Notification) ]]
RaxorHub:Notify({
    Title = "RaxorHub",
    Content = "ยินดีต้อนรับสู่ RaxorHub Library! โหลดตัวอย่าง UI สำเร็จแล้ว",
    Duration = 3.5
})

-- =========================================================================
-- [[ แท็บ 1: Combat (ไอคอนดาบ) ]]
-- =========================================================================
local CombatTab = Window:AddTab({
    Name = "Combat",
    Icon = "Combat" -- เรียกใช้ด้วยชื่อ "Combat" หรือ rbxassetid://87875752333553
})

local KillAuraSection = CombatTab:AddSection("KillAura Settings", "ตั้งค่าระบบโจมตีอัตโนมัติ")

-- 1. ToggleSwitch
KillAuraSection:AddToggleSwitch({
    Title = "Enable KillAura",
    Description = "โจมตีเป้าหมายในระยะอัตโนมัติ",
    Default = false,
    ID = "Combat_KillAura",
    Callback = function(val)
        print("[Combat] KillAura status:", val)
    end
})

-- 2. Slider
KillAuraSection:AddSlider({
    Title = "Attack Distance",
    Description = "ระยะในการเล็งเป้าหมาย (Studs)",
    Min = 3,
    Max = 50,
    Default = 15,
    Suffix = " studs",
    ID = "Combat_Distance",
    Callback = function(val)
        print("[Combat] Distance set to:", val)
    end
})

-- 3. Dropdown (Single Select with Search)
local TargetDropdown = KillAuraSection:AddDropdown({
    Title = "Target Mode",
    Description = "เลือกรูปแบบการล็อคเป้าหมาย",
    Options = {"Closest Distance", "Lowest Health", "Highest Value", "Players Only", "NPCs Only"},
    Default = "Closest Distance",
    ID = "Combat_TargetMode",
    Callback = function(selected)
        print("[Combat] Target Mode selected:", selected)
    end
})

-- 4. MultiSelect (Multiple Select with Search)
KillAuraSection:AddMultiSelect({
    Title = "Target Hitboxes",
    Description = "เลือกส่วนของร่างกายที่ต้องการล็อค",
    Options = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftArm", "RightArm", "LeftLeg", "RightLeg"},
    Default = {"Head", "HumanoidRootPart"},
    ID = "Combat_Hitboxes",
    Callback = function(selected)
        print("[Combat] Active Hitboxes:", table.concat(selected, ", "))
    end
})

-- 5. Keybind
KillAuraSection:AddKeybind({
    Title = "KillAura Keybind",
    Description = "ปุ่มลัดสำหรับเปิด/ปิด KillAura",
    Default = Enum.KeyCode.R,
    ID = "Combat_Bind",
    Callback = function(key)
        print("[Combat] Keybind pressed:", key.Name)
    end
})

-- 6. Button
KillAuraSection:AddButton({
    Title = "Reset Combat Config",
    Description = "รีเซ็ตการตั้งค่า Combat กลับเป็นค่าเริ่มต้น",
    ButtonText = "Reset",
    Callback = function()
        print("[Combat] Reset button clicked!")
        RaxorHub:Notify({
            Title = "Combat Reset",
            Content = "รีเซ็ตการตั้งค่าระบบ Combat เรียบร้อยแล้ว",
            Duration = 2
        })
    end
})

-- =========================================================================
-- [[ แท็บ 2: Movement (ไอคอนรองเท้า) ]]
-- =========================================================================
local MovementTab = Window:AddTab({
    Name = "Movement",
    Icon = "Movement" -- rbxassetid://89131492438764
})

local SpeedSection = MovementTab:AddSection("Speed & Jump", "ปรับแต่งความเร็วและการเคลื่อนที่")

SpeedSection:AddToggleSwitch({
    Title = "Speed Hack",
    Description = "เปิด/ปิด การปรับแต่งความเร็วเดิน",
    Default = false,
    ID = "Move_SpeedToggle",
    Callback = function(val)
        print("[Movement] Speed hack:", val)
    end
})

SpeedSection:AddSlider({
    Title = "WalkSpeed",
    Description = "ความเร็วในการเดินของผู้เล่น",
    Min = 16,
    Max = 350,
    Default = 64,
    Suffix = " spd",
    ID = "Move_SpeedVal",
    Callback = function(val)
        print("[Movement] WalkSpeed set to:", val)
    end
})

-- 7. Input (TextBox / Custom Value)
SpeedSection:AddInput({
    Title = "Custom Teleport Coordinates",
    Description = "พิมพ์พิกัด X, Y, Z เพื่อวาร์ป",
    Placeholder = "0, 50, 0",
    Default = "",
    ID = "Move_TeleportInput",
    Callback = function(text)
        print("[Movement] Coordinates entered:", text)
    end
})

SpeedSection:AddButton({
    Title = "Teleport to Coordinates",
    Description = "วาร์ปไปยังพิกัดที่ระบุไว้ในช่องข้อความ",
    ButtonText = "Teleport",
    Callback = function()
        print("[Movement] Teleporting...")
    end
})

-- =========================================================================
-- [[ แท็บ 3: Visuals (ไอคอนลูกตา) ]]
-- =========================================================================
local VisualsTab = Window:AddTab({
    Name = "Visuals",
    Icon = "Visuals" -- rbxassetid://82702843090557
})

local EspSection = VisualsTab:AddSection("ESP & Wallhack", "แสดงตำแหน่งเป้าหมายทะลุกำแพง")

EspSection:AddToggleSwitch({
    Title = "Enable ESP",
    Description = "เปิดใช้งานกรอบแสดงตัวเป้าหมาย",
    Default = false,
    ID = "ESP_Toggle",
    Callback = function(val)
        print("[Visuals] ESP status:", val)
    end
})

-- 8. ColorPicker
EspSection:AddColorPicker({
    Title = "ESP Color",
    Description = "เลือกสีของกรอบ ESP และไฮไลต์",
    Default = Color3.fromRGB(124, 92, 252),
    ID = "ESP_Color",
    Callback = function(color)
        print("[Visuals] Color changed to:", color)
    end
})

-- 9. Label (Informational text header)
EspSection:AddLabel("Visual Display Options")

EspSection:AddToggleSwitch({
    Title = "Show Names & Distance",
    Description = "แสดงชื่อและระยะห่าง (Studs)",
    Default = true,
    ID = "ESP_ShowInfo",
    Callback = function(val)
        print("[Visuals] Show info:", val)
    end
})

-- =========================================================================
-- [[ แท็บ 4: Automation (ไอคอนฟันเฟือง/ระบบ) ]]
-- =========================================================================
local AutoTab = Window:AddTab({
    Name = "Automation",
    Icon = "Automation" -- rbxassetid://92268014238157
})

local LogSection = AutoTab:AddSection("Activity Logger", "แสดงประวัติการทำงานแบบ Real-time")

-- 10. LogBox (Real-time activity / console viewer)
local ActivityLog = LogSection:AddLogBox({
    Title = "Console Log",
    Description = "บันทึกข้อมูลการทำงานของระบบ",
    Height = 150,
    MaxEntries = 50,
    ID = "Auto_LogBox"
})

-- ตัวอย่างการเพิ่ม Entry ใน LogBox
ActivityLog:AddEntry({
    Tag = "SYSTEM",
    Color = Color3.fromRGB(124, 92, 252),
    Message = "RaxorHub automation initialized."
})

LogSection:AddButton({
    Title = "Test Log Message",
    Description = "ทดสอบส่งข้อความเข้าสู่ Activity Log",
    ButtonText = "Send Log",
    Callback = function()
        ActivityLog:AddEntry({
            Tag = "INFO",
            Color = Color3.fromRGB(0, 255, 150),
            Message = "Test message generated at " .. os.date("%X")
        })
    end
})

-- =========================================================================
-- [[ แท็บ 5: Misc (ไอคอนตั้งค่า) ]]
-- =========================================================================
local MiscTab = Window:AddTab({
    Name = "Misc",
    Icon = "Settings" -- rbxassetid://90986900245399
})

local SecKeybind = MiscTab:AddSection("Keybind Open/Minimize UI", "ตั้งค่าปุ่มเปิด/ปิดหน้าจอ (Keybind)")

SecKeybind:AddToggleSwitch({
    ID = "EnableBind_UI",
    Title = "Enable Keybind",
    Description = "เปิดใช้งานปุ่มเปิด/ปิดหน้าจอ",
    Default = true,
    Callback = function(v)
        print("[Misc] Enable Keybind:", v)
    end
})

SecKeybind:AddKeybind({
    ID = "MenuBind",
    Title = "Keybind Open/Close",
    Description = "กดปุ่มเพื่อเปิดหรือย่อ/ปิดเมนู UI",
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
    Title = "Unload / Close UI",
    Description = "ปิดการทำงานและทำลายหน้าต่าง UI ทั้งหมด",
    ButtonText = "Unload",
    Callback = function()
        if RaxorHub.Destroy then
            RaxorHub:Destroy()
        elseif RaxorHub.ScreenGui then
            RaxorHub.ScreenGui:Destroy()
        end
    end
})
