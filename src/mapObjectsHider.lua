--
-- ${title}
--
-- @author ${author}
-- @version ${version}
-- @date 29/11/2020

MapObjectsHider = {}
MapObjectsHider.debug = r_debug_r
MapObjectsHider.hiddenObjects = {}

InitRoyalUtility(Utils.getFilename("lib/utility/", g_currentModDirectory))

function MapObjectsHider:loadMap()
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
    self.mapNode = g_currentMission.maps[1]
    self:loadSavegame()
end

function MapObjectsHider:loadSavegame()
    if g_server ~= nil then
        local file = g_currentMission.missionInfo.savegameDirectory .. "/mapObjectsHider.xml"
        if fileExists(file) then
            local xmlFile = loadXMLFile("mapObjectsHider_xml_temp", file)
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
                    object.id = Utility.indexToNode(object.index, self.mapNode)
                    if object.id ~= nil then
                        local newHash = Utility.getNodeHierarchyHash(object.id, self.mapNode)
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
                                g_logManager:devInfo("Old hash: %s", object.hash)
                                g_logManager:devInfo("New hash: %s", newHash)
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

function MapObjectsHider:printObjectLoadingError(name)
    g_logManager:warning("Can't find %s, something may have changed in the map hierarchy, the object will be restored.", name)
end

function MapObjectsHider:saveSavegame()
    if g_server ~= nil then
        self = MapObjectsHider
        local file = g_currentMission.missionInfo.savegameDirectory .. "/mapObjectsHider.xml"
        local xmlFile = createXMLFile("mapObjectsHider_xml_temp", file, "mapObjectsHider")
        local index = 0
        for _, object in pairs(self.hiddenObjects) do
            local key = string.format("mapObjectsHider.hiddenObjects.object(%d)", index)
            setXMLString(xmlFile, key .. "#name", object.name)
            setXMLString(xmlFile, key .. "#index", object.index)
            setXMLString(xmlFile, key .. "#hash", object.hash)
            setXMLString(xmlFile, key .. "#date", object.date)
            setXMLString(xmlFile, key .. "#time", object.time)

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

function MapObjectsHider:update(dt)
    --Utility.renderNodeHierarchy(0.01, 0.98, 0.01, I3DUtil.indexToObject(self.mapNode, "10"))
    --Utility.renderNodeHierarchy(0.01, 0.98, 0.01, self.mapNode, 2)
end

function MapObjectsHider:mouseEvent(posX, posY, isDown, isUp, button)
end

function MapObjectsHider:keyEvent(unicode, sym, modifier, isDown)
end

function MapObjectsHider:draw()
end

function MapObjectsHider:delete()
end

function MapObjectsHider:deleteMap()
end

function MapObjectsHider:hideObject(objectId)
    if g_server ~= nil then
        local objectName = ""
        Utility.queryNodeParents(
            objectId,
            function(node, name)
                -- do some extra checks to ensure that's the real object
                if getVisibility(node) then
                    objectId = node
                    objectName = name
                    return false
                end
                return true
            end
        )

        local object = MapObjectsHider:getHideObject(objectId, objectName)

        if MapObjectsHider:checkHideObject(object) then
            self:hideNode(object.id)
            HideDecollideNodeEvent.sendToClients(object.id, true)
            for _, collision in pairs(object.collisions) do
                self:decollideNode(collision.id)
                HideDecollideNodeEvent.sendToClients(collision.id, false)
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

function MapObjectsHider:getHideObject(objectId, objectName)
    local object = {}
    object.index = Utility.nodeToIndex(objectId, self.mapNode)
    object.id = objectId
    object.hash = Utility.getNodeHierarchyHash(objectId, self.mapNode)
    object.name = objectName
    object.date = getDate("%d/%m/%Y")
    object.time = getDate("%H:%M:%S")

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

    if object.hash ~= Utility.getNodeHierarchyHash(object.id, self.mapNode) then
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

Utility.appendedFunction(FSBaseMission, "saveSavegame", MapObjectsHider.saveSavegame)

addModEventListener(MapObjectsHider)
