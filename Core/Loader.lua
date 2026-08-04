--[=[
    XLORENs - Loader
    Gestor de módulos con carga segura y manejo de errores.
]=]

local XLORENs = {
    Modules = {},
    Services = {},
    Config = {},
}

local function SafeLoadModule(moduleName, filePath)
    local url = "https://raw.githubusercontent.com/player2dwhite/XLORENs/main/" .. filePath
    print("[Loader] Cargando " .. moduleName .. " desde " .. url)

    local success, result = pcall(function()
        local rawCode = game:HttpGet(url)
        if not rawCode or rawCode == "" then
            error("El archivo está vacío o no se pudo descargar.")
        end
        local compiledFunction, compileError = loadstring(rawCode)
        if not compiledFunction then
            error("Error de sintaxis en " .. moduleName .. ": " .. tostring(compileError))
        end
        return compiledFunction()
    end)

    if success and result then
        XLORENs.Modules[moduleName] = result
        print("[Loader] " .. moduleName .. " cargado correctamente.")
        return result
    else
        warn("[Loader] Error cargando " .. moduleName .. ": " .. tostring(result))
        return nil
    end
end

function XLORENs:Initialize()
    -- No cargamos UI desde GitHub (se usa la embebida en Main.lua)
    self.UI = nil

    -- Módulo de silenciado de logs
    self.ConsoleBypass = SafeLoadModule("ConsoleBypass", "Core/ConsoleBypass.lua") or {}
    if self.ConsoleBypass and self.ConsoleBypass.Settings and self.ConsoleBypass.Settings.Enabled then
        self.ConsoleBypass:Enable()
    end

    -- Motor de percepción
    self.WallChecker = SafeLoadModule("WallChecker", "Vision/WallChecker.lua") or {}
    if self.WallChecker and self.WallChecker.Initialize then
        self.WallChecker:Initialize(self)
    end

    -- Gestor de objetivos
    self.TargetManager = SafeLoadModule("TargetManager", "Combat/TargetManager.lua") or {}
    if self.TargetManager and self.TargetManager.Initialize then
        self.TargetManager:Initialize(self)
    end

    -- Aimbot
    self.Aimbot = SafeLoadModule("Aimbot", "Combat/Aimbot.lua") or {}
    if self.Aimbot and self.Aimbot.Initialize then
        self.Aimbot:Initialize(self)
    end

    -- Movimiento
    self.Movement = SafeLoadModule("Movement", "Combat/Movement.lua") or {}
    if self.Movement and self.Movement.Initialize then
        self.Movement:Initialize(self)
    end

    -- ESP
    self.Chams = SafeLoadModule("Charms", "ESP/Chams.lua") or {}
    if self.Chams and self.Chams.Initialize then
        self.Chams:Initialize(self)
    end

    print("[XLORENs] Todos los módulos cargados exitosamente.")
    return self
end

getgenv().XLORENs = XLORENs
return XLORENs
