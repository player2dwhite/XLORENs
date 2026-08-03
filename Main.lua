--[=[
    XLORENs - Main
    Punto de entrada del framework.
]=]

-- Cargar Core
local XLORENs = loadstring(game:HttpGet("https://raw.githubusercontent.com/player2dwhite/XLORENs/main/Core/Loader.lua"))()
XLORENs:Init()

-- Crear UI
local UI = XLORENs.UI
local window = UI:CreateWindow({
    Name = "XLORENs",
    Keybind = "K"
})

-- === Pestaña Aimbot ===
local aimbotTab = window:AddTab("Aimbot")

local aimbotToggle = aimbotTab:AddToggle("Aimbot", function(state)
    if state then
        XLORENs.Aimbot:Enable()
    else
        XLORENs.Aimbot:Disable()
    end
end)

aimbotTab:AddKeybind("Toggle Key", "T", function(key)
    XLORENs.Aimbot.Settings.Key = key
    window.Keybind = key
end)

aimbotTab:AddSlider("FOV", 10, 500, XLORENs.TargetManager.Settings.FOV, function(v)
    XLORENs.TargetManager.Settings.FOV = v
end)

aimbotTab:AddSlider("Smooth Amount", 0, 100, XLORENs.Aimbot.Settings.SmoothAmount, function(v)
    XLORENs.Aimbot.Settings.SmoothAmount = v
end)

aimbotTab:AddSlider("Lock Time", 0, 1, XLORENs.TargetManager.Settings.LockTime, function(v)
    XLORENs.TargetManager.Settings.LockTime = v
end)

-- === Pestaña WallChecker ===
local wallTab = window:AddTab("WallChecker")

wallTab:AddSlider("Min Visibility", 0, 1, XLORENs.WallChecker.Settings.MinimumVisibility, function(v)
    XLORENs.WallChecker.Settings.MinimumVisibility = v
end)

wallTab:AddSlider("Max Distance", 100, 1000, XLORENs.WallChecker.Settings.MaxDistance, function(v)
    XLORENs.WallChecker.Settings.MaxDistance = v
end)

wallTab:AddToggle("Team Check", function(v)
    XLORENs.WallChecker.Settings.TeamCheckMode = v and "Auto" or "Disabled"
end)

wallTab:AddToggle("Ignore Same Team", function(v)
    XLORENs.WallChecker.Settings.IgnoreSameTeam = v
end)

wallTab:AddToggle("Debug", function(v)
    XLORENs.WallChecker.Settings.Debug = v
end)

-- === BUCLE PRINCIPAL ===
game:GetService("RunService").RenderStepped:Connect(function()
    if XLORENs.Aimbot.Settings.Enabled then
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

-- Conectar disparo
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        XLORENs.Aimbot:Shoot()
    end
end)

print("[XLORENs] Ready! Press K to open menu.")
