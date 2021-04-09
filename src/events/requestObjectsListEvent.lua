--- ${title}

---@author ${author}
---@version r_version_r
---@date 08/04/2021

RequestObjectsListEvent = {}
local RequestObjectsListEvent_mt = Class(RequestObjectsListEvent, Event)

InitEventClass(RequestObjectsListEvent, "RequestObjectsListEvent")

---@return table
function RequestObjectsListEvent:emptyNew()
    local o = Event:new(RequestObjectsListEvent_mt)
    o.className = "RequestObjectsListEvent"
    return o
end

---@return table
function RequestObjectsListEvent:new()
    local o = RequestObjectsListEvent:emptyNew()
    return o
end

---@param streamId integer
function RequestObjectsListEvent:writeStream(streamId, _)
end

---@param streamId integer
---@param connection Connection
function RequestObjectsListEvent:readStream(streamId, connection)
    self:run(connection)
end

---@param connection Connection
function RequestObjectsListEvent:run(connection)
    if g_server ~= nil then
        connection:sendEvent(SendObjectsListEvent:new(MapObjectsHider.hiddenObjects))
    end
end

function RequestObjectsListEvent.sendToServer()
    g_client:getServerConnection():sendEvent(RequestObjectsListEvent:new())
end
