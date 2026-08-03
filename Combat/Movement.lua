--[=[
    XLORENs - Movement
    Sistema de macros de movimiento para entrenamiento de peaks/quickpeaks.
    INTERPRETA secuencias como "Q + A + D", "dE", "3x", etc.
    NO está diseñado para automatizar partidas, solo para practicar mecánicas.
]=]

local Movement = {}
Movement.__index = Movement

-- ====================================================
-- CONFIGURACIÓN
-- ====================================================
Movement.Settings = {
    Enabled = false,
    AutoExecute = false,      -- Ejecutar automáticamente al detectar enemigo
    LoopMode = false,         -- Repetir la secuencia en bucle
    Keybind = "B",            -- Tecla para ejecutar la secuencia actual
    Debug = false,
}

-- ====================================================
-- INTERPRETADOR DE SECUENCIAS
-- ====================================================

-- Mapa de teclas a códigos de teclado (para simulación)
local KEY_MAP = {
    ["A"] = Enum.KeyCode.A,
    ["D"] = Enum.KeyCode.D,
    ["W"] = Enum.KeyCode.W,
    ["S"] = Enum.KeyCode.S,
    ["Q"] = Enum.KeyCode.Q,
    ["E"] = Enum.KeyCode.E,
    ["Space"] = Enum.KeyCode.Space,
    ["Jump"] = Enum.KeyCode.Space,
    ["Aim"] = Enum.KeyCode.RightMouseButton,   -- Asumo que aim es clic derecho
    ["UnAim"] = nil,                           -- Soltar el botón derecho
    ["Shoot"] = Enum.KeyCode.MouseButton1,     -- Disparo
    ["Reload"] = Enum.KeyCode.R,               -- Recargar
}

local function parseKey(key)
    -- Limpiar espacios y convertir a mayúsculas
    local cleaned = string.upper(key):match("%a+") or key
    if KEY_MAP[cleaned] then
        return KEY_MAP[cleaned]
    end
    -- Si no está en el mapa, intentar convertir directamente
    local success, result = pcall(function()
        return Enum.KeyCode[cleaned]
    end)
    if success and result then
        return result
    end
    warn("[Movement] Tecla no reconocida:", key)
    return nil
end

local function parseAction(action)
    -- Ejemplos: "Q", "dE", "A+D+E", "Jump"
    local keys = {}
    local hasUppercase = false
    local lowerCaseKeys = {}

    -- Separar por '+'
    local parts = {}
    for part in string.gmatch(action, "[^+]+") do
        table.insert(parts, part:gsub("%s+", "")) -- eliminar espacios
    end

    for _, part in ipairs(parts) do
        -- Detectar combinaciones como "dE" (minúscula + mayúscula)
        if part:match("^%l+%u+$") or part:match("^%l+%u?%l?%u?$") then
            -- Es una combinación pegada tipo "dE", "qA", "eD"
            local lowercase = ""
            local uppercase = ""
            for char in part:gmatch(".") do
                if char:match("%l") then
                    lowercase = lowercase .. char
                elseif char:match("%u") then
                    uppercase = uppercase .. char
                end
            end
            -- Las minúsculas se interpretan como teclas que se mantienen (hold)
            for char in lowercase:gmatch(".") do
                table.insert(lowerCaseKeys, char:upper())
            end
            -- Las mayúsculas se presionan y sueltan rápidamente (tap)
            for char in uppercase:gmatch(".") do
                table.insert(keys, { Key = char:upper(), Type = "tap" })
            end
        else
            -- Tecla normal (puede estar en mayúsculas o minúsculas)
            local upperPart = part:upper()
            if part:match("^%l+$") then
                -- Si es minúscula, es una tecla que se mantiene (hold)
                table.insert(lowerCaseKeys, upperPart)
            else
                table.insert(keys, { Key = upperPart, Type = "tap" })
            end
        end
    end

    -- Procesar las teclas que se mantienen (lowercase)
    if #lowerCaseKeys > 0 then
        -- Mantener presionadas todas las teclas lowerCaseKeys simultáneamente
        local holdKeys = {}
        for _, k in ipairs(lowerCaseKeys) do
            local keyCode = parseKey(k)
            if keyCode then
                table.insert(holdKeys, keyCode)
            end
        end
        return { Hold = holdKeys, Taps = keys }
    else
        return { Hold = {}, Taps = keys }
    end
end

local function parseSequence(sequence)
    local actions = {}
    local tokens = {}
    local current = ""
    local inQuotes = false

    -- Dividir la secuencia por espacios, respetando comillas
    for i = 1, #sequence do
        local char = string.sub(sequence, i, i)
        if char == '"' then
            inQuotes = not inQuotes
        elseif char == " " and not inQuotes then
            if current ~= "" then
                table.insert(tokens, current)
                current = ""
            end
        else
            current = current .. char
        end
    end
    if current ~= "" then
        table.insert(tokens, current)
    end

    local i = 1
    while i <= #tokens do
        local token = tokens[i]

        -- Manejar repeticiones "3x"
        if token:match("^%d+x$") then
            local repeatCount = tonumber(token:match("^(%d+)"))
            local action = actions[#actions] -- Última acción
            if action and action.RepeatCount == nil then
                action.RepeatCount = repeatCount
                action.Original = action.Original -- preservar
            else
                warn("[Movement] Repetición sin acción previa:", token)
            end
            i = i + 1
            continue
        end

        -- Manejar esperas "...."
        if token:match("^%.+$") then
            local waitTime = #token * 0.1 -- Cada punto son 100ms
            table.insert(actions, { Type = "Wait", Duration = waitTime })
            i = i + 1
            continue
        end

        -- Manejar acciones compuestas como "A+D+E"
        local action = parseAction(token)
        if #action.Hold > 0 or #action.Taps > 0 then
            table.insert(actions, {
                Type = "Action",
                Hold = action.Hold,
                Taps = action.Taps,
                Original = token,
                RepeatCount = 1,
            })
        else
            warn("[Movement] Acción no reconocida:", token)
        end
        i = i + 1
    end

    return actions
end

-- ====================================================
-- EJECUTOR DE SECUENCIAS (simulación de teclas)
-- ====================================================
local function executeKey(keyCode, isPress)
    if not keyCode then return end
    local vim = game:GetService("VirtualInputManager")
    if isPress then
        vim:SendKeyEvent(true, keyCode, false, game)
    else
        vim:SendKeyEvent(false, keyCode, false, game)
    end
end

function Movement:ExecuteSequence(sequence)
    if not self.Settings.Enabled then
        print("[Movement] Movimiento desactivado.")
        return
    end

    local actions = parseSequence(sequence)
    if #actions == 0 then
        print("[Movement] Secuencia vacía o no válida:", sequence)
        return
    end

    print("[Movement] Ejecutando secuencia:", sequence)

    -- Ejecutar en un hilo separado para no bloquear
    task.spawn(function()
        for _, action in ipairs(actions) do
            if not self.Settings.Enabled then break end

            if action.Type == "Wait" then
                task.wait(action.Duration)
                continue
            end

            if action.Type == "Action" then
                local repeatCount = action.RepeatCount or 1
                for r = 1, repeatCount do
                    if not self.Settings.Enabled then break end
                    if self.Settings.Debug then
                        print("[Movement] Ejecutando:", action.Original or "acción")
                    end

                    -- Mantener teclas (Hold)
                    for _, keyCode in ipairs(action.Hold) do
                        executeKey(keyCode, true)
                    end

                    -- Pulsar teclas (Tap)
                    for _, tap in ipairs(action.Taps) do
                        local keyCode = parseKey(tap.Key)
                        if keyCode then
                            if tap.Type == "tap" then
                                executeKey(keyCode, true)
                                task.wait(0.02) -- pulso breve
                                executeKey(keyCode, false)
                            end
                        end
                    end

                    -- Liberar teclas mantenidas (Hold)
                    for _, keyCode in ipairs(action.Hold) do
                        executeKey(keyCode, false)
                    end

                    if r < repeatCount then
                        task.wait(0.05) -- pequeño delay entre repeticiones
                    end
                end
            end
        end
        print("[Movement] Secuencia completada.")
    end)
end

-- ====================================================
-- PRESETS (secuencias predefinidas)
-- ====================================================
Movement.Presets = {
    -- Peaks básicos
    BasicPeak = "E + D + A",
    BasicPeak2 = "Q + A + D + E",
    QuickPeak = "Q + A + D + E + Shoot",
    QuickPeak2 = "Q + A + D + E + Q + A",

    -- Avanzados
    DoublePeak = "Q + A + D + E + Q + A + D + E",
    JumpPeak = "Jump + Q + A + D + E",
    FakePeak = "Q + A + D + Q + A",
    WidePeak = "Q + A + D + D + E",
    ShoulderPeak = "Q + A + D + E + Aim",
}

-- ====================================================
-- FUNCIONES PÚBLICAS
-- ====================================================
function Movement:Init(framework)
    self._framework = framework
    self._currentSequence = nil
    self._isRunning = false

    -- Conectar keybind
    local UIS = game:GetService("UserInputService")
    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode[self.Settings.Keybind] then
            if self._currentSequence then
                self:ExecuteSequence(self._currentSequence)
            else
                print("[Movement] No hay secuencia cargada. Usa Movement:SetSequence()")
            end
        end
    end)

    return self
end

function Movement:SetSequence(sequence)
    self._currentSequence = sequence
    print("[Movement] Secuencia cargada:", sequence)
end

function Movement:SetPreset(name)
    if self.Presets[name] then
        self:SetSequence(self.Presets[name])
        return true
    else
        warn("[Movement] Preset no encontrado:", name)
        return false
    end
end

function Movement:Enable()
    self.Settings.Enabled = true
    print("[Movement] Activado.")
end

function Movement:Disable()
    self.Settings.Enabled = false
    print("[Movement] Desactivado.")
end

function Movement:Toggle()
    if self.Settings.Enabled then
        self:Disable()
    else
        self:Enable()
    end
    return self.Settings.Enabled
end

return Movement
