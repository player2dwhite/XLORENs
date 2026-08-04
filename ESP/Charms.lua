--[=[
    XLORENs - Chams (ESP)
    Sistema de ESP con highlights, boxes e información.
]=]

local Chams = {}
Chams.__index = Chams

Chams.DefaultSettings = {
    Enabled = false,
    Highlights = {
        Enabled = true,
        Color = Color3.fromRGB(0, 255, 0),
        Transparency = 0.7,
        OutlineColor = Color3.fromRGB(255, 255, 255),
        OutlineTransparency = 0,
        ColorByHealth = false,
        ColorByTeam = false,
    },
    Box = {
        Enabled = true,
        Color = Color3.fromRGB(0, 255, 0),
        Thickness = 2,
        Transparency = 0.3,
    },
    Info = {
        Enabled = true,
        ShowName = true,
        ShowHealth = true,
        ShowDistance = true,
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 0.3,
    },
    Visibility = {
        UseWallCheck = true,
        VisibleColor = Color3.fromRGB(0, 255, 0),
        HiddenColor = Color3.fromRGB(255, 0, 0),
    },
}

function Chams:Initialize(framework)
    self._framework = framework
    self._settings = Chams.DefaultSettings
    self._chams = {}
    self._boxes = {}
    self._info = {}
    self._playersCache = {}
    self._updateConnection = nil
    self:_SetupEvents()
    return self
}

function Chams:_SetupEvents()
    local players = game:GetService("Players")
    players.PlayerAdded:Connect(function(player)
        task.wait(0.5)
        if self._settings.Enabled then self:AddPlayer(player) end
    end)
    players.PlayerRemoving:Connect(function(player)
        self:RemovePlayer(player)
    end)
    players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if self._settings.Enabled then self:AddPlayer(player) end
        end)
    end)
end

function Chams:AddPlayer(player)
    if not player or player == game:GetService("Players").LocalPlayer then return end
    self:RemovePlayer(player)

    local character = player.Character
    if not character then return end

    if self._settings.Highlights.Enabled then
        local highlight = Instance.new("Highlight")
        highlight.Name = "XLORENs_ESP_Highlight"
        highlight.FillColor = self:_GetPlayerColor(player)
        highlight.FillTransparency = self._settings.Highlights.Transparency
        highlight.OutlineColor = self._settings.Highlights.OutlineColor
        highlight.OutlineTransparency = self._settings.Highlights.OutlineTransparency
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = game:GetService("CoreGui")
        highlight.Adornee = character
        self._chams[player] = highlight
    end

    if self._settings.Box.Enabled then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "XLORENs_ESP_Box"
            box.Size = Vector3.new(4, 6, 2)
            box.Adornee = root
            box.Color3 = self._settings.Box.Color
            box.Transparency = self._settings.Box.Transparency
            box.ZIndex = 10
            box.AlwaysOnTop = true
            box.Parent = root
            self._boxes[player] = box
        end
    end

    if self._settings.Info.Enabled then
        local head = character:FindFirstChild("Head")
        if head then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "XLORENs_ESP_Info"
            billboard.Size = UDim2.new(0, 200, 0, 60)
            billboard.StudsOffset = Vector3.new(0, 1.5, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = head

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundTransparency = self._settings.Info.Transparency
            frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            frame.BorderSizePixel = 0
            frame.Parent = billboard

            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.TextColor3 = self._settings.Info.Color
            textLabel.Font = Enum.Font.GothamBold
            textLabel.TextSize = 12
            textLabel.TextWrapped = true
            textLabel.TextScaled = true
            textLabel.Parent = frame

            self._info[player] = {
                Billboard = billboard,
                TextLabel = textLabel,
            }
        end
    end
end

function Chams:RemovePlayer(player)
    if self._chams[player] then
        self._chams[player]:Destroy()
        self._chams[player] = nil
    end
    if self._boxes[player] then
        self._boxes[player]:Destroy()
        self._boxes[player] = nil
    end
    if self._info[player] then
        self._info[player].Billboard:Destroy()
        self._info[player] = nil
    end
    self._playersCache[player] = nil
end

function Chams:_GetPlayerColor(player)
    local color = self._settings.Highlights.Color

    if self._settings.Highlights.ColorByTeam then
        local localTeam = game:GetService("Players").LocalPlayer.Team
        local targetTeam = player.Team
        if targetTeam and localTeam then
            if targetTeam == localTeam then
                color = Color3.fromRGB(0, 255, 255)
            else
                color = Color3.fromRGB(255, 0, 0)
            end
        end
    end

    if self._settings.Highlights.ColorByHealth then
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.MaxHealth > 0 then
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            color = Color3.fromRGB(
                255 * (1 - healthPercent),
                255 * healthPercent,
                0
            )
        end
    end

    return color
end

function Chams:UpdateAll()
    local players = game:GetService("Players"):GetPlayers()
    for _, player in ipairs(players) do
        if player ~= game:GetService("Players").LocalPlayer then
            if self._settings.Enabled then
                self:AddPlayer(player)
            else
                self:RemovePlayer(player)
            end
        end
    end
end

function Chams:Enable()
    self._settings.Enabled = true
    self:UpdateAll()
    self:_StartUpdateLoop()
end

function Chams:Disable()
    self._settings.Enabled = false
    for player, _ in pairs(self._chams) do
        self:RemovePlayer(player)
    end
    if self._updateConnection then
        self._updateConnection:Disconnect()
        self._updateConnection = nil
    end
end

function Chams:_StartUpdateLoop()
    if self._updateConnection then
        self._updateConnection:Disconnect()
        self._updateConnection = nil
    end
    self._updateConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not self._settings.Enabled then
            for player, _ in pairs(self._chams) do
                if self._chams[player] then
                    self._chams[player].Visible = false
                end
            end
            return
        end

        local localPlayer = game:GetService("Players").LocalPlayer
        local wallChecker = self._framework and self._framework.WallChecker

        for player, highlight in pairs(self._chams) do
            local character = player.Character
            if not character then
                highlight.Visible = false
                continue
            end

            if self._settings.Visibility.UseWallCheck and wallChecker then
                local originPart = localPlayer.Character and (localPlayer.Character:FindFirstChild("Head") or localPlayer.Character:FindFirstChild("HumanoidRootPart"))
                if originPart then
                    local head = character:FindFirstChild("Head")
                    if head then
                        local isVisible = true -- Simulación, se puede usar wallChecker:GetBestEnemy
                        if isVisible then
                            highlight.FillColor = self._settings.Visibility.VisibleColor
                        else
                            highlight.FillColor = self._settings.Visibility.HiddenColor
                        end
                    end
                end
            else
                highlight.FillColor = self:_GetPlayerColor(player)
            end

            highlight.Visible = true
            if highlight.Adornee ~= character then
                highlight.Adornee = character
            end
        end

        for player, info in pairs(self._info) do
            local character = player.Character
            if not character then
                info.Billboard.Visible = false
                continue
            end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                info.Billboard.Visible = false
                continue
            end

            local text = ""
            if self._settings.Info.ShowName then
                text = text .. player.Name .. "\n"
            end
            if self._settings.Info.ShowHealth then
                text = text .. "❤️ " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth) .. "\n"
            end
            if self._settings.Info.ShowDistance then
                local localChar = localPlayer.Character
                local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
                local targetRoot = character:FindFirstChild("HumanoidRootPart")
                if localRoot and targetRoot then
                    local distance = (localRoot.Position - targetRoot.Position).Magnitude
                    text = text .. "📏 " .. math.floor(distance) .. "m"
                end
            end
            info.TextLabel.Text = text
            info.Billboard.Visible = true
        end
    end)
end

return Chams
