--[=[
    WallChecker Pro v3.3
    Motor de percepción puro para Aimbot/ESP.
    
    RETORNA para cada enemigo:
    {
        Player = player,
        Character = character,
        Humanoid = humanoid,
        Visible = true/false,
        VisiblePart = BasePart,
        Position = Vector3,
        ScreenPosition = Vector2,
        Velocity = Vector3,
        Distance = number,
        Health = number,
        Visibility = number (0-1),
        Confidence = number (0-1),
        Exposure = { Head = 0-1, Body = 0-1 },
        ScreenDistance = number (distancia al centro de la pantalla),
        AimParts = { Head = true/false, Body = true/false },
    }
]=]

local WallCheck = {}

-- ===== CONFIGURACIÓN =====
WallCheck.Settings = {
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
    PointMode = "fast",

    PartPriority = {
        Head = 10,
        UpperTorso = 7,
        LowerTorso = 6,
        HumanoidRootPart = 5,
    },

    VisionAngle = 120,

    TeamCheckMode = "Auto",
    CustomTeamProperty = nil,
    IgnoreSameTeam = true,
    AllowNeutral = true,
    NeutralIsEnemy = true,
    DebugTeam = false,

    IgnoreDead = true,
    IgnoreForceField = true,
    Debug = false,
    DebugDuration = 0.5,
}

-- ===== TEAM CHECKER =====
local TeamChecker = {
    _systemDetected = nil,
    _teamCache = {},
    _neutralCache = {},
}

local enemyCache = {}

local TeamAttrNames = {
    "Team", "TeamID", "Faction", "Role", "Group", "Side", "Class", "Job"
}
local CommonPropNames = {
    "Team", "Faction", "Role", "Group", "Side", "Class", "Job", "TeamID"
}

local function ResetTeamCache()
    TeamChecker._systemDetected = nil
    TeamChecker._teamCache = {}
    TeamChecker._neutralCache = {}
    enemyCache = {}
end

local function ClearPlayerCache(player)
    if not player then return end
    TeamChecker._teamCache[player] = nil
    TeamChecker._neutralCache[player] = nil
    enemyCache[player] = nil
end

local function ResolveTeamIdentifier(player)
    if not player then return nil end
    local mode = WallCheck.Settings.TeamCheckMode
    if mode == "Disabled" then return nil end

    local result

    if mode == "Roblox" or mode == "Auto" or mode == "Custom" then
        if player.Team then return tostring(player.Team) end
    end

    if mode == "Auto" or mode == "Custom" then
        for _, attr in ipairs(TeamAttrNames) do
            local val = player:GetAttribute(attr)
            if val ~= nil then return tostring(val) end
        end
    end

    if mode == "Custom" and WallCheck.Settings.CustomTeamProperty then
        local prop = player:FindFirstChild(WallCheck.Settings.CustomTeamProperty)
        if prop then
            if prop:IsA("StringValue") or prop:IsA("NumberValue") or prop:IsA("BoolValue") then
                return tostring(prop.Value)
            elseif prop:IsA("ObjectValue") then
                return tostring(prop.Value)
            else
                return tostring(prop)
            end
        end
    end

    if mode == "Auto" or mode == "Custom" then
        for _, propName in ipairs(CommonPropNames) do
            local prop = player:FindFirstChild(propName)
            if prop then
                if prop:IsA("StringValue") or prop:IsA("NumberValue") or prop:IsA("BoolValue") then
                    return tostring(prop.Value)
                elseif prop:IsA("ObjectValue") then
                    return tostring(prop.Value)
                else
                    return tostring(prop)
                end
            end
        end
    end

    if mode == "Auto" or mode == "Roblox" then
        if player.TeamColor then return tostring(player.TeamColor) end
    end

    if mode == "Auto" then
        local ls = player:FindFirstChild("leaderstats")
        if ls then
            local teamStat = ls:FindFirstChild("Team")
            if teamStat and teamStat:IsA("StringValue") then return teamStat.Value end
            local teamStatNum = ls:FindFirstChild("TeamID")
            if teamStatNum and teamStatNum:IsA("NumberValue") then return tostring(teamStatNum.Value) end
        end
    end

    if mode == "Auto" then
        local data = player:FindFirstChild("Data") or player:FindFirstChild("PlayerData")
        if data then
            local teamData = data:FindFirstChild("Team") or data:FindFirstChild("TeamID")
            if teamData and teamData:IsA("StringValue") then return teamData.Value end
        end
    end

    return nil
end

local function GetTeamIdentifier(player)
    if not player then return nil end
    if TeamChecker._teamCache[player] ~= nil then
        return TeamChecker._teamCache[player]
    end
    local id = ResolveTeamIdentifier(player)
    TeamChecker._teamCache[player] = id
    return id
end

local function GetNeutralStatus(player)
    if not player then return false end
    if TeamChecker._neutralCache[player] ~= nil then
        return TeamChecker._neutralCache[player]
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
    TeamChecker._neutralCache[player] = neutral
    return neutral
end

local function DetectTeamSystem()
    if TeamChecker._systemDetected ~= nil then
        return TeamChecker._systemDetected
    end

    local players = game:GetService("Players"):GetPlayers()
    if #players < 2 then
        TeamChecker._systemDetected = false
        return false
    end

    local mode = WallCheck.Settings.TeamCheckMode
    if mode == "Disabled" then
        TeamChecker._systemDetected = false
        return false
    end

    local teamMap = {}
    local firstTeam = nil
    local allSame = true

    for _, plr in ipairs(players) do
        local id = GetTeamIdentifier(plr)
        if id == nil then
            TeamChecker._systemDetected = false
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
        TeamChecker._systemDetected = false
        return false
    end

    if teamCount >= 2 then
        TeamChecker._systemDetected = true
        return true
    end

    TeamChecker._systemDetected = false
    return false
end

local function IsEnemy(player)
    if not player then return false end
    local lp = game:GetService("Players").LocalPlayer
    if not lp or player == lp then return false end

    if enemyCache[player] ~= nil then
        return enemyCache[player]
    end

    if WallCheck.Settings.TeamCheckMode == "Disabled" then
        enemyCache[player] = true
        return true
    end

    if WallCheck.Settings.AllowNeutral then
        if GetNeutralStatus(player) then
            enemyCache[player] = WallCheck.Settings.NeutralIsEnemy
            return enemyCache[player]
        end
    end

    if not DetectTeamSystem() then
        enemyCache[player] = true
        return true
    end

    if not WallCheck.Settings.IgnoreSameTeam then
        enemyCache[player] = true
        return true
    end

    local localId = GetTeamIdentifier(lp)
    local targetId = GetTeamIdentifier(player)

    if localId == nil or targetId == nil then
        enemyCache[player] = true
        return true
    end

    enemyCache[player] = (localId ~= targetId)
    return enemyCache[player]
end

-- ===== EVENTOS DINÁMICOS =====
local function SetupTeamEvents()
    local players = game:GetService("Players")
    players.PlayerAdded:Connect(function(plr)
        ResetTeamCache()
        plr:GetPropertyChangedSignal("Team"):Connect(ResetTeamCache)
        plr:GetPropertyChangedSignal("TeamColor"):Connect(ResetTeamCache)
        for _, attr in ipairs(TeamAttrNames) do
            plr:GetAttributeChangedSignal(attr):Connect(ResetTeamCache)
        end
        plr.ChildAdded:Connect(function(child)
            for _, name in ipairs(CommonPropNames) do
                if child.Name == name then ResetTeamCache() break end
            end
            if child.Name == "leaderstats" then child.ChildAdded:Connect(ResetTeamCache) end
            if child.Name == "Data" or child.Name == "PlayerData" then child.ChildAdded:Connect(ResetTeamCache) end
        end)
    end)
    players.PlayerRemoving:Connect(function(plr)
        ClearPlayerCache(plr)
        ResetTeamCache()
    end)
    for _, plr in ipairs(players:GetPlayers()) do
        plr:GetPropertyChangedSignal("Team"):Connect(ResetTeamCache)
        plr:GetPropertyChangedSignal("TeamColor"):Connect(ResetTeamCache)
        for _, attr in ipairs(TeamAttrNames) do
            plr:GetAttributeChangedSignal(attr):Connect(ResetTeamCache)
        end
    end
end
task.spawn(SetupTeamEvents)

-- ===== FUNCIONES PÚBLICAS TEAM =====
function WallCheck:RefreshTeamSystem()
    ResetTeamCache()
    DetectTeamSystem()
end

function WallCheck:IsEnemy(player)
    return IsEnemy(player)
end

-- ===== VISIBILIDAD (código optimizado) =====
local PartOrder = {
    "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"
}
local PointCache = {}
local CacheConnections = {}

local function GetPartType(name)
    return name:find("Head") and "Head" or "Body"
end

local function GetPointCount(partType, mode)
    if mode == "fast" then return partType == "Head" and 5 or 3 end
    if mode == "high" then return partType == "Head" and 13 or 9 end
    return partType == "Head" and 9 or 5
end

local function GetPartPoints(part)
    local size = part.Size / 2
    local cf = part.CFrame
    local pType = GetPartType(part.Name)
    local num = GetPointCount(pType, WallCheck.Settings.PointMode)
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
        for i = 1, math.min(num - 1, #headOffsets) do table.insert(offsets, headOffsets[i]) end
    else
        local bodyOffsets = {
            Vector3.new(size.X,0,0), Vector3.new(-size.X,0,0),
            Vector3.new(0,size.Y,0), Vector3.new(0,-size.Y,0),
            Vector3.new(size.X,size.Y,0), Vector3.new(-size.X,size.Y,0),
            Vector3.new(size.X,-size.Y,0), Vector3.new(-size.X,-size.Y,0),
        }
        for i = 1, math.min(num - 1, #bodyOffsets) do table.insert(offsets, bodyOffsets[i]) end
    end
    for _, off in ipairs(offsets) do table.insert(pts, cf * off) end
    return pts
end

local function UpdateCache(part, char)
    if not part or not part:IsA("BasePart") or not char then return end
    if not PointCache[char] then PointCache[char] = {} end
    PointCache[char][part] = GetPartPoints(part)
end

local function SetupCache(char)
    if not char or not char:IsA("Model") then return end
    if CacheConnections[char] then return end
    PointCache[char] = {}
    local conns = {}
    for _, name in ipairs(PartOrder) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            UpdateCache(part, char)
            table.insert(conns, part:GetPropertyChangedSignal("Size"):Connect(function() UpdateCache(part, char) end))
            table.insert(conns, part:GetPropertyChangedSignal("CFrame"):Connect(function() UpdateCache(part, char) end))
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

function WallCheck:ClearAllCache()
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
    local layers, blockers, last = 0, {}, nil
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
        current = result.Position + (last == hit and dir or result.Normal) * 0.2
        last = hit
        layers = layers + 1
    end
    return false, blockers
end

-- ===== FUNCIÓN PRINCIPAL: GetEnemyInfo =====
function WallCheck:GetEnemyInfo(origin, target, ignore)
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
    if not targetPlayer or not IsEnemy(targetPlayer) then return nil end

    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    if WallCheck.Settings.IgnoreDead and hum.Health <= 0 then return nil end
    if WallCheck.Settings.IgnoreForceField and targetChar:FindFirstChildOfClass("ForceField") then return nil end

    local settings = WallCheck.Settings
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

    -- Cache setup
    if not PointCache[targetChar] then SetupCache(targetChar) end

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
                UpdateCache(part, targetChar)
                points = PointCache[targetChar][part] or GetPartPoints(part)
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

    -- AimParts: qué partes son viables para apuntar
    local aimParts = {
        Head = headVis > 0.3,
        Body = bodyVis > 0.3,
    }

    return {
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
    }
end

-- ===== GET ALL ENEMIES =====
function WallCheck:GetAllEnemies(origin, ignore)
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
        local info = WallCheck:GetEnemyInfo(originPos, plr.Character, ignore)
        if info then table.insert(enemies, info) end
    end
    return enemies
end

-- ===== GET BEST ENEMY =====
function WallCheck:GetBestEnemy(origin, ignore)
    local enemies = WallCheck:GetAllEnemies(origin, ignore)
    if #enemies == 0 then return nil end

    local best = nil
    local bestScore = -math.huge

    for _, enemy in ipairs(enemies) do
        local score = (enemy.Visibility * 300) +
                      (enemy.Confidence * 300) -
                      (enemy.Distance * 0.3) -
                      (enemy.ScreenDistance * 0.2)
        if score > bestScore then
            bestScore = score
            best = enemy
        end
    end
    return best
end

-- ===== EXPOSICIÓN GLOBAL =====
_G.WallCheck = WallCheck
return WallCheck
