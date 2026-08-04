--[=[
    XLORENs - Main
    Punto de entrada con UI completa (ESP, Aimbot, Trigger, About, Movement).
]=]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

print("[XLORENs] Iniciando...")

-- ====================================================
-- UI EMBEBIDA (se usa si Window.lua falla)
-- ====================================================
local function CreateUI(config)
    config = config or {}
    local window = {
        Name = config.Name or "XLORENs Pro",
        Keybind = config.Keybind or "K",
        Tabs = {},
        Visible = true,
    }

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XLORENs_UI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 999
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 420, 0, 520)
    main.Position = UDim2.new(0.5, -210, 0.5, -260)
    main.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Visible = true
    main.Parent = screenGui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 44)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    title.Text = window.Name
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 20
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Parent = main
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, 0, 1, -44)
    tabContainer.Position = UDim2.new(0, 0, 0, 44)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = main

    local tabButtons = Instance.new("Frame")
    tabButtons.Size = UDim2.new(1, 0, 0, 36)
    tabButtons.BackgroundTransparency = 1
    tabButtons.Parent = tabContainer

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -10, 1, -46)
    content.Position = UDim2.new(0, 5, 0, 40)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 80)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.Parent = tabContainer

    local function AddTab(name)
        local tab = { Name = name, Elements = {} }
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 80, 1, 0)
        btn.Position = UDim2.new(#window.Tabs * 0.11, 0, 0, 0)
        btn.BackgroundTransparency = 1
        btn.Text = name
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.TextColor3 = Color3.fromRGB(150, 150, 170)
        btn.AutoButtonColor = false
        btn.Parent = tabButtons
        btn.MouseButton1Click:Connect(function()
            for _, t in ipairs(window.Tabs) do
                t.Frame.Visible = false
                t.Button.TextColor3 = Color3.fromRGB(150, 150, 170)
            end
            tab.Frame.Visible = true
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.Visible = (#window.Tabs == 0)
        frame.Parent = content

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = frame

        -- ========== Elementos de UI ==========
        function tab:AddToggle(text, callback)
            local active = false
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, -5, 0, 44)
            f.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
            f.BorderSizePixel = 0
            f.Parent = frame
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(220, 220, 235)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = f

            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(0, 42, 0, 24)
            bg.Position = UDim2.new(1, -52, 0.5, -12)
            bg.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
            bg.BorderSizePixel = 0
            bg.Parent = f
            Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 20, 0, 20)
            knob.Position = UDim2.new(0, 2, 0.5, -10)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.Parent = bg
            Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

            local btn2 = Instance.new("TextButton")
            btn2.Size = UDim2.new(1, 0, 1, 0)
            btn2.BackgroundTransparency = 1
            btn2.Text = ""
            btn2.Parent = f

            local function setState(state)
                active = state
                bg.BackgroundColor3 = active and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(50, 50, 65)
                knob.Position = active and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
                if callback then pcall(callback, active) end
            end

            btn2.MouseButton1Click:Connect(function() setState(not active) end)
            return { Set = setState, Get = function() return active end }
        end

        function tab:AddSlider(text, min, max, default, callback)
            local value = default or min
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, -5, 0, 64)
            f.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
            f.BorderSizePixel = 0
            f.Parent = frame
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -12, 0, 22)
            label.Position = UDim2.new(0, 12, 0, 8)
            label.BackgroundTransparency = 1
            label.Text = text .. ": " .. value
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(220, 220, 235)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = f

            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -24, 0, 6)
            track.Position = UDim2.new(0, 12, 0, 42)
            track.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
            track.BorderSizePixel = 0
            track.Parent = f
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

        function tab:AddKeybind(text, defaultKey, callback)
            local key = defaultKey or "None"
            local binding = false
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, -5, 0, 44)
            f.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
            f.BorderSizePixel = 0
            f.Parent = frame
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0, 160, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(220, 220, 235)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = f

            local btn2 = Instance.new("TextButton")
            btn2.Size = UDim2.new(0, 60, 0, 28)
            btn2.Position = UDim2.new(1, -70, 0.5, -14)
            btn2.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            btn2.Text = key
            btn2.Font = Enum.Font.GothamBold
            btn2.TextSize = 11
            btn2.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn2.AutoButtonColor = false
            btn2.Parent = f
            Instance.new("UICorner", btn2).CornerRadius = UDim.new(0, 6)

            btn2.MouseButton1Click:Connect(function()
                binding = true
                btn2.Text = "..."
                btn2.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
            end)

            UIS.InputBegan:Connect(function(input, gp)
                if not binding or gp then return end
                if input.KeyCode == Enum.KeyCode.Escape then
                    binding = false
                    btn2.Text = key
                    btn2.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
                    return
                end
                key = input.KeyCode.Name
                btn2.Text = key
                binding = false
                btn2.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
                if callback then pcall(callback, key) end
            end)

            return { GetKey = function() return key end }
        end

        function tab:AddLabel(text)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -10, 0, 28)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 13
            lbl.TextColor3 = Color3.fromRGB(150, 150, 170)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = frame
            return lbl
        end

        function tab:AddSeparator()
            local sep = Instance.new("Frame")
            sep.Size = UDim2.new(1, -10, 0, 2)
            sep.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            sep.BorderSizePixel = 0
            sep.Parent = frame
            return sep
        end

        function tab:AddDropdown(text, options, default, callback)
            local selected = default or options[1] or ""
            local open = false
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, -5, 0, 44)
            f.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
            f.BorderSizePixel = 0
            f.ClipsDescendants = false
            f.Parent = frame
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0, 100, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(220, 220, 235)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = f

            local btn2 = Instance.new("TextButton")
            btn2.Size = UDim2.new(1, -120, 0, 28)
            btn2.Position = UDim2.new(0, 105, 0.5, -14)
            btn2.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            btn2.Text = selected
            btn2.Font = Enum.Font.GothamBold
            btn2.TextSize = 11
            btn2.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn2.AutoButtonColor = false
            btn2.Parent = f
            Instance.new("UICorner", btn2).CornerRadius = UDim.new(0, 6)

            local dropdownFrame = Instance.new("Frame")
            dropdownFrame.Size = UDim2.new(1, -105, 0, 0)
            dropdownFrame.Position = UDim2.new(0, 105, 0, 32)
            dropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            dropdownFrame.BorderSizePixel = 0
            dropdownFrame.ClipsDescendants = true
            dropdownFrame.Visible = false
            dropdownFrame.Parent = f
            Instance.new("UICorner", dropdownFrame).CornerRadius = UDim.new(0, 6)

            local scroll = Instance.new("ScrollingFrame")
            scroll.Size = UDim2.new(1, 0, 1, 0)
            scroll.BackgroundTransparency = 1
            scroll.ScrollBarThickness = 2
            scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            scroll.Parent = dropdownFrame

            local layout2 = Instance.new("UIListLayout")
            layout2.Padding = UDim.new(0, 2)
            layout2.SortOrder = Enum.SortOrder.LayoutOrder
            layout2.Parent = scroll

            local function updateDropdownHeight()
                local count = #scroll:GetChildren()
                local height = math.min(count * 26 + 4, 120)
                dropdownFrame.Size = UDim2.new(1, -105, 0, height)
            end

            local function selectOption(option)
                selected = option
                btn2.Text = option
                dropdownFrame.Visible = false
                open = false
                if callback then pcall(callback, option) end
            end

            for _, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, -4, 0, 24)
                optBtn.Position = UDim2.new(0, 2, 0, 0)
                optBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                optBtn.Text = opt
                optBtn.Font = Enum.Font.GothamBold
                optBtn.TextSize = 11
                optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
                optBtn.AutoButtonColor = false
                optBtn.Parent = scroll
                optBtn.MouseButton1Click:Connect(function() selectOption(opt) end)
            end
            updateDropdownHeight()

            btn2.MouseButton1Click:Connect(function()
                open = not open
                dropdownFrame.Visible = open
                if open then
                    updateDropdownHeight()
                    dropdownFrame.Size = UDim2.new(1, -105, 0, 0)
                    dropdownFrame.Size = UDim2.new(1, -105, 0, math.min(#options * 26 + 4, 120))
                end
            end)

            return {
                Set = function(opt) selectOption(opt) end,
                Get = function() return selected end
            }
        end

        function tab:AddModeSelector(text, modes, defaultMode, callback)
            local selected = defaultMode or modes[1] or "Siempre"
            local bindKey = "None"
            local binding = false

            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, -5, 0, 90)
            f.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
            f.BorderSizePixel = 0
            f.Parent = frame
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -12, 0, 22)
            label.Position = UDim2.new(0, 12, 0, 6)
            label.BackgroundTransparency = 1
            label.Text = text
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(220, 220, 235)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = f

            local modeContainer = Instance.new("Frame")
            modeContainer.Size = UDim2.new(1, -24, 0, 24)
            modeContainer.Position = UDim2.new(0, 12, 0, 32)
            modeContainer.BackgroundTransparency = 1
            modeContainer.Parent = f

            local modeButtons = {}
            for i, modeName in ipairs(modes) do
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1/#modes, -2, 1, 0)
                btn.Position = UDim2.new((i-1)/#modes, 1, 0, 0)
                btn.BackgroundColor3 = (modeName == selected) and Color3.fromRGB(60, 120, 200) or Color3.fromRGB(40, 40, 50)
                btn.Text = modeName
                btn.Font = Enum.Font.GothamBold
                btn.TextSize = 11
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.AutoButtonColor = false
                btn.Parent = modeContainer
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                btn.MouseButton1Click:Connect(function()
                    selected = modeName
                    for _, b in ipairs(modeButtons) do
                        b.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                    end
                    btn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
                    if callback then pcall(callback, selected, bindKey) end
                end)
                table.insert(modeButtons, btn)
            end

            local bindBtn = Instance.new("TextButton")
            bindBtn.Size = UDim2.new(0.6, 0, 0, 24)
            bindBtn.Position = UDim2.new(0, 12, 0, 60)
            bindBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            bindBtn.Text = "Bind: " .. bindKey
            bindBtn.Font = Enum.Font.GothamBold
            bindBtn.TextSize = 11
            bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            bindBtn.AutoButtonColor = false
            bindBtn.Parent = f
            Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 4)

            bindBtn.MouseButton1Click:Connect(function()
                binding = true
                bindBtn.Text = "[Press key]"
                bindBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 60)
            end)

            UIS.InputBegan:Connect(function(input, gp)
                if not binding or gp then return end
                if input.KeyCode == Enum.KeyCode.Escape then
                    binding = false
                    bindBtn.Text = "Bind: " .. bindKey
                    bindBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
                    return
                end
                bindKey = input.KeyCode.Name
                bindBtn.Text = "Bind: " .. bindKey
                binding = false
                bindBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
                if callback then pcall(callback, selected, bindKey) end
            end)

            return {
                GetMode = function() return selected end,
                GetBind = function() return bindKey end,
                SetMode = function(m) selected = m; for _, b in ipairs(modeButtons) do
                    b.BackgroundColor3 = (b.Text == m) and Color3.fromRGB(60, 120, 200) or Color3.fromRGB(40, 40, 50)
                end end,
                SetBind = function(k) bindKey = k; bindBtn.Text = "Bind: " .. k end
            }
        end

        window.Tabs[#window.Tabs + 1] = {
            Name = name,
            Frame = frame,
            Button = btn,
            AddToggle = tab.AddToggle,
            AddSlider = tab.AddSlider,
            AddKeybind = tab.AddKeybind,
            AddLabel = tab.AddLabel,
            AddSeparator = tab.AddSeparator,
            AddDropdown = tab.AddDropdown,
            AddModeSelector = tab.AddModeSelector,
        }
        return tab
    end

    window:AddTab = AddTab

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

    return window
end

-- ====================================================
-- CARGAR XLORENs (Loader.lua)
-- ====================================================
local XLORENs

local loaderSuccess, loaderResult = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/player2dwhite/XLORENs/main/Core/Loader.lua"))()
end)

if loaderSuccess and loaderResult then
    XLORENs = loaderResult
    XLORENs:Initialize()
    print("[XLORENs] Loader ejecutado correctamente.")
else
    print("[XLORENs] Loader falló. Creando estructura básica...")
    XLORENs = {
        UI = { CreateWindow = CreateUI },
        ConsoleBypass = nil,
        WallChecker = nil,
        TargetManager = nil,
        Aimbot = nil,
        Charms = nil,
        Movement = nil,
    }
end

-- Asegurar UI
if not XLORENs.UI or not XLORENs.UI.CreateWindow then
    XLORENs.UI = { CreateWindow = CreateUI }
end

-- ====================================================
-- CREAR VENTANA (usando UI/Window.lua o la embebida)
-- ====================================================
print("[XLORENs] Creando ventana...")
local window = XLORENs.UI:CreateWindow({ Name = "XLORENs Pro", Keybind = "K" })
task.wait(0.2)
window:Open()
print("[XLORENs] Ventana abierta automáticamente.")

-- ====================================================
-- VARIABLES DE ESTADO
-- ====================================================
local noRecoilRunning = false
local noRecoilConn = nil
local trigEnabled = false
local trigMode = "Nunca"
local trigBind = "F"
local fullbrightEnabled = false
local fullbrightConnection = nil

-- ====================================================
-- FUNCIONES (No Recoil, Fullbright, Trigger)
-- ====================================================
local function startNoRecoil()
    if noRecoilRunning then return end
    noRecoilRunning = true
    noRecoilConn = RunService.Heartbeat:Connect(function()
        if not noRecoilRunning then
            noRecoilConn:Disconnect()
            noRecoilConn = nil
            return
        end
        local recoil = LocalPlayer:FindFirstChild("Recoil")
        if recoil then pcall(function() recoil:Destroy() end) end
    end)
end

local function stopNoRecoil()
    noRecoilRunning = false
    if noRecoilConn then
        noRecoilConn:Disconnect()
        noRecoilConn = nil
    end
end

local function toggleFullbright(state)
    fullbrightEnabled = state
    if fullbrightConnection then
        fullbrightConnection:Disconnect()
        fullbrightConnection = nil
    end
    if state then
        fullbrightConnection = RunService.RenderStepped:Connect(function()
            Lighting.ClockTime = 12
            Lighting:SetMinutesAfterMidnight(720)
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
            if Lighting:FindFirstChild("Atmosphere") then
                Lighting.Atmosphere:Destroy()
            end
            for _, child in ipairs(Lighting:GetChildren()) do
                if child:IsA("Atmosphere") or child:IsA("Sky") or child.Name == "Fog" then
                    child:Destroy()
                end
            end
        end)
    end
end

local function shouldTrigger()
    if not trigEnabled then return false end
    if trigMode == "Nunca" then return false end
    if trigMode == "Siempre" then return true end
    if trigMode == "Por bind" then
        return UIS:IsKeyDown(Enum.KeyCode[trigBind])
    end
    return false
end

RunService.RenderStepped:Connect(function()
    if shouldTrigger() then
        local mouse = LocalPlayer:GetMouse()
        local target = mouse.Target
        if target and target.Parent then
            local hum = target.Parent:FindFirstChildOfClass("Humanoid")
            local char = target.Parent
            if not hum and char.Parent then
                hum = char.Parent:FindFirstChildOfClass("Humanoid")
                if hum then char = char.Parent end
            end
            if hum and hum.Health > 0 and char ~= LocalPlayer.Character then
                mouse1press()
                task.wait(0.05)
                mouse1release()
            end
        end
    end
end)

-- ====================================================
-- BUCLE PRINCIPAL
-- ====================================================
local lastTime = tick()

RunService.RenderStepped:Connect(function()
    local currentTime = tick()
    local deltaTime = math.min(currentTime - lastTime, 0.05)
    lastTime = currentTime

    if XLORENs.Aimbot and XLORENs.Aimbot._settings.General.Enabled then
        local character = LocalPlayer.Character
        if character then
            local originPart = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
            if originPart then
                local target = XLORENs.TargetManager:GetTarget(originPart.Position)
                XLORENs.Aimbot:Update(target, deltaTime)
            end
        end
    end
end)

-- ====================================================
-- CONFIGURACIÓN DE UI (todas las pestañas completas)
-- ====================================================

-- Pestaña Aimbot
local aimTab = window:AddTab("Aimbot")
local aimToggle = aimTab:AddToggle("Aimbot", function(state)
    if state then
        if XLORENs.Aimbot then XLORENs.Aimbot:Enable() end
    else
        if XLORENs.Aimbot then XLORENs.Aimbot:Disable() end
    end
end)

aimTab:AddModeSelector("Modo", {"Siempre", "Por bind", "Nunca"}, "Siempre", function(mode, bind)
    if XLORENs.Aimbot then
        XLORENs.Aimbot._settings.General.Mode = mode
        XLORENs.Aimbot._settings.General.BindKey = bind
    end
end)

aimTab:AddSeparator()

-- FOV
aimTab:AddSlider("FOV (pixels)", 10, 500, 200, function(v)
    if XLORENs.Aimbot then
        XLORENs.Aimbot._settings.FOV.Radius = v
        XLORENs.Aimbot:CreateFOVCircle()
    end
end)

aimTab:AddToggle("Mostrar FOV", function(state)
    if XLORENs.Aimbot then
        XLORENs.Aimbot._settings.FOV.Enabled = state
        XLORENs.Aimbot:CreateFOVCircle()
    end
end)

aimTab:AddToggle("FOV Pulse", function(state)
    if XLORENs.Aimbot then
        XLORENs.Aimbot._settings.FOV.Pulse = state
        XLORENs.Aimbot:CreateFOVCircle()
    end
end)

aimTab:AddSeparator()

-- Modo de apuntado
aimTab:AddDropdown("Modo de apuntado", {"HeadOnly", "HumanLike"}, "HumanLike", function(selected)
    if XLORENs.Aimbot then
        XLORENs.Aimbot._settings.Aim.AimMode = selected
    end
end)

aimTab:AddSeparator()

-- Smooth
aimTab:AddToggle("Smooth", function(state)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Aim.Smooth = state end
end)

aimTab:AddSlider("Smooth Amount", 0, 100, 65, function(v)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Aim.SmoothAmount = v end
end)

aimTab:AddSlider("Smooth Variation", 0, 10, 2, function(v)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Aim.SmoothVariation = v end
end)

aimTab:AddSlider("Inertia", 0, 1, 0.18, function(v)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Aim.Inertia = v end
end)

aimTab:AddSeparator()
aimTab:AddLabel("=== Movimiento Orgánico ===")

aimTab:AddToggle("Offset Humano", function(state)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Aim.Offset.Enabled = state end
end)

aimTab:AddSlider("Offset Switch Time", 0.2, 2, 0.7, function(v)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Aim.Offset.SwitchTime = v end
end)

aimTab:AddToggle("Predicción", function(state)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Aim.Prediction.Enabled = state end
end)

aimTab:AddSlider("Predicción Base", 0.05, 0.3, 0.12, function(v)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Aim.Prediction.Base = v end
end)

aimTab:AddSlider("Predicción Variation", 0, 0.05, 0.02, function(v)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Aim.Prediction.Variation = v end
end)

aimTab:AddSlider("Error de seguimiento", 0, 0.15, 0.05, function(v)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Aim.ErrorScale = v end
end)

aimTab:AddSlider("Overshoot", 0, 0.08, 0.02, function(v)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Aim.Overshoot = v end
end)

aimTab:AddSlider("Deadzone", 0, 10, 2, function(v)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Aim.Deadzone = v end
end)

aimTab:AddSeparator()
aimTab:AddLabel("=== Límites ===")

aimTab:AddSlider("Max Turn Speed (deg/s)", 0, 720, 360, function(v)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.General.MaxTurnSpeed = v end
end)

aimTab:AddSlider("View Angle", 0, 180, 90, function(v)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.General.ViewAngle = v end
end)

aimTab:AddSlider("Grace Period (s)", 0, 0.5, 0.15, function(v)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.General.GracePeriod = v end
end)

aimTab:AddSlider("Reaction Time (s)", 0, 0.5, 0.15, function(v)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Aim.ReactionTime = v end
end)

aimTab:AddSeparator()
aimTab:AddLabel("=== Arma ===")

aimTab:AddToggle("No Recoil", function(state)
    if state then startNoRecoil() else stopNoRecoil() end
end)

aimTab:AddToggle("Recoil (cámara)", function(state)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Recoil.Enabled = state end
end)

aimTab:AddSlider("Recoil Intensity", 0, 1, 0.3, function(v)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Recoil.Intensity = v end
end)

aimTab:AddSlider("Recoil Decay", 0.5, 1, 0.9, function(v)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.Recoil.Decay = v end
end)

aimTab:AddSeparator()
aimTab:AddLabel("=== Auto-Scope ===")
aimTab:AddToggle("Auto-Scope (Móvil)", function(state)
    if XLORENs.Aimbot then XLORENs.Aimbot._settings.AutoScope = state end
end)

-- Pestaña Trigger
local trigTab = window:AddTab("Trigger")
trigTab:AddToggle("Trigger Bot", function(state) trigEnabled = state end)
trigTab:AddModeSelector("Modo", {"Siempre", "Por bind", "Nunca"}, trigMode, function(mode, bind)
    trigMode = mode
    trigBind = bind
end)

-- Pestaña ESP
local espTab = window:AddTab("ESP")
espTab:AddToggle("ESP", function(state)
    if state then
        if XLORENs.Chams then XLORENs.Chams:Enable() end
    else
        if XLORENs.Chams then XLORENs.Chams:Disable() end
    end
end)

espTab:AddSeparator()
espTab:AddLabel("=== Highlights ===")
espTab:AddToggle("Chams", function(state)
    if XLORENs.Chams then XLORENs.Chams._settings.Highlights.Enabled = state end
end)
espTab:AddToggle("Color por salud", function(state)
    if XLORENs.Chams then XLORENs.Chams._settings.Highlights.ColorByHealth = state end
end)
espTab:AddToggle("Color por equipo", function(state)
    if XLORENs.Chams then XLORENs.Chams._settings.Highlights.ColorByTeam = state end
end)

espTab:AddSeparator()
espTab:AddLabel("=== Box ESP ===")
espTab:AddToggle("Box ESP", function(state)
    if XLORENs.Chams then XLORENs.Chams._settings.Box.Enabled = state end
end)
espTab:AddSlider("Box Grosor", 1, 5, 2, function(v)
    if XLORENs.Chams then XLORENs.Chams._settings.Box.Thickness = v end
end)

espTab:AddSeparator()
espTab:AddLabel("=== Información ===")
espTab:AddToggle("Info ESP", function(state)
    if XLORENs.Chams then XLORENs.Chams._settings.Info.Enabled = state end
end)
espTab:AddToggle("Mostrar nombre", function(state)
    if XLORENs.Chams then XLORENs.Chams._settings.Info.ShowName = state end
end)
espTab:AddToggle("Mostrar salud", function(state)
    if XLORENs.Chams then XLORENs.Chams._settings.Info.ShowHealth = state end
end)
espTab:AddToggle("Mostrar distancia", function(state)
    if XLORENs.Chams then XLORENs.Chams._settings.Info.ShowDistance = state end
end)

espTab:AddSeparator()
espTab:AddLabel("=== Visibilidad ===")
espTab:AddToggle("Detección de pared", function(state)
    if XLORENs.Chams then XLORENs.Chams._settings.Visibility.UseWallCheck = state end
end)

espTab:AddSeparator()
espTab:AddLabel("=== Colores ===")
local cr = espTab:AddSlider("Color R", 0, 255, 0, function(v)
    if XLORENs.Chams then
        local c = Color3.fromRGB(v, cg.Get(), cb.Get())
        XLORENs.Chams._settings.Highlights.Color = c
        XLORENs.Chams._settings.Box.Color = c
    end
end)
local cg = espTab:AddSlider("Color G", 0, 255, 255, function(v)
    if XLORENs.Chams then
        local c = Color3.fromRGB(cr.Get(), v, cb.Get())
        XLORENs.Chams._settings.Highlights.Color = c
        XLORENs.Chams._settings.Box.Color = c
    end
end)
local cb = espTab:AddSlider("Color B", 0, 255, 0, function(v)
    if XLORENs.Chams then
        local c = Color3.fromRGB(cr.Get(), cg.Get(), v)
        XLORENs.Chams._settings.Highlights.Color = c
        XLORENs.Chams._settings.Box.Color = c
    end
end)
espTab:AddSlider("Transparencia", 0, 100, 70, function(v)
    if XLORENs.Chams then XLORENs.Chams._settings.Highlights.Transparency = v / 100 end
end)

-- Pestaña WallChecker
local wallTab = window:AddTab("WallCheck")
wallTab:AddSlider("Min Visibility", 0, 1, 0.15, function(v)
    if XLORENs.WallChecker then XLORENs.WallChecker._settings.MinimumVisibility = v end
end)
wallTab:AddSlider("Max Distance", 100, 1000, 500, function(v)
    if XLORENs.WallChecker then XLORENs.WallChecker._settings.MaxDistance = v end
end)
wallTab:AddToggle("Team Check", function(state)
    if XLORENs.WallChecker then XLORENs.WallChecker._settings.TeamCheckMode = state and "Auto" or "Disabled" end
end)
wallTab:AddToggle("Ignore Same Team", function(state)
    if XLORENs.WallChecker then XLORENs.WallChecker._settings.IgnoreSameTeam = state end
end)

-- Pestaña Movement
local moveTab = window:AddTab("Movement")
moveTab:AddLabel("=== Velocidad ===")
moveTab:AddSlider("Walk Speed", 10, 250, 16, function(v)
    if XLORENs.Movement then XLORENs.Movement._settings.WalkSpeed = v end
end)
moveTab:AddSlider("Jump Power", 30, 200, 50, function(v)
    if XLORENs.Movement then XLORENs.Movement._settings.JumpPower = v end
end)
moveTab:AddLabel("=== Saltos ===")
moveTab:AddToggle("Infinite Jump", function(state)
    if XLORENs.Movement then XLORENs.Movement._settings.InfiniteJump = state end
end)
moveTab:AddLabel("=== Vuelo ===")
moveTab:AddToggle("Fly Mode", function(state)
    if XLORENs.Movement then
        XLORENs.Movement._settings.Fly.Enabled = state
        if not state and XLORENs.Movement._isFlying then
            XLORENs.Movement:ToggleFly()
        end
    end
end)
moveTab:AddSlider("Fly Speed", 10, 150, 50, function(v)
    if XLORENs.Movement then XLORENs.Movement._settings.Fly.Speed = v end
end)
moveTab:AddToggle("Activar Vuelo", function(state)
    if XLORENs.Movement and XLORENs.Movement._settings.Fly.Enabled then
        XLORENs.Movement:ToggleFly()
    end
end)
moveTab:AddLabel("=== Noclip ===")
moveTab:AddToggle("Noclip", function(state)
    if XLORENs.Movement then XLORENs.Movement._settings.Noclip = state end
end)
moveTab:AddLabel("=== Freecam ===")
moveTab:AddToggle("Freecam", function(state)
    if XLORENs.Movement then
        XLORENs.Movement._settings.Freecam.Enabled = state
        if state then
            XLORENs.Movement:ToggleFreecam()
        else
            XLORENs.Movement:ToggleFreecam() -- lo apaga
        end
    end
end)
moveTab:AddSlider("Freecam Speed", 10, 150, 30, function(v)
    if XLORENs.Movement then XLORENs.Movement._settings.Freecam.Speed = v end
end)
moveTab:AddSlider("Freecam Sensitivity", 0.1, 2, 0.5, function(v)
    if XLORENs.Movement then XLORENs.Movement._settings.Freecam.Sensitivity = v end
end)

-- Pestaña Misc
local miscTab = window:AddTab("Misc")
miscTab:AddLabel("=== Consola ===")
miscTab:AddToggle("Silenciar logs (Bypass)", function(state)
    if XLORENs.ConsoleBypass then
        if state then XLORENs.ConsoleBypass:Enable() else XLORENs.ConsoleBypass:Disable() end
    end
end)
miscTab:AddSeparator()
miscTab:AddLabel("=== Fullbright ===")
miscTab:AddToggle("Fullbright (Loop)", function(state)
    toggleFullbright(state)
end)

-- Pestaña About
local aboutTab = window:AddTab("About")
aboutTab:AddLabel("XLORENs Pro")
aboutTab:AddLabel("v3.0 - Framework Completo")
aboutTab:AddLabel("")
aboutTab:AddLabel("Módulos:")
aboutTab:AddLabel("• Aimbot v4 (Orgánico)")
aboutTab:AddLabel("• ESP (Chams + Box + Info)")
aboutTab:AddLabel("• WallChecker (Visibilidad)")
aboutTab:AddLabel("• TargetManager")
aboutTab:AddLabel("• Trigger Bot")
aboutTab:AddLabel("• No Recoil")
aboutTab:AddLabel("• Console Bypass")
aboutTab:AddLabel("• Fullbright")
aboutTab:AddLabel("• Movement (Speed, Jump, Fly, Noclip, Freecam)")
aboutTab:AddLabel("")
aboutTab:AddLabel("Teclas:")
aboutTab:AddLabel("• K - Abrir/cerrar menú")
aboutTab:AddLabel("• F - Trigger rápido (bind)")

-- ====================================================
-- INICIALIZAR ESP
-- ====================================================
if XLORENs.Chams then
    XLORENs.Chams:Disable()
end

-- ====================================================
-- NOTIFICACIÓN FINAL
-- ====================================================
task.wait(1)
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "XLORENs Pro",
    Text = "Cargado! Presiona K para abrir el menú.",
    Duration = 4
})

print("[XLORENs] ¡Sistema listo! Framework completo cargado.")
