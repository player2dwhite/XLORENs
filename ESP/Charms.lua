--[=[
    XLORENs - Chams (ESP)
    Sistema de ESP con Highlight.
]=]

local Chams = {}
Chams.__index = Chams

function Chams:Init(framework)
    self._framework = framework
    self._chams = {}
    self.Settings = {
        Enabled = false,
        Color = Color3.fromRGB(0, 255, 0),
        Transparency = 0.7,
        OutlineColor = Color3.fromRGB(255, 255, 255),
        OutlineTransparency = 0,
    }
    self:_SetupEvents()
    return self
end

function Chams:_SetupEvents()
    local players = game:GetService("Players")
    players.PlayerAdded:Connect(function(p)
        task.wait(0.5)
        if self.Settings.Enabled and p ~= players.LocalPlayer then
            self:AddPlayer(p)
        end
    end)
    players.PlayerRemoving:Connect(function(p)
        self:RemovePlayer(p)
    end)
end

function Chams:AddPlayer(player)
    if not player or player == game:GetService("Players").LocalPlayer then return end
    self:RemovePlayer(player)

    local highlight = Instance.new("Highlight")
    highlight.Name = "XLORENs_Chams"
    highlight.FillColor = self.Settings.Color
    highlight.FillTransparency = self.Settings.Transparency
    highlight.OutlineColor = self.Settings.OutlineColor
    highlight.OutlineTransparency = self.Settings.OutlineTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = game:GetService("CoreGui")

    if player.Character then
        highlight.Adornee = player.Character
    end

    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        highlight.Adornee = char
    end)
    player.CharacterRemoving:Connect(function()
        highlight.Adornee = nil
    end)

    self._chams[player] = highlight
end

function Chams:RemovePlayer(player)
    if self._chams[player] then
        self._chams[player]:Destroy()
        self._chams[player] = nil
    end
end

function Chams:UpdateAll()
    local players = game:GetService("Players"):GetPlayers()
    for _, p in ipairs(players) do
        if p ~= game:GetService("Players").LocalPlayer then
            if self.Settings.Enabled then
                self:AddPlayer(p)
            else
                self:RemovePlayer(p)
            end
        end
    end
end

function Chams:Enable()
    self.Settings.Enabled = true
    self:UpdateAll()
end

function Chams:Disable()
    self.Settings.Enabled = false
    for p, _ in pairs(self._chams) do
        self:RemovePlayer(p)
    end
end

return Chams
