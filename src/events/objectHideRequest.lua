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

function ObjectHideRequestEvent:new(objectId)
    local o = ObjectHideRequestEvent:emptyNew()
    o.objectId = objectId
    return o
end

function ObjectHideRequestEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.objectId)
end

function ObjectHideRequestEvent:readStream(streamId, connection)
    self.objectId = streamReadInt32(streamId)
    self:run(connection)
end

function ObjectHideRequestEvent:run(connection)
    if g_server ~= nil then
        MapObjectsHider:hideObject(self.objectId)
    end
end

function ObjectHideRequestEvent.sendToServer(objectId)
    if g_server == nil then
        g_client:getServerConnection():sendEvent(ObjectHideRequestEvent:new(objectId))
    end
end
