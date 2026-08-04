--[=[
    XLORENs - Chams (ESP)
]=]

local Chams = {}
Chams.__index = Chams

function Chams:Init(framework)
    self._framework = framework
    self._chams = {}
    self._boxes = {}
    self.Settings = {
        Enabled = false,
        ChamsEnabled = true,
        ChamsColor = Color3.fromRGB(0, 255, 0),
        ChamsTransparency = 0.7,
        BoxEnabled = true,
        BoxColor = Color3.fromRGB(0, 255, 0),
        BoxThickness = 2,
        InfoEnabled = true,
        ShowName = true,
        ShowHealth = true,
        ShowDistance = true,
        UseWallCheck = true,
        VisibleColor = Color3.fromRGB(0, 255, 0),
        HiddenColor = Color3.fromRGB(255, 0, 0),
    }
    self._updateConnection = nil
    self._playersCache = {}
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

function Chams:AddPlayer(player)
    if not player or player == game:GetService("Players").LocalPlayer then return end
    self:RemovePlayer(player)

    -- Highlight
    if self.Settings.ChamsEnabled then
        local highlight = Instance.new("Highlight")
        highlight.Name = "XLORENs_Chams"
        highlight.FillColor = self.Settings.ChamsColor
        highlight.FillTransparency = self.Settings.ChamsTransparency
        highlight.OutlineColor = Color3.fromRGB(255,255,255)
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = game:GetService("CoreGui")
        if player.Character then highlight.Adornee = player.Character end
        player.CharacterAdded:Connect(function(char) task.wait(0.5); highlight.Adornee = char end)
        player.CharacterRemoving:Connect(function() highlight.Adornee = nil end)
        self._chams[player] = highlight
    end

    -- Box ESP (usando BoxHandleAdornment como en Town)
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
                box.Transparency = 0.3
                box.ZIndex = 10
                box.AlwaysOnTop = true
                box.Parent = root
                self._boxes[player] = box
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
    self._playersCache[player] = nil
end

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
end

function Chams:Disable()
    self.Settings.Enabled = false
    for p, _ in pairs(self._chams) do self:RemovePlayer(p) end
    if self._updateConnection then self._updateConnection:Disconnect(); self._updateConnection = nil end
end

function Chams:Toggle()
    if self.Settings.Enabled then self:Disable() else self:Enable() end
    return self.Settings.Enabled
end

return Chams
