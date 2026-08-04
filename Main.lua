--[=[
    XLORENs - Main
]=]

print("[XLORENs] Iniciando...")

local success, result = pcall(function()
    local raw = game:HttpGet("https://raw.githubusercontent.com/player2dwhite/XLORENs/main/Core/Loader.lua")
    if not raw then error("No se pudo descargar Loader.lua") end
    local func = loadstring(raw)
    if not func then error("Error de sintaxis en Loader.lua") end
    return func()
end)

if success and result then
    local XLORENs = result
    XLORENs:Initialize()
    print("[XLORENs] Listo.")
else
    warn("[XLORENs] Error: " .. tostring(result))
end
