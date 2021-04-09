--- ${title}

---@author ${author}
---@version r_version_r
---@date 08/04/2021

SendObjectsListEvent = {}
local SendObjectsListEvent_mt = Class(SendObjectsListEvent, Event)

InitEventClass(SendObjectsListEvent, "SendObjectsListEvent")

---@return table
function SendObjectsListEvent:emptyNew()
    local o = Event:new(SendObjectsListEvent_mt)
    o.className = "SendObjectsListEvent"
    ---@type HiddenObject[]
    self.hiddenObjects = {}
    return o
end

---@param hiddenObjects HideObject[]
---@return table
function SendObjectsListEvent:new(hiddenObjects)
    local o = SendObjectsListEvent:emptyNew()

    for _, ho in pairs(hiddenObjects) do
        ---@class HiddenObject
        local pho = {
            index = ho.index,
            id = 0,
            name = "",
            datetime = "",
            timestamp = ho.timestamp,
            player = ho.player
        }
        table.insert(self.hiddenObjects, pho)
    end
    return o
end

---@param streamId integer
function SendObjectsListEvent:writeStream(streamId, _)
    streamWriteUInt16(streamId, #self.hiddenObjects)
    for _, ho in pairs(self.hiddenObjects) do
        streamWriteString(streamId, ho.index)
        streamWriteString(streamId, ho.player)
        streamWriteUIntN(streamId, ho.timestamp, 28)
    end
end

---@param streamId integer
---@param connection Connection
function SendObjectsListEvent:readStream(streamId, connection)
    local hoCount = streamReadUInt16(streamId)
    for i = 1, hoCount, 1 do
        ---@type HiddenObject
        local ho = {index = streamReadString(streamId)}
        ho.player = streamReadString(streamId)
        ho.timestamp = streamReadUIntN(streamId, 28)
        table.insert(self.hiddenObjects, ho)
    end
    self:run(connection)
end

---@param connection Connection
function SendObjectsListEvent:run(connection)
    MapObjectsHider.gui.target:onHiddenObjectsReceived(self.hiddenObjects)
end
