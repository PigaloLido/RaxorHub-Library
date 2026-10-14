local source = game:HttpGet("https://raw.githubusercontent.com/PigaloLido/RaxorHub-Library/main/RaxorHub_UI.lua")
RaxorHub = loadstring(source)()


-- สร้างหน้าต่างหลัก
local Window = RaxorHub:Window({
    Title = "RAXOR",
    SubTitle = "Elite Client",
    ProfileTag = "Till: Lifetime"
})

-- แจ้งเตือนเริ่มต้น
RaxorHub:Notify({
    Title = "RaxorHub",
    Content = "ยินดีต้อนรับสู่ RaxorHub! โหลดระบบเรียบร้อย",
    Duration = 3.5
})

-- [[ แท็บ 1: Combat (ไอคอนดาบ) ]]
local CombatTab = Window:AddTab({
    Name = "Combat",
    Icon = "Combat" -- เรียกใช้ด้วยชื่อ "Combat" หรือ rbxassetid://87875752333553
})

local KillAuraSection = CombatTab:AddSection("KillAura Settings", "ตั้งค่าระบบโจมตีอัตโนมัติ")

KillAuraSection:AddToggleSwitch({
    Title = "Enable KillAura",
    Description = "โจมตีเป้าหมายในระยะอัตโนมัติ",
    Default = false,
    ID = "Combat_KillAura",
    Callback = function(val)
        print("[Combat] KillAura status:", val)
    end
})

KillAuraSection:AddSlider({
    Title = "Distance",
    Description = "ระยะในการเล็งเป้าหมาย",
    Min = 3,
    Max = 20,
    Default = 7,
    Suffix = " studs",
    ID = "Combat_Distance",
    Callback = function(val)
        print("[Combat] Distance set to:", val)
    end
})

KillAuraSection:AddMultiSelect({
    Title = "Target Hitboxes",
    Description = "เลือกส่วนของร่างกายที่ต้องการล็อค",
    Options = {"Head", "Chest", "Body", "Neck", "Legs"},
    Default = {"Head", "Body"},
    ID = "Combat_Hitboxes",
    Callback = function(selected)
        print("[Combat] Active Hitboxes:", table.concat(selected, ", "))
    end
})

KillAuraSection:AddKeybind({
    Title = "KillAura Keybind",
    Description = "ปุ่มลัดสำหรับเปิด/ปิดฟังก์ชัน",
    Default = Enum.KeyCode.R,
    ID = "Combat_Bind",
    Callback = function(key)
        print("[Combat] Key pressed:", key.Name)
    end
})

-- [[ แท็บ 2: Movement (ไอคอนรองเท้า) ]]
local MovementTab = Window:AddTab({
    Name = "Movement",
    Icon = "Movement" -- rbxassetid://89131492438764
})

local SpeedSection = MovementTab:AddSection("Speed & Jump", "ปรับแต่งความเร็วและการเคลื่อนที่")

SpeedSection:AddToggleSwitch({
    Title = "Speed Hack",
    Description = "เพิ่มความเร็วในการเดินของผู้เล่น",
    Default = false,
    ID = "Move_SpeedToggle",
    Callback = function(val)
        print("[Movement] Speed status:", val)
    end
})

SpeedSection:AddSlider({
    Title = "WalkSpeed Multiplier",
    Description = "ตัวคูณความเร็วการเดิน",
    Min = 16,
    Max = 250,
    Default = 32,
    Suffix = " spd",
    ID = "Move_SpeedVal",
    Callback = function(val)
        print("[Movement] Speed:", val)
    end
})

-- [[ แท็บ 3: Visuals (ไอคอนลูกตา) ]]
local VisualsTab = Window:AddTab({
    Name = "Visuals",
    Icon = "Visuals" -- rbxassetid://82702843090557
})

local EspSection = VisualsTab:AddSection("ESP & Wallhack", "แสดงตำแหน่งผู้เล่นทะลุกำแพง")

EspSection:AddToggleSwitch({
    Title = "Enable ESP",
    Description = "เปิดใช้งานกรอบแสดงตัวผู้เล่น",
    Default = false,
    ID = "ESP_Toggle",
    Callback = function(val)
        print("[Visuals] ESP:", val)
    end
})

EspSection:AddColorPicker({
    Title = "ESP Color",
    Description = "เลือกสีของกรอบ ESP และไฮไลต์",
    Default = Color3.fromRGB(124, 92, 252),
    ID = "ESP_Color",
    Callback = function(color)
        print("[Visuals] Color changed:", color)
    end
})

-- [[ แท็บ 4: Misc (ไอคอนฟันเฟือง) ]]
local MiscTab = Window:AddTab({
    Name = "Misc",
    Icon = "Settings" -- rbxassetid://90986900245399
})

-- [[ Section: Keybind Open/Minimize UI ]]
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
