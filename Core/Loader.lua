--[=[
    XLORENs - Loader (con logs para depuración)
    Gestor de módulos con carga segura y logs detallados.
]=]

local XLORENs = {
    Modules = {},
    Services = {},
    Config = {},
}

local function SafeLoadModule(moduleName, filePath)
    local url = "https://raw.githubusercontent.com/player2dwhite/XLORENs/main/" .. filePath
    print("[Loader] ⏳ Cargando " .. moduleName .. " desde " .. url)

    local success, result = pcall(function()
        print("[Loader] 📥 Descargando " .. moduleName .. "...")
        local rawCode = game:HttpGet(url)
        if not rawCode or rawCode == "" then
            error("El archivo está vacío o no se pudo descargar.")
        end
        print("[Loader] 📄 Archivo " .. moduleName .. " descargado (" .. string.len(rawCode) .. " bytes)")

        print("[Loader] 🔧 Compilando " .. moduleName .. "...")
        local compiledFunction, compileError = loadstring(rawCode)
        if not compiledFunction then
            error("Error de sintaxis en " .. moduleName .. ": " .. tostring(compileError))
        end
        print("[Loader] ✅ Compilación de " .. moduleName .. " exitosa")

        print("[Loader] 🚀 Ejecutando " .. moduleName .. "...")
        local moduleTable = compiledFunction()
        if moduleTable == nil then
            error("El módulo " .. moduleName .. " devolvió nil")
        end
        return moduleTable
    end)

    if success and result then
        XLORENs.Modules[moduleName] = result
        print("[Loader] ✅ " .. moduleName .. " cargado correctamente.")
        return result
    else
        warn("[Loader] ❌ Error cargando " .. moduleName .. ": " .. tostring(result))
        return nil
    end
end

function XLORENs:Initialize()
    print("[Loader] 🚀 Inicializando XLORENs...")

    -- No cargamos UI desde GitHub (se usa la embebida en Main.lua)
    self.UI = nil
    print("[Loader] ℹ️ UI: usando embebida en Main.lua")

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

    -- ESP (Charms.lua) - NOTA: archivo se llama Charms, pero el módulo interno se llama Chams
    self.Chams = SafeLoadModule("Chams", "ESP/Charms.lua") or {}
    if self.Chams and self.Chams.Initialize then
        self.Chams:Initialize(self)
    end

    print("[Loader] ✅ Todos los módulos procesados.")
    print("[Loader] 📊 Resumen de carga:")
    for name, mod in pairs(XLORENs) do
        if type(mod) == "table" and name ~= "Modules" and name ~= "Services" and name ~= "Config" then
            print("   • " .. name .. ": " .. (mod ~= nil and "✅" or "❌"))
        end
    end

    return self
end

getgenv().XLORENs = XLORENs
return XLORENs
