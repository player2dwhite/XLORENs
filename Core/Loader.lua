--[=[
    XLORENs Core - Loader (mejorado con manejo de errores)
]=]

local XLORENs = {
    Modules = {},
    Services = {},
    Config = {},
    Signals = {},
}

-- Cargar módulos internos (rutas relativas)
local function LoadModule(name, path)
    local url = "https://raw.githubusercontent.com/player2dwhite/XLORENs/main/" .. path
    print("[Loader] Cargando " .. name .. " desde " .. url)
    
    local success, result = pcall(function()
        local raw = game:HttpGet(url)
        if not raw or raw == "" then
            error("El archivo está vacío o no se pudo descargar.")
        end
        local func, err = loadstring(raw)
        if not func then
            error("Error en loadstring: " .. tostring(err))
        end
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
    -- Cargar UI (con manejo especial de errores)
    local uiSuccess, uiResult = pcall(function()
        return LoadModule("UI", "UI/Window.lua")
    end)
    
    if uiSuccess and uiResult then
        self.UI = uiResult
        print("[Loader] UI cargada correctamente.")
    else
        warn("[Loader] Error crítico en UI: " .. tostring(uiResult))
        -- Crear UI de emergencia embebida si falla
        self.UI = nil
        print("[Loader] Usar UI embebida en Main.lua")
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
