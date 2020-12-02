--
-- ${title}
--
-- @author ${author}
-- @version ${version}
-- @date 29/11/2020

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
        Utility.renderTable(0.1, 0.95, 0.009, self.debugInfo or "nil", 3, false)
    end
end

function PlayerExtension:updateTick(superFunc, dt)
    superFunc(self, dt)
    if self.isEntered then
        local x, y, z = localToWorld(self.cameraNode, 0, 0, 1.0)
        local dx, dy, dz = localDirectionToWorld(self.cameraNode, 0, 0, -1)
        self.raycastHittedObject = nil
        self.debugInfo = nil
        raycastAll(x, y, z, dx, dy, dz, "raycastCallback", 5, self)
    end
end

function PlayerExtension:raycastCallback(hitObjectId, _, _, _, _)
    if hitObjectId ~= self.rootNode then
        if getHasClassId(hitObjectId, ClassIds.SHAPE) then
            if MapObjectsHider.debug and self.debugInfo == nil then
                self.debugInfo = {}
                self.debugInfo.id = hitObjectId
                self.debugInfo.object = g_currentMission:getNodeObject(hitObjectId) or "nil"
                self.debugInfo.rigidBodyType = getRigidBodyType(hitObjectId)
                self.debugInfo.index = Utility.nodeToIndex(hitObjectId, MapObjectsHider.mapNode)
                self.debugInfo.name = getName(hitObjectId)
                self.debugInfo.material = getMaterial(hitObjectId, 0)
                self.debugInfo.materialName = getName(self.debugInfo.material)
                self.debugInfo.geometry = getGeometry(hitObjectId)
                self.debugInfo.clipDistance = getClipDistance(hitObjectId)
                self.debugInfo.mask = getObjectMask(hitObjectId)
            end
            if g_currentMission:getNodeObject(hitObjectId) == nil and (getRigidBodyType(hitObjectId) == "Static" or getRigidBodyType(hitObjectId) == "Dynamic") and getSplitType(hitObjectId) == 0 then
                local object = {}
                object.id = hitObjectId
                object.name = getName(hitObjectId)
                if not getVisibility(hitObjectId) then
                    object.name = getName(getParent(hitObjectId))
                end
                self.raycastHittedObject = object
                return false
            end
        end
    end
    return true -- continue raycast
end

function PlayerExtension:updateActionEvents(superFunc)
    superFunc(self)
    if self.raycastHittedObject ~= nil then
        local id = self.inputInformation.registrationList[InputAction.MAP_OBJECT_HIDER_HIDE].eventId
        g_inputBinding:setActionEventText(id, g_i18n:getText("moh_HIDE"):format(self.raycastHittedObject.name))
        g_inputBinding:setActionEventActive(id, true)
        g_inputBinding:setActionEventTextVisibility(id, true)
    else
        local id = self.inputInformation.registrationList[InputAction.MAP_OBJECT_HIDER_HIDE].eventId
        g_inputBinding:setActionEventActive(id, false)
        g_inputBinding:setActionEventTextVisibility(id, false)
    end
end

function PlayerExtension:hideObjectActionEvent()
    if self.raycastHittedObject ~= nil then
        self.raycastHittedObjectIdBackup = self.raycastHittedObject.id
        g_gui:showYesNoDialog({text = g_i18n:getText("moh_dialog_text"):format(self.raycastHittedObject.name), title = g_i18n:getText("moh_dialog_title"), callback = self.hideObjectDialogCallback, target = self})
    end
end

function PlayerExtension:hideObjectDialogCallback(yes)
    if yes and self.raycastHittedObjectIdBackup ~= nil then
        MapObjectsHider:hideObject(self.raycastHittedObjectIdBackup)
        self.raycastHittedObjectIdBackup = nil
    end
end
