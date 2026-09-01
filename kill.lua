-- ============================================================
-- PRISON LIFE KILL v2.0 (УБИВАЕТ ПОЛНОСТЬЮ)
-- ============================================================

print("=== ЗАГРУЗКА PRISON LIFE KILL v2.0 ===")

-- ============================================================
-- СЛУЖБЫ
-- ============================================================
local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

repeat task.wait() until LP and LP.Character
print("✅ Игра загружена")

-- ============================================================
-- ПОИСК ВСЕХ RemoteEvent ДЛЯ УБИЙСТВА
-- ============================================================
local AttackEvents = {}

local function FindAttackEvents()
    for _, child in pairs(game:GetDescendants()) do
        if child:IsA("RemoteEvent") then
            local name = child.Name:lower()
            if name:find("melee") or name:find("hit") or name:find("attack") or name:find("damage") or name:find("punch") or name:find("stab") or name:find("kill") then
                table.insert(AttackEvents, child)
                print("✅ Найден:", child.Name)
            end
        end
    end
end

FindAttackEvents()

if #AttackEvents == 0 then
    print("❌ Не найден RemoteEvent для убийства!")
    print("❌ Попробуй запустить в матче")
end

-- ============================================================
-- ФУНКЦИЯ УБИЙСТВА (МНОГО УДАРОВ)
-- ============================================================

local function KillPlayer(player)
    if not player or player == LP then return end
    if #AttackEvents == 0 then return end
    
    print("💀 Атака на:", player.Name)
    
    -- Отправляем МНОГО ударов через ВСЕ найденные события
    for _, event in pairs(AttackEvents) do
        for i = 1, 50 do  -- 50 ударов через каждое событие
            pcall(function()
                event:FireServer(player)
            end)
        end
    end
    
    -- Дополнительный способ: прямая установка здоровья
    pcall(function()
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = 0
            end
        end
    end)
    
    -- Отправляем ещё один тип атаки (если есть)
    pcall(function()
        local remote = game:GetService("ReplicatedStorage"):FindFirstChild("meleeEvent")
        if remote then
            for i = 1, 50 do
                remote:FireServer(player)
            end
        end
    end)
    
    print("💀 Убит:", player.Name)
end

-- ============================================================
-- ПОИСК ИГРОКА ПОД МЫШЬЮ
-- ============================================================
local mouse = LP:GetMouse()
if not mouse then
    print("❌ Не удалось получить мышь!")
    return
end

local function GetPlayerUnderMouse()
    if not mouse or not mouse.Target then return nil end
    
    local target = mouse.Target
    if not target then return nil end
    
    local character = target
    while character and character.Parent do
        if character:IsA("Model") and character:FindFirstChildOfClass("Humanoid") then
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
-- КЛИК ПО ИГРОКУ (ЛКМ)
-- ============================================================

UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local target = GetPlayerUnderMouse()
        if target then
            KillPlayer(target)
        end
    end
end)

-- ============================================================
-- ВИЗУАЛЬНАЯ ПОДСВЕТКА (на кого наводишься)
-- ============================================================

local Highlight = Instance.new("Highlight")
Highlight.FillColor = Color3.fromRGB(255, 0, 0)
Highlight.FillTransparency = 0.2
Highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
Highlight.OutlineTransparency = 0
Highlight.Parent = nil

RunService.RenderStepped:Connect(function()
    local target = GetPlayerUnderMouse()
    if target and target.Character then
        Highlight.Parent = target.Character
    else
        Highlight.Parent = nil
    end
end)

-- ============================================================
-- ХОТКЕЙ: УБИТЬ ВСЕХ (F3)
-- ============================================================

UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.KeyCode == Enum.KeyCode.F3 then
        print("========================================")
        print("💀 УБИВАЕМ ВСЕХ ИГРОКОВ!")
        print("========================================")
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP then
                KillPlayer(player)
            end
        end
    end
end)

-- ============================================================
-- ЗАПУСК
-- ============================================================

print("========================================")
print("✦ PRISON LIFE KILL v2.0 ЗАГРУЖЕН!")
print("✦ Наведись на игрока → ЛКМ = смерть")
print("✦ F3 = убить ВСЕХ игроков")
print("========================================")

task.wait(1)
print("✅ Готово! Наводись на игроков и кликай!")
