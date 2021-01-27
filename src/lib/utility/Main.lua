--
-- Royal Utility
--
-- @author Royal Modding
-- @version 1.7.1.0
-- @date 21/11/2020

--- Initialize RoyalUtility
---@param utilityDirectory string
function InitRoyalUtility(utilityDirectory)
    source(Utils.getFilename("Utility.lua", utilityDirectory))
    source(Utils.getFilename("UtilityDebug.lua", utilityDirectory))
    source(Utils.getFilename("UtilityEntity.lua", utilityDirectory))
    source(Utils.getFilename("UtilityGameplay.lua", utilityDirectory))
    source(Utils.getFilename("UtilityString.lua", utilityDirectory))
    source(Utils.getFilename("UtilityTable.lua", utilityDirectory))
    source(Utils.getFilename("UtilityInterpolator.lua", utilityDirectory))
    g_logManager:devInfo("Royal Utility loaded successfully by " .. g_currentModName)
    return true
end
