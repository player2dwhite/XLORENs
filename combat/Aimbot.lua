--[=[
    XLORENs - Aimbot
    Solo controla la cámara. Recibe el objetivo del TargetManager.
]=]

local Aimbot = {}
Aimbot.__index = Aimbot

function Aimbot:Init(framework)
    self._framework = framework
    self.TargetManager = framework.TargetManager
    self.Settings = {
        Enabled = false,
        Key = "T",
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
    return self
end

function Aimbot:Update()
    if not self.Settings.Enabled then return end

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
end

function Aimbot:Disable()
    self.Settings.Enabled = false
    self._active = false
    self._lastAimPos = nil
    self._recoilOffset = Vector2.new(0, 0)
end

function Aimbot:Toggle()
    if self.Settings.Enabled then
        self:Disable()
    else
        self:Enable()
    end
    return self.Settings.Enabled
end

return Aimbot
