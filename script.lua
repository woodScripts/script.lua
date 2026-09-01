-- ============================================================
-- PRISON LIFE ХАБ v3.0
-- Полностью на русском языке
-- ============================================================

print("=== ЗАГРУЗКА PRISON LIFE ХАБ ===")

-- Проверка
local test = Drawing.new("Square")
if not test then
    print("❌ Ошибка: Рисование не поддерживается!")
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
Экран.Name = "PrisonLifeHub"
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
Заголовок.Text = "✦ PRISON LIFE ХАБ v3.0"
Заголовок.TextColor3 = Color3.fromRGB(0, 191, 255)
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
local СписокВкладок = {"Основное", "Визуал", "Бой", "Настройки"}
local ТекущаяВкладка = "Основное"
local КнопкиВкладок = {}

-- ============================================================
-- НАСТРОЙКИ
-- ============================================================
local Настройки = {
    -- Визуал
    ESP = false,
    ПоказыватьРамку = true,
    ПоказыватьИмя = true,
    ПоказыватьЗдоровье = true,
    ПоказыватьРасстояние = true,
    ЦветРамки = {1, 0, 0},
    ЦветИмени = {1, 1, 0},
    КругПрицела = false,
    РазмерКруга = 120,
    
    -- Движение
    Ускорение = false,
    Скорость = 50,
    Полет = false,
    Телепорт = false,
    
    -- Бой
    Наведение = false,
    БесшумноеНаведение = false,
    РасширениеХитбокса = false,
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
        return {X = вектор.X, Y = вектор.Y}
    end
    return nil
end

local function НайтиЧасть(персонаж)
    local дети = персонаж:GetChildren()
    for i = 1, #дети do
        local часть = дети[i]
        if часть:IsA("BasePart") then
            return часть
        end
    end
    return nil
end

local function Цвет(r, g, b)
    return Color3.new(r or 1, g or 0, b or 0)
end

-- ============================================================
-- СОЗДАНИЕ ЭЛЕМЕНТОВ МЕНЮ
-- ============================================================

-- Переключатель (Вкл/Выкл)
local function СоздатьПереключатель(название, ключНастройки, действие)
    local рамка = Instance.new("Frame")
    рамка.Size = UDim2.new(1, 0, 0, 32)
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
        if ключНастройки then
            Настройки[ключНастройки] = состояние
        end
        if действие then действие(состояние) end
    end)
    
    return function() return состояние end
end

-- Ползунок (настройка значения)
local function СоздатьПолзунок(название, ключНастройки, минимум, максимум, значениеПоУмолчанию, действие)
    local рамка = Instance.new("Frame")
    рамка.Size = UDim2.new(1, 0, 0, 32)
    рамка.BackgroundTransparency = 1
    рамка.Parent = Контейнер
    
    local надпись = Instance.new("TextLabel")
    надпись.Size = UDim2.new(0.5, 0, 1, 0)
    надпись.BackgroundTransparency = 1
    надпись.Text = название .. ": " .. tostring(значениеПоУмолчанию)
    надпись.TextColor3 = Color3.fromRGB(220, 220, 220)
    надпись.TextXAlignment = Enum.TextXAlignment.Left
    надпись.Font = Enum.Font.Gotham
    надпись.TextSize = 14
    надпись.Parent = рамка
    
    local кнопка = Instance.new("TextButton")
    кнопка.Size = UDim2.new(0, 120, 0, 24)
    кнопка.Position = UDim2.new(1, -120, 0.5, -12)
    кнопка.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    кнопка.Text = tostring(значениеПоУмолчанию)
    кнопка.TextColor3 = Color3.fromRGB(255, 255, 255)
    кнопка.Font = Enum.Font.GothamBold
    кнопка.TextSize = 12
    кнопка.Parent = рамка
    
    local значение = значениеПоУмолчанию
    кнопка.MouseButton1Click:Connect(function()
        значение = значение + 5
        if значение > максимум then значение = минимум end
        кнопка.Text = tostring(значение)
        надпись.Text = название .. ": " .. tostring(значение)
        if ключНастройки then
            Настройки[ключНастройки] = значение
        end
        if действие then действие(значение) end
    end)
    
    return function() return значение end
end

-- Текстовая метка
local function СоздатьМетку(текст)
    local метка = Instance.new("TextLabel")
    метка.Size = UDim2.new(1, 0, 0, 25)
    метка.BackgroundTransparency = 1
    метка.Text = текст
    метка.TextColor3 = Color3.fromRGB(200, 200, 200)
    метка.TextXAlignment = Enum.TextXAlignment.Left
    метка.Font = Enum.Font.Gotham
    метка.TextSize = 14
    метка.Parent = Контейнер
    return метка
end

-- Очистка содержимого
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
    
    if ТекущаяВкладка == "Основное" then
        СоздатьМетку("⚡ ДВИЖЕНИЕ:")
        СоздатьПереключатель("Увеличенная скорость", "Ускорение", function(вкл)
            if вкл then
                Игрок.Character.Humanoid.WalkSpeed = Настройки.Скорость
            else
                Игрок.Character.Humanoid.WalkSpeed = 16
            end
        end)
        СоздатьПолзунок("Скорость бега", "Скорость", 20, 200, 50, function(значение)
            if Настройки.Ускорение then
                Игрок.Character.Humanoid.WalkSpeed = значение
            end
        end)
        СоздатьПереключатель("Режим полёта", "Полет", function(вкл)
            if вкл then
                Игрок.Character.Humanoid.PlatformStand = true
            else
                Игрок.Character.Humanoid.PlatformStand = false
            end
        end)
        СоздатьПереключатель("Телепорт (клавиша T)", "Телепорт")
        
    elseif ТекущаяВкладка == "Визуал" then
        СоздатьМетку("👁️ ВИЗУАЛЬНЫЕ ЭФФЕКТЫ:")
        СоздатьПереключатель("Подсветка игроков (ESP)", "ESP")
        СоздатьПереключатель("Рамка вокруг игрока", "ПоказыватьРамку")
        СоздатьПереключатель("Имя над головой", "ПоказыватьИмя")
        СоздатьПереключатель("Полоска здоровья", "ПоказыватьЗдоровье")
        СоздатьПереключатель("Расстояние до игрока", "ПоказыватьРасстояние")
        СоздатьМетку("")
        СоздатьПереключатель("Круг прицела (FOV)", "КругПрицела")
        СоздатьПолзунок("Размер круга", "РазмерКруга", 50, 300, 120)
        
    elseif ТекущаяВкладка == "Бой" then
        СоздатьМетку("⚔️ БОЕВЫЕ ФУНКЦИИ:")
        СоздатьПереключатель("Автоматическое наведение", "Наведение")
        СоздатьПереключатель("Бесшумное наведение", "БесшумноеНаведение")
        СоздатьПереключатель("Расширение зоны попадания", "РасширениеХитбокса")
        
    elseif ТекущаяВкладка == "Настройки" then
        СоздатьМетку("📌 УПРАВЛЕНИЕ:")
        СоздатьМетку("F1 - Открыть / Закрыть меню")
        СоздатьМетку("T - Телепорт к ближайшему игроку")
        СоздатьМетку("")
        СоздатьМетку("📦 ИНФОРМАЦИЯ:")
        СоздатьМетку("✦ Prison Life Хаб v3.0")
        СоздатьМетку("✦ Версия для GitHub")
        СоздатьМетку("✦ Автор: woodScripts")
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
-- ОСНОВНЫЕ ФУНКЦИИ
-- ============================================================

-- Рисование ESP
local function ОбновитьESP()
    if not Настройки.ESP then
        Очистить()
        return
    end
    
    Очистить()
    
    local камера = Workspace.CurrentCamera
    if not камера then return end
    
    local игроки = Players:GetPlayers()
    
    for i = 1, #игроки do
        local игрок = игроки[i]
        if игрок ~= Игрок then
            local персонаж = игрок.Character
            if персонаж then
                local часть = НайтиЧасть(персонаж)
                if часть then
                    local позиция = ВЭкран(часть.Position)
                    if позиция then
                        local расстояние = (часть.Position - камера.CFrame.Position).Magnitude
                        local метры = math.floor(расстояние * 0.1)
                        local масштаб = math.clamp(1 - расстояние / 500, 0.2, 1)
                        local размер = 70 * масштаб
                        
                        if Настройки.ПоказыватьРамку then
                            Нарисовать("Square", {
                                Position = Vector2.new(позиция.X - размер/2, позиция.Y - размер/2),
                                Size = Vector2.new(размер, размер),
                                Color = Цвет(Настройки.ЦветРамки[1], Настройки.ЦветРамки[2], Настройки.ЦветРамки[3]),
                                Thickness = 2,
                                Filled = false
                            })
                        end
                        
                        if Настройки.ПоказыватьИмя then
                            local текст = игрок.Name
                            if Настройки.ПоказыватьРасстояние then
                                текст = текст .. " [" .. метры .. " м]"
                            end
                            Нарисовать("Text", {
                                Position = Vector2.new(позиция.X, позиция.Y - размер/2 - 18),
                                Text = текст,
                                Color = Цвет(Настройки.ЦветИмени[1], Настройки.ЦветИмени[2], Настройки.ЦветИмени[3]),
                                Size = 14,
                                Center = true,
                                Outline = true,
                                OutlineColor = Color3.new(0, 0, 0)
                            })
                        end
                        
                        if Настройки.ПоказыватьЗдоровье then
                            local человек = персонаж:FindFirstChildOfClass("Humanoid")
                            if человек then
                                local здоровье = math.floor(человек.Health)
                                local максЗдоровье = человек.MaxHealth
                                local отношение = math.clamp(здоровье / максЗдоровье, 0, 1)
                                
                                local ширинаПолоски = размер
                                local xПолоски = позиция.X - ширинаПолоски / 2
                                local yПолоски = позиция.Y + размер/2 + 5
                                
                                Нарисовать("Square", {
                                    Position = Vector2.new(xПолоски, yПолоски),
                                    Size = Vector2.new(ширинаПолоски, 5),
                                    Color = Color3.new(0, 0, 0),
                                    Thickness = 1,
                                    Filled = true,
                                    Transparency = 0.5
                                })
                                
                                Нарисовать("Square", {
                                    Position = Vector2.new(xПолоски + 2, yПолоски + 2),
                                    Size = Vector2.new((ширинаПолоски - 4) * отношение, 1),
                                    Color = Color3.new(1 - отношение, отношение, 0),
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
    кругПрицела.Transparency = 0.5
    кругПрицела.Visible = Настройки.КругПрицела
end

-- Режим полёта
local function ОбновитьПолет()
    if not Настройки.Полет then return end
    
    local персонаж = Игрок.Character
    if not персонаж then return end
    
    local корень = персонаж:FindFirstChild("HumanoidRootPart")
    if not корень then return end
    
    local вперед = Камера.CFrame.LookVector * 2
    local вправо = Камера.CFrame.RightVector * 2
    local вверх = Vector3.new(0, 1, 0) * 2
    
    if UserInput:IsKeyDown(Enum.KeyCode.W) then
        корень.Velocity = вперед * 30
    elseif UserInput:IsKeyDown(Enum.KeyCode.S) then
        корень.Velocity = -вперед * 30
    elseif UserInput:IsKeyDown(Enum.KeyCode.A) then
        корень.Velocity = -вправо * 30
    elseif UserInput:IsKeyDown(Enum.KeyCode.D) then
        корень.Velocity = вправо * 30
    elseif UserInput:IsKeyDown(Enum.KeyCode.Space) then
        корень.Velocity = вверх * 30
    elseif UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then
        корень.Velocity = -вверх * 30
    else
        корень.Velocity = Vector3.new(0, 0, 0)
    end
end

-- Телепорт к ближайшему игроку
local function Телепортироваться()
    if not Настройки.Телепорт then return end
    
    local персонаж = Игрок.Character
    if not персонаж then return end
    
    local корень = персонаж:FindFirstChild("HumanoidRootPart")
    if not корень then return end
    
    local ближайший, расстояние = nil, math.huge
    for _, игрок in pairs(Players:GetPlayers()) do
        if игрок ~= Игрок and игрок.Character then
            local цель = игрок.Character:FindFirstChild("HumanoidRootPart")
            if цель then
                local дистанция = (корень.Position - цель.Position).Magnitude
                if дистанция < расстояние then
                    ближайший = цель
                    расстояние = дистанция
                end
            end
        end
    end
    
    if ближайший then
        корень.CFrame = ближайший.CFrame + Vector3.new(0, 2, 0)
    end
end

-- Наведение на ближайшего игрока
local function НайтиБлижайшего()
    if not Настройки.Наведение then return nil end
    
    local персонаж = Игрок.Character
    if not персонаж then return nil end
    
    local корень = персонаж:FindFirstChild("HumanoidRootPart")
    if not корень then return nil end
    
    local ближайший, расстояние = nil, math.huge
    for _, игрок in pairs(Players:GetPlayers()) do
        if игрок ~= Игрок and игрок.Character then
            local цель = игрок.Character:FindFirstChild("HumanoidRootPart")
            if цель then
                local дистанция = (корень.Position - цель.Position).Magnitude
                if дистанция < расстояние then
                    ближайший = цель
                    расстояние = дистанция
                end
            end
        end
    end
    
    return ближайший
end

-- ============================================================
-- УПРАВЛЕНИЕ С КЛАВИАТУРЫ
-- ============================================================

UserInput.InputBegan:Connect(function(ввод, обработано)
    if обработано then return end
    
    if ввод.KeyCode == Enum.KeyCode.F1 then
        Окно.Visible = not Окно.Visible
    end
    
    if ввод.KeyCode == Enum.KeyCode.T then
        Телепортироваться()
    end
end)

-- ============================================================
-- ЗАПУСК
-- ============================================================

print("========================================")
print("✦ PRISON LIFE ХАБ v3.0 ЗАГРУЖЕН!")
print("✦ F1 - Открыть / Закрыть меню")
print("✦ T - Телепорт к игроку")
print("========================================")

-- Главный цикл
RunService.RenderStepped:Connect(function()
    ОбновитьESP()
    ОбновитьКруг()
    ОбновитьПолет()
    
    local цель = НайтиБлижайшего()
    if цель and Настройки.Наведение then
        Камера.CFrame = CFrame.new(Камера.CFrame.Position, цель.Position)
    end
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
    task.wait(3)
    тест:Remove()
end
