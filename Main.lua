--[=[
    XLORENs - Main
    Punto de entrada con UI completa (ESP, Aimbot, Trigger, About).
    VERSIÓN MODULAR: Carga Loader.lua y este carga el resto.
    INTERFAZ VISIBLE AL INICIO (presiona K para cerrar/abrir)
]=]

-- Cargar Core (Loader.lua)
local XLORENs = loadstring(game:HttpGet("https://raw.githubusercontent.com/player2dwhite/XLORENs/main/Core/Loader.lua"))()
XLORENs:Init()

-- Cargar módulos adicionales (si no se cargaron automáticamente)
local Chams = loadstring(game:HttpGet("https://raw.githubusercontent.com/player2dwhite/XLORENs/main/ESP/Chams.lua"))()
if Chams then
    XLORENs.Chams = Chams:Init(XLORENs)
end

-- Crear UI
local UI = XLORENs.UI
local window = UI:CreateWindow({
    Name = "XLORENs",
    Keybind = "K"
})

-- ===== MOSTRAR INTERFAZ AL INICIO =====
-- window:Toggle()  -- Esto alternaría el estado (lo dejaría como estaba)
-- En su lugar, forzamos que sea visible:
window.Visible = true
-- Necesitamos acceder al Frame principal para hacerlo visible.
-- En UI/Window.lua, el frame principal se llama "main" (variable local).
-- Para hacerlo limpio, vamos a buscar el ScreenGui y hacer visible su contenido.

-- Buscamos el ScreenGui creado por UI:CreateWindow
local screenGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("XLORENs")
if screenGui then
    -- Buscamos el Frame principal dentro del ScreenGui
    for _, child in ipairs(screenGui:GetChildren()) do
        if child:IsA("Frame") and child.Name == "MainFrame" then
            child.Visible = true
            break
        end
    end
end

-- ===== Variables globales para configuración =====
local config = {
    -- Aimbot
    aimMode = "Siempre",
    aimBind = "X",
    aimPart = "Head",
    aimFOV = 30,
    aimSmooth = 65,
    aimVisibleOnly = true,
    aimLockTime = 0.35,
    noRecoil = false,

    -- Círculo FOV
    circleColor = Color3.fromRGB(255, 0, 0),
    circleThickness = 2,
    circleTransparency = 0.7,

    -- Trigger
    trigMode = "Nunca",
    trigBind = "F",

    -- ESP
    espEnabled = false,
    espColor = Color3.fromRGB(0, 255, 0),
    espTransparency = 0.7,

    -- WallChecker
    minVis = 0.15,
    maxDist = 500,
    teamCheck = true,
    ignoreSameTeam = true,
    debug = false,
}

-- ===== FUNCIÓN NO RECOIL =====
local noRecoilRunning = false
local noRecoilConnection = nil

local function startNoRecoil()
    if noRecoilRunning then return end
    noRecoilRunning = true

    noRecoilConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not noRecoilRunning then
            noRecoilConnection:Disconnect()
            noRecoilConnection = nil
            return
        end
        local player = game:GetService("Players").LocalPlayer
        local recoil = player:FindFirstChild("Recoil")
        if recoil then
            pcall(function()
                recoil:Destroy()
            end)
        end
    end)
end

local function stopNoRecoil()
    noRecoilRunning = false
    if noRecoilConnection then
        noRecoilConnection:Disconnect()
        noRecoilConnection = nil
    end
end

-- Reiniciar No Recoil al respawnear
game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
    if noRecoilRunning then
        stopNoRecoil()
        startNoRecoil()
    end
end)

-- ===== Pestaña Aimbot =====
local aimTab = window:AddTab("Aimbot")

local aimToggle = aimTab:AddToggle("Aimbot", function(state)
    if state then
        XLORENs.Aimbot:Enable()
    else
        XLORENs.Aimbot:Disable()
    end
end)

-- Modo selector
local aimModeSelector = aimTab:AddModeSelector("Modo", {"Siempre", "Por bind", "Nunca"}, config.aimMode, function(mode, bind)
    config.aimMode = mode
    config.aimBind = bind
    XLORENs.Aimbot.Settings.Mode = mode
    XLORENs.Aimbot.Settings.BindKey = bind
end)

aimTab:AddSeparator()

-- Parte del cuerpo (dropdown)
local partDropdown = aimTab:AddDropdown("Parte", {"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"}, config.aimPart, function(v)
    config.aimPart = v
    XLORENs.Aimbot.Settings.Part = v
end)

-- FOV slider
aimTab:AddSlider("FOV (pixels)", 10, 50, config.aimFOV, function(v)
    config.aimFOV = v
    XLORENs.Aimbot.Settings.FOV = v
    XLORENs.Aimbot:CreateFOVCircle()
end)

-- Smooth slider
aimTab:AddSlider("Smooth", 0, 100, config.aimSmooth, function(v)
    config.aimSmooth = v
    XLORENs.Aimbot.Settings.SmoothAmount = v
end)

-- Lock time slider
aimTab:AddSlider("Lock Time", 0, 1, config.aimLockTime, function(v)
    config.aimLockTime = v
    XLORENs.TargetManager.Settings.LockTime = v
end)

-- Toggles
aimTab:AddToggle("Smooth", function(v)
    XLORENs.Aimbot.Settings.Smooth = v
end)

aimTab:AddToggle("Solo visibles", function(v)
    config.aimVisibleOnly = v
    XLORENs.Aimbot.Settings.VisibleOnly = v
end)

aimTab:AddToggle("Mostrar FOV", function(v)
    XLORENs.Aimbot.Settings.ShowFOV = v
    if v then
        XLORENs.Aimbot:CreateFOVCircle()
    else
        if XLORENs.Aimbot._fovCircle then
            pcall(function() XLORENs.Aimbot._fovCircle:Remove() end)
            XLORENs.Aimbot._fovCircle = nil
        end
    end
end)

-- No Recoil
aimTab:AddSeparator()
aimTab:AddLabel("=== Arma ===")
local noRecoilToggle = aimTab:AddToggle("No Recoil", function(state)
    config.noRecoil = state
    if state then startNoRecoil() else stopNoRecoil() end
end)

-- Controles del círculo FOV
aimTab:AddSeparator()
aimTab:AddLabel("=== Círculo FOV ===")

local circleR = aimTab:AddSlider("R", 0, 255, 255, function(v)
    config.circleColor = Color3.fromRGB(v, circleG.Get(), circleB.Get())
    if XLORENs.Aimbot._fovCircle then
        XLORENs.Aimbot._fovCircle.Color = config.circleColor
    end
end)

local circleG = aimTab:AddSlider("G", 0, 255, 0, function(v)
    config.circleColor = Color3.fromRGB(circleR.Get(), v, circleB.Get())
    if XLORENs.Aimbot._fovCircle then
        XLORENs.Aimbot._fovCircle.Color = config.circleColor
    end
end)

local circleB = aimTab:AddSlider("B", 0, 255, 0, function(v)
    config.circleColor = Color3.fromRGB(circleR.Get(), circleG.Get(), v)
    if XLORENs.Aimbot._fovCircle then
        XLORENs.Aimbot._fovCircle.Color = config.circleColor
    end
end)

aimTab:AddSlider("Grosor", 1, 10, config.circleThickness, function(v)
    config.circleThickness = v
    if XLORENs.Aimbot._fovCircle then
        XLORENs.Aimbot._fovCircle.Thickness = v
    end
end)

aimTab:AddSlider("Transparencia", 0, 100, 70, function(v)
    config.circleTransparency = v / 100
    if XLORENs.Aimbot._fovCircle then
        XLORENs.Aimbot._fovCircle.Transparency = config.circleTransparency
    end
end)

-- ===== Pestaña Trigger =====
local trigTab = window:AddTab("Trigger")

local trigToggle = trigTab:AddToggle("Trigger Bot", function(state)
    config.trigEnabled = state
end)

local trigModeSelector = trigTab:AddModeSelector("Modo", {"Siempre", "Por bind", "Nunca"}, config.trigMode, function(mode, bind)
    config.trigMode = mode
    config.trigBind = bind
end)

trigTab:AddLabel("Al apuntar a un enemigo, dispara automáticamente.")

-- ===== Pestaña ESP =====
local espTab = window:AddTab("ESP")

local espToggle = espTab:AddToggle("ESP (Chams)", function(state)
    config.espEnabled = state
    if XLORENs.Chams then
        if state then XLORENs.Chams:Enable() else XLORENs.Chams:Disable() end
    end
end)

-- Color picker
espTab:AddLabel("Color (R,G,B)")
local espColorR = espTab:AddSlider("Rojo", 0, 255, 0, function(v)
    config.espColor = Color3.fromRGB(v, espColorG.Get(), espColorB.Get())
    if XLORENs.Chams then
        XLORENs.Chams.Settings.Color = config.espColor
        XLORENs.Chams:UpdateAll()
    end
end)
local espColorG = espTab:AddSlider("Verde", 0, 255, 255, function(v)
    config.espColor = Color3.fromRGB(espColorR.Get(), v, espColorB.Get())
    if XLORENs.Chams then
        XLORENs.Chams.Settings.Color = config.espColor
        XLORENs.Chams:UpdateAll()
    end
end)
local espColorB = espTab:AddSlider("Azul", 0, 255, 0, function(v)
    config.espColor = Color3.fromRGB(espColorR.Get(), espColorG.Get(), v)
    if XLORENs.Chams then
        XLORENs.Chams.Settings.Color = config.espColor
        XLORENs.Chams:UpdateAll()
    end
end)

espTab:AddSlider("Transparencia", 0, 100, 70, function(v)
    config.espTransparency = v / 100
    if XLORENs.Chams then
        XLORENs.Chams.Settings.Transparency = config.espTransparency
        XLORENs.Chams:UpdateAll()
    end
end)

-- ===== Pestaña WallChecker =====
local wallTab = window:AddTab("WallCheck")

wallTab:AddSlider("Min Visibility", 0, 1, config.minVis, function(v)
    config.minVis = v
    XLORENs.WallChecker.Settings.MinimumVisibility = v
end)

wallTab:AddSlider("Max Distance", 100, 1000, config.maxDist, function(v)
    config.maxDist = v
    XLORENs.WallChecker.Settings.MaxDistance = v
end)

wallTab:AddToggle("Team Check", function(v)
    config.teamCheck = v
    XLORENs.WallChecker.Settings.TeamCheckMode = v and "Auto" or "Disabled"
end)

wallTab:AddToggle("Ignore Same Team", function(v)
    config.ignoreSameTeam = v
    XLORENs.WallChecker.Settings.IgnoreSameTeam = v
end)

wallTab:AddToggle("Debug", function(v)
    config.debug = v
    XLORENs.WallChecker.Settings.Debug = v
end)

-- ===== Pestaña About =====
local aboutTab = window:AddTab("About")
aboutTab:AddLabel("XLORENs Framework")
aboutTab:AddLabel("v3.0 - Player Visibility Engine")
aboutTab:AddLabel("")
aboutTab:AddLabel("Módulos:")
aboutTab:AddLabel("• WallChecker (visibilidad)")
aboutTab:AddLabel("• Aimbot + TargetManager")
aboutTab:AddLabel("• Chams (ESP)")
aboutTab:AddLabel("• Trigger Bot")
aboutTab:AddLabel("• No Recoil")
aboutTab:AddLabel("")
aboutTab:AddLabel("Teclas:")
aboutTab:AddLabel("• " .. window.Keybind .. " - Abrir/cerrar menú")
aboutTab:AddLabel("• F - Trigger rápido (si está en modo bind)")

-- ===== BUCLE PRINCIPAL =====
game:GetService("RunService").RenderStepped:Connect(function()
    if XLORENs.Aimbot and XLORENs.Aimbot.Settings.Enabled then
        local origin = game:GetService("Players").LocalPlayer.Character
        if origin then
            local head = origin:FindFirstChild("Head") or origin:FindFirstChild("HumanoidRootPart")
            if head then
                XLORENs.TargetManager:GetTarget(head.Position)
                XLORENs.Aimbot:Update()
            end
        end
    end
end)

-- ===== TRIGGER BOT =====
local function shouldTrigger()
    if not config.trigEnabled then return false end
    if config.trigMode == "Nunca" then return false end
    if config.trigMode == "Siempre" then return true end
    if config.trigMode == "Por bind" then
        local key = Enum.KeyCode[config.trigBind]
        return game:GetService("UserInputService"):IsKeyDown(key)
    end
    return false
end

game:GetService("RunService").RenderStepped:Connect(function()
    if shouldTrigger() then
        local mouse = game:GetService("Players").LocalPlayer:GetMouse()
        local target = mouse.Target
        if target and target.Parent then
            local hum = target.Parent:FindFirstChildOfClass("Humanoid")
            local char = target.Parent
            if not hum and char.Parent then
                hum = char.Parent:FindFirstChildOfClass("Humanoid")
                if hum then char = char.Parent end
            end
            if hum and hum.Health > 0 and char ~= game:GetService("Players").LocalPlayer.Character then
                if XLORENs.WallChecker and XLORENs.WallChecker:IsEnemy(game:GetService("Players"):GetPlayerFromCharacter(char)) then
                    mouse1press()
                    task.wait(0.05)
                    mouse1release()
                end
            end
        end
    end
end)

-- ===== CONECTAR DISPARO =====
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if XLORENs.Aimbot then XLORENs.Aimbot:Shoot() end
    end
end)

-- ===== INICIALIZAR ESP =====
if XLORENs.Chams then
    XLORENs.Chams:Disable()
end

-- ===== NOTIFICACIÓN =====
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "XLORENs",
    Text = "Cargado! Presiona " .. window.Keybind .. " para cerrar/abrir el menú",
    Duration = 4
})

print("[XLORENs] Ready! Press " .. window.Keybind .. " to toggle menu.")
