--- ${title}

---@author ${author}
---@version r_version_r
---@date 09/04/2021

ObjectShowRequestEvent = {}
local ObjectShowRequestEvent_mt = Class(ObjectShowRequestEvent, Event)

InitEventClass(ObjectShowRequestEvent, "ObjectShowRequestEvent")

---@return table
function ObjectShowRequestEvent:emptyNew()
    local o = Event:new(ObjectShowRequestEvent_mt)
    o.className = "ObjectShowRequestEvent"
    return o
end

---@param objectIndex string
---@return table
function ObjectShowRequestEvent:new(objectIndex)
    local o = ObjectShowRequestEvent:emptyNew()
    o.objectIndex = objectIndex
    return o
end

---@param streamId integer
function ObjectShowRequestEvent:writeStream(streamId, _)
    streamWriteString(streamId, self.objectIndex)
end

---@param streamId integer
---@param connection Connection
function ObjectShowRequestEvent:readStream(streamId, connection)
    self.objectIndex = streamReadString(streamId)
    self:run(connection)
end

---@param connection Connection
function ObjectShowRequestEvent:run(connection)
    if g_server ~= nil then
        MapObjectsHider:showObject(self.objectIndex)
    end
end

---@param objectIndex string
function ObjectShowRequestEvent.sendToServer(objectIndex)
    g_client:getServerConnection():sendEvent(ObjectShowRequestEvent:new(objectIndex))
end
