--
-- Royal Settings
--
-- @author Royal Modding
-- @version 1.0.0.0
-- @date 12/01/2021

---@class RoyalSetting
RoyalSetting = {}
RoyalSetting_mt = Class(RoyalSetting)

--- RoyalSetting base class
---@param mt? table custom meta table
---@return RoyalSetting
function RoyalSetting:new(mt)
    ---@type RoyalSetting
    local rs = setmetatable({}, mt or RoyalSetting_mt)
    rs.genv = getfenv(0)
    rs.callbacks = {}
    return rs
end

function RoyalSetting:initialize(key, modName, name, defaultIndex, values, texts, description, tooltip)
    self.key = key
    self.modName = modName
    self.name = name
    self.options = {}
    for i, value in ipairs(values) do
        self.options[i] = {value = value, text = StringUtility.parseI18NText(texts[i])}
    end
    if self.options[defaultIndex] ~= nil then
        self.selected = defaultIndex
    else
        self.selected = 1
    end
    self.tooltip = StringUtility.parseI18NText(tooltip)
    self.description = StringUtility.parseI18NText(description)
    return true
end

function RoyalSetting:select(index)
    if self.options[index] ~= nil then
        self.selected = index
        self:callCallbacks()
    end
end

function RoyalSetting:getSelectedValue()
    return self.options[self.selected].value
end

function RoyalSetting:getSelectedText()
    return self.options[self.selected].text
end

function RoyalSetting:getSelectedIndex()
    return self.selected
end

function RoyalSetting:getSavegameFilePath()
    return ""
end

function RoyalSetting:saveToXMLFile(xmlId, key)
    setXMLInt(xmlId, string.format("%s.%s#si", key, self.key), self:getSelectedIndex())
end

function RoyalSetting:loadFromXMLFile(xmlId, key)
    self:select(getXMLInt(xmlId, string.format("%s.%s#si", key, self.key)) or self:getSelectedIndex())
end

--- Adds callback for setting change notifications
---@param callback fun(selectedValue:any, selectedIndex:integer, settingKey:string, settingName:string, settingModName:string) callback function
---@param callObject any callback object
function RoyalSetting:addCallback(callback, callObject)
    table.insert(self.callbacks, {callback = callback, callObject = callObject})
end

function RoyalSetting:callCallbacks(callback, callObject)
    for _, cbs in ipairs(self.callbacks) do
        if cbs.callObject ~= nil then
            cbs.callback(cbs.callObject, self:getSelectedValue(), self:getSelectedIndex(), self.key, self.name, self.modName)
        else
            cbs.callback(self:getSelectedValue(), self:getSelectedIndex(), self.key, self.name, self.modName)
        end
    end
end
