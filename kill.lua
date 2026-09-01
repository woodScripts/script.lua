--[[
    PRISON LIVE CLIENT v2.1
    Модули: ESP | AIM | TELEPORT
    Управление: CTRL+X (меню)
]]

(function()
    -- [1] ГЛУШИМ КОНСОЛЬ
    local oldPrint = print
    local oldWarn = warn
    local oldError = error
    print = function() end
    warn = function() end
    error = function() end

    -- [2] НАСТРОЙКИ
    local Config = {
        ESP = { Box = true, Name = true, Distance = true, Health = false },
        AIM = { Enabled = false, FOV = 120, Smooth = 75, Target = "Head" },
        TELEPORT = { SaveKey = Enum.KeyCode.F1, LoadKey = Enum.KeyCode.F2 },
        Hotkeys = { ToggleMenu = Enum.KeyCode.X },
        Whitelist = {},
        Colors = {
            Background = Color3.fromRGB(15, 15, 15),
            Text = Color3.fromRGB(255, 255, 255),
            Accent = Color3.fromRGB(60, 60, 60),
            Green = Color3.fromRGB(0, 255, 0),
            Red = Color3.fromRGB(255, 0, 0),
            Yellow = Color3.fromRGB(255, 255, 0)
        }
    }

    -- [3] ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local CoreGui = game:GetService("CoreGui")
    local Workspace = game:GetService("Workspace")
    local Camera = Workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer
    local Mouse = LocalPlayer:GetMouse()

    local _visuals = { Enabled = true, Objects = {} }
    local _targeting = { Enabled = false, Target = nil, LastTarget = nil }
    local _movement = { LastTeleport = 0, SavedPos = nil }
    local _stats = { Teleports = 0, AimShots = 0, LastReset = os.time() }
    local _ui = { Visible = false }
    local _whitelist = Config.Whitelist
    local _isMenuOpen = false
    local _connection = nil

    -- [4] СЛУЧАЙНЫЕ ИМЕНА ДЛЯ МАСКИРОВКИ
    local _render = {}
    local _track = {}
    local _move = {}

    -- [5] ОБРАБОТКА ОШИБОК
    local function safeCall(func, ...)
        local success, result = pcall(func, ...)
        if not success then
            -- Фейковая ошибка в консоль
            if math.random(1, 10) == 1 then
                oldWarn("attempt to index nil with 'Humanoid'")
            end
            return nil
        end
        return result
    end

    -- [6] ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
    local function getPlayers()
        local list = {}
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
                local humanoid = player.Character.Humanoid
                if humanoid.Health > 0 then
                    table.insert(list, player)
                end
            end
        end
        return list
    end

    local function isAdmin(player)
        return player:IsInGroup(123456) or player.Name == "AdminName" -- Фейковая проверка
    end

    local function isInPrison(player)
        if not player.Character then return false end
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        local pos = root.Position
        -- Примерные координаты тюрьмы (подставь реальные)
        return pos.X > -100 and pos.X < 100 and pos.Z > -100 and pos.Z < 100 and pos.Y < 50
    end

    local function getTargetPart(player, targetType)
        if not player.Character then return nil end
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        if targetType == "Head" then
            local head = player.Character:FindFirstChild("Head")
            if head then return head end
        elseif targetType == "Torso" then
            return root
        elseif targetType == "Random" then
            local parts = player.Character:GetChildren()
            local validParts = {}
            for _, part in pairs(parts) do
                if part:IsA("BasePart") then
                    table.insert(validParts, part)
                end
            end
            if #validParts > 0 then
                return validParts[math.random(1, #validParts)]
            end
        end
        return root
    end

    -- [7] ОСНОВНОЙ МОДУЛЬ UI
    local Client = {}

    function Client:CreateUI()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "RenderedUI"
        screenGui.Parent = CoreGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 400, 0, 500)
        frame.Position = UDim2.new(0.5, -200, 0.5, -250)
        frame.BackgroundColor3 = Config.Colors.Background
        frame.BackgroundTransparency = 0.15
        frame.BorderColor3 = Config.Colors.Accent
        frame.BorderSizePixel = 1
        frame.Visible = false
        frame.Parent = screenGui
        _ui.Frame = frame

        -- Заголовок
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 40)
        title.Position = UDim2.new(0, 0, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "PRISON LIVE CLIENT v2.1"
        title.TextColor3 = Config.Colors.Text
        title.TextSize = 18
        title.TextXAlignment = Enum.TextXAlignment.Center
        title.Font = Enum.Font.GothamBold
        title.Parent = frame

        -- Перетаскивание
        local dragging = false
        local dragStart = nil
        local startPos = nil

        title.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
            end
        end)

        title.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        -- Разделитель
        local divider1 = Instance.new("Frame")
        divider1.Size = UDim2.new(0.9, 0, 0, 1)
        divider1.Position = UDim2.new(0.05, 0, 0, 40)
        divider1.BackgroundColor3 = Config.Colors.Accent
        divider1.BackgroundTransparency = 0.5
        divider1.Parent = frame

        -- Контейнер для элементов
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -20, 1, -80)
        container.Position = UDim2.new(0, 10, 0, 50)
        container.BackgroundTransparency = 1
        container.Parent = frame

        local yPos = 0

        -- Функция создания переключателя
        local function createToggle(parent, label, default, callback)
            local toggleFrame = Instance.new("Frame")
            toggleFrame.Size = UDim2.new(1, 0, 0, 30)
            toggleFrame.Position = UDim2.new(0, 0, 0, yPos)
            toggleFrame.BackgroundTransparency = 1
            toggleFrame.Parent = parent

            local labelText = Instance.new("TextLabel")
            labelText.Size = UDim2.new(0.7, 0, 1, 0)
            labelText.BackgroundTransparency = 1
            labelText.Text = "[▶] " .. label
            labelText.TextColor3 = Config.Colors.Text
            labelText.TextSize = 14
            labelText.TextXAlignment = Enum.TextXAlignment.Left
            labelText.Font = Enum.Font.Gotham
            labelText.Parent = toggleFrame

            local stateText = Instance.new("TextButton")
            stateText.Size = UDim2.new(0.2, 0, 1, 0)
            stateText.Position = UDim2.new(0.8, 0, 0, 0)
            stateText.BackgroundTransparency = 1
            stateText.Text = default and "ON" or "OFF"
            stateText.TextColor3 = default and Config.Colors.Green or Config.Colors.Red
            stateText.TextSize = 14
            stateText.Font = Enum.Font.Gotham
            stateText.Parent = toggleFrame

            local state = default

            stateText.MouseButton1Click:Connect(function()
                state = not state
                stateText.Text = state and "ON" or "OFF"
                stateText.TextColor3 = state and Config.Colors.Green or Config.Colors.Red
                if callback then callback(state) end
            end)

            yPos = yPos + 35
            return toggleFrame
        end

        -- ESP секция
        local espLabel = Instance.new("TextLabel")
        espLabel.Size = UDim2.new(1, 0, 0, 25)
        espLabel.Position = UDim2.new(0, 0, 0, yPos)
        espLabel.BackgroundTransparency = 1
        espLabel.Text = "ESP"
        espLabel.TextColor3 = Config.Colors.Text
        espLabel.TextSize = 16
        espLabel.Font = Enum.Font.GothamBold
        espLabel.TextXAlignment = Enum.TextXAlignment.Left
        espLabel.Parent = container
        yPos = yPos + 30

        createToggle(container, "ESP", true, function(state)
            _visuals.Enabled = state
        end)

        createToggle(container, "Box ESP", true, function(state)
            Config.ESP.Box = state
        end)

        createToggle(container, "Name ESP", true, function(state)
            Config.ESP.Name = state
        end)

        createToggle(container, "Distance", true, function(state)
            Config.ESP.Distance = state
        end)

        createToggle(container, "Health Bar", false, function(state)
            Config.ESP.Health = state
        end)

        yPos = yPos + 5

        -- Разделитель
        local divider2 = Instance.new("Frame")
        divider2.Size = UDim2.new(0.9, 0, 0, 1)
        divider2.Position = UDim2.new(0.05, 0, 0, yPos)
        divider2.BackgroundColor3 = Config.Colors.Accent
        divider2.BackgroundTransparency = 0.5
        divider2.Parent = container
        yPos = yPos + 10

        -- AIMBOT секция
        local aimLabel = Instance.new("TextLabel")
        aimLabel.Size = UDim2.new(1, 0, 0, 25)
        aimLabel.Position = UDim2.new(0, 0, 0, yPos)
        aimLabel.BackgroundTransparency = 1
        aimLabel.Text = "AIMBOT"
        aimLabel.TextColor3 = Config.Colors.Text
        aimLabel.TextSize = 16
        aimLabel.Font = Enum.Font.GothamBold
        aimLabel.TextXAlignment = Enum.TextXAlignment.Left
        aimLabel.Parent = container
        yPos = yPos + 30

        createToggle(container, "AIMBOT", false, function(state)
            _targeting.Enabled = state
            Config.AIM.Enabled = state
        end)

        -- FOV слайдер
        local fovFrame = Instance.new("Frame")
        fovFrame.Size = UDim2.new(1, 0, 0, 25)
        fovFrame.Position = UDim2.new(0, 0, 0, yPos)
        fovFrame.BackgroundTransparency = 1
        fovFrame.Parent = container

        local fovLabel = Instance.new("TextLabel")
        fovLabel.Size = UDim2.new(0.5, 0, 1, 0)
        fovLabel.BackgroundTransparency = 1
        fovLabel.Text = "FOV:"
        fovLabel.TextColor3 = Config.Colors.Text
        fovLabel.TextSize = 14
        fovLabel.TextXAlignment = Enum.TextXAlignment.Left
        fovLabel.Font = Enum.Font.Gotham
        fovLabel.Parent = fovFrame

        local fovValue = Instance.new("TextLabel")
        fovValue.Size = UDim2.new(0.2, 0, 1, 0)
        fovValue.Position = UDim2.new(0.8, 0, 0, 0)
        fovValue.BackgroundTransparency = 1
        fovValue.Text = "120"
        fovValue.TextColor3 = Config.Colors.Text
        fovValue.TextSize = 14
        fovValue.TextXAlignment = Enum.TextXAlignment.Center
        fovValue.Font = Enum.Font.Gotham
        fovValue.Parent = fovFrame

        yPos = yPos + 30

        -- Smooth слайдер
        local smoothFrame = Instance.new("Frame")
        smoothFrame.Size = UDim2.new(1, 0, 0, 25)
        smoothFrame.Position = UDim2.new(0, 0, 0, yPos)
        smoothFrame.BackgroundTransparency = 1
        smoothFrame.Parent = container

        local smoothLabel = Instance.new("TextLabel")
        smoothLabel.Size = UDim2.new(0.5, 0, 1, 0)
        smoothLabel.BackgroundTransparency = 1
        smoothLabel.Text = "Smooth:"
        smoothLabel.TextColor3 = Config.Colors.Text
        smoothLabel.TextSize = 14
        smoothLabel.TextXAlignment = Enum.TextXAlignment.Left
        smoothLabel.Font = Enum.Font.Gotham
        smoothLabel.Parent = smoothFrame

        local smoothValue = Instance.new("TextLabel")
        smoothValue.Size = UDim2.new(0.2, 0, 1, 0)
        smoothValue.Position = UDim2.new(0.8, 0, 0, 0)
        smoothValue.BackgroundTransparency = 1
        smoothValue.Text = "75"
        smoothValue.TextColor3 = Config.Colors.Text
        smoothValue.TextSize = 14
        smoothValue.TextXAlignment = Enum.TextXAlignment.Center
        smoothValue.Font = Enum.Font.Gotham
        smoothValue.Parent = smoothFrame

        yPos = yPos + 30

        -- Target выпадающий список
        local targetFrame = Instance.new("Frame")
        targetFrame.Size = UDim2.new(1, 0, 0, 25)
        targetFrame.Position = UDim2.new(0, 0, 0, yPos)
        targetFrame.BackgroundTransparency = 1
        targetFrame.Parent = container

        local targetLabel = Instance.new("TextLabel")
        targetLabel.Size = UDim2.new(0.5, 0, 1, 0)
        targetLabel.BackgroundTransparency = 1
        targetLabel.Text = "Target:"
        targetLabel.TextColor3 = Config.Colors.Text
        targetLabel.TextSize = 14
        targetLabel.TextXAlignment = Enum.TextXAlignment.Left
        targetLabel.Font = Enum.Font.Gotham
        targetLabel.Parent = targetFrame

        local targetDropdown = Instance.new("TextButton")
        targetDropdown.Size = UDim2.new(0.3, 0, 1, 0)
        targetDropdown.Position = UDim2.new(0.7, 0, 0, 0)
        targetDropdown.BackgroundColor3 = Config.Colors.Background
        targetDropdown.BackgroundTransparency = 0.5
        targetDropdown.Text = "Head ▼"
        targetDropdown.TextColor3 = Config.Colors.Text
        targetDropdown.TextSize = 14
        targetDropdown.Font = Enum.Font.Gotham
        targetDropdown.BorderColor3 = Config.Colors.Accent
        targetDropdown.BorderSizePixel = 1
        targetDropdown.Parent = targetFrame

        local targetOptions = {"Head", "Torso", "Random"}
        local currentTarget = 1
        targetDropdown.MouseButton1Click:Connect(function()
            currentTarget = currentTarget % #targetOptions + 1
            targetDropdown.Text = targetOptions[currentTarget] .. " ▼"
            Config.AIM.Target = targetOptions[currentTarget]
        end)

        yPos = yPos + 35

        -- Разделитель
        local divider3 = Instance.new("Frame")
        divider3.Size = UDim2.new(0.9, 0, 0, 1)
        divider3.Position = UDim2.new(0.05, 0, 0, yPos)
        divider3.BackgroundColor3 = Config.Colors.Accent
        divider3.BackgroundTransparency = 0.5
        divider3.Parent = container
        yPos = yPos + 10

        -- TELEPORT секция
        local teleLabel = Instance.new("TextLabel")
        teleLabel.Size = UDim2.new(1, 0, 0, 25)
        teleLabel.Position = UDim2.new(0, 0, 0, yPos)
        teleLabel.BackgroundTransparency = 1
        teleLabel.Text = "TELEPORT"
        teleLabel.TextColor3 = Config.Colors.Text
        teleLabel.TextSize = 16
        teleLabel.Font = Enum.Font.GothamBold
        teleLabel.TextXAlignment = Enum.TextXAlignment.Left
        teleLabel.Parent = container
        yPos = yPos + 30

        -- Выпадающий список игроков
        local playerFrame = Instance.new("Frame")
        playerFrame.Size = UDim2.new(1, 0, 0, 25)
        playerFrame.Position = UDim2.new(0, 0, 0, yPos)
        playerFrame.BackgroundTransparency = 1
        playerFrame.Parent = container

        local playerLabel = Instance.new("TextLabel")
        playerLabel.Size = UDim2.new(0.5, 0, 1, 0)
        playerLabel.BackgroundTransparency = 1
        playerLabel.Text = "To Player:"
        playerLabel.TextColor3 = Config.Colors.Text
        playerLabel.TextSize = 14
        playerLabel.TextXAlignment = Enum.TextXAlignment.Left
        playerLabel.Font = Enum.Font.Gotham
        playerLabel.Parent = playerFrame

        local playerDropdown = Instance.new("TextButton")
        playerDropdown.Size = UDim2.new(0.3, 0, 1, 0)
        playerDropdown.Position = UDim2.new(0.7, 0, 0, 0)
        playerDropdown.BackgroundColor3 = Config.Colors.Background
        playerDropdown.BackgroundTransparency = 0.5
        playerDropdown.Text = "▼"
        playerDropdown.TextColor3 = Config.Colors.Text
        playerDropdown.TextSize = 14
        playerDropdown.Font = Enum.Font.Gotham
        playerDropdown.BorderColor3 = Config.Colors.Accent
        playerDropdown.BorderSizePixel = 1
        playerDropdown.Parent = playerFrame

        yPos = yPos + 30

        -- Кнопка телепорта
        local teleportBtn = Instance.new("TextButton")
        teleportBtn.Size = UDim2.new(0.5, 0, 0, 30)
        teleportBtn.Position = UDim2.new(0.25, 0, 0, yPos)
        teleportBtn.BackgroundColor3 = Config.Colors.Background
        teleportBtn.BackgroundTransparency = 0.5
        teleportBtn.Text = "► TELEPORT"
        teleportBtn.TextColor3 = Config.Colors.Text
        teleportBtn.TextSize = 14
        teleportBtn.Font = Enum.Font.Gotham
        teleportBtn.BorderColor3 = Config.Colors.Text
        teleportBtn.BorderSizePixel = 1
        teleportBtn.Parent = container

        yPos = yPos + 35

        -- Хоткеи
        local hotkeyFrame = Instance.new("Frame")
        hotkeyFrame.Size = UDim2.new(1, 0, 0, 25)
        hotkeyFrame.Position = UDim2.new(0, 0, 0, yPos)
        hotkeyFrame.BackgroundTransparency = 1
        hotkeyFrame.Parent = container

        local saveHotkey = Instance.new("TextLabel")
        saveHotkey.Size = UDim2.new(0.5, 0, 1, 0)
        saveHotkey.BackgroundTransparency = 1
        saveHotkey.Text = "Save Pos: [F1]"
        saveHotkey.TextColor3 = Config.Colors.Text
        saveHotkey.TextSize = 14
        saveHotkey.TextXAlignment = Enum.TextXAlignment.Left
        saveHotkey.Font = Enum.Font.Gotham
        saveHotkey.Parent = hotkeyFrame

        local loadHotkey = Instance.new("TextLabel")
        loadHotkey.Size = UDim2.new(0.5, 0, 1, 0)
        loadHotkey.Position = UDim2.new(0.5, 0, 0, 0)
        loadHotkey.BackgroundTransparency = 1
        loadHotkey.Text = "Load Pos: [F2]"
        loadHotkey.TextColor3 = Config.Colors.Text
        loadHotkey.TextSize = 14
        loadHotkey.TextXAlignment = Enum.TextXAlignment.Left
        loadHotkey.Font = Enum.Font.Gotham
        loadHotkey.Parent = hotkeyFrame

        yPos = yPos + 35

        -- Разделитель
        local divider4 = Instance.new("Frame")
        divider4.Size = UDim2.new(0.9, 0, 0, 1)
        divider4.Position = UDim2.new(0.05, 0, 0, yPos)
        divider4.BackgroundColor3 = Config.Colors.Accent
        divider4.BackgroundTransparency = 0.5
        divider4.Parent = container
        yPos = yPos + 10

        -- Кнопка закрытия
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0.3, 0, 0, 30)
        closeBtn.Position = UDim2.new(0.35, 0, 0, yPos)
        closeBtn.BackgroundColor3 = Config.Colors.Background
        closeBtn.BackgroundTransparency = 0.5
        closeBtn.Text = "[X] CLOSE"
        closeBtn.TextColor3 = Config.Colors.Text
        closeBtn.TextSize = 14
        closeBtn.Font = Enum.Font.Gotham
        closeBtn.BorderColor3 = Config.Colors.Text
        closeBtn.BorderSizePixel = 1
        closeBtn.Parent = container

        closeBtn.MouseButton1Click:Connect(function()
            _ui.Visible = false
            frame.Visible = false
        end)

        yPos = yPos + 35

        -- Подсказка
        local hint = Instance.new("TextLabel")
        hint.Size = UDim2.new(1, 0, 0, 20)
        hint.Position = UDim2.new(0, 0, 0, yPos)
        hint.BackgroundTransparency = 1
        hint.Text = "[CTRL+X] TOGGLE MENU"
        hint.TextColor3 = Config.Colors.Accent
        hint.TextSize = 12
        hint.TextXAlignment = Enum.TextXAlignment.Center
        hint.Font = Enum.Font.Gotham
        hint.Parent = container

        -- Логика выбора игрока
        local selectedPlayer = nil
        playerDropdown.MouseButton1Click:Connect(function()
            local players = getPlayers()
            if #players == 0 then
                playerDropdown.Text = "No players"
                return
            end
            -- Простой выбор (в реальности нужно сделать дропдаун)
            local names = {}
            for i, p in pairs(players) do
                names[i] = p.Name
            end
            selectedPlayer = players[math.random(1, #players)]
            playerDropdown.Text = selectedPlayer.Name .. " ▼"
        end)

        -- Телепорт к игроку
        teleportBtn.MouseButton1Click:Connect(function()
            if selectedPlayer then
                Client:TELEPORT_To(selectedPlayer)
            end
        end)

        _ui.Container = container
        _ui.PlayerDropdown = playerDropdown
        _ui.SelectedPlayer = selectedPlayer

        return screenGui
    end

    -- [8] МОДУЛЬ ESP
    function Client:ESP_Update()
        if not _visuals.Enabled then
            for _, obj in pairs(_visuals.Objects) do
                if obj and obj.Remove then
                    pcall(obj.Remove, obj)
                end
            end
            _visuals.Objects = {}
            return
        end

        local players = getPlayers()
        local newObjects = {}
        local index = 1

        for _, player in pairs(players) do
            local character = player.Character
            if not character then continue end
            local root = character:FindFirstChild("HumanoidRootPart")
            if not root then continue end
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then continue end

            local pos, onScreen = Camera:WorldToScreenPoint(root.Position)
            if not onScreen then continue end

            local isPrison = isInPrison(player)
            local color = isPrison and Config.Colors.Yellow or Config.Colors.Text

            -- Box
            if Config.ESP.Box then
                local size = 3
                local box = _visuals.Objects[index] or Drawing.new("Square")
                box.Visible = true
                box.Color = color
                box.Thickness = 1
                box.Filled = false
                box.Size = Vector2.new(60, 80)
                box.Position = Vector2.new(pos.X - 30, pos.Y - 40)
                newObjects[index] = box
                index = index + 1
            end

            -- Name
            if Config.ESP.Name then
                local nameText = _visuals.Objects[index] or Drawing.new("Text")
                nameText.Visible = true
                nameText.Color = color
                nameText.Size = 14
                nameText.Center = true
                nameText.Outline = true
                nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
                nameText.Text = player.Name
                nameText.Position = Vector2.new(pos.X, pos.Y - 45)
                newObjects[index] = nameText
                index = index + 1
            end

            -- Distance
            if Config.ESP.Distance then
                local dist = (root.Position - Camera.CFrame.Position).Magnitude
                local distText = _visuals.Objects[index] or Drawing.new("Text")
                distText.Visible = true
                distText.Color = color
                distText.Size = 12
                distText.Center = true
                distText.Outline = true
                distText.OutlineColor = Color3.fromRGB(0, 0, 0)
                distText.Text = string.format("%.0f studs", dist)
                distText.Position = Vector2.new(pos.X, pos.Y - 30)
                newObjects[index] = distText
                index = index + 1
            end

            -- Health Bar
            if Config.ESP.Health then
                local health = humanoid.Health / humanoid.MaxHealth
                local healthColor = Color3.fromRGB(255 * (1 - health), 255 * health, 0)
                local bar = _visuals.Objects[index] or Drawing.new("Line")
                bar.Visible = true
                bar.Color = healthColor
                bar.Thickness = 4
                local barWidth = 40
                local barX = pos.X - barWidth / 2
                local barY = pos.Y - 50
                bar.From = Vector2.new(barX, barY)
                bar.To = Vector2.new(barX + barWidth * health, barY)
                newObjects[index] = bar
                index = index + 1
            end
        end

        -- Удаляем старые объекты
        for i = index, #_visuals.Objects do
            if _visuals.Objects[i] and _visuals.Objects[i].Remove then
                pcall(_visuals.Objects[i].Remove, _visuals.Objects[i])
            end
        end

        _visuals.Objects = newObjects
    end

    -- [9] МОДУЛЬ AIMBOT
    function Client:AIM_Update()
        if not _targeting.Enabled then return end

        local target = nil
        local targetDist = math.huge
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

        for _, player in pairs(getPlayers()) do
            if player == LocalPlayer then continue end
            if table.find(_whitelist, player.Name) then continue end
            if isAdmin(player) then continue end

            local character = player.Character
            if not character then continue end
            local root = character:FindFirstChild("HumanoidRootPart")
            if not root then continue end

            local pos, onScreen = Camera:WorldToScreenPoint(root.Position)
            if not onScreen then continue end

            -- FOV проверка
            local dir = (root.Position - Camera.CFrame.Position).Unit
            local angle = math.deg(math.acos(Camera.CFrame.LookVector:Dot(dir)))
            if angle > Config.AIM.FOV then continue end

            -- Raycast проверка
            local ray = Ray.new(Camera.CFrame.Position, (root.Position - Camera.CFrame.Position).Unit * 1000)
            local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
            if hit and hit.Parent ~= character then continue end

            local screenDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
            if screenDist < targetDist then
                targetDist = screenDist
                target = player
            end
        end

        if target then
            _targeting.Target = target
            local part = getTargetPart(target, Config.AIM.Target)
            if part then
                local targetPos = part.Position
                local currentPos = Camera.CFrame.Position
                local lookAt = CFrame.lookAt(currentPos, targetPos)

                -- Smooth
                local smoothFactor = Config.AIM.Smooth / 100
                local newCFrame = Camera.CFrame:Lerp(lookAt, smoothFactor)

                -- Jitter
                local jitter = math.rad(math.random(-1, 1) * 0.001)
                newCFrame = newCFrame * CFrame.Angles(jitter, jitter, 0)

                Camera.CFrame = newCFrame
                _stats.AimShots = _stats.AimShots + 1
            end
        else
            _targeting.Target = nil
        end
    end

    -- [10] МОДУЛЬ ТЕЛЕПОРТ
    function Client:TELEPORT_To(player)
        if not player or not player.Character then return end
        if isAdmin(player) then
            _ui.Frame.Visible = false
            return
        end

        local now = tick()
        if now - _movement.LastTeleport < 2 then
            return
        end

        local character = LocalPlayer.Character
        if not character then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end

        -- Безопасность: проверка на границы карты
        local targetPos = targetRoot.Position
        if math.abs(targetPos.X) > 500 or math.abs(targetPos.Z) > 500 or targetPos.Y < 0 then
            return
        end

        -- Имитация ходьбы для обхода анти-чита
        local startPos = root.Position
        local endPos = targetPos
        local steps = 5
        local stepSize = (endPos - startPos).Magnitude / steps

        for i = 1, steps do
            local t = i / steps
            local newPos = startPos:Lerp(endPos, t)
            if stepSize <= 5 then
                root.CFrame = CFrame.new(newPos)
            else
                -- Если расстояние большое, телепортируем с задержкой
                root.CFrame = CFrame.new(newPos)
                wait(0.05)
            end
        end

        _movement.LastTeleport = now
        _stats.Teleports = _stats.Teleports + 1

        -- Проверка на превышение лимита
        if _stats.Teleports > 50 then
            _targeting.Enabled = false
            Config.AIM.Enabled = false
            _stats.Teleports = 0
            -- Показываем сообщение в UI
            local msg = Instance.new("TextLabel")
            msg.Size = UDim2.new(1, 0, 0, 30)
            msg.Position = UDim2.new(0, 0, 0, 100)
            msg.BackgroundTransparency = 1
            msg.Text = "⚠️ TELEPORT LIMIT REACHED (30s cooldown)"
            msg.TextColor3 = Config.Colors.Yellow
            msg.TextSize = 14
            msg.Font = Enum.Font.Gotham
            msg.Parent = _ui.Container
            task.wait(30)
            msg:Destroy()
            _targeting.Enabled = true
            Config.AIM.Enabled = true
        end
    end

    function Client:SavePosition()
        local character = LocalPlayer.Character
        if not character then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        _movement.SavedPos = root.Position
    end

    function Client:LoadPosition()
        if not _movement.SavedPos then return end
        local character = LocalPlayer.Character
        if not character then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        root.CFrame = CFrame.new(_movement.SavedPos)
    end

    -- [11] СТАТИСТИКА
    function Client:UpdateStats()
        -- Фейковая статистика
        local fps = math.random(50, 70)
        local ping = math.random(30, 60)
        -- Можно обновить UI
    end

    -- [12] ФЕЙКОВЫЕ ОШИБКИ
    function Client:FakeErrors()
        task.spawn(function()
            while true do
                task.wait(math.random(30, 60))
                if math.random(1, 3) == 1 then
                    oldWarn("attempt to index nil with 'Humanoid'")
                end
            end
        end)
    end

    -- [13] ОСНОВНОЙ ЦИКЛ
    function Client:Start()
        -- Создаем UI
        local ui = self:CreateUI()

        -- Хоткеи
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end

            -- CTRL+X
            if input.KeyCode == Config.Hotkeys.ToggleMenu and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                _ui.Visible = not _ui.Visible
                _ui.Frame.Visible = _ui.Visible
            end

            -- F1
            if input.KeyCode == Config.TELEPORT.SaveKey then
                self:SavePosition()
            end

            -- F2
            if input.KeyCode == Config.TELEPORT.LoadKey then
                self:LoadPosition()
            end
        end)

        -- Запускаем обновление ESP
        _connection = RunService.RenderStepped:Connect(function()
            safeCall(self.ESP_Update, self)
            safeCall(self.AIM_Update, self)
            safeCall(self.UpdateStats, self)
        end)

        -- Запускаем фейковые ошибки
        self:FakeErrors()

        -- Watermark
        local watermark = Instance.new("TextLabel")
        watermark.Size = UDim2.new(0, 150, 0, 20)
        watermark.Position = UDim2.new(1, -160, 1, -30)
        watermark.BackgroundTransparency = 1
        watermark.Text = "Prison Client v2.1"
        watermark.TextColor3 = Config.Colors.Accent
        watermark.TextSize = 12
        watermark.Font = Enum.Font.Gotham
        watermark.TextTransparency = 0.5
        watermark.Parent = CoreGui

        print("Prison Client v2.1 loaded successfully")
    end

    -- [14] ЗАПУСК С ОБРАБОТКОЙ ОШИБОК
    local success, err = pcall(function()
        Client:Start()
    end)

    if not success then
        -- Показываем ошибку в UI
        local errorGui = Instance.new("ScreenGui")
        errorGui.Name = "ErrorUI"
        errorGui.Parent = CoreGui

        local errorFrame = Instance.new("Frame")
        errorFrame.Size = UDim2.new(0, 300, 0, 100)
        errorFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
        errorFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        errorFrame.BackgroundTransparency = 0.15
        errorFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
        errorFrame.BorderSizePixel = 2
        errorFrame.Parent = errorGui

        local errorText = Instance.new("TextLabel")
        errorText.Size = UDim2.new(1, 0, 1, 0)
        errorText.BackgroundTransparency = 1
        errorText.Text = "ERROR: перезагрузи скрипт"
        errorText.TextColor3 = Color3.fromRGB(255, 0, 0)
        errorText.TextSize = 16
        errorText.Font = Enum.Font.GothamBold
        errorText.TextXAlignment = Enum.TextXAlignment.Center
        errorText.Parent = errorFrame

        oldWarn("Critical error in Prison Client: " .. tostring(err))
    end

    -- [15] ВОССТАНОВЛЕНИЕ КОНСОЛИ
    print = oldPrint
    warn = oldWarn
    error = oldError
end)()
