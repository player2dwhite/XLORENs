--[=[
    XLORENs Core - Loader
]=]

local XLORENs = {
    Modules = {},
    Services = {},
    Config = {},
    Signals = {},
}

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
            error("Error de sintaxis en " .. name .. ": " .. tostring(err))
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

function XLORENs:Init()
    -- NO cargamos UI desde GitHub (usamos la embebida de Main.lua)
    self.UI = nil

    -- Cargar ConsoleBypass
    self.ConsoleBypass = LoadModule("ConsoleBypass", "Core/ConsoleBypass.lua") or {}
    if self.ConsoleBypass and self.ConsoleBypass.Settings then
        if self.ConsoleBypass.Settings.Enabled then
            self.ConsoleBypass:Enable()
        end
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

    -- Cargar ESP
    self.Chams = LoadModule("Chams", "ESP/Chams.lua") or {}
    if self.Chams and self.Chams.Init then
        self.Chams:Init(self)
    end

    print("[XLORENs] Loaded successfully!")
    return self
end

getgenv().XLORENs = XLORENs
return XLORENs
