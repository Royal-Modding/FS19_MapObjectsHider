---${title}

---@author ${author}
---@version r_version_r
---@date 09/03/2021

DeleteSplitShapeEvent = {}
local DeleteSplitShapeEvent_mt = Class(DeleteSplitShapeEvent, Event)

InitEventClass(DeleteSplitShapeEvent, "DeleteSplitShapeEvent")

function DeleteSplitShapeEvent:emptyNew()
    local e = Event:new(DeleteSplitShapeEvent_mt)
    return e
end

---@param splitShapeId integer
---@return table
function DeleteSplitShapeEvent:new(splitShapeId)
    local e = DeleteSplitShapeEvent:emptyNew()
    e.splitShapeId = splitShapeId
    return e
end

---@param streamId integer
function DeleteSplitShapeEvent:writeStream(streamId)
    writeSplitShapeIdToStream(streamId, self.splitShapeId)
end

---@param streamId integer
---@param connection Connection
function DeleteSplitShapeEvent:readStream(streamId, connection)
    self.splitShapeId = readSplitShapeIdFromStream(streamId)
    self:run(connection)
end

function DeleteSplitShapeEvent:run()
    if self.splitShapeId ~= 0 then
        delete(self.splitShapeId)
    end
end

---@param splitShapeId integer
function DeleteSplitShapeEvent.sendEvent(splitShapeId)
    g_client:getServerConnection():sendEvent(DeleteSplitShapeEvent:new(splitShapeId))
end
