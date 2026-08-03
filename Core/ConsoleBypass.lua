--[=[
    XLORENs - Console Bypass
    Oculta todos los logs (print, warn, error) del LogService global.
]=]

local ConsoleBypass = {}

-- ====================================================
-- CONFIGURACIÓN
-- ====================================================
ConsoleBypass.Settings = {
    Enabled = true,          -- Activar/desactivar el bypass
    DebugMode = false,       -- Si true, los logs se muestran en la consola del ejecutor
    BlockLogService = true,  -- Desconectar LogService.MessageOut
}

-- ====================================================
-- VARIABLES INTERNAS
-- ====================================================
local oldPrint, oldWarn, oldError
local hooksActive = false

-- ====================================================
-- FUNCIONES DE INTERCEPCIÓN
-- ====================================================
local function interceptPrint(...)
    if not ConsoleBypass.Settings.Enabled then
        return oldPrint(...)
    end
    if ConsoleBypass.Settings.DebugMode and oldPrint then
        oldPrint("[XLORENs]", ...)
    end
end

local function interceptWarn(...)
    if not ConsoleBypass.Settings.Enabled then
        return oldWarn(...)
    end
    if ConsoleBypass.Settings.DebugMode and oldWarn then
        oldWarn("[XLORENs WARN]", ...)
    end
end

local function interceptError(msg, level)
    if not ConsoleBypass.Settings.Enabled then
        return oldError(msg, (level or 1) + 1)
    end
    if ConsoleBypass.Settings.DebugMode and oldError then
        oldError(msg, (level or 1) + 1)
    end
    return oldError(msg, (level or 1) + 1)
end

-- ====================================================
-- ACTIVAR / DESACTIVAR BYPASS
-- ====================================================
function ConsoleBypass:Enable()
    if hooksActive then return end
    hooksActive = true

    oldPrint = print
    oldWarn = warn
    oldError = error

    local hookSuccess = pcall(function()
        hookfunction(print, interceptPrint)
        hookfunction(warn, interceptWarn)
        hookfunction(error, interceptError)
    end)

    if not hookSuccess then
        _G.print = interceptPrint
        _G.warn = interceptWarn
        _G.error = interceptError
    end

    if ConsoleBypass.Settings.BlockLogService then
        pcall(function()
            local LogService = game:GetService("LogService")
            local hasGetConnections = pcall(function() return getconnections end)
            if hasGetConnections then
                for _, conn in ipairs(getconnections(LogService.MessageOut)) do
                    pcall(function() conn:Disable() end)
                end
            end
        end)
    end
end

function ConsoleBypass:Disable()
    if not hooksActive then return end
    hooksActive = false

    local restoreSuccess = pcall(function()
        hookfunction(print, oldPrint)
        hookfunction(warn, oldWarn)
        hookfunction(error, oldError)
    end)

    if not restoreSuccess then
        _G.print = oldPrint
        _G.warn = oldWarn
        _G.error = oldError
    end
end

function ConsoleBypass:Toggle()
    if hooksActive then
        self:Disable()
    else
        self:Enable()
    end
end

if ConsoleBypass.Settings.Enabled then
    ConsoleBypass:Enable()
end

return ConsoleBypass
