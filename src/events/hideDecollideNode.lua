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

function HideDecollideNodeEvent:new(objectId, hide)
    local o = HideDecollideNodeEvent:emptyNew()
    o.objectId = objectId
    o.mode = hide
    return o
end

function HideDecollideNodeEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.objectId)
    streamWriteBool(streamId, self.hide)
end

function HideDecollideNodeEvent:readStream(streamId, connection)
    self.objectId = streamReadInt32(streamId)
    self.hide = streamReadBool(streamId)
    self:run(connection)
end

function HideDecollideNodeEvent:run(connection)
    if g_server == nil then
        if self.hide then
            MapObjectsHider:hideNode(self.objectId)
        else
            MapObjectsHider:decollideNode(self.objectId)
        end
    end
end

function HideDecollideNodeEvent.sendToClients(objectId, hide)
    if g_server ~= nil then
        g_server:broadcastEvent(HideDecollideNodeEvent:new(objectId, hide))
    end
end
