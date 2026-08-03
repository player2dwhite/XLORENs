--[=[
    XLORENs - ESP (Chams + Box + Info)
    Sistema de ESP completo con:
    - Highlights (chams) con colores por equipo y salud.
    - Box ESP (cajas 2D) usando Drawing.
    - Información en pantalla (nombre, salud, distancia).
    - Detección de visibilidad con WallChecker.
    - Alto rendimiento con caché y actualización inteligente.
]=]

local Chams = {}
Chams.__index = Chams

function Chams:Init(framework)
    self._framework = framework
    self._chams = {}
    self._boxEsp = {}      -- Caché de objetos Drawing para Box ESP
    self._infoEsp = {}     -- Caché de BillboardGuis para información
    self._playersCache = {} -- Datos de jugadores para actualización eficiente

    -- ===== CONFIGURACIÓN =====
    self.Settings = {
        Enabled = false,

        -- Highlights (Chams)
        ChamsEnabled = true,
        ChamsColor = Color3.fromRGB(0, 255, 0),
        ChamsTransparency = 0.7,
        ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
        ChamsOutlineTransparency = 0,
        ChamsByTeam = false,      -- Colorear por equipo (si el juego tiene Teams)
        ChamsByHealth = false,    -- Colorear según salud (verde → rojo)

        -- Box ESP
        BoxEnabled = true,
        BoxColor = Color3.fromRGB(0, 255, 0),
        BoxThickness = 2,
        BoxTransparency = 0.8,
        BoxFilled = false,

        -- Información (Info)
        InfoEnabled = true,
        ShowName = true,
        ShowHealth = true,
        ShowDistance = true,
        InfoColor = Color3.fromRGB(255, 255, 255),
        InfoTransparency = 0.3,

        -- Visibilidad
        UseWallCheck = true,     -- Usar WallChecker para detectar si el enemigo está visible
        VisibleColor = Color3.fromRGB(0, 255, 0),
        HiddenColor = Color3.fromRGB(255, 0, 0),
    }

    self._updateConnection = nil
    self._updateRate = 0.15  -- Actualizar cada 150ms para rendimiento

    self:_SetupEvents()
    return self
end

-- ====================================================
-- EVENTOS
-- ====================================================
function Chams:_SetupEvents()
    local players = game:GetService("Players")
    players.PlayerAdded:Connect(function(p)
        task.wait(0.5)
        if self.Settings.Enabled then
            self:AddPlayer(p)
        end
    end)
    players.PlayerRemoving:Connect(function(p)
        self:RemovePlayer(p)
    end)
    -- Actualizar cuando cambia el personaje
    players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if self.Settings.Enabled then
                self:AddPlayer(p)
            end
        end)
    end)
end

-- ====================================================
-- OBTENER COLOR SEGÚN CONFIGURACIÓN
-- ====================================================
function Chams:GetPlayerColor(player)
    local color = self.Settings.ChamsColor

    -- Por equipo (si está activado y el jugador tiene Team)
    if self.Settings.ChamsByTeam then
        local localTeam = game:GetService("Players").LocalPlayer.Team
        local targetTeam = player.Team
        if targetTeam and localTeam then
            if targetTeam == localTeam then
                color = Color3.fromRGB(0, 255, 255) -- Aliado: cian
            else
                color = Color3.fromRGB(255, 0, 0)   -- Enemigo: rojo
            end
        end
    end

    -- Por salud (verde → amarillo → rojo)
    if self.Settings.ChamsByHealth then
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.MaxHealth > 0 then
            local healthPercent = hum.Health / hum.MaxHealth
            color = Color3.fromRGB(
                255 * (1 - healthPercent),
                255 * healthPercent,
                0
            )
        end
    end

    return color
end

-- ====================================================
-- HIGHLIGHTS (CHAMS)
-- ====================================================
function Chams:AddPlayer(player)
    if not player or player == game:GetService("Players").LocalPlayer then return end
    self:RemovePlayer(player)

    -- Crear Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "XLORENs_Chams"
    highlight.FillColor = self:GetPlayerColor(player)
    highlight.FillTransparency = self.Settings.ChamsTransparency
    highlight.OutlineColor = self.Settings.ChamsOutlineColor
    highlight.OutlineTransparency = self.Settings.ChamsOutlineTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = game:GetService("CoreGui")

    if player.Character then
        highlight.Adornee = player.Character
    end

    -- Conectar eventos
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        highlight.Adornee = char
    end)
    player.CharacterRemoving:Connect(function()
        highlight.Adornee = nil
    end)

    self._chams[player] = highlight

    -- Crear Box ESP y Info ESP
    if self.Settings.BoxEnabled then
        self:_AddBoxEsp(player)
    end
    if self.Settings.InfoEnabled then
        self:_AddInfoEsp(player)
    end
end

function Chams:RemovePlayer(player)
    -- Eliminar Highlight
    if self._chams[player] then
        self._chams[player]:Destroy()
        self._chams[player] = nil
    end
    -- Eliminar Box ESP
    if self._boxEsp[player] then
        for _, obj in ipairs(self._boxEsp[player]) do
            pcall(function() obj:Remove() end)
        end
        self._boxEsp[player] = nil
    end
    -- Eliminar Info ESP
    if self._infoEsp[player] then
        self._infoEsp[player]:Destroy()
        self._infoEsp[player] = nil
    end
    -- Limpiar caché
    self._playersCache[player] = nil
end

-- ====================================================
-- BOX ESP (con Drawing)
-- ====================================================
function Chams:_AddBoxEsp(player)
    if self._boxEsp[player] then return end
    local boxes = {}

    -- Crear 4 líneas para el rectángulo
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Visible = true
        line.Color = self.Settings.BoxColor
        line.Thickness = self.Settings.BoxThickness
        line.Transparency = self.Settings.BoxTransparency
        table.insert(boxes, line)
    end

    self._boxEsp[player] = boxes
end

function Chams:_UpdateBoxEsp(player, char)
    local boxes = self._boxEsp[player]
    if not boxes or not char then return end

    local cam = workspace.CurrentCamera
    if not cam then return end

    -- Obtener el torso y la cabeza para calcular la caja
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not head or not root then
        -- Ocultar líneas
        for _, line in ipairs(boxes) do
            line.Visible = false
        end
        return
    end

    -- Calcular puntos en pantalla
    local topPos, topVis = cam:WorldToScreenPoint(head.Position + Vector3.new(0, 1.5, 0))
    local bottomPos, bottomVis = cam:WorldToScreenPoint(root.Position - Vector3.new(0, 1.5, 0))

    if not topVis or not bottomVis then
        for _, line in ipairs(boxes) do
            line.Visible = false
        end
        return
    end

    local width = (bottomPos.Y - topPos.Y) * 0.4
    local topLeft = Vector2.new(topPos.X - width, topPos.Y)
    local topRight = Vector2.new(topPos.X + width, topPos.Y)
    local bottomLeft = Vector2.new(bottomPos.X - width, bottomPos.Y)
    local bottomRight = Vector2.new(bottomPos.X + width, bottomPos.Y)

    -- Actualizar líneas
    boxes[1].From = topLeft
    boxes[1].To = topRight
    boxes[2].From = topRight
    boxes[2].To = bottomRight
    boxes[3].From = bottomRight
    boxes[3].To = bottomLeft
    boxes[4].From = bottomLeft
    boxes[4].To = topLeft

    -- Visibilidad de líneas
    for _, line in ipairs(boxes) do
        line.Visible = true
        -- Color según visibilidad (si está activado)
        if self.Settings.UseWallCheck and self._playersCache[player] then
            local isVisible = self._playersCache[player].Visible or false
            line.Color = isVisible and self.Settings.VisibleColor or self.Settings.HiddenColor
        else
            line.Color = self.Settings.BoxColor
        end
    end
end

-- ====================================================
-- INFO ESP (BillboardGui)
-- ====================================================
function Chams:_AddInfoEsp(player)
    if self._infoEsp[player] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "XLORENs_Info"
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = game:GetService("CoreGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = self.Settings.InfoTransparency
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = self.Settings.InfoColor
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 12
    textLabel.TextWrapped = true
    textLabel.TextScaled = true
    textLabel.Parent = frame

    -- Conectar al personaje del jugador
    local function updateAdornee()
        if player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                billboard.Adornee = head
            else
                billboard.Adornee = player.Character
            end
        else
            billboard.Adornee = nil
        end
    end

    player.CharacterAdded:Connect(updateAdornee)
    player.CharacterRemoving:Connect(function()
        billboard.Adornee = nil
    end)

    self._infoEsp[player] = {
        Billboard = billboard,
        TextLabel = textLabel,
    }
end

function Chams:_UpdateInfoEsp(player, char)
    local info = self._infoEsp[player]
    if not info or not info.TextLabel then return end

    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then
        info.TextLabel.Text = ""
        return
    end

    local text = ""
    if self.Settings.ShowName then
        text = text .. player.Name .. "\n"
    end
    if self.Settings.ShowHealth then
        text = text .. "❤️ " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. "\n"
    end
    if self.Settings.ShowDistance then
        local localPlayer = game:GetService("Players").LocalPlayer
        local localChar = localPlayer.Character
        local root = localChar and localChar:FindFirstChild("HumanoidRootPart")
        local targetRoot = char and char:FindFirstChild("HumanoidRootPart")
        if root and targetRoot then
            local dist = (root.Position - targetRoot.Position).Magnitude
            text = text .. "📏 " .. math.floor(dist) .. "m"
        end
    end

    info.TextLabel.Text = text
end

-- ====================================================
-- ACTUALIZACIÓN PRINCIPAL (bucle eficiente)
-- ====================================================
function Chams:_UpdateLoop()
    if self._updateConnection then
        self._updateConnection:Disconnect()
        self._updateConnection = nil
    end

    self._updateConnection = game:GetService("RunService").Heartbeat:Connect(function()
        -- Solo actualizar si está habilitado
        if not self.Settings.Enabled then
            -- Ocultar todos los elementos
            for p, _ in pairs(self._chams) do
                if self._chams[p] then
                    self._chams[p].Visible = false
                end
            end
            for p, boxes in pairs(self._boxEsp) do
                for _, line in ipairs(boxes) do
                    line.Visible = false
                end
            end
            return
        end

        local players = game:GetService("Players"):GetPlayers()
        local localPlayer = game:GetService("Players").LocalPlayer

        -- Obtener WallChecker si está disponible
        local wallChecker = self._framework and self._framework.WallChecker

        for _, plr in ipairs(players) do
            if plr == localPlayer then
                -- Ocultar el propio jugador
                if self._chams[plr] then
                    self._chams[plr].Visible = false
                end
                if self._boxEsp[plr] then
                    for _, line in ipairs(self._boxEsp[plr]) do
                        line.Visible = false
                    end
                end
                continue
            end

            local char = plr.Character
            if not char then
                -- Si no tiene personaje, ocultar elementos
                if self._chams[plr] then
                    self._chams[plr].Visible = false
                end
                if self._boxEsp[plr] then
                    for _, line in ipairs(self._boxEsp[plr]) do
                        line.Visible = false
                    end
                end
                continue
            end

            -- Verificar si el jugador está visible (usando WallChecker)
            local isVisible = true
            if self.Settings.UseWallCheck and wallChecker and wallChecker.GetBestEnemy then
                local origin = localPlayer.Character and (localPlayer.Character:FindFirstChild("Head") or localPlayer.Character:FindFirstChild("HumanoidRootPart"))
                if origin then
                    -- Verificar visibilidad de una parte concreta (cabeza)
                    local head = char:FindFirstChild("Head")
                    if head then
                        local result = wallChecker:CanSee(origin, head, {localPlayer.Character})
                        isVisible = result and result.Visible or false
                    else
                        isVisible = false
                    end
                end
            end

            -- Guardar en caché para usarlo en colores
            self._playersCache[plr] = {
                Visible = isVisible,
                Character = char,
                Humanoid = char:FindFirstChildOfClass("Humanoid"),
            }

            -- Actualizar Highlight
            if self.Settings.ChamsEnabled and self._chams[plr] then
                local hl = self._chams[plr]
                hl.Visible = true
                -- Color según visibilidad
                if self.Settings.UseWallCheck and not isVisible then
                    hl.FillColor = self.Settings.HiddenColor
                else
                    hl.FillColor = self:GetPlayerColor(plr)
                end
                hl.FillTransparency = self.Settings.ChamsTransparency
                hl.OutlineColor = self.Settings.ChamsOutlineColor
                hl.OutlineTransparency = self.Settings.ChamsOutlineTransparency
                if hl.Adornee ~= char then
                    hl.Adornee = char
                end
            end

            -- Actualizar Box ESP
            if self.Settings.BoxEnabled then
                if not self._boxEsp[plr] then
                    self:_AddBoxEsp(plr)
                end
                self:_UpdateBoxEsp(plr, char)
            end

            -- Actualizar Info ESP
            if self.Settings.InfoEnabled then
                if not self._infoEsp[plr] then
                    self:_AddInfoEsp(plr)
                end
                self:_UpdateInfoEsp(plr, char)
            end
        end
    end)
end

-- ====================================================
-- FUNCIONES PÚBLICAS
-- ====================================================
function Chams:Enable()
    self.Settings.Enabled = true
    self:UpdateAll()
    self:_UpdateLoop()
end

function Chams:Disable()
    self.Settings.Enabled = false
    for p, _ in pairs(self._chams) do
        self:RemovePlayer(p)
    end
    if self._updateConnection then
        self._updateConnection:Disconnect()
        self._updateConnection = nil
    end
    -- Ocultar elementos del propio jugador
    local lp = game:GetService("Players").LocalPlayer
    if self._chams[lp] then
        self._chams[lp].Visible = false
    end
    if self._boxEsp[lp] then
        for _, line in ipairs(self._boxEsp[lp]) do
            line.Visible = false
        end
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

function Chams:Toggle()
    if self.Settings.Enabled then
        self:Disable()
    else
        self:Enable()
    end
    return self.Settings.Enabled
end

return Chams
