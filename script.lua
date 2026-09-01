-- ============================================================
-- BLOXSTRIKE ХАБ v3.0
-- Полноценный ESP + меню для BloxStrike
-- GitHub Version
-- ============================================================

print("=== ЗАГРУЗКА BLOXSTRIKE ХАБ ===")

-- Проверка Drawing
local test = Drawing.new("Square")
if not test then
    print("❌ Ошибка: Рисование не поддерживается!")
    print("❌ Используйте Solara, Delta или Xeno")
    return
end
test:Remove()
print("✅ Рисование работает")

-- ============================================================
-- СЛУЖБЫ ИГРЫ
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Игрок = Players.LocalPlayer
local Камера = Workspace.CurrentCamera

-- Ждём загрузки
repeat task.wait() until Игрок and Игрок.Character
repeat task.wait() until Workspace.CurrentCamera
print("✅ Игра загружена")

-- ============================================================
-- МЕНЮ (ГРАФИЧЕСКИЙ ИНТЕРФЕЙС)
-- ============================================================
local Экран = Instance.new("ScreenGui")
Экран.Name = "BloxStrikeHub"
Экран.Parent = Игрок:WaitForChild("PlayerGui")
Экран.ResetOnSpawn = false

-- Главное окно
local Окно = Instance.new("Frame")
Окно.Name = "ГлавноеОкно"
Окно.Size = UDim2.new(0, 480, 0, 420)
Окно.Position = UDim2.new(0.5, -240, 0.5, -210)
Окно.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Окно.BorderSizePixel = 0
Окно.Active = true
Окно.Draggable = true
Окно.Parent = Экран

-- Заголовок
local Заголовок = Instance.new("TextLabel")
Заголовок.Size = UDim2.new(1, 0, 0, 30)
Заголовок.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Заголовок.Text = "✦ BLOXSTRIKE ХАБ v3.0"
Заголовок.TextColor3 = Color3.fromRGB(255, 70, 70)
Заголовок.Font = Enum.Font.GothamBold
Заголовок.TextSize = 18
Заголовок.Parent = Окно

-- Кнопка закрытия
local Закрыть = Instance.new("TextButton")
Закрыть.Size = UDim2.new(0, 30, 0, 30)
Закрыть.Position = UDim2.new(1, -30, 0, 0)
Закрыть.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
Закрыть.Text = "✕"
Закрыть.TextColor3 = Color3.fromRGB(255, 255, 255)
Закрыть.Font = Enum.Font.GothamBold
Закрыть.TextSize = 16
Закрыть.Parent = Окно
Закрыть.MouseButton1Click:Connect(function()
    Экран:Destroy()
end)

-- Панель вкладок
local ПанельВкладок = Instance.new("Frame")
ПанельВкладок.Size = UDim2.new(1, 0, 0, 30)
ПанельВкладок.Position = UDim2.new(0, 0, 0, 30)
ПанельВкладок.BackgroundTransparency = 1
ПанельВкладок.Parent = Окно

-- Контейнер для содержимого
local Контейнер = Instance.new("Frame")
Контейнер.Size = UDim2.new(1, -10, 1, -70)
Контейнер.Position = UDim2.new(0, 5, 0, 60)
Контейнер.BackgroundTransparency = 1
Контейнер.Parent = Окно

-- Список вкладок
local СписокВкладок = {"ESP", "Визуал", "Настройки", "Инфо"}
local ТекущаяВкладка = "ESP"
local КнопкиВкладок = {}

-- ============================================================
-- НАСТРОЙКИ
-- ============================================================
local Настройки = {
    -- ESP
    ESP_Включен = false,
    ПоказыватьРамку = true,
    ПоказыватьИмя = true,
    ПоказыватьЗдоровье = true,
    ПоказыватьРасстояние = true,
    ПоказыватьТочку = true,
    ПоказыватьСкелет = false,
    ПоказыватьЛинию = false,
    
    -- Цвета
    ЦветРамки = {1, 0, 0},
    ЦветИмени = {1, 1, 0},
    ЦветТочки = {1, 0, 0},
    ЦветЛинии = {0, 1, 0},
    
    -- Визуал
    ТолщинаРамки = 2,
    РазмерШрифта = 14,
    РадиусТочки = 4,
    КругПрицела = false,
    РазмерКруга = 120,
    Прозрачность = 0.3,
}

-- ============================================================
-- ОБЪЕКТЫ ДЛЯ РИСОВАНИЯ (ESP)
-- ============================================================
local Объекты = {}

local function Очистить()
    for i = #Объекты, 1, -1 do
        pcall(function()
            if Объекты[i] then
                Объекты[i]:Remove()
            end
        end)
        Объекты[i] = nil
    end
    Объекты = {}
end

local function Нарисовать(тип, свойства)
    local объект = Drawing.new(тип)
    if объект then
        for ключ, значение in pairs(свойства) do
            pcall(function() объект[ключ] = значение end)
        end
        объект.ZIndex = 999
        table.insert(Объекты, объект)
    end
    return объект
end

-- ============================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================================

local function ВЭкран(позиция)
    local камера = Workspace.CurrentCamera
    if not камера then return nil end
    local вектор, наЭкране = камера:WorldToViewportPoint(позиция)
    if наЭкране then
        return {X = вектор.X, Y = вектор.Y, Z = вектор.Z}
    end
    return nil
end

local function НайтиЧасть(персонаж, имя)
    if имя then
        local часть = персонаж:FindFirstChild(имя)
        if часть and часть:IsA("BasePart") then
            return часть
        end
    end
    
    local дети = персонаж:GetChildren()
    for i = 1, #дети do
        local часть = дети[i]
        if часть:IsA("BasePart") then
            return часть
        end
    end
    return nil
end

local function НайтиГолову(персонаж)
    local голова = персонаж:FindFirstChild("Head")
    if голова then return голова end
    
    local дети = персонаж:GetChildren()
    for i = 1, #дети do
        local часть = дети[i]
        if часть:IsA("BasePart") and string.find(string.lower(часть.Name), "head") then
            return часть
        end
    end
    return НайтиЧасть(персонаж)
end

local function НайтиЧастиТела(персонаж)
    local части = {}
    local имена = {"Head", "UpperTorso", "Torso", "HumanoidRootPart", 
                   "LeftArm", "RightArm", "LeftLeg", "RightLeg"}
    
    for i = 1, #имена do
        local часть = персонаж:FindFirstChild(имена[i])
        if часть and часть:IsA("BasePart") then
            table.insert(части, часть)
        end
    end
    
    if #части == 0 then
        local дети = персонаж:GetChildren()
        for i = 1, #дети do
            local часть = дети[i]
            if часть:IsA("BasePart") then
                table.insert(части, часть)
            end
        end
    end
    
    return части
end

local function Цвет(r, g, b)
    return Color3.new(r or 1, g or 0, b or 0)
end

local function Враг(игрок)
    if игрок == Игрок then return false end
    
    -- Проверка команд в BloxStrike
    local мояКоманда = Игрок.Team
    local ихКоманда = игрок.Team
    
    if мояКоманда and ихКоманда then
        return мояКоманда ~= ихКоманда
    end
    
    return true
end

-- ============================================================
-- СОЗДАНИЕ ЭЛЕМЕНТОВ МЕНЮ
-- ============================================================

local function СоздатьПереключатель(название, ключ)
    local рамка = Instance.new("Frame")
    рамка.Size = UDim2.new(1, 0, 0, 30)
    рамка.BackgroundTransparency = 1
    рамка.Parent = Контейнер
    
    local надпись = Instance.new("TextLabel")
    надпись.Size = UDim2.new(0.6, 0, 1, 0)
    надпись.BackgroundTransparency = 1
    надпись.Text = название
    надпись.TextColor3 = Color3.fromRGB(220, 220, 220)
    надпись.TextXAlignment = Enum.TextXAlignment.Left
    надпись.Font = Enum.Font.Gotham
    надпись.TextSize = 14
    надпись.Parent = рамка
    
    local кнопка = Instance.new("TextButton")
    кнопка.Size = UDim2.new(0, 80, 0, 24)
    кнопка.Position = UDim2.new(1, -80, 0.5, -12)
    кнопка.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    кнопка.Text = "ВЫКЛ"
    кнопка.TextColor3 = Color3.fromRGB(255, 255, 255)
    кнопка.Font = Enum.Font.GothamBold
    кнопка.TextSize = 12
    кнопка.Parent = рамка
    
    local состояние = false
    кнопка.MouseButton1Click:Connect(function()
        состояние = not состояние
        кнопка.BackgroundColor3 = состояние and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(60, 60, 60)
        кнопка.Text = состояние and "ВКЛ" or "ВЫКЛ"
        if ключ then
            Настройки[ключ] = состояние
        end
    end)
end

local function СоздатьПолзунок(название, ключ, мин, макс, поумолчанию)
    local рамка = Instance.new("Frame")
    рамка.Size = UDim2.new(1, 0, 0, 30)
    рамка.BackgroundTransparency = 1
    рамка.Parent = Контейнер
    
    local надпись = Instance.new("TextLabel")
    надпись.Size = UDim2.new(0.5, 0, 1, 0)
    надпись.BackgroundTransparency = 1
    надпись.Text = название .. ": " .. tostring(поумолчанию)
    надпись.TextColor3 = Color3.fromRGB(220, 220, 220)
    надпись.TextXAlignment = Enum.TextXAlignment.Left
    надпись.Font = Enum.Font.Gotham
    надпись.TextSize = 14
    надпись.Parent = рамка
    
    local кнопка = Instance.new("TextButton")
    кнопка.Size = UDim2.new(0, 120, 0, 24)
    кнопка.Position = UDim2.new(1, -120, 0.5, -12)
    кнопка.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    кнопка.Text = tostring(поумолчанию)
    кнопка.TextColor3 = Color3.fromRGB(255, 255, 255)
    кнопка.Font = Enum.Font.GothamBold
    кнопка.TextSize = 12
    кнопка.Parent = рамка
    
    local значение = поумолчанию
    кнопка.MouseButton1Click:Connect(function()
        значение = значение + 5
        if значение > макс then значение = мин end
        кнопка.Text = tostring(значение)
        надпись.Text = название .. ": " .. tostring(значение)
        if ключ then
            Настройки[ключ] = значение
        end
    end)
end

local function СоздатьМетку(текст)
    local метка = Instance.new("TextLabel")
    метка.Size = UDim2.new(1, 0, 0, 25)
    метка.BackgroundTransparency = 1
    метка.Text = текст
    метка.TextColor3 = Color3.fromRGB(200, 200, 200)
    метка.TextXAlignment = Enum.TextXAlignment.Left
    метка.Font = Enum.Font.Gotham
    метка.TextSize = 13
    метка.Parent = Контейнер
end

local function ОчиститьКонтейнер()
    for _, ребенок in pairs(Контейнер:GetChildren()) do
        ребенок:Destroy()
    end
end

-- ============================================================
-- ОБНОВЛЕНИЕ СОДЕРЖИМОГО ПО ВКЛАДКАМ
-- ============================================================

local function ОбновитьСодержимое()
    ОчиститьКонтейнер()
    
    if ТекущаяВкладка == "ESP" then
        СоздатьМетку("🔴 ОСНОВНЫЕ НАСТРОЙКИ ESP:")
        СоздатьПереключатель("Включить ESP", "ESP_Включен")
        СоздатьМетку("")
        СоздатьМетку("📦 ЭЛЕМЕНТЫ ESP:")
        СоздатьПереключатель("Рамка вокруг игрока", "ПоказыватьРамку")
        СоздатьПереключатель("Имя над головой", "ПоказыватьИмя")
        СоздатьПереключатель("Полоска здоровья", "ПоказыватьЗдоровье")
        СоздатьПереключатель("Расстояние до игрока", "ПоказыватьРасстояние")
        СоздатьПереключатель("Точка на голове", "ПоказыватьТочку")
        СоздатьПереключатель("Скелет (экспериментально)", "ПоказыватьСкелет")
        СоздатьПереключатель("Линия к игроку", "ПоказыватьЛинию")
        
    elseif ТекущаяВкладка == "Визуал" then
        СоздатьМетку("🎨 ЦВЕТА:")
        СоздатьМетку("Рамка: КРАСНЫЙ | Имя: ЖЁЛТЫЙ")
        СоздатьМетку("Точка: КРАСНЫЙ | Линия: ЗЕЛЁНЫЙ")
        СоздатьМетку("")
        СоздатьМетку("📐 РАЗМЕРЫ:")
        СоздатьПолзунок("Толщина рамки", "ТолщинаРамки", 1, 5, 2)
        СоздатьПолзунок("Размер шрифта", "РазмерШрифта", 10, 20, 14)
        СоздатьПолзунок("Радиус точки", "РадиусТочки", 2, 10, 4)
        СоздатьМетку("")
        СоздатьМетку("🎯 КРУГ ПРИЦЕЛА:")
        СоздатьПереключатель("Показывать круг", "КругПрицела")
        СоздатьПолзунок("Размер круга", "РазмерКруга", 50, 300, 120)
        СоздатьПолзунок("Прозрачность", "Прозрачность", 10, 90, 30)
        
    elseif ТекущаяВкладка == "Настройки" then
        СоздатьМетку("⌨️ УПРАВЛЕНИЕ:")
        СоздатьМетку("F1 - Открыть / Закрыть меню")
        СоздатьМетку("F2 - Включить / Выключить ESP")
        СоздатьМетку("")
        СоздатьМетку("📌 ИНФОРМАЦИЯ:")
        СоздатьМетку("✦ Создано специально для BloxStrike")
        СоздатьМетку("✦ Версия 3.0")
        СоздатьМетку("✦ GitHub: woodScripts/script.lua")
        
    elseif ТекущаяВкладка == "Инфо" then
        СоздатьМетку("📦 BLOXSTRIKE ХАБ v3.0")
        СоздатьМетку("")
        СоздатьМетку("🔹 Что умеет этот скрипт:")
        СоздатьМетку("  • Подсветка всех игроков (ESP)")
        СоздатьМетку("  • Рамка, имя, здоровье, дистанция")
        СоздатьМетку("  • Точка на голове для прицеливания")
        СоздатьМетку("  • Круг прицела (FOV)")
        СоздатьМетку("  • Отображение сквозь стены")
        СоздатьМетку("")
        СоздатьМетку("🔹 Управление:")
        СоздатьМетку("  • F1 - Меню")
        СоздатьМетку("  • F2 - Вкл/Выкл ESP")
        СоздатьМетку("")
        СоздатьМетку("⚠️ Используйте на свой страх и риск")
    end
end

-- ============================================================
-- СОЗДАНИЕ ВКЛАДОК
-- ============================================================

local function СоздатьВкладки()
    for i, название in ipairs(СписокВкладок) do
        local кнопка = Instance.new("TextButton")
        кнопка.Size = UDim2.new(0, 105, 1, 0)
        кнопка.Position = UDim2.new((i-1) * 0.25, 0, 0, 0)
        кнопка.BackgroundTransparency = 1
        кнопка.Text = название
        кнопка.TextColor3 = Color3.fromRGB(180, 180, 180)
        кнопка.Font = Enum.Font.GothamSemibold
        кнопка.TextSize = 14
        кнопка.Parent = ПанельВкладок
        
        кнопка.MouseButton1Click:Connect(function()
            ТекущаяВкладка = название
            for _, кн in pairs(КнопкиВкладок) do
                кн.BackgroundTransparency = 1
                кн.TextColor3 = Color3.fromRGB(180, 180, 180)
            end
            кнопка.BackgroundTransparency = 0.8
            кнопка.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            кнопка.TextColor3 = Color3.fromRGB(255, 255, 255)
            ОбновитьСодержимое()
        end)
        
        table.insert(КнопкиВкладок, кнопка)
    end
end
СоздатьВкладки()

-- ============================================================
-- ОСНОВНЫЕ ФУНКЦИИ ESP
-- ============================================================

-- Главная функция ESP
local function ОбновитьESP()
    if not Настройки.ESP_Включен then
        Очистить()
        return
    end
    
    Очистить()
    
    local камера = Workspace.CurrentCamera
    if not камера then return end
    
    local игроки = Players:GetPlayers()
    local экран = камера.ViewportSize
    
    for i = 1, #игроки do
        local игрок = игроки[i]
        if игрок ~= Игрок then
            local персонаж = игрок.Character
            if персонаж then
                -- Находим центр персонажа
                local центр = НайтиЧасть(персонаж, "HumanoidRootPart") or НайтиЧасть(персонаж)
                if not центр then goto продолжение end
                
                local позиция = ВЭкран(центр.Position)
                if not позиция then goto продолжение end
                
                local враг = Враг(игрок)
                local цвет = враг and Цвет(1, 0, 0) or Цвет(0, 0, 1)
                
                local расстояние = (центр.Position - камера.CFrame.Position).Magnitude
                local метры = math.floor(расстояние * 0.1)
                local масштаб = math.clamp(1 - расстояние / 500, 0.2, 1)
                local размер = 70 * масштаб
                
                -- ===== РАМКА =====
                if Настройки.ПоказыватьРамку then
                    -- Основная рамка
                    Нарисовать("Square", {
                        Position = Vector2.new(позиция.X - размер/2, позиция.Y - размер/2),
                        Size = Vector2.new(размер, размер),
                        Color = цвет,
                        Thickness = Настройки.ТолщинаРамки,
                        Filled = false
                    })
                    
                    -- Полупрозрачная заливка
                    Нарисовать("Square", {
                        Position = Vector2.new(позиция.X - размер/2 + 4, позиция.Y - размер/2 + 4),
                        Size = Vector2.new(размер - 8, размер - 8),
                        Color = цвет,
                        Thickness = 0,
                        Filled = true,
                        Transparency = 0.15
                    })
                end
                
                -- ===== ИМЯ =====
                if Настройки.ПоказыватьИмя then
                    local текст = игрок.Name
                    if Настройки.ПоказыватьРасстояние then
                        текст = текст .. " [" .. метры .. " м]"
                    end
                    Нарисовать("Text", {
                        Position = Vector2.new(позиция.X, позиция.Y - размер/2 - 18),
                        Text = текст,
                        Color = Настройки.ЦветИмени and Цвет(1, 1, 0) or Цвет(1, 1, 1),
                        Size = Настройки.РазмерШрифта,
                        Center = true,
                        Outline = true,
                        OutlineColor = Color3.new(0, 0, 0)
                    })
                end
                
                -- ===== ЗДОРОВЬЕ =====
                if Настройки.ПоказыватьЗдоровье then
                    local человек = персонаж:FindFirstChildOfClass("Humanoid")
                    if человек then
                        local здоровье = math.floor(человек.Health)
                        local максЗдоровье = человек.MaxHealth
                        local отношение = math.clamp(здоровье / максЗдоровье, 0, 1)
                        
                        local ширинаПолоски = размер
                        local xПолоски = позиция.X - ширинаПолоски / 2
                        local yПолоски = позиция.Y + размер/2 + 5
                        
                        -- Фон полоски
                        Нарисовать("Square", {
                            Position = Vector2.new(xПолоски, yПолоски),
                            Size = Vector2.new(ширинаПолоски, 5),
                            Color = Color3.new(0, 0, 0),
                            Thickness = 1,
                            Filled = true,
                            Transparency = 0.5
                        })
                        
                        -- Заполнение
                        Нарисовать("Square", {
                            Position = Vector2.new(xПолоски + 2, yПолоски + 2),
                            Size = Vector2.new((ширинаПолоски - 4) * отношение, 1),
                            Color = Color3.new(1 - отношение, отношение, 0),
                            Thickness = 0,
                            Filled = true
                        })
                        
                        -- Текст здоровья
                        Нарисовать("Text", {
                            Position = Vector2.new(позиция.X, yПолоски + 14),
                            Text = здоровье .. "/" .. максЗдоровье,
                            Color = Color3.new(1, 1, 1),
                            Size = 10,
                            Center = true,
                            Outline = true,
                            OutlineColor = Color3.new(0, 0, 0)
                        })
                    end
                end
                
                -- ===== ТОЧКА НА ГОЛОВЕ =====
                if Настройки.ПоказыватьТочку then
                    local голова = НайтиГолову(персонаж)
                    if голова then
                        local позицияГоловы = ВЭкран(голова.Position)
                        if позицияГоловы then
                            Нарисовать("Circle", {
                                Position = Vector2.new(позицияГоловы.X, позицияГоловы.Y),
                                Radius = Настройки.РадиусТочки,
                                Color = Настройки.ЦветТочки and Цвет(1, 0, 0) or цвет,
                                Filled = true
                            })
                        end
                    end
                end
                
                -- ===== ЛИНИЯ К ИГРОКУ =====
                if Настройки.ПоказыватьЛинию then
                    local центрЭкрана = Vector2.new(экран.X / 2, экран.Y)
                    Нарисовать("Line", {
                        From = центрЭкрана,
                        To = Vector2.new(позиция.X, позиция.Y),
                        Color = Настройки.ЦветЛинии and Цвет(0, 1, 0) or цвет,
                        Thickness = 1
                    })
                end
                
                -- ===== СКЕЛЕТ =====
                if Настройки.ПоказыватьСкелет then
                    local части = НайтиЧастиТела(персонаж)
                    for j = 1, #части do
                        for k = j + 1, #части do
                            local ч1, ч2 = части[j], части[k]
                            if ч1 and ч2 then
                                local п1 = ВЭкран(ч1.Position)
                                local п2 = ВЭкран(ч2.Position)
                                if п1 and п2 then
                                    local расстояниеМежду = (ч1.Position - ч2.Position).Magnitude
                                    if расстояниеМежду < 15 then
                                        Нарисовать("Line", {
                                            From = Vector2.new(п1.X, п1.Y),
                                            To = Vector2.new(п2.X, п2.Y),
                                            Color = Цвет(1, 1, 1),
                                            Thickness = 1,
                                            Transparency = 0.5
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
                
                ::продолжение::
            end
        end
    end
end

-- Круг прицела
local кругПрицела = Drawing.new("Circle")
кругПрицела.Thickness = 1
кругПрицела.NumSides = 12
кругПрицела.Filled = false
кругПрицела.Visible = false

local function ОбновитьКруг()
    local экран = Камера.ViewportSize
    кругПрицела.Position = Vector2.new(экран.X / 2, экран.Y / 2)
    кругПрицела.Radius = Настройки.РазмерКруга
    кругПрицела.Color = Цвет(0, 1, 1)
    кругПрицела.Transparency = Настройки.Прозрачность / 100
    кругПрицела.Visible = Настройки.КругПрицела
end

-- ============================================================
-- УПРАВЛЕНИЕ С КЛАВИАТУРЫ
-- ============================================================

UserInput.InputBegan:Connect(function(ввод, обработано)
    if обработано then return end
    
    if ввод.KeyCode == Enum.KeyCode.F1 then
        Окно.Visible = not Окно.Visible
    end
    
    if ввод.KeyCode == Enum.KeyCode.F2 then
        Настройки.ESP_Включен = not Настройки.ESP_Включен
        print("ESP:", Настройки.ESP_Включен and "ВКЛЮЧЕН ✅" or "ВЫКЛЮЧЕН ❌")
    end
end)

-- ============================================================
-- ЗАПУСК
-- ============================================================

print("========================================")
print("✦ BLOXSTRIKE ХАБ v3.0 ЗАГРУЖЕН!")
print("✦ F1 - Открыть / Закрыть меню")
print("✦ F2 - Включить / Выключить ESP")
print("========================================")

-- Главный цикл
RunService.RenderStepped:Connect(function()
    ОбновитьESP()
    ОбновитьКруг()
end)

-- Первоначальное обновление
ОбновитьСодержимое()

-- Тестовый квадрат
task.wait(1)
local тест = Drawing.new("Square")
if тест then
    тест.Position = Vector2.new(50, 50)
    тест.Size = Vector2.new(100, 100)
    тест.Color = Color3.new(0, 1, 0)
    тест.Filled = true
    тест.Transparency = 0.3
    тест.ZIndex = 999
    print("🟢 Тестовый квадрат в левом верхнем углу!")
    print("🟢 Если видите его - всё работает!")
    task.wait(3)
    тест:Remove()
end
