--[=[
    XLORENs - Movement
    Control de movimiento avanzado:
    - Walk Speed
    - Jump Power
    - Infinite Jump
    - Fly (modo vuelo con control de cámara)
    - Noclip (atravesar paredes)
    - Freecam (cámara libre)
]=]

local Movement = {}
Movement.__index = Movement

Movement.DefaultSettings = {
    Enabled = true,
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Fly = {
        Enabled = false,
        Speed = 50,
    },
    Noclip = false,
    Freecam = {
        Enabled = false,
        Speed = 30,
        Sensitivity = 0.5,
    },
}

function Movement:Initialize(framework)
    self._framework = framework
    self._settings = Movement.DefaultSettings
    self._isFlying = false
    self._flyBodyVelocity = nil
    self._flyConnection = nil
    self._noclipConnection = nil
    self._freecamConnection = nil
    self._originalCamera = nil
    self._freecamCFrame = nil
    self._connections = {}
    self._SetupUpdateLoop()
    return self
end

function Movement:_SetupUpdateLoop()
    -- Aplicar velocidad y salto
    local speedConn = game:GetService("RunService").RenderStepped:Connect(function()
        if not self._settings.Enabled then return end
        local character = game:GetService("Players").LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = self._settings.WalkSpeed
                humanoid.JumpPower = self._settings.JumpPower
            end
        end
    end)
    table.insert(self._connections, speedConn)

    -- Infinite Jump
    local jumpConn = game:GetService("RunService").RenderStepped:Connect(function()
        if not self._settings.Enabled or not self._settings.InfiniteJump then return end
        local character = game:GetService("Players").LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                local inputService = game:GetService("UserInputService")
                if inputService:IsKeyDown(Enum.KeyCode.Space) then
                    if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end
        end
    end)
    table.insert(self._connections, jumpConn)

    -- Noclip
    local noclipConn = game:GetService("RunService").Heartbeat:Connect(function()
        if not self._settings.Enabled or not self._settings.Noclip then
            return
        end
        local character = game:GetService("Players").LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
    table.insert(self._connections, noclipConn)
    self._noclipConnection = noclipConn

    -- Freecam (se activa por separado)
end

-- ===== FLY =====
function Movement:ToggleFly()
    if not self._settings.Fly.Enabled then
        if self._isFlying then
            self._isFlying = false
            if self._flyBodyVelocity then
                self._flyBodyVelocity:Destroy()
                self._flyBodyVelocity = nil
            end
            local character = game:GetService("Players").LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.PlatformStand = false
                end
            end
            if self._flyConnection then
                self._flyConnection:Disconnect()
                self._flyConnection = nil
            end
        end
        return
    end

    self._isFlying = not self._isFlying
    local character = game:GetService("Players").LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if self._isFlying then
                humanoid.PlatformStand = true
                self._flyBodyVelocity = Instance.new("BodyVelocity")
                self._flyBodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 10000
                local rootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
                if rootPart then
                    self._flyBodyVelocity.Parent = rootPart
                end

                if self._flyConnection then
                    self._flyConnection:Disconnect()
                    self._flyConnection = nil
                end
                self._flyConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    if not self._isFlying or not self._settings.Fly.Enabled then return end
                    local char = game:GetService("Players").LocalPlayer.Character
                    if char and self._flyBodyVelocity then
                        local camera = workspace.CurrentCamera
                        if not camera then return end
                        local moveDirection = Vector3.new(0, 0, 0)
                        local forward = camera.CFrame.LookVector
                        local right = camera.CFrame.RightVector
                        local up = camera.CFrame.UpVector
                        local inputService = game:GetService("UserInputService")

                        if inputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + forward end
                        if inputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - forward end
                        if inputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - right end
                        if inputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + right end
                        if inputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + up end
                        if inputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - up end

                        if moveDirection.Magnitude > 0 then
                            moveDirection = moveDirection.Unit * self._settings.Fly.Speed
                            self._flyBodyVelocity.Velocity = moveDirection
                        else
                            self._flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
                        end
                    end
                end)
                table.insert(self._connections, self._flyConnection)
            else
                humanoid.PlatformStand = false
                if self._flyBodyVelocity then
                    self._flyBodyVelocity:Destroy()
                    self._flyBodyVelocity = nil
                end
                if self._flyConnection then
                    self._flyConnection:Disconnect()
                    self._flyConnection = nil
                end
            end
        end
    end
end

-- ===== FREECAM =====
function Movement:ToggleFreecam()
    local camera = workspace.CurrentCamera
    if not camera then return end

    if not self._settings.Freecam.Enabled then
        if self._freecamConnection then
            self._freecamConnection:Disconnect()
            self._freecamConnection = nil
        end
        -- Restaurar cámara
        if self._originalCamera then
            camera.CameraSubject = self._originalCamera.CameraSubject
            camera.CameraType = self._originalCamera.CameraType
            camera.CFrame = self._originalCamera.CFrame
            self._originalCamera = nil
        end
        return
    end

    if not self._freecamConnection then
        -- Guardar estado original
        self._originalCamera = {
            CameraSubject = camera.CameraSubject,
            CameraType = camera.CameraType,
            CFrame = camera.CFrame,
        }
        camera.CameraType = Enum.CameraType.Scriptable

        self._freecamCFrame = camera.CFrame
        local inputService = game:GetService("UserInputService")

        self._freecamConnection = game:GetService("RunService").RenderStepped:Connect(function()
            if not self._settings.Freecam.Enabled then return end

            local moveDirection = Vector3.new(0, 0, 0)
            local forward = self._freecamCFrame.LookVector
            local right = self._freecamCFrame.RightVector
            local up = self._freecamCFrame.UpVector

            if inputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + forward end
            if inputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - forward end
            if inputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - right end
            if inputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + right end
            if inputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + up end
            if inputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - up end

            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit * self._settings.Freecam.Speed
                self._freecamCFrame = self._freecamCFrame + moveDirection
            end

            -- Rotación con el mouse
            local mouseDelta = inputService:GetMouseDelta()
            if mouseDelta.X ~= 0 or mouseDelta.Y ~= 0 then
                local sensitivity = self._settings.Freecam.Sensitivity
                local yaw = -mouseDelta.X * sensitivity * 0.01
                local pitch = -mouseDelta.Y * sensitivity * 0.01
                self._freecamCFrame = self._freecamCFrame * CFrame.Angles(0, yaw, 0)
                self._freecamCFrame = self._freecamCFrame * CFrame.Angles(pitch, 0, 0)
            end

            camera.CFrame = self._freecamCFrame
        end)
        table.insert(self._connections, self._freecamConnection)
    end
end

function Movement:Cleanup()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    self._connections = {}
    if self._flyBodyVelocity then
        self._flyBodyVelocity:Destroy()
        self._flyBodyVelocity = nil
    end
    self._isFlying = false
    if self._flyConnection then
        self._flyConnection:Disconnect()
        self._flyConnection = nil
    end
    if self._freecamConnection then
        self._freecamConnection:Disconnect()
        self._freecamConnection = nil
    end
    if self._noclipConnection then
        self._noclipConnection:Disconnect()
        self._noclipConnection = nil
    end
end

return Movement
