--[[
    XLORENs - All-in-One
    Copia y pega esto directamente en Solara.
    No necesita archivos externos.
]]

local player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ===== UI SIMPLIFICADA =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XLORENs"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 400)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
title.Text = "XLORENs"
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = mainFrame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -10, 1, -50)
content.Position = UDim2.new(0, 5, 0, 45)
content.BackgroundTransparency = 1
content.ScrollBarThickness = 3
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

function AddToggle(parent, text, callback)
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
        if callback then callback(active) end
    end

    btn.MouseButton1Click:Connect(function() setState(not active) end)
    return { Set = setState, Get = function() return active end }
end

function AddSlider(parent, text, min, max, default, callback)
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
        if callback then callback(value) end
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

-- ===== VARIABLES =====
local aimbotEnabled = false
local aimbotFOV = 30
local aimbotSmooth = 65
local fovCircle = nil
local noRecoilEnabled = false

-- ===== FUNCIONES =====
-- No Recoil
local function startNoRecoil()
    noRecoilEnabled = true
    task.spawn(function()
        while noRecoilEnabled do
            local recoil = player:FindFirstChild("Recoil")
            if recoil then pcall(function() recoil:Destroy() end) end
            task.wait(0.2)
        end
    end)
end

local function stopNoRecoil()
    noRecoilEnabled = false
end

-- FOV Circle
function createFOVCircle()
    if fovCircle then pcall(function() fovCircle:Remove() end); fovCircle = nil end
    if not aimbotEnabled then return end
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = true
    fovCircle.Thickness = 2
    fovCircle.Transparency = 0.7
    fovCircle.ZIndex = 10
    fovCircle.Filled = false
    fovCircle.NumSides = 64
    fovCircle.Color = Color3.fromRGB(255, 0, 0)

    RunService.RenderStepped:Connect(function()
        if not fovCircle or not aimbotEnabled then
            if fovCircle then fovCircle.Visible = false end
            return
        end
        local mouse = UIS:GetMouseLocation()
        fovCircle.Position = Vector2.new(mouse.X, mouse.Y)
        fovCircle.Radius = aimbotFOV
        fovCircle.Visible = true
    end)
end

-- Aimbot
RunService.RenderStepped:Connect(function()
    if not aimbotEnabled then return end
    local cam = workspace.CurrentCamera
    if not cam then return end

    -- Buscar enemigo más cercano al centro del FOV
    local bestTarget = nil
    local bestDist = math.huge
    local mouse = UIS:GetMouseLocation()

    for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
        if plr ~= player and plr.Character then
            local char = plr.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = char:FindFirstChild("Head")
                if head then
                    local pos, onScreen = cam:WorldToScreenPoint(head.Position)
                    if onScreen then
                        local screenPos = Vector2.new(pos.X, pos.Y)
                        local dist = (screenPos - mouse).Magnitude
                        if dist < aimbotFOV and dist < bestDist then
                            bestDist = dist
                            bestTarget = head
                        end
                    end
                end
            end
        end
    end

    if bestTarget then
        local camPos = cam.CFrame.Position
        local targetPos = bestTarget.Position
        local lookVector = (targetPos - camPos).Unit

        if aimbotSmooth > 0 then
            local smoothFactor = 1 - (aimbotSmooth / 100)
            local currentLook = cam.CFrame.LookVector
            local smoothed = currentLook:Lerp(lookVector, smoothFactor)
            cam.CFrame = CFrame.new(camPos, camPos + smoothed)
        else
            cam.CFrame = CFrame.new(camPos, targetPos)
        end
    end
end)

-- ===== INTERFAZ =====
-- Añadir elementos al menú
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -10, 0, 30)
label.BackgroundTransparency = 1
label.Text = "=== Aimbot ==="
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.TextColor3 = Color3.fromRGB(150, 150, 200)
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = content

local aimToggle = AddToggle(content, "Aimbot", function(state)
    aimbotEnabled = state
    if state then createFOVCircle() else
        if fovCircle then pcall(function() fovCircle:Remove() end); fovCircle = nil end
    end
end)

local fovSlider = AddSlider(content, "FOV", 10, 50, 30, function(v)
    aimbotFOV = v
    if aimbotEnabled then createFOVCircle() end
end)

local smoothSlider = AddSlider(content, "Smooth", 0, 100, 65, function(v)
    aimbotSmooth = v
end)

local noRecoilToggle = AddToggle(content, "No Recoil", function(state)
    if state then startNoRecoil() else stopNoRecoil() end
end)

-- ===== TECLAS =====
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.K then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- ===== NOTIFICACIÓN =====
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "XLORENs",
    Text = "Cargado! Presiona K para el menú",
    Duration = 4
})

print("[XLORENs] Ready! Press K to open menu.")
