--[=[
    XLORENs Core - Loader
    Gestor de dependencias y carga de módulos.
]=]

local XLORENs = {
    Modules = {},
    Services = {},
    Config = {},
    Signals = {},
}

-- Cargar módulos internos
local function LoadModule(name, path)
    local success, module = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/player2dwhite/XLORENs/main/" .. path))()
    end)
    if success and module then
        XLORENs.Modules[name] = module
        return module
    else
        warn("[XLORENs] Error loading " .. name .. ": " .. tostring(module))
        return nil
    end
end

-- Inicializar servicios
function XLORENs:Init()
    -- Cargar Core
    self.Config = LoadModule("Config", "Core/Config.lua") or {}
    self.Signals = LoadModule("Signals", "Core/Signal.lua") or {}

    -- Cargar UI
    self.UI = LoadModule("UI", "UI/Window.lua") or {}
    self.UI.Elements = LoadModule("UIElements", "UI/Elements.lua") or {}
    self.UI.Theme = LoadModule("UITheme", "UI/Theme.lua") or {}

    -- Cargar Vision
    self.WallChecker = LoadModule("WallChecker", "Vision/WallChecker.lua") or {}
    self.ESP = LoadModule("ESP", "Vision/ESP.lua") or {}

    -- Cargar Combat
    self.TargetManager = LoadModule("TargetManager", "Combat/TargetManager.lua") or {}
    self.Aimbot = LoadModule("Aimbot", "Combat/Aimbot.lua") or {}
    self.Prediction = LoadModule("Prediction", "Combat/Prediction.lua") or {}

    -- Pasar dependencias
    if self.WallChecker then
        self.WallChecker:Init(self)
    end
    if self.TargetManager then
        self.TargetManager:Init(self)
    end
    if self.Aimbot then
        self.Aimbot:Init(self)
    end

    print("[XLORENs] Loaded successfully!")
    return self
end

-- Exponer globalmente
getgenv().XLORENs = XLORENs

return XLORENs
