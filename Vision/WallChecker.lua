--[=[
    XLORENs - WallChecker v3.5
    Motor de percepción avanzado con:
    - Raycast por capas (atraviesa objetos transparentes y paredes finas)
    - Puntos adaptativos por tipo de parte (Head, Body, Limbs)
    - Caché de puntos por personaje
    - Team Check avanzado (oficial, Attributes, TeamColor, leaderstats, Data folders)
    - Visibilidad, confianza, exposición, score
    - FOV, distancia máxima, materiales suaves
    - API orientada a objetos (enemy:GetAimPart(), enemy:GetPredictionPosition())
]=]

local WallChecker = {}
WallChecker.__index = WallChecker

-- ===== CONFIGURACIÓN =====
WallChecker.DefaultSettings = {
    MinimumVisibility = 0.15,
    MinimumImportantVisibility = 0.25,
    MaxLayers = 2,
    MaxDistance = 500,
    SoftMaterials = {
        [Enum.Material.Glass] = true,
        [Enum.Material.ForceField] = true,
        [Enum.Material.Ice] = true,
    },
    IgnoreAccessories = true,
    IgnoreEffects = true,
    PointMode = "fast",          -- "fast", "medium", "high"
    PartPriority = {
        Head = 20,
        UpperTorso = 10,
        LowerTorso = 5,
        HumanoidRootPart = 3,
    },
    VisionAngle = 120,
    TeamCheckMode = "Auto",
    CustomTeamProperty = nil,
    IgnoreSameTeam = true,
    AllowNeutral = true,
    NeutralIsEnemy = true,
    IgnoreDead = true,
    IgnoreForceField = true,
    EarlyExitOnCenter = false,
    Debug = false,
    DebugDuration = 0.5,
}

-- ===== OBJETO ENEMY =====
local Enemy = {}
Enemy.__index = Enemy

function Enemy:GetAimPart(priority)
    priority = priority or {
        Head = 1,
        UpperTorso = 2,
        HumanoidRootPart = 3,
        LowerTorso = 4,
    }
    local candidates = {}
    for _, partName in ipairs({"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"}) do
        local part = self.Character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local visible = false
            if partName == "Head" and self.AimParts.Head then visible = true end
            if partName ~= "Head" and self.AimParts.Body then visible = true end
            if visible then
                table.insert(candidates, { Part = part, Priority = priority[partName] or 10 })
            end
        end
    end
    if #candidates == 0 then return self.VisiblePart end
    table.sort(candidates, function(a, b) return a.Priority < b.Priority end)
    return candidates[1].Part
end

function Enemy:GetPredictionPosition(predictionFactor)
    predictionFactor = predictionFactor or 0.12
    local pos = self.Position
    if self.Velocity.Magnitude > 0 then
        local factor = math.clamp(predictionFactor * (self.Distance / 300), 0, 0.25)
        pos = pos + self.Velocity * factor
    end
    return pos
end

function Enemy:IsValid()
    return self.Visible and self.Character and self.Humanoid and self.Humanoid.Health > 0
end

function Enemy:GetPriority()
    return self.Score or 0
end

-- ===== WALLCHECKER =====
function WallChecker:Initialize(framework)
    self._framework = framework
    self._settings = WallChecker.DefaultSettings
    self.EnemyCache = {}
    self._lastUpdate = 0
    self._updateDelay = 0.15

    -- Team Checker internals
    self._teamSystemDetected = nil
    self._teamCache = {}
    self._neutralCache = {}
    self._enemyCache = {}

    -- Point Cache
    self._pointCache = {}
    self._cacheConnections = {}

    -- Eventos para caché automática
    self:_SetupEvents()

    -- Timer para Team Checker (optimización)
    task.spawn(function()
        while task.wait(5) do
            self:_ResetTeamCache()
        end
    end)

    return self
end

function WallChecker:_SetupEvents()
    local players = game:GetService("Players")
    players.PlayerAdded:Connect(function() self:RefreshCache() end)
    players.PlayerRemoving:Connect(function() self:RefreshCache() end)

    for _, player in ipairs(players:GetPlayers()) do
        player.CharacterAdded:Connect(function() self:RefreshCache() end)
        player.CharacterRemoving:Connect(function() self:RefreshCache() end)
    end
end

function WallChecker:RefreshCache()
    self.EnemyCache = {}
    self._lastUpdate = 0
end

-- ============================================================
-- TEAM CHECKER AVANZADO (universal)
-- ============================================================
function WallChecker:_ResetTeamCache()
    self._teamSystemDetected = nil
    self._teamCache = {}
    self._neutralCache = {}
    self._enemyCache = {}
end

function WallChecker:_GetTeamIdentifier(player)
    if not player then return nil end
    if self._teamCache[player] ~= nil then return self._teamCache[player] end

    local mode = self._settings.TeamCheckMode
    if mode == "Disabled" then
        self._teamCache[player] = nil
        return nil
    end

    local result = nil

    -- 1. Player.Team (sistema oficial de Roblox)
    if mode == "Roblox" or mode == "Auto" or mode == "Custom" then
        if player.Team then
            result = tostring(player.Team)
            self._teamCache[player] = result
            return result
        end
    end

    -- 2. Player:GetAttribute (juegos modernos)
    if mode == "Auto" or mode == "Custom" then
        local attributeNames = {"Team", "TeamID", "Faction", "Role", "Group", "Side", "Class", "Job"}
        for _, attrName in ipairs(attributeNames) do
            local value = player:GetAttribute(attrName)
            if value ~= nil then
                result = tostring(value)
                self._teamCache[player] = result
                return result
            end
        end
    end

    -- 3. Custom property (configurable)
    if mode == "Custom" and self._settings.CustomTeamProperty then
        local prop = player:FindFirstChild(self._settings.CustomTeamProperty)
        if prop then
            if prop:IsA("StringValue") or prop:IsA("NumberValue") or prop:IsA("BoolValue") then
                result = tostring(prop.Value)
            elseif prop:IsA("ObjectValue") then
                result = tostring(prop.Value)
            else
                result = tostring(prop)
            end
            self._teamCache[player] = result
            return result
        end
    end

    -- 4. Common properties
    if mode == "Auto" or mode == "Custom" then
        local commonProps = {"Team", "Faction", "Role", "Group", "Side", "Class", "Job", "TeamID"}
        for _, propName in ipairs(commonProps) do
            local prop = player:FindFirstChild(propName)
            if prop then
                if prop:IsA("StringValue") or prop:IsA("NumberValue") or prop:IsA("BoolValue") then
                    result = tostring(prop.Value)
                elseif prop:IsA("ObjectValue") then
                    result = tostring(prop.Value)
                else
                    result = tostring(prop)
                end
                self._teamCache[player] = result
                return result
            end
        end
    end

    -- 5. TeamColor (alternativa)
    if mode == "Auto" or mode == "Roblox" then
        if player.TeamColor then
            result = tostring(player.TeamColor)
            self._teamCache[player] = result
            return result
        end
    end

    -- 6. leaderstats (juegos antiguos)
    if mode == "Auto" then
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local teamStat = leaderstats:FindFirstChild("Team")
            if teamStat and teamStat:IsA("StringValue") then
                result = teamStat.Value
                self._teamCache[player] = result
                return result
            end
            local teamStatNum = leaderstats:FindFirstChild("TeamID")
            if teamStatNum and teamStatNum:IsA("NumberValue") then
                result = tostring(teamStatNum.Value)
                self._teamCache[player] = result
                return result
            end
        end
    end

    -- 7. Data folder
    if mode == "Auto" then
        local dataFolder = player:FindFirstChild("Data") or player:FindFirstChild("PlayerData")
        if dataFolder then
            local teamData = dataFolder:FindFirstChild("Team") or dataFolder:FindFirstChild("TeamID")
            if teamData and teamData:IsA("StringValue") then
                result = teamData.Value
                self._teamCache[player] = result
                return result
            end
        end
    end

    self._teamCache[player] = nil
    return nil
end

function WallChecker:_GetNeutralStatus(player)
    if not player then return false end
    if self._neutralCache[player] ~= nil then return self._neutralCache[player] end

    local isNeutral = false
    if player.Neutral ~= nil then
        isNeutral = (player.Neutral == true)
    else
        local neutralValue = player:FindFirstChild("Neutral")
        if neutralValue and neutralValue:IsA("BoolValue") then
            isNeutral = (neutralValue.Value == true)
        end
        if not isNeutral then
            local attr = player:GetAttribute("Neutral")
            if attr ~= nil then isNeutral = (attr == true) end
        end
    end

    self._neutralCache[player] = isNeutral
    return isNeutral
end

function WallChecker:_DetectTeamSystem()
    if self._teamSystemDetected ~= nil then return self._teamSystemDetected end

    local players = game:GetService("Players"):GetPlayers()
    if #players < 2 then
        self._teamSystemDetected = false
        return false
    end

    local mode = self._settings.TeamCheckMode
    if mode == "Disabled" then
        self._teamSystemDetected = false
        return false
    end

    local teamMap = {}
    local firstTeam = nil
    local allSame = true

    for _, player in ipairs(players) do
        local id = self:_GetTeamIdentifier(player)
        if id == nil then
            self._teamSystemDetected = false
            if self._settings.Debug then
                warn("[WallChecker] Jugador sin equipo detectado. Sistema de equipos desactivado.")
            end
            return false
        end
        teamMap[id] = (teamMap[id] or 0) + 1
        if firstTeam == nil then
            firstTeam = id
        elseif id ~= firstTeam then
            allSame = false
        end
    end

    -- Contar equipos reales (no usar #tabla)
    local teamCount = 0
    for _ in pairs(teamMap) do teamCount = teamCount + 1 end

    if allSame and teamCount == 1 then
        self._teamSystemDetected = false
        if self._settings.Debug then
            warn("[WallChecker] Todos los jugadores tienen el mismo equipo. Sistema de equipos desactivado.")
        end
        return false
    end

    if teamCount >= 2 then
        self._teamSystemDetected = true
        if self._settings.Debug then
            print("[WallChecker] Sistema de equipos detectado: " .. teamCount .. " equipos diferentes.")
        end
        return true
    end

    self._teamSystemDetected = false
    return false
end

function WallChecker:IsEnemy(player)
    if not player then return false end
    local localPlayer = game:GetService("Players").LocalPlayer
    if not localPlayer or player == localPlayer then return false end

    if self._enemyCache[player] ~= nil then return self._enemyCache[player] end

    if self._settings.TeamCheckMode == "Disabled" then
        self._enemyCache[player] = true
        return true
    end

    if self._settings.AllowNeutral then
        if self:_GetNeutralStatus(player) then
            self._enemyCache[player] = self._settings.NeutralIsEnemy
            return self._enemyCache[player]
        end
    end

    if not self:_DetectTeamSystem() then
        self._enemyCache[player] = true
        return true
    end

    if not self._settings.IgnoreSameTeam then
        self._enemyCache[player] = true
        return true
    end

    local localId = self:_GetTeamIdentifier(localPlayer)
    local targetId = self:_GetTeamIdentifier(player)

    if localId == nil or targetId == nil then
        self._enemyCache[player] = true
        return true
    end

    self._enemyCache[player] = (localId ~= targetId)
    return self._enemyCache[player]
end

-- ============================================================
-- PUNTOS ADAPTATIVOS (Head, Body, Limbs)
-- ============================================================
local PartOrder = {
    "Head",
    "UpperTorso",
    "Torso",
    "HumanoidRootPart",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperArm",  "LeftLowerArm",  "LeftHand",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
    "LeftUpperLeg",  "LeftLowerLeg",  "LeftFoot",
}

local function GetPartType(partName)
    if partName:find("Head") then return "Head" end
    if partName:find("Torso") or partName:find("RootPart") then return "Body" end
    if partName:find("Arm") or partName:find("Hand") then return "Limb" end
    if partName:find("Leg") or partName:find("Foot") then return "Limb" end
    return "Body"
end

local function GetPointCount(partType, mode)
    if mode == "fast" then
        if partType == "Head" then return 5 end
        if partType == "Body" then return 3 end
        return 1
    elseif mode == "high" then
        if partType == "Head" then return 13 end
        if partType == "Body" then return 9 end
        return 5
    else -- medium
        if partType == "Head" then return 9 end
        if partType == "Body" then return 5 end
        return 3
    end
end

local function GetPartPoints(part, settings)
    local size = part.Size / 2
    local cf = part.CFrame
    local partType = GetPartType(part.Name)
    local numPoints = GetPointCount(partType, settings.PointMode or "fast")

    local points = { cf * Vector3.new(0,0,0) } -- centro siempre incluido
    if numPoints == 1 then return points end

    local offsets = {}

    if partType == "Head" then
        local headOffsets = {
            Vector3.new(size.X, 0, 0), Vector3.new(-size.X, 0, 0),
            Vector3.new(0, size.Y, 0), Vector3.new(0, -size.Y, 0),
            Vector3.new(0, 0, size.Z), Vector3.new(0, 0, -size.Z),
            Vector3.new(size.X, size.Y, 0), Vector3.new(-size.X, size.Y, 0),
            Vector3.new(size.X, -size.Y, 0), Vector3.new(-size.X, -size.Y, 0),
            Vector3.new(0, size.Y, size.Z), Vector3.new(0, -size.Y, size.Z),
        }
        for i = 1, math.min(numPoints - 1, #headOffsets) do
            table.insert(offsets, headOffsets[i])
        end
    elseif partType == "Body" then
        local bodyOffsets = {
            Vector3.new(size.X, 0, 0), Vector3.new(-size.X, 0, 0),
            Vector3.new(0, size.Y, 0), Vector3.new(0, -size.Y, 0),
            Vector3.new(size.X, size.Y, 0), Vector3.new(-size.X, size.Y, 0),
            Vector3.new(size.X, -size.Y, 0), Vector3.new(-size.X, -size.Y, 0),
        }
        for i = 1, math.min(numPoints - 1, #bodyOffsets) do
            table.insert(offsets, bodyOffsets[i])
        end
    else -- Limbs
        local limbOffsets = {
            Vector3.new(0, size.Y * 0.7, 0), Vector3.new(0, -size.Y * 0.7, 0),
            Vector3.new(size.X * 0.7, 0, 0), Vector3.new(-size.X * 0.7, 0, 0),
        }
        for i = 1, math.min(numPoints - 1, #limbOffsets) do
            table.insert(offsets, limbOffsets[i])
        end
    end

    for _, offset in ipairs(offsets) do
        table.insert(points, cf * offset)
    end
    return points
end

-- ============================================================
-- CACHÉ DE PUNTOS
-- ============================================================
function WallChecker:_UpdatePointCache(part, character)
    if not part or not part:IsA("BasePart") or not character then return end
    if not self._pointCache[character] then self._pointCache[character] = {} end
    self._pointCache[character][part] = GetPartPoints(part, self._settings)
end

function WallChecker:_SetupPointCache(character)
    if not character or not character:IsA("Model") then return end
    if self._cacheConnections[character] then return end

    self._pointCache[character] = {}
    local connections = {}

    local function onPartChanged(part)
        self:_UpdatePointCache(part, character)
    end

    for _, partName in ipairs(PartOrder) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            self:_UpdatePointCache(part, character)
            local c1 = part:GetPropertyChangedSignal("Size"):Connect(function() onPartChanged(part) end)
            local c2 = part:GetPropertyChangedSignal("CFrame"):Connect(function() onPartChanged(part) end)
            table.insert(connections, c1)
            table.insert(connections, c2)
        end
    end

    local c3 = character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            self:_ClearPointCache(character)
        end
    end)
    table.insert(connections, c3)

    self._cacheConnections[character] = connections
end

function WallChecker:_ClearPointCache(character)
    if self._cacheConnections[character] then
        for _, conn in ipairs(self._cacheConnections[character]) do
            conn:Disconnect()
        end
        self._cacheConnections[character] = nil
    end
    self._pointCache[character] = nil
end

function WallChecker:ClearAllCache()
    for character, _ in pairs(self._pointCache) do
        self:_ClearPointCache(character)
    end
    self._pointCache = {}
    self.EnemyCache = {}
    self._lastUpdate = 0
end

-- ============================================================
-- RAYCAST POR CAPAS (con materiales suaves, accesorios, efectos)
-- ============================================================
local function CreateRaycastParams(ignoreList)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    params.FilterDescendantsInstances = ignoreList or {}
    return params
end

local function IsAccessory(instance)
    local parent = instance.Parent
    while parent do
        if parent:IsA("Accessory") then return true end
        if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then return false end
        parent = parent.Parent
    end
    return false
end

local function IsEffect(instance)
    local name = instance.Name:lower()
    return name:find("effect") or name:find("particle") or name:find("trail") or name:find("beam")
end

-- Raycast simple (sin capas) - usado en modo "fast"
local function SimpleRay(origin, target, character, params, settings)
    local direction = (target - origin)
    local distance = direction.Magnitude
    if distance < 0.001 then return true, {} end
    direction = direction.Unit

    local result = workspace:Raycast(origin, direction * distance, params)
    if not result then return true, {} end

    local hit = result.Instance
    if hit:IsDescendantOf(character) then return true, {} end

    if settings.IgnoreTransparent and hit:IsA("BasePart") and hit.Transparency >= settings.TransparencyLimit then
        return true, {}
    end
    if settings.IgnoreNonCollidable and hit:IsA("BasePart") and not hit.CanCollide then
        return true, {}
    end
    if hit:IsA("BasePart") and settings.SoftMaterials[hit.Material] then
        return true, {}
    end
    if settings.IgnoreAccessories and IsAccessory(hit) then
        return true, {}
    end
    if settings.IgnoreEffects and IsEffect(hit) then
        return true, {}
    end
    return false, { hit }
end

-- Raycast con capas (usado en modo "medium"/"high")
local function LayerRay(origin, target, character, params, settings)
    local current = origin
    local direction = (target - origin)
    local distance = direction.Magnitude
    if distance < 0.001 then return true, {} end
    direction = direction.Unit

    local layers = 0
    local blockers = {}
    local lastHit = nil

    while layers < settings.MaxLayers do
        local result = workspace:Raycast(current, direction * (target - current).Magnitude, params)
        if not result then
            return true, blockers
        end

        local hit = result.Instance
        if hit:IsDescendantOf(character) then
            return true, blockers
        end

        if settings.IgnoreTransparent and hit:IsA("BasePart") and hit.Transparency >= settings.TransparencyLimit then
            current = result.Position + direction * 0.1
            continue
        end

        if settings.IgnoreNonCollidable and hit:IsA("BasePart") and not hit.CanCollide then
            current = result.Position + direction * 0.1
            continue
        end

        if hit:IsA("BasePart") and settings.SoftMaterials[hit.Material] then
            current = result.Position + direction * 0.1
            continue
        end

        if settings.IgnoreAccessories and IsAccessory(hit) then
            current = result.Position + direction * 0.1
            continue
        end

        if settings.IgnoreEffects and IsEffect(hit) then
            current = result.Position + direction * 0.1
            continue
        end

        table.insert(blockers, hit)

        if lastHit == hit then
            current = result.Position + direction * 0.2
        else
            current = result.Position + result.Normal * 0.2
            lastHit = hit
        end
        layers = layers + 1
    end
    return false, blockers
end

-- ============================================================
-- FUNCIÓN PRINCIPAL: GetEnemyInfo
-- ============================================================
function WallChecker:GetEnemyInfo(origin, target, ignoreList)
    -- Obtener posición de origen
    local originPosition
    if typeof(origin) == "Vector3" then
        originPosition = origin
    elseif origin and origin:IsA("BasePart") then
        originPosition = origin.Position
    else
        return nil
    end

    if not target then return nil end

    -- Obtener character objetivo
    local targetCharacter
    if target:IsA("BasePart") then
        targetCharacter = target.Parent
        while targetCharacter and not targetCharacter:IsA("Model") do
            targetCharacter = targetCharacter.Parent
        end
        if not targetCharacter then return nil end
    elseif target:IsA("Model") then
        targetCharacter = target
    else
        return nil
    end

    local targetPlayer = game:GetService("Players"):GetPlayerFromCharacter(targetCharacter)
    if not targetPlayer or not self:IsEnemy(targetPlayer) then return nil end

    local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    if self._settings.IgnoreDead and humanoid.Health <= 0 then return nil end
    if self._settings.IgnoreForceField and targetCharacter:FindFirstChildOfClass("ForceField") then return nil end

    local settings = self._settings
    local targetPosition = targetCharacter:GetPivot().Position
    local distance = (targetPosition - originPosition).Magnitude

    if settings.MaxDistance and distance > settings.MaxDistance then return nil end

    -- FOV check
    if settings.VisionAngle and settings.VisionAngle > 0 and settings.VisionAngle < 360 then
        local camera = workspace.CurrentCamera
        if camera then
            local lookDirection = camera.CFrame.LookVector
            local toTarget = (targetPosition - originPosition).Unit
            local dot = lookDirection:Dot(toTarget)
            local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
            if angle > settings.VisionAngle / 2 then return nil end
        end
    end

    -- Preparar caché de puntos
    if not self._pointCache[targetCharacter] then
        self:_SetupPointCache(targetCharacter)
    end

    local raycastParams = CreateRaycastParams(ignoreList or {})
    local totalPoints = 0
    local visiblePoints = 0
    local bestPart = nil
    local bestScore = -1
    local blockersSet = {}
    local exposure = { Head = 0, Body = 0, Limbs = 0 }
    local countByType = { Head = 0, Body = 0, Limbs = 0 }
    local visibleByType = { Head = 0, Body = 0, Limbs = 0 }

    local useLayers = (settings.PointMode == "medium" or settings.PointMode == "high")
    local rayFunction = useLayers and LayerRay or SimpleRay

    for _, partName in ipairs(PartOrder) do
        local part = targetCharacter:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local points = self._pointCache[targetCharacter][part]
            if not points then
                self:_UpdatePointCache(part, targetCharacter)
                points = self._pointCache[targetCharacter][part] or GetPartPoints(part, settings)
            end
            local partType = GetPartType(partName)
            countByType[partType] = (countByType[partType] or 0) + #points

            local partVisibleCount = 0
            for i, point in ipairs(points) do
                totalPoints = totalPoints + 1
                local seen, blockers = rayFunction(
                    originPosition, point, targetCharacter,
                    raycastParams, settings
                )
                if seen then
                    visiblePoints = visiblePoints + 1
                    partVisibleCount = partVisibleCount + 1
                    visibleByType[partType] = (visibleByType[partType] or 0) + 1
                else
                    for _, blocker in ipairs(blockers) do
                        blockersSet[blocker] = true
                    end
                end
                if settings.EarlyExitOnCenter and i == 1 and seen then
                    visiblePoints = visiblePoints + (#points - 1)
                    partVisibleCount = partVisibleCount + (#points - 1)
                    visibleByType[partType] = (visibleByType[partType] or 0) + (#points - 1)
                    break
                end
            end

            local priority = settings.PartPriority[partName] or 1
            local score = (partVisibleCount / #points) * priority
            if score > bestScore then
                bestScore = score
                bestPart = part
            end
        end
    end

    -- Calcular exposiciones por tipo
    for partType, totalCount in pairs(countByType) do
        if totalCount > 0 then
            exposure[partType] = (visibleByType[partType] or 0) / totalCount
        end
    end

    local visibility = totalPoints > 0 and visiblePoints / totalPoints or 0
    local blockersList = {}
    for blocker, _ in pairs(blockersSet) do
        table.insert(blockersList, blocker)
    end

    local headVis = exposure.Head or 0
    local bodyVis = exposure.Body or 0
    local importantVisibility = math.max(headVis, bodyVis)
    local confidence = (visibility * 0.5) + (importantVisibility * 0.5)

    local isVisible = visibility >= settings.MinimumVisibility and
                      importantVisibility >= settings.MinimumImportantVisibility

    if not isVisible then return nil end

    -- Screen position
    local camera = workspace.CurrentCamera
    local screenPosition = Vector2.new(0, 0)
    local screenDistance = math.huge
    if camera then
        local position, onScreen = camera:WorldToScreenPoint(targetPosition)
        if onScreen then
            screenPosition = Vector2.new(position.X, position.Y)
            screenDistance = (screenPosition - camera.ViewportSize / 2).Magnitude
        end
    end

    -- Velocity
    local velocity = Vector3.new(0, 0, 0)
    local rootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    if rootPart then
        velocity = rootPart.AssemblyLinearVelocity
    end

    local aimParts = {
        Head = headVis > 0.3,
        Body = bodyVis > 0.3,
        Limbs = (exposure.Limbs or 0) > 0.2,
    }

    -- Crear objeto Enemy
    local enemy = setmetatable({
        Player = targetPlayer,
        Character = targetCharacter,
        Humanoid = humanoid,
        Visible = isVisible,
        VisiblePart = bestPart,
        Position = targetPosition,
        ScreenPosition = screenPosition,
        Velocity = velocity,
        Distance = distance,
        Health = humanoid.Health,
        Visibility = visibility,
        Confidence = confidence,
        Exposure = exposure,
        ScreenDistance = screenDistance,
        AimParts = aimParts,
        Blockers = blockersList,
        Score = 0,
    }, Enemy)

    return enemy
end

-- ============================================================
-- GET ALL ENEMIES & GET BEST ENEMY
-- ============================================================
function WallChecker:GetAllEnemies(origin, ignoreList)
    local currentTime = tick()
    if currentTime - self._lastUpdate < self._updateDelay then
        return self.EnemyCache
    end

    local originPosition
    if typeof(origin) == "Vector3" then
        originPosition = origin
    elseif origin and origin:IsA("BasePart") then
        originPosition = origin.Position
    else
        return {}
    end

    local enemies = {}
    local players = game:GetService("Players"):GetPlayers()
    local localPlayer = game:GetService("Players").LocalPlayer

    for _, player in ipairs(players) do
        if player == localPlayer then continue end
        local enemyInfo = self:GetEnemyInfo(originPosition, player.Character, ignoreList)
        if enemyInfo then
            local score = (enemyInfo.Visibility * 300) +
                          (enemyInfo.Confidence * 300) -
                          (enemyInfo.Distance * 0.3) -
                          (enemyInfo.ScreenDistance * 0.2)
            enemyInfo.Score = score
            table.insert(enemies, enemyInfo)
        end
    end

    self.EnemyCache = enemies
    self._lastUpdate = currentTime
    return enemies
end

function WallChecker:GetBestEnemy(origin, ignoreList)
    local enemies = self:GetAllEnemies(origin, ignoreList)
    if #enemies == 0 then return nil end

    local best = nil
    local bestScore = -math.huge
    for _, enemy in ipairs(enemies) do
        if enemy.Score > bestScore then
            bestScore = enemy.Score
            best = enemy
        end
    end
    return best
end

-- ============================================================
-- DEPURACIÓN VISUAL
-- ============================================================
if WallChecker.DefaultSettings.Debug then
    local function DebugPoint(position, color)
        local part = Instance.new("Part")
        part.Size = Vector3.new(0.15, 0.15, 0.15)
        part.Position = position
        part.Anchored = true
        part.CanCollide = false
        part.Material = Enum.Material.Neon
        part.Color = color
        part.Parent = workspace
        task.delay(WallChecker.DefaultSettings.DebugDuration or 0.5, function()
            part:Destroy()
        end)
    end

    local oldGetEnemyInfo = WallChecker.GetEnemyInfo
    WallChecker.GetEnemyInfo = function(self, ...)
        local result = oldGetEnemyInfo(self, ...)
        if result and result.VisiblePart then
            local points = self._pointCache[result.Character] and self._pointCache[result.Character][result.VisiblePart] or {}
            for _, point in ipairs(points) do
                DebugPoint(point, Color3.fromRGB(0, 255, 0))
            end
        end
        return result
    end
end

return WallChecker
