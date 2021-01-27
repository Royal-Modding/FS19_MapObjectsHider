--
-- Royal Settings
--
-- @author Royal Modding
-- @version 1.0.0.0
-- @date 19/01/2021

---@class RoyalSettingsMod
RoyalSettingsMod = {}

---@param name string
---@param icon string
---@param description string
---@return RoyalSettingsMod
function RoyalSettingsMod.new(name, icon, description)
    ---@type RoyalSettingsMod
    local mod = {}
    ---@type string
    mod.name = name
    ---@type string
    mod.icon = icon
    ---@type string
    mod.description = StringUtility.parseI18NText(description)
    ---@type string
    mod.guiPageName = ""
    ---@type RoyalSetting[]
    mod.settings = {}
    ---@type RoyalSetting[]
    mod.orderedSettings = {}

    --- Adds a new setting to mod
    ---@param self RoyalSettingsMod
    ---@param setting RoyalSetting
    mod.addSetting = function(self, setting)
        table.insert(self.orderedSettings, setting)
        self.settings[setting.key] = setting
    end

    --- Adds callback for setting change notifications to all mod settings
    ---@param self RoyalSettingsMod
    ---@param callback fun(selectedValue:any, selectedIndex:integer, settingKey:string, settingName:string, settingModName:string) callback function
    ---@param callObject any callback object
    mod.addCallback = function(self, callback, callObject)
        ---@type RoyalSetting
        for _, s in ipairs(self.orderedSettings) do
            s:addCallback(callback, callObject)
        end
    end
    return mod
end
