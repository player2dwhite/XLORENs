--[=[
    XLORENs - Main (Doble capa + Apertura automática)
]=]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

print("[XLORENs] Iniciando con doble capa de protección...")

-- ====================================================
-- CAPA 1: Cargar Loader.lua (con respaldo)
-- ====================================================
local XLORENs

local loaderSuccess, loaderResult = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/player2dwhite/XLORENs/main/Core/Loader.lua"))()
end)

if loaderSuccess and loaderResult then
    XLORENs = loaderResult
    print("[XLORENs] Loader.lua cargado correctamente desde GitHub.")
else
    print("[XLORENs] Loader.lua falló. Creando estructura de emergencia...")
    XLORENs = {
        Modules = {},
        Services = {},
        Config = {},
        Signals = {},
        UI = nil,
        WallChecker = nil,
        TargetManager = nil,
        Aimbot = nil,
    }
    function XLORENs:Init() print("[XLORENs] Init de emergencia.") return self end
end

pcall(function() XLORENs:Init() end)

-- ====================================================
-- CAPA 2: Fallbacks para módulos críticos
-- ====================================================

-- === FALLBACK: UI ===
if not XLORENs.UI or not XLORENs.UI.CreateWindow then
    print("[XLORENs] UI no encontrado. Creando UI de emergencia...")
    local EmergencyUI = {}
    function EmergencyUI:CreateWindow(config)
        config = config or {}
        local window = {
            Name = config.Name or "XLORENs",
            Keybind = config.Keybind or "K",
            Tabs = {},
            Visible = true,
        }
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "XLORENs_Emergency"
        screenGui.ResetOnSpawn = false
        screenGui.DisplayOrder = 999
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

        local main = Instance.new("Frame")
        main.Size = UDim2.new(0, 350, 0, 450)
        main.Position = UDim2.new(0.5, -175, 0.5, -225)
        main.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
        main.BorderSizePixel = 0
        main.ClipsDescendants = true
        main.Visible = true  -- <--- ABIERTO POR DEFECTO
        main.Parent = screenGui
        Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 40)
        title.Position = UDim2.new(0, 0, 0, 0)
        title.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        title.Text = window.Name .. " (EMERGENCIA)"
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 16
        title.TextColor3 = Color3.fromRGB(255, 200, 100)
        title.Parent = main
        Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

        local content = Instance.new("ScrollingFrame")
        content.Size = UDim2.new(1, -10, 1, -50)
        content.Position = UDim2.new(0, 5, 0, 45)
        content.BackgroundTransparency = 1
        content.ScrollBarThickness = 3
        content.AutomaticCanvasSize = Enum.AutomaticSize.Y
        content.CanvasSize = UDim2.new(0, 0, 0, 0)
        content.Parent = main

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = content

        local function AddToggle(parent, text, callback)
            local active = false
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -5, 0, 40)
            frame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
            frame.BorderSizePixel = 0
            frame.Parent = parent
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(220, 220, 235)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(0, 42, 0, 24)
            bg.Position = UDim2.new(1, -52, 0.5, -12)
            bg.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
            bg.BorderSizePixel = 0
            bg.Parent = frame
            Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 20, 0, 20)
            knob.Position = UDim2.new(0, 2, 0.5, -10)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.Parent = bg
            Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.Parent = frame

            local function setState(state)
                active = state
                bg.BackgroundColor3 = active and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(50, 50, 65)
                knob.Position = active and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
                if callback then pcall(callback, active) end
            end

            btn.MouseButton1Click:Connect(function() setState(not active) end)
            return { Set = setState, Get = function() return active end }
        end

        local function AddSlider(parent, text, min, max, default, callback)
            local value = default or min
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -5, 0, 58)
            frame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
            frame.BorderSizePixel = 0
            frame.Parent = parent
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -12, 0, 22)
            label.Position = UDim2.new(0, 12, 0, 6)
            label.BackgroundTransparency = 1
            label.Text = text .. ": " .. value
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(220, 220, 235)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -24, 0, 6)
            track.Position = UDim2.new(0, 12, 0, 36)
            track.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
            track.BorderSizePixel = 0
            track.Parent = frame
            Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

            local p = math.clamp((value - min) / (max - min), 0, 1)
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(p, 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
            fill.BorderSizePixel = 0
            fill.Parent = track
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local handle = Instance.new("Frame")
            handle.Size = UDim2.new(0, 16, 0, 16)
            handle.Position = UDim2.new(p, -8, 0.5, -8)
            handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            handle.BorderSizePixel = 0
            handle.Parent = track
            Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)

            local dragging = false
            local function update()
                local mouse = UIS:GetMouseLocation()
                local m = math.clamp((mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (m * (max - min)))
                label.Text = text .. ": " .. value
                fill.Size = UDim2.new(m, 0, 1, 0)
                handle.Position = UDim2.new(m, -8, 0.5, -8)
                if callback then pcall(callback, value) end
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    update()
                end
            end)

            UIS.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    update()
                end
            end)

            UIS.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            return { Set = function(v) value = v; label.Text = text .. ": " .. value end }
        end

        local function AddLabel(parent, text)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -10, 0, 28)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 13
            lbl.TextColor3 = Color3.fromRGB(150, 150, 170)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = parent
            return lbl
        end

        AddLabel(content, "=== MODO EMERGENCIA ===")
        AddLabel(content, "Algunos módulos no se cargaron.")
        AddLabel(content, "Aimbot básico disponible.")

        local aimToggle = AddToggle(content, "Aimbot (Emergencia)", function(state)
            if state then
                if XLORENs.Aimbot and XLORENs.Aimbot.Enable then XLORENs.Aimbot:Enable() end
            else
                if XLORENs.Aimbot and XLORENs.Aimbot.Disable then XLORENs.Aimbot:Disable() end
            end
        end)

        AddSlider(content, "FOV", 10, 50, 30, function(v)
            if XLORENs.Aimbot and XLORENs.Aimbot.Settings then XLORENs.Aimbot.Settings.FOV = v end
        end)

        AddSlider(content, "Smooth", 0, 100, 65, function(v)
            if XLORENs.Aimbot and XLORENs.Aimbot.Settings then XLORENs.Aimbot.Settings.SmoothAmount = v end
        end)

        function window:Toggle()
            self.Visible = not self.Visible
            main.Visible = self.Visible
        end

        function window:Open()
            main.Visible = true
            self.Visible = true
        end

        UIS.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == Enum.KeyCode[window.Keybind] then
                window:Toggle()
            end
        end)

        -- ABRIR AUTOMÁTICAMENTE
        task.wait(0.1)
        window:Open()
        print("[XLORENs] UI de emergencia abierta automáticamente. Presiona " .. window.Keybind .. " para cerrar/abrir.")
        return window
    end
    XLORENs.UI = EmergencyUI
    print("[XLORENs] UI de emergencia asignada.")
end

-- === FALLBACK: Aimbot ===
if not XLORENs.Aimbot then
    print("[XLORENs] Aimbot no encontrado. Creando Aimbot de emergencia...")
    XLORENs.Aimbot = {
        Settings = { Enabled = false, Mode = "Siempre", BindKey = "X", FOV = 30, SmoothAmount = 65, Smooth = true },
        _lastAimPos = nil,
        _active = false,
    }
    function XLORENs.Aimbot:Enable() self.Settings.Enabled = true; self._active = true; print("[Aimbot] Activado (emergencia)") end
    function XLORENs.Aimbot:Disable() self.Settings.Enabled = false; self._active = false; self._lastAimPos = nil; print("[Aimbot] Desactivado (emergencia)") end
    function XLORENs.Aimbot:Update()
        if not self.Settings.Enabled then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local bestTarget, bestDist = nil, math.huge
        local center = cam.ViewportSize / 2
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local char = plr.Character
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                    if head then
                        local pos, onScreen = cam:WorldToScreenPoint(head.Position)
                        if onScreen then
                            local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                            if dist < self.Settings.FOV and dist < bestDist then
                                bestDist = dist; bestTarget = head
                            end
                        end
                    end
                end
            end
        end
        if bestTarget then
            local camPos = cam.CFrame.Position
            local lookVector = (bestTarget.Position - camPos).Unit
            if self.Settings.Smooth then
                local smoothFactor = 1 - (self.Settings.SmoothAmount / 100)
                local currentLook = cam.CFrame.LookVector
                local smoothed = currentLook:Lerp(lookVector, smoothFactor)
                cam.CFrame = CFrame.new(camPos, camPos + smoothed)
            else
                cam.CFrame = CFrame.new(camPos, bestTarget.Position)
            end
        end
    end
    function XLORENs.Aimbot:Shoot() end
    function XLORENs.Aimbot:CreateFOVCircle() end
    print("[XLORENs] Aimbot de emergencia asignado.")
end

-- === FALLBACK: TargetManager ===
if not XLORENs.TargetManager then
    print("[XLORENs] TargetManager no encontrado. Creando TargetManager de emergencia...")
    XLORENs.TargetManager = { CurrentTarget = nil, Settings = { FOV = 150, LockTime = 0.35 } }
    function XLORENs.TargetManager:GetTarget(origin)
        if XLORENs.WallChecker and XLORENs.WallChecker.GetBestEnemy then
            self.CurrentTarget = XLORENs.WallChecker:GetBestEnemy(origin)
        else
            local best, bestDist = nil, math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local char = plr.Character
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                        if head then
                            local dist = (head.Position - origin).Magnitude
                            if dist < bestDist then
                                bestDist = dist
                                best = { Character = char, Position = head.Position, VisiblePart = head, GetAimPart = function() return head end, GetPredictionPosition = function() return head.Position end }
                            end
                        end
                    end
                end
            end
            self.CurrentTarget = best
        end
        return self.CurrentTarget
    end
    function XLORENs.TargetManager:GetCurrentTarget() return self.CurrentTarget end
    print("[XLORENs] TargetManager de emergencia asignado.")
end

-- === FALLBACK: WallChecker ===
if not XLORENs.WallChecker then
    print("[XLORENs] WallChecker no encontrado. Creando WallChecker de emergencia...")
    XLORENs.WallChecker = { Settings = { MaxDistance = 500, MinimumVisibility = 0.15 } }
    function XLORENs.WallChecker:GetBestEnemy(origin)
        local best, bestDist = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local char = plr.Character
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                    if head then
                        local dist = (head.Position - origin).Magnitude
                        if dist < bestDist then
                            bestDist = dist
                            best = { Character = char, Position = head.Position, VisiblePart = head, GetAimPart = function() return head end, GetPredictionPosition = function() return head.Position end }
                        end
                    end
                end
            end
        end
        return best
    end
    function XLORENs.WallChecker:IsEnemy(player) return player ~= LocalPlayer end
    print("[XLORENs] WallChecker de emergencia asignado.")
end

-- ====================================================
-- CREAR VENTANA PRINCIPAL Y FORZAR APERTURA
-- ====================================================
print("[XLORENs] Creando ventana principal...")

local window
local windowSuccess, windowError = pcall(function()
    window = XLORENs.UI:CreateWindow({
        Name = "XLORENs Pro",
        Keybind = "K"
    })
end)

if not windowSuccess then
    print("[XLORENs] Error al crear la ventana: " .. tostring(windowError))
    -- UI de error simple
    local emergencyGui = Instance.new("ScreenGui")
    emergencyGui.Name = "XLORENs_Error"
    emergencyGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    local errorFrame = Instance.new("Frame")
    errorFrame.Size = UDim2.new(0, 300, 0, 150)
    errorFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
    errorFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 10)
    errorFrame.BorderSizePixel = 0
    errorFrame.Parent = emergencyGui
    Instance.new("UICorner", errorFrame).CornerRadius = UDim.new(0, 8)
    local errLabel = Instance.new("TextLabel")
    errLabel.Size = UDim2.new(1, -20, 1, 0)
    errLabel.Position = UDim2.new(0, 10, 0, 0)
    errLabel.BackgroundTransparency = 1
    errLabel.Text = "Error al cargar la UI.\nAimbot de emergencia activo.\nPresiona K para intentar abrir."
    errLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
    errLabel.Font = Enum.Font.GothamBold
    errLabel.TextSize = 14
    errLabel.TextWrapped = true
    errLabel.Parent = errorFrame
    errorFrame.Visible = true
    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.K then
            errorFrame.Visible = not errorFrame.Visible
        end
    end)
    print("[XLORENs] UI de error creada.")
else
    print("[XLORENs] Ventana creada correctamente.")
    -- FORZAR APERTURA AUTOMÁTICA
    task.wait(0.2)
    if window and window.Open then
        window:Open()
        print("[XLORENs] Ventana abierta automáticamente.")
    elseif window and window.Toggle then
        window:Toggle()
        print("[XLORENs] Ventana abierta automáticamente (Toggle).")
    end
end

-- ====================================================
-- BUCLE PRINCIPAL (PROTEGIDO)
-- ====================================================
print("[XLORENs] Iniciando bucle principal...")

RunService.RenderStepped:Connect(function()
    pcall(function()
        if XLORENs.Aimbot and XLORENs.Aimbot.Settings and XLORENs.Aimbot.Settings.Enabled then
            local char = LocalPlayer.Character
            if char then
                local origin = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                if origin then
                    if XLORENs.TargetManager then XLORENs.TargetManager:GetTarget(origin.Position) end
                    if XLORENs.Aimbot.Update then XLORENs.Aimbot:Update() end
                end
            end
        end
    end)
end)

-- ====================================================
-- NOTIFICACIÓN FINAL
-- ====================================================
task.wait(1)
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "XLORENs Pro",
    Text = "Cargado! La interfaz se abrirá automáticamente. Presiona K para cerrar/abrir.",
    Duration = 4
})

print("[XLORENs] ¡Sistema listo! Interfaz abierta automáticamente.")
