--- Royal Settings

---@author Royal Modding
---@version 1.4.0.0
---@date 13/01/2021

---@class RoyalSettingGlobal : RoyalSetting
RoyalSettingGlobal = {}
RoyalSettingGlobal_mt = Class(RoyalSettingGlobal, RoyalSetting)

--- RoyalSettingGlobal class
---@param mt? table custom meta table
---@return RoyalSettingGlobal
function RoyalSettingGlobal:new(mt)
    ---@type RoyalSettingGlobal
    local rs = RoyalSetting:new(mt or RoyalSettingGlobal_mt)
    return rs
end

function RoyalSettingGlobal:getSavegameFilePath()
    return "modsSettings/royalSettings.xml"
end
