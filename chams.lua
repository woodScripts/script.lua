-- ============================================================
-- BLOXSTRIKE CHAMS v1.0
-- Подсветка игроков через изменение цвета моделей
-- GitHub Version
-- ============================================================

print("=== ЗАГРУЗКА BLOXSTRIKE CHAMS ===")

-- Проверка Drawing (для теста)
local test = Drawing.new("Square")
if not test then
    print("❌ Ошибка: Рисование не поддерживается!")
    return
end
test:Remove()
print("✅ Рисование работает")

-- ============================================================
-- СЛУЖБЫ
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

-- Ждём загрузку
repeat task.wait() until LP and LP.Character
repeat task.wait() until Workspace.CurrentCamera
print("✅ Игра загружена")

-- ============================================================
-- НАСТРОЙКИ
-- ============================================================
local Settings = {
    Enabled = false,           -- Вкл/Выкл (F2)
    EnemyColor = {1, 0, 0},    -- Красный (враги)
    TeamColor = {0, 0, 1},     -- Синий (союзники)
    Transparency = 0.3,        -- Прозрачность (0-1)
    TeamCheck = false,         -- true = различать команды
}

print("📌 CHAMS ВЫКЛЮЧЕНЫ. Нажми F2 чтобы включить")

-- ============================================================
-- ХРАНИЛИЩЕ ОРИГИНАЛЬНЫХ ЦВЕТОВ
-- ============================================================
local OriginalColors = {}

-- ============================================================
-- ФУНКЦИИ
-- ============================================================

-- Восстановление оригинальных цветов
local function RestoreColors(char)
    if not char then return end
    if OriginalColors[char] then
        for part, data in pairs(OriginalColors[char]) do
            if part and part:IsA("BasePart") then
                part.Color = data.Color
                part.Transparency = data.Transparency
                part.Material = data.Material
            end
        end
        OriginalColors[char] = nil
    end
end

-- Применение Chams
local function ApplyChams(char, color, transparency)
    if not char then return end
    
    -- Сохраняем оригинальные цвета
    if not OriginalColors[char] then
        OriginalColors[char] = {}
        local children = char:GetChildren()
        for i = 1, #children do
            local part = children[i]
            if part:IsA("BasePart") then
                OriginalColors[char][part] = {
                    Color = part.Color,
                    Transparency = part.Transparency,
                    Material = part.Material
                }
            end
        end
    end
    
    -- Применяем новый цвет
    local children = char:GetChildren()
    for i = 1, #children do
        local part = children[i]
        if part:IsA("BasePart") then
            part.Color = Color3.new(color[1], color[2], color[3])
            part.Transparency = transparency
            part.Material = Enum.Material.Neon
        end
    end
end

-- Восстановление всех
local function RestoreAll()
    for char, _ in pairs(OriginalColors) do
        RestoreColors(char)
    end
    OriginalColors = {}
end

-- Проверка, враг ли игрок
local function IsEnemy(player)
    if player == LP then return false end
    
    if Settings.TeamCheck then
        local myTeam = LP.Team
        local theirTeam = player.Team
        if myTeam and theirTeam then
            return myTeam ~= theirTeam
        end
    end
    
    return true
end

-- ============================================================
-- ОСНОВНАЯ ФУНКЦИЯ
-- ============================================================

local function UpdateChams()
    if not Settings.Enabled then
        RestoreAll()
        return
    end
    
    local players = Players:GetPlayers()
    
    for i = 1, #players do
        local player = players[i]
        if player ~= LP then
            local char = player.Character
            if char then
                local isEnemy = IsEnemy(player)
                local color = isEnemy and Settings.EnemyColor or Settings.TeamColor
                local transparency = Settings.Transparency
                ApplyChams(char, color, transparency)
            end
        end
    end
end

-- ============================================================
-- ОТСЛЕЖИВАНИЕ НОВЫХ ИГРОКОВ
-- ============================================================

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if Settings.Enabled then
            local isEnemy = IsEnemy(player)
            local color = isEnemy and Settings.EnemyColor or Settings.TeamColor
            ApplyChams(char, color, Settings.Transparency)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        RestoreColors(player.Character)
    end
end)

-- ============================================================
-- УПРАВЛЕНИЕ
-- ============================================================

UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.KeyCode == Enum.KeyCode.F2 then
        Settings.Enabled = not Settings.Enabled
        print("========================================")
        print("CHAMS:", Settings.Enabled and "ВКЛЮЧЕНЫ ✅" or "ВЫКЛЮЧЕНЫ ❌")
        print("========================================")
        
        if not Settings.Enabled then
            RestoreAll()
        end
    end
end)

-- ============================================================
-- ЗАПУСК
-- ============================================================

print("========================================")
print("✦ BLOXSTRIKE CHAMS v1.0 ЗАГРУЖЕН!")
print("✦ F2 - Включить/Выключить")
print("✦ Враги = КРАСНЫЕ, Союзники = СИНИЕ")
print("========================================")

RunService.RenderStepped:Connect(UpdateChams)

-- ============================================================
-- ТЕСТ
-- ============================================================

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
    print("🟢 Если видите - всё работает!")
    task.wait(3)
    testSquare:Remove()
end
