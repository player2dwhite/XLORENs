--[=[
    XLORENs - UI Window
    Sistema de ventana minimalista con tabs, toggles, sliders y keybinds.
]=]

local UI = {}

function UI:CreateWindow(config)
    config = config or {}
    local window = {
        Name = config.Name or "XLORENs",
        Keybind = config.Keybind or "K",
        Tabs = {},
        Visible = true,
    }

    local player = game:GetService("Players").LocalPlayer
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XLORENs"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    -- Frame principal
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 420, 0, 520)
    main.Position = UDim2.new(0.5, -210, 0.5, -260)
    main.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = screenGui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

    -- Título
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

    -- Tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, 0, 1, -44)
    tabContainer.Position = UDim2.new(0, 0, 0, 44)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = main

    -- Tab buttons
    local tabButtons = Instance.new("Frame")
    tabButtons.Size = UDim2.new(1, 0, 0, 36)
    tabButtons.BackgroundTransparency = 1
    tabButtons.Parent = tabContainer

    -- Content area
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

        -- Tab button
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

        -- Tab content frame
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.Visible = (#window.Tabs == 0)
        frame.Parent = content

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = frame

        -- Funciones para añadir elementos
        function tab:AddToggle(text, callback)
            local active = false

            local frame2 = Instance.new("Frame")
            frame2.Size = UDim2.new(1, -5, 0, 44)
            frame2.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
            frame2.BorderSizePixel = 0
            frame2.Parent = frame
            Instance.new("UICorner", frame2).CornerRadius = UDim.new(0, 8)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(220, 220, 235)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame2

            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(0, 42, 0, 24)
            bg.Position = UDim2.new(1, -52, 0.5, -12)
            bg.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
            bg.BorderSizePixel = 0
            bg.Parent = frame2
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
            btn2.Parent = frame2

            local function setState(state)
                active = state
                bg.BackgroundColor3 = active and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(50, 50, 65)
                knob.Position = active and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
                if callback then callback(active) end
            end

            btn2.MouseButton1Click:Connect(function()
                setState(not active)
            end)

            return { Set = setState, Get = function() return active end }
        end

        function tab:AddSlider(text, min, max, default, callback)
            local value = default or min

            local frame2 = Instance.new("Frame")
            frame2.Size = UDim2.new(1, -5, 0, 64)
            frame2.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
            frame2.BorderSizePixel = 0
            frame2.Parent = frame
            Instance.new("UICorner", frame2).CornerRadius = UDim.new(0, 8)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -12, 0, 22)
            label.Position = UDim2.new(0, 12, 0, 8)
            label.BackgroundTransparency = 1
            label.Text = text .. ": " .. value
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(220, 220, 235)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame2

            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -24, 0, 6)
            track.Position = UDim2.new(0, 12, 0, 42)
            track.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
            track.BorderSizePixel = 0
            track.Parent = frame2
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
                local mouse = game:GetService("UserInputService"):GetMouseLocation()
                local m = math.clamp((mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (m * (max - min)))
                label.Text = text .. ": " .. value
                fill.Size = UDim2.new(m, 0, 1, 0)
                handle.Position = UDim2.new(m, -8, 0.5, -8)
                if callback then callback(value) end
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    update()
                end
            end)

            game:GetService("UserInputService").InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    update()
                end
            end)

            game:GetService("UserInputService").InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            return { Set = function(v) value = v; label.Text = text .. ": " .. value end }
        end

        function tab:AddKeybind(text, defaultKey, callback)
            local key = defaultKey or "None"
            local binding = false

            local frame2 = Instance.new("Frame")
            frame2.Size = UDim2.new(1, -5, 0, 44)
            frame2.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
            frame2.BorderSizePixel = 0
            frame2.Parent = frame
            Instance.new("UICorner", frame2).CornerRadius = UDim.new(0, 8)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0, 160, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(220, 220, 235)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame2

            local btn2 = Instance.new("TextButton")
            btn2.Size = UDim2.new(0, 60, 0, 28)
            btn2.Position = UDim2.new(1, -70, 0.5, -14)
            btn2.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            btn2.Text = key
            btn2.Font = Enum.Font.GothamBold
            btn2.TextSize = 11
            btn2.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn2.AutoButtonColor = false
            btn2.Parent = frame2
            Instance.new("UICorner", btn2).CornerRadius = UDim.new(0, 6)

            btn2.MouseButton1Click:Connect(function()
                binding = true
                btn2.Text = "..."
                btn2.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
            end)

            game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
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
                if callback then callback(key) end
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

        window.Tabs[#window.Tabs + 1] = {
            Name = name,
            Frame = frame,
            Button = btn,
            AddToggle = tab.AddToggle,
            AddSlider = tab.AddSlider,
            AddKeybind = tab.AddKeybind,
            AddLabel = tab.AddLabel,
        }

        return tab
    end

    window:AddTab = AddTab

    -- Mostrar/ocultar
    function window:Toggle()
        self.Visible = not self.Visible
        main.Visible = self.Visible
    end

    -- Keybind global
    game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode[window.Keybind] then
            window:Toggle()
        end
    end)

    return window
end

return UI
