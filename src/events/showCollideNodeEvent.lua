--- ${title}

---@author ${author}
---@version r_version_r
---@date 09/04/2021

ShowCollideNodeEvent = {}
local ShowCollideNodeEvent_mt = Class(ShowCollideNodeEvent, Event)

InitEventClass(ShowCollideNodeEvent, "ShowCollideNodeEvent")

function ShowCollideNodeEvent:emptyNew()
    local o = Event:new(ShowCollideNodeEvent_mt)
    o.className = "ShowCollideNodeEvent"
    return o
end

---@param show boolean
---@param objectIndex string
---@param rigidBodyType string
---@return table
function ShowCollideNodeEvent:new(show, objectIndex, rigidBodyType)
    local o = ShowCollideNodeEvent:emptyNew()
    o.objectIndex = objectIndex
    o.show = show
    o.rigidBodyType = rigidBodyType
    return o
end

---@param streamId integer
function ShowCollideNodeEvent:writeStream(streamId)
    streamWriteString(streamId, self.objectIndex)
    streamWriteBool(streamId, self.show)
    if not self.show then
        streamWriteString(streamId, self.rigidBodyType)
    end
end

---@param streamId integer
---@param connection Connection
function ShowCollideNodeEvent:readStream(streamId, connection)
    self.objectIndex = streamReadString(streamId)
    self.show = streamReadBool(streamId)
    if not self.show then
        self.rigidBodyType = streamReadString(streamId)
    end
    self:run(connection)
end

---@param connection Connection
function ShowCollideNodeEvent:run(connection)
    if g_server == nil then
        if self.show then
            MapObjectsHider:showNode(EntityUtility.indexToNode(self.objectIndex, MapObjectsHider.mapNode))
        else
            MapObjectsHider:collideNode(EntityUtility.indexToNode(self.objectIndex, MapObjectsHider.mapNode), self.rigidBodyType)
        end
    end
end

---@param show boolean
---@param objectIndex string
---@param rigidBodyType string
function ShowCollideNodeEvent.sendToClients(show, objectIndex, rigidBodyType)
    if g_server ~= nil then
        g_server:broadcastEvent(ShowCollideNodeEvent:new(show, objectIndex, rigidBodyType))
    end
end
