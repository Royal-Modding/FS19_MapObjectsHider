--
-- Royal Mod
--
-- @author Royal Modding
-- @version 1.3.0.0
-- @date 03/12/2020

--- Initialize RoyalMod
---@param utilityDirectory string
function InitRoyalMod(utilityDirectory)
    source(Utils.getFilename("RoyalMod.lua", utilityDirectory))
    g_logManager:devInfo("Royal Mod loaded successfully by " .. g_currentModName)
    return true
end
