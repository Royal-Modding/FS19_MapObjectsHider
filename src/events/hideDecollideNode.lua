--- ${title}

---@author ${author}
---@version r_version_r
---@date 02/12/2020

HideDecollideNodeEvent = {}
HideDecollideNodeEvent_mt = Class(HideDecollideNodeEvent, Event)

InitEventClass(HideDecollideNodeEvent, "HideDecollideNodeEvent")

function HideDecollideNodeEvent:emptyNew()
    local o = Event:new(HideDecollideNodeEvent_mt)
    o.className = "HideDecollideNodeEvent"
    return o
end

---@param objectIndex integer
---@param hide boolean
---@return table
function HideDecollideNodeEvent:new(objectIndex, hide)
    local o = HideDecollideNodeEvent:emptyNew()
    o.objectIndex = objectIndex
    o.hide = hide
    return o
end

---@param streamId integer
function HideDecollideNodeEvent:writeStream(streamId)
    streamWriteString(streamId, self.objectIndex)
    streamWriteBool(streamId, self.hide)
end

---@param streamId integer
---@param connection Connection
function HideDecollideNodeEvent:readStream(streamId, connection)
    self.objectIndex = streamReadString(streamId)
    self.hide = streamReadBool(streamId)
    self:run(connection)
end

---@param connection Connection
function HideDecollideNodeEvent:run(connection)
    if g_server == nil then
        if self.hide then
            MapObjectsHider:hideNode(EntityUtility.indexToNode(self.objectIndex, MapObjectsHider.mapNode))
        else
            MapObjectsHider:decollideNode(EntityUtility.indexToNode(self.objectIndex, MapObjectsHider.mapNode))
        end
    end
end

---@param objectIndex integer
---@param hide boolean
function HideDecollideNodeEvent.sendToClients(objectIndex, hide)
    if g_server ~= nil then
        g_server:broadcastEvent(HideDecollideNodeEvent:new(objectIndex, hide))
    end
end
