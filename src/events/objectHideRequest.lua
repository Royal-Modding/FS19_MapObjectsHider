--
-- ${title}
--
-- @author ${author}
-- @version ${version}
-- @date 02/12/2020

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
        MapObjectsHider:hideObject(Utility.indexToNode(self.objectIndex, MapObjectsHider.mapNode))
    end
end

function ObjectHideRequestEvent.sendToServer(objectId)
    if g_server == nil then
        g_client:getServerConnection():sendEvent(ObjectHideRequestEvent:new(Utility.nodeToIndex(objectId, MapObjectsHider.mapNode)))
    end
end
