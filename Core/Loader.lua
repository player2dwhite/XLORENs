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

-- Cargar módulos internos (rutas relativas)
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
