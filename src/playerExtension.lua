--- ${title}

---@author ${author}
---@version r_version_r
---@date 29/11/2020

PlayerExtension = {}

function PlayerExtension:new(superFunc, isServer, isClient)
    self = superFunc(nil, isServer, isClient)
    self.inputInformation.registrationList[InputAction.MAP_OBJECT_HIDER_HIDE] = {
        eventId = "",
        callback = self.hideObjectActionEvent,
        triggerUp = false,
        triggerDown = true,
        triggerAlways = false,
        activeType = Player.INPUT_ACTIVE_TYPE.STARTS_ENABLED,
        callbackState = nil,
        text = g_i18n:getText("moh_HIDE"),
        textVisibility = true
    }
    return self
end

function PlayerExtension:update(superFunc, dt)
    superFunc(self, dt)
    if MapObjectsHider.debug and self.debugInfo ~= nil then
        DebugUtility.renderTable(0.1, 0.95, 0.01, self.debugInfo, 3, false)
    end
    if MapObjectsHider.debug and self.hideObjectDebugInfo ~= nil then
        DebugUtility.renderTable(0.2, 0.95, 0.01, self.hideObjectDebugInfo, 3, false)
    end
end

function PlayerExtension:updateTick(superFunc, dt)
    superFunc(self, dt)
    if self.isEntered and g_dedicatedServerInfo == nil then
        local x, y, z = localToWorld(self.cameraNode, 0, 0, 1.0)
        local dx, dy, dz = localDirectionToWorld(self.cameraNode, 0, 0, -1)
        self.raycastHideObject = nil
        self.debugInfo = nil
        self.hideObjectDebugInfo = nil
        raycastAll(x, y, z, dx, dy, dz, "raycastCallback", 5, self)
    end
end

function PlayerExtension:raycastCallback(hitObjectId)
    if hitObjectId ~= self.rootNode then
        if getHasClassId(hitObjectId, ClassIds.SHAPE) then
            if MapObjectsHider.debug and self.debugInfo == nil then
                -- debug first hitted object
                self.debugInfo = MapObjectsHider:getObjectDebugInfo(hitObjectId)
            end
            local rigidBodyType = getRigidBodyType(hitObjectId)
            if (rigidBodyType == "Static" or rigidBodyType == "Dynamic") then
                if getSplitType(hitObjectId) ~= 0 then
                    self.raycastHideObject = {name = getName(getParent(hitObjectId)), objectId = hitObjectId, isSplitShape = true}
                    if MapObjectsHider.debug then
                        -- debug placeable
                        self.hideObjectDebugInfo = {splitType = g_splitTypeManager:getSplitTypeByIndex(getSplitType(hitObjectId))}
                    end
                    return false
                elseif g_currentMission:getNodeObject(hitObjectId) == nil then
                    local object = {}
                    object.id, object.name = MapObjectsHider:getRealHideObject(hitObjectId)
                    if object.id ~= nil then
                        self.raycastHideObject = object
                        if MapObjectsHider.debug then
                            -- debug hide object
                            self.hideObjectDebugInfo = MapObjectsHider:getObjectDebugInfo(object.id)
                        end
                        return false
                    end
                else
                    local object = g_currentMission:getNodeObject(hitObjectId)
                    if object:isa(Placeable) then
                        local storeItem = g_storeManager:getItemByXMLFilename(object.configFileName)
                        if storeItem ~= nil then
                            self.raycastHideObject = {name = storeItem.name, object = object, isSellable = true}
                            if MapObjectsHider.debug then
                                -- debug placeable
                                self.hideObjectDebugInfo = {storeItem = storeItem}
                            end
                            return false
                        end
                    end
                end
            end
        end
    end
    return true -- continue raycast
end

function PlayerExtension:updateActionEvents(superFunc)
    superFunc(self)
    if self.raycastHideObject ~= nil then
        local id = self.inputInformation.registrationList[InputAction.MAP_OBJECT_HIDER_HIDE].eventId
        if self.raycastHideObject.isSellable then
            g_inputBinding:setActionEventText(id, g_i18n:getText("moh_SELL"):format(self.raycastHideObject.name))
        elseif self.raycastHideObject.isSplitShape then
            g_inputBinding:setActionEventText(id, g_i18n:getText("moh_DELETE"):format(self.raycastHideObject.name))
        else
            g_inputBinding:setActionEventText(id, g_i18n:getText("moh_HIDE"):format(self.raycastHideObject.name))
        end
        g_inputBinding:setActionEventActive(id, true)
        g_inputBinding:setActionEventTextVisibility(id, true)
    else
        local id = self.inputInformation.registrationList[InputAction.MAP_OBJECT_HIDER_HIDE].eventId
        g_inputBinding:setActionEventActive(id, false)
        g_inputBinding:setActionEventTextVisibility(id, false)
    end
end

function PlayerExtension:hideObjectActionEvent()
    if self.raycastHideObject ~= nil then
        self.raycastHideObjectBackup = self.raycastHideObject
        if self.raycastHideObject.isSellable then
            if MapObjectsHider.sellConfirmEnabled then
                g_gui:showYesNoDialog({text = g_i18n:getText("moh_sell_dialog_text"):format(self.raycastHideObjectBackup.name), title = g_i18n:getText("moh_dialog_title"), callback = self.sellObjectDialogCallback, target = self})
            else
                self:sellObjectDialogCallback(true)
            end
        elseif self.raycastHideObject.isSplitShape then
            if MapObjectsHider.deleteSplitShapeConfirmEnabled then
                g_gui:showYesNoDialog({text = g_i18n:getText("moh_delete_split_shape_dialog_text"), title = g_i18n:getText("moh_dialog_title"), callback = self.deleteSplitShapeDialogCallback, target = self})
            else
                self:deleteSplitShapeDialogCallback(true)
            end
        else
            if MapObjectsHider.hideConfirmEnabled then
                g_gui:showYesNoDialog({text = g_i18n:getText("moh_dialog_text"):format(self.raycastHideObjectBackup.name), title = g_i18n:getText("moh_dialog_title"), callback = self.hideObjectDialogCallback, target = self})
            else
                self:hideObjectDialogCallback(true)
            end
        end
    end
end

function PlayerExtension:hideObjectDialogCallback(yes)
    if yes and self.raycastHideObjectBackup ~= nil and self.raycastHideObjectBackup.id ~= nil then
        MapObjectsHider:hideObject(self.raycastHideObjectBackup.id)
        self.raycastHideObjectBackup = nil
    end
end

function PlayerExtension:sellObjectDialogCallback(yes)
    if yes and self.raycastHideObjectBackup ~= nil and self.raycastHideObjectBackup.object ~= nil then
        g_client:getServerConnection():sendEvent(SellPlaceableEvent:new(self.raycastHideObjectBackup.object))
    end
end

function PlayerExtension:deleteSplitShapeDialogCallback(yes)
    if yes and self.raycastHideObjectBackup ~= nil and self.raycastHideObjectBackup.objectId ~= nil then
        g_client:getServerConnection():sendEvent(DeleteSplitShapeEvent:new(self.raycastHideObjectBackup.objectId))
    end
end
