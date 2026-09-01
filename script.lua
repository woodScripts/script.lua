-- ============================================================
-- PRISON LIFE HUB v3.0
-- GitHub Version
-- ============================================================

print("=== ЗАГРУЗКА PRISON LIFE HUB ===")

-- Проверка
local test = Drawing.new("Square")
if not test then
    print("❌ Drawing не поддерживается!")
    return
end
test:Remove()
print("✅ Drawing OK")

-- ============================================================
-- СЕРВИСЫ
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local WS = workspace
local LP = Players.LocalPlayer
local Camera = WS.CurrentCamera

repeat task.wait() until LP and LP.Character
repeat task.wait() until WS.CurrentCamera
print("✅ Игра загружена")

-- ============================================================
-- ГУИ (МЕНЮ)
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PrisonLifeHub"
ScreenGui.Parent = LP:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 450, 0, 400)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Title.Text = "✦ PRISON LIFE HUB v3.0"
Title.TextColor3 = Color3.fromRGB(0, 191, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = MainFrame

-- Кнопка закрытия
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = MainFrame
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Вкладки
local TabsContainer = Instance.new("Frame")
TabsContainer.Size = UDim2.new(1, 0, 0, 30)
TabsContainer.Position = UDim2.new(0, 0, 0, 30)
TabsContainer.BackgroundTransparency = 1
TabsContainer.Parent = MainFrame

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -10, 1, -70)
ContentContainer.Position = UDim2.new(0, 5, 0, 60)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

local Tabs = {"Основное", "Визуал", "Бой", "Настройки"}
local CurrentTab = "Основное"
local TabButtons = {}

-- ============================================================
-- НАСТРОЙКИ
-- ============================================================
local Settings = {
    -- Визуал
    ESP = false,
    Box = true,
    Name = true,
    Health = true,
    Distance = true,
    BoxColor = {1, 0, 0},
    NameColor = {1, 1, 0},
    FOV = false,
    FOVSize = 120,
    FOVColor = {0, 1, 1},
    
    -- Движение
    Walkspeed = false,
    SpeedValue = 50,
    Fly = false,
    Noclip = false,
    Teleport = false,
    
    -- Бой
    Aimlock = false,
    SilentAim = false,
    HitboxExpander = false,
}

-- ============================================================
-- ОБЪЕКТЫ ДЛЯ РИСОВАНИЯ
-- ============================================================
local Objects = {}

local function Clear()
    for i = #Objects, 1, -1 do
        pcall(function()
            if Objects[i] then
                Objects[i]:Remove()
            end
        end)
        Objects[i] = nil
    end
    Objects = {}
end

local function Draw(type, props)
    local obj = Drawing.new(type)
    if obj then
        for k, v in pairs(props) do
            pcall(function() obj[k] = v end)
        end
        obj.ZIndex = 999
        table.insert(Objects, obj)
    end
    return obj
end

-- ============================================================
-- ФУНКЦИИ
-- ============================================================

local function WorldToScreen(pos)
    local cam = WS.CurrentCamera
    if not cam then return nil end
    local vec, on = cam:WorldToViewportPoint(pos)
    if on then
        return {X = vec.X, Y = vec.Y}
    end
    return nil
end

local function FindAnyPart(char)
    local children = char:GetChildren()
    for i = 1, #children do
        local part = children[i]
        if part:IsA("BasePart") then
            return part
        end
    end
    return nil
end

local function IsEnemy(player)
    if player == LP then return false end
    return true
end

local function GetColor(r, g, b)
    return Color3.new(r or 1, g or 0, b or 0)
end

-- ============================================================
-- СОЗДАНИЕ ЭЛЕМЕНТОВ МЕНЮ
-- ============================================================

local function CreateToggle(label, settingKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1
    frame.Parent = ContentContainer
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.Parent = frame
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 80, 0, 24)
    toggle.Position = UDim2.new(1, -80, 0.5, -12)
    toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggle.Text = "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 12
    toggle.Parent = frame
    
    local state = false
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(60, 60, 60)
        toggle.Text = state and "ON" or "OFF"
        if settingKey then
            Settings[settingKey] = state
        end
        if callback then callback(state) end
    end)
    
    return function() return state end
end

local function CreateSlider(label, settingKey, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1
    frame.Parent = ContentContainer
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": " .. tostring(default)
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.Parent = frame
    
    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(0, 120, 0, 24)
    slider.Position = UDim2.new(1, -120, 0.5, -12)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    slider.Text = tostring(default)
    slider.TextColor3 = Color3.fromRGB(255, 255, 255)
    slider.Font = Enum.Font.GothamBold
    slider.TextSize = 12
    slider.Parent = frame
    
    local value = default
    slider.MouseButton1Click:Connect(function()
        value = value + 5
        if value > max then value = min end
        slider.Text = tostring(value)
        lbl.Text = label .. ": " .. tostring(value)
        if settingKey then
            Settings[settingKey] = value
        end
        if callback then callback(value) end
    end)
    
    return function() return value end
end

local function CreateLabel(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 25)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.Parent = ContentContainer
    return lbl
end

local function ClearContent()
    for _, child in pairs(ContentContainer:GetChildren()) do
        child:Destroy()
    end
end

-- ============================================================
-- ОБНОВЛЕНИЕ КОНТЕНТА ПО ВКЛАДКАМ
-- ============================================================

local function UpdateContent()
    ClearContent()
    
    if CurrentTab == "Основное" then
        CreateLabel("Движение:")
        CreateToggle("Увеличенная скорость", "Walkspeed", function(val)
            if val then
                LP.Character.Humanoid.WalkSpeed = Settings.SpeedValue or 50
            else
                LP.Character.Humanoid.WalkSpeed = 16
            end
        end)
        CreateSlider("Скорость", "SpeedValue", 20, 200, 50, function(val)
            if Settings.Walkspeed then
                LP.Character.Humanoid.WalkSpeed = val
            end
        end)
        CreateToggle("Полёт (Noclip)", "Fly", function(val)
            if val then
                LP.Character.Humanoid.PlatformStand = true
            else
                LP.Character.Humanoid.PlatformStand = false
            end
        end)
        CreateToggle("Телепорт (T)", "Teleport")
        
    elseif CurrentTab == "Визуал" then
        CreateLabel("ESP Настройки:")
        CreateToggle("ESP (подсветка)", "ESP")
        CreateToggle("Box ESP", "Box")
        CreateToggle("Имена", "Name")
        CreateToggle("Здоровье", "Health")
        CreateToggle("Дистанция", "Distance")
        CreateLabel("")
        CreateToggle("FOV Circle", "FOV")
        CreateSlider("Радиус FOV", "FOVSize", 50, 300, 120)
        
    elseif CurrentTab == "Бой" then
        CreateLabel("Боевые функции:")
        CreateToggle("Aimlock (автонаведение)", "Aimlock")
        CreateToggle("Silent Aim", "SilentAim")
        CreateToggle("Hitbox Expander", "HitboxExpander")
        
    elseif CurrentTab == "Настройки" then
        CreateLabel("Управление:")
        CreateLabel("F1 - Открыть/Закрыть меню")
        CreateLabel("T - Телепорт к игроку")
        CreateLabel("")
        CreateLabel("Информация:")
        CreateLabel("✦ Prison Life Hub v3.0")
        CreateLabel("✦ GitHub Version")
    end
end

-- ============================================================
-- СОЗДАНИЕ ВКЛАДОК
-- ============================================================

local function CreateTabs()
    for i, tabName in ipairs(Tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 100, 1, 0)
        btn.Position = UDim2.new((i-1) * 0.25, 0, 0, 0)
        btn.BackgroundTransparency = 1
        btn.Text = tabName
        btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 14
        btn.Parent = TabsContainer
        
        btn.MouseButton1Click:Connect(function()
            CurrentTab = tabName
            for _, b in pairs(TabButtons) do
                b.BackgroundTransparency = 1
                b.TextColor3 = Color3.fromRGB(180, 180, 180)
            end
            btn.BackgroundTransparency = 0.8
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            UpdateContent()
        end)
        
        table.insert(TabButtons, btn)
    end
end
CreateTabs()

-- ============================================================
-- ОСНОВНЫЕ ФУНКЦИИ
-- ============================================================

-- ESP
local function UpdateESP()
    if not Settings.ESP then
        Clear()
        return
    end
    
    Clear()
    
    local cam = WS.CurrentCamera
    if not cam then return end
    
    local players = Players:GetPlayers()
    
    for i = 1, #players do
        local player = players[i]
        if player ~= LP then
            local char = player.Character
            if char then
                local part = FindAnyPart(char)
                if part then
                    local screenPos = WorldToScreen(part.Position)
                    if screenPos then
                        local dist = (part.Position - cam.CFrame.Position).Magnitude
                        local distM = math.floor(dist * 0.1)
                        local scale = math.clamp(1 - dist / 500, 0.2, 1)
                        local size = 70 * scale
                        
                        if Settings.Box then
                            Draw("Square", {
                                Position = Vector2.new(screenPos.X - size/2, screenPos.Y - size/2),
                                Size = Vector2.new(size, size),
                                Color = GetColor(Settings.BoxColor[1], Settings.BoxColor[2], Settings.BoxColor[3]),
                                Thickness = 2,
                                Filled = false
                            })
                        end
                        
                        if Settings.Name then
                            local text = player.Name
                            if Settings.Distance then
                                text = text .. " [" .. distM .. "м]"
                            end
                            Draw("Text", {
                                Position = Vector2.new(screenPos.X, screenPos.Y - size/2 - 18),
                                Text = text,
                                Color = GetColor(Settings.NameColor[1], Settings.NameColor[2], Settings.NameColor[3]),
                                Size = 14,
                                Center = true,
                                Outline = true,
                                OutlineColor = Color3.new(0, 0, 0)
                            })
                        end
                        
                        if Settings.Health then
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            if hum then
                                local health = math.floor(hum.Health)
                                local maxHealth = hum.MaxHealth
                                local ratio = math.clamp(health / maxHealth, 0, 1)
                                
                                local barWidth = size
                                local barX = screenPos.X - barWidth / 2
                                local barY = screenPos.Y + size/2 + 5
                                
                                Draw("Square", {
                                    Position = Vector2.new(barX, barY),
                                    Size = Vector2.new(barWidth, 5),
                                    Color = Color3.new(0, 0, 0),
                                    Thickness = 1,
                                    Filled = true,
                                    Transparency = 0.5
                                })
                                
                                Draw("Square", {
                                    Position = Vector2.new(barX + 2, barY + 2),
                                    Size = Vector2.new((barWidth - 4) * ratio, 1),
                                    Color = Color3.new(1 - ratio, ratio, 0),
                                    Thickness = 0,
                                    Filled = true
                                })
                            end
                        end
                    end
                end
            end
        end
    end
end

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.NumSides = 12
fovCircle.Filled = false
fovCircle.Visible = false

local function UpdateFOV()
    local viewport = Camera.ViewportSize
    fovCircle.Position = Vector2.new(viewport.X / 2, viewport.Y / 2)
    fovCircle.Radius = Settings.FOVSize
    fovCircle.Color = GetColor(Settings.FOVColor[1], Settings.FOVColor[2], Settings.FOVColor[3])
    fovCircle.Transparency = 0.5
    fovCircle.Visible = Settings.FOV
end

-- Полёт
local function UpdateFly()
    if not Settings.Fly then return end
    
    local char = LP.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local forward = Camera.CFrame.LookVector * 2
    local right = Camera.CFrame.RightVector * 2
    local up = Vector3.new(0, 1, 0) * 2
    
    if UIS:IsKeyDown(Enum.KeyCode.W) then
        root.Velocity = forward * 30
    elseif UIS:IsKeyDown(Enum.KeyCode.S) then
        root.Velocity = -forward * 30
    elseif UIS:IsKeyDown(Enum.KeyCode.A) then
        root.Velocity = -right * 30
    elseif UIS:IsKeyDown(Enum.KeyCode.D) then
        root.Velocity = right * 30
    elseif UIS:IsKeyDown(Enum.KeyCode.Space) then
        root.Velocity = up * 30
    elseif UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
        root.Velocity = -up * 30
    else
        root.Velocity = Vector3.new(0, 0, 0)
    end
end

-- Телепорт
local function TeleportToTarget()
    if not Settings.Teleport then return end
    
    local char = LP.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local nearest, dist = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (root.Position - targetRoot.Position).Magnitude
                if distance < dist then
                    nearest = targetRoot
                    dist = distance
                end
            end
        end
    end
    
    if nearest then
        root.CFrame = nearest.CFrame + Vector3.new(0, 2, 0)
    end
end

-- Aimlock
local function GetClosestPlayer()
    if not Settings.Aimlock then return nil end
    
    local char = LP.Character
    if not char then return nil end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    local nearest, dist = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (root.Position - targetRoot.Position).Magnitude
                if distance < dist then
                    nearest = targetRoot
                    dist = distance
                end
            end
        end
    end
    
    return nearest
end

-- ============================================================
-- ХОТКЕИ
-- ============================================================

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        MainFrame.Visible = not MainFrame.Visible
    end
    
    if input.KeyCode == Enum.KeyCode.T then
        TeleportToTarget()
    end
end)

-- ============================================================
-- ЗАПУСК
-- ============================================================

print("========================================")
print("✦ PRISON LIFE HUB v3.0 ЗАГРУЖЕН!")
print("✦ F1 - Открыть/Закрыть меню")
print("✦ T - Телепорт к игроку")
print("========================================")

-- Основной цикл
RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateFOV()
    UpdateFly()
    
    local target = GetClosestPlayer()
    if target and Settings.Aimlock then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
    end
end)

-- Тестовый квадрат
task.wait(1)
local testSquare = Drawing.new("Square")
if testSquare then
    testSquare.Position = Vector2.new(50, 50)
    testSquare.Size = Vector2.new(100, 100)
    testSquare.Color = Color3.new(0, 1, 0)
    testSquare.Filled = true
    testSquare.Transparency = 0.3
    testSquare.ZIndex = 999
    print("🟢 ЗЕЛЁНЫЙ КВАДРАТ В ЛЕВОМ ВЕРХНЕМ УГЛУ!")
    task.wait(3)
    testSquare:Remove()
end
