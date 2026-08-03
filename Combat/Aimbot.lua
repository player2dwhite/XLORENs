--[=[
    XLORENs - Aimbot
    Controlador de cámara con modos (Siempre, Por bind, Nunca) y FOV circle.
]=]

local Aimbot = {}
Aimbot.__index = Aimbot

function Aimbot:Init(framework)
    self._framework = framework
    self.TargetManager = framework.TargetManager
    self.Settings = {
        Enabled = false,
        Mode = "Siempre",        -- "Siempre", "Por bind", "Nunca"
        BindKey = "X",
        Part = "Head",
        FOV = 200,               -- en píxeles
        ShowFOV = true,
        VisibleOnly = true,
        Smooth = true,
        SmoothAmount = 65,
        TrackingInertia = 0.20,
        RecoilEnabled = true,
        RecoilIntensity = 0.3,
        RecoilDecay = 0.9,
        RecoilResetDelay = 0.5,
    }
    self._lastAimPos = nil
    self._recoilOffset = Vector2.new(0, 0)
    self._lastShotTime = 0
    self._active = false
    self._fovCircle = nil
    self._fovConnection = nil
    return self
end

function Aimbot:ShouldAim()
    if not self.Settings.Enabled then return false end
    if self.Settings.Mode == "Nunca" then return false end
    if self.Settings.Mode == "Siempre" then return true end
    if self.Settings.Mode == "Por bind" then
        local key = Enum.KeyCode[self.Settings.BindKey]
        return game:GetService("UserInputService"):IsKeyDown(key)
    end
    return false
end

function Aimbot:CreateFOVCircle()
    if self._fovCircle then
        pcall(function() self._fovCircle:Remove() end)
        self._fovCircle = nil
    end
    if not self.Settings.ShowFOV then return end

    self._fovCircle = Drawing.new("Circle")
    self._fovCircle.Visible = true
    self._fovCircle.Thickness = 1.5
    self._fovCircle.Transparency = 0.7
    self._fovCircle.ZIndex = 10
    self._fovCircle.Filled = false
    self._fovCircle.NumSides = 64
    self._fovCircle.Color = Color3.fromRGB(255, 0, 0)

    if self._fovConnection then self._fovConnection:Disconnect() end
    self._fovConnection = game:GetService("RunService").RenderStepped:Connect(function()
        if not self._fovCircle or not self.Settings.ShowFOV or not self.Settings.Enabled then
            if self._fovCircle then self._fovCircle.Visible = false end
            return
        end
        local mouse = game:GetService("UserInputService"):GetMouseLocation()
        self._fovCircle.Position = Vector2.new(mouse.X, mouse.Y)
        self._fovCircle.Radius = self.Settings.FOV
        self._fovCircle.Visible = true
    end)
end

function Aimbot:Update()
    if not self.Settings.Enabled then
        if self._fovCircle then self._fovCircle.Visible = false end
        return
    end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local target = self.TargetManager:GetCurrentTarget()
    if not target then
        self._lastAimPos = nil
        return
    end

    local aimPart = target:GetAimPart()
    if not aimPart then return end

    local targetPos = target:GetPredictionPosition()

    self:_UpdateRecoil()
    local recoil = self._recoilOffset

    local screenPos, onScreen = cam:WorldToScreenPoint(targetPos)
    if not onScreen then return end

    -- FOV check
    if self.Settings.FOV > 0 then
        local mouse = game:GetService("UserInputService"):GetMouseLocation()
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
        if dist > self.Settings.FOV then
            self._lastAimPos = nil
            return
        end
    end

    local aimScreen = Vector2.new(screenPos.X + recoil.X, screenPos.Y + recoil.Y)

    if self._lastAimPos then
        local inertia = self.Settings.TrackingInertia
        if self.Settings.Smooth then
            local smoothFactor = 1 - (self.Settings.SmoothAmount / 100)
            inertia = inertia + (1 - inertia) * smoothFactor
        end
        aimScreen = self._lastAimPos:Lerp(aimScreen, 1 - inertia)
    end
    self._lastAimPos = aimScreen

    local aimPos = cam:ScreenToWorldPoint(Vector3.new(aimScreen.X, aimScreen.Y, 1000))
    local camPos = cam.CFrame.Position
    local lookVector = (aimPos - camPos).Unit

    if self.Settings.Smooth then
        local smoothFactor = 1 - (self.Settings.SmoothAmount / 100)
        local currentLook = cam.CFrame.LookVector
        local smoothed = currentLook:Lerp(lookVector, smoothFactor)
        cam.CFrame = CFrame.new(camPos, camPos + smoothed)
    else
        cam.CFrame = CFrame.new(camPos, aimPos)
    end
end

function Aimbot:Shoot()
    if not self.Settings.RecoilEnabled then return end
    local intensity = self.Settings.RecoilIntensity * 2
    self._recoilOffset = self._recoilOffset + Vector2.new(
        (math.random() - 0.5) * intensity * 0.3,
        -math.random() * intensity * 0.8
    )
    self._recoilOffset = Vector2.new(
        math.clamp(self._recoilOffset.X, -intensity, intensity),
        math.clamp(self._recoilOffset.Y, -intensity, intensity)
    )
    self._lastShotTime = tick()
end

function Aimbot:_UpdateRecoil()
    if not self.Settings.RecoilEnabled then
        self._recoilOffset = Vector2.new(0, 0)
        return
    end
    local time = tick()
    if time - self._lastShotTime > self.Settings.RecoilResetDelay then
        self._recoilOffset = Vector2.new(0, 0)
    else
        self._recoilOffset = self._recoilOffset * self.Settings.RecoilDecay
        if self._recoilOffset.Magnitude < 0.001 then
            self._recoilOffset = Vector2.new(0, 0)
        end
    end
end

function Aimbot:Enable()
    self.Settings.Enabled = true
    self._active = true
    self:CreateFOVCircle()
end

function Aimbot:Disable()
    self.Settings.Enabled = false
    self._active = false
    self._lastAimPos = nil
    self._recoilOffset = Vector2.new(0, 0)
    if self._fovCircle then
        pcall(function() self._fovCircle:Remove() end)
        self._fovCircle = nil
    end
    if self._fovConnection then
        self._fovConnection:Disconnect()
        self._fovConnection = nil
    end
end

return Aimbot
