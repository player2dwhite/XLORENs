--[=[
    XLORENs - TargetManager
    Selección y seguimiento de objetivos con FOV y lock time.
]=]

local TargetManager = {}
TargetManager.__index = TargetManager

TargetManager.DefaultSettings = {
    FieldOfView = 150,       -- en píxeles
    LockTime = 0.35,         -- segundos antes de cambiar de objetivo
}

function TargetManager:Initialize(framework)
    self._framework = framework
    self._wallChecker = framework.WallChecker
    self._settings = TargetManager.DefaultSettings
    self._currentTarget = nil
    self._lastSwitchTime = 0
    return self
end

function TargetManager:GetTarget(originPosition, optionalSettings)
    local settings = optionalSettings or self._settings
    local currentTime = tick()

    local allEnemies = self._wallChecker:GetAllEnemies(originPosition)

    local enemiesInFOV = {}
    for _, enemy in ipairs(allEnemies) do
        if enemy.ScreenDistance <= settings.FieldOfView then
            table.insert(enemiesInFOV, enemy)
        end
    end

    local bestEnemy = nil
    local bestScore = -math.huge
    for _, enemy in ipairs(enemiesInFOV) do
        if enemy.Score > bestScore then
            bestScore = enemy.Score
            bestEnemy = enemy
        end
    end

    if not bestEnemy and #allEnemies > 0 then
        bestEnemy = allEnemies[1]
        for _, enemy in ipairs(allEnemies) do
            if enemy.Score > bestScore then
                bestScore = enemy.Score
                bestEnemy = enemy
            end
        end
    end

    if not bestEnemy then
        self._currentTarget = nil
        self._lastSwitchTime = 0
        return nil
    end

    if self._currentTarget then
        local stillValid = false
        for _, enemy in ipairs(enemiesInFOV) do
            if enemy.Player == self._currentTarget.Player then
                stillValid = true
                self._currentTarget = enemy
                break
            end
        end
        if not stillValid then
            self._currentTarget = nil
            self._lastSwitchTime = 0
        else
            if currentTime - self._lastSwitchTime >= settings.LockTime then
                if bestEnemy and bestEnemy.Score > self._currentTarget.Score then
                    self._currentTarget = bestEnemy
                    self._lastSwitchTime = currentTime
                end
            end
            return self._currentTarget
        end
    end

    self._currentTarget = bestEnemy
    self._lastSwitchTime = currentTime
    return self._currentTarget
end

function TargetManager:GetCurrentTarget()
    return self._currentTarget
end

return TargetManager
