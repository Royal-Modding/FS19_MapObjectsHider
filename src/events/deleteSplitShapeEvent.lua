---${title}

---@author ${author}
---@version r_version_r
---@date 09/03/2021

DeleteSplitShapeEvent = {}
DeleteSplitShapeEvent_mt = Class(DeleteSplitShapeEvent, Event)

InitEventClass(DeleteSplitShapeEvent, "DeleteSplitShapeEvent")

function DeleteSplitShapeEvent:emptyNew()
    local e = Event:new(DeleteSplitShapeEvent_mt)
    return e
end

function DeleteSplitShapeEvent:new(splitShapeId)
    local e = DeleteSplitShapeEvent:emptyNew()
    e.splitShapeId = splitShapeId
    return e
end

function DeleteSplitShapeEvent:writeStream(streamId, _)
    writeSplitShapeIdToStream(streamId, self.splitShapeId)
end

function DeleteSplitShapeEvent:readStream(streamId, connection)
    self.splitShapeId = readSplitShapeIdFromStream(streamId)
    self:run(connection)
end

function DeleteSplitShapeEvent:run(_)
    if self.splitShapeId ~= 0 then
        delete(self.splitShapeId)
    end
end

function DeleteSplitShapeEvent.sendEvent(splitShapeId)
    g_client:getServerConnection():sendEvent(DeleteSplitShapeEvent:new(splitShapeId))
end
