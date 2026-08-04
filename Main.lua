--[=[
    XLORENs - Main (solo con UI/Window.lua)
]=]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

print("[XLORENs] Iniciando con Window.lua...")

-- === Cargar Window.lua ===
local windowModule = nil
local loadSuccess, loadResult = pcall(function()
    local raw = game:HttpGet("https://raw.githubusercontent.com/player2dwhite/XLORENs/main/UI/Window.lua")
    if not raw then error("No se pudo descargar Window.lua") end
    local func = loadstring(raw)
    if not func then error("Error de sintaxis en Window.lua") end
    return func()
end)

if loadSuccess and loadResult then
    windowModule = loadResult
    print("[XLORENs] Window.lua cargado correctamente")
else
    print("[XLORENs] Error cargando Window.lua: " .. tostring(loadResult))
    -- Fallback: usar UI embebida
    windowModule = {
        CreateWindow = function(config)
            -- UI embebida de emergencia (la que funcionó antes)
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "XLORENs"
            screenGui.ResetOnSpawn = false
            screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            local main = Instance.new("Frame")
            main.Size = UDim2.new(0, 350, 0, 200)
            main.Position = UDim2.new(0.5, -175, 0.5, -100)
            main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
            main.BorderSizePixel = 0
            main.Visible = true
            main.Parent = screenGui
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0, 40)
            title.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
            title.Text = "XLORENs (Fallback)"
            title.TextColor3 = Color3.fromRGB(255, 255, 255)
            title.Font = Enum.Font.GothamBlack
            title.TextSize = 20
            title.Parent = main
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 0, 80)
            label.Position = UDim2.new(0, 10, 0, 50)
            label.BackgroundTransparency = 1
            label.Text = "Window.lua no se cargó.\nUsando UI de emergencia."
            label.TextColor3 = Color3.fromRGB(255, 200, 100)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 14
            label.TextWrapped = true
            label.Parent = main
            local function toggle()
                main.Visible = not main.Visible
            end
            UIS.InputBegan:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.K then
                    toggle()
                end
            end)
            return { Toggle = toggle }
        end
    }
end

-- === Crear ventana ===
local window = windowModule:CreateWindow({
    Name = "XLORENs Pro",
    Keybind = "K"
})

print("[XLORENs] Ventana creada. Presiona K para abrir/cerrar.")
