--[=[
    XLORENs - Aimbot v4 (orgánico)
]=]

local Aimbot = {}
Aimbot.__index = Aimbot

Aimbot.Settings = {
    General = {
        Enabled = false,
        Mode = "Siempre",
        BindKey = "X",
        GracePeriod = 0.15,
        ViewAngle = 90,
        MaxTurnSpeed = 360,
    },
    Aim = {
        Priority = { "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso" },
        Smooth = true,
        SmoothAmount = 65,
        SmoothVariation = 2,
        Deadzone = 2,
        Inertia = 0.18,
        ReactionTime = 0.15,
        ErrorScale = 0.05,
        Overshoot = 0.02,
        Prediction = {
            Enabled = true,
            Base = 0.12,
            Variation = 0.02,
            DistanceScale = true,
            PingScale = true,
        },
        History = {
            Size = 5,
            Enabled = true,
        },
        Offset = {
            Enabled = true,
            SwitchTime = 0.7,
            Positions = {
                { Name = "Head", Offset = Vector3.new(0, 0.25, 0), Weight = 40 },
                { Name = "Neck", Offset = Vector3.new(0, -0.1, 0.1), Weight = 30 },
                { Name = "Chest", Offset = Vector3.new(0, -0.6, 0.2), Weight = 20 },
                { Name = "Shoulder", Offset = Vector3.new(0.2, -0.2, 0.1), Weight = 10 },
            },
        },
    },
    FOV = {
        Enabled = true,
        Radius = 200,
        Filled = false,
        Thickness = 2,
        Color = Color3.fromRGB(255, 0, 0),
        TargetColor = Color3.fromRGB(0, 255, 0),
        Pulse = true,
        PulseSpeed = 1.5,
        Transparency = 0.7,
    },
    Recoil = {
        Enabled = true,
        Intensity = 0.3,
        Decay = 0.9,
        ResetDelay = 0.5,
    },
}

function Aimbot:Init(framework)
    self._framework = framework
    self.TargetManager = framework.TargetManager
    self._lastAimPos = nil
    self._targetLostTime = 0
    self._currentTarget = nil
    self._targetAcquireTime = 0
    self._currentOffset = nil
    self._offsetSwitchTime = 0
    self._history = {}
    self._recoilOffset = Vector2.new(0, 0)
    self._lastShotTime = 0
    self._fovCircle = nil
    self._fovConnection = nil
    self._lastCameraCFrame = nil
    self._lastUpdateTime = 0
    self._microPhase = math.random() * 100
    return self
end

function Aimbot:_SelectOffset()
    if not self.Settings.Aim.Offset.Enabled then return Vector3.new(0,0,0) end
    local now = tick()
    if self._currentOffset and now - self._offsetSwitchTime < self.Settings.Aim.Offset.SwitchTime then
        return self._currentOffset
    end
    local positions = self.Settings.Aim.Offset.Positions
    local totalWeight = 0
    for _, p in ipairs(positions) do totalWeight = totalWeight + p.Weight end
    local rand = math.random() * totalWeight
    local cumulative = 0
    local selected = positions[1]
    for _, p in ipairs(positions) do
        cumulative = cumulative + p.Weight
        if rand <= cumulative then selected = p; break end
    end
    local variation = Vector3.new(
        (math.random() - 0.5) * 0.06,
        (math.random() - 0.5) * 0.06,
        (math.random() - 0.5) * 0.04
    )
    self._currentOffset = selected.Offset + variation
    self._offsetSwitchTime = now
    return self._currentOffset
end

function Aimbot:_GetDynamicPriority(enemy)
    local speed = (enemy.Velocity or Vector3.new(0,0,0)).Magnitude
    if speed > 12 then return { "UpperTorso", "HumanoidRootPart", "Head", "LowerTorso" }
    elseif speed > 5 then return { "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso" }
    else return { "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso" }
    end
end

function Aimbot:_GetAimPart(enemy)
    if not enemy or not enemy.Character then return nil end
    local priority = self:_GetDynamicPriority(enemy)
    for _, partName in ipairs(priority) do
        local part = enemy.Character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local visible = false
            if enemy.AimParts then
                if partName == "Head" and enemy.AimParts.Head then visible = true
                elseif partName ~= "Head" and enemy.AimParts.Body then visible = true
                end
            end
            if not enemy.AimParts or visible then return part
        end
    end
    return enemy.VisiblePart
end

function Aimbot:_GetPrediction(enemy, dt)
    if not self.Settings.Aim.Prediction.Enabled then return enemy.Position end
    local base = self.Settings.Aim.Prediction.Base
    local variation = (math.random() - 0.5) * self.Settings.Aim.Prediction.Variation * 2
    local pred = base + variation
    if self.Settings.Aim.Prediction.DistanceScale then pred = pred * (enemy.Distance / 300) end
    if self.Settings.Aim.Prediction.PingScale then
        local ping = game:GetService("Stats").Network.ServerStatsItem.DataPing:GetValue() / 100
        pred = pred * (1 + ping * 0.2)
    end
    pred = math.clamp(pred, 0, 0.5)
    local velocity = enemy.Velocity or Vector3.new(0,0,0)
    return enemy.Position + velocity * pred
end

function Aimbot:_GetSmoothedPosition(enemy, dt)
    if not self.Settings.Aim.History.Enabled then return self:_GetPrediction(enemy, dt) end
    local pos = enemy.Position
    table.insert(self._history, { Position = pos, Time = tick() })
    if #self._history > self.Settings.Aim.History.Size then table.remove(self._history, 1) end
    local avg = Vector3.new(0,0,0)
    local totalWeight = 0
    local now = tick()
    for i, entry in ipairs(self._history) do
        local age = now - entry.Time
        if age < 0.5 then
            local weight = 1 / (1 + age * 4)
            avg = avg + entry.Position * weight
            totalWeight = totalWeight + weight
        end
    end
    if totalWeight > 0 then return avg / totalWeight end
    return self:_GetPrediction(enemy, dt)
end

function Aimbot:_IsInViewAngle(targetPos)
    local cam = workspace.CurrentCamera
    if not cam then return true end
    local origin = cam.CFrame.Position
    local lookDir = cam.CFrame.LookVector
    local toTarget = (targetPos - origin).Unit
    local dot = lookDir:Dot(toTarget)
    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
    return angle <= self.Settings.General.ViewAngle
end

function Aimbot:_GetTrackingError(enemy)
    local speed = (enemy.Velocity or Vector3.new(0,0,0)).Magnitude
    local baseError = self.Settings.Aim.ErrorScale * 3
    local speedFactor = math.clamp(speed / 20, 0, 1)
    return baseError * (1 + speedFactor * 0.5)
end

function Aimbot:_GetSmoothAmount()
    local base = self.Settings.Aim.SmoothAmount
    local variation = self.Settings.Aim.SmoothVariation
    if variation > 0 then
        base = base + (math.random() - 0.5) * variation * 2
        base = math.clamp(base, 0, 100)
    end
    return base
end

function Aimbot:_ApplyOvershoot(targetPos, currentPos)
    local overshoot = self.Settings.Aim.Overshoot
    if overshoot <= 0 then return targetPos end
    local direction = (targetPos - currentPos).Unit
    local distance = (targetPos - currentPos).Magnitude
    local overshootAmount = distance * overshoot
    return targetPos + direction * overshootAmount
end

function Aimbot:_GetMicroOffset(dt)
    self._microPhase = self._microPhase + dt * (2 + math.random() * 0.5)
    local amp = 0.2 + math.random() * 0.3
    return Vector2.new(
        math.sin(self._microPhase) * amp,
        math.cos(self._microPhase * 0.7 + 0.5) * amp * 0.8
    )
end

function Aimbot:Shoot()
    if not self.Settings.Recoil.Enabled then return end
    local intensity = self.Settings.Recoil.Intensity * 2
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
    if not self.Settings.Recoil.Enabled then
        self._recoilOffset = Vector2.new(0,0)
        return
    end
    local time = tick()
    if time - self._lastShotTime > self.Settings.Recoil.ResetDelay then
        self._recoilOffset = Vector2.new(0,0)
    else
        self._recoilOffset = self._recoilOffset * self.Settings.Recoil.Decay
        if self._recoilOffset.Magnitude < 0.001 then self._recoilOffset = Vector2.new(0,0) end
    end
end

function Aimbot:CreateFOVCircle()
    if self._fovCircle then pcall(function() self._fovCircle:Remove() end); self._fovCircle = nil end
    if not self.Settings.FOV.Enabled or not self.Settings.General.Enabled then return end
    self._fovCircle = Drawing.new("Circle")
    self._fovCircle.Visible = true
    self._fovCircle.Thickness = self.Settings.FOV.Thickness
    self._fovCircle.Transparency = self.Settings.FOV.Transparency
    self._fovCircle.ZIndex = 10
    self._fovCircle.Filled = self.Settings.FOV.Filled
    self._fovCircle.NumSides = 128
    self._fovCircle.Color = self.Settings.FOV.Color

    if self._fovConnection then self._fovConnection:Disconnect() end
    local pulsePhase = 0
    self._fovConnection = game:GetService("RunService").RenderStepped:Connect(function()
        if not self._fovCircle or not self.Settings.FOV.Enabled or not self.Settings.General.Enabled then
            if self._fovCircle then self._fovCircle.Visible = false end
            return
        end
        local mouse = game:GetService("UserInputService"):GetMouseLocation()
        self._fovCircle.Position = Vector2.new(mouse.X, mouse.Y)
        self._fovCircle.Radius = self.Settings.FOV.Radius
        local hasTarget = self._currentTarget ~= nil
        self._fovCircle.Color = hasTarget and self.Settings.FOV.TargetColor or self.Settings.FOV.Color
        if self.Settings.FOV.Pulse then
            pulsePhase = pulsePhase + self.Settings.FOV.PulseSpeed * 0.02
            local pulse = 0.6 + 0.4 * math.sin(pulsePhase)
            self._fovCircle.Transparency = self.Settings.FOV.Transparency * pulse
        else
            self._fovCircle.Transparency = self.Settings.FOV.Transparency
        end
        self._fovCircle.Visible = true
    end)
end

function Aimbot:_ApplyTurnSpeedLimit(currentLook, targetLook, dt)
    if self.Settings.General.MaxTurnSpeed <= 0 then return targetLook end
    local angle = math.deg(math.acos(math.clamp(currentLook:Dot(targetLook), -1, 1)))
    local maxAngle = self.Settings.General.MaxTurnSpeed * dt
    if angle > maxAngle then
        local axis = currentLook:Cross(targetLook)
        if axis.Magnitude > 0.001 then
            axis = axis.Unit
            return currentLook * math.cos(math.rad(maxAngle)) + axis * math.sin(math.rad(maxAngle))
        end
    end
    return targetLook
}

function Aimbot:Update(target, dt)
    if not self.Settings.General.Enabled then
        self._lastAimPos = nil
        self._targetLostTime = 0
        return
    end

    local cam = workspace.CurrentCamera
    if not cam then return end

    if not self:_ShouldAim() then
        self._lastAimPos = nil
        self._targetLostTime = 0
        return
    end

    dt = dt or 0.016
    local now = tick()

    local hasValidTarget = false
    local aimPart = nil
    local targetPos = nil
    local enemy = nil

    if target and target.Visible then
        if self:_IsInViewAngle(target.Position) then
            enemy = target
            aimPart = self:_GetAimPart(target)
            if aimPart then
                targetPos = self:_GetSmoothedPosition(target, dt)
                hasValidTarget = true
                self._targetLostTime = 0
                self._targetAcquireTime = tick()
                self._currentTarget = target
            end
        end
    end

    if not hasValidTarget and self._currentTarget then
        self._targetLostTime = self._targetLostTime + dt
        if self._targetLostTime < self.Settings.General.GracePeriod then
            targetPos = self._lastAimPos or (self._currentTarget and self._currentTarget.Position)
            if targetPos then
                hasValidTarget = true
                enemy = self._currentTarget
            end
        else
            self._currentTarget = nil
            self._targetAcquireTime = 0
            if self._lastAimPos then
                local center = cam.ViewportSize / 2
                self._lastAimPos = self._lastAimPos:Lerp(center, 0.05)
                if (self._lastAimPos - center).Magnitude < 1 then
                    self._lastAimPos = nil
                end
            end
            return
        end
    end

    if not hasValidTarget or not aimPart or not enemy then return end

    if tick() - self._targetAcquireTime < self.Settings.Aim.ReactionTime then
        self._lastAimPos = nil
        return
    end

    local predictedPos = self:_GetPrediction(enemy, dt)
    local offset = self:_SelectOffset()
    predictedPos = predictedPos + offset

    local screenPos, onScreen = cam:WorldToScreenPoint(predictedPos)
    if not onScreen then
        self._lastAimPos = nil
        return
    end

    local mousePos = game:GetService("UserInputService"):GetMouseLocation()
    local aimScreen = Vector2.new(screenPos.X, screenPos.Y)

    self:_UpdateRecoil()
    aimScreen = aimScreen + self._recoilOffset

    local diffToMouse = (aimScreen - mousePos).Magnitude
    if diffToMouse < self.Settings.Aim.Deadzone then
        self._lastAimPos = nil
        return
    end

    if self.Settings.FOV.Enabled and diffToMouse > self.Settings.FOV.Radius then
        self._lastAimPos = nil
        return
    end

    local errorScale = self:_GetTrackingError(enemy)
    local errorOffset = Vector2.new(
        (math.random() - 0.5) * errorScale * 2,
        (math.random() - 0.5) * errorScale * 2
    )
    aimScreen = aimScreen + errorOffset

    if self._lastAimPos then
        local overshootTarget = self:_ApplyOvershoot(aimScreen, self._lastAimPos)
        aimScreen = overshootTarget
    end

    if self._lastAimPos then
        local smoothAmount = self:_GetSmoothAmount() / 100
        local alpha = 1 - math.exp(-smoothAmount * dt * 60)
        if self.Settings.Aim.Smooth then
            aimScreen = self._lastAimPos:Lerp(aimScreen, alpha)
        else
            aimScreen = self._lastAimPos:Lerp(aimScreen, 0.9)
        end
    end

    if self.Settings.Aim.Inertia > 0 and self._lastAimPos then
        local inertiaFactor = 1 - self.Settings.Aim.Inertia
        aimScreen = aimScreen:Lerp(mousePos, inertiaFactor)
    end

    local micro = self:_GetMicroOffset(dt)
    aimScreen = aimScreen + micro

    self._lastAimPos = aimScreen

    local aimPos = cam:ScreenToWorldPoint(Vector3.new(aimScreen.X, aimScreen.Y, 1000))
    local camPos = cam.CFrame.Position
    local lookVector = (aimPos - camPos).Unit

    local currentLook = cam.CFrame.LookVector
    lookVector = self:_ApplyTurnSpeedLimit(currentLook, lookVector, dt)

    cam.CFrame = CFrame.new(camPos, camPos + lookVector)
end

function Aimbot:_ShouldAim()
    if not self.Settings.General.Enabled then return false end
    local mode = self.Settings.General.Mode
    if mode == "Nunca" then return false end
    if mode == "Siempre" then return true end
    if mode == "Por bind" then
        local key = Enum.KeyCode[self.Settings.General.BindKey]
        return game:GetService("UserInputService"):IsKeyDown(key)
    end
    return false
end

function Aimbot:Enable()
    self.Settings.General.Enabled = true
    self:CreateFOVCircle()
    self._lastAimPos = nil
    self._targetLostTime = 0
    self._targetAcquireTime = 0
    self._currentOffset = nil
    self._microPhase = math.random() * 100
end

function Aimbot:Disable()
    self.Settings.General.Enabled = false
    self._lastAimPos = nil
    self._currentTarget = nil
    self._targetLostTime = 0
    self._targetAcquireTime = 0
    self._recoilOffset = Vector2.new(0,0)
    self._history = {}
    if self._fovCircle then pcall(function() self._fovCircle:Remove() end); self._fovCircle = nil end
    if self._fovConnection then self._fovConnection:Disconnect(); self._fovConnection = nil end
end

function Aimbot:Toggle()
    if self.Settings.General.Enabled then self:Disable() else self:Enable() end
    return self.Settings.General.Enabled
end

return Aimbot
