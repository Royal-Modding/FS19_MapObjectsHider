--- Royal Settings

---@author Royal Modding
---@version 1.4.1.0
---@date 12/01/2021

--- Initialize RoyalSettings library
---@param libDirectory string
function InitRoyalSettings(libDirectory)
    source(Utils.getFilename("RoyalSettings.lua", libDirectory))
    RoyalSettings.libDirectory = libDirectory
    g_logManager:devInfo("Royal Settings loaded successfully by " .. g_currentModName)
    return true
end
