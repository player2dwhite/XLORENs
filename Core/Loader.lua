--[=[
    XLORENs Core - Loader (mejorado con manejo de errores)
]=]

local XLORENs = {
    Modules = {},
    Services = {},
    Config = {},
    Signals = {},
}

-- Cargar módulos internos con manejo de errores mejorado
local function LoadModule(name, path)
    local url = "https://raw.githubusercontent.com/player2dwhite/XLORENs/main/" .. path
    print("[Loader] Cargando " .. name .. " desde " .. url)
    
    local success, result = pcall(function()
        local raw = game:HttpGet(url)
        if not raw or raw == "" then
            error("El archivo está vacío o no se pudo descargar.")
        end
        
        -- Intentar compilar el código
        local func, err = loadstring(raw)
        if not func then
            error("Error de sintaxis en " .. name .. ": " .. tostring(err))
        end
        
        -- Ejecutar el código compilado
        return func()
    end)

    if success and result then
        XLORENs.Modules[name] = result
        print("[Loader] " .. name .. " cargado correctamente.")
        return result
    else
        warn("[Loader] Error cargando " .. name .. ": " .. tostring(result))
        return nil
    end
end

-- Inicializar servicios
function XLORENs:Init()
    -- Cargar UI (con manejo de errores específico)
    self.UI = LoadModule("UI", "UI/Window.lua")
    
    -- Si la UI falló, crear una UI de emergencia directamente
    if not self.UI or not self.UI.CreateWindow then
        print("[Loader] UI no cargada correctamente. Creando UI de emergencia...")
        self.UI = {
            CreateWindow = function(config)
                config = config or {}
                local window = {
                    Name = config.Name or "XLORENs",
                    Keybind = config.Keybind or "K",
                    Tabs = {},
                    Visible = true,
                }
                
                local player = game:GetService("Players").LocalPlayer
                local screenGui = Instance.new("ScreenGui")
                screenGui.Name = "XLORENs_UI_Emergency"
                screenGui.ResetOnSpawn = false
                screenGui.DisplayOrder = 999
                screenGui.Parent = player:WaitForChild("PlayerGui")
                
                local main = Instance.new("Frame")
                main.Size = UDim2.new(0, 400, 0, 300)
                main.Position = UDim2.new(0.5, -200, 0.5, -150)
                main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
                main.BorderSizePixel = 0
                main.ClipsDescendants = true
                main.Visible = true
                main.Parent = screenGui
                Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
                
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, 0, 0, 40)
                title.Position = UDim2.new(0, 0, 0, 0)
                title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                title.Text = window.Name .. " (Emergencia)"
                title.Font = Enum.Font.GothamBlack
                title.TextSize = 16
                title.TextColor3 = Color3.fromRGB(255, 200, 100)
                title.Parent = main
                Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)
                
                local content = Instance.new("Frame")
                content.Size = UDim2.new(1, -20, 1, -50)
                content.Position = UDim2.new(0, 10, 0, 45)
                content.BackgroundTransparency = 1
                content.Parent = main
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 0, 100)
                label.Position = UDim2.new(0, 0, 0, 20)
                label.BackgroundTransparency = 1
                label.Text = "UI de emergencia cargada.\nEl archivo UI/Window.lua tiene errores.\nPresiona K para cerrar/abrir."
                label.TextColor3 = Color3.fromRGB(200, 200, 200)
                label.Font = Enum.Font.GothamBold
                label.TextSize = 14
                label.TextWrapped = true
                label.Parent = content
                
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
        }
        print("[Loader] UI de emergencia creada correctamente.")
    end

    -- Cargar Vision
    self.WallChecker = LoadModule("WallChecker", "Vision/WallChecker.lua") or {}
    if self.WallChecker and self.WallChecker.Init then
        self.WallChecker:Init(self)
    end

    -- Cargar Combat
    self.TargetManager = LoadModule("TargetManager", "Combat/TargetManager.lua") or {}
    if self.TargetManager and self.TargetManager.Init then
        self.TargetManager:Init(self)
    end

    self.Aimbot = LoadModule("Aimbot", "Combat/Aimbot.lua") or {}
    if self.Aimbot and self.Aimbot.Init then
        self.Aimbot:Init(self)
    end

    print("[XLORENs] Loaded successfully!")
    return self
end

-- Exponer globalmente
getgenv().XLORENs = XLORENs

return XLORENs
