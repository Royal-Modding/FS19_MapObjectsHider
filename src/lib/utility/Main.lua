--
-- Royal Utility
--
-- @author Royal Modding
-- @version 1.3.0.0
-- @date 21/11/2020

--- Initialize RoyalUtility
---@param utilityDirectory string
function InitRoyalUtility(utilityDirectory)
    source(Utils.getFilename("Utility.lua", utilityDirectory))
    g_logManager:devInfo("Royal Utility loaded successfully by " .. g_currentModName)
    return true
end
