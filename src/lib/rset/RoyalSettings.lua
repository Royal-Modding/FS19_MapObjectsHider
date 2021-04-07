--- Royal Settings

---@author Royal Modding
---@version 1.4.0.0
---@date 12/01/2021

---@class RoyalSettings
RoyalSettings = {}
---@type integer
RoyalSettings.revision = 5
---@type string
RoyalSettings.loadingModName = g_currentModName
---@type string
RoyalSettings.userProfileDirectory = getUserProfileAppPath()
---@type string
RoyalSettings.libDirectory = ""
---@type string
RoyalSettings.name = g_currentModName
---@type string
RoyalSettings.xmlRootNode = "royalSettings"
---@type string
RoyalSettings.settingsGuiName = "RoyalSettings_SettingsGui"
RoyalSettings.TYPES = {}
---@type integer
RoyalSettings.TYPES.GLOBAL = 1
---@type integer
RoyalSettings.TYPES.SAVEGAME = 2
RoyalSettings.OWNERS = {}
---@type integer
RoyalSettings.OWNERS.ALL = 1
---@type integer
RoyalSettings.OWNERS.USER = 2

---@param gameEnv any
function RoyalSettings:initialize(gameEnv)
    g_logManager:devInfo("Initializing Royal Settings from %s", self.loadingModName)

    self.registrationEnabled = true
    self.guiDirectory = self.libDirectory .. "gui/"

    self.g_i18n = g_i18n

    self.dummyModDescDirectory = Utils.getFilename("dummyModDesc.xml", g_royalSettings.libDirectory)

    local dummyModDesc = loadXMLFile("dummyModDesc", self.dummyModDescDirectory)
    local i = 0
    while true do
        local baseName = string.format("modDesc.l10n.text(%d)", i)
        local name = getXMLString(dummyModDesc, baseName .. "#name")
        if name == nil then
            break
        end
        local text = getXMLString(dummyModDesc, baseName .. "." .. g_languageShort)
        if text == nil then
            text = getXMLString(dummyModDesc, baseName .. ".en")
        end
        self.g_i18n:setText(name, text)
        i = i + 1
    end
    delete(dummyModDesc)

    -- loading other scripts here to prevent useless loading from multiple instances of the library
    source(Utils.getFilename("RoyalSetting.lua", self.libDirectory))
    source(Utils.getFilename("RoyalSettingsMod.lua", self.libDirectory))
    source(Utils.getFilename("RoyalSettingGlobal.lua", self.libDirectory))
    source(Utils.getFilename("gui/SettingsGui.lua", self.libDirectory))
    source(Utils.getFilename("gui/SettingsGuiPage.lua", self.libDirectory))

    self.settingsClass = {}
    self.settingsClass[self.TYPES.GLOBAL] = {}
    self.settingsClass[self.TYPES.GLOBAL][self.OWNERS.ALL] = nil
    self.settingsClass[self.TYPES.GLOBAL][self.OWNERS.USER] = RoyalSettingGlobal

    ---@type RoyalSettingsMod[]
    self.mods = {}

    ---@type RoyalSetting[]
    self.settings = {}

    Utility.prependedFunction(Mission00, "loadMission00Finished", self.onLoad)
    Utility.appendedFunction(FSBaseMission, "saveSavegame", self.onSaveSavegame)

    Utility.prependedFunction(g_inputBinding, "loadModActions", self.preLoadModActionsAndBindings)
    Utility.appendedFunction(g_inputBinding, "loadModActions", self.postLoadModActionsAndBindings)
    Utility.prependedFunction(g_inputBinding, "loadModBindingDefaults", self.preLoadModActionsAndBindings)
    Utility.appendedFunction(g_inputBinding, "loadModBindingDefaults", self.postLoadModActionsAndBindings)

    Utility.appendedFunction(gameEnv, "registerGlobalActionEvents", self.registerGlobalActionEvents)

    self.modManager_getMods = g_modManager.getMods

    local time = getTimeSec()
    g_inputBinding:load()

    g_logManager:devInfo("[Royal Settings] InputBinding reloaded in %.1f ms", (getTimeSec() - time) * 1000)
end

---@param inputManager InputBinding
function RoyalSettings.registerGlobalActionEvents(inputManager)
    local eventAdded, eventId = inputManager:registerActionEvent(InputAction.ROYAL_SETTINGS_OPEN, g_royalSettings, g_royalSettings.openGui, false, true, false, true)
    if eventAdded then
        inputManager:setActionEventTextVisibility(eventId, false)
    end
end

---@param modManager ModManager
---@return ModEntry[]
function RoyalSettings.custom_modManager_getMods(modManager)
    ---@type ModEntry[]
    local mods = g_royalSettings.modManager_getMods(modManager)
    ---@type ModEntry
    local dummyRoyalSettingsMod = {modName = "g_royalSettings", modFile = g_royalSettings.dummyModDescDirectory}
    table.insert(mods, dummyRoyalSettingsMod)
    return mods
end

function RoyalSettings.preLoadModActionsAndBindings(inputBinding)
    g_modManager.getMods = g_royalSettings.custom_modManager_getMods
end

function RoyalSettings.postLoadModActionsAndBindings(inputBinding)
    g_modManager.getMods = g_royalSettings.modManager_getMods
end

function RoyalSettings:onLoad()
    self = g_royalSettings

    self:onLoadSavegame()

    self.guis = {}
    self.guis.pagesIds = {}
    local settingsGuiPageXml = loadXMLFile("settingsGuiPageXml", self.guiDirectory .. "SettingsGuiPage.xml")
    local settingsGuiXml = loadXMLFile("settingsGuiXml", self.guiDirectory .. "SettingsGui.xml")
    local index = 0
    ---@type RoyalSettingsMod
    for _, m in pairs(self.mods) do
        m.guiPageName = self.settingsGuiName .. "_" .. m.name
        table.insert(self.guis.pagesIds, m.guiPageName)

        setXMLString(settingsGuiPageXml, "GUI#name", m.guiPageName)
        self.createGui(settingsGuiPageXml, m.guiPageName, SettingsGuiPage:new(), true)

        local tmpKey = string.format("GUI.GuiElement(2).GuiElement.GuiElement(%d)", index)
        setXMLString(settingsGuiXml, tmpKey .. "#type", "frameReference")
        setXMLString(settingsGuiXml, tmpKey .. "#ref", m.guiPageName)
        setXMLString(settingsGuiXml, tmpKey .. "#name", m.guiPageName)
        setXMLString(settingsGuiXml, tmpKey .. "#id", m.guiPageName)
        index = index + 1
    end
    delete(settingsGuiPageXml)
    self.createGui(settingsGuiXml, self.settingsGuiName, SettingsGui:new())
    delete(settingsGuiXml)
end

function RoyalSettings:onLoadSavegame()
    self.registrationEnabled = false
    local xmlIds = {}
    ---@type RoyalSetting
    for _, setting in pairs(self.settings) do
        local xmlPath = Utils.getFilename(setting:getSavegameFilePath(), self.userProfileDirectory)
        if xmlIds[xmlPath] == nil then
            if fileExists(xmlPath) then
                xmlIds[xmlPath] = loadXMLFile("royalSettingsSave" .. xmlPath, xmlPath)
            end
        end
        if xmlIds[xmlPath] == nil then
            setting:loadDefaults()
        else
            setting:loadFromXMLFile(xmlIds[xmlPath], self.xmlRootNode)
        end
    end
    for _, xml in pairs(xmlIds) do
        delete(xml)
    end
end

function RoyalSettings:onSaveSavegame()
    self = g_royalSettings
    local xmlIds = {}
    ---@type RoyalSetting
    for _, setting in pairs(self.settings) do
        local xmlPath = Utils.getFilename(setting:getSavegameFilePath(), self.userProfileDirectory)
        if xmlIds[xmlPath] == nil then
            if fileExists(xmlPath) then
                xmlIds[xmlPath] = loadXMLFile("royalSettingsSave" .. xmlPath, xmlPath)
            else
                xmlIds[xmlPath] = createXMLFile("royalSettingsSave" .. xmlPath, xmlPath, self.xmlRootNode)
            end
            setXMLInt(xmlIds[xmlPath], self.xmlRootNode .. "#revision", self.revision)
        end
        setting:saveToXMLFile(xmlIds[xmlPath], self.xmlRootNode)
    end
    for _, xml in pairs(xmlIds) do
        saveXMLFile(xml)
        delete(xml)
    end
end

function RoyalSettings:onGuiClosed()
    --TODO: not all kind of settings have to be saved on gui closed
    self.onSaveSavegame()
end

--- Open settings gui
function RoyalSettings:openGui()
    if not g_gui:getIsGuiVisible() and not g_gui:getIsDialogVisible() and not g_gui:getIsOverlayGuiVisible() then
        g_gui:showGui(self.settingsGuiName)
    end
end

--- Register a mod tab
---@param modName string
---@param icon string
---@param description string
---@return RoyalSettingsMod
function RoyalSettings:registerMod(modName, icon, description)
    if self.registrationEnabled then
        if self.mods[modName] == nil then
            self.mods[modName] = RoyalSettingsMod.new(modName, icon, description)
            return self.mods[modName]
        else
            g_logManager:devError("[Royal Settings] Tab for '%s' is already registered", modName)
        end
    else
        g_logManager:devError("[Royal Settings] Mods / tabs registration isn't allowd at this time")
    end
end

--- Register a mod setting
---@param modName string
---@param settingName string
---@param settingType integer
---@param settingOwner integer
---@param defaultIndex integer
---@param values any[]
---@param texts string[]
---@param description string
---@param tooltip string
---@return RoyalSetting
function RoyalSettings:registerSetting(modName, settingName, settingType, settingOwner, defaultIndex, values, texts, description, tooltip)
    if self.registrationEnabled then
        if self.mods[modName] ~= nil then
            local sclass = self.settingsClass[settingType][settingOwner]
            if sclass ~= nil then
                ---@type RoyalSetting
                local newSetting = sclass:new()
                local key = string.format("%s.%s", modName, settingName)
                if self.settings[key] == nil then
                    if newSetting:initialize(key, modName, settingName, defaultIndex, values, texts, description, tooltip) then
                        self.settings[key] = newSetting
                        self.mods[modName]:addSetting(newSetting)
                        return self.settings[key]
                    end
                else
                    g_logManager:devError("[Royal Settings] Setting with key '%s' is already registered", key)
                end
            else
                g_logManager:devError("[Royal Settings] Can't find a proper setting class for (%d, %d) type / owner combination", settingType, settingOwner)
            end
        else
            g_logManager:devError("[Royal Settings] Tab for '%s' isn't still registered", modName)
        end
    else
        g_logManager:devError("[Royal Settings] Settings registration isn't allowd at this time")
    end
end

--#region gui utils
function RoyalSettings.createGui(xmlFile, name, controller, isFrame)
    local gui = nil
    if xmlFile ~= nil and xmlFile ~= 0 then
        FocusManager:setGui(name)

        gui = GuiElement:new(controller)
        gui.name = name
        --gui.xmlFilename = xmlFilename
        controller.name = name

        gui:loadFromXML(xmlFile, "GUI")

        if isFrame then
            controller.name = gui.name
        end

        g_gui:loadGuiRec(xmlFile, "GUI", gui, controller)

        if not isFrame then
            -- frames must only be scaled as part of screens, do not scale them on loading
            gui:applyScreenAlignment()
            gui:updateAbsolutePosition()
        end

        controller:addElement(gui)
        controller:exposeControlsAsFields(name)

        controller:onGuiSetupFinished()
        -- call onCreate of configuration root node --> targets onCreate on view
        gui:raiseCallback("onCreateCallback", gui, gui.onCreateArgs)

        if isFrame then
            g_gui:addFrame(controller, gui)
        else
            g_gui.guis[name] = gui
            g_gui.nameScreenTypes[name] = controller:class() -- TEMP, until showGui is replaced
            -- store screen by its class for symbolic access
            g_gui:addScreen(controller:class(), controller, gui)
        end
    else
        g_logManager:error("Could not use gui-config '%s'!", xmlFile)
    end

    return gui
end
--#endregion

--#region bootstrap
local game = getfenv(0)
if game.g_royalSettings == nil then
    game.g_royalSettings = {}
    game.g_royalSettings.instances = {}
    game.g_royalSettings.bootstrap = function()
        local hRevision = -1
        ---@type RoyalSettings
        local object = nil
        for _, rs in ipairs(game.g_royalSettings.instances) do
            if rs ~= nil and rs.obj ~= nil and rs.obj.initialize ~= nil and rs.rev > hRevision then
                hRevision = rs.rev
                object = rs.obj
            end
        end
        for _, rs in ipairs(game.g_royalSettings.instances) do
            if rs ~= object then
                rs = nil
            end
        end
        g_royalSettings = object
        game.g_royalSettings = object
        game.g_royalSettings:initialize(game)
    end
    Utility.prependedFunction(VehicleTypeManager, "validateVehicleTypes", game.g_royalSettings.bootstrap)
end
table.insert(game.g_royalSettings.instances, {obj = RoyalSettings, rev = RoyalSettings.revision})
--#endregion
