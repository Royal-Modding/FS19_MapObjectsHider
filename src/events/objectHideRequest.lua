--- ${title}

---@author ${author}
---@version r_version_r
---@date 02/12/2020

ObjectHideRequestEvent = {}
ObjectHideRequestEvent_mt = Class(ObjectHideRequestEvent, Event)

InitEventClass(ObjectHideRequestEvent, "ObjectHideRequestEvent")

function ObjectHideRequestEvent:emptyNew()
    local o = Event:new(ObjectHideRequestEvent_mt)
    o.className = "ObjectHideRequestEvent"
    return o
end

function ObjectHideRequestEvent:new(objectIndex)
    local o = ObjectHideRequestEvent:emptyNew()
    o.objectIndex = objectIndex
    return o
end

function ObjectHideRequestEvent:writeStream(streamId, connection)
    streamWriteString(streamId, self.objectIndex)
end

function ObjectHideRequestEvent:readStream(streamId, connection)
    self.objectIndex = streamReadString(streamId)
    self:run(connection)
end

function ObjectHideRequestEvent:run(connection)
    if g_server ~= nil then
        MapObjectsHider:hideObject(EntityUtility.indexToNode(self.objectIndex, MapObjectsHider.mapNode), nil, g_currentMission.userManager:getUserByConnection(connection):getNickname())
    end
end

function ObjectHideRequestEvent.sendToServer(objectId)
    if g_server == nil then
        g_client:getServerConnection():sendEvent(ObjectHideRequestEvent:new(EntityUtility.nodeToIndex(objectId, MapObjectsHider.mapNode)))
    end
end
