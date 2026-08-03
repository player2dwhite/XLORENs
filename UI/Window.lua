--[=[
    XLORENs - UI Window (Versión estable y corregida)
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
    screenGui.DisplayOrder = 999
    screenGui.Parent = player:WaitForChild("PlayerGui")

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

        -- Toggle
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

        -- Slider
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
                local mouse = game:GetService("UserInputService"):GetMouseLocation()
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

        -- Keybind
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
                if callback then pcall(callback, key) end
            end)

            return { GetKey = function() return key end }
        end

        -- Label
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

        -- Separador
        function tab:AddSeparator()
            local sep = Instance.new("Frame")
            sep.Size = UDim2.new(1, -10, 0, 2)
            sep.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            sep.BorderSizePixel = 0
            sep.Parent = frame
            return sep
        end

        -- Dropdown
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

            local function updateHeight()
                local count = #scroll:GetChildren()
                local height = math.min(count * 26 + 4, 120)
                dropdownFrame.Size = UDim2.new(1, -105, 0, height)
            end

            local function selectOption(opt)
                selected = opt
                btn2.Text = opt
                dropdownFrame.Visible = false
                open = false
                if callback then pcall(callback, opt) end
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
            updateHeight()

            btn2.MouseButton1Click:Connect(function()
                open = not open
                dropdownFrame.Visible = open
                if open then
                    updateHeight()
                    dropdownFrame.Size = UDim2.new(1, -105, 0, 0)
                    dropdownFrame.Size = UDim2.new(1, -105, 0, math.min(#options * 26 + 4, 120))
                end
            end)

            return { Set = selectOption, Get = function() return selected end }
        end

        -- Modo selector
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

            game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
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

    game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode[window.Keybind] then
            window:Toggle()
        end
    end)

    return window
end

return UI
