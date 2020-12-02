--
-- ${title}
--
-- @author ${author}
-- @version ${version}
-- @date 02/12/2020

HideDecollideNodeEvent = {}
HideDecollideNodeEvent_mt = Class(HideDecollideNodeEvent, Event)

InitEventClass(HideDecollideNodeEvent, "HideDecollideNodeEvent")

function HideDecollideNodeEvent:emptyNew()
    local o = Event:new(HideDecollideNodeEvent_mt)
    o.className = "HideDecollideNodeEvent"
    return o
end

function HideDecollideNodeEvent:new(objectIndex, hide)
    local o = HideDecollideNodeEvent:emptyNew()
    o.objectIndex = objectIndex
    o.hide = hide
    return o
end

function HideDecollideNodeEvent:writeStream(streamId, connection)
    streamWriteString(streamId, self.objectIndex)
    streamWriteBool(streamId, self.hide)
end

function HideDecollideNodeEvent:readStream(streamId, connection)
    self.objectIndex = streamReadString(streamId)
    self.hide = streamReadBool(streamId)
    self:run(connection)
end

function HideDecollideNodeEvent:run(connection)
    if g_server == nil then
        if self.hide then
            MapObjectsHider:hideNode(Utility.indexToNode(self.objectIndex, MapObjectsHider.mapNode))
        else
            MapObjectsHider:decollideNode(Utility.indexToNode(self.objectIndex, MapObjectsHider.mapNode))
        end
    end
end

function HideDecollideNodeEvent.sendToClients(objectIndex, hide)
    if g_server ~= nil then
        g_server:broadcastEvent(HideDecollideNodeEvent:new(objectIndex, hide))
    end
end
