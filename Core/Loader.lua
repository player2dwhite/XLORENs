--[=[
    XLORENs - Loader
]=]

local XLORENs = {
    Modules = {},
}

local function LoadModule(name, path)
    local url = "https://raw.githubusercontent.com/player2dwhite/XLORENs/main/" .. path
    print("[Loader] Cargando " .. name)

    local ok, mod = pcall(function()
        local raw = game:HttpGet(url)
        if not raw then error("Descarga fallida") end
        local fn = loadstring(raw)
        if not fn then error("Sintaxis error") end
        return fn()
    end)

    if ok and mod then
        XLORENs.Modules[name] = mod
        print("[Loader] ✅ " .. name)
        return mod
    else
        warn("[Loader] ❌ " .. name .. ": " .. tostring(mod))
        return nil
    end
end

function XLORENs:Initialize()
    -- Cargar UI (interfaz completa)
    local UI = LoadModule("UI", "UI/Window.lua")
    if UI and UI.CreateWindow then
        self.Window = UI:CreateWindow({
            Name = "XLORENs Pro",
            Keybind = "K"
        })
        self.Window:Open()
        print("[Loader] Ventana creada.")
    else
        warn("[Loader] UI no disponible.")
    end

    -- Cargar resto de módulos
    self.ConsoleBypass = LoadModule("ConsoleBypass", "Core/ConsoleBypass.lua")
    self.WallChecker = LoadModule("WallChecker", "Vision/WallChecker.lua")
    self.TargetManager = LoadModule("TargetManager", "Combat/TargetManager.lua")
    self.Aimbot = LoadModule("Aimbot", "Combat/Aimbot.lua")
    self.Movement = LoadModule("Movement", "Combat/Movement.lua")
    self.Chams = LoadModule("Charms", "ESP/Charms.lua")  -- Archivo se llama Charms

    -- Inicializar módulos que lo necesiten
    if self.WallChecker and self.WallChecker.Initialize then
        self.WallChecker:Initialize(self)
    end
    if self.TargetManager and self.TargetManager.Initialize then
        self.TargetManager:Initialize(self)
    end
    if self.Aimbot and self.Aimbot.Initialize then
        self.Aimbot:Initialize(self)
    end
    if self.Movement and self.Movement.Initialize then
        self.Movement:Initialize(self)
    end
    if self.Chams and self.Chams.Initialize then
        self.Chams:Initialize(self)
    end

    print("[Loader] Inicialización completada.")
    return self
end

getgenv().XLORENs = XLORENs
return XLORENs
