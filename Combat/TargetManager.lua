--[=[
    XLORENs - TargetManager
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
    }
    return self
end

function TargetManager:GetTarget(origin, settings)
    settings = settings or self.Settings
    local enemies = self.WallChecker:GetAllEnemies(origin)
    if #enemies == 0 then
        self.CurrentTarget = nil
        return nil
    end
    local best = enemies[1]
    for _, e in ipairs(enemies) do
        if e.Distance < best.Distance then best = e end
    end
    self.CurrentTarget = best
    return best
end

function TargetManager:GetCurrentTarget()
    return self.CurrentTarget
end

return TargetManager
