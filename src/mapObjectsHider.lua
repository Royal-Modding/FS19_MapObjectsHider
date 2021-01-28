--
-- ${title}
--
-- @author ${author}
-- @version ${version}
-- @date 29/11/2020

InitRoyalMod(Utils.getFilename("lib/rmod/", g_currentModDirectory))
InitRoyalUtility(Utils.getFilename("lib/utility/", g_currentModDirectory))
InitRoyalSettings(Utils.getFilename("lib/rset/", g_currentModDirectory))

---@class MapObjectsHider : RoyalMod
MapObjectsHider = RoyalMod.new(r_debug_r, true)
MapObjectsHider.hiddenObjects = {}
MapObjectsHider.revision = 1
MapObjectsHider.md5 = not MapObjectsHider.debug
MapObjectsHider.hideConfirmEnabled = true
MapObjectsHider.sellConfirmEnabled = true

function MapObjectsHider:initialize()
    Utility.overwrittenFunction(Player, "updateTick", PlayerExtension.updateTick)
    Utility.overwrittenFunction(Player, "update", PlayerExtension.update)
    Utility.overwrittenFunction(Player, "new", PlayerExtension.new)
    Utility.overwrittenFunction(Player, "updateActionEvents", PlayerExtension.updateActionEvents)
    if Player.raycastCallback == nil then
        Player.raycastCallback = PlayerExtension.raycastCallback
    end
    if Player.hideObjectActionEvent == nil then
        Player.hideObjectActionEvent = PlayerExtension.hideObjectActionEvent
    end
    if Player.hideObjectDialogCallback == nil then
        Player.hideObjectDialogCallback = PlayerExtension.hideObjectDialogCallback
    end
    if Player.sellObjectDialogCallback == nil then
        Player.sellObjectDialogCallback = PlayerExtension.sellObjectDialogCallback
    end
end

function MapObjectsHider:onMissionInitialize(baseDirectory, missionCollaborators)
end

function MapObjectsHider:onSetMissionInfo(missionInfo, missionDynamicInfo)
    if missionDynamicInfo.isMultiplayer then
        -- disable findDynamicObjects to prevent rigid body removal on mp
        BaseMission.findDynamicObjects = function()
        end
    end
end

function MapObjectsHider:onLoad()
    g_royalSettings:registerMod(self.name, self.directory .. "settings_icon.dds", "$l10n_moh_mod_settings_title")
    g_royalSettings:registerSetting(
        self.name,
        "hide_confirm_enabled",
        g_royalSettings.TYPES.GLOBAL,
        g_royalSettings.OWNERS.USER,
        2,
        {false, true},
        {"$l10n_ui_off", "$l10n_ui_on"},
        "$l10n_moh_hide_confirm_enabled",
        "$l10n_moh_hide_confirm_enabled_tooltip"
    ):addCallback(self.hideConfirmEnabledChanged, self)
    g_royalSettings:registerSetting(
        self.name,
        "sell_confirm_enabled",
        g_royalSettings.TYPES.GLOBAL,
        g_royalSettings.OWNERS.USER,
        2,
        {false, true},
        {"$l10n_ui_off", "$l10n_ui_on"},
        "$l10n_moh_sell_confirm_enabled",
        "$l10n_moh_sell_confirm_enabled_tooltip"
    ):addCallback(self.sellConfirmEnabledChanged, self)
end

function MapObjectsHider:hideConfirmEnabledChanged(value)
    self.hideConfirmEnabled = value
end

function MapObjectsHider:sellConfirmEnabledChanged(value)
    self.sellConfirmEnabled = value
end

function MapObjectsHider:onPreLoadMap(mapFile)
end

function MapObjectsHider:onCreateStartPoint(startPointNode)
end

function MapObjectsHider:onLoadMap(mapNode, mapFile)
    self.mapNode = mapNode
end

function MapObjectsHider:onPostLoadMap(mapNode, mapFile)
end

function MapObjectsHider:onLoadSavegame(savegameDirectory, savegameIndex)
    if g_server ~= nil then
        local file = string.format("%smapObjectsHider.xml", savegameDirectory)
        if fileExists(file) then
            local xmlFile = loadXMLFile("mapObjectsHider_xml_temp", file)
            local savegameUpdate = false
            local savegameRevision = getXMLInt(xmlFile, "mapObjectsHider#revision") or 0
            if savegameRevision < self.revision then
                g_logManager:devInfo("[%s] Updating savegame from revision %d to %d", self.name, savegameRevision, self.revision)
                savegameUpdate = true
            end
            local savegameMd5 = getXMLBool(xmlFile, "mapObjectsHider#md5") or false
            if savegameMd5 ~= self.md5 then
                savegameUpdate = true
            end
            local index = 0
            while true do
                local key = string.format("mapObjectsHider.hiddenObjects.object(%d)", index)
                if hasXMLProperty(xmlFile, key) then
                    local object = {}
                    object.name = getXMLString(xmlFile, key .. "#name") or ""
                    object.index = getXMLString(xmlFile, key .. "#index") or ""
                    object.hash = getXMLString(xmlFile, key .. "#hash") or ""
                    object.date = getXMLString(xmlFile, key .. "#date") or ""
                    object.time = getXMLString(xmlFile, key .. "#time") or ""
                    object.player = getXMLString(xmlFile, key .. "#player") or ""
                    object.id = Utility.indexToNode(object.index, self.mapNode)
                    if object.id ~= nil then
                        local newHash = Utility.getNodeHierarchyHash(object.id, self.mapNode, self.md5)
                        if savegameUpdate then
                            object.hash = newHash
                        end
                        if newHash == object.hash then
                            self:hideNode(object.id)
                            object.collisions = {}
                            local cIndex = 0
                            while true do
                                local cKey = string.format("%s.collision(%d)", key, cIndex)
                                if hasXMLProperty(xmlFile, cKey) then
                                    local collision = {}
                                    collision.name = getXMLString(xmlFile, cKey .. "#name") or ""
                                    collision.index = getXMLString(xmlFile, cKey .. "#index") or ""
                                    collision.rigidBodyType = getXMLString(xmlFile, cKey .. "#rigidBodyType") or "NoRigidBody"
                                    collision.id = Utility.indexToNode(collision.index, self.mapNode)
                                    if collision.id ~= nil and getRigidBodyType(collision.id) == collision.rigidBodyType then
                                        self:decollideNode(collision.id)
                                        table.insert(object.collisions, collision)
                                    end
                                    cIndex = cIndex + 1
                                else
                                    break
                                end
                            end
                            table.insert(self.hiddenObjects, object)
                        else
                            self:printObjectLoadingError(object.name)
                            if self.debug then
                                g_logManager:devInfo("  Old: %s", object.hash)
                                g_logManager:devInfo("  New: %s", newHash)
                            end
                        end
                    else
                        self:printObjectLoadingError(object.name)
                    end
                    index = index + 1
                else
                    break
                end
            end
            delete(xmlFile)
        end
    end
end

function MapObjectsHider:onPreLoadVehicles(xmlFile, resetVehicles)
end

function MapObjectsHider:onPreLoadItems(xmlFile)
end

function MapObjectsHider:onPreLoadOnCreateLoadedObjects(xmlFile)
end

function MapObjectsHider:onLoadFinished()
end

function MapObjectsHider:onStartMission()
end

function MapObjectsHider:onMissionStarted()
end

function MapObjectsHider:onWriteStream(streamId)
    local objectsCount = #self.hiddenObjects
    local collisionsCount = 0
    local collisions = {}
    streamWriteInt32(streamId, objectsCount)
    for i = 1, objectsCount, 1 do
        local obj = self.hiddenObjects[i]
        collisionsCount = collisionsCount + #obj.collisions
        for _, col in pairs(obj.collisions) do
            table.insert(collisions, col.index)
        end
        streamWriteString(streamId, obj.index)
    end
    streamWriteInt32(streamId, collisionsCount)
    for i = 1, collisionsCount, 1 do
        streamWriteString(streamId, collisions[i])
    end
end

function MapObjectsHider:onReadStream(streamId)
    local objectsCount = streamReadInt32(streamId)
    for i = 1, objectsCount, 1 do
        local objIndex = streamReadString(streamId)
        self:hideNode(Utility.indexToNode(objIndex, self.mapNode))
    end
    local collisionsCount = streamReadInt32(streamId)
    for i = 1, collisionsCount, 1 do
        local colIndex = streamReadString(streamId)
        self:decollideNode(Utility.indexToNode(colIndex, self.mapNode))
    end
end

function MapObjectsHider:onUpdate(dt)
    --Utility.renderNodeHierarchy(0.01, 0.98, 0.01, I3DUtil.indexToObject(self.mapNode, "10"))
    --Utility.renderNodeHierarchy(0.01, 0.98, 0.01, self.mapNode, 2)
end

function MapObjectsHider:onUpdateTick(dt)
end

function MapObjectsHider:onWriteUpdateStream(streamId, connection, dirtyMask)
end

function MapObjectsHider:onReadUpdateStream(streamId, timestamp, connection)
end

function MapObjectsHider:onMouseEvent(posX, posY, isDown, isUp, button)
end

function MapObjectsHider:onKeyEvent(unicode, sym, modifier, isDown)
end

function MapObjectsHider:onDraw()
end

function MapObjectsHider:onPreSaveSavegame(savegameDirectory, savegameIndex)
end

function MapObjectsHider:onPostSaveSavegame(savegameDirectory, savegameIndex)
    if g_server ~= nil then
        self = MapObjectsHider
        local file = string.format("%smapObjectsHider.xml", savegameDirectory)
        local xmlFile = createXMLFile("mapObjectsHider_xml_temp", file, "mapObjectsHider")
        setXMLInt(xmlFile, "mapObjectsHider#revision", self.revision)
        setXMLBool(xmlFile, "mapObjectsHider#md5", self.md5)
        local index = 0
        for _, object in pairs(self.hiddenObjects) do
            local key = string.format("mapObjectsHider.hiddenObjects.object(%d)", index)
            setXMLString(xmlFile, key .. "#name", object.name)
            setXMLString(xmlFile, key .. "#index", object.index)
            setXMLString(xmlFile, key .. "#hash", object.hash)
            setXMLString(xmlFile, key .. "#date", object.date)
            setXMLString(xmlFile, key .. "#time", object.time)
            setXMLString(xmlFile, key .. "#player", object.player)

            local cIndex = 0
            for _, collision in pairs(object.collisions) do
                local cKey = string.format("%s.collision(%d)", key, cIndex)
                setXMLString(xmlFile, cKey .. "#name", collision.name)
                setXMLString(xmlFile, cKey .. "#index", collision.index)
                setXMLString(xmlFile, cKey .. "#rigidBodyType", collision.rigidBodyType)
                cIndex = cIndex + 1
            end

            index = index + 1
        end
        saveXMLFile(xmlFile)
        delete(xmlFile)
    end
end

function MapObjectsHider:onPreDeleteMap()
end

function MapObjectsHider:onDeleteMap()
end

function MapObjectsHider:printObjectLoadingError(name)
    g_logManager:warning("[%s] Can't find %s, something may have changed in the map hierarchy, the object will be restored.", self.name, name)
end

function MapObjectsHider:hideObject(objectId, name, hiderPlayerName)
    if g_server ~= nil then
        local objectName = name or getName(objectId)

        local object = MapObjectsHider:getHideObject(objectId, objectName, hiderPlayerName)

        if MapObjectsHider:checkHideObject(object) then
            self:hideNode(object.id)
            HideDecollideNodeEvent.sendToClients(object.index, true)
            for _, collision in pairs(object.collisions) do
                self:decollideNode(collision.id)
                HideDecollideNodeEvent.sendToClients(collision.index, false)
            end
            table.insert(self.hiddenObjects, object)
        end
    else
        ObjectHideRequestEvent.sendToServer(objectId)
    end
end

function MapObjectsHider:hideNode(nodeId)
    setVisibility(nodeId, false)
end

function MapObjectsHider:decollideNode(nodeId)
    setRigidBodyType(nodeId, "NoRigidBody")
end

function MapObjectsHider:getHideObject(objectId, objectName, hiderPlayerName)
    local object = {}
    object.index = Utility.nodeToIndex(objectId, self.mapNode)
    object.id = objectId
    object.hash = Utility.getNodeHierarchyHash(objectId, self.mapNode, self.md5)
    object.name = objectName
    object.date = getDate("%d/%m/%Y")
    object.time = getDate("%H:%M:%S")
    object.player = hiderPlayerName or g_currentMission.userManager:getUserByUserId(g_currentMission.player.userId):getNickname()

    object.collisions = {}
    Utility.queryNodeHierarchy(
        objectId,
        function(node, name)
            local rigidType = getRigidBodyType(node)
            if rigidType ~= "NoRigidBody" then
                local col = {}
                col.index = Utility.nodeToIndex(node, self.mapNode)
                col.name = name
                col.id = node
                col.rigidBodyType = rigidType
                table.insert(object.collisions, col)
            end
        end
    )
    return object
end

function MapObjectsHider:checkHideObject(object)
    if type(object.id) ~= "number" or not entityExists(object.id) then
        return false
    end

    if object.hash ~= Utility.getNodeHierarchyHash(object.id, self.mapNode, self.md5) then
        return false
    end

    if object.name ~= getName(object.id) then
        return false
    end

    for _, collision in pairs(object.collisions) do
        if type(collision.id) ~= "number" or not entityExists(collision.id) then
            return false
        end

        if collision.rigidBodyType ~= getRigidBodyType(collision.id) then
            return false
        end

        if collision.name ~= getName(collision.id) then
            return false
        end
    end

    return true
end

function MapObjectsHider:getRealHideObject(objectId)
    local name = ""
    local id = nil
    Utility.queryNodeParents(
        objectId,
        function(node, nodeName)
            -- do some extra checks to ensure that's the real object
            if getVisibility(node) then
                id = node
                name = nodeName
                return false
            end
            return true
        end
    )
    return id, name
end

function MapObjectsHider:getObjectDebugInfo(objectId)
    local debugInfo = {}
    debugInfo.id = objectId
    _, debugInfo.objectClass = Utility.getObjectClass(objectId)
    debugInfo.object = g_currentMission:getNodeObject(objectId) or "nil"
    debugInfo.rigidBodyType = getRigidBodyType(objectId)
    debugInfo.index = Utility.nodeToIndex(objectId, self.mapNode)
    debugInfo.name = getName(objectId)
    debugInfo.material = getMaterial(objectId, 0)
    debugInfo.materialName = getName(debugInfo.material)
    debugInfo.geometry = getGeometry(objectId)
    debugInfo.clipDistance = getClipDistance(objectId)
    debugInfo.mask = getObjectMask(objectId)
    debugInfo.isNonRenderable = getIsNonRenderable(objectId)
    return debugInfo
end
