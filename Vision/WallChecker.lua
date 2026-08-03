--[=[
    XLORENs - WallChecker v3.5
    Motor de percepción puro con API orientada a objetos.
    Incluye: raycast por capas, puntos adaptativos, caché, team check, etc.
]=]

local WallChecker = {}
WallChecker.__index = WallChecker

-- ===== CONFIGURACIÓN =====
WallChecker.Settings = {
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
    for _, name in ipairs({"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"}) do
        local part = self.Character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            local visible = false
            if name == "Head" and self.AimParts.Head then visible = true end
            if name ~= "Head" and self.AimParts.Body then visible = true end
            if visible then
                table.insert(candidates, { Part = part, Priority = priority[name] or 10 })
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
function WallChecker:Init(framework)
    self._framework = framework
    self.EnemyCache = {}
    self._lastUpdate = 0
    self._updateDelay = 0.15

    -- Team Checker internals
    self._teamSystemDetected = nil
    self._teamCache = {}
    self._neutralCache = {}
    self._enemyCache = {}

    -- Eventos para caché automática
    local players = game:GetService("Players")
    players.PlayerAdded:Connect(function() self:RefreshCache() end)
    players.PlayerRemoving:Connect(function() self:RefreshCache() end)
    for _, plr in ipairs(players:GetPlayers()) do
        plr.CharacterAdded:Connect(function() self:RefreshCache() end)
        plr.CharacterRemoving:Connect(function() self:RefreshCache() end)
    end

    -- Timer para Team Checker (optimización)
    task.spawn(function()
        while task.wait(5) do
            self:_ResetTeamCache()
        end
    end)

    return self
end

function WallChecker:RefreshCache()
    self.EnemyCache = {}
    self._lastUpdate = 0
end

-- ===== TEAM CHECKER =====
function WallChecker:_ResetTeamCache()
    self._teamSystemDetected = nil
    self._teamCache = {}
    self._neutralCache = {}
    self._enemyCache = {}
end

function WallChecker:_GetTeamIdentifier(player)
    if not player then return nil end
    if self._teamCache[player] ~= nil then
        return self._teamCache[player]
    end
    local mode = self.Settings.TeamCheckMode
    if mode == "Disabled" then
        self._teamCache[player] = nil
        return nil
    end

    local result = nil
    -- 1. Player.Team
    if mode == "Roblox" or mode == "Auto" or mode == "Custom" then
        if player.Team then
            result = tostring(player.Team)
            self._teamCache[player] = result
            return result
        end
    end

    -- 2. Attributes
    if mode == "Auto" or mode == "Custom" then
        local attrNames = {"Team", "TeamID", "Faction", "Role", "Group", "Side", "Class", "Job"}
        for _, attr in ipairs(attrNames) do
            local val = player:GetAttribute(attr)
            if val ~= nil then
                result = tostring(val)
                self._teamCache[player] = result
                return result
            end
        end
    end

    -- 3. Custom property
    if mode == "Custom" and self.Settings.CustomTeamProperty then
        local prop = player:FindFirstChild(self.Settings.CustomTeamProperty)
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
        local propNames = {"Team", "Faction", "Role", "Group", "Side", "Class", "Job", "TeamID"}
        for _, propName in ipairs(propNames) do
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

    -- 5. TeamColor
    if mode == "Auto" or mode == "Roblox" then
        if player.TeamColor then
            result = tostring(player.TeamColor)
            self._teamCache[player] = result
            return result
        end
    end

    -- 6. leaderstats
    if mode == "Auto" then
        local ls = player:FindFirstChild("leaderstats")
        if ls then
            local teamStat = ls:FindFirstChild("Team")
            if teamStat and teamStat:IsA("StringValue") then
                result = teamStat.Value
                self._teamCache[player] = result
                return result
            end
            local teamStatNum = ls:FindFirstChild("TeamID")
            if teamStatNum and teamStatNum:IsA("NumberValue") then
                result = tostring(teamStatNum.Value)
                self._teamCache[player] = result
                return result
            end
        end
    end

    -- 7. Data folder
    if mode == "Auto" then
        local data = player:FindFirstChild("Data") or player:FindFirstChild("PlayerData")
        if data then
            local teamData = data:FindFirstChild("Team") or data:FindFirstChild("TeamID")
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
    if self._neutralCache[player] ~= nil then
        return self._neutralCache[player]
    end
    local neutral = false
    if player.Neutral ~= nil then
        neutral = (player.Neutral == true)
    else
        local nv = player:FindFirstChild("Neutral")
        if nv and nv:IsA("BoolValue") then
            neutral = (nv.Value == true)
        end
        if not neutral then
            local attr = player:GetAttribute("Neutral")
            if attr ~= nil then neutral = (attr == true) end
        end
    end
    self._neutralCache[player] = neutral
    return neutral
end

function WallChecker:_DetectTeamSystem()
    if self._teamSystemDetected ~= nil then
        return self._teamSystemDetected
    end

    local players = game:GetService("Players"):GetPlayers()
    if #players < 2 then
        self._teamSystemDetected = false
        return false
    end

    local mode = self.Settings.TeamCheckMode
    if mode == "Disabled" then
        self._teamSystemDetected = false
        return false
    end

    local teamMap = {}
    local firstTeam = nil
    local allSame = true

    for _, plr in ipairs(players) do
        local id = self:_GetTeamIdentifier(plr)
        if id == nil then
            self._teamSystemDetected = false
            return false
        end
        teamMap[id] = (teamMap[id] or 0) + 1
        if firstTeam == nil then
            firstTeam = id
        elseif id ~= firstTeam then
            allSame = false
        end
    end

    local teamCount = 0
    for _ in pairs(teamMap) do teamCount = teamCount + 1 end

    if allSame and teamCount == 1 then
        self._teamSystemDetected = false
        return false
    end

    if teamCount >= 2 then
        self._teamSystemDetected = true
        return true
    end

    self._teamSystemDetected = false
    return false
end

function WallChecker:IsEnemy(player)
    if not player then return false end
    local lp = game:GetService("Players").LocalPlayer
    if not lp or player == lp then return false end

    if self._enemyCache[player] ~= nil then
        return self._enemyCache[player]
    end

    if self.Settings.TeamCheckMode == "Disabled" then
        self._enemyCache[player] = true
        return true
    end

    if self.Settings.AllowNeutral then
        if self:_GetNeutralStatus(player) then
            self._enemyCache[player] = self.Settings.NeutralIsEnemy
            return self._enemyCache[player]
        end
    end

    if not self:_DetectTeamSystem() then
        self._enemyCache[player] = true
        return true
    end

    if not self.Settings.IgnoreSameTeam then
        self._enemyCache[player] = true
        return true
    end

    local localId = self:_GetTeamIdentifier(lp)
    local targetId = self:_GetTeamIdentifier(player)

    if localId == nil or targetId == nil then
        self._enemyCache[player] = true
        return true
    end

    self._enemyCache[player] = (localId ~= targetId)
    return self._enemyCache[player]
end

-- ===== RAYCAST Y VISIBILIDAD =====
local PartOrder = {
    "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"
}
local PointCache = {}
local CacheConnections = {}

local function GetPartType(name)
    return name:find("Head") and "Head" or "Body"
end

local function GetPointCount(partType, mode)
    if mode == "fast" then
        return partType == "Head" and 5 or 3
    elseif mode == "high" then
        return partType == "Head" and 13 or 9
    end
    return partType == "Head" and 9 or 5
end

local function GetPartPoints(part, settings)
    local size = part.Size / 2
    local cf = part.CFrame
    local pType = GetPartType(part.Name)
    local num = GetPointCount(pType, settings.PointMode or "fast")
    local pts = { cf * Vector3.new(0,0,0) }
    if num == 1 then return pts end

    local offsets = {}
    if pType == "Head" then
        local headOffsets = {
            Vector3.new(size.X,0,0), Vector3.new(-size.X,0,0),
            Vector3.new(0,size.Y,0), Vector3.new(0,-size.Y,0),
            Vector3.new(0,0,size.Z), Vector3.new(0,0,-size.Z),
            Vector3.new(size.X,size.Y,0), Vector3.new(-size.X,size.Y,0),
            Vector3.new(size.X,-size.Y,0), Vector3.new(-size.X,-size.Y,0),
            Vector3.new(0,size.Y,size.Z), Vector3.new(0,-size.Y,size.Z),
        }
        for i = 1, math.min(num - 1, #headOffsets) do
            table.insert(offsets, headOffsets[i])
        end
    else
        local bodyOffsets = {
            Vector3.new(size.X,0,0), Vector3.new(-size.X,0,0),
            Vector3.new(0,size.Y,0), Vector3.new(0,-size.Y,0),
            Vector3.new(size.X,size.Y,0), Vector3.new(-size.X,size.Y,0),
            Vector3.new(size.X,-size.Y,0), Vector3.new(-size.X,-size.Y,0),
        }
        for i = 1, math.min(num - 1, #bodyOffsets) do
            table.insert(offsets, bodyOffsets[i])
        end
    end
    for _, off in ipairs(offsets) do
        table.insert(pts, cf * off)
    end
    return pts
end

local function UpdateCache(part, char, settings)
    if not part or not part:IsA("BasePart") or not char then return end
    if not PointCache[char] then PointCache[char] = {} end
    PointCache[char][part] = GetPartPoints(part, settings)
end

local function SetupCache(char, settings)
    if not char or not char:IsA("Model") then return end
    if CacheConnections[char] then return end
    PointCache[char] = {}
    local conns = {}
    for _, name in ipairs(PartOrder) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            UpdateCache(part, char, settings)
            table.insert(conns, part:GetPropertyChangedSignal("Size"):Connect(function() UpdateCache(part, char, settings) end))
            table.insert(conns, part:GetPropertyChangedSignal("CFrame"):Connect(function() UpdateCache(part, char, settings) end))
        end
    end
    table.insert(conns, char.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if CacheConnections[char] then
                for _, c in ipairs(CacheConnections[char]) do c:Disconnect() end
                CacheConnections[char] = nil
            end
            PointCache[char] = nil
        end
    end))
    CacheConnections[char] = conns
end

function WallChecker:ClearAllCache()
    for char, _ in pairs(PointCache) do
        if CacheConnections[char] then
            for _, c in ipairs(CacheConnections[char]) do c:Disconnect() end
            CacheConnections[char] = nil
        end
        PointCache[char] = nil
    end
    PointCache = {}
end

local function CreateParams(ignore)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.IgnoreWater = true
    p.FilterDescendantsInstances = ignore or {}
    return p
end

local function IsAccessory(inst)
    local parent = inst.Parent
    while parent do
        if parent:IsA("Accessory") then return true end
        if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then return false end
        parent = parent.Parent
    end
    return false
end

local function IsEffect(inst)
    local name = inst.Name:lower()
    return name:find("effect") or name:find("particle") or name:find("trail") or name:find("beam")
end

local function SimpleRay(origin, target, char, params, settings)
    local dir = (target - origin)
    local dist = dir.Magnitude
    if dist < 0.001 then return true, {} end
    dir = dir.Unit
    local result = workspace:Raycast(origin, dir * dist, params)
    if not result then return true, {} end
    local hit = result.Instance
    if hit:IsDescendantOf(char) then return true, {} end
    if settings.IgnoreTransparent and hit:IsA("BasePart") and hit.Transparency >= settings.TransparencyLimit then return true, {} end
    if settings.IgnoreNonCollidable and hit:IsA("BasePart") and not hit.CanCollide then return true, {} end
    if hit:IsA("BasePart") and settings.SoftMaterials[hit.Material] then return true, {} end
    if settings.IgnoreAccessories and IsAccessory(hit) then return true, {} end
    if settings.IgnoreEffects and IsEffect(hit) then return true, {} end
    return false, { hit }
end

local function LayerRay(origin, target, char, params, settings)
    local current = origin
    local dir = (target - origin)
    local dist = dir.Magnitude
    if dist < 0.001 then return true, {} end
    dir = dir.Unit
    local layers, blockers = 0, {}
    while layers < settings.MaxLayers do
        local result = workspace:Raycast(current, dir * (target - current).Magnitude, params)
        if not result then return true, blockers end
        local hit = result.Instance
        if hit:IsDescendantOf(char) then return true, blockers end
        if settings.IgnoreTransparent and hit:IsA("BasePart") and hit.Transparency >= settings.TransparencyLimit then
            current = result.Position + dir * 0.1
            continue
        end
        if settings.IgnoreNonCollidable and hit:IsA("BasePart") and not hit.CanCollide then
            current = result.Position + dir * 0.1
            continue
        end
        if hit:IsA("BasePart") and settings.SoftMaterials[hit.Material] then
            current = result.Position + dir * 0.1
            continue
        end
        if settings.IgnoreAccessories and IsAccessory(hit) then
            current = result.Position + dir * 0.1
            continue
        end
        if settings.IgnoreEffects and IsEffect(hit) then
            current = result.Position + dir * 0.1
            continue
        end
        table.insert(blockers, hit)
        current = result.Position + dir * 0.2
        layers = layers + 1
    end
    return false, blockers
end

-- ===== GET ENEMY INFO =====
function WallChecker:GetEnemyInfo(origin, target, ignore)
    local originPos
    if typeof(origin) == "Vector3" then
        originPos = origin
    elseif origin and origin:IsA("BasePart") then
        originPos = origin.Position
    else
        return nil
    end

    if not target then return nil end

    local targetChar
    if target:IsA("BasePart") then
        targetChar = target.Parent
        while targetChar and not targetChar:IsA("Model") do targetChar = targetChar.Parent end
        if not targetChar then return nil end
    elseif target:IsA("Model") then
        targetChar = target
    else return nil end

    local targetPlayer = game:GetService("Players"):GetPlayerFromCharacter(targetChar)
    if not targetPlayer or not self:IsEnemy(targetPlayer) then return nil end

    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    if self.Settings.IgnoreDead and hum.Health <= 0 then return nil end
    if self.Settings.IgnoreForceField and targetChar:FindFirstChildOfClass("ForceField") then return nil end

    local settings = self.Settings
    local targetPos = targetChar:GetPivot().Position
    local distance = (targetPos - originPos).Magnitude

    if settings.MaxDistance and distance > settings.MaxDistance then return nil end

    -- FOV check
    if settings.VisionAngle and settings.VisionAngle > 0 and settings.VisionAngle < 360 then
        local cam = workspace.CurrentCamera
        if cam then
            local dir = cam.CFrame.LookVector
            local to = (targetPos - originPos).Unit
            local dot = dir:Dot(to)
            local ang = math.deg(math.acos(math.clamp(dot, -1, 1)))
            if ang > settings.VisionAngle / 2 then return nil end
        end
    end

    if not PointCache[targetChar] then SetupCache(targetChar, settings) end

    local params = CreateParams(ignore or {})
    local total, visible = 0, 0
    local bestPart = nil
    local bestScore = -1
    local blockersSet = {}
    local exposure = { Head = 0, Body = 0 }
    local countByType = { Head = 0, Body = 0 }
    local visibleByType = { Head = 0, Body = 0 }

    local useLayers = (settings.PointMode == "medium" or settings.PointMode == "high")
    local rayFunc = useLayers and LayerRay or SimpleRay

    for _, name in ipairs(PartOrder) do
        local part = targetChar:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            local points = PointCache[targetChar][part]
            if not points then
                UpdateCache(part, targetChar, settings)
                points = PointCache[targetChar][part] or GetPartPoints(part, settings)
            end
            local pType = GetPartType(name)
            countByType[pType] = (countByType[pType] or 0) + #points

            local partVisible = 0
            for i, point in ipairs(points) do
                total = total + 1
                local seen, blockers = rayFunc(originPos, point, targetChar, params, settings)
                if seen then
                    visible = visible + 1
                    partVisible = partVisible + 1
                    visibleByType[pType] = (visibleByType[pType] or 0) + 1
                else
                    for _, b in ipairs(blockers) do blockersSet[b] = true end
                end
                if settings.EarlyExitOnCenter and i == 1 and seen then
                    visible = visible + (#points - 1)
                    partVisible = partVisible + (#points - 1)
                    visibleByType[pType] = (visibleByType[pType] or 0) + (#points - 1)
                    break
                end
            end

            local priority = settings.PartPriority[name] or 1
            local score = (partVisible / #points) * priority
            if score > bestScore then
                bestScore = score
                bestPart = part
            end
        end
    end

    for typ, totalCount in pairs(countByType) do
        if totalCount > 0 then exposure[typ] = (visibleByType[typ] or 0) / totalCount end
    end

    local percent = total > 0 and visible / total or 0
    local headVis = exposure.Head or 0
    local bodyVis = exposure.Body or 0
    local importantVis = math.max(headVis, bodyVis)
    local confidence = (percent * 0.5) + (importantVis * 0.5)

    local visibleFlag = percent >= settings.MinimumVisibility and
                        importantVis >= settings.MinimumImportantVisibility

    if not visibleFlag then return nil end

    -- Screen position
    local cam = workspace.CurrentCamera
    local screenPos = Vector2.new(0, 0)
    local screenDist = math.huge
    if cam then
        local pos, onScreen = cam:WorldToScreenPoint(targetPos)
        if onScreen then
            screenPos = Vector2.new(pos.X, pos.Y)
            screenDist = (screenPos - cam.ViewportSize / 2).Magnitude
        end
    end

    -- Velocity
    local velocity = Vector3.new(0, 0, 0)
    local root = targetChar:FindFirstChild("HumanoidRootPart")
    if root then
        velocity = root.AssemblyLinearVelocity
    end

    local aimParts = {
        Head = headVis > 0.3,
        Body = bodyVis > 0.3,
    }

    -- Crear objeto Enemy
    local enemy = setmetatable({
        Player = targetPlayer,
        Character = targetChar,
        Humanoid = hum,
        Visible = visibleFlag,
        VisiblePart = bestPart,
        Position = targetPos,
        ScreenPosition = screenPos,
        Velocity = velocity,
        Distance = distance,
        Health = hum.Health,
        Visibility = percent,
        Confidence = confidence,
        Exposure = exposure,
        ScreenDistance = screenDist,
        AimParts = aimParts,
        Blockers = blockersSet,
        Score = 0,
    }, Enemy)

    return enemy
end

-- ===== GET ALL ENEMIES =====
function WallChecker:GetAllEnemies(origin, ignore)
    local now = tick()
    if now - self._lastUpdate < self._updateDelay then
        return self.EnemyCache
    end

    local originPos
    if typeof(origin) == "Vector3" then
        originPos = origin
    elseif origin and origin:IsA("BasePart") then
        originPos = origin.Position
    else
        return {}
    end

    local enemies = {}
    local players = game:GetService("Players"):GetPlayers()
    for _, plr in ipairs(players) do
        local info = self:GetEnemyInfo(originPos, plr.Character, ignore)
        if info then
            local score = (info.Visibility * 300) + (info.Confidence * 300) -
                          (info.Distance * 0.3) - (info.ScreenDistance * 0.2)
            info.Score = score
            table.insert(enemies, info)
        end
    end

    self.EnemyCache = enemies
    self._lastUpdate = now
    return enemies
end

-- ===== GET BEST ENEMY =====
function WallChecker:GetBestEnemy(origin, ignore)
    local enemies = self:GetAllEnemies(origin, ignore)
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

-- ===== DEPURACIÓN =====
if WallChecker.Settings.Debug then
    local function DebugPoint(pos, color)
        local p = Instance.new("Part")
        p.Size = Vector3.new(0.15, 0.15, 0.15)
        p.Position = pos
        p.Anchored = true
        p.CanCollide = false
        p.Material = Enum.Material.Neon
        p.Color = color
        p.Parent = workspace
        task.delay(WallChecker.Settings.DebugDuration or 0.5, function() p:Destroy() end)
    end
    local oldGetEnemyInfo = WallChecker.GetEnemyInfo
    WallChecker.GetEnemyInfo = function(self, ...)
        local result = oldGetEnemyInfo(self, ...)
        if result and result.VisiblePart then
            local pts = PointCache[result.Character] and PointCache[result.Character][result.VisiblePart] or {}
            for _, pt in ipairs(pts) do
                DebugPoint(pt, Color3.fromRGB(0,255,0))
            end
        end
        return result
    end
end

return WallChecker
