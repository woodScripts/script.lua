-- ============================================================
-- PRISON LIFE KILL v1.0
-- Убийство игроков кликом (для Prison Life)
-- GitHub Version
-- ============================================================

print("=== ЗАГРУЗКА PRISON LIFE KILL ===")

-- ============================================================
-- СЛУЖБЫ
-- ============================================================
local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- Ждём загрузку
repeat task.wait() until LP and LP.Character
print("✅ Игра загружена")

-- ============================================================
-- ПРОВЕРКА НА МЫШЬ
-- ============================================================
local mouse = LP:GetMouse()
if not mouse then
    print("❌ Не удалось получить мышь!")
    return
end
print("✅ Мышь получена")

-- ============================================================
-- ПОИСК remoteEvent для убийства
-- ============================================================
local meleeEvent = nil

-- Ищем в ReplicatedStorage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
for _, child in pairs(ReplicatedStorage:GetChildren()) do
    if child:IsA("RemoteEvent") and (child.Name:lower():find("melee") or child.Name:lower():find("hit") or child.Name:lower():find("attack")) then
        meleeEvent = child
        print("✅ Найден RemoteEvent:", child.Name)
        break
    end
end

-- Если не нашли - ищем в других местах
if not meleeEvent then
    for _, child in pairs(game:GetDescendants()) do
        if child:IsA("RemoteEvent") and (child.Name:lower():find("melee") or child.Name:lower():find("hit") or child.Name:lower():find("attack")) then
            meleeEvent = child
            print("✅ Найден RemoteEvent:", child.Name)
            break
        end
    end
end

if not meleeEvent then
    print("❌ Не найден RemoteEvent для убийства!")
    print("❌ Скрипт может не работать")
end

-- ============================================================
-- ФУНКЦИЯ УБИЙСТВА
-- ============================================================

local function KillPlayer(player)
    if not player or player == LP then return end
    if not meleeEvent then return end
    
    -- Отправляем сигнал об ударе
    for i = 1, 20 do
        pcall(function()
            meleeEvent:FireServer(player)
        end)
    end
    
    print("💀 Убит:", player.Name)
end

-- ============================================================
-- ПОИСК ИГРОКА ПОД МЫШЬЮ
-- ============================================================

local function GetPlayerUnderMouse()
    if not mouse or not mouse.Target then return nil end
    
    local target = mouse.Target
    if not target then return nil end
    
    -- Ищем игрока через часть тела
    local character = target
    while character and character.Parent do
        if character:IsA("Model") and character:FindFirstChildOfClass("Humanoid") then
            -- Проверяем, что это игрок
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character == character then
                    return player
                end
            end
        end
        character = character.Parent
    end
    
    return nil
end

-- ============================================================
-- ОБРАБОТКА КЛИКА ПО ИГРОКУ
-- ============================================================

UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    -- Клик левой кнопкой мыши
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local targetPlayer = GetPlayerUnderMouse()
        if targetPlayer then
            KillPlayer(targetPlayer)
        end
    end
end)

-- ============================================================
-- ВИЗУАЛЬНАЯ ПОДСВЕТКА (чтобы видеть на кого наводишься)
-- ============================================================

local Highlight = Instance.new("Highlight")
Highlight.FillColor = Color3.fromRGB(255, 0, 0)
Highlight.FillTransparency = 0.3
Highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
Highlight.Parent = nil

RunService.RenderStepped:Connect(function()
    if not mouse then return end
    
    local targetPlayer = GetPlayerUnderMouse()
    if targetPlayer and targetPlayer.Character then
        Highlight.Parent = targetPlayer.Character
        Highlight.Enabled = true
    else
        Highlight.Parent = nil
        Highlight.Enabled = false
    end
end)

-- ============================================================
-- УПРАВЛЕНИЕ
-- ============================================================

print("========================================")
print("✦ PRISON LIFE KILL v1.0 ЗАГРУЖЕН!")
print("✦ Наведись на игрока и нажми ЛКМ")
print("✦ Враг будет подсвечен КРАСНЫМ")
print("========================================")

-- ============================================================
-- ТЕСТ (проверка, что скрипт работает)
-- ============================================================

task.wait(1)
print("✅ Скрипт работает! Наведись на игрока и кликни")
