--[=[
    XLORENs - TargetManager
    Selección, lock y validación de objetivos.
]=]

local TargetManager = {}
TargetManager.__index = TargetManager

function TargetManager:Init(framework)
    self._framework = framework
    self.WallChecker = framework.WallChecker
    self.CurrentTarget = nil
    self.TargetSwitchTime = 0
    self.Settings = {
        FOV = 150,
        LockTime = 0.35,
        ValidationDelay = 0.15,
    }
    return self
end

function TargetManager:GetTarget(origin, settings)
    settings = settings or self.Settings
    local originPos
    if typeof(origin) == "Vector3" then
        originPos = origin
    elseif origin and origin:IsA("BasePart") then
        originPos = origin.Position
    else
        return nil
    end

    local allEnemies = self.WallChecker:GetAllEnemies(originPos)
    local enemiesInFOV = {}
    for _, e in ipairs(allEnemies) do
        if e.ScreenDistance <= settings.FOV then
            table.insert(enemiesInFOV, e)
        end
    end

    local bestEnemy = nil
    local bestScore = -math.huge
    for _, e in ipairs(enemiesInFOV) do
        if e.Score > bestScore then
            bestScore = e.Score
            bestEnemy = e
        end
    end

    if not bestEnemy then
        for _, e in ipairs(allEnemies) do
            if e.Score > bestScore then
                bestScore = e.Score
                bestEnemy = e
            end
        end
    end

    if not bestEnemy then
        self.CurrentTarget = nil
        self.TargetSwitchTime = 0
        return nil
    end

    local now = tick()
    if self.CurrentTarget then
        local stillValid = false
        for _, e in ipairs(enemiesInFOV) do
            if e.Player == self.CurrentTarget.Player then
                stillValid = true
                self.CurrentTarget = e
                break
            end
        end
        if not stillValid then
            self.CurrentTarget = nil
            self.TargetSwitchTime = 0
        end
    end

    if self.CurrentTarget then
        if now - self.TargetSwitchTime < settings.LockTime then
            return self.CurrentTarget
        end
        if bestEnemy and bestEnemy.Score > self.CurrentTarget.Score then
            self.CurrentTarget = bestEnemy
            self.TargetSwitchTime = now
            return self.CurrentTarget
        end
        return self.CurrentTarget
    else
        self.CurrentTarget = bestEnemy
        self.TargetSwitchTime = now
        return self.CurrentTarget
    end
end

function TargetManager:GetCurrentTarget()
    return self.CurrentTarget
end

function TargetManager:ClearTarget()
    self.CurrentTarget = nil
    self.TargetSwitchTime = 0
end

return TargetManager
