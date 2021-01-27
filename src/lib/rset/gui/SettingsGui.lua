--
-- Royal Settings
--
-- @author Royal Modding
-- @version 1.0.0.0
-- @date 18/01/2021

SettingsGui = {}

local SettingsGui_mt = Class(SettingsGui, TabbedMenu)

SettingsGui.CONTROLS = {}

function SettingsGui:new()
    local o = TabbedMenu:new(nil, SettingsGui_mt, g_messageCenter, g_i18n, g_gui.inputManager)
    o.returnScreenName = ""
    SettingsGui.CONTROLS = g_royalSettings.guis.pagesIds
    o:registerControls(SettingsGui.CONTROLS)
    return o
end

function SettingsGui:onGuiSetupFinished()
    SettingsGui:superClass().onGuiSetupFinished(self)
    self:setupPages()
end

function SettingsGui:setupPages()
    local alwaysEnabled = function()
        return true
    end

    ---@type RoyalSettingsMod
    for _, mod in pairs(g_royalSettings.mods) do
        local page = self[mod.guiPageName]
        local normalizedIconUVs = getNormalizedUVs({0, 0, 1024, 1024})
        self:registerPage(page, nil, alwaysEnabled)
        self:addPageTab(page, mod.icon, normalizedIconUVs)
        page.headerIcon:setImageFilename(mod.icon)
        page.headerIcon:setImageUVs(nil, unpack(normalizedIconUVs))
        page.headerText:setText(mod.description)
        page:setup(mod)
    end
end

function SettingsGui:onOpen()
    SettingsGui:superClass().onOpen(self)
    self.inputDisableTime = 200
end

function SettingsGui:onClose()
    SettingsGui:superClass().onClose(self)
end

function SettingsGui:setupMenuButtonInfo()
    self.defaultMenuButtonInfo = {{inputAction = InputAction.MENU_BACK, text = self.l10n:getText("button_back"), callback = self:makeSelfCallback(self.onClickBack), showWhenPaused = true}}
end

function SettingsGui:onClickBack()
    SettingsGui:superClass().onClickBack(self)
    g_royalSettings:onGuiClosed()
end
