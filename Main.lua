--[=[
    XLORENs - Main (sintácticamente correcto)
]=]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

print("[XLORENs] Iniciando...")

-- UI simple
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XLORENs"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 350, 0, 300)
main.Position = UDim2.new(0.5, -175, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
main.BorderSizePixel = 0
main.Visible = true
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
title.Text = "XLORENs Pro"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.Parent = main

-- Toggle
local toggleFrame = Instance.new("Frame")
toggleFrame.Size = UDim2.new(1, -20, 0, 40)
toggleFrame.Position = UDim2.new(0, 10, 0, 50)
toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
toggleFrame.Parent = main

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -60, 1, 0)
label.Position = UDim2.new(0, 10, 0, 0)
label.BackgroundTransparency = 1
label.Text = "Aimbot"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = toggleFrame

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 40, 0, 24)
bg.Position = UDim2.new(1, -50, 0.5, -12)
bg.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
bg.Parent = toggleFrame

local knob = Instance.new("Frame")
knob.Size = UDim2.new(0, 20, 0, 20)
knob.Position = UDim2.new(0, 2, 0.5, -10)
knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
knob.Parent = bg

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, 0, 1, 0)
btn.BackgroundTransparency = 1
btn.Text = ""
btn.Parent = toggleFrame

local active = false
btn.MouseButton1Click:Connect(function()
    active = not active
    bg.BackgroundColor3 = active and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(50, 50, 65)
    knob.Position = active and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
end)

-- Keybind para cerrar
UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.K then
        main.Visible = not main.Visible
    end
end)

print("[XLORENs] UI cargada. Presiona K para ocultar/mostrar.")
