--- ${title}

---@author ${author}
---@version r_version_r
---@date 02/12/2020

ObjectHideRequestEvent = {}
ObjectHideRequestEvent_mt = Class(ObjectHideRequestEvent, Event)

InitEventClass(ObjectHideRequestEvent, "ObjectHideRequestEvent")

---@return table
function ObjectHideRequestEvent:emptyNew()
    local o = Event:new(ObjectHideRequestEvent_mt)
    o.className = "ObjectHideRequestEvent"
    return o
end

---@param objectIndex integer
---@return table
function ObjectHideRequestEvent:new(objectIndex)
    local o = ObjectHideRequestEvent:emptyNew()
    o.objectIndex = objectIndex
    return o
end

---@param streamId integer
function ObjectHideRequestEvent:writeStream(streamId, _)
    streamWriteString(streamId, self.objectIndex)
end

---@param streamId integer
---@param connection Connection
function ObjectHideRequestEvent:readStream(streamId, connection)
    self.objectIndex = streamReadString(streamId)
    self:run(connection)
end

---@param connection Connection
function ObjectHideRequestEvent:run(connection)
    if g_server ~= nil then
        MapObjectsHider:hideObject(EntityUtility.indexToNode(self.objectIndex, MapObjectsHider.mapNode), nil, g_currentMission.userManager:getUserByConnection(connection):getNickname())
    end
end

---@param objectId integer
function ObjectHideRequestEvent.sendToServer(objectId)
    if g_server == nil then
        g_client:getServerConnection():sendEvent(ObjectHideRequestEvent:new(EntityUtility.nodeToIndex(objectId, MapObjectsHider.mapNode)))
    end
end
