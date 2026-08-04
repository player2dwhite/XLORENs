--[=[
    XLORENs - Chams (ESP)
    Con Highlights, Box ESP (BoxHandleAdornment) e información (BillboardGui).
]=]

local Chams = {}
Chams.__index = Chams

function Chams:Init(framework)
    self._framework = framework
    self._chams = {}
    self._boxes = {}
    self._info = {}
    self._playersCache = {}
    self.Settings = {
        Enabled = false,
        ChamsEnabled = true,
        ChamsColor = Color3.fromRGB(0, 255, 0),
        ChamsTransparency = 0.7,
        ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
        ChamsOutlineTransparency = 0,
        ChamsByTeam = false,
        ChamsByHealth = false,
        BoxEnabled = true,
        BoxColor = Color3.fromRGB(0, 255, 0),
        BoxThickness = 2,
        BoxTransparency = 0.3,
        InfoEnabled = true,
        ShowName = true,
        ShowHealth = true,
        ShowDistance = true,
        InfoColor = Color3.fromRGB(255, 255, 255),
        InfoTransparency = 0.3,
        UseWallCheck = true,
        VisibleColor = Color3.fromRGB(0, 255, 0),
        HiddenColor = Color3.fromRGB(255, 0, 0),
    }
    self._updateConnection = nil
    self._updateRate = 0.15
    self:_SetupEvents()
    return self
end

function Chams:_SetupEvents()
    local players = game:GetService("Players")
    players.PlayerAdded:Connect(function(p)
        task.wait(0.5)
        if self.Settings.Enabled then self:AddPlayer(p) end
    end)
    players.PlayerRemoving:Connect(function(p) self:RemovePlayer(p) end)
    players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if self.Settings.Enabled then self:AddPlayer(p) end
        end)
    end)
end

function Chams:GetPlayerColor(player)
    local color = self.Settings.ChamsColor
    if self.Settings.ChamsByTeam then
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
    if self.Settings.ChamsByHealth then
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.MaxHealth > 0 then
            local healthPercent = hum.Health / hum.MaxHealth
            color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
        end
    end
    return color
end

function Chams:AddPlayer(player)
    if not player or player == game:GetService("Players").LocalPlayer then return end
    self:RemovePlayer(player)

    -- Highlight (Chams)
    if self.Settings.ChamsEnabled then
        local highlight = Instance.new("Highlight")
        highlight.Name = "XLORENs_Chams"
        highlight.FillColor = self:GetPlayerColor(player)
        highlight.FillTransparency = self.Settings.ChamsTransparency
        highlight.OutlineColor = self.Settings.ChamsOutlineColor
        highlight.OutlineTransparency = self.Settings.ChamsOutlineTransparency
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = game:GetService("CoreGui")
        if player.Character then highlight.Adornee = player.Character end
        player.CharacterAdded:Connect(function(char) task.wait(0.5); highlight.Adornee = char end)
        player.CharacterRemoving:Connect(function() highlight.Adornee = nil end)
        self._chams[player] = highlight
    end

    -- Box ESP
    if self.Settings.BoxEnabled then
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "XLORENs_Box"
                box.Size = Vector3.new(4, 6, 2)
                box.Adornee = root
                box.Color3 = self.Settings.BoxColor
                box.Transparency = self.Settings.BoxTransparency
                box.ZIndex = 10
                box.AlwaysOnTop = true
                box.Parent = root
                self._boxes[player] = box
            end
        end
    end

    -- Info ESP
    if self.Settings.InfoEnabled then
        local char = player.Character
        if char then
            local head = char:FindFirstChild("Head")
            if head then
                local billboard = Instance.new("BillboardGui")
                billboard.Name = "XLORENs_Info"
                billboard.Size = UDim2.new(0, 200, 0, 60)
                billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = head
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = self.Settings.InfoTransparency
                label.BackgroundColor3 = Color3.fromRGB(0,0,0)
                label.TextColor3 = self.Settings.InfoColor
                label.Font = Enum.Font.GothamBold
                label.TextSize = 14
                label.TextScaled = true
                label.Parent = billboard
                self._info[player] = { Billboard = billboard, Label = label }
            end
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
}

function Chams:UpdateAll()
    local players = game:GetService("Players"):GetPlayers()
    for _, p in ipairs(players) do
        if p ~= game:GetService("Players").LocalPlayer then
            if self.Settings.Enabled then self:AddPlayer(p) else self:RemovePlayer(p) end
        end
    end
end

function Chams:Enable()
    self.Settings.Enabled = true
    self:UpdateAll()
    if not self._updateConnection then
        self._updateConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if not self.Settings.Enabled then return end
            local players = game:GetService("Players"):GetPlayers()
            local lp = game:GetService("Players").LocalPlayer
            for _, plr in ipairs(players) do
                if plr == lp then continue end
                if not plr.Character then
                    if self._chams[plr] then self._chams[plr].Visible = false end
                    if self._boxes[plr] then self._boxes[plr].Visible = false end
                    if self._info[plr] then self._info[plr].Billboard.Enabled = false end
                    continue
                end
                -- Actualizar información periódicamente
                if self.Settings.InfoEnabled and self._info[plr] then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local text = ""
                        if self.Settings.ShowName then text = text .. plr.Name .. "\n" end
                        if self.Settings.ShowHealth then text = text .. "❤️ " .. math.floor(hum.Health) .. "\n" end
                        if self.Settings.ShowDistance then
                            local lpRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                            local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                            if lpRoot and targetRoot then
                                local dist = math.floor((lpRoot.Position - targetRoot.Position).Magnitude)
                                text = text .. "📏 " .. dist .. "m"
                            end
                        end
                        self._info[plr].Label.Text = text
                    end
                end
                -- Actualizar colores según visibilidad
                if self.Settings.UseWallCheck then
                    local origin = lp.Character and (lp.Character:FindFirstChild("Head") or lp.Character:FindFirstChild("HumanoidRootPart"))
                    if origin and self._framework and self._framework.WallChecker then
                        local result = self._framework.WallChecker:GetBestEnemy(origin.Position)
                        if result and result.Player == plr then
                            local isVisible = result.Visible
                            if self._chams[plr] then
                                self._chams[plr].FillColor = isVisible and self.Settings.VisibleColor or self.Settings.HiddenColor
                            end
                            if self._boxes[plr] then
                                self._boxes[plr].Color3 = isVisible and self.Settings.VisibleColor or self.Settings.HiddenColor
                            end
                        end
                    end
                end
            end
        end)
    end
end

function Chams:Disable()
    self.Settings.Enabled = false
    for p, _ in pairs(self._chams) do self:RemovePlayer(p) end
    if self._updateConnection then
        self._updateConnection:Disconnect()
        self._updateConnection = nil
    end
end

function Chams:Toggle()
    if self.Settings.Enabled then self:Disable() else self:Enable() end
    return self.Settings.Enabled
end

return Chams
